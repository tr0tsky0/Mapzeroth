-- A route as lines on the map: which look each kind of travel has, how a plan is cut into pieces on the map
-- that is open, and the dashes and dots along a path. (Drawing them is UI/RouteLines, tested with the UI.)
useTestDistances()
addon.World:Build()

local MapRoute = addon.MapRoute

-- Looks.
check(MapRoute:StyleOf("walk") == "foot" and MapRoute:StyleOf("transition") == "foot", "walking is on foot")
check(MapRoute:StyleOf("taxi") == "flight", "a flight is a flight")
check(MapRoute:StyleOf("ship") == "boat" and MapRoute:StyleOf("zeppelin") == "boat" and MapRoute:StyleOf("tram") == "boat", "boats, zeppelins and trams look alike")
check(MapRoute:StyleOf("teleport") == "ability" and MapRoute:StyleOf("hearthstone") == "ability" and MapRoute:StyleOf("portal") == "ability", "teleports, the hearthstone and portals too")
check(MapRoute:StyleOf("nonsense") == "foot", "anything else is on foot")
check(MapRoute:StyleOf("equip") == "ability", "putting an item on is the player's own ability, like using it")

-- Dashes along a path.
local function line(...) local pts = {} for i = 1, select("#", ...), 2 do pts[#pts + 1] = { x = select(i, ...), y = select(i + 1, ...) } end return pts end
local dashes = MapRoute.Pattern(line(0, 0, 100, 0), 10, 10)
check(#dashes == 5, "a 100 long line in 10 on, 10 off makes five dashes: " .. #dashes)
check(dashes[1][1] == 0 and dashes[1][3] == 10 and dashes[2][1] == 20 and dashes[5][1] == 80 and dashes[5][3] == 90,
    "at 0-10, 20-30 and so on: the last is " .. dashes[5][1] .. " to " .. dashes[5][3])
local dots = MapRoute.Pattern(line(0, 0, 0, 90), 2, 7)
check(#dots == 10 and dots[1][4] == 2 and dots[2][2] == 9, "dots are short dashes, spaced: " .. #dots)
-- Round a corner the dash carries on: 15 along, then 15 up, dashes of 10 with gaps of 10.
local corner = MapRoute.Pattern(line(0, 0, 15, 0, 15, 15), 10, 10)
local total = 0
for _, d in ipairs(corner) do total = total + math.sqrt((d[3] - d[1]) ^ 2 + (d[4] - d[2]) ^ 2) end
check(math.abs(total - 20) < 1e-6, "the pattern keeps its rhythm round a corner (30 long: 10 on, 10 off, 10 on): " .. total .. " drawn")
check(#corner == 2 and math.abs(corner[2][2] - 5) < 1e-6 and corner[2][4] == 15, "the second dash starts 5 up the second side, after the rest of the gap")
check(#MapRoute.Pattern(line(5, 5), 10, 10) == 0 and #MapRoute.Pattern(line(0, 0, 10, 0), 0, 10) == 0, "nothing to draw for a point or a zero dash")

-- Clipping to a round minimap.
local function near(a, b) return a ~= nil and b ~= nil and math.abs(a - b) < 1e-9 end
local x1, y1, x2, y2 = MapRoute.ClipCircle(-3, 0, 3, 0, 10)
check(x1 == -3 and x2 == 3, "a segment inside the circle is left alone")
x1, y1, x2, y2 = MapRoute.ClipCircle(0, 0, 30, 0, 10)
check(near(x1, 0) and near(x2, 10) and near(y2, 0), "one that runs out is cut at the rim: " .. tostring(x2))
x1, y1, x2, y2 = MapRoute.ClipCircle(-30, 0, 30, 0, 10)
check(near(x1, -10) and near(x2, 10), "one that crosses the whole circle is cut at both ends")
check(MapRoute.ClipCircle(20, 0, 30, 0, 10) == nil and MapRoute.ClipCircle(-30, 12, 30, 12, 10) == nil, "one outside, or passing wide of it, is dropped")
check(MapRoute.ClipCircle(5, 5, 5, 5, 10) == 5 and MapRoute.ClipCircle(50, 50, 50, 50, 10) == nil, "a point is in or out")
local re, rn = MapRoute.Rotate(0, 1, math.pi / 2)
check(near(re, -1) and near(rn, 0), "north turned a quarter turn counter-clockwise is west")
re, rn = MapRoute.Rotate(1, 0, -math.pi / 2)
check(near(re, 0) and near(rn, -1), "east turned a quarter turn clockwise is south")

-- Pieces of a plan on the map that is open. Points on other maps can't be placed there.
local realMapPoint = addon.Navigation.MapPoint
addon.Navigation.MapPoint = function(node, mapID)
    if node.mapID == mapID then return node.x, node.y end
    return nil
end
local plan = { steps = {
    { method = "walk", path = { { mapID = 1, x = 0.1, y = 0.1 }, { mapID = 1, x = 0.2, y = 0.2 }, { mapID = 1, x = 0.3, y = 0.3 } } },
    { method = "taxi", path = { { mapID = 1, x = 0.3, y = 0.3 }, { mapID = 2, x = 0.5, y = 0.5 } } },
    { method = "ship", path = { { mapID = 2, x = 0.5, y = 0.5 }, { mapID = 1, x = 0.7, y = 0.7 } } },
    { method = "walk", path = { { mapID = 1, x = 0.7, y = 0.7 }, { mapID = 1, x = 0.9, y = 0.9 } } },
} }
local pieces, markers = MapRoute:Pieces(plan, 1)
check(#pieces == 2 and pieces[1].style == "foot" and pieces[1].step == 1 and #pieces[1].points == 3 and pieces[2].style == "foot" and pieces[2].step == 4,
    "on map 1 the two walks are drawn; the flight and the boat go off the map and aren't: " .. #pieces .. " pieces")
check(#markers == 5 and markers[1].kind == "step" and markers[1].index == 1 and markers[#markers].kind == "dest", "a badge for each step that shows, and the end")
check(markers[#markers].x == 0.9 and markers[#markers].y == 0.9, "the end is where the last piece ends")
local _, onTwo = MapRoute:Pieces(plan, 2)
check(#onTwo >= 1 and onTwo[#onTwo].kind == "dest" and onTwo[#onTwo].x == 0.5, "on map 2 the route ends at the last point it can show there")
local none, noMarkers = MapRoute:Pieces(plan, 3)
check(#none == 0 and #noMarkers == 0, "on a map none of it is on, nothing is drawn")
check(#MapRoute:Pieces({ steps = {} }, 1) == 0 and #MapRoute:Pieces(nil, 1) == 0, "no plan, no lines")
addon.Navigation.MapPoint = realMapPoint

-- A real plan carries the points of its steps: a merged walk through its stops, the start, the end.
addon.GetNodeName = function(_, id) return "Place " .. id end
addon.GetZoneName = function(_, mapID) return "Zone " .. tostring(mapID) end
local ctx = makeCtx({ faction = "Alliance" })
local a, b = addon.World:GetNode("TAXI_2"), addon.World:GetNode("TAXI_6")
local start = { id = "YOU_path", mapID = a.mapID, x = a.x + 0.05, y = a.y + 0.05 }
local session = addon.Journey:Build(ctx, start)
local route = addon.Journey:Plan(session, "TAXI_6")
check(route and #route.steps >= 1, "there is a route to plan")
for i, step in ipairs(route.steps) do
    check(step.path and #step.path >= 2, "step " .. i .. " has the points it goes through: " .. tostring(step.path and #step.path))
    for _, point in ipairs(step.path) do check(point.mapID and point.x and point.y, "each point is a place on a map") end
end
local first = route.steps[1].path[1]
check(first.mapID == start.mapID and first.x == start.x and first.y == start.y, "the first point is where the player stands")
local lastStep = route.steps[#route.steps]
local finish = lastStep.path[#lastStep.path]
check(finish.mapID == b.mapID and finish.x == b.x and finish.y == b.y, "and the last is where the route ends")
