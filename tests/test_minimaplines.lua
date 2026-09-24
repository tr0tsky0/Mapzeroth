-- The route on the minimap: drawn round the player, north up or turned with them, scaled by the minimap's zoom,
-- clipped to its circle, and following the trip being followed. (Frames here record what they are asked to draw.)
useTestDistances()
addon.World:Build()

local Options, MinimapLines = addon.Options, addon.MinimapLines

-- The minimap and what the client tells us about the player.
local zoom, cvars, facing = 0, { minimapZoom = "0", minimapInsideZoom = "1", rotateMinimap = "0" }, 0
local playerX, playerY, playerMap = 0.5, 0.5, 1453
local lines = {}
local function newFrame()
    local f = { _shown = true, _scripts = {} }
    f.SetAllPoints = function() end
    f.SetFrameLevel = function() end
    f.RegisterEvent = function() end
    f.SetScript = function(self, name, fn) self._scripts[name] = fn end
    f.Show = function(self) self._shown = true end
    f.Hide = function(self) self._shown = false end
    f.GetEffectiveScale = function() return 1 end
    f.CreateLine = function()
        local line = { _shown = true }
        line.SetThickness = function(self, t) self._thickness = t end
        line.SetColorTexture = function(self, r, g, b, a) self._alpha = a end
        line.SetStartPoint = function(self, _, _, x, y) self._x1, self._y1 = x, y end
        line.SetEndPoint = function(self, _, _, x, y) self._x2, self._y2 = x, y end
        line.Show = function(self) self._shown = true end
        line.Hide = function(self) self._shown = false end
        lines[#lines + 1] = line
        return line
    end
    return f
end
local mode, followsAtOnce = "outdoor", true                   -- which scale the minimap is on, and whether its settings update at once
Minimap = {
    GetZoom = function() return zoom end,
    SetZoom = function(_, z)
        zoom = z
        if followsAtOnce then cvars[mode == "indoor" and "minimapInsideZoom" or "minimapZoom"] = tostring(z) end
    end,
    GetWidth = function() return 140 end,
    GetFrameLevel = function() return 3 end,
}
CreateFrame = newFrame
UIParent = newFrame()
GetCVar = function(name) return cvars[name] end
GetPlayerFacing = function() return facing end
C_Map = {
    GetBestMapForUnit = function() return playerMap end,
    GetPlayerMapPosition = function() return { GetXY = function() return playerX, playerY end } end,
}
addon.Theme:Init("moderndark")

local function visible()
    local out = {}
    for _, line in ipairs(lines) do if line._shown then out[#out + 1] = line end end
    return out
end
local function extent()
    local minX, maxX, minY, maxY, farthest = 1e9, -1e9, 1e9, -1e9, 0
    for _, line in ipairs(visible()) do
        for _, p in ipairs({ { line._x1, line._y1 }, { line._x2, line._y2 } }) do
            minX, maxX = math.min(minX, p[1]), math.max(maxX, p[1])
            minY, maxY = math.min(minY, p[2]), math.max(maxY, p[2])
            farthest = math.max(farthest, math.sqrt(p[1] ^ 2 + p[2] ^ 2))
        end
    end
    return minX, maxX, minY, maxY, farthest
end

-- A route 170 yards due north of the player (0.1 of this map's height is 170 yards).
local function walk(fromY, toY)
    return { method = "walk", path = { { mapID = 1453, x = 0.5, y = fromY }, { mapID = 1453, x = 0.5, y = toY } } }
end
local plan = { steps = { walk(0.5, 0.4) } }

check(MinimapLines:IsAvailable(), "a client with a minimap and the map calls can draw on it")
local savedMinimap = Minimap
Minimap = nil
check(not MinimapLines:IsAvailable(), "and one without a minimap can't")
Minimap = savedMinimap

local across, indoors = MinimapLines:YardsAcross()
check(math.abs(across - 466 - 2 / 3) < 1e-6 and indoors == false, "at the furthest zoom outdoors the minimap spans 466 yards: " .. tostring(across))

-- Drawn round the player: 3.33 yards to the pixel on this zoom outdoors, so 170 yards is 51 pixels up.
MinimapLines:Follow(plan, 1)
check(#visible() > 5, "the route is drawn as dots: " .. #visible())
local minX, maxX, minY, maxY, farthest = extent()
check(math.abs(minX) < 1e-6 and math.abs(maxX) < 1e-6, "straight up from the player")
check(minY >= -0.01 and maxY > 45 and maxY <= 51.01, "as far as the route goes (51 pixels, the last dash ends a little short): " .. maxY)
check(farthest <= 67 + 1e-6, "never past the rim")

-- The dots stay put on the ground as the player walks: moving north brings the start behind them.
playerY = 0.45
MinimapLines:Update()
minX, maxX, minY, maxY = extent()
check(math.abs(minY + 25.5) < 0.5 and maxY > 21 and maxY <= 25.51, "walked half way: the route is half behind, half ahead: " .. minY .. " to " .. maxY)
playerY = 0.5

-- Turned with the player when the minimap rotates: facing east, north is on their left.
cvars.rotateMinimap, facing = "1", -math.pi / 2
MinimapLines:Update()
minX, maxX, minY, maxY = extent()
check(minX < -45 and minX >= -51.01 and math.abs(maxX) < 1e-3 and math.abs(minY) < 0.5 and math.abs(maxY) < 0.5,
    "facing east the route is about 50 pixels to the left: " .. minX)
cvars.rotateMinimap, facing = "0", 0

-- Clipped to the circle: a long route runs off the edge and stops at the rim.
local far = { steps = { walk(0.5, 0.0) } }
MinimapLines:Follow(far, 1)
minX, maxX, minY, maxY, farthest = extent()
check(#visible() > 5 and farthest <= 67 + 1e-6 and maxY > 60, "a route past the rim is cut at it: " .. maxY .. " from the centre")

-- The minimap's zoom sets the scale, and indoors it has its own scale.
MinimapLines:Follow(plan, 1)
zoom = 5
MinimapLines:Update()
minX, maxX, minY, maxY = extent()
check(math.abs(maxY - 170 / (133 + 1 / 3) * 140) < 0.5 or maxY > 66, "zoomed in, the same 170 yards is many more pixels (past the rim, so cut off): " .. maxY)
zoom, mode = 1, "indoor"                                 -- indoors: a zoom change moves the indoor setting
cvars.minimapZoom, cvars.minimapInsideZoom = "3", "1"
MinimapLines.state.frame._scripts.OnEvent()
check(MinimapLines.state.indoors == true and zoom == 1, "indoors is found by which setting follows the zoom, and the zoom is put back")
check(cvars.minimapZoom == "3" and cvars.minimapInsideZoom == "1", "with both settings as they were")
MinimapLines:Update()
minX, maxX, minY, maxY = extent()
check(maxY > 66, "on the indoor scale zoom 1 spans 240 yards, so 170 yards is 99 pixels: cut at the rim " .. maxY)
zoom, mode = 0, "outdoor"
cvars.minimapZoom, cvars.minimapInsideZoom = "0", "0"     -- both settings equal, as on the beta: the nudge can't reuse either value
MinimapLines.state.frame._scripts.OnEvent()
check(MinimapLines.state.indoors == false and zoom == 0, "outdoors is found the same way, even with both settings equal")
-- A client that only updates its settings later: neither setting follows, so the game's own answer decides.
followsAtOnce = false
IsIndoors = function() return true end
MinimapLines.state.frame._scripts.OnEvent()
check(MinimapLines.state.indoors == true, "when neither setting follows, IsIndoors() decides")
IsIndoors = function() return false end
MinimapLines.state.frame._scripts.OnEvent()
check(MinimapLines.state.indoors == false, "either way")
IsIndoors = nil
MinimapLines.state.frame._scripts.OnEvent()
check(MinimapLines.state.indoors == false, "and with no answer at all, outdoors")
followsAtOnce = true
MinimapLines:Update()

-- Steps already done fade.
local two = { steps = { walk(0.5, 0.45), walk(0.45, 0.4) } }
MinimapLines:Follow(two, 2)
local faded, solid = 0, 0
for _, line in ipairs(visible()) do
    if line._alpha < 1 then faded = faded + 1 else solid = solid + 1 end
end
check(faded > 0 and solid > 0, "the step done is faint, the step on is not: " .. faded .. " / " .. solid)

-- Only the trip being followed: nothing drawn for no plan, and stopping takes it down.
MinimapLines:Follow(nil)
check(#visible() == 0 and not MinimapLines.state.frame._shown, "no trip, no route")

-- The setting turns it off and on.
MinimapLines:Follow(plan, 1)
check(#visible() > 0, "drawn again for a new trip")
Options:Set("showRouteOnMinimap", false)
check(#visible() == 0, "switched off in the settings, it goes")
Options:Set("showRouteOnMinimap", true)
check(#visible() > 0, "and back on")

-- Off its map: a route on another map can't be placed round the player, and that is no error.
playerMap = 2
MinimapLines:Update()
check(#visible() == 0 and not MinimapLines.state.error, "nothing to draw when the player is on a map the route isn't on")
playerMap = 1453

-- Whatever goes wrong while drawing stays out of the minimap.
C_Map.GetPlayerMapPosition = function() error("no position") end
local ok = pcall(function() MinimapLines:Update() end)
check(ok and #visible() == 0 and MinimapLines.state.error, "an error is caught and leaves it undrawn: " .. tostring(MinimapLines.state.error))
MinimapLines:Follow(nil)

-- Finding 5: a map's scale is measured once; asking again (MinimapLines does, every 0.1 s) costs no distance at all.
do
    local provider = addon.TravelGraph.DistanceProvider
    local calls = 0
    addon.TravelGraph.DistanceProvider = function(a, b) calls = calls + 1; return provider(a, b) end
    local x1, y1 = addon.Navigation.YardsPerUnit(1453)
    local first = calls
    local x2, y2 = addon.Navigation.YardsPerUnit(1453)
    check(x1 and y1 and x1 == x2 and y1 == y2, "the same scale on two calls: " .. tostring(x1) .. ", " .. tostring(y1))
    check(first == 2 and calls == first, "the first call measures (2 distances), the second makes none: " .. first .. " then " .. calls)
    local x3 = addon.Navigation.YardsPerUnit(1454)
    check(x3 and calls == first + 2, "another map is measured on its own")
    addon.TravelGraph.DistanceProvider = provider
end
