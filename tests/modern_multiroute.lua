-- Tours (MultiRoute.lua): several stops in the quickest order, on Modern's data. The stops are the pet tamers for
-- the Family Battler achievement, as /way lists (Kalimdor, Eastern Kingdoms, Northrend).
-- Run: python tests/harness.py --modern modern_multiroute

useRetailDistances()
addon.World:Build()

-- Names come from the client's map and taxi data, which isn't here: it answers "unknown".
C_Map = C_Map or {}
C_Map.GetMapInfo = C_Map.GetMapInfo or function() return nil end
C_Map.GetAreaInfo = C_Map.GetAreaInfo or function() return nil end
C_TaxiMap = C_TaxiMap or { GetTaxiNodesForMap = function() return {} end }
Enum = Enum or { UIMapType = { Continent = 2 } }

local MR, J = addon.MultiRoute, addon.Journey

local KALIMDOR = [[
/way #1 43.8 28.8 Zunta
/way #10 58.6 53.0 Dagra the Fierce
/way #63 20.2 29.6 Analynn
/way #65 59.6 71.6 Zonya the Sadist
/way #66 57.2 45.8 Merda Stronghoof
/way #69 59.6 49.6 Traitor Gluk
/way #80 46.0 60.4 Elena Flutterfly
/way #199 39.6 79.2 Cassandra Kaboom
/way #70 53.8 74.8 Grazzle the Great
/way #77 40.0 56.6 Zoltan
/way #64 31.8 32.8 Kela Grimtotem
/way #83 65.6 64.4 Stone Cold Trixxy
]]
local EASTERN_KINGDOMS = [[
/way #37 41.6 83.6 Julia Stevens
/way #52 60.8 18.4 Old MacDonald
/way #49 33.2 52.6 Lindsay
/way #47 19.8 44.8 Eric Davidson
/way #50 46.0 40.4 Steven Lisbane
/way #210 51.4 73.2 Bill Buckler
/way #26 62.8 54.6 David Kosse
/way #23 66.55 56.99 Deiza Plaguehorn
/way #32 35.4 27.4 Kortas Darkhammer
/way #36 25.6 47.6 Durin Darkhammer
/way #51 76.6 41.4 Everessa
/way #42 40.2 76.4 Lydia Accoste
]]
local NORTHREND = [[
/way #117 28.6 33.8 Beegle Blastfuse
/way #115 59.0 77.0 Okrut Dragonwaste
/way #118 77.4 19.6 Major Payne
/way #127 50.2 59.0 Nearly Headless Jacob
/way #121 13.2 66.8 Gutretch
]]

-- 1. The order. Exact for few stops: never worse than trying every order by hand.
do
    local seed = 7
    local function rand()
        seed = (seed * 1103515245 + 12345) % 2147483648
        return seed / 2147483648
    end
    local function permutations(list, n, out)
        n = n or #list
        out = out or {}
        if n <= 1 then
            local copy = {}
            for i, v in ipairs(list) do copy[i] = v end
            out[#out + 1] = copy
        else
            for i = 1, n do
                list[i], list[n] = list[n], list[i]
                permutations(list, n - 1, out)
                list[i], list[n] = list[n], list[i]
            end
        end
        return out
    end
    for trial = 1, 5 do
        local n = 6
        local cost = {}
        for i = 0, n do
            cost[i] = {}
            for j = 1, n do if i ~= j then cost[i][j] = 10 + math.floor(rand() * 500) end end
        end
        local order, total = MR.Order(cost, n)
        local best = math.huge
        local ids = {}
        for i = 1, n do ids[i] = i end
        for _, p in ipairs(permutations(ids)) do
            local t, from = 0, 0
            for _, k in ipairs(p) do t = t + cost[from][k]; from = k end
            if t < best then best = t end
        end
        check(order and #order == n and math.abs(total - best) < 1e-9, ("exact order matches brute force (trial %d): %s vs %s"):format(trial, tostring(total), best))
    end

    -- Many stops: the heuristic's order visits each once, and is no worse than going to the nearest each time.
    local n = 16
    local cost = {}
    local px, py = {}, {}
    for i = 0, n do px[i], py[i] = rand() * 1000, rand() * 1000 end
    for i = 0, n do
        cost[i] = {}
        for j = 1, n do if i ~= j then cost[i][j] = math.sqrt((px[i] - px[j]) ^ 2 + (py[i] - py[j]) ^ 2) end end
    end
    local order, total = MR.Order(cost, n)
    local seen = {}
    for _, k in ipairs(order or {}) do seen[k] = true end
    local count = 0
    for _ in pairs(seen) do count = count + 1 end
    check(order and #order == n and count == n, "the heuristic visits all 16 stops once each")
    local nn, from, used = 0, 0, {}
    for _ = 1, n do
        local pick
        for k = 1, n do if not used[k] and (not pick or cost[from][k] < cost[from][pick]) then pick = k end end
        used[pick] = true
        nn, from = nn + cost[from][pick], pick
    end
    check(total <= nn + 1e-9, ("and is no slower than nearest-first: %.0f vs %.0f"):format(total or -1, nn))

    -- A stop nothing reaches: no order.
    check(MR.Order({ [0] = { [1] = 5 }, [1] = {}, [2] = { [1] = 5 } }, 2) == nil, "no order when a stop can't be reached")
end

-- 2. /way lines.
do
    local points, bad = MR.ParseWay(KALIMDOR)
    check(#points == 12 and #bad == 0, "twelve Kalimdor points read: " .. #points)
    check(points[1].mapID == 1 and math.abs(points[1].x - 0.438) < 1e-9 and math.abs(points[1].y - 0.288) < 1e-9 and points[1].name == "Zunta",
        "the first is Zunta, on Durotar (map 1) at 43.8 28.8")
    local loose = MR.ParseWay("/way 12.5, 40 Somewhere\n  #85 50 50\nnot a point", 1)
    check(#loose == 2 and loose[1].mapID == 1 and loose[1].y == 0.4 and loose[2].mapID == 85 and loose[2].name == nil,
        "the map and name may be left out, and commas are fine")
    local _, rejected = MR.ParseWay("/way #1 north\n/way #1 1 2", nil)
    check(#rejected == 1, "a line with no coordinates is reported")
end

-- 3. The tours.
local function tour(name, text, ctx, start)
    local entry, unplaced = MR:Entry(name, (MR.ParseWay(text)))
    check(#unplaced == 0, name .. ": every stop is on a map we know: " .. table.concat(unplaced, ", "))
    local session = J:Build(ctx, start, J:ExtrasOf(entry))
    check(session ~= nil, name .. ": a session from the start")
    local t0 = os.clock()
    local plan = J:PlanEntry(session, entry)
    local took = os.clock() - t0
    return plan, entry, session, took
end

local function describe(plan)
    local names = {}
    for _, leg in ipairs(plan.legs) do names[#names + 1] = ("%s %s"):format(leg.name, J:FormatTime(leg.cost)) end
    return table.concat(names, " > ")
end

local orgrimmar = { id = "YOU_TEST_ORGRIMMAR", mapID = 1, x = 0.45, y = 0.12 }       -- Durotar, just outside Orgrimmar's gate
local horde = makeCtx({ faction = "Horde", items = { 6948 }, hearthNode = "INN_295" })

do
    local plan, entry, session, took = tour("Kalimdor", KALIMDOR, horde, orgrimmar)
    check(plan and #plan.legs == 12 and #plan.dropped == 0, "Kalimdor: all twelve stops planned" .. (plan and (", dropped: " .. table.concat(plan.dropped, ", ")) or ""))
    if plan then
        print(("Kalimdor tour (%.2fs to plan): %s, total %s"):format(took, describe(plan), J:FormatTime(plan.cost)))
        local sum, steps, seen = 0, 0, {}
        for i, leg in ipairs(plan.legs) do
            sum = sum + leg.cost
            steps = steps + #leg.steps
            seen[leg.name] = true
            check(leg.goal == leg.stop.place.id and leg.stop.number == i, "leg " .. i .. " ends at its stop, numbered " .. i)
        end
        local count = 0
        for _ in pairs(seen) do count = count + 1 end
        check(count == 12, "each stop is visited once")
        check(math.abs(sum - plan.cost) < 1e-6 and steps == #plan.steps, "the plan's total and steps are its legs'")
        check(plan.legs[1].heading == "1. " .. plan.legs[1].name, "a leg is headed by its stop's number and name")
        -- The hearthstone is used once at most.
        local hearths = 0
        for _, step in ipairs(plan.raw) do if step.method == "hearthstone" then hearths = hearths + 1 end end
        check(hearths <= 1, "the hearthstone is used at most once: " .. hearths)
        -- The stops' names are in the step text.
        local last = plan.legs[1].steps[#plan.legs[1].steps]
        check(last.name == plan.legs[1].name, "the first leg's last step names its stop: " .. tostring(last.name))

        -- Followed leg by leg: the navigator's title is the stop the leg goes to.
        local N = addon.Navigation
        N:Start(entry, plan)
        local legs = J:Legs(plan)
        check(legs == plan.legs, "a tour's legs are its own")
        local model = N:Update({ mapID = orgrimmar.mapID, x = orgrimmar.x, y = orgrimmar.y, now = 0, facing = 0 })
        check(model and model.destination == plan.legs[1].name, "the navigator heads for stop 1: " .. tostring(model and model.destination))
        N:Stop()

        -- Planned again from somewhere else part way (a flight went astray): the rest of the order is kept.
        local rest = { name = entry.name, stops = {}, keep = {} }
        for i = 5, 12 do
            rest.stops[#rest.stops + 1] = plan.legs[i].stop
            if i > 5 then rest.keep[#rest.keep + 1] = plan.legs[i] end
        end
        local astray = { id = "YOU_TEST_ASTRAY", mapID = 10, x = 0.50, y = 0.50 }     -- the Northern Barrens
        local again = J:Build(horde, astray, J:ExtrasOf(rest))
        local replanned = again and J:PlanEntry(again, rest)
        check(replanned and #replanned.legs == 8 and replanned.legs[1].stop == plan.legs[5].stop and replanned.legs[2] == plan.legs[6],
            "the rest of the tour is planned again to its next stop, the legs after kept")
        check(replanned and replanned.legs[1].heading:find("^5%. "), "and the stops keep their numbers")
    end

    -- Spread over frames (headless: at once), the same plan comes back.
    local done
    MR:Run(function(yield) return J:PlanEntry(session, entry, yield) end, function(p) done = p end)
    check(done and math.abs(done.cost - plan.cost) < 1e-6, "planned a little at a time, the tour is the same")
end

do
    local stormwind = { id = "YOU_TEST_STORMWIND", mapID = 37, x = 0.40, y = 0.60 }  -- Elwynn Forest
    local alliance = makeCtx({ faction = "Alliance", items = { 6948 }, hearthNode = "INN_295" })
    local plan, _, _, took = tour("Eastern Kingdoms", EASTERN_KINGDOMS, alliance, stormwind)
    check(plan and #plan.legs + #plan.dropped == 12, "Eastern Kingdoms: every stop planned or named as dropped")
    if plan then
        print(("Eastern Kingdoms tour (%.2fs to plan): %s, total %s%s"):format(took, describe(plan), J:FormatTime(plan.cost),
            #plan.dropped > 0 and (", dropped: " .. table.concat(plan.dropped, ", ")) or ""))
    end
end

do
    local dalaran = { id = "YOU_TEST_BOREAN", mapID = 114, x = 0.50, y = 0.50 }     -- Borean Tundra
    local plan, _, _, took = tour("Northrend", NORTHREND, horde, dalaran)
    check(plan and #plan.legs + #plan.dropped == 5, "Northrend: every stop planned or named as dropped")
    if plan then
        print(("Northrend tour (%.2fs to plan): %s, total %s%s"):format(took, describe(plan), J:FormatTime(plan.cost),
            #plan.dropped > 0 and (", dropped: " .. table.concat(plan.dropped, ", ")) or ""))
    end
end

-- One-use abilities shape the order, not just the leg that happens to come first. With Path of the Windrunners (8 h,
-- so one-use) from Searing Gorge, the quick way is to Eastern Plaguelands by it, then fly on to the Hinterlands; not
-- the Hinterlands first and back to EPL (seen in game, 2026-10-08).
do
    local searing = { id = "YOU_TEST_SEARING", mapID = 32, x = 0.354, y = 0.274 }     -- Kortas Darkhammer's spot
    local windrunner = makeCtx({ faction = "Alliance", spells = { 1254400 } })
    local plan = tour("Searing Gorge to the north", [[
/way #26 62.8 54.6 David Kosse
/way #23 66.55 56.99 Deiza Plaguehorn
]], windrunner, searing)
    check(plan and #plan.legs == 2, "both stops planned")
    if plan then
        print(("Searing Gorge with Windrunners: %s, total %s"):format(describe(plan), J:FormatTime(plan.cost)))
        local first = plan.legs[1]
        local cast = false
        for _, step in ipairs(first.raw) do if step.source and step.source.spellID == 1254400 then cast = true end end
        check(first.name == "Deiza Plaguehorn" and cast, "Path of the Windrunners to Deiza first, then David: " .. describe(plan))
    end
end

-- A flight on the player's own mount is drawn as one straight line, from where it starts to where it ends, however
-- many hops the search made of it (seen in game: the line bounced through Talonbranch Glade, 2026-10-08).
do
    local plan = tour("Kalimdor (drawn)", KALIMDOR, horde, orgrimmar)
    local flights, straight = 0, 0
    for _, step in ipairs(plan and plan.steps or {}) do
        if step.method == "fly" then
            flights = flights + 1
            if #step.path == 2 then straight = straight + 1 end
        end
    end
    check(flights > 0 and straight == flights, ("every flight is drawn start to end: %d of %d"):format(straight, flights))
end

-- /way lines may name the zone instead of "#map" (as many guides write them).
do
    local zones = { durotar = 1, ["northern barrens"] = 10 }
    local points, bad = MR.ParseWay("/way Durotar 43.8 28.8 Zunta\n/way Northern Barrens, 58.6, 53.0\n/way Nowhere Land 1 2",
        nil, function(name) return zones[name:lower()] end)
    check(#points == 2 and points[1].mapID == 1 and points[1].name == "Zunta" and points[2].mapID == 10 and points[2].name == nil,
        "a zone's name is read as its map")
    check(#bad == 1 and bad[1]:find("Nowhere"), "and a zone nobody knows makes the line unreadable")
end

-- A short cooldown is back before a trip needs it again: Dreamwalk (60 s, into the druids' Emerald Dreamway) can be used
-- on any leg; the hearthstone, a dungeon's teleport and a consumable are used once.
do
    local druid = makeCtx({ faction = "Alliance", class = "DRUID", spells = { 193753, 1254400 }, items = { 6948, 184504 }, hearthNode = "INN_295" })
    local session = J:Build(druid, orgrimmar, nil)
    local once = {}
    for _, key in ipairs(J:OneUseAbilities(session)) do once[key] = true end
    check(not once[193753], "Dreamwalk isn't used up by one leg")
    check(once[6948] and once[1254400], "the hearthstone and Path of the Windrunners are")
    check(once[184504], "and so is a consumable (the Oribos portal, 5 min), short cooldown or not")
end

-- An ability with a choice of landings says which to pick: "Cast Mole Machine to Aerie Peak", not just "Cast Mole Machine".
do
    local realSpell = C_Spell
    C_Spell = { GetSpellInfo = function(id) if id == 265225 then return { name = "Mole Machine" } end end }
    local mole = makeCtx({ faction = "Alliance", race = "DarkIronDwarf", spells = { 265225 } })
    local session = J:Build(mole, orgrimmar, nil)
    local plan = J:Plan(session, "AERIE_PEAK_MOLE")
    local first = plan and plan.steps[1]
    check(first and first.source and first.source.toList and first.text == addon.L["STEP_CAST_TO"]:format("Mole Machine", first.name),
        "the step names the landing: " .. tostring(first and first.text))
    -- One with a single landing still reads as before.
    C_Spell = { GetSpellInfo = function(id) if id == 1254400 then return { name = "Path of the Windrunners" } end end }
    local runner = makeCtx({ faction = "Alliance", spells = { 1254400 } })
    local own = J:Plan(J:Build(runner, orgrimmar, nil), "INSTANCE_WINDRUNNER_SPIRE")
    check(own and own.steps[1].text == addon.L["STEP_CAST"]:format("Path of the Windrunners"), "a single landing doesn't: " .. tostring(own and own.steps[1].text))
    C_Spell = realSpell
end

-- Holiday routes (Data/Modern/HolidayRoutes.lua, MultiRoute:HolidayRoutes): offered only while their holiday is on, with
-- the neutral stops and the player's own faction's.
do
    local function offers(faction, on)
        return MR:HolidayRoutes(makeCtx({ faction = faction, holidays = { hallows_end = on } }))
    end
    check(#offers("Horde", false) == 0, "no holiday routes when the holiday is off")
    local horde, alliance = offers("Horde", true), offers("Alliance", true)
    check(#horde == #addon.HolidayRoutes and #alliance == #addon.HolidayRoutes, "every Hallow's End route while it is on")
    local function count(text)
        local n = 0
        for _ in (text or ""):gmatch("[^\n]+") do n = n + 1 end
        return n
    end
    local ek = addon.HolidayRoutes[1]
    check(#horde[1].points == count(ek.neutral) + count(ek.horde) and #alliance[1].points == count(ek.neutral) + count(ek.alliance),
        "each faction gets the neutral stops and its own: " .. #horde[1].points .. " / " .. #alliance[1].points)
    local neither = MR:HolidayRoutes(makeCtx({ faction = "Neutral", holidays = { hallows_end = true } }))
    check(neither[1] and #neither[1].points == count(ek.neutral), "a player of neither faction, only the neutral ones")

    -- Every stop reads, and is on a map we can place (the Underbelly through Dalaran's map above it, as the client does).
    local parents = { [126] = 125 }
    local realInfo, realToWorld, realFromWorld = C_Map.GetMapInfo, C_Map.GetWorldPosFromMapPos, C_Map.GetMapPosFromWorldPos
    CreateVector2D = CreateVector2D or function(x, y) return { x = x, y = y, GetXY = function(self) return self.x, self.y end } end
    C_Map.GetMapInfo = function(id) return parents[id] and { parentMapID = parents[id] } or nil end
    C_Map.GetWorldPosFromMapPos = function(id, pos)
        local b = RETAIL_MAP_BOUNDS[id]
        local x, y = pos:GetXY()
        return b.continent, { wy = b.maxY - x * (b.maxY - b.minY), wx = b.maxX - y * (b.maxX - b.minX) }
    end
    C_Map.GetMapPosFromWorldPos = function(continent, world, id)
        local b = RETAIL_MAP_BOUNDS[id]
        return continent, CreateVector2D((b.maxY - world.wy) / (b.maxY - b.minY), (b.maxX - world.wx) / (b.maxX - b.minX))
    end
    for _, route in ipairs(addon.HolidayRoutes) do
        for _, block in ipairs({ "neutral", "alliance", "horde" }) do
            local _, bad = MR.ParseWay(route[block] or "")
            check(#bad == 0, route.name .. " " .. block .. ": every line reads")
        end
        for _, offer in ipairs({ horde, alliance }) do
            for _, o in ipairs(offer) do
                if o.route == route then
                    local _, unplaced = MR:Entry(route.name, o.points)
                    check(#unplaced == 0, route.name .. ": every stop placed: " .. table.concat(unplaced, ", "))
                end
            end
        end
    end
    C_Map.GetMapInfo, C_Map.GetWorldPosFromMapPos, C_Map.GetMapPosFromWorldPos = realInfo, realToWorld, realFromWorld

    -- Planned like any tour: Outland for the Horde, from Hellfire, reaches every stop.
    local ctx = makeCtx({ faction = "Horde", level = 80, holidays = { hallows_end = true } })
    local outland
    for _, o in ipairs(MR:HolidayRoutes(ctx)) do if o.route.name:find("Outland") then outland = o end end
    local entry = MR:Entry(outland.route.name, outland.points)
    local plan = J:PlanEntry(J:Build(ctx, { id = "YOU_TEST_HELLFIRE", mapID = 100, x = 0.5, y = 0.5 }, J:ExtrasOf(entry)), entry)
    check(plan and #plan.legs == #outland.points and #plan.dropped == 0, "the Outland route reaches all its stops")
end
