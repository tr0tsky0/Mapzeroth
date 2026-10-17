local addonName, addon = ...

-- The one place styling lives. The panel never sets a colour, texture, backdrop or font of
-- its own: it asks the theme for a widget ("panel", "button", "edit", "area", "row", "text", ...)
-- and the theme skins it. Every widget made this way is remembered, so switching theme
-- re-skins what is already on screen.
--
-- A theme is a table registered with Theme:Register(id, def):
--   label        shown to the player
--   colors       named {r, g, b, a}: panel, panelBorder, header, text, dim, accent, good, warn,
--                buttonBg, buttonHover, buttonPressed, buttonText, primaryBg, primaryText,
--                editBg, editBorder, rowHover, rowSelected, divider
--   fonts        font object names: title, body, small
--   panel        { backdrop = <SetBackdrop table> }
--   button       "flat" (a coloured backdrop) or "blizzard" (the classic red button textures)
--   edit         { backdrop = <SetBackdrop table> }
--   styles       colours by route style (foot, flight, boat, ability; addon.METHODS gives each method its style)
--   map          (optional) colours for the route drawn on the world map and minimap: foot, flight, boat, ability
--                (the route styles), casing (the dark edge under every line and marker, so it shows on any map
--                art), stop (a tour's stops), dest (the end). The map is pale parchment and sepia whatever the
--                theme, so these are brighter than the panel's styles; a colour left out falls back to styles.
--   markers      colours by kind of place (place, flight, transport, instance, ...)
--   icons        (optional) pictures for route steps by method, each a list of texture paths, the first the client
--                has winning; a method it leaves out uses STEP_ICONS below
--   stepIcon     (optional) { size = pixels, crop = fraction trimmed off each edge (an icon's own frame) }
--   buttonIcons  (optional) pictures for icon buttons by name (edit, ...); one it leaves out uses BUTTON_ICONS below
-- Files under UI/Themes/ hold the themes we ship. Adding one is adding a file and a TOC line.

local Theme = {}
addon.Theme = Theme

local themes, order = {}, {}
local current
local widgets = setmetatable({}, { __mode = "k" })    -- widget -> { role, opts }
local skin = {}                                       -- role -> function(widget, opts)

local BLIZZARD_BUTTON = "Interface\\Buttons\\UI-Panel-Button-"
local FLAT = "Interface\\Buttons\\WHITE8x8"
-- Our own arrow pointing up (tools/gen_media.py): white and a paler grey half, on a dark edge, tinted with the accent.
-- Drawn large and scaled down, so it stays crisp at any size.
local ARROW = "Interface\\AddOns\\" .. addonName .. "\\Media\\Arrow"
-- Buttons in another brand's colours, the same in every theme (Theme:BrandButton): its fill, its fill under the mouse,
-- and its logo (white, Media/, from tools/gen_media.py). The text and logo are white.
local BRANDS = {
    discord = { fill = { 0.345, 0.396, 0.949 }, hover = { 0.278, 0.322, 0.769 },      -- Discord's blurple, #5865F2
                logo = "Interface\\AddOns\\" .. addonName .. "\\Media\\Discord" },
}

-- The picture beside a route step when the player shows icons instead of colour chips (the stepMarkers setting).
-- Each is a list of candidates, the first the client has winning: the classic clients lack some later art, so the
-- last of each list is an icon that has been in the game since launch. A step that uses a spell or an item
-- (a hearthstone, a teleport) shows that spell's or item's own icon before any of these.
local ICONS = "Interface\\Icons\\"
-- The pictures on icon buttons (Theme:IconButton), unless a theme has its own (buttonIcons).
local BUTTON_ICONS = {
    edit = "Interface\\Buttons\\UI-GuildButton-PublicNote-Up",       -- the game's own "edit a note" pen
    reroute = "Interface\\Buttons\\UI-RefreshButton",                -- the game's own circling arrow (group finder's refresh)
}
local STEP_ICONS = {
    walk        = { ICONS .. "Ability_Rogue_Sprint" },
    taxi        = { "Interface\\Minimap\\Tracking\\FlightMaster", ICONS .. "Spell_Nature_RavenForm" },   -- the flight master's winged boot
    fly         = { ICONS .. "Ability_Mount_Gryphon_01", ICONS .. "Spell_Nature_RavenForm" },
    ship        = { ICONS .. "INV_Misc_Anchor", ICONS .. "Spell_Frost_WindWalkOn" },
    zeppelin    = { ICONS .. "INV_Misc_Zeppelin", ICONS .. "INV_Misc_Anchor", ICONS .. "Spell_Frost_WindWalkOn" },
    tram        = { ICONS .. "INV_Gizmo_02", ICONS .. "INV_Misc_Gear_01" },
    hearthstone = { ICONS .. "INV_Misc_Rune_01" },
    teleport    = { ICONS .. "Spell_Arcane_TeleportStormWind" },
    portal      = { ICONS .. "Spell_Arcane_PortalStormWind" },
    equip       = { ICONS .. "INV_Misc_Bag_08", ICONS .. "Spell_Arcane_TeleportStormWind" },
}
STEP_ICONS.transition, STEP_ICONS.phaseswitch = STEP_ICONS.walk, STEP_ICONS.walk
-- Flying yourself: the Horde flies wyverns, not gryphons.
local HORDE_ICONS = {
    fly = { ICONS .. "Ability_Mount_Wyvern_01", ICONS .. "Spell_Nature_RavenForm" },
}

function Theme:Register(id, def)
    def.id = id
    if not themes[id] then order[#order + 1] = id end
    themes[id] = def
end

function Theme:Current() return current end
-- Whether the current theme turns on a layout choice: stopBadges (a tour's stops numbered in a disc, their steps
-- set in under them), methodTimes (step times in the colour of how the step travels).
function Theme:Has(flag) return current ~= nil and current[flag] == true end
function Theme:List() return order end
function Theme:Label(id) return themes[id] and themes[id].label or id end

-- r, g, b, a for a named colour of the current theme (white if the theme lacks it).
function Theme:Color(name)
    local c = current and current.colors[name]
    if not c then return 1, 1, 1, 1 end
    return c[1], c[2], c[3], c[4] or 1
end

function Theme:StyleColor(style)
    local c = current and current.styles and (current.styles[style] or current.styles.default)
    if not c then return self:Color("text") end
    return c[1], c[2], c[3], c[4] or 1
end

-- A holiday route's own look on the map, over whichever theme is on (a theme's `holidayMap[key]` wins): only the
-- colours named here change; teleports keep the theme's. Hallow's End: pumpkin orange on near-black, the last stop green.
local HOLIDAY_MAP = {
    hallows_end = {
        foot = { 0.96, 0.52, 0.13 }, flight = { 1, 0.68, 0.25 }, boat = { 0.85, 0.40, 0.08 },
        stop = { 1, 0.55, 0.10 }, dest = { 0.55, 0.85, 0.25 }, casing = { 0.03, 0.02, 0.02, 0.92 },
    },
}

-- A colour for the route on the map (see `map` above); `holiday` (an addon.HOLIDAYS key) for a holiday route's look.
function Theme:MapColor(name, holiday)
    local look = holiday and (current and current.holidayMap and current.holidayMap[holiday] or HOLIDAY_MAP[holiday])
    local c = look and look[name] or current and current.map and current.map[name]
    if c then return c[1], c[2], c[3], c[4] or 1 end
    if name == "casing" then return 0.05, 0.04, 0.03, 0.85 end
    if name == "dest" then return self:Color("accent") end
    if name == "stop" then return 1, 1, 1, 1 end
    return self:StyleColor(name)
end

function Theme:MethodColor(method)
    return self:StyleColor(addon:Method(method).style)
end

function Theme:MarkerColor(group)
    local c = current and current.markers and (current.markers[group] or current.markers.default)
    if not c then return self:Color("accent") end
    return c[1], c[2], c[3], c[4] or 1
end

-- Whether the client has a texture file. An old client without the lookup: assume it does.
local function hasFile(path)
    if not GetFileIDFromPath then return true end
    return GetFileIDFromPath(path) ~= nil
end

local resolved = {}         -- "theme:method" -> the first candidate the client has (false: none of them)

-- The icon of the spell or item a step uses, if the client knows it.
local function sourceIcon(source)
    if type(source) ~= "table" then return nil end
    if source.itemID then
        local icon = C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(source.itemID)
        if not icon and GetItemIcon then icon = GetItemIcon(source.itemID) end
        if icon then return icon end
    end
    if source.spellID then
        local icon = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(source.spellID)
        if not icon and GetSpellTexture then icon = GetSpellTexture(source.spellID) end
        if icon then return icon end
    end
end

-- The picture for a route step: its spell's or item's own icon, else the theme's (or the default) for its method.
-- Nil when the client has none of them; the row then keeps its colour chip.
function Theme:StepIcon(method, source)
    local icon = sourceIcon(source)
    if icon then return icon end
    method = method or "walk"
    local horde = UnitFactionGroup and UnitFactionGroup("player") == "Horde"
    local key = (current and current.id or "") .. ":" .. method .. (horde and ":horde" or "")
    if resolved[key] == nil then
        local list = current and current.icons and current.icons[method]
            or horde and HORDE_ICONS[method] or STEP_ICONS[method] or STEP_ICONS.walk
        resolved[key] = false
        for _, path in ipairs(list) do
            if hasFile(path) then
                resolved[key] = path
                break
            end
        end
    end
    return resolved[key] or nil
end

-- Whether route steps show icons (the stepMarkers setting) rather than colour chips.
function Theme:StepIconsOn()
    return addon.Options:Get("stepMarkers") == "icon"
end

local function fontObject(name)
    return _G[name] or GameFontNormal
end

-- A label must have a font before it is given any text, or the client refuses; the theme's
-- own font replaces this one when it skins the label.
local function withFont(fs)
    fs:SetFontObject(fontObject(current and current.fonts.body or "GameFontNormal"))
    return fs
end

-- ---------------------------------------------------------------------------------------
-- Skinning: one function per role, each reading the current theme.

skin.panel = function(frame)
    local def = current.panel
    frame:SetBackdrop(def.backdrop)
    frame:SetBackdropColor(Theme:Color("panel"))
    frame:SetBackdropBorderColor(Theme:Color("panelBorder"))

    -- A solid background under the backdrop, for themes whose own texture is see-through:
    -- the texture the theme can read from the game (panelTexture), else a plain colour.
    if not frame.mzFill then
        frame.mzFill = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
    end
    local fill, texture = current.panelFill, current.panelTexture and current.panelTexture()
    if fill or texture then
        local inset = def.backdrop.insets or { left = 0, right = 0, top = 0, bottom = 0 }
        frame.mzFill:ClearAllPoints()
        frame.mzFill:SetPoint("TOPLEFT", inset.left, -inset.top)
        frame.mzFill:SetPoint("BOTTOMRIGHT", -inset.right, inset.bottom)
        if texture and texture.atlas then
            frame.mzFill:SetTexCoord(0, 1, 0, 1)
            frame.mzFill:SetAtlas(texture.atlas)
        elseif texture and texture.file then
            frame.mzFill:SetTexture(texture.file)
            frame.mzFill:SetTexCoord(unpack(texture.coords or { 0, 1, 0, 1 }))
        else
            frame.mzFill:SetTexCoord(0, 1, 0, 1)
            frame.mzFill:SetColorTexture(fill[1], fill[2], fill[3], fill[4] or 1)
        end
        frame.mzFill:Show()
    else
        frame.mzFill:Hide()
    end
end

skin.arrow = function(arrow)
    arrow:SetTexture(current.arrow or ARROW, "CLAMP", "CLAMP", "TRILINEAR")
    local crop = current.arrow and current.arrowCrop or 0
    arrow:SetTexCoord(crop, 1 - crop, crop, 1 - crop)
    arrow:SetVertexColor(Theme:Color("accent"))
end

-- The round button on the minimap: the game's own ring, tinted with the theme's accent, over a disc in the panel colour.
skin.minimap = function(button)
    button.disc:SetVertexColor(Theme:Color("panel"))
    button.ring:SetVertexColor(Theme:Color("accent"))
end

skin.slider = function(slider)
    slider.track:SetColorTexture(Theme:Color("editBg"))
    slider.thumb:SetColorTexture(Theme:Color("accent"))
end

skin.bar = function(bar)
    bar:SetStatusBarColor(Theme:Color("accent"))
    bar.bg:SetColorTexture(Theme:Color("editBg"))
end

-- The colour each text style is drawn in. "time" is a route step's time: the accent, or with the theme's
-- `methodTimes` the colour of how the step travels (fs.mzMethod), so the list matches the lines on the map.
local TEXT_COLORS = { title = "accent", body = "text", small = "dim", dim = "dim", accent = "accent",
                      good = "good", warn = "warn", button = "buttonText", primary = "primaryText", time = "accent" }

-- The game's fonts carry a dark drop shadow, which blurs dark text on a light ground: a theme with `noShadow`, and dark
-- text on a primary (light) button, go without it; everything else keeps its font's own.
local function setShadow(fs, off)
    if not fs.SetShadowOffset then return end
    local object = fs.GetFontObject and fs:GetFontObject()
    if off then
        fs:SetShadowOffset(0, 0)
    elseif object and object.GetShadowOffset then
        fs:SetShadowOffset(object:GetShadowOffset())
    end
end

skin.text = function(fs, opts)
    local style = opts.style
    local font = (style == "title" and current.fonts.title) or (style == "small" and current.fonts.small)
        or current.fonts.body
    fs:SetFontObject(fontObject(font))
    fs:SetTextColor(Theme:Color(TEXT_COLORS[style] or "text"))
    if style == "time" and current.methodTimes and fs.mzMethod then
        local methodStyle = addon:Method(fs.mzMethod).style
        if methodStyle == "foot" then fs:SetTextColor(Theme:Color("dim")) else fs:SetTextColor(Theme:StyleColor(methodStyle)) end
    end
    setShadow(fs, current.noShadow or (style == "primary" and current.button ~= "blizzard"))
end

skin.taximark = function(mark)
    mark.ring:SetVertexColor(Theme:MapColor("dest"))
    mark.edge:SetVertexColor(Theme:MapColor("casing"))
end

-- A tour stop's number in a disc of the primary button's colours.
skin.badge = function(badge)
    badge.disc:SetVertexColor(Theme:Color("primaryBg"))
    badge.number:SetFontObject(fontObject(current.fonts.small))
    badge.number:SetTextColor(Theme:Color("primaryText"))
    setShadow(badge.number, true)
end

-- How a route's time splits between ways of travelling: a part per route style, in the style's colour.
skin.split = function(bar)
    bar.bg:SetColorTexture(Theme:Color("editBg"))
    for i, part in ipairs(bar.parts) do
        if bar.styles[i] then part:SetColorTexture(Theme:StyleColor(bar.styles[i])) end
    end
end

local BUTTON_SLOTS = {
    { "SetNormalTexture", "GetNormalTexture", "Up" },
    { "SetPushedTexture", "GetPushedTexture", "Down" },
    { "SetHighlightTexture", "GetHighlightTexture", "Highlight" },
}

skin.button = function(button, opts)
    local state = button.mzState or "normal"
    -- The client won't clear a button texture (it wants an asset), so a flat button just hides
    -- whichever of the three exist, and a Blizzard one sets them and shows them.
    if current.button == "blizzard" then
        button:SetBackdrop(nil)
        for _, slot in ipairs(BUTTON_SLOTS) do
            button[slot[1]](button, BLIZZARD_BUTTON .. slot[3])
            local texture = button[slot[2]](button)
            if texture then
                texture:SetTexCoord(0, 0.625, 0, 0.6875)
                texture:SetAlpha(1)
            end
        end
        skin.text(button.label, { style = "button" })
    else
        for _, slot in ipairs(BUTTON_SLOTS) do
            local texture = button[slot[2]](button)
            if texture then texture:SetAlpha(0) end
        end
        button:SetBackdrop({ bgFile = FLAT, edgeFile = FLAT, edgeSize = 1,
                             insets = { left = 1, right = 1, top = 1, bottom = 1 } })
        local bg = opts.primary and "primaryBg" or "buttonBg"
        if state == "hover" then bg = opts.primary and "primaryBg" or "buttonHover" end
        if state == "pressed" then bg = "buttonPressed" end
        button:SetBackdropColor(Theme:Color(bg))
        -- An action button (the navigator's "use this") is an ordinary one edged in the accent: it says "do this"
        -- without dark text on a bright fill.
        button:SetBackdropBorderColor(Theme:Color(opts.primary and "primaryBg" or opts.action and "accent" or "panelBorder"))
        skin.text(button.label, { style = opts.primary and "primary" or "button" })
    end
end

skin.brandbutton = function(button, opts)
    local brand = BRANDS[opts.brand]
    button:SetBackdrop({ bgFile = FLAT, edgeFile = FLAT, edgeSize = 1, insets = { left = 1, right = 1, top = 1, bottom = 1 } })
    local fill = button.mzHover and brand.hover or brand.fill
    button:SetBackdropColor(fill[1], fill[2], fill[3], 1)
    button:SetBackdropBorderColor(fill[1], fill[2], fill[3], 1)
    button.label:SetFontObject(fontObject(current.fonts.body))
    button.label:SetTextColor(1, 1, 1)
end

-- An icon button: in a flat theme a small button of the theme's colours round the picture; in the Blizzard one just
-- the picture, brighter under the mouse.
skin.iconbutton = function(button, opts)
    button.icon:SetTexture((current.buttonIcons or {})[opts.icon] or BUTTON_ICONS[opts.icon])
    if current.button == "blizzard" then
        button:SetBackdrop(nil)
        button.icon:SetAlpha(button.mzHover and 1 or 0.75)
    else
        button:SetBackdrop({ bgFile = FLAT, edgeFile = FLAT, edgeSize = 1,
                             insets = { left = 1, right = 1, top = 1, bottom = 1 } })
        button:SetBackdropColor(Theme:Color(button.mzHover and "buttonHover" or "buttonBg"))
        button:SetBackdropBorderColor(Theme:Color("panelBorder"))
        button.icon:SetAlpha(1)
    end
end

skin.edit = function(edit)
    edit:SetBackdrop(current.edit.backdrop)
    edit:SetBackdropColor(Theme:Color("editBg"))
    edit:SetBackdropBorderColor(Theme:Color("editBorder"))
    edit:SetFontObject(fontObject(current.fonts.body))
    edit:SetTextColor(Theme:Color("text"))
end

-- A text area: the border is an edit box's, and so are the text's font and colour.
skin.area = function(area)
    area:SetBackdrop(current.edit.backdrop)
    area:SetBackdropColor(Theme:Color("editBg"))
    area:SetBackdropBorderColor(Theme:Color("editBorder"))
    area.edit:SetFontObject(fontObject(current.fonts.body))
    area.edit:SetTextColor(Theme:Color("text"))
end

-- A checkbox: its box is drawn like an edit box (the theme's border), the tick in the accent colour.
skin.check = function(check)
    check.box:SetBackdrop(current.edit.backdrop)
    check.box:SetBackdropColor(Theme:Color("editBg"))
    check.box:SetBackdropBorderColor(Theme:Color(check.mzHover and "accent" or "editBorder"))
    check.tick:SetVertexColor(Theme:Color("accent"))
    skin.text(check.label, { style = "body" })
end

skin.row = function(row)
    row.hl:SetColorTexture(Theme:Color("rowHover"))
    row.sel:SetColorTexture(Theme:Color("rowSelected"))
    if row.markerGroup then row.marker:SetColorTexture(Theme:MarkerColor(row.markerGroup)) end
    if row.markerMethod then row.marker:SetColorTexture(Theme:MethodColor(row.markerMethod)) end
    -- A route step can show a picture of how it travels in place of the chip (row.iconShown tells the caller,
    -- which moves the step's text over for it).
    local icon = type(row.markerMethod) == "string" and Theme:StepIconsOn() and Theme:StepIcon(row.markerMethod, row.markerSource)
    row.iconShown = icon and true or false
    if icon then
        local def = current.stepIcon or {}
        local crop, size = def.crop or 0.08, def.size or 18
        -- The minimap's own symbols (the flight master's boot) have no frame to trim: cropping would cut the art.
        if type(icon) == "string" and icon:find("Minimap", 1, true) then crop = 0 end
        row.icon:SetTexture(icon)
        row.icon:SetTexCoord(crop, 1 - crop, crop, 1 - crop)
        row.icon:SetSize(size, size)
        row.icon:Show()
        row.marker:Hide()
    else
        row.icon:Hide()
        row.marker:Show()
    end
end

local function register(widget, role, opts)
    opts = opts or {}
    widgets[widget] = { role = role, opts = opts }
    if current then skin[role](widget, opts) end
    return widget
end

-- Re-skin everything already made (after a theme change).
function Theme:Apply()
    for widget, info in pairs(widgets) do
        skin[info.role](widget, info.opts)
    end
end

function Theme:Set(id)
    if not themes[id] then return false end
    current = themes[id]
    addon.Options:Store("theme", id)
    self:Apply()
    return true
end

-- Choose the saved theme, or the default.
function Theme:Init(default)
    local saved = addon.Options:Get("theme")
    self:Set(themes[saved] and saved or default or order[1])
    if not self.listening then
        self.listening = true
        -- Picking a theme on the settings page changes it live.
        addon.Options:OnChange(function(key, value)
            if key == "theme" and themes[value] then Theme:Set(value) end
        end)
    end
end

-- ---------------------------------------------------------------------------------------
-- Widget makers. These are what the panel uses.

function Theme:Panel(parent, name)
    return register(CreateFrame("Frame", name, parent, "BackdropTemplate"), "panel")
end

-- style: "title", "body", "small", "dim", "accent", "good" or "warn".
function Theme:Text(parent, style)
    local fs = withFont(parent:CreateFontString(nil, "OVERLAY"))
    fs:SetJustifyH("LEFT")
    return register(fs, "text", { style = style or "body" })
end

-- `template` adds to the button's templates, for a secure button ("SecureActionButtonTemplate"). `primary` is the
-- filled main button, or "action" for the accent-edged one with a picture (Theme:ActionButton).
function Theme:Button(parent, text, width, height, primary, template)
    local button = CreateFrame("Button", nil, parent, template and (template .. ",BackdropTemplate") or "BackdropTemplate")
    button:SetSize(width, height)
    button.label = withFont(button:CreateFontString(nil, "OVERLAY"))
    button.label:SetPoint("CENTER")
    button.label:SetText(text)
    local function state(value)
        button.mzState = value
        if current then skin.button(button, widgets[button].opts) end
    end
    button:SetScript("OnEnter", function() state("hover") end)
    button:SetScript("OnLeave", function() state("normal") end)
    button:SetScript("OnMouseDown", function() state("pressed") end)
    button:SetScript("OnMouseUp", function() state("hover") end)
    local action = primary == "action"
    return register(button, "button", { primary = primary and not action, action = action })
end

-- A button for a spell or item: its icon on the left, the name beside it. button:SetIcon(texture) sets the picture
-- (nil hides it).
function Theme:ActionButton(parent, width, height, template)
    local button = Theme:Button(parent, "", width, height, "action", template)
    local size = height - 8
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetSize(size, size)
    button.icon:SetPoint("LEFT", 4, 0)
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button.label:ClearAllPoints()
    button.label:SetPoint("LEFT", button.icon, "RIGHT", 10, 0)
    button.label:SetPoint("RIGHT", -8, 0)
    button.label:SetJustifyH("LEFT")
    button.label:SetWordWrap(false)
    function button:SetIcon(texture)
        self.icon:SetTexture(texture)
        self.icon:SetShown(texture ~= nil)
    end
    return button
end

-- A button for the minimap's rim, `icon` a texture in it. Placing it (round the rim) is the caller's; the ring and the
-- disc behind the icon follow the theme.
function Theme:MinimapButton(parent, name, icon)
    local button = CreateFrame("Button", name, parent)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    button.disc = button:CreateTexture(nil, "BACKGROUND")
    button.disc:SetSize(24, 24)
    button.disc:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    button.disc:SetPoint("CENTER", 0, 1)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetSize(20, 20)
    button.icon:SetTexture(icon)
    button.icon:SetPoint("CENTER", 0, 1)
    button.ring = button:CreateTexture(nil, "OVERLAY")
    button.ring:SetSize(50, 50)
    button.ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    button.ring:SetPoint("TOPLEFT")
    return register(button, "minimap")
end

-- A slider, horizontal unless `vertical` (a scroll bar; `length` is then its height). Set its range with
-- SetMinMaxValues/SetValueStep; read changes through the OnValueChanged script (self, value, userInput).
function Theme:Slider(parent, length, vertical)
    local slider = CreateFrame("Slider", nil, parent)
    slider:SetObeyStepOnDrag(true)
    slider.track = slider:CreateTexture(nil, "BACKGROUND")
    slider:SetThumbTexture(FLAT)
    slider.thumb = slider:GetThumbTexture()
    if vertical then
        slider:SetSize(10, length)
        slider:SetOrientation("VERTICAL")
        slider.track:SetPoint("TOP", 0, 0)
        slider.track:SetPoint("BOTTOM", 0, 0)
        slider.track:SetWidth(6)
        slider.thumb:SetSize(10, 40)
    else
        slider:SetSize(length, 18)
        slider:SetOrientation("HORIZONTAL")
        slider.track:SetPoint("LEFT", 0, 0)
        slider.track:SetPoint("RIGHT", 0, 0)
        slider.track:SetHeight(6)
        slider.thumb:SetSize(10, 18)
    end
    return register(slider, "slider")
end

-- A dropdown: a button showing the chosen option that opens a list under it. `options` is
-- { { id = ..., label = ... }, ... }; onSelect(id) runs when the player picks one. Returns a
-- table with :SetValue(id) (shows an option without calling onSelect) and :Select(id) (as if
-- the player clicked it). The list is a child of the button, so it hides with it, unless `menuParent` is given:
-- a button inside a scroll frame needs its list outside it, or the list is clipped to the scrolled view.
local DISABLED_ALPHA = 0.4     -- how far a disabled control fades

function Theme:Dropdown(parent, width, options, onSelect, menuParent)
    local dropdown = { options = options, rows = {} }
    dropdown.button = Theme:Button(parent, "", width, 24)
    dropdown.menu = Theme:Panel(menuParent or dropdown.button, nil)
    if menuParent then dropdown.button:HookScript("OnHide", function() dropdown.menu:Hide() end) end
    dropdown.menu:SetFrameStrata("FULLSCREEN_DIALOG")
    dropdown.menu:SetSize(width, #options * 24 + 8)
    dropdown.menu:SetPoint("TOPLEFT", dropdown.button, "BOTTOMLEFT", 0, -2)
    dropdown.menu:Hide()

    function dropdown:SetValue(id)
        self.value = id
        for i, option in ipairs(self.options) do
            self.rows[i]:SetSelected(option.id == id)
            -- The arrow says it opens: a disabled one doesn't.
            if option.id == id then self.button.label:SetText(option.label .. (self.disabled and "" or "  v")) end
        end
    end
    -- Greyed out and unclickable (any theme: the whole button fades), or back to normal.
    function dropdown:SetEnabled(on)
        self.disabled = not on
        self.button:SetEnabled(on)
        self.button:SetAlpha(on and 1 or DISABLED_ALPHA)
        self.menu:Hide()
        if self.value ~= nil then self:SetValue(self.value) end
    end
    function dropdown:Select(id)
        self:SetValue(id)
        self.menu:Hide()
        if onSelect then onSelect(id) end
    end

    for i, option in ipairs(options) do
        local row = Theme:Row(dropdown.menu, width - 8, 24)
        row:SetPoint("TOPLEFT", 4, -(4 + (i - 1) * 24))
        row.text = Theme:Text(row, "body")
        row.text:SetPoint("LEFT", 12, 0)
        row.text:SetText(option.label)
        row:SetScript("OnClick", function() dropdown:Select(option.id) end)
        dropdown.rows[i] = row
    end
    dropdown.button:SetScript("OnClick", function() dropdown.menu:SetShown(not dropdown.menu:IsShown()) end)
    return dropdown
end

-- A checkbox with its label beside it; clicking either ticks it. onToggle(checked) runs when the player clicks it.
-- check:SetChecked(on) shows a value without calling onToggle; check:GetChecked() reads it.
local CHECK_BOX = 18
local CHECK_TICK = "Interface\\Buttons\\UI-CheckBox-Check"       -- in every client

function Theme:Checkbox(parent, text, onToggle)
    local check = CreateFrame("Button", nil, parent)
    check.box = CreateFrame("Frame", nil, check, "BackdropTemplate")
    check.box:SetSize(CHECK_BOX, CHECK_BOX)
    check.box:SetPoint("LEFT", 0, 0)
    check.tick = check.box:CreateTexture(nil, "OVERLAY")
    check.tick:SetTexture(CHECK_TICK)
    check.tick:SetPoint("CENTER", 1, 0)
    check.tick:SetSize(CHECK_BOX + 6, CHECK_BOX + 6)
    check.tick:Hide()
    check.label = withFont(check:CreateFontString(nil, "OVERLAY"))
    check.label:SetPoint("LEFT", check.box, "RIGHT", 8, 0)
    check.label:SetJustifyH("LEFT")
    check.label:SetText(text)
    check:SetSize(CHECK_BOX + 8 + math.max(40, check.label:GetStringWidth() or 0), CHECK_BOX + 4)
    function check:SetChecked(on)
        self.mzChecked = on and true or false
        self.tick:SetShown(self.mzChecked)
    end
    function check:GetChecked() return self.mzChecked == true end
    check:SetScript("OnClick", function(self)
        self:SetChecked(not self.mzChecked)
        if onToggle then onToggle(self.mzChecked) end
    end)
    local function hover(on)
        check.mzHover = on
        if current then skin.check(check) end
    end
    check:SetScript("OnEnter", function() hover(true) end)
    check:SetScript("OnLeave", function() hover(false) end)
    return register(check, "check")
end

-- An arrow pointing up until rotated: arrow:SetRotation(radians), counter-clockwise. Its picture
-- and colour come from the theme (`arrow` in the theme definition, else the minimap arrow).
function Theme:Arrow(parent, size)
    local arrow = parent:CreateTexture(nil, "ARTWORK")
    arrow:SetSize(size, size)
    return register(arrow, "arrow")
end

-- The ring round the flight point a route flies to, on the flight master's map: a slow pulse, in the route's end
-- colour over the casing (our own picture, tools/gen_media.py). Takes no clicks; the game's button under it does.
function Theme:TaxiMark(parent)
    local mark = CreateFrame("Frame", nil, parent)
    mark:EnableMouse(false)
    mark.edge = mark:CreateTexture(nil, "ARTWORK", nil, 1)
    mark.edge:SetAllPoints()
    mark.edge:SetTexture("Interface\\AddOns\\" .. addonName .. "\\Media\\HaloEdge", "CLAMP", "CLAMP", "TRILINEAR")
    mark.ring = mark:CreateTexture(nil, "ARTWORK", nil, 2)
    mark.ring:SetAllPoints()
    mark.ring:SetTexture("Interface\\AddOns\\" .. addonName .. "\\Media\\Halo", "CLAMP", "CLAMP", "TRILINEAR")
    local pulse = mark:CreateAnimationGroup()
    pulse:SetLooping("BOUNCE")
    local fade = pulse:CreateAnimation("Alpha")
    fade:SetFromAlpha(1)
    fade:SetToAlpha(0.35)
    fade:SetDuration(0.8)
    fade:SetSmoothing("IN_OUT")
    mark.pulse = pulse
    mark:SetScript("OnShow", function(self) self.pulse:Play() end)
    mark:SetScript("OnHide", function(self) self.pulse:Stop() end)
    mark:Hide()          -- a new frame starts shown, and its first Show would then never start the pulse
    return register(mark, "taximark")
end

-- A number in a disc (a tour stop's): badge:SetNumber(n).
function Theme:Badge(parent, size)
    local badge = CreateFrame("Frame", nil, parent)
    badge:SetSize(size, size)
    badge.disc = badge:CreateTexture(nil, "ARTWORK")
    badge.disc:SetAllPoints()
    badge.disc:SetTexture("Interface\\AddOns\\" .. addonName .. "\\Media\\Dot")
    badge.number = withFont(badge:CreateFontString(nil, "OVERLAY"))
    badge.number:SetPoint("CENTER", 0, 0)
    function badge:SetNumber(n) self.number:SetText(n) end
    return register(badge, "badge")
end

-- A thin bar split into parts: bar:SetParts({ { style = "flight", share = 0.3 }, ... }), shares adding up to 1.
local SPLIT_PARTS = 4
function Theme:SplitBar(parent, width, height)
    local bar = CreateFrame("Frame", nil, parent)
    bar:SetSize(width, height)
    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints()
    bar.parts, bar.styles, bar.mzWidth = {}, {}, width
    for i = 1, SPLIT_PARTS do
        bar.parts[i] = bar:CreateTexture(nil, "ARTWORK")
        bar.parts[i]:SetHeight(height)
        bar.parts[i]:Hide()
    end
    function bar:SetParts(list)
        local x, width = 0, self.mzWidth
        for i, part in ipairs(self.parts) do
            local item = list[i]
            local w = item and math.floor(item.share * width + 0.5) or 0
            self.styles[i] = item and item.style
            if w > 0 then
                part:ClearAllPoints()
                part:SetPoint("LEFT", x, 0)
                part:SetWidth(w)
                part:Show()
                x = x + w
            else
                part:Hide()
            end
        end
        if current then skin.split(self) end
    end
    return register(bar, "split")
end

-- A progress bar (0 to 1): bar:SetValue(fraction).
function Theme:Bar(parent, width, height)
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetSize(width, height)
    bar:SetMinMaxValues(0, 1)
    bar:SetStatusBarTexture(FLAT)
    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints()
    return register(bar, "bar")
end

function Theme:EditBox(parent, width, height)
    local edit = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    edit:SetSize(width, height)
    edit:SetAutoFocus(false)
    edit:SetTextInsets(8, 8, 0, 0)
    return register(edit, "edit")
end

-- A small square button showing a picture (`icon`: a name from BUTTON_ICONS, "edit"), for an action on a row.
-- tooltip (optional): the text shown under the mouse.
-- A button in another brand's colours (BRANDS: "discord"), its logo then `text`, the same in every theme. It sizes
-- itself to fit the text.
function Theme:BrandButton(parent, brand, text, height)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    local size = height - 8
    button.logo = button:CreateTexture(nil, "ARTWORK")
    button.logo:SetTexture(BRANDS[brand].logo)
    button.logo:SetSize(size * 4 / 3, size)                  -- the picture is 4:3
    button.logo:SetPoint("LEFT", 10, 0)
    button.label = button:CreateFontString(nil, "OVERLAY")
    button.label:SetPoint("LEFT", button.logo, "RIGHT", 6, 0)
    local function hover(on)
        button.mzHover = on
        if current then skin.brandbutton(button, widgets[button].opts) end
    end
    button:SetScript("OnEnter", function() hover(true) end)
    button:SetScript("OnLeave", function() hover(false) end)
    register(button, "brandbutton", { brand = brand })
    button.label:SetText(text)
    button:SetSize(10 + size * 4 / 3 + 6 + (button.label:GetStringWidth() or 0) + 12, height)
    return button
end

function Theme:IconButton(parent, size, icon, tooltip)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(size, size)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("CENTER")
    button.icon:SetSize(size - 4, size - 4)
    local function hover(on)
        button.mzHover = on
        if current then skin.iconbutton(button, widgets[button].opts) end
        if on and tooltip then
            Theme:ShowTooltip(button, { { tooltip, "body" } })
        elseif not on then
            Theme:HideTooltip(button)
        end
    end
    button:SetScript("OnEnter", function() hover(true) end)
    button:SetScript("OnLeave", function() hover(false) end)
    return register(button, "iconbutton", { icon = icon })
end

-- A line of accent text that shows a tooltip when pointed at or clicked: lines(), called each time, gives the tooltip's
-- lines as Theme:ShowTooltip takes them. The button is sized to its text; its FontString is button.label.
function Theme:Link(parent, text, lines)
    local button = CreateFrame("Button", nil, parent)
    button.label = self:Text(button, "accent")
    button.label:SetPoint("LEFT")
    button.label:SetText(text)
    button:SetSize(math.ceil(button.label:GetStringWidth() or 0) + 2, math.ceil(button.label:GetStringHeight() or 12) + 4)
    local function show() Theme:ShowTooltip(button, lines()) end
    button:SetScript("OnEnter", show)
    button:SetScript("OnClick", show)
    button:SetScript("OnLeave", function() Theme:HideTooltip(button) end)
    return button
end

-- A box for several lines of text (pasting a list into), looking like an edit box. The text scrolls with the mouse
-- wheel and follows the cursor. Returns the box; its EditBox is box.edit.
function Theme:TextArea(parent, width, height)
    local area = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    area:SetSize(width, height)
    local scroll = CreateFrame("ScrollFrame", nil, area)
    scroll:SetPoint("TOPLEFT", 8, -6)
    scroll:SetPoint("BOTTOMRIGHT", -8, 6)
    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetMaxLetters(0)
    edit:SetSize(width - 16, height - 12)
    scroll:SetScrollChild(edit)
    -- Keep the line being typed on in view.
    edit:SetScript("OnCursorChanged", function(_, _, y, _, lineHeight)
        local top, offset, view = -y, scroll:GetVerticalScroll(), scroll:GetHeight()
        if top < offset then
            scroll:SetVerticalScroll(top)
        elseif top + lineHeight > offset + view then
            scroll:SetVerticalScroll(top + lineHeight - view)
        end
    end)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local most = self:GetVerticalScrollRange() or 0
        self:SetVerticalScroll(math.max(0, math.min(most, self:GetVerticalScroll() - delta * 20)))
    end)
    -- A click anywhere in the box puts the cursor in it, not just on the lines there are.
    area:EnableMouse(true)
    area:SetScript("OnMouseDown", function() edit:SetFocus() end)
    area.edit, area.scroll = edit, scroll
    return register(area, "area")
end

-- A clickable list row: a marker bar on the left, highlight on hover, a selected state.
-- The caller adds its own texts (Theme:Text) and sets row.markerGroup or row.markerMethod
-- (and row.markerSource, a step's spell or item) and calls Theme:Restyle(row) to colour the marker.
-- A step row may show an icon (row.icon) in place of the marker bar; see skin.row.
function Theme:Row(parent, width, height)
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(width, height)
    row.sel = row:CreateTexture(nil, "BACKGROUND")
    row.sel:SetAllPoints()
    row.sel:Hide()
    row.hl = row:CreateTexture(nil, "BACKGROUND")
    row.hl:SetAllPoints()
    row.hl:Hide()
    row.marker = row:CreateTexture(nil, "ARTWORK")
    row.marker:SetSize(3, height - 12)
    row.marker:SetPoint("LEFT", 4, 0)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetPoint("LEFT", 4, 0)
    row.icon:Hide()
    row:SetScript("OnEnter", function(self) self.hl:Show() end)
    row:SetScript("OnLeave", function(self) self.hl:Hide() end)
    function row:SetSelected(selected)
        if selected then self.sel:Show() else self.sel:Hide() end
    end
    -- Moves the marker (and icon) right by `indent`, for a row set in under a heading.
    function row:SetIndent(indent)
        self.marker:SetPoint("LEFT", 4 + indent, 0)
        self.icon:SetPoint("LEFT", 4 + indent, 0)
    end
    return register(row, "row")
end

-- A tooltip beside `owner`: lines = { { text, style }, ... } in the text styles above (the first is the heading).
-- It is the game's own tooltip, with the words in the theme's colours.
function Theme:ShowTooltip(owner, lines)
    if not GameTooltip or not lines or #lines == 0 then return end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    for _, line in ipairs(lines) do
        local r, g, b = self:Color(TEXT_COLORS[line[2] or "body"] or "text")
        GameTooltip:AddLine(line[1], r, g, b, true)
    end
    GameTooltip:Show()
end

function Theme:HideTooltip(owner)
    if GameTooltip and GameTooltip:IsOwned(owner) then GameTooltip:Hide() end
end

-- Change a Theme:Text's style ("dim" to grey out a label, say).
function Theme:SetTextStyle(fs, style)
    local info = widgets[fs]
    if info then
        info.opts.style = style
        self:Restyle(fs)
    end
end

-- Re-skin one widget (after changing what it shows, such as a row's marker).
function Theme:Restyle(widget)
    local info = widgets[widget]
    if info and current then skin[info.role](widget, info.opts) end
end

-- How many widgets are registered, and whether each has a skin (for tests).
function Theme:Audit()
    local count, missing = 0, 0
    for _, info in pairs(widgets) do
        count = count + 1
        if not skin[info.role] then missing = missing + 1 end
    end
    return count, missing
end
