-- A city is enclosed: on foot, getting in or out goes through its gate. Nothing walks straight through the wall,
-- and the two sides of the gate are one step with no time of its own.
useTestDistances()
addon.World:Build()

addon.GetNodeName = function(_, id) return "Place " .. id end       -- names come from the client
local TravelGraph = addon.TravelGraph
local ali = makeCtx({ faction = "Alliance" })

-- Stormwind's gate: an entrance on the city's own map (inside) and one on the zone's (outside).
local inner, outer
addon.World:ForEachNode(function(node)
    if node.kind == "entrance" and node.city == "stormwind" then
        if node.mapID == addon.Cities.stormwind.mapID then inner = node else outer = node end
    end
end)
check(inner and outer and inner.mapID ~= outer.mapID, "Stormwind has a gate node on each side of its wall")
local bank = addon.World:GetNode("BANK_C1453_638_808")
local border = addon.World:GetNode("BORDER_ELWYNN_FOREST_TO_WESTFALL")
check(bank and border and bank.mapID == inner.mapID and border.mapID == outer.mapID, "a bank inside and a border crossing outside")

local graph = TravelGraph:Build(ali)
local function edge(from, to)
    for _, step in ipairs(graph.adjacency[from] or {}) do if step.to == to and step.method == "walk" then return step end end
end
check(not edge(border.id, bank.id) and not edge(bank.id, border.id), "no walking edge straight through the wall")
check(edge(bank.id, "TAXI_2") and edge("TAXI_2", bank.id), "inside the city everything is joined")
check(edge(border.id, outer.id), "outside it, everything is joined to the gate")
local hop = edge(inner.id, outer.id)
check(hop and hop.cost == 0 and edge(outer.id, inner.id).cost == 0, "the two sides of the gate are joined by a step that takes no time")

-- A route in goes to the gate, through it, and on to the bank.
local result = addon.Pathfinder:FindPath(graph, border.id, bank.id)
local via = {}
for _, step in ipairs(result.steps) do via[#via + 1] = step.to end
check(via[#via] == bank.id and table.concat(via, ">"):find(outer.id .. ">" .. inner.id, 1, true),
    "from Elwynn to the bank: the outer gate, then the inner one, then the bank: " .. table.concat(via, ">"))
local collapsed = addon.Pathfinder:CollapseSteps(result.steps)
check(#collapsed == 3 and collapsed[1].to == outer.id and collapsed[3].to == bank.id and collapsed[2].cost == 0,
    "as steps: walk to the gate, through it, walk to the bank: " .. #collapsed)

-- And out again.
local back = addon.Pathfinder:FindPath(graph, bank.id, border.id)
local out = {}
for _, step in ipairs(back.steps) do out[#out + 1] = step.to end
check(table.concat(out, ">"):find(inner.id .. ">" .. outer.id, 1, true), "and out through the same gate: " .. table.concat(out, ">"))

-- A player standing inside the city, or a destination in it, is walled the same way.
local session = addon.Journey:Build(ali, { id = "YOU_inside", mapID = inner.mapID, x = 0.6, y = 0.6 })
local toBorder = addon.Journey:Plan(session, border.id)
local ids = {}
for _, step in ipairs(toBorder.steps) do ids[#ids + 1] = step.nodeID end
check(ids[1] == inner.id and ids[#ids] == border.id, "a player inside walks to the gate first (the step through it takes no time, so it isn't shown): " .. table.concat(ids, ">"))
local waypoint = { id = "WAYPOINT_test", mapID = inner.mapID, x = 0.5, y = 0.5 }
local outside = addon.Journey:Build(ali, { id = "YOU_outside", mapID = outer.mapID, x = 0.5, y = 0.5 }, { waypoint })
local toWaypoint = addon.Journey:Plan(outside, waypoint.id)
ids = {}
for _, step in ipairs(toWaypoint.steps) do ids[#ids + 1] = step.nodeID end
check(table.concat(ids, ">"):find(outer.id, 1, true) and ids[#ids] == waypoint.id, "a waypoint inside a city is reached through its gate: " .. table.concat(ids, ">"))
local direct = addon.Journey:Build(ali, { id = "YOU_in2", mapID = inner.mapID, x = 0.2, y = 0.2 }, { waypoint })
local inCity = addon.Journey:Plan(direct, waypoint.id)
check(#inCity.steps == 1 and inCity.steps[1].nodeID == waypoint.id, "and one inside the same city is a plain walk")

-- A building within a city can be walled the same way, but by container instead of map (both sides
-- share Stormwind's own mapID): the Wizard's Sanctum, where the Dalaran portal exits.
local sanctumOuter = addon.World:GetNode("ENTRANCE_SW_WIZARDS_SANCTUM_OUTER")
local sanctumInner = addon.World:GetNode("ENTRANCE_SW_WIZARDS_SANCTUM_INNER")
local portalExit = addon.World:GetNode("PORTAL_STORMWIND_DALARAN")
check(sanctumOuter and sanctumInner and portalExit, "the Sanctum's gate and the portal it holds exist")
check(sanctumOuter.mapID == sanctumInner.mapID and sanctumOuter.mapID == bank.mapID, "all on Stormwind's own map, unlike a whole city's gate")
check(not edge(bank.id, portalExit.id) and not edge(portalExit.id, bank.id), "no straight line from the bank into the Sanctum")
local sanctumHop = edge(sanctumOuter.id, sanctumInner.id)
check(sanctumHop and sanctumHop.cost == 0 and edge(sanctumInner.id, sanctumOuter.id).cost == 0, "its door takes no time either")
local outOfSanctum = addon.Pathfinder:FindPath(graph, portalExit.id, bank.id)
local sanctumVia = {}
for _, step in ipairs(outOfSanctum.steps) do sanctumVia[#sanctumVia + 1] = step.to end
check(table.concat(sanctumVia, ">"):find(sanctumInner.id .. ">" .. sanctumOuter.id, 1, true) and sanctumVia[#sanctumVia] == bank.id,
    "from the portal to the bank: out through the Sanctum's own door first: " .. table.concat(sanctumVia, ">"))

-- Cities that aren't enclosed are left alone: Dalaran's map is its zone's, and it has no gate pair.
local dalaranDock, alterac = addon.World:GetNode("DOCK_DALARAN"), nil
addon.World:ForEachNode(function(node) if node.id:find("^BORDER_ALTERAC") then alterac = alterac or node end end)
local dalaran = addon.Pathfinder:FindPath(graph, dalaranDock.id, alterac.id)
local touchesGate = false
for _, step in ipairs(dalaran.steps) do if step.to:find("^ENTRANCE") then touchesGate = true end end
check(dalaran and not touchesGate, "Dalaran, not enclosed, is walked straight")
