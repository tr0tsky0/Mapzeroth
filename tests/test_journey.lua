useTestDistances()
addon.World:Build()

local J = addon.Journey

-- Names come from the client; give the few we read a name.
local maps = {
    [1453] = { name = "Stormwind City", mapType = 3, parentMapID = 1415 },
    [1429] = { name = "Elwynn Forest", mapType = 3, parentMapID = 1415 },
    [1455] = { name = "Ironforge", mapType = 3, parentMapID = 1415 },
    [1426] = { name = "Dun Morogh", mapType = 3, parentMapID = 1415 },
    [1415] = { name = "Eastern Kingdoms", mapType = 2, parentMapID = 947 },
    [947] = { name = "Azeroth", mapType = 1, parentMapID = 0 },
}
C_Map = { GetMapInfo = function(id) return maps[id] end }
Enum = { UIMapType = { Continent = 2 } }
C_TaxiMap = { GetTaxiNodesForMap = function(id)
    if id == 1415 then
        return { { nodeID = 2, name = "Stormwind, Elwynn" }, { nodeID = 6, name = "Ironforge, Dun Morogh" },
                 { nodeID = 8, name = "Thelsamar, Loch Modan" }, { nodeID = 5, name = "Lakeshire, Redridge" },
                 { nodeID = 74, name = "Thorium Point, Searing Gorge" } }
    end
    return {}
end }
addon:ClearNodeNameCache()

-- Times.
check(J:FormatTime(45) == "45s", "seconds: " .. J:FormatTime(45))
check(J:FormatTime(234) == "3m 54s", "minutes: " .. J:FormatTime(234))
check(J:FormatTime(59.6) == "1m 00s", "rounds up across the minute: " .. J:FormatTime(59.6))
check(J:FormatTime(3900) == "1h 05m", "hours: " .. J:FormatTime(3900))

-- A session prices every node; a plan reads the route to one.
local ali = makeCtx({ faction = "Alliance" })
local start = { id = "YOU_t1", mapID = 1453, x = 0.60, y = 0.60 }
local session = J:Build(ali, start)
check(session, "a session builds from a known map")
check(select(2, J:Build(ali, { id = "YOU_x", mapID = 99999, x = 0.5, y = 0.5 })) == "nowhere", "and reports 'nowhere' otherwise")
check(J:Cost(session, "TAXI_6") ~= nil, "Ironforge is priced")

local plan = J:Plan(session, "TAXI_6")
check(plan and plan.cost == J:Cost(session, "TAXI_6"), "the plan costs what the session priced")
check(#plan.steps == 2, "walk to the flight master, then fly: " .. #plan.steps)
check(plan.steps[1].method == "walk" and plan.steps[1].approx, "walking is marked approximate")
check(plan.steps[2].method == "taxi" and not plan.steps[2].approx, "a flight is not")
check(plan.steps[2].text == "Fly to Ironforge Flight Master", "the step reads well: " .. plan.steps[2].text)
check(plan.steps[1].text == "Walk to Stormwind Flight Master", "walking to the flight master: " .. plan.steps[1].text)
check(plan.hint == nil, "no hint when there's no flight rule in play")

-- Nearest of several.
local best, cost = J:Nearest(session, { "TAXI_23", "TAXI_6", "TAXI_4" })
check(best == "TAXI_4" and cost == J:Cost(session, "TAXI_4"), "Sentinel Hill is nearest of those: " .. tostring(best))
check(J:Nearest(session, { "NOT_A_NODE" }) == nil, "nothing reachable gives nil")

-- Hints: with flights limited to found points, an unfound one that would help is named.
local FK = addon.FlightKnowledge
FK:Reset()
FK:Record({
    { nodeID = 2, state = 0 }, { nodeID = 6, state = 1 },     -- Stormwind (here) and Ironforge found
    { nodeID = 8, state = 2 },                                -- Thelsamar: Unreachable, so not found
}, ali)
local limited = makeCtx({ faction = "Alliance" })
setFlights(limited, function(id) return FK:IsFound(id) end)
local limitedSession = J:Build(limited, start)
local toThelsamar = J:Plan(limitedSession, "TAXI_8")
check(toThelsamar and toThelsamar.hint, "flying to Thelsamar isn't allowed, and a hint says so")
check(toThelsamar.hint.nodeID == "TAXI_8" and toThelsamar.hint.known, "it names Thelsamar as known-not-found")
check(toThelsamar.hint.saves > 0, "and what unlocking it would save")
check(J:HintText(toThelsamar.hint):find("Thelsamar Flight Master", 1, true), "the sentence names it: " .. J:HintText(toThelsamar.hint))

-- Before anything has been read, the hint asks the player to open a flight window.
FK:Reset()
local blank = J:Build(limited, start)
local blankPlan = J:Plan(blank, "TAXI_6")
check(blankPlan.hint and not blankPlan.hint.known, "with nothing known the hint is the 'open a window' one")
check(J:HintText(blankPlan.hint):find("Open a flight master", 1, true), "and reads that way")
check(J:HintText(nil) == nil, "no hint, no sentence")

-- Where the player is: read from the client, carried up to a map we cover.
local pos = { x = 0.5, y = 0.5 }
local currentMap
C_Map.GetBestMapForUnit = function() return currentMap end
C_Map.GetPlayerMapPosition = function(mapID) return { GetXY = function() return pos.x, pos.y end } end
C_Map.GetWorldPosFromMapPos = function(mapID, vec) return 0, { GetXY = function() return vec.x * 1000, vec.y * 1000 end } end
C_Map.GetMapPosFromWorldPos = function(continent, world, parent)
    local wx, wy = world:GetXY()
    return parent, { GetXY = function() return wx / 1000 / 2, wy / 1000 / 2 end }
end
maps[9001] = { name = "A subzone", mapType = 5, parentMapID = 1429 }

currentMap = 1453
local here = addon:GetPlayerStart()
check(here and here.mapID == 1453 and here.x == 0.5, "on a map we cover, the player is where they are")
check(here.id:find("^YOU_1453_"), "and the id names the spot: " .. here.id)

currentMap = 9001
local carried = addon:GetPlayerStart()
check(carried and carried.mapID == 1429, "a subzone is carried up to its zone: " .. tostring(carried and carried.mapID))
check(math.abs(carried.x - 0.25) < 1e-9, "with its position converted")

currentMap = nil
check(select(2, addon:GetPlayerStart()) == "no map", "no map, no start")
currentMap = 1453
C_Map.GetPlayerMapPosition = function() return nil end
check(select(2, addon:GetPlayerStart()) == "no position", "no position, no start (instances)")

-- A portal step names the portal you use, not the one you come out of.
local skyborne = makeCtx({ faction = "Alliance", race = "Skyborne" })
local inDalaran = J:Build(skyborne, { id = "YOU_d", mapID = 1416, x = 0.13, y = 0.57 })
local viaPortal = J:Plan(inDalaran, "PORTAL_STORMWIND_DALARAN")
local portalStep = viaPortal and viaPortal.steps[#viaPortal.steps]
check(portalStep and portalStep.method == "portal", "a Skyborne in Dalaran takes the portal")
check(portalStep.text == "Use Skyborne Portal to Stormwind", "and the step says which: " .. tostring(portalStep and portalStep.text))

-- Standing at a flight master, the walk to it isn't a step.
local atFlightMaster = J:Build(ali, { id = "YOU_fm", mapID = 1453, x = 0.7098, y = 0.7293 })
local justFly = J:Plan(atFlightMaster, "TAXI_6")
check(justFly and #justFly.steps == 1 and justFly.steps[1].method == "taxi", "no trivial walk step: " .. tostring(justFly and #justFly.steps))
check(J:Plan(atFlightMaster, "TAXI_2").steps[1] ~= nil, "but a route that is only a tiny walk keeps it")

-- Lakeshire to Ironforge goes through Thorium Point: two tickets in the data, one flight in game. The
-- game's flight map shows a single ticket, so the plan is one step that names the stop.
maps[1433] = { name = "Redridge Mountains", mapType = 3, parentMapID = 1415 }
addon:ClearNodeNameCache()
local lakeshire = addon.World:GetNode("TAXI_5")
local fromLakeshire = J:Build(ali, { id = "YOU_ls", mapID = lakeshire.mapID, x = lakeshire.x, y = lakeshire.y })
local ticket = J:Plan(fromLakeshire, "TAXI_6")
check(ticket and #ticket.steps == 1 and ticket.steps[1].method == "taxi", "Lakeshire to Ironforge is one flight step: " .. tostring(ticket and #ticket.steps))
check(ticket.steps[1].via and #ticket.steps[1].via >= 1, "that goes through another flight point")
check(ticket.steps[1].text:find("(via ", 1, true) and ticket.steps[1].text:find("Fly to Ironforge Flight Master", 1, true), "and says so: " .. ticket.steps[1].text)
check(math.abs(ticket.steps[1].seconds - ticket.cost) < 1, "with the whole flight's time on it")

-- Money: a route the player can't pay for isn't offered. Starting at Refuge Pointe's flight master, Ironforge is
-- 271 s direct (530c) or 215 s on two tickets through Menethil Harbor (660c).
do
    local refuge = addon.World:GetNode("TAXI_16")
    local at = { id = "YOU_refuge", mapID = refuge.mapID, x = refuge.x, y = refuge.y }
    local function planWith(money)
        local ctx = makeCtx({ faction = "Alliance" })
        ctx.money = money
        local session = J:Build(ctx, at)
        return session and J:Plan(session, "TAXI_6"), session
    end
    local rich = planWith(nil)
    check(rich and rich.fare == 660 and rich.cost < 230, "with no money known, fares are just reported: " .. tostring(rich and rich.fare))
    local plenty = planWith(100000)
    check(plenty.fare == 660 and not plenty.quickest and not plenty.unaffordable, "with plenty, the quickest route and nothing to say")
    check(J:FareText(plenty) == nil, "so no fare warning")
    local short = planWith(600)
    check(short.fare == 530 and short.cost == 271 and not short.unaffordable, "600 copper can't pay 660: the direct ticket at 530: " .. tostring(short.fare) .. "c " .. tostring(short.cost) .. "s")
    check(short.quickest and short.quickest.fare == 660 and short.quickest.saves > 50, "and it says the quicker one costs more")
    check(J:FareText(short):find("quickest") and J:FareText(short):find("6s 60c"), "in words: " .. tostring(J:FareText(short)))
    local broke = planWith(0)
    local flights = 0
    for _, step in ipairs(broke and broke.steps or {}) do if step.method == "taxi" then flights = flights + 1 end end
    check(broke == nil or broke.unaffordable or flights == 0, "with no money there is no flight in the route (or it says it can't be paid for)")
    if broke and broke.unaffordable then
        check(J:FareText(broke):find("can't afford"), "an unaffordable route says so: " .. tostring(J:FareText(broke)))
    end

    -- Pricing every place is bounded by the money too.
    local _, richSession = planWith(nil)
    local _, poorSession = planWith(0)
    check(J:Cost(richSession, "TAXI_6") ~= nil, "priced with money unknown")
    local flown = J:Cost(poorSession, "TAXI_7")
    check(flown == nil or flown > J:Cost(richSession, "TAXI_7"), "with nothing to spend, Menethil Harbor isn't reached by a flight")

    check(J:FormatMoney(0) == "0c" and J:FormatMoney(830) == "8s 30c" and J:FormatMoney(12345) == "1g 23s 45c" and J:FormatMoney(20000) == "2g",
        "money reads as gold, silver and copper")
end

-- Back to Stormwind from Thorium Point with 1638 copper, 22 short of the game's own ticket (1660c).
do
    local thorium = addon.World:GetNode("TAXI_74")
    local at = { id = "YOU_thorium", mapID = thorium.mapID, x = thorium.x, y = thorium.y }
    local ctx = makeCtx({ faction = "Alliance" })
    ctx.money = 1638
    local session = J:Build(ctx, at)
    local plan = J:Plan(session, "TAXI_2")
    local flights = {}
    for _, step in ipairs(plan.steps) do if step.method == "taxi" then flights[#flights + 1] = step end end
    check(plan.fare == 1250 and #flights == 2 and flights[1].nodeID == "TAXI_5" and flights[2].nodeID == "TAXI_2",
        "22 copper short of the direct ticket: a ticket to Lakeshire, then on to Stormwind: " .. tostring(plan.fare) .. "c")
    check(flights[1].via and #flights[1].via == 1, "the first ticket says it flies through Morgan's Vigil")
    check(plan.quickest and plan.quickest.fare == 1660 and plan.quickest.saves > 30 and plan.quickest.saves < 40,
        "and it says the quicker one costs 1660c: saves " .. tostring(plan.quickest and plan.quickest.saves) .. "s")
    check(not plan.unaffordable, "which isn't out of reach")
end

-- What a step says when the player is using something of their own, or a portal we can't name.
-- "Cast <spell>" and "Use <item>" name the spell or item (the client's name for it) instead of where it
-- lands; a portal with no name of ours (Modern's) says where you come out, by its map, not a raw id.
do
    local list = addon.Nodes.EasternKingdoms or select(2, next(addon.Nodes))
    local swContainer = addon.World:GetNodeContainer("TAXI_2").path
    local ifContainer = addon.World:GetNodeContainer("TAXI_6").path
    table.insert(list, { id = "ZZTEST_A", container = ifContainer, mapID = 1455, x = 0.5, y = 0.5 })
    table.insert(list, { id = "ZZTEST_B", container = swContainer, mapID = 1453, x = 0.5, y = 0.5 })
    table.insert(list, { id = "ZZTEST_SPELL", container = swContainer, mapID = 1453, x = 0.4, y = 0.4 })
    table.insert(list, { id = "ZZTEST_ITEM", container = swContainer, mapID = 1453, x = 0.6, y = 0.6 })
    table.insert(addon.Edges, { from = "ZZTEST_A", to = "ZZTEST_B", method = "portal", cost = 0 })
    table.insert(addon.Abilities.Teleports, { spellID = 900002, to = "ZZTEST_SPELL", cost = 5 })
    addon.Abilities.Items = addon.Abilities.Items or {}
    table.insert(addon.Abilities.Items, { itemID = 900001, to = "ZZTEST_ITEM", cost = 5 })
    addon.World:Build()
    addon:ClearNodeNameCache()
    C_Spell = { GetSpellInfo = function(id) if id == 900002 then return { name = "Path of Testing" } end end }
    C_Item = { GetItemNameByID = function(id) if id == 900001 then return "Test Key" end end }

    local ctx = makeCtx({ faction = "Alliance", spells = { 900002 }, items = { 900001 } })
    local from = { id = "YOU_zz", mapID = 1455, x = 0.5, y = 0.5 }
    local s = J:Build(ctx, from)
    local spellPlan = J:Plan(s, "ZZTEST_SPELL")
    check(spellPlan and spellPlan.steps[1].text == "Cast Path of Testing", "a spell teleport is named for the spell: " .. tostring(spellPlan and spellPlan.steps[1].text))
    local itemPlan = J:Plan(s, "ZZTEST_ITEM")
    check(itemPlan and itemPlan.steps[1].text == "Use Test Key", "an item teleport is named for the item: " .. tostring(itemPlan and itemPlan.steps[1].text))
    local portalPlan = J:Plan(s, "ZZTEST_B")
    local portal
    for _, step in ipairs(portalPlan and portalPlan.steps or {}) do if step.method == "portal" then portal = step end end
    check(portal and portal.text == "Take the portal to Stormwind City", "an unnamed portal says where it comes out: " .. tostring(portal and portal.text))

    C_Spell.GetSpellInfo = function() return nil end     -- the client has no name yet: say where it goes instead
    local unnamed = J:Plan(J:Build(ctx, from), "ZZTEST_SPELL")
    check(unnamed and unnamed.steps[1].text == "Teleport to Stormwind City", "with no name to give, it says where it goes: " .. tostring(unnamed and unnamed.steps[1].text))
end

-- Finding 10: a context that already allows every flight builds no second, "free" graph for the flight hint.
do
    local free = makeCtx({ faction = "Alliance" })
    local session = J:Build(free, start)
    local plan = J:Plan(session, "TAXI_8")
    check(plan and plan.hint == nil and session.free == nil, "no free-route graph and no hint with no flight rule")
end
