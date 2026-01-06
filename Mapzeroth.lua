-- Mapzeroth.lua
-- Main addon initialization
local addonName, addon = ...

-- Create the addon namespace
_G["Mapzeroth"] = addon

addon.DEBUG = false

-- Simple load confirmation
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("HEARTHSTONE_BOUND")
frame:RegisterEvent("SUPER_TRACKING_CHANGED")
frame:RegisterEvent("CALENDAR_UPDATE_EVENT_LIST")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        print("[Mapzeroth] Loaded successfully! Type /mapzeroth help for commands.")

        -- Initialize minimap button
        addon:InitializeMinimapButton()
        -- Initialize settings panel
        addon:InitializeSettingsPanel()

        -- Prime the item cache by calling GetAvailableTravelAbilities once
        -- This triggers the client to query item data, so subsequent calls work properly
        C_Timer.After(1, function()
            if addon.GetAvailableTravelAbilities then
                addon:GetAvailableTravelAbilities()
                if addon.DEBUG then
                    print("[Mapzeroth] DEBUG: Item cache primed")
                end
            end
        end)
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
    end
end)
