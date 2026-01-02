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
    taxSlider:SetMinMaxValues(0, 60)
    taxSlider:SetValueStep(1)
    taxSlider:SetObeyStepOnDrag(true)
    taxSlider:SetWidth(300)

    -- Slider label
    _G[taxSlider:GetName() .. "Text"]:SetText("Loading Screen Delay")

    -- Low/High labels
    _G[taxSlider:GetName() .. "Low"]:SetText("0s")
    _G[taxSlider:GetName() .. "High"]:SetText("60s")

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
    -- MINIMAP BUTTON CHECKBOX
    -----------------------------------------------------------

    local minimapCheckbox = CreateFrame("CheckButton", "MapzerothMinimapCheckbox", panel,
        "InterfaceOptionsCheckButtonTemplate")
        minimapCheckbox:SetPoint("TOPLEFT", taxSlider, "BOTTOMLEFT", 0, -40)
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
    -- REFRESH CALLBACK (called when panel is opened)
    -----------------------------------------------------------

    panel.refresh = function()
        -- Load saved values
        local tax = MapzerothDB.settings.loadingScreenTax or 15
        taxSlider:SetValue(tax)
        taxValue:SetText(tax .. " seconds")

        -- Minimap button
        local minimapShown = not (MapzerothDB.minimap and MapzerothDB.minimap.hide)
        minimapCheckbox:SetChecked(minimapShown)
    end

    -----------------------------------------------------------
    -- DEFAULT CALLBACK (called when "Defaults" button clicked)
    -----------------------------------------------------------

    panel.default = function()
        -- Reset to defaults
        taxSlider:SetValue(15)
        minimapCheckbox:SetChecked(true)

        -- Apply defaults
        MapzerothDB.settings.loadingScreenTax = 15
        addon:ShowMinimapButton()

        print("[Mapzeroth] Settings reset to defaults")
    end

    return panel
end

-----------------------------------------------------------
-- INITIALIZE SETTINGS PANEL (Modern API)
-----------------------------------------------------------

function addon:InitializeSettingsPanel()
    local panel = CreateSettingsPanel()

    -- Use new Settings API (10.0+)
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
-- OPEN SETTINGS PANEL (Modern API)
-----------------------------------------------------------

function addon:OpenSettings()
    if not addon.SettingsPanel then
        addon:InitializeSettingsPanel()
    end

    -- Open settings to our category
    Settings.OpenToCategory(addon.SettingsCategory.ID)
end
