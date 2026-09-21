local addonName, addon = ...

-- Classic: the game's own frames and buttons. A dialog-box panel, the red panel buttons,
-- tooltip-style edit boxes, and Blizzard's gold and white text.

local function c(r, g, b, a) return { r, g, b, a or 1 } end

-- The quest log's dark page (QuestScrollFrame.Background, found with /fstack), read from the
-- game so it is always what the game itself draws. Nil until the map has loaded.
local function questLogBackground()
    local background = QuestScrollFrame and QuestScrollFrame.Background
    if not background then return nil end
    local atlas = background.GetAtlas and background:GetAtlas()
    if atlas then return { atlas = atlas } end
    local file = background.GetTexture and background:GetTexture()
    if file then
        local left, right, top, bottom = background:GetTexCoord()
        return { file = file, coords = left and { left, right, top, bottom } or nil }
    end
end

addon.Theme:Register("classic", {
    label = "Classic",
    colors = {
        panel = c(1, 1, 1, 1), panelBorder = c(1, 1, 1, 1), header = c(0, 0, 0, 0),
        text = c(1, 1, 1), dim = c(0.62, 0.62, 0.62), accent = c(1, 0.82, 0),
        good = c(0.3, 0.9, 0.4), warn = c(1, 0.6, 0.2),
        buttonBg = c(1, 1, 1), buttonHover = c(1, 1, 1), buttonPressed = c(1, 1, 1),
        buttonText = c(1, 0.82, 0), primaryBg = c(1, 1, 1), primaryText = c(1, 0.82, 0),
        editBg = c(0, 0, 0, 0.6), editBorder = c(0.75, 0.75, 0.75),
        rowHover = c(1, 0.82, 0, 0.12), rowSelected = c(1, 0.82, 0, 0.25), divider = c(0.4, 0.4, 0.4),
    },
    fonts = { title = "GameFontNormalLarge", body = "GameFontHighlight", small = "GameFontHighlightSmall" },
    -- The dialog texture alone lets the world show through, which makes text hard to read.
    panelFill = c(0.07, 0.055, 0.045, 1),
    panelTexture = questLogBackground,
    panel = { backdrop = {
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    } },
    button = "blizzard",
    edit = { backdrop = {
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    } },
    methods = {
        walk = c(0.9, 0.9, 0.9), flight = c(0.4, 0.75, 1), ship = c(0.4, 0.75, 1), zeppelin = c(0.4, 0.75, 1),
        tram = c(0.4, 0.75, 1), portal = c(1, 0.82, 0), teleport = c(1, 0.82, 0),
        hearthstone = c(1, 0.82, 0), default = c(0.62, 0.62, 0.62),
    },
    markers = {
        place = c(1, 0.82, 0), flight = c(0.4, 0.75, 1), transport = c(0.4, 0.75, 1), instance = c(0.9, 0.3, 0.3),
        leyline = c(0.7, 0.5, 1), default = c(0.62, 0.62, 0.62),
    },
})
