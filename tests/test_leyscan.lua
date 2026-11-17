-- Finding ley line / convergence blips on the minimap (LeyScan.lua) and sharing them (LeyShare:OnMinimapNode).
-- A fake minimap draws blips with its own forward model (world -> minimap), written apart from LeyScan's inverse,
-- including a rotating minimap where the player's facing is up instead of north. Ported from SLLCM's
-- tools/test_scan.py.
-- LeyScan.lua is out of the .toc since 2026-11-16 (Forever's minimap tooltips are secret to addons), so it's loaded
-- here by hand, to keep it working in case Blizzard reverts.

do
    local f = assert(io.open(ADDON_ROOT .. "/LeyScan.lua", "rb"))
    local src = f:read("*a")
    f:close()
    assert(loadstring(src, "@LeyScan.lua"))("Mapzeroth-Dev", addon)
end
useTestDistances()
addon.World:Build()

local LS, Scan = addon.LeyShare, addon.LeyScan

local ZONE_W, ZONE_H = 3000, 2000              -- yards
local VIEW_RADIUS = 233                        -- yards from the minimap's centre to its edge
local MM_SIZE, MM_LEFT, MM_BOTTOM, MM_SCALE = 140, 1000, 500, 0.8
local BLIP_SIZES = { 6, 12 }                   -- a blip's tooltip area half-widths to try, minimap units (10+ in game)
local blipHalf = 6
local YPP = VIEW_RADIUS / (MM_SIZE / 2)        -- yards per minimap unit
local TOLERANCE = math.sqrt(2) * YPP           -- a scan: the 2-unit fine grid is off by up to 1 unit per axis
local HOVER_TOLERANCE = 12 * YPP               -- a resting cursor is anywhere on the blip
local MAP = 1417

-- A Skyborne Alliance character sharing, on a client with the channel joined as /5.
local now, clock = 1800000000, 1000
function GetServerTime() return now end
function GetTime() return clock end
function UnitRace() return "Skyborne", "Skyborne", 99 end
function UnitFactionGroup() return "Alliance" end
function strsplit(sep, text, limit)
    local out, start = {}, 1
    while true do
        if limit and #out == limit - 1 then out[#out + 1] = text:sub(start) break end
        local i = text:find(sep, start, true)
        if not i then out[#out + 1] = text:sub(start) break end
        out[#out + 1] = text:sub(start, i - 1)
        start = i + 1
    end
    return unpack(out)
end
function wipe(t) for k in pairs(t) do t[k] = nil end return t end
local loaded = {}
C_AddOns = { IsAddOnLoaded = function(name) return loaded[name] or false end }
-- The send queue drains at once; the 15 s echo check never fires (the server always echoes here).
C_Timer = { After = function(delay, fn) if delay ~= 15 then fn() end end }
local sent = {}
C_ChatInfo = { SendAddonMessage = function(_, msg) sent[#sent + 1] = msg return 0 end }
function GetChannelName(name) return name == "SLLCMShareA" and 5 or 0 end
MapzerothRebuildDB = {}
addon.Options:Set("shareSightings", true)

-- The world: the player, their facing, and the minimap's state.
local player, facing, rotate, wrongWay = { 0.5, 0.5 }, 0, false, false
local controller, pointer, mouseOver, combat, instance = false, nil, false, false, false
local blips, softOn, probe = {}, false, nil
C_Map = {
    GetMapInfo = function(id) return { name = "map " .. id } end,
    GetBestMapForUnit = function() return MAP end,
    GetPlayerMapPosition = function() return { x = player[1], y = player[2] } end,
    -- World axes are swapped relative to the map's, as in the client.
    GetWorldPosFromMapPos = function(id, v) return id, CreateVector2D(v.y * ZONE_H, v.x * ZONE_W) end,
}
C_Minimap = { GetViewRadius = function() return VIEW_RADIUS end }
function GetCVar(k) return (k == "rotateMinimap" and rotate) and "1" or "0" end
function GetCVarBool(k) return k == "GamePadEnable" end     -- on for keyboard players too: must not matter
InputUtil = { IsGamepadUIEnabled = function() return controller end }
function GetPlayerFacing() return facing end
function InCombatLockdown() return combat end
function IsInInstance() return instance end
GameTooltip = { IsShown = function() return false end }

-- World -> minimap units, the way the game draws it. GetPlayerFacing is radians counter-clockwise from north; with
-- rotation on, the facing direction is up.
local function project(node)
    local east = (node[1] - player[1]) * ZONE_W
    local north = -(node[2] - player[2]) * ZONE_H       -- map y grows southward
    local sx, sy = east, north
    if rotate then
        local f = wrongWay and -facing or facing
        local fwdE, fwdN = -math.sin(f), math.cos(f)
        local rightE, rightN = math.cos(f), math.sin(f)
        sx, sy = east * rightE + north * rightN, east * fwdE + north * fwdN
    end
    return MM_SIZE / 2 + sx / YPP, MM_SIZE / 2 + sy / YPP
end

local function tooltipAt(pt)
    local lines = {}
    if pt then
        for _, b in ipairs(blips) do
            if math.abs(pt[1] - b[1]) <= blipHalf and math.abs(pt[2] - b[2]) <= blipHalf then
                lines[#lines + 1] = { leftText = "|cffffffffLey Line|r" }
            end
        end
        if math.abs(pt[1] - 30) < 5 and math.abs(pt[2] - 30) < 5 then lines[#lines + 1] = { leftText = "Copper Vein" } end
    end
    return { lines = lines }
end

Minimap = {
    SetUsingSoftCursor = function(_, on) softOn = on end,
    UpdateMouseoverAtPoint = function(_, x, y)
        check(softOn, "the soft cursor is on while probing")
        probe = { x / MM_SCALE - MM_LEFT, y / MM_SCALE - MM_BOTTOM }
    end,
    GetEffectiveScale = function() return MM_SCALE end,
    GetLeft = function() return MM_LEFT end,
    GetBottom = function() return MM_BOTTOM end,
    GetSize = function() return MM_SIZE, MM_SIZE end,
    IsVisible = function() return true end,
    IsMouseOver = function() return mouseOver end,
    GetZoom = function() return 0 end,
}
-- With a controller the game points the minimap's mouseover at its own cursor.
C_TooltipInfo = { GetMinimapMouseover = function() return tooltipAt(controller and pointer or probe) end }

local frame, tickers
function CreateFrame()
    local f = { shown = true }
    function f:SetScript(k, fn) self[k] = fn end
    function f:Show() self.shown = true end
    function f:Hide() self.shown = false end
    frame = f
    return f
end
C_Timer.NewTicker = function(secs, fn) tickers[secs] = fn end

-- Reported positions: LeyShare's handler swapped for a recorder while the geometry is tested.
local found
local realReport = LS.OnMinimapNode
local function record() LS.OnMinimapNode = function(_, _, x, y) found[#found + 1] = { x, y } end end

local function setup(nodes)
    Scan:ResetForTests()
    tickers, found, probe, softOn = {}, {}, nil, false
    blips = {}
    for _, n in ipairs(nodes) do blips[#blips + 1] = { project(n) } end
    Scan:Start()
end

local function runScan(nodes)
    setup(nodes)
    tickers[2]()                                 -- Check starts a scan
    for _ = 1, 500 do
        if not frame.shown then break end
        frame.OnUpdate(frame)
    end
    check(not softOn, "the soft cursor is off again")
    return found
end

local function yards(a, b)
    return math.sqrt(((a[1] - b[1]) * ZONE_W) ^ 2 + ((a[2] - b[2]) * ZONE_H) ^ 2)
end

local function lands(nodes, got, tolerance)
    if #got ~= #nodes then return false, ("%d found of %d"):format(#got, #nodes) end
    local worst = 0
    for _, n in ipairs(nodes) do
        local best = math.huge
        for _, f in ipairs(got) do best = math.min(best, yards(n, f)) end
        worst = math.max(worst, best)
    end
    return worst <= (tolerance or TOLERANCE), ("worst %.1f yd"):format(worst)
end

record()
-- Three nodes in view: NE, SW, and nearly due west.
local nodes = { { 0.5 + 120 / ZONE_W, 0.5 - 80 / ZONE_H }, { 0.5 - 60 / ZONE_W, 0.5 + 150 / ZONE_H },
                { 0.5 - 190 / ZONE_W, 0.5 + 10 / ZONE_H } }

local ok, detail
for _, half in ipairs(BLIP_SIZES) do
    blipHalf = half
    facing, rotate = 1.0, false
    ok, detail = lands(nodes, runScan(nodes))
    check(ok, ("blip %d: rotation off: %s"):format(half, detail))
    rotate = true
    for _, deg in ipairs({ 0, 45, 90, 135, 180, 230, 300 }) do
        facing = math.rad(deg)
        ok, detail = lands(nodes, runScan(nodes))
        check(ok, ("blip %d: rotating, facing %d deg: %s"):format(half, deg, detail))
    end
end

-- Standing on a node with a wide tooltip area: one blip, not one per coarse hit (it split into four in SLLCM in game).
blipHalf, rotate, facing = 12, false, 0
ok, detail = lands({ player }, runScan({ player }))
check(ok, "standing on a node: " .. detail)
blipHalf, rotate = 6, true

-- The test can tell a wrong rotation apart: drawn rotated the other way, the scan must miss.
facing, wrongWay = math.rad(70), true
ok = lands(nodes, runScan(nodes))
check(not ok, "drawn rotated the wrong way misses")
wrongWay = false

-- Never with the mouse on the minimap, in combat or in an instance; a scan in progress stops for them.
facing = 0
mouseOver = true
check(#runScan(nodes) == 0, "not with the mouse on the minimap")
mouseOver = false
combat = true
check(#runScan(nodes) == 0, "nor in combat")
combat = false
instance = true
check(#runScan(nodes) == 0, "nor in an instance")
instance = false
setup(nodes)
tickers[2]()
frame.OnUpdate(frame)
combat = true
frame.OnUpdate(frame)
check(not frame.shown and #found == 0 and not softOn, "combat starting stops a scan")
combat = false

-- Once scanned, not again until moved 30 yards, zoomed, or a minute passes.
setup(nodes)
tickers[2]()
check(frame.shown, "a scan starts")
for _ = 1, 500 do if frame.shown then frame.OnUpdate(frame) end end
tickers[2]()
check(not frame.shown, "standing still, not straight away")
player = { 0.5 + 20 / ZONE_W, 0.5 }
tickers[2]()
check(not frame.shown, "nor after 20 yards")
player = { 0.5 + 35 / ZONE_W, 0.5 }
tickers[2]()
check(frame.shown, "but after 35")
for _ = 1, 500 do if frame.shown then frame.OnUpdate(frame) end end
clock = clock + 61
tickers[2]()
check(frame.shown, "or after a minute")
player = { 0.5, 0.5 }

-- Only while Mapzeroth shares: not with sharing off, the setting off, SLLCM loaded, or on another race.
local function starts()
    setup(nodes)
    tickers[2]()
    return frame.shown
end
addon.Options:Set("shareSightings", false)
check(not starts(), "not with sharing off")
addon.Options:Set("shareSightings", true)
addon.Options:Set("detectMinimapNodes", false)
check(not starts(), "nor with detection off")
addon.Options:Set("detectMinimapNodes", true)
loaded.SkyborneLeyLineConvergenceMarker = true
check(not starts(), "nor with SLLCM loaded (it scans itself)")
loaded.SkyborneLeyLineConvergenceMarker = nil
UnitRace = function() return "Human", "Human", 1 end
check(not starts(), "nor on another race")
UnitRace = function() return "Skyborne", "Skyborne", 99 end
check(starts(), "and with all of that, it does")

-- A controller: no scan (the game owns the soft cursor); its SoftCursor resting on a blip records it.
controller, rotate = true, true
for _, deg in ipairs({ 0, 160 }) do
    facing = math.rad(deg)
    setup(nodes)
    tickers[2]()
    check(not frame.shown, "a controller never scans")
    local bx, by = project(nodes[1])
    pointer = { bx + 2, by - 1 }
    local cs = 0.64           -- the SoftCursor in a UI scale different from the minimap's
    SoftCursor = {
        shown = true,
        IsShown = function(self) return self.shown end,
        GetEffectiveScale = function() return cs end,
        GetCenter = function() return (MM_LEFT + pointer[1]) * MM_SCALE / cs, (MM_BOTTOM + pointer[2]) * MM_SCALE / cs end,
    }
    for _ = 1, 3 do tickers[0.1]() end
    check(#found == 0, "nothing while the cursor rests on it")
    SoftCursor.shown = false
    tickers[0.1]()
    ok, detail = lands({ nodes[1] }, found, HOVER_TOLERANCE)
    check(ok, ("controller cursor, facing %d deg: %s"):format(deg, detail))
end
controller, pointer, SoftCursor = false, nil, nil

-- The dev report (/mzr scan): one scan now, whatever the last was, reporting what it saw.
setup(nodes)
local report
check(Scan:ScanNow(function(r) report = r end) == nil, "ScanNow starts a scan")
check(Scan:ScanNow(function() end) == "one already running", "but not a second")
for _ = 1, 500 do if frame.shown then frame.OnUpdate(frame) end end
check(report and report.why == "finished" and report.blips == 3 and #report.found == 3, "it reports three blips")
local sawVein = false
for _, t in ipairs(report.texts) do if t == "Copper Vein" then sawVein = true end end
check(sawVein, "and the other tooltip text it passed")
check(Scan:Diagnose().scanning, "Diagnose: scanning with GamePadEnable on and no gamepad UI")

---------------------------------------------------------------------------
-- Sharing a blip: like a racial's sighting, unless this phase has one of that node from the last 10 minutes.
---------------------------------------------------------------------------

LS.OnMinimapNode = realReport
LS:ResetForTests()
MapzerothRebuildDB.sightings, MapzerothRebuildDB.sharedNodes = nil, nil
sent = {}
local node = { 0.4, 0.6 }
LS:OnMinimapNode(MAP, node[1], node[2])
check(#sent == 0, "no phase yet: nothing sent")
LS:ReadGUID("Creature-0-1-2-3104-1234-0001")
check(sent[1] == "R:1:A:3104:1417:4000:6000:" .. now, "the blip goes out once the phase is known: " .. tostring(sent[1]))
check(sent[2] == "Q:1:A:3104", "and the phase is asked about: " .. tostring(sent[2]))
sent = {}
now = now + 60
LS:OnMinimapNode(MAP, node[1] + 10 / ZONE_W, node[2])
check(#sent == 0, "passing it again a minute later sends nothing")
now = now + 10 * 60
LS:OnMinimapNode(MAP, node[1], node[2])
check(#sent == 1 and sent[1]:find("^R:1:A:3104:1417:4000:6000:"), "ten minutes on it goes out again")
sent = {}
LS:OnMinimapNode(MAP, 0.7, 0.3)
check(#sent == 1, "another node goes out straight away")
sent = {}
-- Someone else's sighting counts too.
LS:OnMessage(("R:1:A:3104:1417:2000:2000:%d"):format(now))
LS:OnMinimapNode(MAP, 0.2, 0.2)
check(#sent == 0, "a node someone just reported isn't sent again")
-- And one from another phase doesn't.
LS:OnMessage(("R:1:A:9999:1417:8000:8000:%d"):format(now))
LS:OnMinimapNode(MAP, 0.8, 0.8)
check(#sent == 1, "one reported in another phase is")
sent = {}
addon.Options:Set("detectMinimapNodes", false)
LS:OnMinimapNode(MAP, 0.1, 0.9)
check(#sent == 0, "detection off: nothing")
addon.Options:Set("detectMinimapNodes", true)
loaded.SkyborneLeyLineConvergenceMarker = true
LS:OnMinimapNode(MAP, 0.1, 0.9)
check(#sent == 0, "SLLCM loaded: nothing (it reports its own)")
loaded.SkyborneLeyLineConvergenceMarker = nil

local w, h = LS:ZoneSizeYards(MAP)
check(w == ZONE_W and h == ZONE_H, "zone size from the world axes, swapped: " .. tostring(w) .. " x " .. tostring(h))
