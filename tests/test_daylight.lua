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
local skins, handlers = {}, {}
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
} }

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

-- Another theme hides the shell and puts the backdrop back; the next DaylightUI change leaves it alone.
Theme:Set("moderndark")
check(not holder:IsShown() and panel._backdrop ~= nil, "Modern Dark hides the shell and has its backdrop")
before = #skins
handlers.StyleChanged()
check(#skins == before and Theme:Current().id == "moderndark", "DaylightUI changes don't touch another theme")
Theme:Set("daylight")
check(holder:IsShown(), "back on Daylight the shell shows again")

-- A saved choice wins over Daylight.
MapzerothRebuildDB.settings.theme = "classic"
Theme:Init("moderndark")
check(Theme:Current().id == "classic", "a theme the player picked stays picked")
