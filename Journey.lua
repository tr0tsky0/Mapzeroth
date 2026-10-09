local addonName, addon = ...

-- Planning a trip from where the player stands, for the panel: a session holds the graph
-- and the cost of getting everywhere (so each search result can show a time), and a plan is
-- the route to one destination, as steps a person can read.

local Journey = {}
addon.Journey = Journey

local L = addon.L

-- "3m 54s", "45s", "1h 05m". `seconds` may be fractional.
function Journey:FormatTime(seconds)
    seconds = math.floor(seconds + 0.5)
    if seconds >= 3600 then
        return L["TIME_HOURS"]:format(math.floor(seconds / 3600), math.floor(seconds % 3600 / 60))
    elseif seconds >= 60 then
        return L["TIME_MINUTES"]:format(math.floor(seconds / 60), seconds % 60)
    end
    return L["TIME_SECONDS"]:format(seconds)
end

-- Builds the graph for this player from `start` (see TravelGraph:AddStart). Nothing is
-- priced yet: a plan searches for one destination, and Cost prices everywhere on first use.
-- Returns nil, "nowhere" if we have no nodes on the start's map.
-- graph.phase is the side the player is on in each phase group (World:LivePhases): where the start and the
-- extras sit on a map split between phases, and the state every search of this session starts from.
-- An extra marked `leave` (a stop of a tour) is also somewhere a leg starts from: it gets every way out the player's own
-- spot has, and the extras are joined to one another directly (walking, or flying where it's allowed).
function Journey:Build(ctx, start, extras)
    local graph = addon.TravelGraph:Build(ctx)
    graph.phase = addon.World:LivePhases(ctx.mapArtID)
    if not addon.TravelGraph:AddStart(graph, ctx, start) then return nil, "nowhere" end
    local linked = { start }                     -- the places a tour's stops are joined to directly
    for _, dest in ipairs(extras or {}) do
        if dest.leave then linked[#linked + 1] = dest end
    end
    for _, dest in ipairs(extras or {}) do
        addon.TravelGraph:AddDestination(graph, ctx, dest, start, dest.leave and linked or nil)
        if dest.leave then addon.TravelGraph:AddStart(graph, ctx, dest) end
    end
    return { ctx = ctx, start = start, graph = graph, extras = extras }
end

-- The places that aren't nodes of ours a destination entry needs in the graph: a waypoint, or a tour's stops.
function Journey:ExtrasOf(entry)
    if entry.stops then
        local places = {}
        for _, stop in ipairs(entry.stops) do
            if stop.place then places[#places + 1] = stop.place end
        end
        return places
    end
    return entry.dest and { entry.dest } or nil
end

-- (A session can be told, in `returnTo`, that a round trip's way back goes to somewhere other than where it starts.)

-- A flight costs its fare, and a route the player can't pay for isn't a route: with the player's money
-- known (ctx.money, copper) the search only takes routes whose flights it covers, and picks the
-- quickest of those. With no money known, fares are only reported.
-- `banned`: abilities not to use (a set keyed by Pathfinder.AbilityKey), when part of the trip has spent them.
local function searchOptions(session, budget, banned)
    return { fareFactor = session.ctx.fareFactor or 1, budget = budget, banned = banned }
end

local function banKey(banned)
    local keys = {}
    for key in pairs(banned or {}) do keys[#keys + 1] = tostring(key) end
    table.sort(keys)
    return table.concat(keys, ",")
end

local function costsFor(session, banned)
    session.costCache = session.costCache or {}
    local cacheKey = banKey(banned)
    if session.costCache[cacheKey] then return session.costCache[cacheKey] end
    local money = session.ctx.money
    local quickest, fares = addon.Pathfinder:FindCosts(session.graph, session.start.id, session.graph.phase, searchOptions(session, nil, banned))
    local result = quickest
    if money then
        -- The exact search that keeps every trade of time against fare is dearer, so it only runs when some
        -- place's quickest route is one the player can't pay for (and then covers the whole map at once).
        for _, fare in pairs(fares) do
            if fare > money then
                result = addon.Pathfinder:FindCosts(session.graph, session.start.id, session.graph.phase, searchOptions(session, money, banned))
                break
            end
        end
    end
    session.costCache[cacheKey] = result
    return result
end

local function costs(session)
    return costsFor(session, nil)
end

-- Tests only.
-- Seconds to reach a node, or nil if it can't be reached.
function Journey:Cost(session, nodeID)
    return costs(session)[nodeID]
end

local function goalsOf(entry)
    return entry.nodeIDs or { entry.nodeID }
end

-- The cheapest of several nodes to reach, and its cost ("nearest ley line").
function Journey:Nearest(session, nodeIDs)
    local best, bestCost
    for _, id in ipairs(nodeIDs) do
        local cost = costs(session)[id]
        if cost and (not bestCost or cost < bestCost) then best, bestCost = id, cost end
    end
    return best, bestCost
end

-- The route there and back. "Back" is to where the player stands now (a destination added to the graph the
-- first time it is needed). An ability with a cooldown (the hearthstone) is spent by whichever leg uses it, so
-- the other can't: every split of those abilities between the two legs is tried, and the quickest total wins.
local function returnDestination(session)
    if session.returnID == nil then
        -- Where the way back ends: where the player started, or (a trip planned again part way) where it first began.
        local home = session.returnTo or session.start
        local dest = { id = "RETURN_" .. home.id, mapID = home.mapID, x = home.x, y = home.y }
        session.returnID = addon.TravelGraph:AddDestination(session.graph, session.ctx, dest, session.start) and dest.id or false
    end
    return session.returnID or nil
end

-- The abilities usable from anywhere that the trip can only use once: a cooldown longer than REUSABLE_COOLDOWN, or a
-- consumable.
local function spentOnce(session)
    local keys, seen = {}, {}
    for _, ability in ipairs(session.graph.anywhere or {}) do
        local key = addon.Pathfinder.AbilityKey(ability.source)
        local spent = ability.source.consumable or (ability.source.cooldown or 0) > addon.REUSABLE_COOLDOWN
        if key and spent and not seen[key] then
            seen[key] = true
            keys[#keys + 1] = key
        end
    end
    table.sort(keys)
    return keys
end

function Journey:OneUseAbilities(session)
    return spentOnce(session)
end

-- Seconds from a place back to where the player started, without the `banned` abilities; nil if there's no way.
local function backCost(session, fromID, returnID, banned)
    session.backCache = session.backCache or {}
    local cacheKey = fromID .. "|" .. banKey(banned)
    local cached = session.backCache[cacheKey]
    if cached ~= nil then return cached or nil end
    local graph, money = session.graph, session.ctx.money
    local path = addon.Pathfinder:FindPath(graph, fromID, returnID, graph.phase, searchOptions(session, nil, banned))
    if path and money and path.fare > money then
        path = addon.Pathfinder:FindPath(graph, fromID, returnID, graph.phase, searchOptions(session, money, banned)) or path
    end
    session.backCache[cacheKey] = path and path.cost or false
    return path and path.cost or nil
end

-- The place among `nodeIDs` with the quickest round trip: { nodeID, out, back, total, banned, backBanned } (`banned`: the
-- abilities the way there must leave alone, `backBanned` those the way back must, for planning each leg), or nil when none can be reached and left again.
function Journey:RoundTrip(session, nodeIDs)
    local returnID = returnDestination(session)
    if not returnID then return nil end
    local keys = spentOnce(session)
    -- Each way of dividing the one-use abilities: bit i set means the way there uses key i, so the way back can't.
    local splits = {}
    for mask = 0, 2 ^ #keys - 1 do
        local there, back = {}, {}
        for i, key in ipairs(keys) do
            if math.floor(mask / 2 ^ (i - 1)) % 2 == 1 then back[key] = true else there[key] = true end
        end
        splits[#splits + 1] = { there = there, back = back }
    end
    -- Quickest to reach first: a place whose one-way time alone is no better than the best total can't win.
    local order, free = {}, costs(session)
    for _, id in ipairs(nodeIDs) do
        if free[id] then order[#order + 1] = { id = id, floor = free[id] } end
    end
    table.sort(order, function(a, b) return a.floor < b.floor end)
    local best
    for _, candidate in ipairs(order) do
        if best and candidate.floor >= best.total then break end
        for _, split in ipairs(splits) do
            local out = costsFor(session, split.there)[candidate.id]
            if out and (not best or out < best.total) then
                local back = backCost(session, candidate.id, returnID, split.back)
                if back and (not best or out + back < best.total) then
                    best = { nodeID = candidate.id, out = out, back = back, total = out + back, banned = split.there, backBanned = split.back }
                end
            end
        end
    end
    return best
end

-- The client's name for the spell or item an ability step uses, and which it is ("spell" / "item"), or
-- nil when it has none or the client hasn't loaded it yet (an item's name can take a moment: the request
-- is made, and the text says where the step goes instead until it arrives).
local function abilityName(source)
    if type(source) ~= "table" then return nil end
    if source.itemID then
        local name = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(source.itemID)
        if not name and type(GetItemInfo) == "function" then name = GetItemInfo(source.itemID) end
        if not name and C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(source.itemID) end
        return name, "item"
    end
    if source.spellID then
        local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(source.spellID)
        return info and info.name, "spell"
    end
end

-- The client's name for the spell or item an ability source uses (and "spell" / "item"), or nil. Also for the navigator.
function addon:GetAbilityLabel(source)
    return abilityName(source)
end

-- Steps that are the player using something of their own (addon.METHODS' `ability`): "Cast Path of the Devoted
-- Magistry", "Use Personal Key to the Arcantina", named for the spell or item rather than for where it lands.

local function stepText(method, name, via, source)
    if method == "equip" then
        local label = abilityName(source)
        return L["STEP_EQUIP_ITEM"]:format(label or name)
    end
    if via and #via > 0 then
        return L["STEP_TAXI_VIA"]:format(name, table.concat(via, ", "))
    end
    if addon:Method(method).ability then
        local label, kind = abilityName(source)
        if label and label ~= "" then
            -- One with a choice of landings (Mole Machine, the wormhole generators) says which to pick.
            if type(source) == "table" and source.toList and name then
                return L[kind == "item" and "STEP_USE_ITEM_TO" or "STEP_CAST_TO"]:format(label, name)
            end
            return L[kind == "item" and "STEP_USE_ITEM" or "STEP_CAST"]:format(label)
        end
    end
    local key = "STEP_" .. tostring(method):upper()
    return (addon:HasString(key) and L[key] or L["STEP_OTHER"]):format(name)
end

-- The route as a person reads it: one entry per leg, walking legs merged.
local TRIVIAL_WALK = 4     -- seconds: a walk this short is standing where you already are

-- Where a node id is, as { mapID, x, y }: one of our nodes, or the trip's own start or extra destination.
local function pointOf(session, id)
    local node = addon.World:GetNode(id)
    if not node and session then
        if session.start and (session.start.id == id or session.returnID == id) then node = session.start end
        for _, extra in ipairs(session.extras or {}) do
            if extra.id == id then node = extra end
        end
        for _, place in ipairs(session.ctx and addon:OwnPlaces(session.ctx) or {}) do   -- the bound spot, the camp
            if place.id == id then node = place end
        end
    end
    return node and { mapID = node.mapID, x = node.x, y = node.y } or nil
end

local function readableSteps(result, session)
    -- The place a round trip ends is where the player started, which has no node name.
    local function nameOf(id)
        if session and session.returnID == id then return L["PLACE_START"] end
        for _, extra in ipairs(session and session.extras or {}) do      -- a tour's stop has the name it was given
            if extra.id == id and extra.name then return extra.name end
        end
        return addon:GetNodeName(id)
    end
    local steps = {}
    local legs = addon.Pathfinder:CollapseSteps(result.steps)
    for _, step in ipairs(legs) do
        if not (step.method == "walk" and step.cost < TRIVIAL_WALK and #legs > 1) then
            -- A portal node is named for where it leads, so the step names the one you take
            -- (where you stand), not the one you come out of.
            -- A portal we have a name for is named for where it leads (Forever's "Stormwind Portal");
            -- one we only know by its map (Modern's) is described by where you come out.
            -- A "transition" (walking through Rut'theran's gate into Darnassus) reads the same way, as using the
            -- gate you stand at, so it isn't mistaken for another walk ("Go to Gate to Rut'theran Village").
            local usesPortal = step.method == "portal" or step.method == "transition"
            local ownName = usesPortal and addon:HasNodeName(step.from)
            local name = ownName and addon:GetNodeName(step.from) or nameOf(step.to)
            -- A flight ticket that passes through other flight points names them.
            local via
            if step.method == "taxi" and #step.parts > 1 then
                via = {}
                for i = 1, #step.parts - 1 do via[#via + 1] = nameOf(step.parts[i].to) end
            end
            -- The points it goes through, for drawing it on the map: where it starts, each stop it passes
            -- (the nodes a merged walk or a through-ticket is made of), and where it ends.
            local path = {}
            local function add(id)
                local point = pointOf(session, id)
                if point then path[#path + 1] = point end
            end
            add(step.from)
            if step.method == "fly" then
                add(step.to)            -- the player's own flight goes straight there: its hops are only how the search got there
            else
                for _, part in ipairs(step.parts or {}) do add(part.to) end
            end
            -- Using an item that must be worn first is two steps: put it on (priced at its equip cooldown), then use it.
            local seconds = step.cost
            local wait = step.source and step.source.equipSeconds
            if wait then
                steps[#steps + 1] = {
                    method = "equip", nodeID = step.from, fromID = step.from, source = step.source,
                    seconds = wait, name = name, path = {}, text = stepText("equip", name, nil, step.source),
                }
                seconds = step.cost - wait
            end
            steps[#steps + 1] = {
                method = step.method, nodeID = step.to, fromID = step.from, source = step.source,
                iconSource = step.iconSource,
                seconds = seconds, name = name, via = via, path = path,
                text = (step.method == "portal" and not ownName)
                    and L["STEP_PORTAL_TO"]:format(name)
                    or stepText(ownName and "portal" or step.method, name, via, step.source),
                approx = step.method == "walk",     -- a walk is an estimate
            }
        end
    end
    return steps
end

-- The route with no rule about found flight points (the flights we can't use allowed), or nil.
local function freeRoute(session, goalID)
    local ctx = session.ctx
    local anyFlight = addon.FlightKnowledge.AnyFlight
    if ctx.flightUsable == anyFlight then return nil end     -- already the free route
    local free = {}
    for k, v in pairs(ctx) do free[k] = v end
    free.flightUsable = anyFlight
    session.free = session.free or Journey:Build(free, session.start, session.extras)
    if not session.free then return nil end
    return addon.Pathfinder:FindPath(session.free.graph, session.start.id, goalID, session.free.graph.phase)
end

-- The first flight on a route that this player isn't known to be able to take: { nodeID, name, known }
-- (known: a flight master's window said it isn't found; otherwise we just haven't looked), or nil.
local function unusableFlight(ctx, result)
    for _, step in ipairs(result.steps) do
        if step.method == "taxi" and not ctx.flightUsable(step.to) then
            return { nodeID = step.to, name = addon:GetNodeName(step.to), known = ctx.flightNodeFound(step.to) == false }
        end
    end
end

-- With no rule about found flight points, would a flight we can't use get there faster?
-- Then say which point would help, and by how much.
local function flightHint(session, goalID, plan)
    local result = freeRoute(session, goalID)
    if not result or result.cost + 1 >= plan.cost then return nil end
    local hint = unusableFlight(session.ctx, result)
    if hint then hint.saves = plan.cost - result.cost end
    return hint
end

-- No route at all: is it only because of a flight we can't be sure this player can take? Then say so,
-- rather than a bare "no route" ({ nodeID, name, known }, no `saves`: there is no route to save time on).
local function missingFlightHint(session, goalID)
    local result = freeRoute(session, goalID)
    return result and unusableFlight(session.ctx, result) or nil
end

-- The route to goalID (a node id, or a list of them for the nearest): { cost, goal (the
-- node reached), fare (copper the flights cost), steps = {{method, nodeID, seconds, name, text,
-- approx}}, hint = {nodeID, name, saves, known} or nil }. With the player's money known, it is the
-- quickest route they can pay for: `quickest` = { fare, saves } if a dearer route would be quicker,
-- and `unaffordable` if no route is within their means (then it is the cheapest there is).
-- Returns nil if there is no way there (and, second, a hint like `hint` when a flight this player may not
-- have found is all that stands in the way).
-- `banned`: abilities to leave out (the way there of a round trip leaves some for the way back). `backBanned`: given for
-- a round trip (a set, empty for none): the plan then also has `back` = { cost, steps }, the way from the place it
-- reaches to where the player started, without those abilities.
-- The search for one leg, fromID to goalID: the quickest route, and the quickest the player can pay for (the same
-- one unless the quickest's fares are more than their money; nil when nothing is within it). Nil when there's no way.
local function searchLeg(session, fromID, goalID, banned)
    local graph, money = session.graph, session.ctx.money
    local fastest = addon.Pathfinder:FindPath(graph, fromID, goalID, graph.phase, searchOptions(session, nil, banned))
    if not fastest then return nil end
    if money and fastest.fare > money then
        return fastest, addon.Pathfinder:FindPath(graph, fromID, goalID, graph.phase, searchOptions(session, money, banned))
    end
    return fastest, fastest
end

-- Flights a route takes on the strength of the "assume found" setting (no flight master's window has said either
-- way), added to `list` by name; returns the list, or nil when there are none.
local function assumedFlights(ctx, raw, list)
    for _, step in ipairs(raw) do
        if step.method == "taxi" and ctx.flightNodeFound(step.to) == nil then
            list = list or {}
            table.insert(list, addon:GetNodeName(step.to))
        end
    end
    return list
end

-- One leg of a longer trip (a tour's way from one stop to the next): { cost, fare, steps (readable), raw, goal,
-- unaffordable }, the quickest the player can pay for (else the quickest there is), or nil when there's no way.
function Journey:PlanLeg(session, fromID, goalID, banned)
    local fastest, chosen = searchLeg(session, fromID, goalID, banned)
    local result = chosen or fastest
    if not result then return nil end
    return { cost = result.cost, fare = result.fare, steps = readableSteps(result, session), raw = result.steps,
             goal = result.goal, unaffordable = not chosen or nil }
end

-- Flights a list of raw steps takes on the "assume found" setting, added to `list` (or a new one); nil for none.
function Journey:AssumedFlights(ctx, raw, list)
    return assumedFlights(ctx, raw, list)
end

-- The legs a plan is followed and shown in, or nil for a plan to one place: a tour's own (plan.legs), or a round
-- trip's way there and way back. Each is { cost, fare, steps, heading (text over it in the list, or nil), name }.
function Journey:Legs(plan)
    if not plan then return nil end
    if plan.legs then return plan.legs end
    if plan.back then
        return {
            { cost = plan.cost, fare = plan.fare, steps = plan.steps },
            { cost = plan.back.cost, fare = plan.back.fare, steps = plan.back.steps, heading = L["ROUTE_BACK_HEADING"] },
        }
    end
end

function Journey:Plan(session, goalID, banned, backBanned)
    local money = session.ctx.money
    local fastest, chosen = searchLeg(session, session.start.id, goalID, banned)
    if not fastest then return nil, missingFlightHint(session, goalID) end
    local result = chosen or fastest
    local plan = { cost = result.cost, steps = readableSteps(result, session), goal = result.goal,
                   raw = result.steps,                        -- the search's own steps, before merging: for diagnostics
                   fare = result.fare, money = money }
    if not chosen then
        plan.unaffordable = true                           -- no way there within their means: show the quickest anyway
    elseif chosen ~= fastest and fastest.cost + 1 < chosen.cost then
        plan.quickest = { fare = fastest.fare, saves = chosen.cost - fastest.cost }
    end
    plan.hint = flightHint(session, goalID, plan)
    local returnID = backBanned and returnDestination(session)
    if returnID then
        plan.returnTo = session.returnTo or session.start      -- kept if the trip is planned again part way
        local fastestBack, chosenBack = searchLeg(session, plan.goal, returnID, backBanned)
        local back = chosenBack or fastestBack
        if back then plan.back = { cost = back.cost, steps = readableSteps(back, session), fare = back.fare } end
    end
    plan.assumed = assumedFlights(session.ctx, plan.raw)
    return plan
end

-- `yield` (optional): called between searches, so a long plan (a tour, MultiRoute.lua) can be spread over several
-- frames (MultiRoute:Run); a plan to one place ignores it.
function Journey:PlanEntry(session, entry, yield)
    if entry.stops then return addon.MultiRoute:Plan(session, entry, yield) end
    return self:Plan(session, goalsOf(entry), entry.banned, entry.backBanned)       -- the plan, or nil and a hint about a missing flight
end

-- A round trip to an entry: to whichever of its places has the quickest way there and back to where the player stands,
-- the one-use abilities split between the two ways (RoundTrip). Returns the plan (with `back`) and the entry it was
-- planned for: that one place and the abilities each way leaves alone, so the trip can be planned again part way
-- (Navigation). Nil when no place can be reached and left again.
function Journey:PlanRoundTrip(session, entry)
    local best = self:RoundTrip(session, goalsOf(entry))
    if not best then return nil end
    local trip = {}
    for k, v in pairs(entry) do trip[k] = v end
    trip.nodeID, trip.nodeIDs, trip.banned, trip.backBanned = best.nodeID, { best.nodeID }, best.banned, best.backBanned
    local plan = self:Plan(session, trip.nodeIDs, trip.banned, trip.backBanned)
    return plan, plan and trip or nil
end

-- "1g 20s 5c" for an amount in copper.
function Journey:FormatMoney(copper)
    copper = math.floor((copper or 0) + 0.5)
    local gold, silver, rest = math.floor(copper / 10000), math.floor(copper % 10000 / 100), copper % 100
    local parts = {}
    if gold > 0 then parts[#parts + 1] = L["MONEY_GOLD"]:format(gold) end
    if silver > 0 then parts[#parts + 1] = L["MONEY_SILVER"]:format(silver) end
    if rest > 0 or #parts == 0 then parts[#parts + 1] = L["MONEY_COPPER"]:format(rest) end
    return table.concat(parts, " ")
end

-- What a plan says about its fares beyond the total: that it can't be paid for, or that it is not the
-- quickest way because that costs more than the player has. Nil when there is nothing to say.
function Journey:FareText(plan)
    if not plan then return nil end
    if plan.unaffordable then
        return L["HINT_BROKE"]:format(self:FormatMoney(plan.fare), self:FormatMoney(plan.money))
    end
    if plan.quickest then
        return L["HINT_QUICKER"]:format(self:FormatTime(plan.quickest.saves), self:FormatMoney(plan.quickest.fare))
    end
end

-- The route to a destination entry from where the player is now (nil if there is none).
function Journey:PlanFromHere(entry, returnTo)
    local start = addon:GetPlayerStart()
    local session = start and self:Build(addon:GetPlayerContext(), start, self:ExtrasOf(entry))
    if session then session.returnTo = returnTo end
    return session and self:PlanEntry(session, entry) or nil
end

-- A line for a route that flies to points nobody has confirmed the player found, or nil.
function Journey:AssumedText(plan)
    if not (plan and plan.assumed and #plan.assumed > 0) then return nil end
    return L["HINT_ASSUMED"]:format(table.concat(plan.assumed, ", "))
end

-- The sentence for a hint, in our own words around the client's names.
function Journey:HintText(hint)
    if not hint then return nil end
    if not hint.saves then                          -- no route at all without it
        if hint.known then return L["HINT_ONLY_FLIGHT_UNFOUND"]:format(hint.name) end
        return L["HINT_ONLY_FLIGHT_UNKNOWN"]
    end
    if hint.known then
        return L["HINT_UNFOUND"]:format(hint.name, self:FormatTime(hint.saves))
    end
    return L["HINT_UNKNOWN"]:format(self:FormatTime(hint.saves))
end
