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
check(plan.steps[2].method == "flight" and not plan.steps[2].approx, "a flight is not")
check(plan.steps[2].text == "Fly to Ironforge, Dun Morogh", "the step reads well: " .. plan.steps[2].text)
check(plan.steps[1].text == "Walk to Stormwind, Elwynn", "walking to the flight master: " .. plan.steps[1].text)
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
limited.flightNodeFound = function(id) return FK:IsFound(id) end
local limitedSession = J:Build(limited, start)
local toThelsamar = J:Plan(limitedSession, "TAXI_8")
check(toThelsamar and toThelsamar.hint, "flying to Thelsamar isn't allowed, and a hint says so")
check(toThelsamar.hint.nodeID == "TAXI_8" and toThelsamar.hint.known, "it names Thelsamar as known-not-found")
check(toThelsamar.hint.saves > 0, "and what unlocking it would save")
check(J:HintText(toThelsamar.hint):find("Thelsamar, Loch Modan", 1, true), "the sentence names it: " .. J:HintText(toThelsamar.hint))

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
check(justFly and #justFly.steps == 1 and justFly.steps[1].method == "flight", "no trivial walk step: " .. tostring(justFly and #justFly.steps))
check(J:Plan(atFlightMaster, "TAXI_2").steps[1] ~= nil, "but a route that is only a tiny walk keeps it")

-- Lakeshire to Ironforge goes through Thorium Point: two tickets in the data, one flight in game. The
-- game's flight map shows a single ticket, so the plan is one step that names the stop.
maps[1433] = { name = "Redridge Mountains", mapType = 3, parentMapID = 1415 }
addon:ClearNodeNameCache()
local lakeshire = addon.World:GetNode("TAXI_5")
local fromLakeshire = J:Build(ali, { id = "YOU_ls", mapID = lakeshire.mapID, x = lakeshire.x, y = lakeshire.y })
local ticket = J:Plan(fromLakeshire, "TAXI_6")
check(ticket and #ticket.steps == 1 and ticket.steps[1].method == "flight", "Lakeshire to Ironforge is one flight step: " .. tostring(ticket and #ticket.steps))
check(ticket.steps[1].via and #ticket.steps[1].via >= 1, "that goes through another flight point")
check(ticket.steps[1].text:find("(via ", 1, true) and ticket.steps[1].text:find("Fly to Ironforge, Dun Morogh", 1, true), "and says so: " .. ticket.steps[1].text)
check(math.abs(ticket.steps[1].seconds - ticket.cost) < 1, "with the whole flight's time on it")
