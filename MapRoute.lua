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
            for _, point in ipairs(step.path or {}) do
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
