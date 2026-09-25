-- TravelGraph.DistanceProvider itself (not the useTestDistances() stand-in every other test
-- file swaps in): the real C_Map.GetWorldPosFromMapPos-backed version, and what it does with a
-- node that has no mapID -- a synthetic point built from a live sample that couldn't be placed
-- (a loading screen, an instance; see Navigation.lua's jump check) rather than one of our own,
-- always-complete authored nodes.
addon.World:Build()

local positions = {
    [1453] = { [0.5] = { [0.5] = { 1000, 2000 } }, [0.6] = { [0.5] = { 1100, 2000 } } },
}
C_Map = {
    -- The real API errors on a nil mapID (Usage: ... GetWorldPosFromMapPos(uiMapID, mapPosition));
    -- matching that here means a regression of worldPos's own guard fails this test loudly,
    -- the same way it crashed the real client, rather than silently doing something else.
    GetWorldPosFromMapPos = function(mapID, pos)
        if not mapID then error("bad argument #1 to 'GetWorldPosFromMapPos'", 2) end
        local xy = positions[mapID] and positions[mapID][pos.x] and positions[mapID][pos.x][pos.y]
        return xy and mapID, xy and { GetXY = function() return xy[1], xy[2] end }
    end,
}
CreateVector2D = function(x, y) return { x = x, y = y } end

local a = { id = "A", mapID = 1453, x = 0.5, y = 0.5 }
local b = { id = "B", mapID = 1453, x = 0.6, y = 0.5 }
check(math.abs(addon.TravelGraph.DistanceProvider(a, b) - 100) < 1e-9, "real distance between two placeable nodes")

local noMapID = { id = "JUMP", nocache = true, x = 0.5, y = 0.5 }     -- built from a sample with no mapID
check(addon.TravelGraph.DistanceProvider(a, noMapID) == nil, "a node with no mapID gives no distance, not an error")
check(addon.TravelGraph.DistanceProvider(noMapID, b) == nil, "either side")

local unplaceable = { id = "C", mapID = 99999, x = 0.5, y = 0.5 }     -- a real mapID the client just can't place
check(addon.TravelGraph.DistanceProvider(a, unplaceable) == nil, "a mapID the client can't project also gives no distance")

-- Finding 5: a node carrying `world` (the player's spot, projected once per navigation update) is used as it is,
-- with no projection of its own; the answer is the same as projecting it.
do
    local projections = 0
    local project = C_Map.GetWorldPosFromMapPos
    C_Map.GetWorldPosFromMapPos = function(mapID, pos) projections = projections + 1; return project(mapID, pos) end
    local you = { id = "YOU_NOW", nocache = true, mapID = 1453, x = 0.5, y = 0.5 }
    local projected = addon.TravelGraph.DistanceProvider(you, b)
    local made = projections
    you.world = { x = 1000, y = 2000, continent = 1453 }
    local before = projections
    check(addon.TravelGraph.DistanceProvider(you, b) == projected, "a node's own world position gives the same distance")
    check(projections == before, "and is not projected again: " .. (projections - before) .. " projections")
    check(made >= 1, "(without it the node is projected)")

    -- A whole navigation update projects the player once, however many distances it measures.
    local N = addon.Navigation
    local dest = { id = "TEST_DEST", mapID = 1453, x = 0.6, y = 0.5 }
    local plan = { steps = { { method = "walk", fromID = "YOU", nodeID = "TEST_DEST", seconds = 60, text = "walk" } } }
    N:Start({ name = "x", dest = dest }, plan)
    N:Update({ mapID = 1453, x = 0.5, y = 0.5, now = 0, onTaxi = false })
    projections = 0
    local m = N:Update({ mapID = 1453, x = 0.6, y = 0.5, now = 1, onTaxi = false })
    print(("projections in one navigation update: %d"):format(projections))
    check(projections == 1, "one update, one projection of the player: " .. projections)
    check(m.finished, "and the trip still ends at the destination")
    N:Stop()
    C_Map.GetWorldPosFromMapPos = project
end

-- The expensive geometry pass (walk/gate/fly edges: everything that doesn't depend on ctx) is
-- cached across Build() calls, not redone for every route -- that's what "script ran too long"
-- turned out to be (2026-09-23): the picker prices its sections with one Build(), then plans
-- the chosen route with another, and the O(n^2) fly-edge check used to run fresh both times.
-- (Counted on the live pass: a shipped Geometry.lua would be served with no pass at all; see below for that.)
addon.Geometry, addon.GeometryMeta = nil, nil
addon.World:Build()
local ctx1 = makeCtx({})
local ctx2 = makeCtx({ class = "WARRIOR" })
local before = addon.TravelGraph.staticBuildCount
addon.TravelGraph:Build(ctx1)
addon.TravelGraph:Build(ctx1)
addon.TravelGraph:Build(ctx2)         -- a different ctx doesn't matter: geometry isn't ctx-dependent
check(addon.TravelGraph.staticBuildCount == before + 1, "three Build() calls, one geometry pass: " ..
    tostring(addon.TravelGraph.staticBuildCount - before))
addon.World:Build()                    -- new world data: the geometry cache must not serve stale edges
addon.TravelGraph:Build(ctx1)
check(addon.TravelGraph.staticBuildCount == before + 2, "a World:Build() invalidates the cache: " ..
    tostring(addon.TravelGraph.staticBuildCount - before))

-- A shipped Data/<ruleset>/Geometry.lua (addon.Geometry + addon.GeometryMeta) is used as-is --
-- no live pass at all -- only when its recorded node count matches what's actually loaded; a
-- mismatch (a forgotten regeneration after a data change) falls back to computing it live
-- instead of silently serving stale edges.
local function nodeCount()
    local n = 0
    addon.World:ForEachNode(function() n = n + 1 end)
    return n
end
local function hasEdgeTo(graph, from, to)
    for _, e in ipairs(graph.adjacency[from] or {}) do
        if e.to == to then return true end
    end
    return false
end

addon.Geometry = { ["TAXI_2"] = { { "MADE_UP_DESTINATION", 42, "walk" } } }
addon.GeometryMeta = { nodeCount = nodeCount() - 1 }    -- deliberately wrong
addon.World:Build()
local beforeMismatch = addon.TravelGraph.staticBuildCount
local graph = addon.TravelGraph:Build(ctx1)
check(addon.TravelGraph.staticBuildCount == beforeMismatch + 1, "a mismatched node count is ignored, computed live instead")
check(not hasEdgeTo(graph, "TAXI_2", "MADE_UP_DESTINATION"), "so the bogus shipped edge never appears")

addon.GeometryMeta.nodeCount = nodeCount()    -- now matches
addon.World:Build()
local beforeMatch = addon.TravelGraph.staticBuildCount
graph = addon.TravelGraph:Build(ctx1)
check(addon.TravelGraph.staticBuildCount == beforeMatch, "a matching node count is used as-is: no live pass at all")
check(hasEdgeTo(graph, "TAXI_2", "MADE_UP_DESTINATION"), "and the shipped edge is really what's used")
addon.Geometry, addon.GeometryMeta = nil, nil

-- World coordinates are per continent (the first thing GetWorldPosFromMapPos returns): two places on
-- different continents can share x/y, and were measured as neighbours -- a waypoint in Hyjal got a
-- 19 s "fly" from Eversong. No distance between continents.
positions[2] = { [0.5] = { [0.5] = { 1000, 2000 } } }
C_Map.GetWorldPosFromMapPos = function(mapID, pos)
    local xy = positions[mapID] and positions[mapID][pos.x] and positions[mapID][pos.x][pos.y]
    local continent = mapID == 2 and 2 or 1
    return xy and continent, xy and { GetXY = function() return xy[1], xy[2] end }
end
local sameSpotElsewhere = { id = "ELSEWHERE", mapID = 2, x = 0.5, y = 0.5 }     -- same x/y as A, another continent
check(addon.TravelGraph.DistanceProvider(a, sameSpotElsewhere) == nil, "the same coordinates on another continent are not close")
check(addon.TravelGraph.DistanceProvider(a, b) ~= nil, "and two places on one continent still measure")

-- An authored walk edge with no cost, between two places the client can't measure a distance for (Oribos and
-- its Ring), is kept at a default price, not silently dropped: dropping it cut off the flight master, and the
-- four zones' flights with it.
addon.TravelGraph.DistanceProvider = function() return nil end
local savedEdges = addon.Edges
addon.Edges = { { from = "TAXI_2", to = "TAXI_6", method = "walk" } }
addon.World:Build()
local kept = addon.TravelGraph:Build(ctx1)
local unmeasured
for _, e in ipairs(kept.adjacency["TAXI_2"] or {}) do
    if e.to == "TAXI_6" and e.method == "walk" then unmeasured = e.cost end
end
check(unmeasured == addon.UNMEASURED_WALK_SECONDS, "a walk edge that can't be measured keeps a default cost: " .. tostring(unmeasured))
addon.Edges = savedEdges

-- Finding 4a: the geometry as finished edge tables is materialised once per (world generation, ground speeds)
-- and shared, by reference, between the graphs built from it -- the flight hint's second graph included.
do
    local TG = addon.TravelGraph
    useTestDistances()
    addon.Geometry, addon.GeometryMeta = nil, nil
    addon.World:Build()

    -- A node with a geometry walk edge (no `source`: authored edges carry theirs).
    local function geometryWalk(graph)
        for from, list in pairs(graph.adjacency) do
            for i, e in ipairs(list) do
                if e.method == "walk" and e.source == nil and e.cost > 0 then return from, i end
            end
        end
    end
    local function walkCost(graph, from, to)
        for _, e in ipairs(graph.adjacency[from]) do
            if e.to == to and e.method == "walk" and e.source == nil then return e.cost end
        end
    end

    local plain = makeCtx({})
    local g1 = TG:Build(plain)
    local materialised = TG.materialiseCount
    local statics = TG.staticBuildCount
    local g2 = TG:Build(makeCtx({ class = "WARRIOR" }))
    check(TG.materialiseCount == materialised, "an equal-speed context materialises nothing")
    local x, i = geometryWalk(g1)
    check(x, "there is a geometry walk edge to look at")
    check(g1.adjacency[x][i] == g2.adjacency[x][i], "two builds share the edge table for a geometry edge")
    check(g1.adjacency ~= g2.adjacency and g1.adjacency[x] ~= g2.adjacency[x], "but each build has its own adjacency lists")

    -- Same routes over the shared edges (the values the pathfinder tests expect).
    local r1 = addon.Pathfinder:FindPath(g1, "TAXI_2", "TAXI_6")
    local r2 = addon.Pathfinder:FindPath(g2, "TAXI_2", "TAXI_6")
    check(r1 and r2 and r1.cost == r2.cost and methods(r1) == methods(r2), "the same route over the shared edges")
    check(math.abs(r1.cost - 259) < 1 and methods(r1) == "taxi", "Stormwind -> Ironforge is still the 259 s flight: " .. r1.cost)
    local h1 = addon.Pathfinder:FindPath(g1, "TAXI_2", "TAXI_19")
    local h2 = addon.Pathfinder:FindPath(g2, "TAXI_2", "TAXI_19")
    check(h1 and h2 and h1.cost == h2.cost and methods(h1) == methods(h2), "and Stormwind -> Booty Bay")

    -- Another riding skill is another speed: other walk costs, one more materialisation, no new geometry pass.
    local riding = TG:Build(makeCtx({ spells = { 33388 } }))
    check(TG.materialiseCount == materialised + 1, "a different riding skill materialises once more")
    check(TG.staticBuildCount == statics, "and the geometry pass is not run again")
    local to = g1.adjacency[x][i].to
    check(walkCost(riding, x, to) < walkCost(g1, x, to), "outdoors the mounted walk is cheaper")
    check(riding.adjacency[x][i] ~= g1.adjacency[x][i], "and it is a different edge table")
    TG:Build(makeCtx({ spells = { 33388 } }))
    check(TG.materialiseCount == materialised + 1, "the second build with that skill is a cache hit")

    -- New world data drops the cache.
    addon.World:Build()
    local g3 = TG:Build(plain)
    check(TG.materialiseCount == materialised + 2, "a World:Build() invalidates the materialised edges")
    check(g3.adjacency[x][i] ~= g1.adjacency[x][i], "no edge table survives it")

    -- Only a handful of speeds are kept: a fifth different speed pushes the oldest out.
    local walkSpeed = addon.WALK_SPEED
    local before = TG.materialiseCount
    for n = 1, 5 do
        addon.WALK_SPEED = walkSpeed + n
        TG:Build(plain)
    end
    check(TG.materialiseCount == before + 5, "five new speeds, five materialisations")
    addon.WALK_SPEED = walkSpeed
    TG:Build(plain)
    check(TG.materialiseCount == before + 6, "the oldest entry was evicted, so the original speed is made again")
    addon.WALK_SPEED = walkSpeed
    print(("materialiseCount %d, staticBuildCount %d after the finding 4a checks"):format(TG.materialiseCount, TG.staticBuildCount))
end
