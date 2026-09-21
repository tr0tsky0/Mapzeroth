local addonName, addon = ...

-- The settings page, in the game's own Settings window (Game Menu > Options > AddOns >
-- Mapzeroth, or /mapzeroth settings): how long a loading screen counts for in a route, the size of
-- our windows, the theme, and whether the route is drawn on the map and on the minimap. The page is built from our own themed widgets and handed to the
-- game as a canvas, so it follows the theme like everything else. What the settings mean and
-- how they are kept is Options.lua's; this file only draws them.

local OptionsPanel = {}
addon.OptionsPanel = OptionsPanel

local L = addon.L
local Theme = addon.Theme
local Options = addon.Options

local PAD = 20
local widgets = {}

-- A label, a description and an On / Off choice for one on/off setting, in a column at x.
local function toggleColumn(parent, x, top, key, label, description)
    local title = Theme:Text(parent, "body")
    title:SetPoint("TOPLEFT", x, -top)
    title:SetText(label)
    local hint = Theme:Text(parent, "dim")
    hint:SetPoint("TOPLEFT", x, -(top + 20))
    hint:SetWidth(250)
    hint:SetWordWrap(true)
    hint:SetText(description)
    local choices = { { id = true, label = L["OPT_ON"] }, { id = false, label = L["OPT_OFF"] } }
    local dropdown = Theme:Dropdown(parent, 120, choices, function(id) Options:Set(key, id) end)
    dropdown.button:SetPoint("TOPLEFT", x, -(top + 84))
    dropdown.hint = hint
    dropdown.key = key
    return dropdown
end

-- A label, a description, and a slider bound to one numeric setting, with its value beside it.
local function sliderRow(parent, top, key, label, description, formatValue)
    local title = Theme:Text(parent, "body")
    title:SetPoint("TOPLEFT", PAD, -top)
    title:SetText(label)

    local hint = Theme:Text(parent, "dim")
    hint:SetPoint("TOPLEFT", PAD, -(top + 20))
    hint:SetWidth(520)
    hint:SetWordWrap(true)
    hint:SetText(description)

    local slider = Theme:Slider(parent, 300)
    slider:SetPoint("TOPLEFT", PAD, -(top + 58))
    local min, max, step = Options:Range(key)
    slider:SetMinMaxValues(min, max)
    slider:SetValueStep(step)

    local value = Theme:Text(parent, "accent")
    value:SetPoint("LEFT", slider, "RIGHT", 16, 0)
    slider:SetScript("OnValueChanged", function(_, raw)
        local kept = Options:Set(key, raw) or raw
        value:SetText(formatValue(kept))
    end)
    return { slider = slider, value = value, format = formatValue, key = key }
end

function OptionsPanel:Build()
    local frame = CreateFrame("Frame", "MapzerothRebuildOptions", UIParent)
    frame.name = L["OPT_TITLE"]
    self.frame = frame

    local box = Theme:Panel(frame, nil)
    box:SetPoint("TOPLEFT", 8, -8)
    box:SetPoint("BOTTOMRIGHT", -8, 8)

    local title = Theme:Text(box, "title")
    title:SetPoint("TOPLEFT", PAD, -PAD)
    title:SetText(L["OPT_TITLE"])

    widgets.tax = sliderRow(box, 64, "loadingScreenTax", L["OPT_TAX"], L["OPT_TAX_DESC"],
        function(v) return L["OPT_SECONDS"]:format(v) end)
    widgets.scale = sliderRow(box, 168, "scale", L["OPT_SCALE"], L["OPT_SCALE_DESC"],
        function(v) return L["OPT_PERCENT"]:format(math.floor(v * 100 + 0.5)) end)

    local themeTitle = Theme:Text(box, "body")
    themeTitle:SetPoint("TOPLEFT", PAD, -272)
    themeTitle:SetText(L["OPT_THEME"])
    local themeHint = Theme:Text(box, "dim")
    themeHint:SetPoint("TOPLEFT", PAD, -292)
    themeHint:SetWidth(520)
    themeHint:SetWordWrap(true)
    themeHint:SetText(L["OPT_THEME_DESC"])

    local choices = {}
    for _, id in ipairs(Theme:List()) do choices[#choices + 1] = { id = id, label = Theme:Label(id) } end
    widgets.theme = Theme:Dropdown(box, 220, choices, function(id) Options:Set("theme", id) end)
    widgets.theme.button:SetPoint("TOPLEFT", PAD, -326)

    widgets.routeMap = toggleColumn(box, PAD, 390, "showRouteOnMap", L["OPT_ROUTE_MAP"], L["OPT_ROUTE_MAP_DESC"])
    widgets.routeMinimap = toggleColumn(box, PAD + 290, 390, "showRouteOnMinimap", L["OPT_ROUTE_MINIMAP"], L["OPT_ROUTE_MINIMAP_DESC"])
    if not (addon.MinimapLines and addon.MinimapLines:IsAvailable()) then
        widgets.routeMinimap.hint:SetText(L["OPT_MINIMAP_UNAVAILABLE"])       -- it can't be done here: say so
        widgets.routeMinimap.button:Disable()
    end

    -- Hooks the game's Settings window calls on a canvas page.
    frame.OnCommit = function() end
    frame.OnDefault = function()
        Options:Reset()
        OptionsPanel:Sync()
    end
    frame.OnRefresh = function() OptionsPanel:Sync() end
    frame:SetScript("OnShow", function() OptionsPanel:Sync() end)

    self.widgets = widgets
    return frame
end

-- Show the current settings in the controls.
function OptionsPanel:Sync()
    if not self.frame then return end
    widgets.tax.slider:SetValue(Options:Get("loadingScreenTax"))
    widgets.tax.value:SetText(widgets.tax.format(Options:Get("loadingScreenTax")))
    widgets.scale.slider:SetValue(Options:Get("scale"))
    widgets.scale.value:SetText(widgets.scale.format(Options:Get("scale")))
    widgets.theme:SetValue(Options:Get("theme"))
    widgets.routeMap:SetValue(Options:Get("showRouteOnMap"))
    widgets.routeMinimap:SetValue(Options:Get("showRouteOnMinimap"))
end

-- Add the page to the game's Settings window (once).
function OptionsPanel:Register()
    if self.registered then return true end
    if not self.frame then self:Build() end
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        self.category = Settings.RegisterCanvasLayoutCategory(self.frame, self.frame.name)
        Settings.RegisterAddOnCategory(self.category)
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(self.frame)            -- older clients
    else
        return false
    end
    self.registered = true
    return true
end

function OptionsPanel:Open()
    if not self:Register() then return false end
    if Settings and Settings.OpenToCategory and self.category then
        Settings.OpenToCategory(self.category:GetID())
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(self.frame)
    end
    return true
end
