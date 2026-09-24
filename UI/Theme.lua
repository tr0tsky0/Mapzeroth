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
--   methods      colours by travel method (walk, taxi, ship, zeppelin, tram, portal, ...)
--   markers      colours by kind of place (place, flight, transport, instance, ...)
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

function Theme:MethodColor(method)
    local c = current and current.methods and (current.methods[method] or current.methods.default)
    if not c then return self:Color("text") end
    return c[1], c[2], c[3], c[4] or 1
end

function Theme:MarkerColor(group)
    local c = current and current.markers and (current.markers[group] or current.markers.default)
    if not c then return self:Color("accent") end
    return c[1], c[2], c[3], c[4] or 1
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

skin.text = function(fs, opts)
    local style = opts.style
    local font = (style == "title" and current.fonts.title) or (style == "small" and current.fonts.small)
        or current.fonts.body
    fs:SetFontObject(fontObject(font))
    local color = ({ title = "accent", body = "text", small = "dim", dim = "dim", accent = "accent",
                     good = "good", warn = "warn", button = "buttonText", primary = "primaryText" })[style] or "text"
    fs:SetTextColor(Theme:Color(color))
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

-- A horizontal slider. Set its range with SetMinMaxValues/SetValueStep; read changes through the
-- OnValueChanged script (self, value, userInput).
function Theme:Slider(parent, width)
    local slider = CreateFrame("Slider", nil, parent)
    slider:SetSize(width, 18)
    slider:SetOrientation("HORIZONTAL")
    slider:SetObeyStepOnDrag(true)
    slider.track = slider:CreateTexture(nil, "BACKGROUND")
    slider.track:SetPoint("LEFT", 0, 0)
    slider.track:SetPoint("RIGHT", 0, 0)
    slider.track:SetHeight(6)
    slider:SetThumbTexture(FLAT)
    slider.thumb = slider:GetThumbTexture()
    slider.thumb:SetSize(10, 18)
    return register(slider, "slider")
end

-- A dropdown: a button showing the chosen option that opens a list under it. `options` is
-- { { id = ..., label = ... }, ... }; onSelect(id) runs when the player picks one. Returns a
-- table with :SetValue(id) (shows an option without calling onSelect) and :Select(id) (as if
-- the player clicked it).
function Theme:Dropdown(parent, width, options, onSelect)
    local dropdown = { options = options, rows = {} }
    dropdown.button = Theme:Button(parent, "", width, 24)
    dropdown.menu = Theme:Panel(dropdown.button, nil)     -- a child of the button, so it hides with it
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
-- and calls Theme:Restyle(row) to colour the marker.
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
    row:SetScript("OnEnter", function(self) self.hl:Show() end)
    row:SetScript("OnLeave", function(self) self.hl:Hide() end)
    function row:SetSelected(selected)
        if selected then self.sel:Show() else self.sel:Hide() end
    end
    return register(row, "row")
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
