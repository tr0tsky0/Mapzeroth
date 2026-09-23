-- The waypoint a player sets on the world map is a destination: read from the client, offered first among the
-- personally relevant picks, routed to on foot from wherever it can be reached, and followed to arrival.
useTestDistances()
addon.World:Build()

local maps = {
    [1453] = { name = "Stormwind City", mapType = 3, parentMapID = 1415 },
    [1455] = { name = "Ironforge", mapType = 3, parentMapID = 1415 },
    [1415] = { name = "Eastern Kingdoms", mapType = 2, parentMapID = 947 },
    [947] = { name = "Azeroth", mapType = 1, parentMapID = 0 },
}
local waypoint
C_Map = {
    GetMapInfo = function(id) return maps[id] end,
    GetWorldPosFromMapPos = function() return nil end,          -- no world position for a map we have no nodes on
    HasUserWaypoint = function() return waypoint ~= nil end,
    GetUserWaypoint = function() return waypoint end,
}
Enum = { UIMapType = { Continent = 2 } }
CreateVector2D = function(x, y) return { x = x, y = y, GetXY = function() return x, y end } end
C_TaxiMap = { GetTaxiNodesForMap = function() return {} end }
C_Spell = { GetSpellInfo = function(id) return { name = "Spell " .. id } end }
addon:ClearNodeNameCache()

local function pointAt(mapID, x, y)
    return { uiMapID = mapID, position = { GetXY = function() return x, y end } }
end

-- Reading it from the client.
check(addon:GetWaypoint() == nil, "no waypoint set: nothing")
waypoint = pointAt(1453, 0.40, 0.30)
local dest = addon:GetWaypoint()
check(dest and dest.mapID == 1453 and math.abs(dest.x - 0.40) < 1e-9 and math.abs(dest.y - 0.30) < 1e-9, "a waypoint on a map we cover is a destination")
check(dest.id:find("^WAYPOINT_1453_"), "named for the spot: " .. tostring(dest.id))
check(addon:GetWaypoint().id == dest.id, "and the same spot has the same id")
waypoint = pointAt(99999, 0.5, 0.5)
check(addon:GetWaypoint() == nil, "a map we can't place it on gives nothing")
waypoint = pointAt(1453, 0.40, 0.30)
local hasApi = C_Map.HasUserWaypoint
C_Map.HasUserWaypoint = nil
check(addon:GetWaypoint() == nil, "a client without waypoints gives nothing")
C_Map.HasUserWaypoint = hasApi

-- Offered first among the personally relevant picks.
local ctx = makeCtx({ class = "MAGE", faction = "Alliance" })
local entries = addon.Destinations:Build(ctx)
local without = addon.Sections:Build(entries, ctx, nil)
check(without[1].items[1].group ~= "waypoint", "no waypoint, no such pick")
local sections = addon.Sections:Build(entries, ctx, dest)
local pick = sections[1].items[1]
check(sections[1].id == "relevant" and pick.group == "waypoint" and pick.name == "Your Waypoint" and pick.dest == dest,
    "with a waypoint it is the first pick: " .. tostring(pick.name))
check(pick.nodeIDs[1] == dest.id, "and its node is the waypoint")

-- Routing to it: on foot from the same map; from another the graph still reaches it.
local start = { id = "YOU_way", mapID = 1453, x = 0.60, y = 0.60 }
local session = addon.Journey:Build(ctx, start, { dest })
check(session, "a session builds with the waypoint as an extra destination")
local plan = addon.Journey:PlanEntry(session, pick)
local last = plan and plan.steps[#plan.steps]
check(plan and last and last.method == "walk" and last.nodeID == dest.id, "there is a walk to it")
check(last.name == "Your waypoint" and last.text == "Walk to Your waypoint", "named for the player: " .. tostring(last and last.text))
check(plan.cost > 0, "and it takes time: " .. tostring(plan.cost))
local far = addon.Journey:Build(ctx, { id = "YOU_far", mapID = 1455, x = 0.5, y = 0.5 }, { dest })
local farPlan = far and addon.Journey:PlanEntry(far, pick)
check(farPlan and farPlan.steps[#farPlan.steps].nodeID == dest.id and farPlan.cost > plan.cost, "from another city it takes longer and still gets there")
check(addon.Journey:PlanEntry(addon.Journey:Build(ctx, start), pick) == nil, "without the extra destination in the graph there is no way there")

-- Priced like the other picks, with its zone as the place.
addon.Sections:Price(sections, session)
check(pick.eta and math.abs(pick.eta - plan.cost) < 1e-6 and pick.where == "Stormwind City", "priced, and says where: " .. tostring(pick.eta) .. " " .. tostring(pick.where))

-- Replanning after a mis-clicked flight keeps the waypoint reachable.
addon.GetPlayerStart = function() return start end
addon.GetPlayerContext = function() return ctx end
local again = addon.Journey:PlanFromHere(pick)
check(again and again.steps[#again.steps].nodeID == dest.id, "planning again from here to a waypoint works")

-- Following it: arriving within the walking radius ends the trip.
local N = addon.Navigation
N:Start(pick, plan)
local m = N:Update({ mapID = 1453, x = 0.60, y = 0.60, now = 0 })
check(m.kind == "walk" and m.distance and m.distance > 100, "on the way: a distance to it: " .. tostring(m.distance))
m = N:Update({ mapID = 1453, x = dest.x + 0.001, y = dest.y, now = 5 })
check(m.finished, "arriving at the waypoint ends the trip")
N:Stop()

-- Where flying is allowed a waypoint can be flown to from nodes in range, not only walked to: so a
-- route can end "fly to your waypoint" (Forever has no flying, so its waypoints stay walk-only, above).
local flyPath = addon.World:GetNodeContainer("TAXI_2").path
addon.Containers[flyPath] = { fly = true }
addon.World:Build()
local flySession = addon.Journey:Build(ctx, start, { dest })
local flyEdge
for _, e in ipairs(flySession.graph.adjacency["TAXI_2"] or {}) do
    if e.to == dest.id and e.method == "fly" then flyEdge = e end
end
check(flyEdge and flyEdge.cost > 0, "a flyable zone gets a fly edge to the waypoint from a node in range")
local flyPlan = addon.Journey:PlanEntry(flySession, pick)
check(flyPlan and flyPlan.steps[#flyPlan.steps].nodeID == dest.id, "and the waypoint is still reachable")
addon.Containers[flyPath] = nil
addon.World:Build()
