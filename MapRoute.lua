local addonName, addon = ...

-- A route as lines on the world map: the geometry, with no frames (UI/RouteLines.lua draws it).
--
-- A plan's steps each carry `path`, the points the step goes through as { mapID, x, y } on their own
-- maps (Journey adds it). The map on show is whichever one the player has open, a zone or a continent,
-- so each point is carried onto it through world coordinates (Navigation.MapPoint); a point that can't be
-- placed there (an interior, another world) breaks the line, and the pieces before and after are drawn
-- on their own.
--
-- Each kind of travel has its own look (the design's "route on the map" board): on foot is dotted, a
-- flight dashed, a boat, zeppelin or tram solid; a teleport, hearthstone or portal is no line, just a marker
-- where it leaves and one where it lands. How each is drawn (the dots and dashes) is RouteLines'.

local MapRoute = {}
addon.MapRoute = MapRoute

function MapRoute:StyleOf(method)
    return addon:Method(method).style
end

-- Where a point of a route is on the map being shown, as x, y (0 to 1), or nil.
function MapRoute:Project(point, mapID)
    return addon.Navigation.MapPoint(point, mapID)
end

-- The points a step's line goes through: a walk's own path with the road's way put in between (RoadNet), worked out
-- once per step and kept on it (the minimap redraws its lines as the player moves), until the player changes how
-- much walks keep to roads; anything else, its path.
function MapRoute:DrawnPath(step)
    local path = step.path or {}
    if step.method ~= "walk" or not addon.RoadNet then return path end
    local k = addon.RoadNet:Offroad()
    if step.drawnPath and step.drawnFrom == path and step.drawnCount == #path and step.drawnK == k then return step.drawnPath end
    local drawn = addon.RoadNet:Expand(path)
    step.drawnPath, step.drawnFrom, step.drawnCount, step.drawnK = drawn, path, #path, k
    return drawn
end

-- What to draw on map `mapID` for a plan: pieces = { { style, step, points = { {x, y}, ... } }, ... } in the
-- order of the route, and markers, drawn in this order (later on top):
--   { kind = "step", index, style, x, y }  where each step after the first starts (a small dot, unnumbered:
--                                          numbers on every step were clutter)
--   { kind = "edge", step, style, x, y }   where a step leaves or comes onto this map with nothing to join it to
--                                          here (a boat to another continent): its other end can't be placed on
--                                          this map, so it would draw nothing
--   { kind = "portOut" | "portIn", step, x, y }  where a teleport, hearth or portal (the "ability" style) leaves
--                                          from and lands. These are never lines: a jump drawn across the map
--                                          says nothing the two ends don't, and a tour's criss-cross them
--                                          everywhere. (A teleport cast from wherever the player stands has no
--                                          start point, only its landing.)
--   { kind = "stop", leg, step, x, y }     each stop of a tour (every leg's end but the last)
--   { kind = "dest", x, y }                where the route ends
-- A marker only shows where its place is on this map: a route that runs off the map has no end marker where
-- it leaves, and a step that starts on another map has no dot. Nor does a step that a teleport starts or
-- ends: its port marker is there.
function MapRoute:Pieces(plan, mapID)
    local pieces, markers = {}, {}
    local steps = plan and plan.steps or {}
    local edges, ports = {}, {}
    local function place(point)
        if point then return self:Project(point, mapID) end
    end
    for index, step in ipairs(steps) do
        local style = self:StyleOf(step.method)
        if style == "ability" then
            local path = step.path or {}
            local x, y = place(#path >= 2 and path[1] or nil)
            if x then ports[#ports + 1] = { kind = "portOut", step = index, x = x, y = y } end
            x, y = place(path[#path])
            if x then ports[#ports + 1] = { kind = "portIn", step = index, x = x, y = y } end
        else
            local run, offMap = {}, false
            local lone = {}
            local function flush()
                if #run >= 2 then pieces[#pieces + 1] = { style = style, step = index, points = run }
                elseif #run == 1 then lone[#lone + 1] = run[1] end
                run = {}
            end
            for _, point in ipairs(self:DrawnPath(step)) do
                local x, y = self:Project(point, mapID)
                if x then run[#run + 1] = { x = x, y = y } else offMap = true flush() end
            end
            flush()
            if offMap then
                for _, p in ipairs(lone) do edges[#edges + 1] = { kind = "edge", step = index, style = style, x = p.x, y = p.y } end
            end
        end
    end
    local function ability(i) return steps[i] and self:StyleOf(steps[i].method) == "ability" end
    for index = 2, #steps do
        local first = steps[index].path and steps[index].path[1]
        local x, y
        if first and not ability(index) and not ability(index - 1) then x, y = self:Project(first, mapID) end
        if x then markers[#markers + 1] = { kind = "step", index = index, style = self:StyleOf(steps[index].method), x = x, y = y } end
    end
    for _, edge in ipairs(edges) do markers[#markers + 1] = edge end
    for _, port in ipairs(ports) do markers[#markers + 1] = port end
    local function lastPoint(step)
        local path = step and step.path
        local point = path and path[#path]
        if point then return self:Project(point, mapID) end
    end
    local legs = plan and plan.legs
    if type(legs) == "table" and #legs > 1 then
        local through = 0
        for leg = 1, #legs - 1 do
            through = through + #(legs[leg].steps or {})
            local x, y = lastPoint(steps[through])
            if x then markers[#markers + 1] = { kind = "stop", leg = leg, step = through, x = x, y = y } end
        end
    end
    local x, y = lastPoint(steps[#steps])
    if x then markers[#markers + 1] = { kind = "dest", x = x, y = y } end
    return pieces, markers
end

-- The part of the segment (x1, y1)-(x2, y2) inside a circle of `radius` about the origin, as x1, y1, x2, y2,
-- or nil if none of it is (the minimap shows a round window on the world).
function MapRoute.ClipCircle(x1, y1, x2, y2, radius)
    local r2 = radius * radius
    if x1 * x1 + y1 * y1 <= r2 and x2 * x2 + y2 * y2 <= r2 then return x1, y1, x2, y2 end
    local dx, dy = x2 - x1, y2 - y1
    local a = dx * dx + dy * dy
    if a == 0 then return nil end
    local b = 2 * (x1 * dx + y1 * dy)
    local c = x1 * x1 + y1 * y1 - r2
    local disc = b * b - 4 * a * c
    if disc <= 0 then return nil end
    local root = math.sqrt(disc)
    local low, high = math.max(0, (-b - root) / (2 * a)), math.min(1, (-b + root) / (2 * a))
    if low >= high then return nil end
    return x1 + dx * low, y1 + dy * low, x1 + dx * high, y1 + dy * high
end

-- The part of a segment inside the square of half-width `half` about the origin, or nil.
local function clipSquare(x1, y1, x2, y2, half)
    local dx, dy = x2 - x1, y2 - y1
    local low, high = 0, 1
    for _, edge in ipairs({ { -dx, x1 + half }, { dx, half - x1 }, { -dy, y1 + half }, { dy, half - y1 } }) do
        local p, q = edge[1], edge[2]
        if p == 0 then
            if q < 0 then return nil end
        else
            local t = q / p
            if p < 0 then low = math.max(low, t) else high = math.min(high, t) end
        end
    end
    if low >= high then return nil end
    return x1 + dx * low, y1 + dy * low, x1 + dx * high, y1 + dy * high
end

-- Minimap shapes, by what GetMinimapShape() says (the global minimap addons define; none means round): for each
-- quarter whether it is round (true) or square, in LibDBIcon's order: 1 east-south, 2 west-south, 3 east-north,
-- 4 west-north.
MapRoute.MINIMAP_SHAPES = {
    ROUND = { true, true, true, true },
    SQUARE = { false, false, false, false },
    ["CORNER-TOPLEFT"] = { false, false, false, true },
    ["CORNER-TOPRIGHT"] = { false, false, true, false },
    ["CORNER-BOTTOMLEFT"] = { false, true, false, false },
    ["CORNER-BOTTOMRIGHT"] = { true, false, false, false },
    ["SIDE-LEFT"] = { false, true, false, true },
    ["SIDE-RIGHT"] = { true, false, true, false },
    ["SIDE-TOP"] = { false, false, true, true },
    ["SIDE-BOTTOM"] = { true, true, false, false },
    ["TRICORNER-TOPLEFT"] = { false, true, true, true },
    ["TRICORNER-TOPRIGHT"] = { true, false, true, true },
    ["TRICORNER-BOTTOMLEFT"] = { true, true, false, true },
    ["TRICORNER-BOTTOMRIGHT"] = { true, true, true, false },
}

local function quarter(x, y)
    local q = 1
    if x < 0 then q = q + 1 end
    if y > 0 then q = q + 2 end
    return q
end

-- Whether a point (east, north of the centre) is inside a minimap of `radius` and shape `quarters`
-- (MINIMAP_SHAPES' lists).
function MapRoute.InsideShape(x, y, radius, quarters)
    if quarters[quarter(x, y)] then return x * x + y * y <= radius * radius end
    return math.abs(x) <= radius and math.abs(y) <= radius
end

-- The parts of a segment inside a minimap of `radius` and shape `quarters`: { { x1, y1, x2, y2 }, ... } (the
-- segment is cut where it crosses from one quarter to another, and each part clipped to its quarter's shape).
function MapRoute.ClipShape(x1, y1, x2, y2, radius, quarters)
    local dx, dy = x2 - x1, y2 - y1
    local cuts = { 0, 1 }
    if dx ~= 0 and (x1 < 0) ~= (x2 < 0) then cuts[#cuts + 1] = -x1 / dx end
    if dy ~= 0 and (y1 > 0) ~= (y2 > 0) then cuts[#cuts + 1] = -y1 / dy end
    table.sort(cuts)
    local out = {}
    for i = 1, #cuts - 1 do
        local a, b = cuts[i], cuts[i + 1]
        if b > a then
            local ax, ay, bx, by = x1 + dx * a, y1 + dy * a, x1 + dx * b, y1 + dy * b
            local round = quarters[quarter((ax + bx) / 2, (ay + by) / 2)]
            local cx1, cy1, cx2, cy2
            if round then cx1, cy1, cx2, cy2 = MapRoute.ClipCircle(ax, ay, bx, by, radius)
            else cx1, cy1, cx2, cy2 = clipSquare(ax, ay, bx, by, radius) end
            if cx1 then out[#out + 1] = { cx1, cy1, cx2, cy2 } end
        end
    end
    return out
end

-- A vector (east, north) turned counter-clockwise by `angle` radians.
function MapRoute.Rotate(east, north, angle)
    local cos, sin = math.cos(angle), math.sin(angle)
    return east * cos - north * sin, east * sin + north * cos
end

-- How far the player has come along the step being followed, so the part behind them can go. `points` is a piece's
-- line in yards ({ x, y, along }); the player at (px, py), yards. Looks from segment `from` (where they were last
-- time) up to WALKED_AHEAD yards on, so a road that doubles back past them can't pull the spot ahead. Returns the
-- segment and the fraction along it nearest the player, or nil when they are more than WALKED_NEAR yards off the line
-- (not on it yet, or gone another way): then nothing is taken off.
local WALKED_AHEAD = 150
local WALKED_NEAR = 60
function MapRoute.Walked(points, px, py, from)
    if #points < 2 then return nil end
    from = math.max(1, math.min(from or 1, #points - 1))
    local limit = points[from].along + WALKED_AHEAD
    local best, segment, fraction
    for i = from, #points - 1 do
        local a, b = points[i], points[i + 1]
        if i > from and a.along > limit then break end
        local dx, dy = b.x - a.x, b.y - a.y
        local length2 = dx * dx + dy * dy
        local t = length2 > 0 and ((px - a.x) * dx + (py - a.y) * dy) / length2 or 0
        t = math.max(0, math.min(1, t))
        local ex, ey = a.x + t * dx - px, a.y + t * dy - py
        local d = ex * ex + ey * ey
        if not best or d < best then best, segment, fraction = d, i, t end
    end
    if best > WALKED_NEAR * WALKED_NEAR then return nil end
    return segment, fraction
end
