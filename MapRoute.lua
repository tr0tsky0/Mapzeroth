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
-- flight dashed, a boat, zeppelin or tram solid, a teleport, hearthstone or portal dotted in the
-- accent colour. Dashes and dots are runs of short segments along the path, which Pattern cuts.

local MapRoute = {}
addon.MapRoute = MapRoute

function MapRoute:StyleOf(method)
    return addon:Method(method).style
end

-- Where a point of a route is on the map being shown, as x, y (0 to 1), or nil.
function MapRoute:Project(point, mapID)
    return addon.Navigation.MapPoint(point, mapID)
end

-- What to draw on map `mapID` for a plan: pieces = { { style, step, points = { {x, y}, ... } }, ... } in the
-- order of the route, and markers = { { kind = "step", index, style, x, y }, ..., { kind = "dest", x, y } }:
-- where each step starts, and where the route ends.
function MapRoute:Pieces(plan, mapID)
    local pieces, markers = {}, {}
    local lastX, lastY
    for index, step in ipairs(plan and plan.steps or {}) do
        local style = self:StyleOf(step.method)
        local run = {}
        local function flush()
            if #run >= 2 then pieces[#pieces + 1] = { style = style, step = index, points = run } end
            run = {}
        end
        local marked = false
        for _, point in ipairs(step.path or {}) do
            local x, y = self:Project(point, mapID)
            if x then
                run[#run + 1] = { x = x, y = y }
                lastX, lastY = x, y
                if not marked then
                    markers[#markers + 1] = { kind = "step", index = index, style = style, x = x, y = y }
                    marked = true
                end
            else
                flush()
            end
        end
        flush()
    end
    if lastX then markers[#markers + 1] = { kind = "dest", x = lastX, y = lastY } end
    return pieces, markers
end

-- The runs of a dashed line along `points` ({ {x, y}, ... }, in any units): `on` long, then a gap of `off`,
-- carrying on across corners. Returns { { x1, y1, x2, y2 }, ... }. A dot is a dash a few units long.
function MapRoute.Pattern(points, on, off)
    local out = {}
    if #points < 2 or on <= 0 then return out end
    local drawing, remaining = true, on
    local startX, startY = points[1].x, points[1].y
    for i = 1, #points - 1 do
        local x0, y0, x1, y1 = points[i].x, points[i].y, points[i + 1].x, points[i + 1].y
        local dx, dy = x1 - x0, y1 - y0
        local length = math.sqrt(dx * dx + dy * dy)
        local at = 0
        if drawing and i > 1 then startX, startY = x0, y0 end        -- a dash goes on round the corner
        while length - at > 1e-9 do
            local step = math.min(remaining, length - at)
            at, remaining = at + step, remaining - step
            local px, py = x0 + dx * at / length, y0 + dy * at / length
            if remaining <= 1e-9 then
                if drawing then
                    out[#out + 1] = { startX, startY, px, py }
                    drawing, remaining = false, off
                else
                    drawing, remaining, startX, startY = true, on, px, py
                end
            end
        end
        if drawing and (startX ~= x1 or startY ~= y1) then              -- the corner ends this piece of the dash
            out[#out + 1] = { startX, startY, x1, y1 }
            startX, startY = x1, y1
        end
    end
    return out
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

-- A vector (east, north) turned counter-clockwise by `angle` radians.
function MapRoute.Rotate(east, north, angle)
    local cos, sin = math.cos(angle), math.sin(angle)
    return east * cos - north * sin, east * sin + north * cos
end
