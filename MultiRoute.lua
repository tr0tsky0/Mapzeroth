local addonName, addon = ...

-- A tour: several places to visit, in whichever order is quickest (a round of pet tamers for an achievement).
-- The entry is { name, stops = { stop, ... } }, a stop being { name, place = { id, mapID, x, y, name, leave = true } }
-- for a spot that isn't one of our nodes (a /way point), or { name, nodeID } for one that is. Journey:PlanEntry
-- hands an entry with stops to MultiRoute:Plan.
--
-- How it is planned:
--   1. The time from the start and from every stop to every other stop: one search from each (FindCosts prices
--      everywhere at once), with the abilities a trip can use only once (the hearthstone) left out, so the order
--      doesn't lean on something only one leg can have.
--   2. The quickest order to visit them all, ending at whichever stop comes last (no way back): exact up to
--      EXACT_LIMIT stops, a good one (nearest first, then improved by moves) beyond.
--   3. The one-use abilities brought in: what each would make of a leg (its cast, then the way from where it lands
--      to the stop: guessed from the way back, then searched for real for the landings the plan takes), and the order improved by
--      moves (two stops swapped, one moved, a stretch turned round) priced with them, each given to at most one leg
--      (Path of the Windrunners to EPL, then fly on to the Hinterlands, not the Hinterlands first and back).
--   4. Each leg planned in that order, from the stop before, by the same search as a trip to one place
--      (Journey:PlanLeg), with the one-use ability step 3 gave it, if any, and no other.
-- A stop no route reaches is left out and named in plan.dropped.
--
-- The plan is a Journey plan with legs: { cost, fare, steps (every leg's in a row), legs = { { name, cost, fare,
-- steps, heading, stop } }, goal, raw, dropped, assumed, unaffordable }. Navigation and the panel follow and list
-- it leg by leg (Journey:Legs).

local MultiRoute = {}
addon.MultiRoute = MultiRoute

local L = addon.L

local EXACT_LIMIT = 12      -- stops: the exact order's work grows as 2^n * n^2 (12 stops: about 600,000 steps)
local OPTIONS_PER_STOP = 4  -- one-use abilities weighed for each stop when ordering: the quickest few (MultiRoute.Options)
local MAX_BOOSTS = 20       -- landings of one-use abilities searched from for real (the rest are guessed): see Plan
local INF = math.huge

-- ---------------------------------------------------------------------------------------
-- The order.

-- cost(i, j): seconds from i to j, i = 0 the start, 1..n the stops; INF when there's no way.

local function pathCost(cost, order)
    local total, from = 0, 0
    for _, k in ipairs(order) do
        total = total + cost(from, k)
        from = k
    end
    return total
end

-- Exact: the quickest order over every subset of stops (Held-Karp). best[mask][j] is the quickest way from the start
-- through the stops in `mask` ending at j.
local function exactOrder(cost, n)
    local pow = {}
    for i = 1, n do pow[i] = 2 ^ (i - 1) end
    local function has(mask, i) return math.floor(mask / pow[i]) % 2 == 1 end
    local full = 2 ^ n - 1
    local best, prev = {}, {}
    for j = 1, n do
        best[pow[j] * 32 + j] = cost(0, j)
    end
    for mask = 1, full do
        for j = 1, n do
            local here = best[mask * 32 + j]
            if here and here < INF then
                for k = 1, n do
                    if not has(mask, k) then
                        local key = (mask + pow[k]) * 32 + k
                        local d = here + cost(j, k)
                        if d < (best[key] or INF) then
                            best[key], prev[key] = d, j
                        end
                    end
                end
            end
        end
    end
    local last, total = nil, INF
    for j = 1, n do
        local d = best[full * 32 + j]
        if d and d < total then last, total = j, d end
    end
    if not last then return nil end
    local order, mask = {}, full
    while last do
        table.insert(order, 1, last)
        local before = prev[mask * 32 + last]
        mask = mask - pow[last]
        last = before
    end
    return order, total
end

-- A good order for many stops: nearest first, then improved until no single move helps -- turning a stretch of the
-- tour round (2-opt), or taking one stop out and putting it somewhere else. yield() between rounds of moves.
local function heuristicOrder(cost, n, yield)
    local order, used, from = {}, {}, 0
    for _ = 1, n do
        local pick, pickCost
        for k = 1, n do
            if not used[k] and (not pickCost or cost(from, k) < pickCost) then pick, pickCost = k, cost(from, k) end
        end
        used[pick] = true
        order[#order + 1] = pick
        from = pick
    end
    local total = pathCost(cost, order)
    local improved, passes = true, 0
    while improved and passes < 50 do
        improved, passes = false, passes + 1
        for i = 1, n - 1 do
            for j = i + 1, n do
                local trial = {}
                for k = 1, i - 1 do trial[#trial + 1] = order[k] end
                for k = j, i, -1 do trial[#trial + 1] = order[k] end
                for k = j + 1, n do trial[#trial + 1] = order[k] end
                local t = pathCost(cost, trial)
                if t < total then order, total, improved = trial, t, true end
            end
            yield()
        end
        for i = 1, n do
            for j = 1, n do
                if i ~= j then
                    local trial = {}
                    for k = 1, n do if k ~= i then trial[#trial + 1] = order[k] end end
                    table.insert(trial, j, order[i])
                    local t = pathCost(cost, trial)
                    if t < total then order, total, improved = trial, t, true end
                end
            end
            yield()
        end
    end
    return order, total
end

-- Improves an order by single moves until none helps: two stops swapped, one moved elsewhere, a stretch turned round.
-- price(order) is what an order costs (anything: here, the legs with the one-use abilities given out). yield()
-- (optional) between rounds of moves.
function MultiRoute.Improve(order, price, yield)
    yield = yield or function() end
    local n = #order
    local best = price(order)
    local function try(trial)
        local t = price(trial)
        if t < best - 1e-9 then
            order, best = trial, t
            return true
        end
    end
    local improved, passes = true, 0
    while improved and passes < 50 do
        improved, passes = false, passes + 1
        for i = 1, n - 1 do
            for j = i + 1, n do
                local swapped = {}
                for k = 1, n do swapped[k] = order[k] end
                swapped[i], swapped[j] = swapped[j], swapped[i]
                if try(swapped) then improved = true end
                local turned = {}
                for k = 1, i - 1 do turned[#turned + 1] = order[k] end
                for k = j, i, -1 do turned[#turned + 1] = order[k] end
                for k = j + 1, n do turned[#turned + 1] = order[k] end
                if try(turned) then improved = true end
            end
            yield()
        end
        for i = 1, n do
            for j = 1, n do
                if i ~= j then
                    local moved = {}
                    for k = 1, n do if k ~= i then moved[#moved + 1] = order[k] end end
                    table.insert(moved, j, order[i])
                    if try(moved) then improved = true end
                end
            end
            yield()
        end
    end
    return order, best
end

-- Gives one-use abilities to the legs of an order, each ability to one leg at most and each leg one at most, the
-- biggest saving first. legCost(from, to) is a leg without them; options[to] the quickest ways to stop `to` by an
-- ability, { { a, seconds }, ... } quickest first (MultiRoute.Options: a few per stop, as only those can win). Returns
-- the total and { [leg number] = a }. Called for every order tried, so it is kept to a few steps a leg.
function MultiRoute.Assign(order, legCost, options)
    local total, saves = 0, {}
    local from = 0
    for k, to in ipairs(order) do
        local base = legCost(from, to)
        total = total + base
        for _, option in ipairs(options[to] or {}) do
            if option[2] >= base then break end
            saves[#saves + 1] = { gain = base - option[2], leg = k, a = option[1] }
        end
        from = to
    end
    table.sort(saves, function(x, y) return x.gain > y.gain end)
    local given, usedLeg = {}, {}
    local usedAbility = {}
    for _, save in ipairs(saves) do
        if not usedLeg[save.leg] and not usedAbility[save.a] then
            usedLeg[save.leg], usedAbility[save.a] = true, true
            given[save.leg] = save.a
            total = total - save.gain
        end
    end
    return total, given
end

-- options[stop] for Assign from land[a][stop] (seconds to that stop by ability a): its `keep` quickest, sorted.
function MultiRoute.Options(land, keep)
    local options = {}
    for a, row in pairs(land) do
        for stop, t in pairs(row) do
            options[stop] = options[stop] or {}
            table.insert(options[stop], { a, t })
        end
    end
    for _, list in pairs(options) do
        table.sort(list, function(x, y) return x[2] < y[2] end)
        for i = #list, (keep or #list) + 1, -1 do list[i] = nil end
    end
    return options
end

-- The quickest order to visit stops 1..n from the start (0): a list of stop numbers and its seconds, or nil when
-- no order reaches them all. `cost` is a function (i, j) or a table cost[i][j] (nil for no way). yield (optional): as
-- for Plan.
function MultiRoute.Order(cost, n, yield)
    yield = yield or function() end
    if type(cost) == "table" then
        local t = cost
        cost = function(i, j) return (t[i] and t[i][j]) or INF end
    end
    if n == 0 then return {}, 0 end
    local order, total
    if n <= EXACT_LIMIT then
        order, total = exactOrder(cost, n)
    else
        order, total = heuristicOrder(cost, n, yield)
    end
    if not order or total == INF then return nil end
    return order, total
end

-- ---------------------------------------------------------------------------------------
-- The plan.

local function stopID(stop)
    return stop.place and stop.place.id or stop.nodeID
end

local function heading(number, leg)
    return L["ROUTE_STOP_HEADING"]:format(number, leg.name)
end

-- Puts a tour's legs together as one plan.
local function assemble(session, legs, dropped)
    local Journey = addon.Journey
    local plan = { cost = 0, fare = 0, steps = {}, raw = {}, legs = legs, dropped = dropped, money = session.ctx.money }
    for _, leg in ipairs(legs) do
        plan.cost = plan.cost + leg.cost
        plan.fare = plan.fare + (leg.fare or 0)
        for _, step in ipairs(leg.steps) do plan.steps[#plan.steps + 1] = step end
        for _, step in ipairs(leg.raw or {}) do plan.raw[#plan.raw + 1] = step end
        if leg.unaffordable then plan.unaffordable = true end
        plan.goal = leg.goal
    end
    plan.assumed = Journey:AssumedFlights(session.ctx, plan.raw)
    return plan
end

-- Marks the one-use abilities a leg took as spent.
local function spend(spent, oneUse, leg)
    for _, step in ipairs(leg.raw or {}) do
        local key = step.source and addon.Pathfinder.AbilityKey(step.source)
        if key and oneUse[key] then spent[key] = true end
    end
end

local function copy(set)
    local out = {}
    for k, v in pairs(set) do out[k] = v end
    return out
end

-- The tour for `entry` from where the session starts: a plan with legs (see the top of the file), or nil when no
-- stop can be reached. `yield` (optional) is called between searches (MultiRoute:Run spreads them over frames).
-- An entry with `keep` (Navigation, planning the rest of a tour again from where a flight went astray) has its order
-- and its later legs already: only the way to its first stop is searched, and those legs follow it as they were.
function MultiRoute:Plan(session, entry, yield)
    yield = yield or function() end
    local Journey, Pathfinder = addon.Journey, addon.Pathfinder
    local graph = session.graph
    local oneUse = {}
    for _, key in ipairs(Journey:OneUseAbilities(session)) do oneUse[key] = true end

    if entry.keep then
        local first = entry.stops[1]
        local later = {}                  -- what the kept legs spend, which the way to the first stop must leave them
        for _, leg in ipairs(entry.keep) do spend(later, oneUse, leg) end
        local leg = first and Journey:PlanLeg(session, session.start.id, stopID(first), later)
        if not leg then return nil end
        leg.name, leg.stop = first.name, first
        leg.heading = heading(first.number or 1, leg)
        local legs = { leg }
        for _, kept in ipairs(entry.keep) do legs[#legs + 1] = kept end
        return assemble(session, legs, {})
    end

    -- 1. The time between every two places, without the one-use abilities. Each search stops once it has priced every
    -- stop (Pathfinder:FindCosts' targets): the rest of the world is no part of the tour.
    local opts = { fareFactor = session.ctx.fareFactor or 1, banned = oneUse }
    local targets = {}
    for _, stop in ipairs(entry.stops) do targets[stopID(stop)] = true end
    local fromStart = Pathfinder:FindCosts(graph, session.start.id, graph.phase, opts, targets)
    yield()
    local stops, dropped = {}, {}
    for _, name in ipairs(entry.unplaced or {}) do dropped[#dropped + 1] = name end
    for _, stop in ipairs(entry.stops) do
        if fromStart[stopID(stop)] then stops[#stops + 1] = stop else dropped[#dropped + 1] = stop.name end
    end
    if #stops == 0 then return nil end
    targets = {}                                      -- a stop nothing reaches would make every search the whole world
    for _, stop in ipairs(stops) do targets[stopID(stop)] = true end
    local rows = { [0] = fromStart }
    for i, stop in ipairs(stops) do
        -- Out to the farthest stop, and at least as far as the way here from the start: a one-use ability landing
        -- within that can shorten a leg into this stop (the way back from here to it stands in for the way there).
        rows[i] = Pathfinder:FindCosts(graph, stopID(stop), graph.phase, opts, targets, fromStart[stopID(stop)])
        yield()
    end
    local function cost(i, j)
        return rows[i][stopID(stops[j])] or INF
    end

    -- 2. The order. A stop the others can't be reached from (or reach) makes every order impossible: leave out the
    -- one with the fewest ways in or out until an order exists.
    local order = MultiRoute.Order(cost, #stops, yield)
    while not order and #stops > 1 do
        local worst, worstLinks
        for i = 1, #stops do
            local links = 0
            for j = 1, #stops do
                if i ~= j and cost(i, j) < INF then links = links + 1 end
                if i ~= j and cost(j, i) < INF then links = links + 1 end
            end
            if not worstLinks or links < worstLinks then worst, worstLinks = i, links end
        end
        dropped[#dropped + 1] = stops[worst].name
        table.remove(stops, worst)
        table.remove(rows, worst)
        order = MultiRoute.Order(cost, #stops, yield)
    end
    if not order then return nil end
    yield()

    -- 3. The one-use abilities: where each lands (graph.anywhere: one entry per landing, an ability with a choice of
    -- landings having several: Mole Machine has twenty) and its cast. The way on from a landing to a stop is first
    -- guessed from the way back (rows[stop] already prices every landing; most travel is the same both ways), so the
    -- order can be improved and the abilities given out without a search more. Only a landing that is actually given
    -- to a leg is then searched from, for real, and the order improved again with what that search found, until the
    -- landings given out are all known for real (or MAX_BOOSTS searches have been made). A landing no stop leads back
    -- to (the bound spot, the camp) has no guess, so it is searched from first.
    local landings = {}                               -- { key, to, cost, guess = { [stop] = s }, real = { [stop] = s } }
    for _, ability in ipairs(graph.anywhere or {}) do
        local key = ability.source and Pathfinder.AbilityKey(ability.source)
        if key and oneUse[key] then
            local landing = { key = key, to = ability.to, cost = ability.cost, guess = {} }
            local any = false
            for j, stop in ipairs(stops) do
                local back = ability.to == stopID(stop) and 0 or rows[j][ability.to]
                if back then landing.guess[j], any = ability.cost + back, true end
            end
            -- No guess: no search from a stop got as far as it before pricing every stop. Mostly that is a landing
            -- too far off to help, but not always: the way back can be long where the way there is quick (the
            -- hearthstone to an inn in Goldshire, then Stormwind's portals to Northrend). So the hearthstone's landing
            -- (and the bound spot, the camp, which no search reaches at all) is searched from for real anyway; the
            -- rest are left out.
            landing.unguessed = not any and (ability.method == "hearthstone" or not addon.World:GetNode(ability.to))
            landings[#landings + 1] = landing
        end
    end
    local searches, searched = 0, {}
    local function search(landing)
        local from = searched[landing.to]           -- Hearthstone and Astral Recall land in one place: searched once
        if not from then
            searches = searches + 1
            from = Pathfinder:FindCosts(graph, landing.to, graph.phase, opts, targets)
            searched[landing.to] = from
        end
        landing.real = {}
        for j, stop in ipairs(stops) do
            local on = landing.to == stopID(stop) and 0 or from[stopID(stop)]
            if on then landing.real[j] = landing.cost + on end
        end
        yield()
    end
    for _, landing in ipairs(landings) do
        if landing.unguessed and searches < MAX_BOOSTS then search(landing) end
    end
    -- land[key][stop] = the quickest way to that stop by that ability, and through which landing.
    local function abilityTimes()
        local land, via = {}, {}
        for _, landing in ipairs(landings) do
            local times = landing.real or landing.guess
            for j, t in pairs(times) do
                land[landing.key] = land[landing.key] or {}
                via[landing.key] = via[landing.key] or {}
                if t < (land[landing.key][j] or INF) then land[landing.key][j], via[landing.key][j] = t, landing end
            end
        end
        return land, via
    end
    local given = {}
    if #landings > 0 then
        repeat
            local land, via = abilityTimes()
            local options = MultiRoute.Options(land, OPTIONS_PER_STOP)
            order = MultiRoute.Improve(order, function(trial) return (MultiRoute.Assign(trial, cost, options)) end, yield)
            local _
            _, given = MultiRoute.Assign(order, cost, options)
            local guessed = false
            for number, key in pairs(given) do
                local landing = via[key][order[number]]
                if not landing.real and searches < MAX_BOOSTS then
                    search(landing)
                    guessed = true
                end
            end
        until not guessed
        yield()
    end

    -- 4. The legs, in that order, each with the one-use ability it was given and no other.
    local legs, from = {}, session.start.id
    for number, k in ipairs(order) do
        local stop = stops[k]
        local banned = copy(oneUse)
        if given[number] then banned[given[number]] = nil end
        local leg = Journey:PlanLeg(session, from, stopID(stop), banned)
        yield()
        if leg then
            leg.name, leg.stop = stop.name, stop
            stop.number = #legs + 1
            leg.heading = heading(stop.number, leg)
            legs[#legs + 1] = leg
            from = stopID(stop)
        else
            dropped[#dropped + 1] = stop.name
        end
    end
    if #legs == 0 then return nil end
    return assemble(session, legs, dropped)
end

-- Runs work(yield) a little at a time, so a long plan doesn't freeze the game (or run past the client's time limit for
-- one script): a yield() lets a frame go by once FRAME_BUDGET seconds of work have been done in this one, and otherwise
-- returns at once. (Letting a frame go by at every yield made a 35-stop tour take 19 s in game for 5 s of work: most
-- yields come after a sliver of ordering.) done(result, second) is called with what work returned, or with nil if it
-- failed (the error goes to the game's error handler). Without C_Timer (headless) it runs at once.
local FRAME_BUDGET = 0.04
local function now()
    if debugprofilestop then return debugprofilestop() / 1000 end
    return os.clock()
end
function MultiRoute:Run(work, done)
    local started
    local function yield()
        if now() - started >= FRAME_BUDGET then coroutine.yield() end
    end
    local co = coroutine.create(function() return work(yield) end)
    local function resume()
        started = now()
        local ok, a, b = coroutine.resume(co)
        if not ok then
            local handler = geterrorhandler and geterrorhandler()
            if handler then handler(a) end
            done(nil)
        elseif coroutine.status(co) == "dead" then
            done(a, b)
        elseif C_Timer and C_Timer.After then
            C_Timer.After(0, resume)
        else
            return resume()
        end
    end
    resume()
end

-- ---------------------------------------------------------------------------------------
-- Stops from /way lines.

-- TomTom's /way lines, one point a line: "/way #1 43.8 28.8 Zunta" (map 1, 43.8% across, 28.8% down, named Zunta).
-- The map can be a zone's name instead ("/way Durotar 43.8 28.8 Zunta"), read by mapByName(name) (addon:MapByName in
-- the game); the "/way" and the map may be left out (then the point is on defaultMapID, if given); commas between the
-- numbers are fine, and the name is optional. Returns { { mapID, x, y, name } } with x and y as 0-1, and the lines
-- that couldn't be read.
function MultiRoute.ParseWay(text, defaultMapID, mapByName)
    local points, bad = {}, {}
    for line in (text or ""):gmatch("[^\r\n]+") do
        local rest = line:gsub("^%s*/way%s*", ""):gsub("^%s+", ""):gsub("%s+$", "")
        if rest ~= "" then
            local mapID = defaultMapID
            local map, after = rest:match("^#(%d+)%s*(.*)$")
            if map then
                mapID, rest = tonumber(map), after
            else
                -- A zone's name: everything before the first two numbers, when it doesn't start with one.
                local zone, numbers = rest:match("^(%D.-)%s+([%d%.]+[%s,]+[%d%.]+.*)$")
                if zone then
                    zone = zone:gsub(",%s*$", "")
                    mapID, rest = mapByName and mapByName(zone), numbers
                end
            end
            local x, y, name = rest:match("^([%d%.]+)[%s,]+([%d%.]+)%s*(.*)$")
            x, y = tonumber(x), tonumber(y)
            if mapID and x and y then
                points[#points + 1] = { mapID = mapID, x = x / 100, y = y / 100, name = name ~= "" and name or nil }
            else
                bad[#bad + 1] = line
            end
        end
    end
    return points, bad
end

-- A tour entry for points ({ mapID, x, y, name }, as ParseWay gives them): each becomes a stop at the place the
-- planner knows it by (addon:PlaceAt: a position on a map with no nodes is carried up to one that has some). Points
-- on maps we can't place at all are returned second, and kept on the entry (`unplaced`: the plan names them with the
-- stops it couldn't reach); two points at the same spot are one stop.
function MultiRoute:Entry(name, points)
    local stops, unplaced, seen = {}, {}, {}
    for i, point in ipairs(points) do
        local place = addon:PlaceAt(point.mapID, point.x, point.y, "STOP")
        local label = point.name or L["ROUTE_STOP_UNNAMED"]:format(i)
        if not place then
            unplaced[#unplaced + 1] = label
        elseif not seen[place.id] then
            seen[place.id] = true
            place.name, place.leave = label, true
            stops[#stops + 1] = { name = label, place = place }
        end
    end
    return { name = name, stops = stops, unplaced = unplaced, points = points }, unplaced
end

-- ---------------------------------------------------------------------------------------
-- Saved routes: the player's own tours, kept for every character (MapzerothRebuildDB.routes), offered in the picker and
-- edited in the panel. Each is { id, name, way }: its stops as /way lines, each naming its map, so they read the same
-- whichever map the player is on. A flavour's starters (addon.SampleRoutes, Data/<flavour>/Tours.lua) are added the
-- first time, once: deleting one keeps it deleted.

local function db()
    MapzerothRebuildDB = MapzerothRebuildDB or {}
    local saved = MapzerothRebuildDB
    if not saved.routes then
        saved.routes, saved.nextRouteID = {}, 1
    end
    if not saved.routesSeeded then
        saved.routesSeeded = true
        for _, sample in ipairs(addon.SampleRoutes or {}) do
            saved.routes[#saved.routes + 1] = { id = saved.nextRouteID, name = sample.name, way = sample.way }
            saved.nextRouteID = saved.nextRouteID + 1
        end
    end
    return saved
end

-- The saved routes, in the order they were made.
function MultiRoute:SavedRoutes()
    return db().routes
end

function MultiRoute:FindRoute(id)
    for _, route in ipairs(db().routes) do
        if route.id == id then return route end
    end
end

-- Saves a route (a new one when id is nil) and returns its id.
function MultiRoute:SaveRoute(id, name, way)
    local saved = db()
    local route = id and self:FindRoute(id)
    if not route then
        route = { id = saved.nextRouteID }
        saved.nextRouteID = saved.nextRouteID + 1
        saved.routes[#saved.routes + 1] = route
    end
    route.name, route.way = name, way
    return route.id
end

function MultiRoute:DeleteRoute(id)
    local routes = db().routes
    for i, route in ipairs(routes) do
        if route.id == id then
            table.remove(routes, i)
            return true
        end
    end
    return false
end

-- A saved route's stops as points ({ mapID, x, y, name }), read from its /way lines.
function MultiRoute:RoutePoints(route)
    return (MultiRoute.ParseWay(route.way))
end

-- Points as /way lines, each with its map: what a route is saved as.
function MultiRoute.WayText(points)
    local lines = {}
    local function coordinate(v)
        return (("%.2f"):format(v * 100):gsub("0+$", ""):gsub("%.$", ""))
    end
    for _, point in ipairs(points) do
        local line = ("/way #%d %s %s"):format(point.mapID, coordinate(point.x), coordinate(point.y))
        if point.name and point.name ~= "" then line = line .. " " .. point.name end
        lines[#lines + 1] = line
    end
    return table.concat(lines, "\n")
end

-- ---------------------------------------------------------------------------------------
-- Holiday routes: lists that ship with the addon (addon.HolidayRoutes, Data/<flavour>/HolidayRoutes.lua, generated),
-- offered while their holiday is on. Each has its stops for everyone (neutral) and for each faction.

-- The holiday routes this player is offered now, each { route, points }: those whose holiday is on, with the neutral
-- stops and their own faction's (a player of neither faction gets the neutral ones).
function MultiRoute:HolidayRoutes(ctx)
    local offered = {}
    for _, route in ipairs(addon.HolidayRoutes or {}) do
        if ctx.holidayActive and ctx.holidayActive(route.holiday) then
            local points = MultiRoute.ParseWay(route.neutral or "")
            local own = ctx.faction == "Alliance" and route.alliance or ctx.faction == "Horde" and route.horde
            for _, point in ipairs(own and MultiRoute.ParseWay(own) or {}) do points[#points + 1] = point end
            if #points > 0 then offered[#offered + 1] = { route = route, points = points } end
        end
    end
    return offered
end

