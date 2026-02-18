-- GPSNavigator.lua
-- Standalone draggable GPS navigator for active route guidance.
local addonName, addon = ...

local GPS_WIDTH = 320
local GPS_HEIGHT = 150
local GPS_UPDATE_INTERVAL = 0.1
local STEP_COMPLETION_DISTANCE_YARDS = 55

local COLOURS = {
    bg = {0.04, 0.04, 0.04, 0.9},
    border = {0.3, 0.3, 0.3, 1},
    text = {1, 1, 1, 1},
    textSecondary = {0.7, 0.7, 0.7, 1},
    accent = {0.2, 0.5, 0.9, 1}
}

local GPS_MODIFIERS = {
    "ALT",
    "CTRL",
    "SHIFT"
}

local GPS_MOUSE_BUTTONS = {
    LeftButton = "Left Click",
    RightButton = "Right Click"
}

local gpsFrame = nil
local gpsElapsed = 0
local lastActionButtonDebugKey = nil

local function GPSDebugPrint(message)
    if addon.DEBUG then
        print("[Mapzeroth][GPS DEBUG] " .. message)
    end
end

local function Atan2(y, x)
    if math.atan2 then
        return math.atan2(y, x)
    end

    if x > 0 then
        return math.atan(y / x)
    elseif x < 0 and y >= 0 then
        return math.atan(y / x) + math.pi
    elseif x < 0 and y < 0 then
        return math.atan(y / x) - math.pi
    elseif x == 0 and y > 0 then
        return math.pi / 2
    elseif x == 0 and y < 0 then
        return -math.pi / 2
    end

    return 0
end

local function BuildStepMacro(stepData)
    if stepData.spellID then
        local spellInfo = C_Spell.GetSpellInfo(stepData.spellID)
        if spellInfo then
            return string.format("/cast %s", spellInfo.name)
        end
        return string.format("/cast %d", stepData.spellID)
    end

    if stepData.itemID then
        local itemName = C_Item.GetItemInfo(stepData.itemID)
        if itemName then
            return string.format("/use %s", itemName)
        end
        return string.format("/use %d", stepData.itemID)
    end

    return nil
end

local function GetStepActionIcon(stepData)
    if not stepData then
        return nil
    end

    if stepData.spellID then
        local spellInfo = C_Spell.GetSpellInfo(stepData.spellID)
        if spellInfo and spellInfo.iconID then
            return spellInfo.iconID
        end
    end

    if stepData.itemID then
        local itemIcon = C_Item.GetItemIconByID(stepData.itemID)
        if itemIcon then
            return itemIcon
        end
    end

    return addon.TRAVEL_ICONS[stepData.method] or addon.TRAVEL_ICONS.walk
end

local function GetStepActionText(stepData)
    if not stepData then
        return "No active step"
    end

    if stepData.abilityName then
        if stepData.destinationName then
            return string.format("Use %s to %s", stepData.abilityName, stepData.destinationName)
        end
        return string.format("Use %s", stepData.abilityName)
    end

    local methodPrefix = addon.METHOD_DISPLAY_TEXT[stepData.method] or "Go to"
    return string.format("%s %s", methodPrefix, stepData.destination or "destination")
end

local function ResolveNodeTarget(nodeID)
    if not nodeID then
        return nil
    end

    local node = addon.TravelGraph:GetNodeByID(nodeID)
    if not node or not node.mapID or not node.x or not node.y then
        return nil
    end

    return {
        mapID = node.mapID,
        x = node.x,
        y = node.y,
        name = node.displayName or node.name or "Target"
    }
end

local function ResolveStepTarget(stepData)
    if not stepData then
        return nil, "No active step"
    end

    if stepData.method == "walk" or stepData.method == "fly" then
        if stepData.nodeID == "_WAYPOINT_DESTINATION" and stepData.waypointData then
            return {
                mapID = stepData.waypointData.mapID,
                x = stepData.waypointData.x,
                y = stepData.waypointData.y,
                name = "Waypoint"
            }
        end
        return ResolveNodeTarget(stepData.nodeID)
    end

    if stepData.nodeID and stepData.nodeID ~= "_WAYPOINT_DESTINATION" then
        return ResolveNodeTarget(stepData.nodeID)
    end

    return nil, "Complete current step"
end

local function GetWorldPosition(mapID, x, y)
    if not mapID or not x or not y then
        return nil
    end

    local mapPos = CreateVector2D(x, y)
    if not mapPos then
        return nil
    end

    local _, worldPos = C_Map.GetWorldPosFromMapPos(mapID, mapPos)
    return worldPos
end

local function GetDistanceAndHeading(fromMap, fromX, fromY, toMap, toX, toY)
    if not fromMap or not fromX or not fromY or not toMap or not toX or not toY then
        return nil, nil
    end

    local fromWorld = GetWorldPosition(fromMap, fromX, fromY)
    local toWorld = GetWorldPosition(toMap, toX, toY)

    local dx
    local dy

    if fromWorld and toWorld then
        dx = toWorld.x - fromWorld.x
        dy = toWorld.y - fromWorld.y
    elseif fromMap == toMap then
        dx = (toX - fromX) * addon.MAP_SCALE
        dy = (toY - fromY) * addon.MAP_SCALE
    else
        return nil, nil
    end

    local distance = math.sqrt(dx * dx + dy * dy)
    local heading = Atan2(dy, dx)
    return distance, heading
end

local function IsModifierDown(modifier)
    if modifier == "ALT" then
        return IsAltKeyDown()
    elseif modifier == "CTRL" then
        return IsControlKeyDown()
    elseif modifier == "SHIFT" then
        return IsShiftKeyDown()
    end
    return false
end

local function FormatDistance(distance)
    if not distance then
        return "Target on another map"
    end

    if distance >= 1000 then
        return string.format("%.1f km", distance / 1000)
    end

    return string.format("%.0f yd", distance)
end

function addon:GetMapClickModifier()
    local modifier = MapzerothDB and MapzerothDB.settings and MapzerothDB.settings.mapClickModifier or "ALT"
    for _, value in ipairs(GPS_MODIFIERS) do
        if value == modifier then
            return modifier
        end
    end
    return "ALT"
end

function addon:GetMapClickMouseButton()
    local button = MapzerothDB and MapzerothDB.settings and MapzerothDB.settings.mapClickMouseButton or "LeftButton"
    if GPS_MOUSE_BUTTONS[button] then
        return button
    end
    return "LeftButton"
end

function addon:GetMapClickBindingLabel()
    local modifier = addon:GetMapClickModifier()
    local button = addon:GetMapClickMouseButton()
    return string.format("%s + %s", modifier, GPS_MOUSE_BUTTONS[button])
end

function addon:CycleMapClickModifier()
    local current = addon:GetMapClickModifier()
    local currentIndex = 1
    for i, value in ipairs(GPS_MODIFIERS) do
        if value == current then
            currentIndex = i
            break
        end
    end

    local nextIndex = currentIndex + 1
    if nextIndex > #GPS_MODIFIERS then
        nextIndex = 1
    end

    MapzerothDB.settings.mapClickModifier = GPS_MODIFIERS[nextIndex]
end

function addon:CycleMapClickMouseButton()
    local order = {"LeftButton", "RightButton"}
    local current = addon:GetMapClickMouseButton()
    local currentIndex = 1

    for i, value in ipairs(order) do
        if value == current then
            currentIndex = i
            break
        end
    end

    local nextIndex = currentIndex + 1
    if nextIndex > #order then
        nextIndex = 1
    end

    MapzerothDB.settings.mapClickMouseButton = order[nextIndex]
end

local function AutoAdvanceStep(step, location, target, distance)
    if not step or not location then
        return
    end

    if (step.method == "walk" or step.method == "fly") and distance and distance <= STEP_COMPLETION_DISTANCE_YARDS then
        addon:CompleteRouteStep()
        return
    end

    local fromNode = ResolveNodeTarget(step.fromNodeID)

    if step.itemID or step.spellID then
        if fromNode and location.mapID ~= fromNode.mapID then
            addon:CompleteRouteStep()
            return
        end

        return
    end

    if step.method ~= "walk" and step.method ~= "fly" and not step.itemID and not step.spellID then
        if fromNode and location.mapID ~= fromNode.mapID then
            addon:CompleteRouteStep()
            return
        end

        if target and distance and distance <= STEP_COMPLETION_DISTANCE_YARDS then
            addon:CompleteRouteStep()
            return
        end
    end
end

local function UpdateActionButton(step)
    if not gpsFrame then
        return
    end

    local button = gpsFrame.actionButton
    local arrowDragButton = gpsFrame.arrowDragButton
    local statusText = gpsFrame.statusText
    local macroText = step and BuildStepMacro(step)

    local function AnchorStatusTo(target, yOffset)
        if not statusText or not target then
            return
        end
        statusText:ClearAllPoints()
        statusText:SetPoint("TOP", target, "BOTTOM", 0, yOffset or -1)
        statusText:SetPoint("LEFT", gpsFrame, "LEFT", 10, 0)
        statusText:SetPoint("RIGHT", gpsFrame, "RIGHT", -10, 0)
    end

    if step and macroText then
        button.icon:SetTexture(GetStepActionIcon(step))

        if InCombatLockdown() then
            local combatKey = "combat_hide"
            if lastActionButtonDebugKey ~= combatKey then
                GPSDebugPrint("Action button hidden (combat lockdown)")
                lastActionButtonDebugKey = combatKey
            end
            button:Hide()
            gpsFrame.arrow:Show()
            if arrowDragButton then
                arrowDragButton:Show()
            end
            AnchorStatusTo(gpsFrame.arrow, 5)
            return
        end

        button:SetAttribute("type1", "macro")
        button:SetAttribute("macrotext1", macroText)
        button.stepNum = gpsFrame.currentStepIndex
        local showKey = string.format("show:%s:%s", tostring(button.stepNum), tostring(macroText))
        if lastActionButtonDebugKey ~= showKey then
            GPSDebugPrint(string.format("Action button show step=%s type=%s macro=%s",
                tostring(button.stepNum), tostring(button:GetAttribute("type1")), tostring(button:GetAttribute("macrotext1"))))
            lastActionButtonDebugKey = showKey
        end
        button:Show()
        gpsFrame.arrow:Hide()
        if arrowDragButton then
            arrowDragButton:Hide()
        end
        AnchorStatusTo(button, -6)
        return
    end

    if InCombatLockdown() then
        local combatKey = "combat_hide"
        if lastActionButtonDebugKey ~= combatKey then
            GPSDebugPrint("Action button hidden (combat lockdown)")
            lastActionButtonDebugKey = combatKey
        end
        button:Hide()
        gpsFrame.arrow:Show()
        if arrowDragButton then
            arrowDragButton:Show()
        end
        AnchorStatusTo(gpsFrame.arrow, 5)
        return
    end

    button:SetAttribute("type1", nil)
    button:SetAttribute("macrotext1", nil)
    button.stepNum = nil
    button.icon:SetTexture(nil)
    if lastActionButtonDebugKey ~= "hide:no_macro" then
        GPSDebugPrint("Action button hidden (no macro step)")
        lastActionButtonDebugKey = "hide:no_macro"
    end
    button:Hide()
    gpsFrame.arrow:Show()
    if arrowDragButton then
        arrowDragButton:Show()
    end
    AnchorStatusTo(gpsFrame.arrow, 5)
end

local function UpdateGPS()
    if not gpsFrame then
        return
    end

    local steps, currentStep = addon:GetRouteNavigationState()
    gpsFrame.currentStepIndex = currentStep

    if not steps or #steps == 0 or not currentStep or currentStep == 0 then
        gpsFrame.statusText:SetText("No active route")
        gpsFrame.detailText:SetText("Run navigation to start")
        gpsFrame.distanceText:SetText("")
        gpsFrame.arrow:SetAlpha(0.25)
        UpdateActionButton(nil)
        return
    end

    if currentStep > #steps then
        gpsFrame.statusText:SetText("Route completed")
        gpsFrame.detailText:SetText("All steps done")
        gpsFrame.distanceText:SetText("")
        gpsFrame.arrow:SetAlpha(0.25)
        UpdateActionButton(nil)
        return
    end

    local step = steps[currentStep]
    local location = addon:GetPlayerLocation()
    local target, reason = ResolveStepTarget(step)

    gpsFrame.statusText:SetText(string.format("Step %d/%d", currentStep, #steps))
    gpsFrame.detailText:SetText(GetStepActionText(step))

    UpdateActionButton(step)

    if not location then
        gpsFrame.distanceText:SetText("Player location unavailable")
        gpsFrame.arrow:SetAlpha(0.25)
        return
    end

    if not target then
        gpsFrame.distanceText:SetText(reason or "Complete current step")
        gpsFrame.arrow:SetAlpha(0.25)
        AutoAdvanceStep(step, location, nil, nil)
        return
    end

    local distance, heading = GetDistanceAndHeading(location.mapID, location.x, location.y, target.mapID, target.x, target.y)

    gpsFrame.distanceText:SetText(string.format("%s | %s", target.name, FormatDistance(distance)))
    AutoAdvanceStep(step, location, target, distance)

    local refreshedSteps, refreshedCurrent = addon:GetRouteNavigationState()
    if refreshedCurrent ~= currentStep then
        return
    end

    if not distance or not heading then
        gpsFrame.arrow:SetAlpha(0.25)
        return
    end

    local facing = GetPlayerFacing()
    if not facing then
        gpsFrame.arrow:SetAlpha(0.25)
        return
    end

    if step.itemID or step.spellID then
        gpsFrame.arrow:SetAlpha(0.25)
        return
    end

    gpsFrame.arrow:SetAlpha(1)
    gpsFrame.arrow:SetRotation(heading - facing)
end

local function SaveGPSPosition(frame)
    MapzerothDB.settings.gpsFramePoint = {
        point = frame.point or "CENTER",
        relativePoint = frame.relativePoint or "CENTER",
        x = math.floor(frame.xOfs or 0),
        y = math.floor(frame.yOfs or 0)
    }
end

local function ApplyGPSPosition(frame)
    local pos = MapzerothDB.settings.gpsFramePoint
    frame:ClearAllPoints()

    if pos and pos.point and pos.relativePoint and pos.x and pos.y then
        frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 220)
    end
end

local function StopMovingAndPersist(frame)
    frame:StopMovingOrSizing()
    local point, _, relativePoint, x, y = frame:GetPoint(1)
    frame.point = point
    frame.relativePoint = relativePoint
    frame.xOfs = x
    frame.yOfs = y
    SaveGPSPosition(frame)
end

function addon:ApplyGPSScale(scale)
    if gpsFrame then
        gpsFrame:SetScale(scale or 1)
    end
end

function addon:ShowGPSNavigator(steps, totalTime)
    if not gpsFrame then
        addon:InitializeGPSNavigator()
    end

    addon:BeginRouteNavigation(steps, totalTime)

    if gpsFrame then
        gpsFrame:Show()
        UpdateGPS()
    end
end

local function TryGetWorldMapClickPosition()
    if not WorldMapFrame or not WorldMapFrame.ScrollContainer then
        return nil, nil, nil
    end

    local mapID = WorldMapFrame:GetMapID()
    if not mapID then
        return nil, nil, nil
    end

    local x, y
    if WorldMapFrame.ScrollContainer.GetNormalizedCursorPosition then
        x, y = WorldMapFrame.ScrollContainer:GetNormalizedCursorPosition()
    end

    if not x or not y then
        return nil, nil, nil
    end

    if x < 0 or x > 1 or y < 0 or y > 1 then
        return nil, nil, nil
    end

    return mapID, x, y
end

function addon:HandleConfiguredMapClick(button)
    if not WorldMapFrame or not WorldMapFrame:IsShown() then
        return
    end

    if button ~= addon:GetMapClickMouseButton() then
        return
    end

    if not IsModifierDown(addon:GetMapClickModifier()) then
        return
    end

    local mapID, x, y = TryGetWorldMapClickPosition()
    if not mapID then
        return
    end

    local success = pcall(function()
        C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapID, x, y))
    end)

    if not success then
        return
    end

    if C_SuperTrack then
        C_SuperTrack.SetSuperTrackedUserWaypoint(true)
    end

    addon:UpdateSuperTrackingMap()
    addon:FindRoute("_WAYPOINT_DESTINATION")
end

function addon:InitializeMapClickRouting()
    if addon.mapClickHooked then
        return
    end

    if WorldMapFrame and WorldMapFrame.ScrollContainer then
        WorldMapFrame.ScrollContainer:HookScript("OnMouseUp", function(_, button)
            addon:HandleConfiguredMapClick(button)
        end)
        addon.mapClickHooked = true
        return
    end

    if not addon.mapClickRetryFrame then
        addon.mapClickRetryFrame = CreateFrame("Frame")
    end

    addon.mapClickRetryFrame:SetScript("OnUpdate", function(self)
        if WorldMapFrame and WorldMapFrame.ScrollContainer then
            WorldMapFrame.ScrollContainer:HookScript("OnMouseUp", function(_, button)
                addon:HandleConfiguredMapClick(button)
            end)
            addon.mapClickHooked = true
            self:SetScript("OnUpdate", nil)
        end
    end)
end

function addon:InitializeGPSNavigator()
    if gpsFrame then
        return gpsFrame
    end

    local frame = CreateFrame("Frame", "MapzerothGPSNavigatorFrame", UIParent, "BackdropTemplate")
    frame:SetSize(GPS_WIDTH, GPS_HEIGHT)
    frame:SetFrameStrata("BACKGROUND")
    frame:SetFrameLevel(1)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(false)

    local arrow = frame:CreateTexture(nil, "ARTWORK")
    arrow:SetTexture("Interface\\MINIMAP\\ROTATING-MINIMAPARROW")
    arrow:SetSize(76, 76)
    arrow:SetPoint("TOP", frame, "TOP", 0, -8)

    local arrowDragButton = CreateFrame("Frame", nil, frame)
    arrowDragButton:SetPoint("TOP", frame, "TOP", 0, -8)
    arrowDragButton:SetSize(76, 76)
    arrowDragButton:EnableMouse(true)
    arrowDragButton:RegisterForDrag("LeftButton")
    arrowDragButton:SetScript("OnDragStart", function()
        frame:StartMoving()
    end)
    arrowDragButton:SetScript("OnDragStop", function()
        StopMovingAndPersist(frame)
    end)

    local actionButton = CreateFrame("Button", nil, frame, "SecureActionButtonTemplate,BackdropTemplate")
    actionButton:SetPoint("TOP", frame, "TOP", 0, -8)
    actionButton:SetSize(56, 56)
    actionButton:RegisterForClicks("LeftButtonDown", "LeftButtonUp")
    actionButton:RegisterForDrag("LeftButton")
    actionButton:SetMovable(false)
    actionButton:Hide()

    local actionIcon = actionButton:CreateTexture(nil, "ARTWORK")
    actionIcon:SetTexCoord(0, 1, 0, 1)
    actionIcon:SetVertexColor(0.95, 0.95, 0.95, 1)
    actionButton.icon = actionIcon

    local actionBorder = actionButton:CreateTexture(nil, "OVERLAY", nil, 1)
    actionBorder:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    actionButton.border = actionBorder

    local actionHover = actionButton:CreateTexture(nil, "OVERLAY", nil, 2)
    actionHover:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    actionHover:SetBlendMode("ADD")
    actionHover:SetAlpha(0.38)
    actionHover:Hide()
    actionButton.hover = actionHover

    local actionPressed = actionButton:CreateTexture(nil, "OVERLAY", nil, 3)
    actionPressed:SetTexture("Interface\\Buttons\\WHITE8x8")
    actionPressed:SetBlendMode("BLEND")
    actionPressed:SetVertexColor(0, 0, 0, 0.28)
    actionPressed:Hide()
    actionButton.pressed = actionPressed

    local function ApplyActionButtonLayout()
        local size = actionButton:GetWidth() or 56
        local iconInset = math.max(3, math.floor(size * 0.06 + 0.5))
        local borderOutset = math.max(8, math.floor(size * 0.22 + 0.5))
        local hoverOutset = math.max(2, math.floor(size * 0.04 + 0.5))
        local iconSize = math.max(1, size - (iconInset * 2))

        actionIcon:ClearAllPoints()
        actionIcon:SetSize(iconSize, iconSize)
        actionIcon:SetPoint("CENTER", actionButton, "CENTER", 0, 0)

        actionBorder:ClearAllPoints()
        actionBorder:SetPoint("TOPLEFT", actionButton, "TOPLEFT", -borderOutset, borderOutset)
        actionBorder:SetPoint("BOTTOMRIGHT", actionButton, "BOTTOMRIGHT", borderOutset, -borderOutset)

        actionHover:ClearAllPoints()
        actionHover:SetPoint("TOPLEFT", actionButton, "TOPLEFT", -hoverOutset, hoverOutset)
        actionHover:SetPoint("BOTTOMRIGHT", actionButton, "BOTTOMRIGHT", hoverOutset, -hoverOutset)

        actionPressed:ClearAllPoints()
        actionPressed:SetPoint("TOPLEFT", actionButton, "TOPLEFT", iconInset, -iconInset)
        actionPressed:SetPoint("BOTTOMRIGHT", actionButton, "BOTTOMRIGHT", -iconInset, iconInset)
    end

    ApplyActionButtonLayout()

    local function UpdateActionButtonVisual(self)
        local hovered = self.isHovered and true or false
        local pressed = self.isPressed and true or false

        if self.hover then
            if hovered then
                self.hover:Show()
            else
                self.hover:Hide()
            end
        end

        if self.pressed then
            if pressed then
                self.pressed:Show()
            else
                self.pressed:Hide()
            end
        end

        if pressed then
            self.icon:SetVertexColor(0.84, 0.84, 0.84, 1)
        elseif hovered then
            self.icon:SetVertexColor(1, 1, 1, 1)
        else
            self.icon:SetVertexColor(0.95, 0.95, 0.95, 1)
        end
    end

    actionButton:SetScript("OnEnter", function(self)
        self.isHovered = true
        UpdateActionButtonVisual(self)
    end)

    actionButton:SetScript("OnLeave", function(self)
        self.isHovered = false
        self.isPressed = false
        UpdateActionButtonVisual(self)
    end)

    actionButton:SetScript("OnMouseDown", function(self)
        self.isPressed = true
        UpdateActionButtonVisual(self)
    end)

    actionButton:SetScript("OnMouseUp", function(self)
        self.isPressed = false
        self.isHovered = self:IsMouseOver()
        UpdateActionButtonVisual(self)
    end)

    actionButton:SetScript("OnHide", function(self)
        self.isHovered = false
        self.isPressed = false
        UpdateActionButtonVisual(self)
    end)

    actionButton:SetScript("OnDragStart", function()
        frame:StartMoving()
    end)

    actionButton:SetScript("OnDragStop", function()
        StopMovingAndPersist(frame)
        UpdateGPS()
    end)

    local statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusText:SetPoint("TOP", arrow, "BOTTOM", 0, -1)
    statusText:SetPoint("LEFT", frame, "LEFT", 10, 0)
    statusText:SetPoint("RIGHT", frame, "RIGHT", -10, 0)
    statusText:SetJustifyH("CENTER")
    statusText:SetTextColor(unpack(COLOURS.accent))

    local detailText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    detailText:SetPoint("TOP", statusText, "BOTTOM", 0, -6)
    detailText:SetPoint("LEFT", frame, "LEFT", 10, 0)
    detailText:SetPoint("RIGHT", frame, "RIGHT", -10, 0)
    detailText:SetJustifyH("CENTER")
    detailText:SetTextColor(unpack(COLOURS.text))

    local distanceText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    distanceText:SetPoint("TOP", detailText, "BOTTOM", 0, -6)
    distanceText:SetPoint("LEFT", frame, "LEFT", 10, 0)
    distanceText:SetPoint("RIGHT", frame, "RIGHT", -10, 0)
    distanceText:SetJustifyH("CENTER")
    distanceText:SetTextColor(unpack(COLOURS.textSecondary))

    frame.arrow = arrow
    frame.arrowDragButton = arrowDragButton
    frame.actionButton = actionButton
    frame.statusText = statusText
    frame.detailText = detailText
    frame.distanceText = distanceText
    frame.currentStepIndex = nil

    ApplyGPSPosition(frame)
    addon:ApplyGPSScale(MapzerothDB.settings.windowScale or 1.0)

    frame:SetScript("OnUpdate", function(self, elapsed)
        if not self:IsShown() then
            return
        end

        gpsElapsed = gpsElapsed + elapsed
        if gpsElapsed < GPS_UPDATE_INTERVAL then
            return
        end

        gpsElapsed = 0
        UpdateGPS()
    end)

    frame:Hide()
    gpsFrame = frame
    addon.GPSNavigatorFrame = frame

    addon:InitializeMapClickRouting()

    return frame
end
