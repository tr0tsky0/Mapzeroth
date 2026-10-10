local addonName, addon = ...

-- The route of the trip being followed, drawn on the world map (the design's "route on the map" board): on foot dotted, a flight
-- dashed, a boat solid, a teleport dotted, a small square where each step starts, a bigger one at each stop of a
-- tour and the end marked. What to draw is MapRoute's; this file puts it on the map's canvas, in whatever map the
-- player has open, and redraws it when the map changes. Colours come from the theme's map colours
-- (Theme:MapColor): the map is parchment and sepia, so every line and marker sits on a dark casing, a slightly
-- wider line under it, which keeps it readable on any of the map's art.
--
-- It draws on a frame of its own that fills the canvas, so it pans and zooms with the map, and sizes are
-- worked out against the canvas' scale so lines and markers look the same at any zoom. Frames are built
-- on first use. Drawing never raises an error into the map: a failure just leaves the route undrawn.

local RouteLines = {}
addon.RouteLines = RouteLines

local Theme = addon.Theme
local MapRoute = addon.MapRoute

-- Screen pixels. `on`/`off` make dots or dashes. CASING is how much wider the dark line under each one is.
local LOOK = {
    foot = { width = 3, on = 2, off = 6 },
    flight = { width = 3, on = 9, off = 6 },
    boat = { width = 3.5 },
    ability = { width = 3, on = 2, off = 6 },
}
local CASING = 2.5
-- Marker sizes: a step's start is a round dot, a stop or the end a square; where a boat or flight runs off the
-- map (MapRoute's "edge") a ring in its colour; a teleport is a ring where it leaves (portOut) and a solid dot
-- where it lands (portIn), in the teleport colour, never a line.
local MARKER = { step = 7, edge = 14, portOut = 14, portIn = 11, stop = 11, dest = 15 }
local RING = { edge = true, portOut = true }   -- hollow: the map shows through the middle
-- White pictures, tinted (Media/): a disc, and for a ring its coloured band and the dark edge under it, wider
-- both ways so it shows either side of the band.
local MEDIA = "Interface\\AddOns\\" .. addonName .. "\\Media\\"
local DOT, RING_BAND, RING_EDGE = MEDIA .. "Dot", MEDIA .. "Ring", MEDIA .. "RingEdge"
local DONE_ALPHA = 0.35            -- steps already done fade
-- Everything above is for a zone map. A continent or the whole world puts far more ground in the same space, so
-- lines and markers shrink there to keep from smothering it, by the map's kind (Enum.UIMapType: 0 cosmic,
-- 1 world, 2 continent; zones and anything smaller stay at 1). Lines that thin are all casing, so the world
-- map's have none.
local SHRINK = { [0] = 0.5, [1] = 0.5, [2] = 0.7 }
local NO_CASING = { [0] = true, [1] = true }
local MIN_WIDTH, MIN_ON = 2, 2     -- screen pixels: shrunk below these, lines and dots don't show at all
RouteLines.DOT = DOT               -- for tests

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

local function place(line, frame, ax, ay, bx, by, thickness, r, g, b, alpha)
    line:SetThickness(thickness)
    line:SetColorTexture(r, g, b, alpha)
    line:SetStartPoint("TOPLEFT", frame, ax, -ay)
    line:SetEndPoint("TOPLEFT", frame, bx, -by)
end

-- One run of a line, on its casing (unless the map has none: state.noCasing). The casing reaches `pad` past each
-- end, so dots are edged all round.
local function segment(frame, ax, ay, bx, by, width, unit, r, g, b, alpha)
    if state.noCasing then
        place(acquire(frame, "lines", "linesUsed", "OVERLAY"), frame, ax, ay, bx, by, width * unit, r, g, b, alpha)
        return
    end
    local cr, cg, cb, ca = Theme:MapColor("casing")
    local dx, dy = bx - ax, by - ay
    local length = math.sqrt(dx * dx + dy * dy)
    local pad = CASING / 2 * unit
    local px, py = 0, 0
    if length > 0 then px, py = dx / length * pad, dy / length * pad end
    place(acquire(frame, "casings", "casingsUsed", "ARTWORK"), frame, ax - px, ay - py, bx + px, by + py,
        (width + CASING) * unit, cr, cg, cb, ca * alpha)
    place(acquire(frame, "lines", "linesUsed", "OVERLAY"), frame, ax, ay, bx, by, width * unit, r, g, b, alpha)
end

-- A marker: a dot or a square, on a dark edge.
local function acquireBadge(frame)
    state.badgesUsed = state.badgesUsed + 1
    local badge = state.badges[state.badgesUsed]
    if not badge then
        badge = CreateFrame("Frame", nil, frame)
        badge.ring = badge:CreateTexture(nil, "BACKGROUND")
        badge.ring:SetAllPoints()
        badge.fill = badge:CreateTexture(nil, "BORDER")
        state.badges[state.badgesUsed] = badge
    end
    badge:Show()
    return badge
end

local function drawPiece(frame, piece, unit, shrink, W, H)
    local base = LOOK[piece.style] or LOOK.foot
    local look = { width = math.max(base.width * shrink, MIN_WIDTH),
                   on = base.on and math.max(base.on * shrink, MIN_ON), off = base.off and base.off * shrink }
    local r, g, b = Theme:MapColor(LOOK[piece.style] and piece.style or "foot")
    local alpha = (state.current and piece.step < state.current) and DONE_ALPHA or 1
    local points = {}
    for i, p in ipairs(piece.points) do points[i] = { x = p.x * W, y = p.y * H } end
    if look.on then
        for _, s in ipairs(MapRoute.Pattern(points, look.on * unit, look.off * unit)) do
            segment(frame, s[1], s[2], s[3], s[4], look.width, unit, r, g, b, alpha)
        end
    else
        for i = 1, #points - 1 do
            segment(frame, points[i].x, points[i].y, points[i + 1].x, points[i + 1].y, look.width, unit, r, g, b, alpha)
        end
    end
end

local function drawMarker(frame, marker, unit, W, H)
    local size = MARKER[marker.kind] or MARKER.step
    local badge = acquireBadge(frame)
    badge:SetScale(unit)
    badge:SetSize(size, size)
    badge:ClearAllPoints()
    badge:SetPoint("CENTER", frame, "TOPLEFT", (marker.x * W) / unit, (-marker.y * H) / unit)
    badge.fill:ClearAllPoints()
    if RING[marker.kind] then
        badge.ring:SetTexture(RING_EDGE)
        badge.fill:SetTexture(RING_BAND)
        badge.fill:SetAllPoints()
    else
        local edge = size >= 10 and 2 or 1.5
        badge.fill:SetPoint("TOPLEFT", edge, -edge)
        badge.fill:SetPoint("BOTTOMRIGHT", -edge, edge)
        local round = marker.kind ~= "stop" and marker.kind ~= "dest"
        for _, texture in ipairs({ badge.ring, badge.fill }) do
            if round then texture:SetTexture(DOT) else texture:SetColorTexture(1, 1, 1, 1) end
        end
    end
    local r, g, b
    local done = false
    if marker.kind == "dest" then
        r, g, b = Theme:MapColor("dest")
    elseif marker.kind == "portOut" or marker.kind == "portIn" then
        r, g, b = Theme:MapColor("ability")
        done = state.current and marker.step < state.current
    elseif marker.kind == "edge" then
        r, g, b = Theme:MapColor(LOOK[marker.style] and marker.style or "foot")
        done = state.current and marker.step < state.current
    elseif marker.kind == "stop" then
        r, g, b = Theme:MapColor("stop")
        done = state.current and marker.step < state.current
    else
        r, g, b = Theme:MapColor(LOOK[marker.style] and marker.style or "foot")
        done = state.current and marker.index < state.current
    end
    local alpha = done and DONE_ALPHA or 1
    local cr, cg, cb, ca = Theme:MapColor("casing")
    badge.ring:SetVertexColor(cr, cg, cb, math.max(ca, 0.9) * alpha)
    badge.fill:SetVertexColor(r, g, b, alpha)
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
    local plan = state.plan
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
-- (A route being looked at, not started, is not drawn: the navigator hands this over as the trip updates.)
function RouteLines:Follow(plan, current)
    if plan ~= state.plan then
        state.plan, state.current = plan, current
        self:Redraw()
    elseif state.current ~= current then
        state.current = current
        self:Redraw()
    end
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
