local addonName, addon = ...

-- The button on the minimap's rim. Left-click opens or closes the window (the map with the panel beside it when docked,
-- the panel alone when popped out: Panel:Toggle); right-click opens the settings. Drag it round the rim: where it was
-- left is kept as an angle in the saved variables. Its look is Theme:MinimapButton's.

local MinimapButton = {}
addon.MinimapButton = MinimapButton

local L = addon.L
local Theme = addon.Theme

local ICON = "Interface\\AddOns\\" .. addonName .. "\\Media\\Logo"       -- the logo (Media/Logo.tga; the folder is whatever this addon is called)
local DEFAULT_ANGLE = 215                                    -- degrees, counter-clockwise from the right: lower left of the rim
local MARGIN = 5                                             -- how far outside the minimap's edge the button's centre sits

-- Which corners of a minimap are round (the game's GetMinimapShape, which minimap-reshaping addons define):
-- quadrants 1..4 are top-right, top-left, bottom-right, bottom-left. A square corner sends the button to the corner.
local ROUND = { true, true, true, true }
local SHAPES = {
    ROUND = ROUND, SQUARE = { false, false, false, false },
    ["CORNER-TOPRIGHT"] = { false, true, true, true }, ["CORNER-TOPLEFT"] = { true, false, true, true },
    ["CORNER-BOTTOMRIGHT"] = { true, true, false, true }, ["CORNER-BOTTOMLEFT"] = { true, true, true, false },
    ["SIDE-TOP"] = { false, false, true, true }, ["SIDE-BOTTOM"] = { true, true, false, false },
    ["SIDE-LEFT"] = { false, true, false, true }, ["SIDE-RIGHT"] = { true, false, true, false },
}

local button

local function saved(create)
    if not MapzerothRebuildDB then
        if not create then return nil end
        MapzerothRebuildDB = {}
    end
    if not MapzerothRebuildDB.minimapButton and create then MapzerothRebuildDB.minimapButton = {} end
    return MapzerothRebuildDB.minimapButton
end

function MinimapButton:GetAngle()
    local data = saved(false)
    return data and tonumber(data.angle) or DEFAULT_ANGLE
end

-- Where on the rim `degrees` is, as an offset from the minimap's centre.
function MinimapButton.Offset(degrees, halfWidth, halfHeight, shape)
    local radians = math.rad(degrees)
    local x, y = math.cos(radians), math.sin(radians)
    local quadrant = 1
    if x < 0 then quadrant = quadrant + 1 end
    if y < 0 then quadrant = quadrant + 2 end
    local w, h = halfWidth + MARGIN, halfHeight + MARGIN
    if (SHAPES[shape] or ROUND)[quadrant] then return x * w, y * h end
    -- A square corner: out along the same direction, but no further than the box.
    local reach = math.sqrt(2 * w * w) - 10
    return math.max(-w, math.min(x * reach, w)), math.max(-h, math.min(y * reach, h))
end

function MinimapButton:Place()
    if not button then return end
    local x, y = MinimapButton.Offset(self:GetAngle(), (Minimap:GetWidth() or 140) / 2, (Minimap:GetHeight() or 140) / 2,
        GetMinimapShape and GetMinimapShape() or "ROUND")
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function MinimapButton:SetAngle(degrees)
    saved(true).angle = degrees % 360
    self:Place()
end

-- While dragging: the angle from the minimap's centre to the cursor.
local function follow()
    local mx, my = Minimap:GetCenter()
    local scale = Minimap:GetEffectiveScale()
    local cx, cy = GetCursorPosition()
    if not (mx and my and scale and scale > 0) then return end
    local atan2 = math.atan2 or function(y, x) return math.atan(y / x) + (x < 0 and math.pi or 0) end
    MinimapButton:SetAngle(math.deg(atan2(cy / scale - my, cx / scale - mx)))
end

function MinimapButton:Tooltip()
    Theme:ShowTooltip(button, {
        { L["PANEL_TITLE"], "title" },
        { L["MINIMAP_TIP_TOGGLE"], "body" },
        { L["MINIMAP_TIP_SETTINGS"], "body" },
        { L["MINIMAP_TIP_DRAG"], "dim" },
    })
end

-- Shown unless the player has hidden it (Options).
function MinimapButton:Apply()
    if button then button:SetShown(not addon.Options:Get("hideMinimapButton")) end
end

-- Builds the button (once). False where there is no minimap to put it on.
function MinimapButton:Init()
    if button then return true end
    if not Minimap then return false end
    button = Theme:MinimapButton(Minimap, "MapzerothRebuildMinimapButton", ICON)
    self.button = button
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetScript("OnClick", function(_, mouse)
        if mouse == "RightButton" then
            if not addon.OptionsPanel:Open() then print(L["CMD_NO_SETTINGS"]) end
        else
            addon.Panel:Toggle()
        end
    end)
    button:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", follow)
        Theme:HideTooltip(self)
    end)
    button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    button:SetScript("OnEnter", function() if not button:GetScript("OnUpdate") then MinimapButton:Tooltip() end end)
    button:SetScript("OnLeave", function() Theme:HideTooltip(button) end)
    self:Place()
    self:Apply()
    addon.Options:OnChange(function(key) if key == "hideMinimapButton" then MinimapButton:Apply() end end)
    return true
end
