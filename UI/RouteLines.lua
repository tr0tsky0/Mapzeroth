local addonName, addon = ...

-- The route of the trip being followed, drawn on the world map (the design's "route on the map" board): on foot dotted, a flight
-- dashed, a boat solid, a teleport a ring and arrow where it leaves and where it lands, a small dot where each step
-- starts, a square at each stop of a tour and the end marked. What to draw is MapRoute's; this file puts it on the map's canvas, in whatever map the
-- player has open, and redraws it when the map changes. Colours come from the theme's map colours
-- (Theme:MapColor): the map is parchment and sepia, so every line and marker sits on a dark casing, a slightly
-- wider line under it, which keeps it readable on any of the map's art.
--
-- Each straight run of a line is one textured Line (and one more for its casing), the dots or dashes tiled along it
-- by its texture coordinates from one soft-edged picture (Media/Line*, made by tools/gen_media.py), so a long route
-- costs a few lines rather than one per dot, and its edges are smooth.
--
-- It draws on a frame of its own that fills the canvas, so it pans and zooms with the map, and sizes are
-- worked out against the canvas' scale so lines and markers look the same at any zoom. Frames are built
-- on first use. Drawing never raises an error into the map: a failure just leaves the route undrawn.

local RouteLines = {}
addon.RouteLines = RouteLines

local Theme = addon.Theme
local MapRoute = addon.MapRoute

local MEDIA = "Interface\\AddOns\\" .. addonName .. "\\Media\\"
-- Each style's tile: its picture, and the screen pixels one repeat covers along the line (`period`) and across it
-- (`thickness`, the casing's full width; the line itself is drawn inside that). These match tools/gen_media.py.
local LOOK = {
    foot = { tile = "LineDot", period = 12, thickness = 8 },
    flight = { tile = "LineDash", period = 18, thickness = 8 },
    boat = { tile = "LineSolid", period = 8, thickness = 8, solid = true },
    ability = { tile = "LineDot", period = 12, thickness = 8 },
}
RouteLines.LOOK = LOOK              -- for tests
-- Marker sizes: a step's start is a round dot, a tour stop a rounded square, the end a target; where a boat or
-- flight runs off the map (MapRoute's "edge") a ring in its colour; a teleport is a ring with an arrow out of it
-- where it leaves (portOut) and one with an arrow into it where it lands (portIn), in the teleport colour, never a
-- line. Each is a white picture (Media/, from tools/gen_media.py, drawn for these sizes) tinted, over its own dark
-- edge picture tinted with the casing colour.
local MARKER = { step = 7, edge = 14, portOut = 20, portIn = 20, stop = 11, dest = 15, bucket = 18 }
local PICTURE = {
    step = { MEDIA .. "Step", MEDIA .. "StepEdge" },
    stop = { MEDIA .. "Stop", MEDIA .. "StopEdge" },
    dest = { MEDIA .. "Dest", MEDIA .. "DestEdge" },
    edge = { MEDIA .. "Ring", MEDIA .. "RingEdge" },
    portOut = { MEDIA .. "PortOut", MEDIA .. "PortOutEdge" },
    portIn = { MEDIA .. "PortIn", MEDIA .. "PortInEdge" },
    bucket = { MEDIA .. "Bucket", MEDIA .. "BucketEdge" },
}
RouteLines.PICTURE = PICTURE       -- for tests
-- A holiday route's stops (and its last one) drawn as that holiday's picture instead (plan.holiday, an addon.HOLIDAYS key).
local HOLIDAY_STOP = { hallows_end = "bucket" }
RouteLines.HOLIDAY_STOP = HOLIDAY_STOP
local DONE_ALPHA = 0.35            -- steps already done fade
-- Everything above is for a zone map. A continent or the whole world puts far more ground in the same space, so
-- lines and markers shrink there to keep from smothering it, by the map's kind (Enum.UIMapType: 0 cosmic,
-- 1 world, 2 continent; zones and anything smaller stay at 1). Lines that thin are all casing, so the world
-- map's have none.
local SHRINK = { [0] = 0.5, [1] = 0.5, [2] = 0.7 }
local NO_CASING = { [0] = true, [1] = true }
local MIN_THICKNESS = 4            -- screen pixels: shrunk below this, a dot is a smudge

local state = { plan = nil, current = nil, lines = {}, linesUsed = 0, casings = {}, casingsUsed = 0, badges = {}, badgesUsed = 0 }
RouteLines.state = state            -- for tests

local function canvas()
    if WorldMapFrame and WorldMapFrame.GetCanvas then return WorldMapFrame:GetCanvas() end
end

local function ensureFrame()
    if state.frame then return state.frame end
    local parent = canvas()
    if not parent then return nil end
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints(parent)
    frame:SetFrameLevel((parent:GetFrameLevel() or 1) + 40)
    state.frame = frame
    return frame
end

-- The map draws its own art (the zone's detail layers, the explored-area overlays) in frames of its own, and a
-- frame under those is hidden by them. So ours goes just above the highest of them: the map's pins (points of
-- interest, the player's arrow) are meant to be above the art, so they stay above the route, or at least
-- level with it. Read from the map each time, since layers come and go with the map on show.
local function levelAbove(map, canvas)
    local level = canvas:GetFrameLevel() or 1
    local function scan(pool, wanted)
        if type(pool) ~= "table" or type(pool.EnumerateActive) ~= "function" then return end
        for frame in pool:EnumerateActive() do
            if not wanted or wanted(frame) then level = math.max(level, frame:GetFrameLevel() or 0) end
        end
    end
    scan(map.detailLayerPool)
    for template, pool in pairs(type(map.pinPools) == "table" and map.pinPools or {}) do
        if type(template) == "string" and template:find("Exploration") then scan(pool) end
    end
    return math.min(level + 1, 9990)
end

-- How many of our units make one screen pixel on the canvas.
local function unitOf(frame)
    local mine, ui = frame:GetEffectiveScale(), UIParent and UIParent:GetEffectiveScale()
    if mine and ui and mine > 0 then return ui / mine end
    return 1
end

-- Lines come from two pools: the casings (under) and the coloured lines (over), so no casing covers a line.
local function acquire(frame, pool, used, layer)
    state[used] = state[used] + 1
    local line = state[pool][state[used]]
    if not line then
        line = frame:CreateLine(nil, layer)
        state[pool][state[used]] = line
    end
    line:Show()
    return line
end

-- One straight run of a line in `look`, its edge (casing) picture if `edge`, from (x1, y1) to (x2, y2) off `anchor`
-- of `frame`. `from` and `to` are how far along the whole line it starts and ends, so the pattern carries on across
-- a bend; they and `thickness` (the tile's) are in the frame's units. The minimap draws with this too.
function RouteLines.PlaceRun(line, look, edge, frame, anchor, x1, y1, x2, y2, from, to, thickness, r, g, b, alpha)
    line:SetTexture(MEDIA .. look.tile .. (edge and "Edge" or ""), "REPEAT", "CLAMP", "TRILINEAR")
    local period = thickness * look.period / look.thickness
    line:SetTexCoord(from / period, to / period, 0, 1)
    line:SetThickness(thickness)
    line:SetVertexColor(r, g, b, alpha)
    line:SetStartPoint(anchor, frame, x1, y1)
    line:SetEndPoint(anchor, frame, x2, y2)
end
local function place(line, frame, look, edge, ax, ay, bx, by, from, to, thickness, r, g, b, alpha)
    RouteLines.PlaceRun(line, look, edge, frame, "TOPLEFT", ax, -ay, bx, -by, from, to, thickness, r, g, b, alpha)
end

-- One run, on its casing (unless the map has none: state.noCasing).
local function run(frame, look, ax, ay, bx, by, from, to, thickness, r, g, b, alpha)
    if not state.noCasing then
        local cr, cg, cb, ca = Theme:MapColor("casing", state.holiday)
        place(acquire(frame, "casings", "casingsUsed", "ARTWORK"), frame, look, true, ax, ay, bx, by, from, to,
            thickness, cr, cg, cb, ca * alpha)
    end
    place(acquire(frame, "lines", "linesUsed", "OVERLAY"), frame, look, false, ax, ay, bx, by, from, to,
        thickness, r, g, b, alpha)
end

-- A marker: its picture on a dark edge. The minimap makes its markers with this too.
function RouteLines.NewBadge(parent)
    local badge = CreateFrame("Frame", nil, parent)
    badge.ring = badge:CreateTexture(nil, "BACKGROUND")
    badge.ring:SetAllPoints()
    badge.fill = badge:CreateTexture(nil, "BORDER")
    return badge
end

local function acquireBadge(frame)
    state.badgesUsed = state.badgesUsed + 1
    local badge = state.badges[state.badgesUsed]
    if not badge then
        badge = RouteLines.NewBadge(frame)
        state.badges[state.badgesUsed] = badge
    end
    badge:Show()
    return badge
end

local function drawPiece(frame, piece, unit, shrink, W, H)
    local look = LOOK[piece.style] or LOOK.foot
    local thickness = math.max(look.thickness * shrink, MIN_THICKNESS) * unit
    local r, g, b = Theme:MapColor(LOOK[piece.style] and piece.style or "foot", state.holiday)
    local alpha = (state.current and piece.step < state.current) and DONE_ALPHA or 1
    -- A solid line's runs reach half its width past each end, so a bend has no notch on its outside.
    local reach = look.solid and thickness / 2 or 0
    local along = 0
    for i = 1, #piece.points - 1 do
        local p, q = piece.points[i], piece.points[i + 1]
        local ax, ay, bx, by = p.x * W, p.y * H, q.x * W, q.y * H
        local dx, dy = bx - ax, by - ay
        local length = math.sqrt(dx * dx + dy * dy)
        if length > 0 then
            local ux, uy = dx / length * reach, dy / length * reach
            run(frame, look, ax - ux, ay - uy, bx + ux, by + uy, along - reach, along + length + reach,
                thickness, r, g, b, alpha)
            along = along + length
        end
    end
end

-- Dress a badge as `marker` (MapRoute's): its size (unscaled), picture and colours, faded if its step is before
-- `current`; `holiday` for a holiday route's look. Where it goes is the caller's.
function RouteLines.StyleBadge(badge, marker, current, holiday)
    local shape = marker.kind
    if (shape == "stop" or shape == "dest") and holiday and HOLIDAY_STOP[holiday] then shape = HOLIDAY_STOP[holiday] end
    local size = MARKER[shape] or MARKER.step
    badge:SetSize(size, size)
    local picture = PICTURE[shape] or PICTURE.step
    badge.fill:SetTexture(picture[1], "CLAMP", "CLAMP", "TRILINEAR")
    badge.ring:SetTexture(picture[2], "CLAMP", "CLAMP", "TRILINEAR")
    badge.fill:ClearAllPoints()
    badge.fill:SetAllPoints()
    local r, g, b
    local done = false
    if marker.kind == "dest" then
        r, g, b = Theme:MapColor("dest", holiday)
    elseif marker.kind == "portOut" or marker.kind == "portIn" then
        r, g, b = Theme:MapColor("ability")
        done = current and marker.step < current
    elseif marker.kind == "edge" then
        r, g, b = Theme:MapColor(LOOK[marker.style] and marker.style or "foot", holiday)
        done = current and marker.step < current
    elseif marker.kind == "stop" then
        r, g, b = Theme:MapColor("stop", holiday)
        done = current and marker.step < current
    else
        r, g, b = Theme:MapColor(LOOK[marker.style] and marker.style or "foot", holiday)
        done = current and marker.index < current
    end
    local alpha = done and DONE_ALPHA or 1
    local cr, cg, cb, ca = Theme:MapColor("casing", holiday)
    badge.ring:SetVertexColor(cr, cg, cb, math.max(ca, 0.9) * alpha)
    badge.fill:SetVertexColor(r, g, b, alpha)
end

local function drawMarker(frame, marker, unit, W, H)
    local badge = acquireBadge(frame)
    badge:SetScale(unit)
    badge:ClearAllPoints()
    badge:SetPoint("CENTER", frame, "TOPLEFT", (marker.x * W) / unit, (-marker.y * H) / unit)
    RouteLines.StyleBadge(badge, marker, state.current, state.holiday)
end

-- How much smaller than on a zone map to draw on map `mapID` (see SHRINK), and whether its lines go without casing.
local function shrinkFor(mapID)
    local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
    return info and SHRINK[info.mapType] or 1, info and NO_CASING[info.mapType] or false
end
RouteLines.ShrinkFor = shrinkFor    -- for tests

local function draw(frame, plan, mapID)
    local W, H = frame:GetWidth(), frame:GetHeight()
    if not (W and H and W > 0 and H > 0) then return end
    local shrink, noCasing = shrinkFor(mapID)
    local unit = unitOf(frame)
    state.noCasing = noCasing
    state.holiday = plan.holiday           -- a holiday route's look (Theme:MapColor, HOLIDAY_STOP)
    local pieces, markers = MapRoute:Pieces(plan, mapID)
    for _, piece in ipairs(pieces) do drawPiece(frame, piece, unit, shrink, W, H) end
    for _, marker in ipairs(markers) do drawMarker(frame, marker, unit * shrink, W, H) end
end

-- Take down everything drawn (the pieces stay pooled for next time).
function RouteLines:Hide()
    for i = 1, state.linesUsed do state.lines[i]:Hide() end
    for i = 1, state.casingsUsed do state.casings[i]:Hide() end
    for i = 1, state.badgesUsed do state.badges[i]:Hide() end
    state.linesUsed, state.casingsUsed, state.badgesUsed = 0, 0, 0
end

-- Draw the plan again on the map that is open.
function RouteLines:Redraw()
    self:Hide()
    local plan = state.plan or state.preview      -- the trip being followed comes first
    if not plan or not addon.Options:Get("showRouteOnMap") then return end
    local map = WorldMapFrame
    if not (map and map.GetMapID and map:IsShown()) then return end
    local frame = ensureFrame()
    if not frame then return end
    local ok, err = pcall(function()
        frame:SetFrameLevel(levelAbove(map, frame:GetParent() or canvas()))
        draw(frame, plan, map:GetMapID())
    end)
    if not ok then
        state.error = err              -- kept for the tools; the map carries on
        self:Hide()
    end
end

-- Follow the trip that has been started: draw its plan, and fade the steps before `current`. nil stops.
-- (The navigator hands this over as the trip updates. A route only planned on the panel is Preview's.)
function RouteLines:Follow(plan, current)
    if plan ~= state.plan then
        state.plan, state.current = plan, current
        self:Redraw()
    elseif state.current ~= current then
        state.current = current
        self:Redraw()
    end
end

-- A route planned on the panel but not started: drawn while it is on show there, unless a trip is being followed
-- (that one is drawn instead). nil takes it down.
function RouteLines:Preview(plan)
    if plan == state.preview then return end
    state.preview = plan
    if not state.plan then self:Redraw() end
end

-- Which step the trip is on: earlier ones fade.
function RouteLines:SetCurrent(index)
    if state.current == index then return end
    state.current = index
    self:Redraw()
end

-- Redraw when the map changes what it shows (another map, a zoom). (Opening the map is the panel's: it
-- shows the route again, or clears it.)
function RouteLines:Init()
    if state.hooked or not WorldMapFrame then return end
    state.hooked = true
    addon.Options:OnChange(function(key) if key == "showRouteOnMap" then RouteLines:Redraw() end end)
    for _, method in ipairs({ "OnMapChanged", "OnCanvasScaleChanged" }) do
        if WorldMapFrame[method] then
            hooksecurefunc(WorldMapFrame, method, function() RouteLines:Redraw() end)
        end
    end
end
