local addonName, addon = ...

-- The game's in-world waypoint marker (SuperTrackedFrame, Blizzard_QuestNavigation) shows "321 yd" under the pin, in
-- every client language. With the "units" setting on metres it shows metres instead. Only the marker's text is
-- changed, after the game has written it; the game's own fields are never touched.

local frame = SuperTrackedFrame
if not (frame and frame.UpdateDistanceText and frame.DistanceText and C_Navigation and C_Navigation.GetDistance) then
    return
end

local L = addon.L
local METRES_PER_YARD = 0.9144

local function metresText(yards)
    local metres = math.floor(yards * METRES_PER_YARD + 0.5)
    if metres < 1000 then return L["PIN_METRES"]:format(metres) end
    return L["PIN_KILOMETRES"]:format(metres / 1000)
end

-- The game's own text, as UpdateDistanceText writes it (its GetDistanceString is local).
local function yardsText(yards)
    local d = math.floor(yards + 0.5)
    return IN_GAME_NAVIGATION_RANGE:format(d < 1000 and tostring(d) or AbbreviateNumbers(d))
end

local function rewrite(self, metres)
    if self.isClamped then return end
    local yards = C_Navigation.GetDistance()
    if not yards or (issecretvalue and issecretvalue(yards)) then return end   -- Retail: leave a secret distance alone
    local text = metres and metresText(yards) or yardsText(yards)
    if self.DistanceText:GetText() ~= text then self.DistanceText:SetText(text) end
end

-- The game rewrites its text only when the yards change, so ours goes back on every update.
hooksecurefunc(frame, "UpdateDistanceText", function(self)
    if addon.Options:Get("units") == "metres" then rewrite(self, true) end
end)

-- Back to yards at once when the setting changes (the game wouldn't rewrite until the yards next change).
addon.Options:OnChange(function(key)
    if key == "units" and frame:IsShown() then rewrite(frame, addon.Options:Get("units") == "metres") end
end)
