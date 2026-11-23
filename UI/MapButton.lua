local addonName, addon = ...

-- The button in the world map's top-left corner. Left-click shows or hides the panel (Panel:Toggle: it never opens or
-- closes the map itself), right-click opens the settings. Its look is Theme:MinimapButton's.
-- Other addons put their buttons in that corner too (OneForAll, RareScanner), and the game its floor dropdown on maps
-- with floors: ours goes under the lowest of whatever is shown there, found by position, no list of names. It is
-- placed from the map's canvas, never from another addon's button, so an addon that stacks itself under ours (as
-- OneForAll does) can't make an anchor loop; one that hangs from ours is left out when we look.

local MapButton = {}
addon.MapButton = MapButton

local L = addon.L
local Theme = addon.Theme

local ICON = "Interface\\AddOns\\" .. addonName .. "\\Media\\Logo"
local INSET = 6                    -- from the canvas's top-left corner when nothing else is there
local GAP = 2                      -- under another button
-- What counts as a button in the corner, in the canvas's units: its left edge near the canvas's left, its top in the
-- corner's upper band (a little above the canvas too), button-sized. The floor dropdown is wide but short; under one
-- that wide ours keeps to the corner's inset rather than centring.
local NEAR_LEFT, ABOVE, BAND = 50, 12, 260
local MIN_SIZE, MAX_WIDTH, MAX_HEIGHT, ROUND_WIDTH = 12, 240, 60, 60

local button

-- Whether `f` is placed from `target`, however indirectly.
local function hangsFrom(f, target, depth)
    if f == target then return true end
    depth = depth or 0
    if type(f) ~= "table" or depth > 10 or not f.GetNumPoints then return false end
    if f.IsForbidden and f:IsForbidden() then return false end
    for i = 1, f:GetNumPoints() or 0 do
        local _, rel = f:GetPoint(i)
        if rel and hangsFrom(rel, target, depth + 1) then return true end
    end
    return false
end

-- Where `own` goes, as an offset from `canvas`'s top-left corner in its own units: under the lowest of `candidates`
-- shown in the corner (centred under a round one), or in the corner itself. Each candidate under pcall: whatever
-- another addon's frame does, opening the map never errors over it.
function MapButton.Slot(canvas, candidates, own)
    local cs = canvas:GetEffectiveScale() or 1
    local cl, ct = canvas:GetLeft(), canvas:GetTop()
    if not (cl and ct) then return INSET, -INSET end
    cl, ct = cl * cs, ct * cs
    local lowBottom, lowCentre
    for _, f in ipairs(candidates) do
        pcall(function()
            if f == own or type(f) ~= "table" or not f.IsVisible then return end
            if f.IsForbidden and f:IsForbidden() then return end
            if not f:IsVisible() or hangsFrom(f, own) then return end
            local l, t, r, b = f:GetLeft(), f:GetTop(), f:GetRight(), f:GetBottom()
            if not (l and t and r and b) then return end
            local s = f:GetEffectiveScale() or 1
            l, t, r, b = l * s, t * s, r * s, b * s
            local w, h, down = (r - l) / cs, (t - b) / cs, (ct - t) / cs
            if w < MIN_SIZE or h < MIN_SIZE or w > MAX_WIDTH or h > MAX_HEIGHT then return end
            if math.abs(l - cl) / cs > NEAR_LEFT or down < -ABOVE or down > BAND then return end
            if not lowBottom or b < lowBottom then
                lowBottom, lowCentre = b, w <= ROUND_WIDTH and (l + r) / 2 or nil
            end
        end)
    end
    if not lowBottom then return INSET, -INSET end
    local os = own:GetEffectiveScale() or 1
    local left = lowCentre and lowCentre - (own:GetWidth() or 0) * os / 2 or cl + INSET * os
    return (left - cl) / os, (lowBottom - GAP * os - ct) / os
end

local function canvasOf(map) return type(map.ScrollContainer) == "table" and map.ScrollContainer or map end

-- Every frame that might be a button in the corner: the map's overlay frames and children, and the canvas's children.
local function candidates(map)
    local list = {}
    if type(map.overlayFrames) == "table" then
        for _, f in ipairs(map.overlayFrames) do list[#list + 1] = f end
    end
    for _, f in ipairs({ map:GetChildren() }) do list[#list + 1] = f end
    local canvas = canvasOf(map)
    if canvas ~= map and canvas.GetChildren then
        for _, f in ipairs({ canvas:GetChildren() }) do list[#list + 1] = f end
    end
    return list
end

function MapButton:Place()
    local map = WorldMapFrame
    if not (button and map and button:IsShown()) then return end
    local canvas = canvasOf(map)
    local x, y = MapButton.Slot(canvas, candidates(map), button)
    button:ClearAllPoints()
    button:SetPoint("TOPLEFT", canvas, "TOPLEFT", x, y)
end

-- Placed when the map opens or changes zone (the floor dropdown comes and goes with the map), and again a moment
-- later: other addons place their buttons on the same events, some after a short delay (OneForAll's is 0.2 s).
local function placeSoon()
    MapButton:Place()
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function() MapButton:Place() end)
        C_Timer.After(0.4, function() MapButton:Place() end)
    end
end

local function click(mouse)
    if mouse == "RightButton" then
        local ok, why = addon.OptionsPanel:Open()
        if not ok then print(L[why == "combat" and "CMD_SETTINGS_COMBAT" or "CMD_NO_SETTINGS"]) end
    else
        addon.Panel:Toggle()
    end
end

function MapButton:Apply()
    if not button then return end
    button:SetShown(not addon.Options:Get("hideMapButton"))
    if button:IsShown() and WorldMapFrame and WorldMapFrame:IsShown() then placeSoon() end
end

-- Builds the button (once), on the map. False while the map isn't loaded.
function MapButton:Init()
    if button then return true end
    local map = WorldMapFrame
    if not map then return false end
    button = Theme:MinimapButton(map, "MapzerothRebuildMapButton", ICON)
    self.button = button
    -- A little larger than on the minimap, to match the other buttons in the map's corner (user, 2026-11-21).
    button:SetScale(1.2)
    -- Above the map's canvas and pins, with the game's own overlay buttons.
    button:SetFrameStrata(map:GetFrameStrata() == "FULLSCREEN" and "FULLSCREEN" or "HIGH")
    button:SetFrameLevel(510)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetScript("OnClick", function(_, mouse) click(mouse) end)
    button:SetScript("OnEnter", function()
        Theme:ShowTooltip(button, {
            { L["PANEL_TITLE"], "title" },
            { L["MINIMAP_TIP_TOGGLE"], "body" },
            { L["MINIMAP_TIP_SETTINGS"], "body" },
        })
    end)
    button:SetScript("OnLeave", function() Theme:HideTooltip(button) end)
    map:HookScript("OnShow", placeSoon)
    if map.OnMapChanged then hooksecurefunc(map, "OnMapChanged", function() if map:IsShown() then placeSoon() end end) end
    addon.Options:OnChange(function(key) if key == "hideMapButton" then MapButton:Apply() end end)
    self:Apply()
    return true
end
