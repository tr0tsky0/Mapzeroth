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

-- The expensive geometry pass (walk/gate/fly edges: everything that doesn't depend on ctx) is
-- cached across Build() calls, not redone for every route -- that's what "script ran too long"
-- turned out to be (2026-09-23): the picker prices its sections with one Build(), then plans
-- the chosen route with another, and the O(n^2) fly-edge check used to run fresh both times.
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
