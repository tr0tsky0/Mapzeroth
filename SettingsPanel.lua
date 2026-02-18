-- SettingsPanel.lua
-- Mapzeroth settings integration with Interface Options
local addonName, addon = ...

-----------------------------------------------------------
-- CREATE SETTINGS PANEL
-----------------------------------------------------------

local function CreateSettingsPanel()
    -- Initialize slider value from SavedVariables (or default)
    MapzerothDB = MapzerothDB or {}
    MapzerothDB.settings = MapzerothDB.settings or {}
    MapzerothDB.minimap = MapzerothDB.minimap or {}

    local initialTax = MapzerothDB.settings.loadingScreenTax or 15
    local initialCooldown = MapzerothDB.settings.maxCooldownValue or 8

    -- Main panel frame
    local panel = CreateFrame("Frame")
    panel.name = "Mapzeroth"

    -- Title
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Mapzeroth Settings")

    -- Subtitle
    local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetText("Configure travel routing preferences")

    -----------------------------------------------------------
    -- LOADING SCREEN TAX SLIDER
    -----------------------------------------------------------

    local taxSlider = CreateFrame("Slider", "MapzerothLoadingScreenTaxSlider", panel, "OptionsSliderTemplate")
    taxSlider:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 4, -32)
    taxSlider:SetMinMaxValues(0, 30)
    taxSlider:SetValueStep(1)
    taxSlider:SetObeyStepOnDrag(true)
    taxSlider:SetWidth(300)

    -- Slider label
    _G[taxSlider:GetName() .. "Text"]:SetText("Loading Screen Delay")

    -- Low/High labels
    _G[taxSlider:GetName() .. "Low"]:SetText("0s")
    _G[taxSlider:GetName() .. "High"]:SetText("30s")

    taxSlider:SetValue(initialTax)

    -- Current value display
    local taxValue = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    taxValue:SetPoint("TOP", taxSlider, "BOTTOM", 0, -4)
    taxValue:SetText(initialTax .. " seconds")
    taxSlider.valueText = taxValue

    -- Tooltip
    local taxTooltip = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    taxTooltip:SetPoint("TOPLEFT", taxSlider, "BOTTOMLEFT", 0, -16)
    taxTooltip:SetPoint("RIGHT", panel, "RIGHT", -16, 0)
    taxTooltip:SetJustifyH("LEFT")
    taxTooltip:SetTextColor(0.7, 0.7, 0.7)
    taxTooltip:SetText(
        "Add extra time to routes that trigger loading screens (portals, ships, hearthstones, etc). Adjust based on your PC's load times. Higher values favor walking/flying over teleports.")

    -- Slider change handler
    taxSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        self.valueText:SetText(value .. " seconds")

        -- Update saved variable
        MapzerothDB.settings.loadingScreenTax = value
    end)

    -- Initialize slider value
    panel.taxSlider = taxSlider

    -----------------------------------------------------------
    -- COOLDOWN MAX SLIDER
    -----------------------------------------------------------

    local cooldownSlider = CreateFrame("Slider", "MapzerothCooldownMaxSlider", panel, "OptionsSliderTemplate")
    cooldownSlider:SetPoint("TOPLEFT", taxSlider, "BOTTOMLEFT", 4, -70)
    cooldownSlider:SetMinMaxValues(1, 8)
    cooldownSlider:SetValueStep(1)
    cooldownSlider:SetObeyStepOnDrag(true)
    cooldownSlider:SetWidth(300)

    -- Slider label
    _G[cooldownSlider:GetName() .. "Text"]:SetText("Max Usable Cooldown")

    -- Low/High labels
    _G[cooldownSlider:GetName() .. "Low"]:SetText("1h")
    _G[cooldownSlider:GetName() .. "High"]:SetText("8h")

    cooldownSlider:SetValue(initialCooldown)

    -- Current value display
    local cooldownValue = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    cooldownValue:SetPoint("TOP", cooldownSlider, "BOTTOM", 0, -4)
    cooldownValue:SetText(initialCooldown .. " hours")
    cooldownSlider.valueText = cooldownValue

    -- Tooltip
    local cooldownTooltip = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    cooldownTooltip:SetPoint("TOPLEFT", cooldownSlider, "BOTTOMLEFT", 0, -16)
    cooldownTooltip:SetPoint("RIGHT", panel, "RIGHT", -16, 0)
    cooldownTooltip:SetJustifyH("LEFT")
    cooldownTooltip:SetTextColor(0.7, 0.7, 0.7)
    cooldownTooltip:SetText(
        "Set the maximum cooldown length to be considered for routing. Any items or abilities with higher cooldown will be ignored")

    -- Slider change handler
    cooldownSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        self.valueText:SetText(value .. " hours")

        -- Update saved variable
        MapzerothDB.settings.maxCooldownValue = value
    end)

    -- Initialize slider value
    panel.cooldownSlider = cooldownSlider

    -----------------------------------------------------------
    -- WINDOW SCALE SLIDER
    -----------------------------------------------------------

    local scaleSlider = CreateFrame("Slider", "MapzerothScaleSlider", panel, "OptionsSliderTemplate")
    scaleSlider:SetPoint("TOPLEFT", cooldownSlider, "BOTTOMLEFT", 4, -70)
    scaleSlider:SetMinMaxValues(0.75, 1.5)
    scaleSlider:SetValueStep(0.05)
    scaleSlider:SetObeyStepOnDrag(true)
    scaleSlider:SetWidth(300)

    -- Slider label
    _G[scaleSlider:GetName() .. "Text"]:SetText("Window Scale")

    -- Low/High labels
    _G[scaleSlider:GetName() .. "Low"]:SetText("75%")
    _G[scaleSlider:GetName() .. "High"]:SetText("150%")

    local initialScale = MapzerothDB.settings.windowScale or 1.0
    scaleSlider:SetValue(initialScale)

    -- Current value display
    local scaleValue = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    scaleValue:SetPoint("TOP", scaleSlider, "BOTTOM", 0, -4)
    scaleValue:SetText(math.floor(initialScale * 100) .. "%")
    scaleSlider.valueText = scaleValue

    -- Tooltip
    local scaleTooltip = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    scaleTooltip:SetPoint("TOPLEFT", scaleSlider, "BOTTOMLEFT", 0, -16)
    scaleTooltip:SetPoint("RIGHT", panel, "RIGHT", -16, 0)
    scaleTooltip:SetJustifyH("LEFT")
    scaleTooltip:SetTextColor(0.7, 0.7, 0.7)
    scaleTooltip:SetText("Adjust the size of all Mapzeroth windows. Changes take effect immediately.")

    -- Slider change handler
    scaleSlider:SetScript("OnValueChanged", function(self, value)
        value = tonumber(string.format("%.2f", value))
        self.valueText:SetText(math.floor(value * 100) .. "%")

        -- Update saved variable
        MapzerothDB.settings.windowScale = value

        -- Apply immediately to all frames
        addon:ApplyWindowScale(value)
    end)

    -- Store reference
    panel.scaleSlider = scaleSlider

    -----------------------------------------------------------
    -- MINIMAP BUTTON CHECKBOX
    -----------------------------------------------------------

    local minimapCheckbox = CreateFrame("CheckButton", "MapzerothMinimapCheckbox", panel,
        "InterfaceOptionsCheckButtonTemplate")
    minimapCheckbox:SetPoint("TOPLEFT", scaleSlider, "BOTTOMLEFT", 0, -50)
    _G[minimapCheckbox:GetName() .. "Text"]:SetText("Show Minimap Button")
    minimapCheckbox:SetChecked(not MapzerothDB.minimap.hide)

    minimapCheckbox:SetScript("OnClick", function(self)
        local show = self:GetChecked()
        MapzerothDB.minimap.hide = not show

        if show then
            addon:ShowMinimapButton()
        else
            addon:HideMinimapButton()
        end
    end)

    panel.minimapCheckbox = minimapCheckbox

    -----------------------------------------------------------
    -- MAP CLICK NAVIGATION BINDING
    -----------------------------------------------------------

    local mapClickTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    mapClickTitle:SetPoint("TOPLEFT", minimapCheckbox, "BOTTOMLEFT", 4, -28)
    mapClickTitle:SetText("Map Click Navigation")

    local mapClickDescription = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    mapClickDescription:SetPoint("TOPLEFT", mapClickTitle, "BOTTOMLEFT", 0, -6)
    mapClickDescription:SetPoint("RIGHT", panel, "RIGHT", -16, 0)
    mapClickDescription:SetJustifyH("LEFT")
    mapClickDescription:SetTextColor(0.7, 0.7, 0.7)
    mapClickDescription:SetText(
        "Click on the world map with your configured key combo to create a waypoint and immediately start navigation.")

    local bindingValue = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    bindingValue:SetPoint("TOPLEFT", mapClickDescription, "BOTTOMLEFT", 0, -10)
    bindingValue:SetText("Current: " .. addon:GetMapClickBindingLabel())

    local modifierButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    modifierButton:SetSize(140, 24)
    modifierButton:SetPoint("TOPLEFT", bindingValue, "BOTTOMLEFT", 0, -10)
    modifierButton:SetText("Change Modifier")
    modifierButton:SetScript("OnClick", function()
        addon:CycleMapClickModifier()
        bindingValue:SetText("Current: " .. addon:GetMapClickBindingLabel())
    end)

    local mouseButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    mouseButton:SetSize(140, 24)
    mouseButton:SetPoint("LEFT", modifierButton, "RIGHT", 10, 0)
    mouseButton:SetText("Change Mouse")
    mouseButton:SetScript("OnClick", function()
        addon:CycleMapClickMouseButton()
        bindingValue:SetText("Current: " .. addon:GetMapClickBindingLabel())
    end)

    -----------------------------------------------------------
    -- REFRESH CALLBACK (called when panel is opened)
    -----------------------------------------------------------

    panel.refresh = function()
        -- Load saved values
        local tax = MapzerothDB.settings.loadingScreenTax or 10
        taxSlider:SetValue(tax)
        taxValue:SetText(tax .. " seconds")

        local cooldown = MapzerothDB.settings.maxCooldownValue or 8
        cooldownSlider:SetValue(cooldown)
        cooldownValue:SetText(cooldown .. " hours")

        local scale = MapzerothDB.settings.windowScale or 1.0
        scaleSlider:SetValue(scale)
        scaleValue:SetText(math.floor(scale * 100) .. "%")

        -- Minimap button
        local minimapShown = not (MapzerothDB.minimap and MapzerothDB.minimap.hide)
        minimapCheckbox:SetChecked(minimapShown)
        bindingValue:SetText("Current: " .. addon:GetMapClickBindingLabel())
    end

    -----------------------------------------------------------
    -- DEFAULT CALLBACK (called when "Defaults" button clicked)
    -----------------------------------------------------------

    panel.default = function()
        -- Reset GUI to defaults
        taxSlider:SetValue(10)
        cooldownSlider:SetValue(8)
        scaleSlider:SetValue(1.0)
        minimapCheckbox:SetChecked(true)

        -- Apply defaults
        MapzerothDB.settings.loadingScreenTax = 10
        MapzerothDB.settings.maxCooldownValue = 8
        MapzerothDB.settings.windowScale = 1.0
        MapzerothDB.settings.mapClickModifier = "ALT"
        MapzerothDB.settings.mapClickMouseButton = "LeftButton"
        addon:ApplyWindowScale(1.0)
        addon:ShowMinimapButton()
        bindingValue:SetText("Current: " .. addon:GetMapClickBindingLabel())

        print("[Mapzeroth] Settings reset to defaults")
    end

    return panel
end

-----------------------------------------------------------
-- INITIALIZE SETTINGS PANEL
-----------------------------------------------------------

function addon:InitializeSettingsPanel()
    local panel = CreateSettingsPanel()

    local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(category)

    -- Store reference
    addon.SettingsPanel = panel
    addon.SettingsCategory = category

    if addon.DEBUG then
        print("[Mapzeroth] Settings panel registered")
    end
end

-----------------------------------------------------------
-- OPEN SETTINGS PANEL
-----------------------------------------------------------

function addon:OpenSettings()
    if not addon.SettingsPanel then
        addon:InitializeSettingsPanel()
    end

    -- Open settings to our category
    Settings.OpenToCategory(addon.SettingsCategory.ID)
end
