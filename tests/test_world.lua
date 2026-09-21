-- The Forever dataset loads, builds a container tree and validates clean.
local World = addon.World
World:Build()

local nodeCount, containerCount, continents = World:GetStats()
check(nodeCount > 90, "expected 90+ nodes, got " .. nodeCount)
check(#continents == 3, "expected 3 continents, got " .. #continents)

-- Rut'theran is an isolated child of Teldrassil, not a sibling of it.
local rut = World:GetNodeContainer("TAXI_27")
check(rut.path == "kalimdor.teldrassil.ruttheran", "TAXI_27 container: " .. rut.path)
check(rut.depth == 3, "ruttheran depth: " .. rut.depth)
check(rut.parent.path == "kalimdor.teldrassil", "ruttheran parent")
check(World:GetContinent(rut).path == "kalimdor", "continent of ruttheran")

-- No flying anywhere in Forever, by inheritance from the root.
check(World:GetFlag(rut, "fly") == false, "fly should inherit false from root")

local issues = addon:ValidateData()
for _, i in ipairs(issues) do print(i.level, i.message) end
check(#issues == 0, "expected clean validation, got " .. #issues .. " issue(s)")
