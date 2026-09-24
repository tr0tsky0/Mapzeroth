local addonName, addon = ...

-- The addon's shared table, for the development tools addon (MapzerothDataTools). It is not part of this
-- addon: it reads what the engine knows through this global and owns every command that reports on it.
-- Nothing here writes to the chat window on its own.
MapzerothAddon = addon

local L = addon.L

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("HEARTHSTONE_BOUND")
frame:RegisterEvent("TAXIMAP_OPENED")
frame:RegisterEvent("FACTION_STANDING_CHANGED")
frame:RegisterEvent("UI_INFO_MESSAGE")
pcall(frame.RegisterEvent, frame, "USER_WAYPOINT_UPDATED")
frame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        -- The world map may load after us; attach the panel when it does.
        if (...) == "Blizzard_WorldMap" then addon.Panel:Init() end
        return
    elseif event == "TAXIMAP_OPENED" then
        addon.FlightKnowledge:OnTaxiMapOpened()
        return
    elseif event == "FACTION_STANDING_CHANGED" then
        -- A standing tier crossing can change vendor/flight discounts; see FlightKnowledge's
        -- own doc comment for why this forgets rather than tries to guess which one changed.
        addon.FlightKnowledge:OnFactionChanged()
        return
    elseif event == "USER_WAYPOINT_UPDATED" then
        addon.Panel:OnWaypointChanged()
        return
    elseif event == "UI_INFO_MESSAGE" then
        -- "New flight path discovered": we aren't told which, so forget the "not found"s.
        local _, message = ...
        if ERR_NEWTAXIPATH and message == ERR_NEWTAXIPATH then
            addon.FlightKnowledge:ForgetNotFound()
        end
        return
    end
    if event == "HEARTHSTONE_BOUND" then
        -- You bind at an inn, so this is where the inn is.
        local mapID = C_Map.GetBestMapForUnit("player")
        local pos = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
        if pos then
            local x, y = pos:GetXY()
            addon:SaveBind(mapID, x, y, GetBindLocation and GetBindLocation() or nil)
        end
        return
    end
    addon.World:Build()
    addon.FlightKnowledge:Load()
    addon.Theme:Init(addon.Options:Default("theme"))
    addon.OptionsPanel:Register()
    addon.Panel:Init()
    -- Which flight was chosen: the navigator wants to know where it goes (a post-hook: it changes nothing).
    if type(TakeTaxiNode) == "function" and not addon.takeTaxiHooked then
        addon.takeTaxiHooked = true
        hooksecurefunc("TakeTaxiNode", function(slot)
            addon.Navigation:OnTakeTaxi(addon.FlightKnowledge:StopsForSlot(slot), GetTime())
        end)
    end
end)

-- What a player can type. (Development commands are MapzerothDataTools' /mzr.)
SLASH_MAPZEROTH1 = "/mapzeroth"
SLASH_MAPZEROTH2 = "/mz"
SlashCmdList["MAPZEROTH"] = function(msg)
    local cmd = msg:match("^(%S+)")
    if cmd == "settings" then
        if not addon.OptionsPanel:Open() then print(L["CMD_NO_SETTINGS"]) end
    elseif cmd == "ui" then
        addon.Panel:Toggle()
    else
        print(L["CMD_HELP"])
    end
end
