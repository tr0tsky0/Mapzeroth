local addonName, addon = ...

-- The route of the trip being followed, drawn on the world map (the design's "route on the map" board): on foot dotted, a flight
-- dashed, a boat solid, a teleport dotted in the accent colour, each step's start numbered, and the
-- end marked. What to draw is MapRoute's; this file puts it on the map's canvas, in whatever map the player
-- has open, and redraws it when the map changes. Colours come from the theme (its method colours).
--
-- It draws on a frame of its own that fills the canvas, so it pans and zooms with the map, and sizes are
-- worked out against the canvas' scale so lines and badges look the same at any zoom. Frames are built
-- on first use. Drawing never raises an error into the map: a failure just leaves the route undrawn.

local RouteLines = {}
addon.RouteLines = RouteLines

local Theme = addon.Theme
local MapRoute = addon.MapRoute

-- Screen pixels. `color` names a method colour of the theme; `on`/`off` make dots or dashes; `halo` is a wide
-- faint band under the line.
local LOOK = {
    foot = { color = "walk", width = 3.2, on = 2, off = 6.5, halo = 12 },
    flight = { color = "taxi", width = 3, on = 9, off = 7 },
    boat = { color = "ship", width = 3.5 },
    ability = { color = "teleport", width = 3.2, on = 2, off = 6.5 },
}
local BADGE = 18
local DONE_ALPHA = 0.35            -- steps already done fade

local state = { plan = nil, current = nil, lines = {}, linesUsed = 0, badges = {}, badgesUsed = 0 }
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

local function acquireLine(frame)
    state.linesUsed = state.linesUsed + 1
    local line = state.lines[state.linesUsed]
    if not line then
        line = frame:CreateLine(nil, "OVERLAY")
        state.lines[state.linesUsed] = line
    end
    line:Show()
    return line
end

local function segment(frame, a, b, thickness, r, g, bl, alpha)
    local line = acquireLine(frame)
    line:SetThickness(thickness)
    line:SetColorTexture(r, g, bl, alpha)
    line:SetStartPoint("TOPLEFT", frame, a.x, -a.y)
    line:SetEndPoint("TOPLEFT", frame, b.x, -b.y)
end

local function acquireBadge(frame)
    state.badgesUsed = state.badgesUsed + 1
    local badge = state.badges[state.badgesUsed]
    if not badge then
        badge = CreateFrame("Frame", nil, frame)
        badge:SetSize(BADGE, BADGE)
        badge.ring = badge:CreateTexture(nil, "BACKGROUND")
        badge.ring:SetAllPoints()
        badge.fill = badge:CreateTexture(nil, "BORDER")
        badge.fill:SetPoint("TOPLEFT", 2, -2)
        badge.fill:SetPoint("BOTTOMRIGHT", -2, 2)
        badge.text = Theme:Text(badge, "body")
        badge.text:SetPoint("CENTER", 0, 0)
        state.badges[state.badgesUsed] = badge
    end
    badge:Show()
    return badge
end

local function drawPiece(frame, piece, unit, W, H)
    local look = LOOK[piece.style] or LOOK.foot
    local r, g, b = Theme:MethodColor(look.color)
    local alpha = (state.current and piece.step < state.current) and DONE_ALPHA or 1
    local points = {}
    for i, p in ipairs(piece.points) do points[i] = { x = p.x * W, y = p.y * H } end
    if look.halo then
        for i = 1, #points - 1 do segment(frame, points[i], points[i + 1], look.halo * unit, r, g, b, 0.14 * alpha) end
    end
    if look.on then
        for _, s in ipairs(MapRoute.Pattern(points, look.on * unit, look.off * unit)) do
            segment(frame, { x = s[1], y = s[2] }, { x = s[3], y = s[4] }, look.width * unit, r, g, b, alpha)
        end
    else
        for i = 1, #points - 1 do segment(frame, points[i], points[i + 1], look.width * unit, r, g, b, alpha) end
    end
end

local function drawMarker(frame, marker, unit, W, H)
    local badge = acquireBadge(frame)
    badge:SetScale(unit)
    badge:ClearAllPoints()
    badge:SetPoint("CENTER", frame, "TOPLEFT", (marker.x * W) / unit, (-marker.y * H) / unit)
    if marker.kind == "dest" then
        local r, g, b = Theme:Color("accent")
        badge.ring:SetColorTexture(0.06, 0.07, 0.09, 1)
        badge.fill:SetColorTexture(r, g, b, 1)
        badge.text:SetText("")
    else
        local r, g, b = Theme:MethodColor(LOOK[marker.style] and LOOK[marker.style].color or "walk")
        local current = state.current == marker.index
        local done = state.current and marker.index < state.current
        badge.ring:SetColorTexture(r, g, b, done and DONE_ALPHA or 1)
        if current then badge.fill:SetColorTexture(0.93, 0.9, 0.84, 1) else badge.fill:SetColorTexture(0.08, 0.09, 0.12, 1) end
        badge.text:SetText(tostring(marker.index))
    end
end

local function draw(frame, plan, mapID)
    local W, H = frame:GetWidth(), frame:GetHeight()
    if not (W and H and W > 0 and H > 0) then return end
    local unit = unitOf(frame)
    local pieces, markers = MapRoute:Pieces(plan, mapID)
    for _, piece in ipairs(pieces) do drawPiece(frame, piece, unit, W, H) end
    for _, marker in ipairs(markers) do drawMarker(frame, marker, unit, W, H) end
end

-- Take down everything drawn (the pieces stay pooled for next time).
function RouteLines:Hide()
    for i = 1, state.linesUsed do state.lines[i]:Hide() end
    for i = 1, state.badgesUsed do state.badges[i]:Hide() end
    state.linesUsed, state.badgesUsed = 0, 0
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

-- Show this plan's route on the map. (Its steps carry their paths: Journey.)
function RouteLines:Show(plan)
    state.plan, state.current = plan, nil
    self:Redraw()
end

-- Which step the trip is on: earlier ones fade, this one's badge is filled.
function RouteLines:SetCurrent(index)
    if state.current == index then return end
    state.current = index
    self:Redraw()
end

function RouteLines:Clear()
    state.plan, state.current = nil, nil
    self:Hide()
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
