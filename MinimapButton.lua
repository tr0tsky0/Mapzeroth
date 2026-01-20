-- MinimapButton.lua
-- Minimap button integration using LibDBIcon
local addonName, addon = ...

local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")

-----------------------------------------------------------
-- CREATE DATA BROKER OBJECT
-----------------------------------------------------------

local MapzerothLDB = LDB:NewDataObject("Mapzeroth", {
    type = "launcher",
    icon = "Interface\\AddOns\\Mapzeroth\\Mapzeroth_Logo",
    OnClick = function(self, button)
        if button == "LeftButton" then
            addon:ToggleGUI()
        elseif button == "RightButton" then
            addon:OpenSettings()
        end
    end,
    OnTooltipShow = function(tooltip)
        tooltip:SetText("|cff00ccffMapzeroth|r")
        tooltip:AddLine("Google Maps for Azeroth", 1, 1, 1)
        tooltip:AddLine(" ")
        tooltip:AddLine("|cffaaaaaa< Left-Click >|r Toggle window", 0.2, 1, 0.2)
        tooltip:AddLine("|cffaaaaaa< Right-Click >|r Settings (coming soon)", 0.2, 1, 0.2)
        tooltip:AddLine("|cffaaaaaa< Drag >|r Move button", 0.2, 1, 0.2)
    end,
})

-----------------------------------------------------------
-- INITIALIZE MINIMAP BUTTON
-----------------------------------------------------------

function addon:InitializeMinimapButton()
    -- Ensure SavedVariables exist
    if not MapzerothDB then
        MapzerothDB = {}
    end
    
    if not MapzerothDB.minimap then
        MapzerothDB.minimap = {
            hide = false,
            minimapPos = 220,  -- Default position (degrees around minimap)
        }
    end
    
    -- Register with LibDBIcon
    LDBIcon:Register("Mapzeroth", MapzerothLDB, MapzerothDB.minimap)
    
    if addon.DEBUG then
        print("[Mapzeroth] Minimap button initialized")
    end
end

-----------------------------------------------------------
-- SHOW/HIDE MINIMAP BUTTON
-----------------------------------------------------------

function addon:ShowMinimapButton()
    if MapzerothDB and MapzerothDB.minimap then
        MapzerothDB.minimap.hide = false
        LDBIcon:Show("Mapzeroth")
    end
end

function addon:HideMinimapButton()
    if MapzerothDB and MapzerothDB.minimap then
        MapzerothDB.minimap.hide = true
        LDBIcon:Hide("Mapzeroth")
    end
end

function addon:ToggleMinimapButton()
    if MapzerothDB and MapzerothDB.minimap then
        if MapzerothDB.minimap.hide then
            addon:ShowMinimapButton()
        else
            addon:HideMinimapButton()
        end
    end
end