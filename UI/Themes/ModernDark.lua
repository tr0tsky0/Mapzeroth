local addonName, addon = ...

-- Modern Dark: flat slate panels, a brass accent, teal for boats and flights. The palette
-- comes from the design mock-ups (docs/ui): ink #14181e, edge #2b333d, cream #ece6d6,
-- brass #d4a64f, verdigris #63b7a4.

local function rgb(hex, alpha)
    local r, g, b = hex:match("(%x%x)(%x%x)(%x%x)")
    return { tonumber(r, 16) / 255, tonumber(g, 16) / 255, tonumber(b, 16) / 255, alpha or 1 }
end

local FLAT = "Interface\\Buttons\\WHITE8x8"

addon.Theme:Register("moderndark", {
    label = "Modern Dark",
    colors = {
        panel = rgb("14181e"), panelBorder = rgb("2b333d"), header = rgb("1b2027"),
        text = rgb("ece6d6"), dim = rgb("a8a191"), accent = rgb("d4a64f"),
        good = rgb("63b7a4"), warn = rgb("e6a35a"),
        buttonBg = rgb("232a33"), buttonHover = rgb("2b333d"), buttonPressed = rgb("1b2027"),
        buttonText = rgb("ece6d6"), primaryBg = rgb("d4a64f"), primaryText = rgb("14181e"),
        editBg = rgb("0f1319"), editBorder = rgb("2b333d"),
        rowHover = rgb("ece6d6", 0.06), rowSelected = rgb("d4a64f", 0.16), divider = rgb("2b333d"),
    },
    fonts = { title = "GameFontNormalLarge", body = "GameFontHighlight", small = "GameFontHighlightSmall" },
    panel = { backdrop = { bgFile = FLAT, edgeFile = FLAT, edgeSize = 1,
                           insets = { left = 1, right = 1, top = 1, bottom = 1 } } },
    button = "flat",
    edit = { backdrop = { bgFile = FLAT, edgeFile = FLAT, edgeSize = 1,
                          insets = { left = 1, right = 1, top = 1, bottom = 1 } } },
    methods = {
        walk = rgb("ece6d6"), taxi = rgb("63b7a4"), ship = rgb("63b7a4"), zeppelin = rgb("63b7a4"),
        tram = rgb("63b7a4"), portal = rgb("d4a64f"), teleport = rgb("d4a64f"), equip = rgb("d4a64f"),
        hearthstone = rgb("d4a64f"), default = rgb("a8a191"),
    },
    markers = {
        place = rgb("d4a64f"), flight = rgb("63b7a4"), transport = rgb("63b7a4"), instance = rgb("c0554d"),
        leyline = rgb("8f7bd4"), waypoint = rgb("d4a64f"), default = rgb("a8a191"),
    },
})
