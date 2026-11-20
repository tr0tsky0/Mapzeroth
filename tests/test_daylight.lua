-- The Daylight theme, with a stand-in for DaylightUI.API: it registers only when DaylightUI is there, starts as the
-- theme of a player who never picked one, takes its colours and font from the API (again when they change), and puts
-- DaylightUI's shell on panels, hidden again under any other theme.

local function mock()
    local obj = { _shown = true, _scripts = {} }
    return setmetatable(obj, { __index = function(_, key)
        if key:sub(1, 1) == "_" or key:sub(1, 2) == "mz" then return nil end
        local special = {
            Show = function(self) self._shown = true end,
            Hide = function(self) self._shown = false end,
            IsShown = function(self) return self._shown end,
            SetScript = function(self, name, fn) self._scripts[name] = fn end,
            GetFrameLevel = function() return 5 end,
            SetBackdrop = function(self, b) self._backdrop = b end,
            CreateTexture = function() return mock() end,
            CreateFontString = function() return mock() end,
            SetFont = function(self, face, size, flags) self._face, self._size, self._flags = face, size, flags end,
        }
        return special[key] or function() end
    end })
end
CreateFrame = function() return mock() end
CreateFont = function(name) local f = mock(); _G[name] = f; return f end

local Theme = addon.Theme
check(not (function() for _, id in ipairs(Theme:List()) do if id == "daylight" then return true end end end)(),
      "without DaylightUI there is no Daylight theme")

-- The stand-in API: what API.md promises, recording what we ask of it.
local accent = { 0.2, 0.6, 0.9 }
local skins, handlers, glowing = {}, {}, {}
local function textSample()
    local fs = mock()
    fs.GetFont = function() return "Fonts\\Sample.ttf", 13, "OUTLINE" end
    fs.GetShadowOffset = function() return 1, -1 end
    fs.GetShadowColor = function() return 0, 0, 0, 1 end
    return fs
end
DaylightUI = { API = {
    major = 1, minor = 1,
    Skin = function(frame, opts) skins[#skins + 1] = { frame = frame, opts = opts } end,
    Text = function() return textSample() end,
    Colors = function()
        return { TEXT = { 0.9, 0.9, 0.8 }, VALUE = { 1, 1, 1 }, LABEL = { 0.7, 0.6, 0.5 }, OFF = { 0.5, 0.5, 0.4 },
                 GOOD = { 0.5, 0.8, 0.5 }, WARN = { 0.9, 0.7, 0.3 }, BAD = { 0.9, 0.3, 0.3 } }
    end,
    Accent = function() return accent[1], accent[2], accent[3] end,
    Font = function() return "Fonts\\Daylight.ttf" end,
    On = function(event, fn, name) handlers[event] = fn; return #handlers end,
    GlowAround = function(frame, on) glowing[frame] = on ~= false or nil; return true end,
} }
local timers = {}
C_Timer = { After = function(_, fn) timers[#timers + 1] = fn end }

local f = assert(io.open(ADDON_ROOT .. "/UI/Themes/Daylight.lua", "r"))
local src = f:read("*a")
f:close()
assert(loadstring(src, "Daylight.lua"))("Mapzeroth-Dev", addon)

local found = false
for _, id in ipairs(Theme:List()) do found = found or id == "daylight" end
check(found, "with DaylightUI the Daylight theme is offered")
check(handlers.StyleChanged and handlers.Login, "it follows DaylightUI's StyleChanged and Login")

-- A player who never picked a theme starts on Daylight.
MapzerothRebuildDB = {}
Theme:Init("moderndark")
check(Theme:Current().id == "daylight", "Daylight is the first theme when DaylightUI is there: " .. Theme:Current().id)
local r, g, b = Theme:Color("accent")
check(r == 0.2 and g == 0.6 and b == 0.9, "the accent is DaylightUI's")
check(select(1, Theme:Color("dim")) == 0.7, "labels are DaylightUI's LABEL colour")
local pr, pg, pb = Theme:Color("primaryBg")
local tr, tg, tb = Theme:Color("primaryText")
check(pr < 0.2 and pb < 0.6 and tr == 1 and tg == 1 and tb == 1, "the main button is a deep accent under white text")
check(_G.MapzerothDaylightBody._face == "Fonts\\Daylight.ttf" and _G.MapzerothDaylightBody._flags == "OUTLINE",
      "the body font is DaylightUI's, with its outline")

-- Panels wear the shell on a holder of ours; a dropdown's list is solid.
local panel = Theme:Panel(nil, nil)
local holder = panel.mzShell
check(holder and holder:IsShown(), "a panel gets a shell holder")
check(skins[#skins].frame == holder and skins[#skins].opts.window == true, "the holder is skinned as a window")
check(panel._backdrop == nil, "and the panel has no backdrop of its own")
Theme:Panel(nil, nil, { menu = true })
check(skins[#skins].opts.window == false, "a dropdown's list isn't see-through")
local before = #skins
holder._scripts.OnSizeChanged(holder)
check(#skins == before + 1, "a resized panel is skinned again")

-- The player changes DaylightUI's accent: we re-skin.
accent = { 0.9, 0.3, 0.6 }
handlers.StyleChanged()
r = Theme:Color("accent")
check(r == 0.9, "a new DaylightUI accent is picked up")

-- The step being followed on the map takes the accent, lifted when it is too dark to read over the route's casing.
local cr, cg, cb = Theme:CurrentStepColor()
local function light(a, b2, c) return 0.299 * a + 0.587 * b2 + 0.114 * c end
check(cr and light(cr, cg, cb) >= 0.6 - 1e-9, "the current step's colour is bright enough: " .. tostring(cr))
local bright = Theme.Legible(1, 0.9, 0.2)
check(bright[1] == 1 and bright[2] == 0.9 and bright[3] == 0.2, "a bright accent is used as it is")
local navy = Theme.Legible(0.1, 0.15, 0.5)
check(math.abs(light(navy[1], navy[2], navy[3]) - 0.6) < 1e-9 and navy[3] > navy[1], "a navy accent is lifted, still blue")

-- Another theme hides the shell and puts the backdrop back; the next DaylightUI change leaves it alone.
Theme:Set("moderndark")
check(not holder:IsShown() and panel._backdrop ~= nil, "Modern Dark hides the shell and has its backdrop")
before = #skins
handlers.StyleChanged()
check(#skins == before and Theme:Current().id == "moderndark", "DaylightUI changes don't touch another theme")
Theme:Set("daylight")
check(holder:IsShown(), "back on Daylight the shell shows again")

-- Main buttons glow under Daylight while enabled; plain ones never; another theme puts the light out.
local main = Theme:Button(nil, "Go", 80, 22, true)
local plain = Theme:Button(nil, "Back", 80, 22)
local use = Theme:ActionButton(nil, 200, 30)
check(glowing[main] and glowing[use], "the main button and the navigator's action button glow")
check(not glowing[plain], "an ordinary button doesn't")
main:Disable()
check(not glowing[main], "a disabled main button goes dark")
main:Enable()
check(glowing[main], "and lights again when enabled")
Theme:Set("moderndark")
check(not glowing[main] and not glowing[use], "Modern Dark puts the lights out")
main:Disable(); main:Enable()
check(not glowing[main], "and keeps them out")
Theme:Set("daylight")
check(glowing[main], "back on Daylight they light again")

-- A pulse lights a frame for a moment; a second one on the same frame outlasts the first's timer.
local row = CreateFrame()
Theme:Pulse(row)
check(glowing[row] and #timers == 1, "a pulse lights the frame and sets a timer")
Theme:Pulse(row)
timers[1]()
check(glowing[row], "the first pulse's timer leaves the second's light on")
timers[2]()
check(not glowing[row], "the last timer puts it out")
Theme:Set("moderndark")
Theme:Pulse(row)
check(not glowing[row] and #timers == 2, "other themes don't pulse")
Theme:Set("daylight")

-- A saved choice wins over Daylight.
MapzerothRebuildDB.settings.theme = "classic"
Theme:Init("moderndark")
check(Theme:Current().id == "classic", "a theme the player picked stays picked")

-- Modern Dark saved by an older version at a login (it saved whatever it fell back to, as if picked): DaylightUI
-- installed since still gets Daylight. Picked from the settings, Modern Dark stays.
MapzerothRebuildDB = { settings = { theme = "moderndark" } }
Theme:Init("moderndark")
check(Theme:Current().id == "daylight", "an unpicked Modern Dark doesn't keep Daylight away: " .. Theme:Current().id)
check(MapzerothRebuildDB.settings.theme == "moderndark", "and login saves nothing")
check(Theme:Set("moderndark") and MapzerothRebuildDB.settings.themePicked == true, "picking Modern Dark marks it picked")
Theme:Init("moderndark")
check(Theme:Current().id == "moderndark", "then it stays, DaylightUI or not")

-- A login without the picked theme loaded (here a stand-in for Daylight with DaylightUI off, or missing after an
-- update until a restart) wears another one for now but keeps the choice: it is back at the next login that has it.
MapzerothRebuildDB = { settings = { theme = "laterlook", themePicked = true } }
Theme:Init("moderndark")
check(Theme:Current().id == "daylight", "the picked theme isn't loaded: the preferred one for now")
check(MapzerothRebuildDB.settings.theme == "laterlook", "the choice is kept: " .. tostring(MapzerothRebuildDB.settings.theme))
local later = {}
for k, v in pairs(Theme:Current()) do later[k] = v end
Theme:Register("laterlook", later)
Theme:Init("moderndark")
check(Theme:Current().id == "laterlook", "loaded again: it's worn again")
