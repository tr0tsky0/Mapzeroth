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
--   portal     walk into it; done when the player arrives.
-- A step is done when the player is within a small radius of its destination (a landing or a
-- ship's arrival counts too; a teleport or portal also counts the moment the player is suddenly
-- somewhere else, since a bind point can be well away from the inn node we have for it). If they get to a later step's destination, the steps between are
-- skipped, and finishing the last step ends the trip.

local Navigation = {}
addon.Navigation = Navigation

local WALK_RADIUS = 30       -- yards
local ARRIVE_RADIUS = 60     -- yards, for everything that isn't walking: a landing spot is looser
local DEPART_RADIUS = 40     -- yards moved from the boarding point before a ship counts as underway
local JUMP = 300             -- yards between two updates that can only be a teleport or a portal
local TICKET_WAIT = 15       -- seconds a chosen flight has to start before we forget it was chosen
local NOTICE_TIME = 8        -- seconds a note ("Route updated") stays up

local KINDS = {
    walk = "walk", transition = "walk", taxi = "flight",
    ship = "transport", zeppelin = "transport", tram = "transport",
    teleport = "ability", hearthstone = "ability", portal = "portal",
}

local function kindOf(method)
    return KINDS[method] or "walk"
end

local active       -- the trip: { entry, plan, steps, index, state, finished, model }

-- A flight is timed from take-off to landing, a boat from leaving the dock to arriving (the plan's number
-- also includes waiting for it, so that comparison is only rough). Each measurement, { kind, from, to,
-- planned, actual } in seconds, goes to Navigation.onTiming if a tool has set one (MapzerothDataTools
-- does); nothing is kept or shown here.
local function report(record)
    if Navigation.onTiming then Navigation.onTiming(record) end
end

-- A node of ours, or the trip's own destination when it isn't one (the waypoint).
local function nodeOf(id)
    return id and (addon.World:GetNode(id) or (active and active.extra and active.extra[id]))
end

-- Yards from the sample to a node, or nil if we can't say.
local function distance(sample, node)
    if not (sample and sample.mapID and node and node.mapID) then return nil end
    return addon.TravelGraph.DistanceProvider(
        { id = "YOU_NOW", nocache = true, mapID = sample.mapID, x = sample.x, y = sample.y }, node)
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
local function yardsPerUnit(mapID)
    local here = { id = "SCALE_A", nocache = true, mapID = mapID, x = 0.5, y = 0.5 }
    local east = { id = "SCALE_B", nocache = true, mapID = mapID, x = 0.51, y = 0.5 }
    local south = { id = "SCALE_C", nocache = true, mapID = mapID, x = 0.5, y = 0.51 }
    local dx = addon.TravelGraph.DistanceProvider(here, east)
    local dy = addon.TravelGraph.DistanceProvider(here, south)
    if not (dx and dy) then return nil end
    return dx / 0.01, dy / 0.01
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

local function radiusOf(step)
    return kindOf(step.method) == "walk" and WALK_RADIUS or ARRIVE_RADIUS
end

local function arrived(step, sample)
    local d = distance(sample, nodeOf(step.nodeID))
    return d ~= nil and d <= radiusOf(step)
end

local function beginStep(sample)
    local step = active.steps[active.index]
    local node = nodeOf(step.nodeID)
    local state = { startedAt = sample.now, startDistance = distance(sample, node) }
    if kindOf(step.method) == "transport" then
        state.origin = nodeOf(step.fromID)
        state.routeLength = state.origin and node and addon.TravelGraph.DistanceProvider(state.origin, node)
    end
    active.state = state
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
                         planned = step.seconds, actual = sample.now - state.departedAt })
            end
            return true
        end
        return false
    end
    if kind == "ability" or kind == "portal" then
        return arrived(step, sample) or active.jumped == true
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
        destination = active.entry and active.entry.name,
    }
    local left = step.seconds
    if state.seconds then left = state.seconds end        -- a flight that covers several steps

    if kind == "walk" then
        model.distance = distance(sample, nodeOf(step.nodeID))
        model.heading = Navigation:Heading(sample, nodeOf(step.nodeID))
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
            local d = distance(sample, nodeOf(step.nodeID))
            if d and state.routeLength and state.routeLength > 0 then
                model.progress = clamp(1 - d / state.routeLength, 0, 0.99)
            else
                model.progress = clamp((sample.now - state.departedAt) / step.seconds, 0, 0.99)
            end
            model.overrun = (sample.now - state.departedAt) > step.seconds
            left = step.seconds * (1 - model.progress)
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
function Navigation:Start(entry, plan, notice)
    active = { entry = entry, plan = plan, steps = plan.steps, index = 1, finished = false, jumped = false,
               notice = notice, extra = entry and entry.dest and { [entry.dest.id] = entry.dest } or nil }
end

-- A flight was chosen at a flight master: stops = the node ids the ticket lands at, the last being where
-- it ends (FlightKnowledge:StopsForSlot); now = GetTime(). It takes effect once the taxi is moving.
function Navigation:OnTakeTaxi(stops, now)
    if not active or active.finished or not stops or #stops == 0 then return end
    active.ticket = { stops = stops, at = now or 0 }
end

-- The flight has begun. If it ends where a step of the route ends, that is the step being flown (the
-- ones before it, if any, were flown through, or are skipped); otherwise it is the wrong place, and the
-- route is worked out again on landing.
local function applyTicket(sample)
    local destination = active.ticket.stops[#active.ticket.stops]
    local match
    for i = active.index, #active.steps do
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

-- Feed a sample of the player. Returns the model (nil when no trip).
function Navigation:Update(sample)
    if not active then return nil end
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
                local entry = active.entry
                active = nil
                return { replan = true, entry = entry }
            end
            active.last = sample.mapID and { mapID = sample.mapID, x = sample.x, y = sample.y } or active.last
            active.model = buildModel(sample)
            active.model.offRoute, active.model.flyingTo = true, active.offRoute.destination
            return active.model
        end

        -- Already at a later step's destination: skip everything before it. (Not in the air: a flight
        -- passing over a later stop hasn't got there.)
        if not sample.onTaxi then
            for j = #active.steps, active.index + 1, -1 do
                if arrived(active.steps[j], sample) then
                    active.index = j
                    beginStep(sample)
                    advance(sample)
                    break
                end
            end
        end
        -- Did the player just appear somewhere far from where they were a moment ago?
        local jump = active.last and distance(active.last, { id = "JUMP", nocache = true, mapID = sample.mapID, x = sample.x, y = sample.y })
        active.jumped = jump ~= nil and jump > JUMP
        while not active.finished and completed(active.steps[active.index], sample) do
            advance(sample)
            active.jumped = false           -- one jump ends one step
        end
    end
    active.last = sample.mapID and { mapID = sample.mapID, x = sample.x, y = sample.y } or active.last
    active.model = buildModel(sample)
    return active.model
end

-- Where the player is right now, as a sample (needs the client).
function Navigation:Sample()
    local sample = { now = GetTime(), onTaxi = UnitOnTaxi and UnitOnTaxi("player") or false,
                     facing = GetPlayerFacing and GetPlayerFacing() or nil }
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
