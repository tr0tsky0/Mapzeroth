local addonName, addon = ...

-- Daylight: DaylightUI's look, offered only when DaylightUI is loaded. Panels wear its window shell (API.Skin); text,
-- accent and font are the player's DaylightUI choices, read again whenever they change. Everything is asked of
-- DaylightUI.API (its public calls, API.md); nothing of DaylightUI's own code is used or touched.

local API = DaylightUI and DaylightUI.API
if type(API) ~= "table" or API.major ~= 1 or type(API.Skin) ~= "function" then return end

local FLAT = "Interface\\Buttons\\WHITE8x8"

local function rgb(hex, alpha)
    local r, g, b = hex:match("(%x%x)(%x%x)(%x%x)")
    return { tonumber(r, 16) / 255, tonumber(g, 16) / 255, tonumber(b, 16) / 255, alpha or 1 }
end

local function copy(c, alpha)
    return { c[1], c[2], c[3], alpha or c[4] or 1 }
end

-- Our own font objects in DaylightUI's font, at its title, body and small sizes. Their face, outline and shadow are
-- copied from text API.Text makes, so they match whatever the player picked.
local FONTS = {
    title = { name = "MapzerothDaylightTitle", size = "title", fallback = 18 },
    body  = { name = "MapzerothDaylightBody",  size = "body",  fallback = 13 },
    small = { name = "MapzerothDaylightSmall", size = "small", fallback = 12 },
}
for _, f in pairs(FONTS) do
    f.object = CreateFont(f.name)
    f.object:SetFontObject(GameFontHighlight)
end

local sampler                                   -- a hidden frame holding one API.Text per size, made once
local function refreshFonts()
    if not sampler then
        sampler = CreateFrame("Frame", nil, UIParent)
        sampler:Hide()
    end
    local path = API.Font and API.Font()
    for _, f in pairs(FONTS) do
        f.sample = f.sample or API.Text(sampler, f.size)
        local face, height, flags = f.sample:GetFont()
        face = path or face
        if face then f.object:SetFont(face, height or f.fallback, flags or "") end
        local x, y = f.sample:GetShadowOffset()
        f.object:SetShadowOffset(x or 1, y or -1)
        local r, g, b, a = f.sample:GetShadowColor()
        f.object:SetShadowColor(r or 0, g or 0, b or 0, a or 1)
    end
end

-- DaylightUI gives text colours and an accent; the fills between (buttons, boxes, rows) are near-blacks under its
-- window background, so the accent and the text carry the look.
local function refresh(def)
    local ink = API.Colors()
    local ar, ag, ab = API.Accent()
    local accent = { ar, ag, ab, 1 }
    local c = def.colors
    c.accent = accent
    c.text, c.buttonText = copy(ink.TEXT), copy(ink.TEXT)
    c.dim = copy(ink.LABEL)
    c.good, c.warn = copy(ink.GOOD), copy(ink.WARN)
    -- The main button: a deep shade of the accent under white text. DaylightUI's fonts are outlined, and dark text on
    -- the bright accent itself turns to mush inside a black outline.
    local p = c.panel
    c.primaryBg = { ar * 0.55 + p[1] * 0.45, ag * 0.55 + p[2] * 0.45, ab * 0.55 + p[3] * 0.45, 1 }
    c.primaryText = copy(ink.VALUE)
    c.rowSelected = copy(accent, 0.18)
    c.rowHover = copy(ink.TEXT, 0.06)
    def.markers.place, def.markers.waypoint = accent, accent
    refreshFonts()
end

addon.Theme:Register("daylight", {
    label = "Daylight",
    preferred = true,                            -- the theme a new player starts on when DaylightUI is there
    colors = {
        panel = rgb("141417"), panelBorder = rgb("2a2a30"), header = rgb("1c1c21"),
        text = rgb("f2eee6"), dim = rgb("c2b59e"), accent = rgb("d4a64f"),
        good = rgb("8cd98c"), warn = rgb("f2b852"),
        buttonBg = rgb("1f1f25"), buttonHover = rgb("2a2a31"), buttonPressed = rgb("17171b"),
        buttonText = rgb("f2eee6"), primaryBg = rgb("7c6332"), primaryText = rgb("ffffff"),
        editBg = rgb("0e0e11"), editBorder = rgb("2a2a30"),
        rowHover = rgb("f2eee6", 0.06), rowSelected = rgb("d4a64f", 0.18), divider = rgb("2a2a30"),
    },
    fonts = { title = FONTS.title.name, body = FONTS.body.name, small = FONTS.small.name },
    stopBadges = true,
    methodTimes = true,
    panel = { backdrop = { bgFile = FLAT, edgeFile = FLAT, edgeSize = 1,
                           insets = { left = 1, right = 1, top = 1, bottom = 1 } } },
    shell = function(holder, opts)
        -- A dropdown's list stays solid over what it covers; windows follow the player's window opacity.
        API.Skin(holder, { window = not (opts and opts.menu) })
    end,
    refresh = refresh,
    button = "flat",
    edit = { backdrop = { bgFile = FLAT, edgeFile = FLAT, edgeSize = 1,
                          insets = { left = 1, right = 1, top = 1, bottom = 1 } } },
    styles = {
        foot = rgb("f2eee6"), flight = rgb("63b7a4"), boat = rgb("6fa3e0"), ability = rgb("b38cf0"),
        default = rgb("c2b59e"),
    },
    map = {                                      -- Modern Dark's: tuned for the parchment map, not the panel
        foot = rgb("f4f1ea"), flight = rgb("4fd8c0"), boat = rgb("5aa0ff"), ability = rgb("c070ff"),
        casing = rgb("141417", 0.85), stop = rgb("f4f1ea"), dest = rgb("e5533f"),
    },
    stepIcon = { size = 18, crop = 0.1 },
    markers = {
        place = rgb("d4a64f"), flight = rgb("63b7a4"), transport = rgb("63b7a4"), instance = rgb("c0554d"),
        leyline = rgb("8f7bd4"), convergence = rgb("d47f5a"), waypoint = rgb("d4a64f"), default = rgb("c2b59e"),
    },
})

-- The player changed DaylightUI's font, accent or another look setting (or it finished loading): re-skin, if ours is on.
if type(API.On) == "function" then
    local function follow()
        local current = addon.Theme:Current()
        if current and current.id == "daylight" then addon.Theme:Refresh() end
    end
    API.On("StyleChanged", follow, addonName)
    API.On("Login", follow, addonName)
end
