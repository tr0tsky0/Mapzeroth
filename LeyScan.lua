local addonName, addon = ...

-- Finds ley line / elemental convergence blips on the minimap without the mouse, and hands each to LeyShare as a
-- sighting (a blip only shows while the node is up in the player's phase). Only while LeyShare:Networking() is true,
-- so never alongside SLLCM, which does the same itself.
--
-- The minimap's soft cursor (made for controllers) can be pointed at any spot and asked for the tooltip it would
-- show there. A coarse grid finds blips, then a fine grid around each hit puts its centre within a few yards. With a
-- controller the game drives that soft cursor itself, so instead of scanning, whatever points at the minimap (the
-- mouse, or the controller's SoftCursor) is watched and a blip it passes over is recorded.
--
-- SLLCM's Scan.lua is the reference (the approach came from Skyborne Compass's author); keep the two in step.

local LeyScan = {}
addon.LeyScan = LeyScan

local NAMES = { "Leyline", "Ley Line", "Elemental Convergence" }   -- the minimap tooltip's text; English only, as in SLLCM
-- "Leyline" since 2026-10-18 (was "Ley Line")
local CHECK_SECONDS = 2        -- how often to decide whether to scan
local MOVE_YARDS = 30          -- scan after moving this far
local IDLE_SECONDS = 60        -- or after this long standing still: a node can come up next to you
local COARSE_STEP = 8          -- minimap units between coarse points; a blip is wider than this
local FINE_STEP = 2
local PER_FRAME = 60           -- coarse points per frame, so the scan doesn't stutter
local FINE_PER_FRAME = 150     -- fine points per frame
local HOVER_SECONDS = 0.1      -- controller / no scan APIs: how often to look at the pointer
local MAX_SAMPLE_YARDS = 60    -- a hover reading spread wider than this (moved, tooltip lingered) is dropped

local frame                    -- runs a scan in progress, a frame at a time (made by Start)
local scan                     -- the scan in progress: { mapID, points, i, hits, blips, b, report }
local last                     -- where and when the last scan ran: { mapID, x, y, zoom, at }
local sample                   -- pointer watching: the box of zone positions while a node's tooltip stays up

local function enabled()
    return addon.Options:Get("detectMinimapNodes") and addon.LeyShare:Networking()
end

local function supported()
    return Minimap and Minimap.SetUsingSoftCursor and Minimap.UpdateMouseoverAtPoint and C_TooltipInfo
        and C_TooltipInfo.GetMinimapMouseover and C_Minimap and C_Minimap.GetViewRadius
end

local function strip(text)
    return (text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t", ""):gsub("|A.-|a", ""))
end

local function isNodeText(text)
    if type(text) ~= "string" then return false end
    text = strip(text)
    for _, name in ipairs(NAMES) do
        if text:find(name, 1, true) then return true end
    end
    return false
end

-- Does this tooltip data name a node? One tooltip can list several dots.
local function hasNode(data)
    for _, line in ipairs(data and data.lines or {}) do
        if isNodeText(line.leftText) then return true end
    end
    return false
end

-- Is there a node blip at this point (minimap units from its bottom left)?
local function nodeAt(lx, ly)
    local s = Minimap:GetEffectiveScale()
    Minimap:UpdateMouseoverAtPoint((Minimap:GetLeft() + lx) * s, (Minimap:GetBottom() + ly) * s)
    local data = C_TooltipInfo.GetMinimapMouseover()
    if scan and scan.texts then                         -- a dev report (ScanNow): every tooltip line the scan saw
        for _, line in ipairs(data and data.lines or {}) do
            if type(line.leftText) == "string" then scan.texts[strip(line.leftText)] = true end
        end
    end
    return hasNode(data)
end

-- Runs fn with the soft cursor on, and always turns it back off.
local function withSoftCursor(fn)
    Minimap:SetUsingSoftCursor(true)
    local ok, err = pcall(fn)
    Minimap:SetUsingSoftCursor(false)
    if not ok and scan then scan.err = err end
    return ok
end

local function playerPos()
    local mapID = C_Map.GetBestMapForUnit("player")
    local pos = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
    if pos then return mapID, pos.x, pos.y end
end

-- A minimap point (minimap units from its bottom left) to zone coordinates, from the player's position now.
function LeyScan:ToZone(lx, ly)
    local mapID, px, py = playerPos()
    local zw, zh
    if mapID then zw, zh = addon.LeyShare:ZoneSizeYards(mapID) end
    if not zw then return nil end
    local w, h = Minimap:GetSize()
    local ypp = C_Minimap.GetViewRadius() / (w / 2)
    local dx, dy = (lx - w / 2) * ypp, (ly - h / 2) * ypp     -- yards; +x east, +y north
    if GetCVar("rotateMinimap") == "1" then
        local f = GetPlayerFacing() or 0
        dx, dy = dx * math.cos(f) - dy * math.sin(f), dx * math.sin(f) + dy * math.cos(f)
    end
    local x, y = px + dx / zw, py - dy / zh
    if x >= 0 and x <= 1 and y >= 0 and y <= 1 then return mapID, x, y end
end

-- A controller is in use: it owns the minimap's soft cursor, so we must not switch it on and off. Not the GamePadEnable
-- CVar: it can be on for players who have never touched a controller (it blocked SLLCM's scan for one).
local function controller()
    return (InputUtil and InputUtil.IsGamepadUIEnabled and InputUtil.IsGamepadUIEnabled())
        or (SoftCursor and SoftCursor:IsShown()) or false
end

-- Scan, or (a controller, or a client without the APIs) watch the pointer instead.
local function scanning()
    return supported() and not controller()
end

-- why: set when a scan is cut short, for a dev report.
local function stop(why)
    local s = scan
    scan = nil
    if frame then frame:Hide() end
    if not (s and s.report) then return end
    local texts = {}
    for t in pairs(s.texts) do texts[#texts + 1] = t end
    table.sort(texts)
    s.report({ why = why or "finished", done = math.min(s.i - 1, #s.points), points = #s.points, hits = #s.hits,
               blips = #s.blips, err = s.err, texts = texts, found = s.found })
end

local function blocked()
    return InCombatLockdown() or not Minimap:IsVisible() or Minimap:IsMouseOver()
end

-- Touching coarse hits (diagonals too) are one blip: its tooltip area is wider than the coarse step, by how much
-- depends on the minimap's size and scale (20+ units on a large square minimap in game, where fine-scanning around
-- each hit apart turned one node next to the player into four, ~10 yd off at the corners). Each blip gets a fine grid
-- over its hits' box, widened by a coarse step each way (the area ends somewhere before the next coarse point out).
local function groupBlips(hits)
    local at, blips, seen = {}, {}, {}
    for _, h in ipairs(hits) do at[h.i .. ":" .. h.j] = h end
    for _, h in ipairs(hits) do
        if not seen[h] then
            local x0, x1, y0, y1 = h[1], h[1], h[2], h[2]
            local stack = { h }
            seen[h] = true
            while #stack > 0 do
                local c = table.remove(stack)
                x0, x1, y0, y1 = math.min(x0, c[1]), math.max(x1, c[1]), math.min(y0, c[2]), math.max(y1, c[2])
                for di = -1, 1 do
                    for dj = -1, 1 do
                        local nb = at[(c.i + di) .. ":" .. (c.j + dj)]
                        if nb and not seen[nb] then
                            seen[nb] = true
                            stack[#stack + 1] = nb
                        end
                    end
                end
            end
            local points = {}
            for x = x0 - COARSE_STEP, x1 + COARSE_STEP, FINE_STEP do
                for y = y0 - COARSE_STEP, y1 + COARSE_STEP, FINE_STEP do points[#points + 1] = { x, y } end
            end
            blips[#blips + 1] = { points = points, i = 1, sx = 0, sy = 0, n = 0 }
        end
    end
    return blips
end

-- One frame of a scan in progress.
function LeyScan:Update()
    if not scan then return stop() end
    -- The player's own mouse on the minimap wins; a zone change makes the hits meaningless.
    if blocked() or not enabled() then return stop("stopped (combat, minimap hidden or mouse on it)") end
    if C_Map.GetBestMapForUnit("player") ~= scan.mapID then return stop("stopped (zone changed)") end

    if scan.i <= #scan.points then
        -- Coarse pass: every hit, with its grid indexes.
        local ok = withSoftCursor(function()
            for i = scan.i, math.min(scan.i + PER_FRAME - 1, #scan.points) do
                local p = scan.points[i]
                if nodeAt(p[1], p[2]) then scan.hits[#scan.hits + 1] = p end
            end
        end)
        if not ok then return stop("failed") end
        scan.i = scan.i + PER_FRAME
        if scan.i > #scan.points then scan.blips = groupBlips(scan.hits) end
        return
    end

    -- Fine pass: a blip's centre is the centre of the points that show its tooltip.
    local blip = scan.blips[scan.b]
    if not blip then return stop() end
    local ok = withSoftCursor(function()
        for i = blip.i, math.min(blip.i + FINE_PER_FRAME - 1, #blip.points) do
            local p = blip.points[i]
            if nodeAt(p[1], p[2]) then blip.sx, blip.sy, blip.n = blip.sx + p[1], blip.sy + p[2], blip.n + 1 end
        end
    end)
    if not ok then return stop("failed") end
    blip.i = blip.i + FINE_PER_FRAME
    if blip.i <= #blip.points then return end
    scan.b = scan.b + 1
    if blip.n == 0 then return end
    local lx, ly = blip.sx / blip.n, blip.sy / blip.n
    local mapID, x, y = self:ToZone(lx, ly)
    if scan.found then scan.found[#scan.found + 1] = { lx = lx, ly = ly, n = blip.n, mapID = mapID, x = x, y = y } end
    if mapID then addon.LeyShare:OnMinimapNode(mapID, x, y) end
end

-- Coarse grid centred on the minimap, clipped to its round shape unless an addon made it square. i, j are grid indexes,
-- so groupBlips can find neighbours.
local function coarsePoints()
    local w, h = Minimap:GetSize()
    local cx, cy, r = w / 2, h / 2, math.min(w, h) / 2
    local square = GetMinimapShape and GetMinimapShape() == "SQUARE"
    local points, n = {}, math.floor(r / COARSE_STEP)
    for i = -n, n do
        for j = -n, n do
            local ox, oy = i * COARSE_STEP, j * COARSE_STEP
            if square or ox * ox + oy * oy <= r * r then points[#points + 1] = { cx + ox, cy + oy, i = i, j = j } end
        end
    end
    return points
end

-- Every CHECK_SECONDS: start a scan when the player has moved, zoomed, changed zone, or stood still a while.
function LeyScan:Check()
    if scan or not frame or not enabled() or not scanning() or blocked() then return end
    if IsInInstance() then return end
    local mapID, x, y = playerPos()
    local zw, zh
    if mapID then zw, zh = addon.LeyShare:ZoneSizeYards(mapID) end
    if not zw then return end
    local zoom, now = Minimap:GetZoom(), GetTime()
    if last and last.mapID == mapID and last.zoom == zoom and now - last.at < IDLE_SECONDS
            and math.sqrt(((last.x - x) * zw) ^ 2 + ((last.y - y) * zh) ^ 2) < MOVE_YARDS then
        return
    end
    last = { mapID = mapID, x = x, y = y, zoom = zoom, at = now }
    scan = { mapID = mapID, points = coarsePoints(), i = 1, hits = {}, blips = {}, b = 1 }
    frame:Show()
end

-- For the dev tools (/mzr scan): what decides whether a scan runs, and the minimap's shape and scale.
function LeyScan:Diagnose()
    local w, h = Minimap:GetSize()
    return {
        apis = {
            SetUsingSoftCursor = Minimap.SetUsingSoftCursor ~= nil, UpdateMouseoverAtPoint = Minimap.UpdateMouseoverAtPoint ~= nil,
            GetMinimapMouseover = (C_TooltipInfo and C_TooltipInfo.GetMinimapMouseover) ~= nil,
            GetViewRadius = (C_Minimap and C_Minimap.GetViewRadius) ~= nil,
        },
        setting = addon.Options:Get("detectMinimapNodes"), networking = addon.LeyShare:Networking(),
        gamepadUI = (InputUtil and InputUtil.IsGamepadUIEnabled and InputUtil.IsGamepadUIEnabled()) and true or false,
        softCursor = (SoftCursor and SoftCursor:IsShown()) and true or false,
        combat = InCombatLockdown() and true or false, instance = IsInInstance() and true or false,
        mouseOn = Minimap:IsMouseOver() and true or false, scanning = scanning() and true or false,
        width = w, height = h, left = Minimap:GetLeft(), bottom = Minimap:GetBottom(), scale = Minimap:GetEffectiveScale(),
        shape = GetMinimapShape and GetMinimapShape() or nil, viewRadius = C_Minimap and C_Minimap.GetViewRadius and C_Minimap.GetViewRadius(),
        zoom = Minimap:GetZoom(), rotate = GetCVar("rotateMinimap") == "1",
    }
end

-- For the dev tools: one scan now, whatever the last one was. report(result) is called when it ends, with how far it
-- got, every tooltip line it saw and each blip found ({ lx, ly, n, mapID, x, y }). Returns nil, or why it didn't start.
function LeyScan:ScanNow(report)
    if not scanning() then return supported() and "controller mode (pointer watching instead)" or "APIs missing" end
    if scan then return "one already running" end
    if not frame then return "not started (before login?)" end
    last = nil
    self:Check()
    if not scan then return "didn't start (setting off, not sharing, combat, instance, or mouse on the minimap)" end
    scan.report, scan.texts, scan.found = report, {}, {}
end

---------------------------------------------------------------------------
-- Pointer watching (a controller, or no scan APIs). The tooltip appears as the pointer reaches the blip's edge, so
-- readings are kept while it stays up and the centre of their box is recorded when it goes.
---------------------------------------------------------------------------

-- Where the pointer is on the minimap (minimap units from its bottom left): the mouse, or the controller's SoftCursor.
local function pointerOnMinimap()
    local s, left, bottom = Minimap:GetEffectiveScale(), Minimap:GetLeft(), Minimap:GetBottom()
    if not left then return nil end
    if Minimap:IsMouseOver() then
        local cx, cy = GetCursorPosition()
        return cx / s - left, cy / s - bottom
    end
    local cursor = SoftCursor
    if cursor and cursor:IsShown() then
        local cx, cy = cursor:GetCenter()
        if not cx then return nil end
        local f = cursor:GetEffectiveScale() / s
        local lx, ly = cx * f - left, cy * f - bottom
        local w, h = Minimap:GetSize()
        if lx >= 0 and ly >= 0 and lx <= w and ly <= h then return lx, ly end
    end
end

-- The minimap's own tooltip data, or failing that GameTooltip's lines (the pointer is on the minimap).
local function hoverShowsNode()
    local data = C_TooltipInfo and C_TooltipInfo.GetMinimapMouseover and C_TooltipInfo.GetMinimapMouseover()
    if data and data.lines and #data.lines > 0 then return hasNode(data) end
    if not GameTooltip:IsShown() then return false end
    for i = 1, GameTooltip:NumLines() do
        local line = _G["GameTooltipTextLeft" .. i]
        if line and isNodeText(line:GetText()) then return true end
    end
    return false
end

local function finishSample()
    if not sample then return end
    local s = sample
    sample = nil
    local zw, zh = addon.LeyShare:ZoneSizeYards(s.mapID)
    if not zw or (s.x1 - s.x0) * zw > MAX_SAMPLE_YARDS or (s.y1 - s.y0) * zh > MAX_SAMPLE_YARDS then return end
    addon.LeyShare:OnMinimapNode(s.mapID, (s.x0 + s.x1) / 2, (s.y0 + s.y1) / 2)
end

-- Every HOVER_SECONDS, when not scanning.
function LeyScan:Watch()
    if scanning() or not enabled() then return finishSample() end
    local lx, ly = pointerOnMinimap()
    local ok, node = pcall(hoverShowsNode)           -- tooltip text can be secret in combat
    if not (lx and ok and node) then return finishSample() end
    local mapID, x, y = self:ToZone(lx, ly)
    if not mapID then return end
    if sample and sample.mapID ~= mapID then finishSample() end
    if not sample then
        sample = { mapID = mapID, x0 = x, x1 = x, y0 = y, y1 = y }
    else
        sample.x0, sample.x1 = math.min(sample.x0, x), math.max(sample.x1, x)
        sample.y0, sample.y1 = math.min(sample.y0, y), math.max(sample.y1, y)
    end
end

-- At login (once): the scan frame and the two tickers. Each does nothing while sharing is off or SLLCM is loaded.
function LeyScan:Start()
    if frame or not Minimap then return end
    frame = CreateFrame("Frame")
    frame:Hide()
    frame:SetScript("OnUpdate", function() LeyScan:Update() end)
    C_Timer.NewTicker(CHECK_SECONDS, function() LeyScan:Check() end)
    C_Timer.NewTicker(HOVER_SECONDS, function() LeyScan:Watch() end)
end

-- Tests only: forget the scan, the last scan's place and any hover sample (and the frame, so Start runs again).
function LeyScan:ResetForTests()
    frame, scan, last, sample = nil, nil, nil, nil
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function() LeyScan:Start() end)
