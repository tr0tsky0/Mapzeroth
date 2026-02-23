-- Mapzeroth.lua
-- Main addon initialization
local addonName, addon = ...

-- Create the addon namespace
_G["Mapzeroth"] = addon

addon.DEBUG = false
addon.bagsFullyLoaded = false

local BACK_SLOT = INVSLOT_BACK or 15
local CITY_CLOAK_ITEM_IDS = {
    [65360] = true, -- Cloak of Coordination (Alliance)
    [65274] = true, -- Cloak of Coordination (Horde)
    [63206] = true, -- Wrap of Unity (Alliance)
    [63207] = true, -- Wrap of Unity (Horde)
    [63352] = true, -- Shroud of Cooperation (Alliance)
    [63353] = true  -- Shroud of Cooperation (Horde)
}

addon.cityCloakState = addon.cityCloakState or {}

function addon:IsCityCloakItemID(itemID)
    return itemID and CITY_CLOAK_ITEM_IDS[itemID] == true
end

function addon:DebugCityCloak(message)
    if self.DEBUG then
        print("[Mapzeroth][CLOAK DEBUG] " .. tostring(message))
    end
end

function addon:PrepareCityCloakClick(itemID)
    if not self:IsCityCloakItemID(itemID) then
        self:DebugCityCloak(string.format("Prepare ignored (not city cloak): itemID=%s", tostring(itemID)))
        return nil
    end

    local equippedCloakID = GetInventoryItemID("player", BACK_SLOT)
    local wasEquipped = (equippedCloakID == itemID)

    self.cityCloakState.targetItemID = itemID

    if not wasEquipped then
        self.cityCloakState.previousItemID = equippedCloakID
        self.cityCloakState.awaitingRestore = false
    end

    self:DebugCityCloak(string.format(
        "Prepare: itemID=%d equippedNow=%s previous=%s awaitingRestore=%s",
        itemID,
        tostring(wasEquipped),
        tostring(self.cityCloakState.previousItemID),
        tostring(self.cityCloakState.awaitingRestore)
    ))

    return wasEquipped
end

function addon:FinalizeCityCloakClick(itemID, wasEquippedBeforeClick)
    if not self:IsCityCloakItemID(itemID) then
        self:DebugCityCloak(string.format("Finalize ignored (not city cloak): itemID=%s", tostring(itemID)))
        return
    end

    if wasEquippedBeforeClick then
        self.cityCloakState.targetItemID = itemID
        self.cityCloakState.awaitingRestore = true
    end

    self:DebugCityCloak(string.format(
        "Finalize: itemID=%d wasEquippedBeforeClick=%s awaitingRestore=%s",
        itemID,
        tostring(wasEquippedBeforeClick),
        tostring(self.cityCloakState.awaitingRestore)
    ))
end

function addon:TryRestoreCityCloak()
    local state = self.cityCloakState
    if not state or not state.awaitingRestore then
        return
    end

    if InCombatLockdown() then
        self:DebugCityCloak("Restore blocked by combat lockdown, waiting for PLAYER_REGEN_ENABLED")
        return
    end

    self:DebugCityCloak(string.format(
        "Restore attempt: target=%s previous=%s",
        tostring(state.targetItemID),
        tostring(state.previousItemID)
    ))

    if state.previousItemID and state.previousItemID ~= state.targetItemID and GetItemCount(state.previousItemID) > 0 then
        EquipItemByName(state.previousItemID, BACK_SLOT)
        self:DebugCityCloak(string.format("Restore equipped previous cloak itemID=%d", state.previousItemID))
    else
        self:DebugCityCloak("Restore skipped (missing previous cloak or same as target)")
    end

    self.cityCloakState = {}
    self:DebugCityCloak("Restore complete, cloak state reset")
end

-- Simple load confirmation
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("BAG_UPDATE_DELAYED")
frame:RegisterEvent("HEARTHSTONE_BOUND")
frame:RegisterEvent("SUPER_TRACKING_CHANGED")
frame:RegisterEvent("CALENDAR_UPDATE_EVENT_LIST")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        -- Initialize SavedVariables structure if it doesn't exist
        if not MapzerothDB then
            MapzerothDB = {}
        end
        if not MapzerothDB.settings then
            MapzerothDB.settings = {}
        end
        if not MapzerothDB.minimap then
            MapzerothDB.minimap = {}
        end

        -- Set defaults for any missing settings values
        if MapzerothDB.settings.loadingScreenTax == nil then
            MapzerothDB.settings.loadingScreenTax = 15
        end
        if MapzerothDB.settings.maxCooldownValue == nil then
            MapzerothDB.settings.maxCooldownValue = 8
        end
        if MapzerothDB.settings.windowScale == nil then
            MapzerothDB.settings.windowScale = 1.0
        end
        if MapzerothDB.settings.mapClickModifier == nil then
            MapzerothDB.settings.mapClickModifier = "ALT"
        end
        if MapzerothDB.settings.mapClickMouseButton == nil then
            MapzerothDB.settings.mapClickMouseButton = "LeftButton"
        end
        if MapzerothDB.minimap.hide == nil then
            MapzerothDB.minimap.hide = false
        end

        -- Initialize minimap button
        addon:InitializeMinimapButton()
        -- Initialize standalone GPS navigator
        addon:InitializeGPSNavigator()
        -- Initialize settings panel
        addon:InitializeSettingsPanel()
        print("[Mapzeroth] Loaded successfully! Type /mapzeroth help for commands.")
    elseif event == "BAG_UPDATE_DELAYED" then
        addon.bagsFullyLoaded = true

        if addon.DEBUG then
            print("[Mapzeroth] DEBUG: Bags fully loaded, all travel items should be available")
        end

        frame:UnregisterEvent("BAG_UPDATE_DELAYED")
    elseif event == "HEARTHSTONE_BOUND" then
        if addon.DEBUG then
            print("[Mapzeroth] DEBUG: HEARTHSTONE_BOUND event fired!")
        end
        addon:UpdateHearthstoneLocation()
    elseif event == "SUPER_TRACKING_CHANGED" then
        if addon.DEBUG then
            print("[Mapzeroth] DEBUG: SUPER_TRACKING_CHANGED event fired!")
        end
        addon:UpdateSuperTrackingMap()
    elseif event == "CALENDAR_UPDATE_EVENT_LIST" then
        addon:OnCalendarReady()
    elseif event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_REGEN_ENABLED" then
        addon:TryRestoreCityCloak()
    end
end)
