local addonName, addon = ...

-- Following a route. Once the player starts a trip, this tracks which step they are on and
-- how far along it is, from samples of where they are:
--   sample = { mapID, x, y, onTaxi, now, facing }   (mapID nil when we can't tell, as in an instance)
-- It knows nothing about frames; the navigator shows what Model() says, and tests feed it
-- samples directly.
--
-- What "progress" means depends on the step:
--   walk       distance left to the step's destination (yards), which way to turn to face it
--              (an arrow), and time left scaled from the distance;
--   flight     waiting until the player is actually on the taxi, then a bar over the flight's
--              planned time, done when they land;
--   transport  (boat, zeppelin, tram) waiting until the player has moved off the boarding
--              point, then a bar from how much of the way to the far dock is covered (or from
--              elapsed time when positions aren't readable at sea), done on arrival;
--   ability    (hearthstone, teleport) a button to use it; done when the player arrives;
--   equip      the step before using an item that has to be worn: a button to put it on; done once
--              it is worn (sample.equipped(itemID));
--   portal     walk into it; done when the player arrives (a jump counts only if it lands near there).
-- A step is done when the player is within a small radius of its destination (a landing or a
-- ship's arrival counts too; a teleport or portal also counts the moment the player is suddenly
-- somewhere else, since a bind point can be well away from the inn node we have for it). If they get to a later step's destination, the steps between are
-- skipped, and finishing the last step ends the trip. A walk, or a ship once it has left, also counts as done when
-- the player is already nearer the next walk's destination than its own destination is: they cut across a field
-- past a checkpoint, or jumped off a boat short of the dock (see `passed`).

local Navigation = {}
addon.Navigation = Navigation

local WALK_RADIUS = 30       -- yards
local INDOOR_RADIUS = 8      -- yards, for a walk into, through or out of an interior: 30 is half a building there
local ARRIVE_RADIUS = 60     -- yards, for everything that isn't walking: a landing spot is looser
local DEPART_RADIUS = 40     -- yards moved from the boarding point before a ship counts as underway
local JUMP = 300             -- yards between two updates that can only be a teleport or a portal
local TICKET_WAIT = 15       -- seconds a chosen flight has to start before we forget it was chosen
local NOTICE_TIME = 8        -- seconds a note ("Route updated") stays up
local PASS_MARGIN = 20       -- yards nearer the next destination than a step's own end must be before it counts as passed

local function kindOf(method)
    return addon:Method(method).kind
end

local active       -- the trip: { entry, plan, steps, index, state, finished, model }
local destinationName   -- (below, with Start) what the navigator's title says

-- A flight is timed from take-off to landing, a boat from leaving the dock to arriving (compared with its
-- ride, where the edge has one, not the plan's number, which includes the wait). Each measurement, { kind, from, to,
-- planned, actual } in seconds, goes to Navigation.onTiming if a tool has set one (MapzerothDataTools
-- does); nothing is kept or shown here.
local function report(record)
    if Navigation.onTiming then Navigation.onTiming(record) end
end

-- A node of ours, or the trip's own destination when it isn't one (the waypoint).
local function nodeOf(id)
    return id and (addon.World:GetNode(id) or (active and active.extra and active.extra[id]))
end

-- The player's spot as a node, reused for every distance (a tick would otherwise allocate one per call); `jumpTo`
-- is a second one, because the jump check compares two samples (the last against the current one). While an
-- Update runs, the current sample is projected to world coordinates once and carried on `world` of whichever
-- scratch node stands for it (TravelGraph's DistanceProvider reads it instead of projecting again); the last
-- known spot keeps its own, so the jump check doesn't project it a second time.
local you = { id = "YOU_NOW", nocache = true }
local jumpTo = { id = "JUMP", nocache = true }
local nowSample, nowWorld           -- the sample being updated, and its { x, y, continent } (nil: not projected)
local worldOfNow, worldOfLast = {}, {}

local function place(node, sample)
    node.mapID, node.x, node.y = sample.mapID, sample.x, sample.y
    if sample == nowSample then node.world = nowWorld else node.world = sample.world end
    return node
end

-- Yards from the sample to a node, or nil if we can't say.
local function distance(sample, node)
    if not (sample and sample.mapID and node and node.mapID) then return nil end
    return addon.TravelGraph.DistanceProvider(place(you, sample), node)
end

-- Where a node is on the map the player is on, as x, y (0 to 1), or nil. Same map: as it is;
-- another (a city and its zone): carried across through world coordinates. Replaceable for tests.
function Navigation.MapPoint(node, mapID)
    if node.mapID == mapID then return node.x, node.y end
    local ok, continent, world = pcall(C_Map.GetWorldPosFromMapPos, node.mapID, CreateVector2D(node.x, node.y))
    if not (ok and world) then return nil end
    local ok2, _, pos = pcall(C_Map.GetMapPosFromWorldPos, continent, world, mapID)
    if not (ok2 and pos) then return nil end
    return pos:GetXY()
end

-- Yards for a step of 1 in x and in y on a map, measured with the same distance the rest of the
-- addon uses (a map isn't square, so a unit in x and a unit in y differ).
-- A map's scale never changes, so it is measured once per map (per provider: tests swap it). A map that
-- can't be measured yet is asked again next time.
local scales, scalesProvider = {}, nil
local function yardsPerUnit(mapID)
    local provider = addon.TravelGraph.DistanceProvider
    if scalesProvider ~= provider then scales, scalesProvider = {}, provider end
    local known = scales[mapID]
    if known then return known[1], known[2] end
    local here = { id = "SCALE_A", nocache = true, mapID = mapID, x = 0.5, y = 0.5 }
    local east = { id = "SCALE_B", nocache = true, mapID = mapID, x = 0.51, y = 0.5 }
    local south = { id = "SCALE_C", nocache = true, mapID = mapID, x = 0.5, y = 0.51 }
    local dx = provider(here, east)
    local dy = provider(here, south)
    if not (dx and dy) then return nil end
    known = { dx / 0.01, dy / 0.01 }
    scales[mapID] = known
    return known[1], known[2]
end

-- Yards for a step of 1 in x and in y on a map (the minimap route needs it too).
Navigation.YardsPerUnit = yardsPerUnit

-- The plan of the trip being followed, or nil.
function Navigation:CurrentPlan()
    return active and active.plan or nil
end

-- The turn needed to face a node, in radians: 0 is straight ahead, positive is to the left
-- (counter-clockwise, as the game measures facing), negative to the right. Needs sample.facing.
-- North is up the map, so a target's north-ness is minus its y difference.
function Navigation:Heading(sample, node)
    if not (sample and sample.facing and sample.mapID and node) then return nil end
    local tx, ty = Navigation.MapPoint(node, sample.mapID)
    local xScale, yScale = yardsPerUnit(sample.mapID)
    if not (tx and xScale) then return nil end
    local east = (tx - sample.x) * xScale
    local north = -(ty - sample.y) * yScale
    local bearing = math.atan2(-east, north)           -- counter-clockwise from north
    local turn = bearing - sample.facing
    while turn > math.pi do turn = turn - 2 * math.pi end
    while turn <= -math.pi do turn = turn + 2 * math.pi end
    return turn
end

-- Between updates, for the arrow: the yards to the current step's destination and which way to turn, read from
-- where the player is now, on a step on foot (or flying yourself); nil otherwise. Moves nothing on.
function Navigation:Pointer()
    if not active or active.finished or active.offRoute then return nil end
    local step = active.steps[active.index]
    if not step or kindOf(step.method) ~= "walk" then return nil end
    local sample = self:Sample()
    local node = nodeOf(step.nodeID)
    return distance(sample, node), self:Heading(sample, node)
end

-- Time aboard a boat or zeppelin, from leaving the dock: the edge's `ride` where it has one. The step's own time
-- is the plan's, which also counts the average wait for it to come in.
local function rideOf(step)
    return step.source and step.source.ride or step.seconds
end

-- A walk that starts or ends in an interior (the way out of Stormwind's Mage Tower): walls are close, so it is done only
-- at the door, and it can't be passed by cutting across.
local function indoorWalk(step)
    if kindOf(step.method) ~= "walk" then return false end
    local World = addon.World
    local from, to = World:GetNodeContainer(step.fromID), World:GetNodeContainer(step.nodeID)
    return (from ~= nil and World:GetFlag(from, "indoor") == true) or (to ~= nil and World:GetFlag(to, "indoor") == true)
end

local function radiusOf(step)
    if kindOf(step.method) ~= "walk" then return ARRIVE_RADIUS end
    return indoorWalk(step) and INDOOR_RADIUS or WALK_RADIUS
end

-- True when the player is at the step's destination; also the yards to it, when they were measured.
local function arrived(step, sample)
    if step.method == "equip" then return false end       -- putting something on isn't going anywhere
    local d = distance(sample, nodeOf(step.nodeID))
    return d ~= nil and d <= radiusOf(step), d
end

-- The last step that can be looked ahead to from the current one: the end of the leg it is on, else the route's end.
local function lookAheadEnd()
    if active.legOf and active.legOf[active.index] then return active.legEnds[active.legOf[active.index]] end
    return #active.steps
end

local function beginStep(sample)
    local step = active.steps[active.index]
    local node = nodeOf(step.nodeID)
    local state = { startedAt = sample.now, startDistance = distance(sample, node) }
    local kind = kindOf(step.method)
    if kind == "transport" then
        state.origin = nodeOf(step.fromID)
        state.routeLength = state.origin and node and addon.TravelGraph.DistanceProvider(state.origin, node)
    end
    -- A walk or a ship followed by a walk (in the same leg: a tour's stop is never passed) can be passed: `gap` is how
    -- far its end is from the next one's. Not when the player already starts nearer than that, though: the step
    -- may be the way round something (a pass over a ridge), and the next place only looks near in a straight line.
    local nextStep = active.index < lookAheadEnd() and active.steps[active.index + 1]
    if nextStep and kindOf(nextStep.method) == "walk" and (kind == "walk" or kind == "transport") and not indoorWalk(step) then
        local nextNode = nodeOf(nextStep.nodeID)
        local gap = node and nextNode and addon.TravelGraph.DistanceProvider(node, nextNode)
        local fromStart = gap and distance(sample, nextNode)
        if gap and not (fromStart and fromStart < gap - PASS_MARGIN) then state.gap = gap end
    end
    -- A walk to a zone border (BORDER_<A>_TO_<B>, on A's map; its pair BORDER_<B>_TO_<A> is on B's) is passed once the
    -- player is on B's map, however they crossed: over a river or down a slope instead of by the road.
    local a, b
    if type(step.nodeID) == "string" then a, b = step.nodeID:match("^BORDER_(.+)_TO_(.+)$") end
    local pair = a and addon.World:GetNode("BORDER_" .. b .. "_TO_" .. a)
    if kind == "walk" and pair and node and pair.mapID ~= node.mapID then state.farSide = pair.mapID end
    active.state = state
end

-- True when the current step has been passed without reaching its end (see beginStep): `toNext` is the yards from the
-- player to the next step's destination. A ship has to have been seen leaving first.
local function passed(step, toNext, sample)
    local state = active.state
    if state.farSide and sample.mapID == state.farSide then return true end
    if not (state.gap and toNext) then return false end
    if kindOf(step.method) == "transport" and not state.underway then return false end
    return toNext < state.gap - PASS_MARGIN
end

local function advance(sample)
    active.index = active.index + 1
    if active.index > #active.steps then
        active.finished = true
        active.state = nil
    else
        beginStep(sample)
    end
end

-- True once the current step is done. Also watches for boarding and take-off as it goes.
local function completed(step, sample)
    local kind, state = kindOf(step.method), active.state
    -- A flight or a ship that started far from where it ends and finds the player there is
    -- done, even if we never saw it depart (positions can be unreadable at sea).
    local farStart = state.startDistance == nil or state.startDistance > 2 * ARRIVE_RADIUS

    if kind == "flight" then
        if sample.onTaxi then
            state.flying = true
            state.flightStart = state.flightStart or sample.now
            return false
        end
        if state.flying then
            report({ kind = "flight", from = state.fromID or step.fromID, to = step.nodeID,
                     planned = state.seconds or step.seconds, actual = sample.now - state.flightStart })
            return true
        end
        return farStart and arrived(step, sample)
    elseif kind == "transport" then
        if not state.underway then
            local d = state.origin and distance(sample, state.origin)
            if d and d > DEPART_RADIUS then
                state.underway = true
                state.departedAt = sample.now
            end
        end
        if (state.underway or farStart) and arrived(step, sample) then
            if state.underway then
                report({ kind = step.method, from = step.fromID, to = step.nodeID,
                         planned = rideOf(step), actual = sample.now - state.departedAt })
            end
            return true
        end
        return false
    end
    if step.method == "equip" then
        -- Done once the item is worn (the sample says: it needs the client).
        return sample.equipped ~= nil and step.source ~= nil and sample.equipped(step.source.itemID) == true
    end
    if kind == "ability" then
        return arrived(step, sample) or active.jumped == true
    end
    if kind == "portal" then
        -- A portal lands where we have it, so a jump ends the step only near there (or onto its map, when the client
        -- can't measure to it): the room's other portal, taken by mistake, isn't this one.
        if arrived(step, sample) then return true end
        if not active.jumped then return false end
        local node = nodeOf(step.nodeID)
        local d = distance(sample, node)
        if d then return d <= JUMP end
        return node ~= nil and sample.mapID == node.mapID
    end
    return arrived(step, sample)
end

local function clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

-- What the navigator shows for the current step.
local function buildModel(sample)
    local steps = active.steps
    if active.finished then
        return { finished = true, total = #steps, destination = active.entry and active.entry.name }
    end

    local step, state = steps[active.index], active.state
    local kind = kindOf(step.method)
    local model = {
        finished = false, index = active.index, total = #steps, step = step, kind = kind,
        destination = destinationName(),
    }
    local node = nodeOf(step.nodeID)
    local left = step.seconds
    if state.seconds then left = state.seconds end        -- a flight that covers several steps

    if kind == "walk" then
        model.distance = distance(sample, node)
        model.heading = Navigation:Heading(sample, node)
        if model.distance and state.startDistance and state.startDistance > 0 then
            left = step.seconds * clamp(model.distance / state.startDistance, 0, 1)
        end
    elseif kind == "flight" then
        if state.flying then
            model.phase = "flying"
            local planned = state.seconds or step.seconds
            model.overrun = (sample.now - state.flightStart) > planned      -- longer than the data says
            model.progress = clamp((sample.now - state.flightStart) / planned, 0, 0.99)
            left = planned * (1 - model.progress)
        else
            model.phase = "waiting"
            model.progress = 0
        end
    elseif kind == "transport" then
        if state.underway then
            model.phase = "underway"
            local ride = rideOf(step)
            local d = distance(sample, node)
            if d and state.routeLength and state.routeLength > 0 then
                model.progress = clamp(1 - d / state.routeLength, 0, 0.99)
            else
                model.progress = clamp((sample.now - state.departedAt) / ride, 0, 0.99)
            end
            model.overrun = (sample.now - state.departedAt) > ride
            left = ride * (1 - model.progress)
        else
            model.phase = "waiting"
            model.progress = 0
        end
    else
        model.phase = "use"
    end

    for i = active.index + 1, #steps do left = left + steps[i].seconds end
    model.remaining = left
    if active.notice then
        active.noticeUntil = active.noticeUntil or (sample.now + NOTICE_TIME)
        if sample.now <= active.noticeUntil then model.notice = active.notice end
    end
    return model
end

-- ---------------------------------------------------------------------------------------

-- Begin following a plan (from Journey:PlanEntry) to a destination entry.
-- `notice` (optional) is a string key shown for a few seconds ("NAV_REROUTED").
-- A plan with legs (Journey:Legs: a round trip's way there and back, a tour's stops) is followed as one trip, leg after
-- leg. `legEnds` holds where each leg ends: the later legs' places are not looked for before then (the way back ends
-- where the player is now; a tour can pass a later stop on the way to an earlier one).
function Navigation:Start(entry, plan, notice)
    local steps, legs, legEnds, legOf = plan.steps, addon.Journey:Legs(plan), nil, nil
    if legs then
        steps, legEnds, legOf = {}, {}, {}
        for k, leg in ipairs(legs) do
            for _, step in ipairs(leg.steps) do
                steps[#steps + 1] = step
                legOf[#steps] = k
            end
            legEnds[k] = #steps
        end
        local joined = {}
        for key, v in pairs(plan) do joined[key] = v end
        joined.steps = steps
        plan = joined
    end
    -- Where steps end that are no nodes of ours: the waypoint, a tour's stops, the way back's end (Journey's returnDestination).
    local extra
    for _, place in ipairs(entry and addon.Journey:ExtrasOf(entry) or {}) do
        extra = extra or {}
        extra[place.id] = place
    end
    if plan.returnTo then
        extra = extra or {}
        extra["RETURN_" .. plan.returnTo.id] = plan.returnTo
    end
    active = { entry = entry, plan = plan, steps = steps, legs = legs, legEnds = legEnds, legOf = legOf, returnTo = plan.returnTo,
               index = 1, finished = false, jumped = false, notice = notice, extra = extra }
end

-- What the navigator's title says: where the trip goes, or for a tour the stop this leg goes to (the step count beside
-- it already says how far along the trip is).
destinationName = function()
    local entry = active.entry
    if active.legs and entry and entry.stops then
        local leg = active.legs[active.legOf[active.index] or #active.legs]
        return leg.name
    end
    return entry and entry.name
end

-- The rest of a tour from the leg the trip is on, as an entry to plan again (MultiRoute:Plan with `keep`): its stop
-- first, then the later legs as they were.
local function restOfTour()
    local entry = active.entry
    local k = active.legOf[active.index] or #active.legs
    local rest = { name = entry.name, stops = {}, keep = {}, holiday = entry.holiday }
    for i = k, #active.legs do
        local leg = active.legs[i]
        rest.stops[#rest.stops + 1] = leg.stop
        if i > k then rest.keep[#rest.keep + 1] = leg end
    end
    return rest
end

-- What to plan again from where the player is now, to carry on the trip: the destination entry (for a tour, the stops
-- still to come) and where a round trip goes back to. Nil when no trip is being followed. Leaves the trip as it is.
function Navigation:ReplanTarget()
    if not active or active.finished then return nil end
    local entry = active.entry
    if entry and entry.stops and active.legs then entry = restOfTour() end
    return entry, active.returnTo
end

-- A flight was chosen at a flight master: stops = the node ids the ticket lands at, the last being where
-- it ends (FlightKnowledge:StopsForSlot); now = GetTime(). It takes effect once the taxi is moving.
function Navigation:OnTakeTaxi(stops, now)
    if not active or active.finished or not stops or #stops == 0 then return end
    active.ticket = { stops = stops, at = now or 0 }
end

-- Where the trip flies to from a flight master (a node id, "TAXI_<id>"), for marking it on the flight map: the last
-- landing of the flights that leave fromID one after another (the game sells those as one ticket). Nil when the trip
-- has no flight from there still to come on this leg.
function Navigation:FlightTarget(fromID)
    if not active or active.finished or active.offRoute or not fromID then return nil end
    local last = lookAheadEnd()
    for i = active.index, last do
        local step = active.steps[i]
        if kindOf(step.method) == "flight" and step.fromID == fromID then
            local target = step.nodeID
            for k = i + 1, last do
                local after = active.steps[k]
                if kindOf(after.method) ~= "flight" or after.fromID ~= target then break end
                target = after.nodeID
            end
            return target
        end
    end
    return nil
end

-- The flight has begun. If it ends where a step of the route ends, that is the step being flown (the
-- ones before it, if any, were flown through, or are skipped); otherwise it is the wrong place, and the
-- route is worked out again on landing.
local function applyTicket(sample)
    local destination = active.ticket.stops[#active.ticket.stops]
    local match
    for i = active.index, lookAheadEnd() do
        if kindOf(active.steps[i].method) == "flight" and active.steps[i].nodeID == destination then
            match = i
            break
        end
    end
    if not match then
        active.offRoute = { destination = destination }
    elseif match > active.index then
        local seconds = 0
        for i = active.index, match do
            if kindOf(active.steps[i].method) == "flight" then seconds = seconds + active.steps[i].seconds end
        end
        local from = active.steps[active.index].fromID
        active.index = match
        beginStep(sample)
        active.state.seconds = seconds       -- one ticket over what were several steps
        active.state.fromID = from           -- and it began where the first of them did
    end
end

function Navigation:Stop()
    active = nil
end

function Navigation:IsActive()
    return active ~= nil
end

-- The latest model, or nil when no trip is being followed.
function Navigation:Model()
    return active and active.model
end

-- The player's last known spot, kept in one table for the whole trip.
local function remember(sample)
    if not sample.mapID then return end
    local last = active.last
    if not last then last = {}; active.last = last end
    last.mapID, last.x, last.y = sample.mapID, sample.x, sample.y
    if nowWorld then
        worldOfLast.x, worldOfLast.y, worldOfLast.continent = nowWorld.x, nowWorld.y, nowWorld.continent
        last.world = worldOfLast
    else
        last.world = nil
    end
end

local update

-- Feed a sample of the player. Returns the model (nil when no trip).
function Navigation:Update(sample)
    if not active then return nil end
    -- Project the sample once, for every distance this update measures from it (a client without the
    -- projection, or a sample it can't place, just leaves `world` nil and each distance projects for itself).
    nowSample, nowWorld = sample, nil
    if sample.mapID and C_Map and C_Map.GetWorldPosFromMapPos then
        local ok, continent, pos = pcall(C_Map.GetWorldPosFromMapPos, sample.mapID, CreateVector2D(sample.x, sample.y))
        if ok and pos then
            local x, y = pos:GetXY()
            worldOfNow.x, worldOfNow.y, worldOfNow.continent = x, y, continent
            nowWorld = worldOfNow
        end
    end
    local result = update(sample)
    nowSample, nowWorld = nil, nil          -- the sample may be changed before the next update
    return result
end

update = function(sample)
    if not active.finished then
        if not active.state then beginStep(sample) end

        if active.ticket then
            if sample.onTaxi then
                applyTicket(sample)
                active.ticket = nil
            elseif sample.now - active.ticket.at > TICKET_WAIT then
                active.ticket = nil              -- it never took off (no money, cancelled)
            end
        end

        if active.offRoute then
            if not sample.onTaxi then            -- landed somewhere the route didn't go: plan again from here
                local entry, returnTo = Navigation:ReplanTarget()
                active = nil
                return { replan = true, entry = entry, returnTo = returnTo }
            end
            remember(sample)
            active.model = buildModel(sample)
            active.model.offRoute, active.model.flyingTo = true, active.offRoute.destination
            return active.model
        end

        -- Already at a later step's destination: skip everything before it. (Not in the air: a flight
        -- passing over a later stop hasn't got there.) On the way, the yards to the next step's end, for `passed`.
        local was, toNext = active.index, nil
        if not sample.onTaxi then
            for j = lookAheadEnd(), active.index + 1, -1 do
                local there, d = arrived(active.steps[j], sample)
                if there then
                    active.index = j
                    beginStep(sample)
                    advance(sample)
                    break
                end
                if j == was + 1 then toNext = d end
            end
        end
        -- Did the player just appear somewhere far from where they were a moment ago?
        local jump = active.last and distance(active.last, place(jumpTo, sample))
        active.jumped = jump ~= nil and jump > JUMP
        -- No distance can be read between two maps the client won't put on one plane (a teleport into an interior:
        -- Bizmo's Brawlpub is its own map), but the map itself changing in one update is as good as a jump.
        if jump == nil and active.last and active.last.mapID and sample.mapID and sample.mapID ~= active.last.mapID then
            active.jumped = true
        end
        while not active.finished and completed(active.steps[active.index], sample) do
            advance(sample)
            active.jumped = false           -- one jump ends one step
        end
        -- Not there, but past it: the next step is the one to follow now. (Only for the step the distance was read for.)
        if not active.finished and active.index == was and passed(active.steps[was], toNext, sample) then
            advance(sample)
        end
    end
    remember(sample)
    active.model = buildModel(sample)
    return active.model
end

local function equipped(itemID)
    local f = addon.ItemFn("IsEquippedItem")
    return f ~= nil and f(itemID) and true or false
end

-- Where the player is right now, as a sample (needs the client).
function Navigation:Sample()
    local sample = { now = GetTime(), onTaxi = UnitOnTaxi and UnitOnTaxi("player") or false,
                     facing = GetPlayerFacing and GetPlayerFacing() or nil, equipped = equipped }
    local mapID = C_Map.GetBestMapForUnit("player")
    local pos = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
    if pos then
        local x, y = pos:GetXY()
        if x and not (x == 0 and y == 0) then
            sample.mapID, sample.x, sample.y = mapID, x, y
        end
    end
    return sample
end
