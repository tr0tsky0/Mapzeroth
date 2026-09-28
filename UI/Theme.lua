local addonName, addon = ...

-- The one place styling lives. The panel never sets a colour, texture, backdrop or font of
-- its own: it asks the theme for a widget ("panel", "button", "edit", "row", "text", ...)
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
--   markers      colours by kind of place (place, flight, transport, instance, ...)
--   icons        (optional) pictures for route steps by method, each a list of texture paths, the first the client
--                has winning; a method it leaves out uses STEP_ICONS below
--   stepIcon     (optional) { size = pixels, crop = fraction trimmed off each edge (an icon's own frame) }
-- Files under UI/Themes/ hold the themes we ship. Adding one is adding a file and a TOC line.

local Theme = {}
addon.Theme = Theme

local themes, order = {}, {}
local current
local widgets = setmetatable({}, { __mode = "k" })    -- widget -> { role, opts }
local skin = {}                                       -- role -> function(widget, opts)

local BLIZZARD_BUTTON = "Interface\\Buttons\\UI-Panel-Button-"
local FLAT = "Interface\\Buttons\\WHITE8x8"
local ARROW = "Interface\\Minimap\\ROTATING-MINIMAPARROW"      -- an arrow pointing up, in every client
local ARROW_CROP = 0.15         -- that texture is mostly empty around the arrow: trim it so the arrow fills its box

-- The picture beside a route step when the player shows icons instead of colour chips (the stepMarkers setting).
-- Each is a list of candidates, the first the client has winning: the classic clients lack some later art, so the
-- last of each list is an icon that has been in the game since launch. A step that uses a spell or an item
-- (a hearthstone, a teleport) shows that spell's or item's own icon before any of these.
local ICONS = "Interface\\Icons\\"
local STEP_ICONS = {
    walk        = { ICONS .. "Ability_Rogue_Sprint" },
    taxi        = { "Interface\Minimap\Tracking\FlightMaster", ICONS .. "Spell_Nature_RavenForm" },   -- the flight master's winged boot
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
    arrow:SetTexture(current.arrow or ARROW)
    local crop = current.arrow and (current.arrowCrop or 0) or ARROW_CROP
    arrow:SetTexCoord(crop, 1 - crop, crop, 1 - crop)
    arrow:SetVertexColor(Theme:Color("accent"))
end

skin.slider = function(slider)
    slider.track:SetColorTexture(Theme:Color("editBg"))
    slider.thumb:SetColorTexture(Theme:Color("accent"))
end

skin.bar = function(bar)
    bar:SetStatusBarColor(Theme:Color("accent"))
    bar.bg:SetColorTexture(Theme:Color("editBg"))
end

-- The colour each text style is drawn in.
local TEXT_COLORS = { title = "accent", body = "text", small = "dim", dim = "dim", accent = "accent",
                      good = "good", warn = "warn", button = "buttonText", primary = "primaryText" }

skin.text = function(fs, opts)
    local style = opts.style
    local font = (style == "title" and current.fonts.title) or (style == "small" and current.fonts.small)
        or current.fonts.body
    fs:SetFontObject(fontObject(font))
    fs:SetTextColor(Theme:Color(TEXT_COLORS[style] or "text"))
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
        button:SetBackdropBorderColor(Theme:Color(opts.primary and "primaryBg" or "panelBorder"))
        skin.text(button.label, { style = opts.primary and "primary" or "button" })
    end
end

skin.edit = function(edit)
    edit:SetBackdrop(current.edit.backdrop)
    edit:SetBackdropColor(Theme:Color("editBg"))
    edit:SetBackdropBorderColor(Theme:Color("editBorder"))
    edit:SetFontObject(fontObject(current.fonts.body))
    edit:SetTextColor(Theme:Color("text"))
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

-- `template` adds to the button's templates, for a secure button ("SecureActionButtonTemplate").
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
    return register(button, "button", { primary = primary })
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
            if option.id == id then self.button.label:SetText(option.label .. "  v") end
        end
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

-- An arrow pointing up until rotated: arrow:SetRotation(radians), counter-clockwise. Its picture
-- and colour come from the theme (`arrow` in the theme definition, else the minimap arrow).
function Theme:Arrow(parent, size)
    local arrow = parent:CreateTexture(nil, "ARTWORK")
    arrow:SetSize(size, size)
    return register(arrow, "arrow")
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
