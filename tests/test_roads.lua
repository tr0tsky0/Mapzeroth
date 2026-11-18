-- Roads (RoadNet.lua): the way along the road between two points, when it is worth taking; walks drawn along it
-- (MapRoute:DrawnPath); walks priced by it in a geometry dump; and each map's factor from its roads.
local RoadNet, TravelGraph, MapRoute = addon.RoadNet, addon.TravelGraph, addon.MapRoute
local shipped = addon.RoadData
check(shipped and shipped[0] and shipped[1] and #shipped[0] > 100 and #shipped[1] > 100 and shipped[2991] and #shipped[2991] > 0,
    "Forever ships roads for Eastern Kingdoms, Kalimdor and Zephras Isle")

-- A small made-up network on continent 7: an L from (0,0) east to (1000,0) and north to (1000,1000), and a spur
-- from the corner on east to (2000,0).
addon.RoadData = { [7] = {
    { 0, 0, 1000, 0 },
    { 1000, 0, 1000, 1000 },
    { 1000, 0, 2000, 0 },
} }
RoadNet:Reset()
local function near(a, b, tol) return a and b and math.abs(a - b) <= (tol or 1e-6) end

-- Choosing the way, open ground scores OFFROAD (1.8) a yard of road. A goal off to the side of the spur is walked to
-- along the road, leaving it at the best slant, not square on: (distance from the road) / sqrt(1.8^2 - 1) short of
-- the foot. What comes back is the walk's real length: on, along, off.
check(addon.Options:Get("roadPreference") == 3 and RoadNet:Offroad() == 1.8 and RoadNet:DefaultOffroad() == 1.8,
    "open ground scores 1.8 a yard of road, the middle of the setting")
local r = 1 / math.sqrt(1.8 ^ 2 - 1)
local road, straight, points = RoadNet:Route(7, 0, -10, 1500, 400)
local exitX = 1500 - 400 * r
local expect = math.sqrt((10 * r) ^ 2 + 100) + (exitX - 10 * r) + math.sqrt((400 * r) ^ 2 + 400 ^ 2)
check(road and near(road, expect, 0.01), ("along the road, then across: %s vs %.1f"):format(tostring(road), expect))
check(near(straight, math.sqrt(1500 ^ 2 + 410 ^ 2)), "the straight line is known too")
check(#points == 3 and near(points[1].x, 10 * r) and points[1].y == 0 and points[2].x == 1000 and points[2].y == 0
    and near(points[3].x, exitX) and points[3].y == 0, "joins at a slant, follows the road, leaves before the foot")

-- Round a right angle (the road 1.41 times the straight line): the road, as Westfall's through Sentinel Hill.
road, straight, points = RoadNet:Route(7, 0, -10, 1010, 1000)
check(road and #points == 3 and points[2].x == 1000 and points[2].y == 0 and near(points[3].y, 1000 - 10 * r)
    and near(road, 2 * math.sqrt((10 * r) ^ 2 + 100) + 2000 - 20 * r, 0.01), "a goal round a corner goes by the road")
-- Both ends beside one stretch: on, along, off, without reaching either end of it.
road, straight, points = RoadNet:Route(7, 100, 5, 900, 5)
check(near(road, 2 * math.sqrt((5 * r) ^ 2 + 25) + 800 - 10 * r, 0.01) and #points == 2
    and near(points[1].x, 100 + 5 * r) and near(points[2].x, 900 - 5 * r), "along one stretch: " .. tostring(road))
-- No road near, a walk too short to bother with, a continent with no roads.
check(RoadNet:Route(7, 5000, 5000, 6000, 5000) == nil, "no road near")
check(RoadNet:Route(7, 100, 0, 130, 0) == nil, "a walk of a few yards is straight")
check(RoadNet:Route(8, 0, 0, 1000, 0) == nil, "no roads on a continent without data")
-- Along two lines that meet: the corner is passed through.
road = RoadNet:Route(7, 200, 0, 1800, 0)
check(near(road, 1600), "straight along two lines that meet: " .. tostring(road))
check(near((RoadNet:Nearest(7, 500, 30)), 30), "the nearest road is 30 yd off")

-- Big water (RoadWater, a hand-drawn shore): a lake inside the L, x and y 200 to 800, and a pond out east. Across
-- it a yard scores WATER (3) times open ground, and takes SWIM (1.5) times as long.
do
    local shippedWater = addon.RoadWater
    addon.RoadWater = { [7] = { { 200, 200, 800, 200, 800, 800, 200, 800 }, { 4900, 4900, 5100, 4900, 5100, 5100, 4900, 5100 } } }
    RoadNet:Reset()
    check(near(RoadNet:WetYards(7, 0, 500, 1000, 500), 600), "600 yd of the line across the lake is water")
    check(near(RoadNet:WetYards(7, 500, 500, 1000, 500), 300), "from the middle: 300 yd")
    check(RoadNet:WetYards(7, 0, 900, 1000, 900) == 0, "past the shore, none")
    -- From the lake's far side to the road's corner arm: without the lake straight across (1000 yd, scoring 1800)
    -- beats the road round; with it the walk goes onto the bottom road, round the corner and up.
    addon.RoadWater = { [7] = {} }
    RoadNet:Reset()
    check(RoadNet:Route(7, 0, 500, 1000, 500) == nil, "no lake: straight across")
    addon.RoadWater = { [7] = { { 200, 200, 800, 200, 800, 800, 200, 800 } } }
    RoadNet:Reset()
    local around, straight, points = RoadNet:Route(7, 0, 500, 1000, 500)
    check(around and straight == 1000 and #points >= 2 and points[#points].x == 1000,
        "the lake sends it round by the road: " .. tostring(around))
    check(around < 1000 * 1.5 + 600 * 0.5 + 1000, "timed by its real length: " .. tostring(around))
    -- No road near enough: straight across, swimming, timed slower, nothing to draw.
    addon.RoadWater = { [7] = { { 4900, 4900, 5100, 4900, 5100, 5100, 4900, 5100 } } }
    RoadNet:Reset()
    local swim, flat, none = RoadNet:Route(7, 4500, 5000, 5500, 5000)
    check(near(swim, 1000 + 0.5 * 200) and flat == 1000 and #none == 0, "swum straight: " .. tostring(swim))
    addon.RoadWater = shippedWater
    RoadNet:Reset()
end

-- Steep ground (RoadSteep, rows of cells from the terrain's heights). Made up here with 10-yd cells from origin
-- 10000: row r is x from 10000 - 10r down, column c is y from 10000 - 10c down.
do
    local shippedSteep = addon.RoadSteep
    local DIGITS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_"
    local function num(v)
        local s = ""
        while v >= 32 do s = s .. DIGITS:sub(33 + v % 32, 33 + v % 32); v = math.floor(v / 32) end
        return s .. DIGITS:sub(v + 1, v + 1)
    end
    -- Boxes of steep cells: { x from, x to, y from, y to } (x and y in (from, to]).
    local function grid(boxes)
        local rows, r0, r1 = {}, math.huge, -math.huge
        local runs = {}
        for _, b in ipairs(boxes) do
            for r = (10000 - b[2]) / 10, (10000 - b[1]) / 10 - 1 do
                runs[r] = runs[r] or {}
                table.insert(runs[r], { (10000 - b[4]) / 10, (b[4] - b[3]) / 10 })
                r0, r1 = math.min(r0, r), math.max(r1, r)
            end
        end
        for r = r0, r1 do
            local s, prev = "", 0
            table.sort(runs[r] or {}, function(a, b) return a[1] < b[1] end)
            for _, run in ipairs(runs[r] or {}) do s = s .. num(run[1] - prev) .. num(run[2]); prev = run[1] + run[2] end
            rows[#rows + 1] = s
        end
        rows.r0 = r0
        return { cell = 10, origin = 10000, [7] = rows }
    end
    -- A steep box north of the bottom road, x 400 to 600 and y 100 to 300, and a second one in the same rows far
    -- off at y 2000 to 2100 (two runs in a row).
    addon.RoadSteep = grid({ { 400, 600, 100, 300 }, { 400, 600, 2000, 2100 } })
    RoadNet:Reset()
    check(near(RoadNet:SteepYards(7, 500, -500, 500, 500), 200, 5), "200 yd of the line is steep: "
        .. RoadNet:SteepYards(7, 500, -500, 500, 500))
    check(near(RoadNet:SteepYards(7, 500, 0, 500, 3000), 300, 5), "both boxes in one row: "
        .. RoadNet:SteepYards(7, 500, 0, 500, 3000))
    check(RoadNet:SteepYards(7, 300, -500, 300, 500) == 0, "beside it, none")
    check(near(RoadNet:SteepYards(7, 300, 0, 700, 400), 200 * math.sqrt(2), 10), "corner to corner: "
        .. RoadNet:SteepYards(7, 300, 0, 700, 400))
    -- Up from below the road to above the box: straight (500 yd, 200 of them steep) when the ground is flat; with
    -- the box, along the road and up past its side.
    addon.RoadSteep = nil
    RoadNet:Reset()
    check(RoadNet:Route(7, 500, -100, 500, 400) == nil, "flat ground: straight up")
    addon.RoadSteep = grid({ { 400, 600, 100, 300 } })
    RoadNet:Reset()
    local round, straight, points = RoadNet:Route(7, 500, -100, 500, 400)
    check(round and straight == 500 and #points >= 2, "the steep box sends it by the road: " .. tostring(round))
    local last = points and points[#points]
    check(last and RoadNet:SteepYards(7, last.x, last.y, 500, 400) < 1, "and off the road clear of the box")
    addon.RoadSteep = shippedSteep
    RoadNet:Reset()
end

-- Two places, through their world positions (stubbed here: x, y as given, all on continent 7).
local realWorld = TravelGraph.WorldPosition
TravelGraph.WorldPosition = function(p) return p.wx, p.wy, p.continent end
local A = { wx = 0, wy = -10, continent = 7 }
local B = { wx = 1500, wy = 400, continent = 7 }
road = RoadNet:Between(A, B)
check(near(road, expect, 0.01), "between two places")
check(RoadNet:Between(A, { wx = 1010, wy = 1000, continent = 9 }) == nil, "not between two continents")
-- No roads in a capital on its own map (Undercity lies under Tirisfal's), but Dalaran is part of Alterac's map.
check(RoadNet:Between({ wx = 0, wy = -10, continent = 7, mapID = 1458 }, B) == nil, "no roads in Undercity")
check(RoadNet:Between(A, { wx = 1500, wy = 400, continent = 7, mapID = 1453 }) == nil, "nor into Stormwind")
check(RoadNet:Between({ wx = 0, wy = -10, continent = 7, mapID = 1416 }, B), "Alterac's roads, Dalaran and all")

-- A capital's own streets (CityPaths.lua): Stormwind's are drawn. A made-up city on map 9999, placed into the world
-- at 1000 yd a map unit, right on top of the terrain roads above: its walks go by its streets, never those roads.
check(addon.CityPaths and addon.CityPaths[1453] and #addon.CityPaths[1453] > 50, "Stormwind's streets ship")
do
    local shippedCities, stub = addon.CityPaths, TravelGraph.WorldPosition
    local streets = { { 0.1, 0.5, 0.9, 0.5 }, { 0.9, 0.5, 0.9, 0.1 } }
    addon.CityPaths = { [9999] = streets, [1453] = streets }
    TravelGraph.WorldPosition = function(p)
        if p.mapID == 9999 or p.mapID == 1453 then return p.x * 1000, p.y * 1000, 7 end
        return stub(p)
    end
    RoadNet:Reset()
    local inA = { mapID = 9999, x = 0.1, y = 0.52 }
    local inB = { mapID = 9999, x = 0.88, y = 0.1 }
    local len, straight, points, continent = RoadNet:Between(inA, inB)
    check(len and continent == 7 and #points == 3 and points[2].x == 900 and points[2].y == 500,
        "a walk in the city goes by its streets, round the corner")
    check(points[1].x == 100 and points[1].y == 500 and points[3].x == 900 and points[3].y == 100,
        "joining the street nearest each end, not the terrain road at y 0")
    -- Streets only: the two ends of a U are close across its gap (a harbour wall, say), but the walk goes round it.
    addon.CityPaths[9999] = { { 0.1, 0.5, 0.9, 0.5 }, { 0.9, 0.5, 0.9, 0.9 }, { 0.9, 0.9, 0.2, 0.9 } }
    RoadNet:Reset()
    local uLen, uStraight, uPoints = RoadNet:Between({ mapID = 9999, x = 0.1, y = 0.52 }, { mapID = 9999, x = 0.2, y = 0.88 })
    check(uLen and near(uLen, 20 + 800 + 400 + 700 + 20, 1e-6) and #uPoints == 4 and uPoints[2].x == 900 and uPoints[3].y == 900,
        ("round the U by its streets, not across the gap: %s yd for a %.0f yd straight line"):format(tostring(uLen), uStraight or 0))
    addon.Options:Set("roadPreference", 1)
    check(near(RoadNet:Between({ mapID = 9999, x = 0.1, y = 0.52 }, { mapID = 9999, x = 0.2, y = 0.88 }), uLen, 1e-6),
        "the Walking routes setting doesn't change a city's walk")
    addon.Options:Set("roadPreference", 3)
    addon.CityPaths[9999] = streets
    RoadNet:Reset()
    -- An unmeasured city's streets time its walks; a measured one's (Stormwind, PathFactors.lua) are only drawn.
    local _, _, _, _, drawOnly = RoadNet:Between(inA, inB)
    check(drawOnly == false, "an unmeasured city is timed by its streets")
    local swLen, _, swPoints, _, swDrawOnly = RoadNet:Between({ mapID = 1453, x = 0.1, y = 0.52 }, { mapID = 1453, x = 0.88, y = 0.1 })
    check(swLen and #swPoints == 3 and swDrawOnly == true, "Stormwind's streets are drawn, its measured walking kept")
    -- Without drawn streets, a capital's walks still have none.
    check(RoadNet:Between({ wx = 0, wy = 0, continent = 7, mapID = 1458 }, { wx = 900, wy = 900, continent = 7, mapID = 1458 }) == nil,
        "Undercity has no streets drawn yet: none")
    addon.CityPaths, TravelGraph.WorldPosition = shippedCities, stub
    RoadNet:Reset()
end

-- A walk drawn along the road: its own points stay, the road's go between them as world points.
local expanded = RoadNet:Expand({ A, B })
check(#expanded == 5 and expanded[1] == A and expanded[5] == B and expanded[3].world.x == 1000
    and expanded[3].world.continent == 7, "a walk's path gets the road's way in between")
local step = { method = "walk", path = { A, B } }
local drawn = MapRoute:DrawnPath(step)
check(#drawn == 5 and MapRoute:DrawnPath(step) == drawn, "drawn along the road, worked out once")
step.path[#step.path + 1] = { wx = 1010, wy = 1200, continent = 7 }
check(MapRoute:DrawnPath(step) ~= drawn, "worked out again when the walk's path grows")
local flight = { method = "taxi", path = { A, B } }
check(MapRoute:DrawnPath(flight) == flight.path, "a flight is drawn as it is")

-- The player's setting, from across country to roads. The way round the corner (the road 1.41 times the straight
-- line) is straight across at the first level, by the road at the middle and the last.
local corner = { wx = 1010, wy = 1000, continent = 7 }
addon.Options:Set("roadPreference", 1)
check(RoadNet:Offroad() == 1.25 and RoadNet:Between(A, corner) == nil, "across country: straight round the corner")
addon.Options:Set("roadPreference", 5)
check(RoadNet:Offroad() == 3.5 and RoadNet:Between(A, corner), "roads: round by the road")
addon.Options:Set("roadPreference", 9)
check(addon.Options:Get("roadPreference") == 5, "the setting stays within its five levels")
-- A walk drawn at one level is drawn again at another.
local walk = { method = "walk", path = { A, corner } }
addon.Options:Set("roadPreference", 1)
local across = MapRoute:DrawnPath(walk)
addon.Options:Set("roadPreference", 3)
local byRoad = MapRoute:DrawnPath(walk)
check(#across == 2 and #byRoad > 2, "changing the setting redraws the walk: " .. #across .. " then " .. #byRoad)
-- Walk times shipped in a geometry dump don't depend on whoever ran it: the middle level, always.
addon.Options:Set("roadPreference", 1)
check(RoadNet:Between(A, corner, RoadNet:DefaultOffroad()), "the shipped level is passed through")
addon.Options:Set("roadPreference", 3)

-- Placing a road point on the map goes through the world, not a map of its own.
do
    local realMap = C_Map
    C_Map = { GetMapPosFromWorldPos = function(continent, world, mapID)
        return mapID, CreateVector2D(world.x / 10000, world.y / 10000)
    end }
    local x, y = addon.Navigation.MapPoint({ world = { x = 1000, y = 2000, continent = 7 } }, 1429)
    check(near(x, 0.1) and near(y, 0.2), "a world point is placed through GetMapPosFromWorldPos")
    C_Map = realMap
end

-- A geometry dump prices a walk by its road, and notes the ratio for its map.
useTestDistances()
addon.World:Build()
local geometry = TravelGraph:BuildFreshGeometry()
local a, b, plain
for from, list in pairs(geometry) do
    for _, e in ipairs(list) do
        local na, nb = addon.World:GetNode(from), addon.World:GetNode(e[1])
        if e[3] == "walk" and na and nb and na.mapID == nb.mapID and TravelGraph.DistanceProvider(na, nb) > 300 then
            a, b, plain = na, nb, e[2]
            break
        end
    end
    if a then break end
end
check(a and b, "two walkable places on one map")
-- Their world positions in the test's yards, and a road between them with a kink in it: 1.2 times as long.
TravelGraph.WorldPosition = function(p)
    if p.wx then return p.wx, p.wy, p.continent end
    return p.x * 2500, p.y * 1700, 7
end
local ax, ay = TravelGraph.WorldPosition(a)
local bx, by = TravelGraph.WorldPosition(b)
local mx, my = (ax + bx) / 2, (ay + by) / 2
local dx, dy = bx - ax, by - ay
local len = math.sqrt(dx * dx + dy * dy)
local off = len * math.sqrt(0.36 - 0.25)           -- a kink this far out makes the road 1.2 x the straight line
local kx, ky = mx - dy / len * off, my + dx / len * off
addon.RoadData = { [7] = { { math.floor(ax + 0.5), math.floor(ay + 0.5), math.floor(kx + 0.5), math.floor(ky + 0.5),
    math.floor(bx + 0.5), math.floor(by + 0.5) } } }
RoadNet:Reset()
local ratios = {}
local priced = TravelGraph:BuildFreshGeometry({ roads = true, ratios = ratios })
local roadDtf
for _, e in ipairs(priced[a.id] or {}) do if e[1] == b.id and e[3] == "walk" then roadDtf = e[2] end end
check(roadDtf and near(roadDtf, len * 1.2, 3), ("the walk costs its road: %s vs %.0f"):format(tostring(roadDtf), len * 1.2))
check(roadDtf ~= plain, "not the straight line times a factor")
local noted = false
for _, r in ipairs(ratios[a.mapID] or {}) do if near(r, 1.2, 0.01) then noted = true end end
check(noted, "its ratio is noted for the map")
-- Run as a coroutine, it yields along the way and still finishes.
local yields = 0
local co = coroutine.create(function() return TravelGraph:BuildFreshGeometry({ roads = true, yieldEvery = 5 }) end)
local ok, result = coroutine.resume(co)
while coroutine.status(co) ~= "dead" do yields = yields + 1; ok, result = coroutine.resume(co) end
check(ok and type(result) == "table" and yields > 0, "the dump runs across frames: " .. yields .. " yields")

-- Map factors: measured first, then the roads', then the default.
addon.GeometryPacked = { mapFactors = { [a.mapID] = 1.33, [1453] = 1.2 } }
local measured = addon.PathFactors[a.mapID]
check(near(TravelGraph.MapFactor(a.mapID), measured or 1.33), "a map's road factor applies unless it was measured")
check(TravelGraph.MapFactor(1453) == addon.PathFactors[1453], "Stormwind's measured factor beats a road one")
check(TravelGraph.MapFactor(99999) == addon.DEFAULT_PATH_FACTOR, "a map with neither has the default")

-- A chosen plan's walks are timed again as they are drawn. Back on the made-up network: a 100 s walk round the corner,
-- priced (as a walk from the player's spot is) at the straight line times the default factor.
do
    addon.RoadData = { [7] = { { 0, 0, 1000, 0 }, { 1000, 0, 1000, 1000 }, { 1000, 0, 2000, 0 } } }
    RoadNet:Reset()
    TravelGraph.WorldPosition = function(p) return p.wx, p.wy, p.continent end
    local realDistance = TravelGraph.DistanceProvider
    TravelGraph.DistanceProvider = function(p, q) return math.sqrt((p.wx - q.wx) ^ 2 + (p.wy - q.wy) ^ 2) end
    local from, to = { wx = 0, wy = -10, continent = 7 }, { wx = 1010, wy = 1000, continent = 7 }
    local straightLine = math.sqrt(1010 ^ 2 + 1010 ^ 2)
    local priced = straightLine * addon.DEFAULT_PATH_FACTOR

    addon.Options:Set("roadPreference", 3)                  -- drawn round by the road
    local roadWay = RoadNet:Between(from, to)
    local steps = { { method = "walk", seconds = 100, path = { from, to } }, { method = "taxi", seconds = 50, path = { from, to } } }
    local added = addon.Journey:RetimeWalks(steps)
    check(near(steps[1].seconds, 100 * roadWay / priced, 1e-6) and near(added, steps[1].seconds - 100, 1e-6),
        ("a walk drawn by the road takes the road's yards: %.1f s"):format(steps[1].seconds))
    check(steps[2].seconds == 50, "a flight keeps its time")
    check(addon.Journey:RetimeWalks(steps) == 0, "a step is timed again only once")

    addon.Options:Set("roadPreference", 1)                  -- drawn straight across
    steps = { { method = "walk", seconds = 100, path = { from, to } } }
    check(near(addon.Journey:RetimeWalks(steps), 0, 1e-9) and near(steps[1].seconds, 100, 1e-9),
        "a walk drawn straight, as it was priced, keeps its time")
    addon.Options:Set("roadPreference", 3)
    TravelGraph.DistanceProvider = realDistance
end

-- Undercity's map shows the Ruins of Lordaeron above its streets: a walk in the ruins (the entrance to a lift top)
-- stays straight, while one underground (a lift bottom to a battlemaster) goes by the streets.
do
    check(addon.CityPathsSkip and addon.CityPathsSkip["easternkingdoms.tirisfal_glades.undercity_ruins"], "the ruins skip the streets")
    local shippedCities, stub = addon.CityPaths, TravelGraph.WorldPosition
    addon.CityPaths = { [1458] = { { 0.6, 0.05, 0.6, 0.95 } } }
    TravelGraph.WorldPosition = function(p)
        if p.mapID == 1458 then return p.x * 1000, p.y * 1000, 7 end
        return stub(p)
    end
    RoadNet:Reset()
    local World = addon.World
    check(RoadNet:Between(World:GetNode("ENTRANCE_UNDERCITY_INNER"), World:GetNode("UNDERCITY_ELEVATOR_TOP_1")) == nil,
        "the ruins' corridor stays straight")
    check(RoadNet:Between(World:GetNode("UNDERCITY_ELEVATOR_BOTTOM_1"), World:GetNode("BATTLEMASTER_347")),
        "underground goes by the streets")
    addon.CityPaths, TravelGraph.WorldPosition = shippedCities, stub
    RoadNet:Reset()
end

TravelGraph.WorldPosition = realWorld
addon.RoadData = shipped
addon.GeometryPacked = nil
RoadNet:Reset()
