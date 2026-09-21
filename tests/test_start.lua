-- The player's own position as a starting point, and the cost of everywhere at once.
useTestDistances()
addon.World:Build()

-- A city map belongs to the container its nodes sit in.
local container = addon.World:GetContainerForMap(1453)
check(container and container.path == "easternkingdoms.elwynn_forest", "Stormwind's map is in the Elwynn container")
check(addon.World:GetContainerForMap(99999) == nil, "a map with no nodes has no container")

local ali = makeCtx({ faction = "Alliance" })
local graph = addon.TravelGraph:Build(ali)

-- Standing in Stormwind, a little away from its flight master.
local start = { id = "YOU_1", mapID = 1453, x = 0.60, y = 0.60 }
check(addon.TravelGraph:AddStart(graph, ali, start), "a start on a known map is added")
check(not addon.TravelGraph:AddStart(graph, ali, { id = "YOU_2", mapID = 99999, x = 0.5, y = 0.5 }), "one on an unknown map is refused")

local toStormwindFM = addon.Pathfinder:FindPath(graph, "YOU_1", "TAXI_2")
check(toStormwindFM and #toStormwindFM.steps == 1 and toStormwindFM.steps[1].method == "walk", "you walk to the flight master")

local toIronforge = addon.Pathfinder:FindPath(graph, "YOU_1", "TAXI_6")
check(toIronforge and methods(toIronforge) == "walk,flight", "then fly: " .. tostring(toIronforge and methods(toIronforge)))
check(toIronforge.cost > toStormwindFM.cost, "the trip costs more than the walk")

-- One search gives the cost of every reachable node, and agrees with a single route.
local costs = addon.Pathfinder:FindCosts(graph, "YOU_1")
check(math.abs(costs["TAXI_6"] - toIronforge.cost) < 1e-6, "cost to Ironforge matches the route")
check(math.abs(costs["TAXI_2"] - toStormwindFM.cost) < 1e-6, "cost to Stormwind's flight master matches")
check(costs["YOU_1"] == nil, "the start isn't listed")
check(costs["TAXI_23"] ~= nil, "even another continent is priced (by boat or flight)")
