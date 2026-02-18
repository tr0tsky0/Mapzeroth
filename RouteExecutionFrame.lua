-- RouteExecutionFrame.lua
-- Popup frame with clickable SecureActionButtons for executing routes
local addonName, addon = ...

local FRAME_WIDTH = 400
local STEP_HEIGHT = 40
local FRAME_PADDING = 10
local NAVIGATOR_HEIGHT = 0
local STEP_COMPLETION_DISTANCE_YARDS = 55
local ARROW_UPDATE_INTERVAL = 0.1

-- Material colour palette (matching main GUI)
local COLOURS = {
    background = {0.05, 0.05, 0.05, 0.95},
    backgroundLight = {0.1, 0.1, 0.1, 1},
    border = {0.3, 0.3, 0.3, 1},
    text = {1, 1, 1, 1},
    textSecondary = {0.7, 0.7, 0.7, 1},
    accent = {0.2, 0.5, 0.9, 1},
    accentHover = {0.3, 0.6, 1, 1},
    hoverBg = {0.2, 0.4, 0.6, 0.5},
    cardBg = {0.1, 0.1, 0.1, 0.8},
    currentStepBg = {0.13, 0.21, 0.3, 0.9},
    completedStepBg = {0.08, 0.17, 0.12, 0.8}
}

local routeStepButtons = {}
local routeSteps = {}
local currentRouteStep = 1
local updateElapsed = 0
local routeFooter = nil
local routeTotalTime = nil

-----------------------------------------------------------
-- MATH HELPERS
-----------------------------------------------------------

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

local function FormatDistance(distance)
    if not distance then
        return "Target on another map"
    end

    if distance >= 1000 then
        return string.format("%.1f km", distance / 1000)
    end

    return string.format("%.0f yd", distance)
end

-----------------------------------------------------------
-- STEP TARGET RESOLUTION
-----------------------------------------------------------

local function GetStepActionText(stepData)
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

    if stepData.itemID or stepData.spellID then
        return nil, "Use the current ability/item"
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

    if stepData.fromNodeID then
        return ResolveNodeTarget(stepData.fromNodeID)
    end

    return nil, "Complete this step manually"
end

-----------------------------------------------------------
-- STEP STATE
-----------------------------------------------------------

local function SetStepVisuals()
    for i, btn in ipairs(routeStepButtons) do
        if i < currentRouteStep then
            btn:SetBackdropColor(unpack(COLOURS.completedStepBg))
        elseif i == currentRouteStep then
            btn:SetBackdropColor(unpack(COLOURS.currentStepBg))
        else
            btn:SetBackdropColor(unpack(COLOURS.cardBg))
        end
    end
end

function addon:SetActiveRouteStep(stepIndex)
    if not routeSteps or #routeSteps == 0 then
        return
    end

    local clamped = math.max(1, math.min(stepIndex or 1, #routeSteps))
    currentRouteStep = clamped
    SetStepVisuals()
end

function addon:CompleteRouteStep(stepIndex)
    if not routeSteps or #routeSteps == 0 then
        return
    end

    local index = stepIndex or currentRouteStep
    if index < currentRouteStep then
        return
    end

    if index == currentRouteStep then
        currentRouteStep = math.min(#routeSteps + 1, currentRouteStep + 1)
        SetStepVisuals()
    end
end

function addon:BeginRouteNavigation(steps, totalTime)
    routeSteps = steps or {}
    currentRouteStep = (#routeSteps > 0) and 1 or 0
    routeTotalTime = totalTime
    updateElapsed = 0
    SetStepVisuals()
end

function addon:GetRouteNavigationState()
    return routeSteps, currentRouteStep, routeTotalTime
end

-----------------------------------------------------------
-- BUILD MACRO TEXT FOR STEP
-----------------------------------------------------------

local function BuildStepMacro(stepData)
    if stepData.spellID then
        local spellInfo = C_Spell.GetSpellInfo(stepData.spellID)

        if spellInfo then
            return string.format("/cast %s", spellInfo.name)
        else
            -- Fallback to ID
            return string.format("/cast %d", stepData.spellID)
        end

    elseif stepData.itemID then
        -- Get localized item name from ID
        local itemName = C_Item.GetItemInfo(stepData.itemID)

        if itemName then
            return string.format("/use %s", itemName)
        else
            -- Fallback to ID
            return string.format("/use %d", stepData.itemID)
        end
    end

    return nil
end

-----------------------------------------------------------
-- WALK/FLY WAYPOINT
-----------------------------------------------------------

local function SetWaypoint(mapID, x, y, nodeName, method)
    if not mapID or not x or not y then
        print("[Mapzeroth] Error: Invalid coordinates")
        return false
    end

    -- Try TomTom first (if installed)
    if TomTom then
        local success = pcall(function()
            TomTom:AddWaypoint(mapID, x, y, {
                title = nodeName or "Mapzeroth Waypoint",
                from = "Mapzeroth"
            })
        end)

        if success then
            print(string.format("[Mapzeroth] Waypoint set: %s", nodeName or "destination"))
            return true
        end
    end

    -- Fallback to Blizzard waypoint system
    local success = pcall(function()
        C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapID, x, y))
    end)

    if success then
        print(string.format("[Mapzeroth] Waypoint set: %s", nodeName or "destination"))

        -- Ping the map to draw attention
        if C_SuperTrack then
            C_SuperTrack.SetSuperTrackedUserWaypoint(true)
        end

        return true
    else
        print("[Mapzeroth] Failed to set waypoint")
        return false
    end
end

-----------------------------------------------------------
-- NAVIGATOR UPDATE
-----------------------------------------------------------

local function UpdateNavigator(frame)
    local nav = frame.navigator
    if not nav then
        return
    end

    if not routeSteps or #routeSteps == 0 then
        nav.arrow:SetAlpha(0.25)
        nav.statusText:SetText("No active route")
        nav.distanceText:SetText("")
        return
    end

    if currentRouteStep > #routeSteps then
        nav.arrow:SetAlpha(0.25)
        nav.statusText:SetText("Route completed")
        nav.distanceText:SetText("All steps done")
        return
    end

    local step = routeSteps[currentRouteStep]
    local location = addon:GetPlayerLocation()
    local target, reason = ResolveStepTarget(step)

    nav.statusText:SetText(string.format("Step %d/%d", currentRouteStep, #routeSteps))

    if not target then
        nav.arrow:SetAlpha(0.25)
        nav.distanceText:SetText(reason or "Complete current step")
        nav.detailText:SetText(GetStepActionText(step))
        return
    end

    if not location then
        nav.arrow:SetAlpha(0.25)
        nav.distanceText:SetText("Player location unavailable")
        nav.detailText:SetText(GetStepActionText(step))
        return
    end

    local distance, heading = GetDistanceAndHeading(location.mapID, location.x, location.y, target.mapID, target.x, target.y)

    nav.distanceText:SetText(string.format("%s | %s", target.name, FormatDistance(distance)))
    nav.detailText:SetText(GetStepActionText(step))

    if not distance or not heading then
        nav.arrow:SetAlpha(0.25)
        return
    end

    if (step.method == "walk" or step.method == "fly") and distance <= STEP_COMPLETION_DISTANCE_YARDS then
        addon:CompleteRouteStep(currentRouteStep)
        step = routeSteps[currentRouteStep]
        nav.arrow:SetAlpha(0.25)
        if step then
            nav.detailText:SetText(GetStepActionText(step))
        end
        return
    end

    local facing = GetPlayerFacing()
    if not facing then
        nav.arrow:SetAlpha(0.25)
        return
    end

    nav.arrow:SetAlpha(1)
    nav.arrow:SetRotation(heading - facing)
end

-----------------------------------------------------------
-- CREATE EXECUTION FRAME
-----------------------------------------------------------

local function CreateExecutionFrame()
    if addon.RouteExecutionFrame then
        return addon.RouteExecutionFrame
    end

    local frame = CreateFrame("Frame", "MapzerothRouteExecutionFrame", UIParent, "BackdropTemplate")
    frame:SetSize(FRAME_WIDTH, 200)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    -- Material design backdrop
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        edgeSize = 8,
        insets = {
            left = 2,
            right = 2,
            top = 2,
            bottom = 2
        }
    })
    frame:SetBackdropColor(unpack(COLOURS.background))
    frame:SetBackdropBorderColor(unpack(COLOURS.border))

    -- Close on Escape
    tinsert(UISpecialFrames, frame:GetName())

    -- Header bar
    local headerBar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    headerBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -6)
    headerBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
    headerBar:SetHeight(40)
    headerBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        tile = false
    })
    headerBar:SetBackdropColor(unpack(COLOURS.backgroundLight))

    -- Title
    local title = headerBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", headerBar, "TOPLEFT", 10, -6)
    title:SetText("Route")
    title:SetTextColor(unpack(COLOURS.text))
    frame.title = title

    -- Hint text (second line)
    local hintText = headerBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hintText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
    hintText:SetText("Click steps with items/spells to use them instantly")
    hintText:SetTextColor(0.5, 0.7, 0.9, 1) -- Subtle blue
    frame.hintText = hintText

    -- Close button (adjust position for taller header)
    local closeBtn = CreateFrame("Button", nil, headerBar, "BackdropTemplate")
    closeBtn:SetSize(24, 24)
    closeBtn:SetPoint("RIGHT", headerBar, "RIGHT", -4, 0)
    closeBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        tile = false
    })
    closeBtn:SetBackdropColor(0, 0, 0, 0)

    local symbol = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    symbol:SetPoint("CENTER", 0, 1)
    symbol:SetText("x")
    symbol:SetTextColor(unpack(COLOURS.textSecondary))

    closeBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.4, 0.1, 0.1, 0.8)
        symbol:SetTextColor(1, 1, 1, 1)
    end)
    closeBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0, 0, 0, 0)
        symbol:SetTextColor(unpack(COLOURS.textSecondary))
    end)
    closeBtn:SetScript("OnClick", function()
        frame:Hide()
    end)

    -- Navigator card
    local navigator = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    navigator:SetPoint("TOPLEFT", headerBar, "BOTTOMLEFT", 0, -8)
    navigator:SetPoint("TOPRIGHT", headerBar, "BOTTOMRIGHT", 0, -8)
    navigator:SetHeight(NAVIGATOR_HEIGHT)
    navigator:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        tile = false
    })
    navigator:SetBackdropColor(unpack(COLOURS.backgroundLight))

    local arrow = navigator:CreateTexture(nil, "ARTWORK")
    arrow:SetTexture("Interface\\MINIMAP\\ROTATING-MINIMAPARROW")
    arrow:SetSize(52, 52)
    arrow:SetPoint("LEFT", navigator, "LEFT", 12, 0)

    local statusText = navigator:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusText:SetPoint("TOPLEFT", arrow, "TOPRIGHT", 12, -4)
    statusText:SetPoint("TOPRIGHT", navigator, "TOPRIGHT", -10, -4)
    statusText:SetJustifyH("LEFT")
    statusText:SetTextColor(unpack(COLOURS.accentHover))

    local detailText = navigator:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    detailText:SetPoint("TOPLEFT", statusText, "BOTTOMLEFT", 0, -5)
    detailText:SetPoint("TOPRIGHT", navigator, "TOPRIGHT", -10, -5)
    detailText:SetJustifyH("LEFT")
    detailText:SetTextColor(unpack(COLOURS.text))

    local distanceText = navigator:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    distanceText:SetPoint("TOPLEFT", detailText, "BOTTOMLEFT", 0, -5)
    distanceText:SetPoint("TOPRIGHT", navigator, "TOPRIGHT", -10, -5)
    distanceText:SetJustifyH("LEFT")
    distanceText:SetTextColor(unpack(COLOURS.textSecondary))

    frame.navigator = {
        frame = navigator,
        arrow = arrow,
        statusText = statusText,
        detailText = detailText,
        distanceText = distanceText
    }
    navigator:Hide()

    -- Container for step buttons
    local container = CreateFrame("Frame", nil, frame)
    container:SetPoint("TOPLEFT", headerBar, "BOTTOMLEFT", 0, -10)
    container:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
    container:SetClipsChildren(true)
    frame.container = container

    -- Apply saved scale
    local savedScale = MapzerothDB.settings.windowScale or 1.0
    frame:SetScale(savedScale)

    frame:SetScript("OnUpdate", nil)

    addon.RouteExecutionFrame = frame
    return frame
end

-----------------------------------------------------------
-- CREATE STEP BUTTON (MATERIAL DESIGN CARD)
-----------------------------------------------------------

local function CreateStepButton(parent, stepData, stepNum)
    -- Determine if this needs to be secure
    local needsSecure = (stepData.itemID or stepData.spellID) ~= nil

    local frame
    if needsSecure then
        frame = CreateFrame("Button", nil, parent, "SecureActionButtonTemplate,BackdropTemplate")
        frame:SetAttribute("type", "macro")
        frame:RegisterForClicks("LeftButtonDown", "LeftButtonUp")

        -- Set macro
        local macroText = BuildStepMacro(stepData)
        if macroText then
            frame:SetAttribute("macrotext", macroText)
        end

        frame:SetScript("PreClick", function(self)
            addon:SetActiveRouteStep(self.stepNum)
        end)

        frame:SetScript("PostClick", function(self)
            addon:CompleteRouteStep(self.stepNum)
        end)
    else
        frame = CreateFrame("Button", nil, parent, "BackdropTemplate")

        frame:SetScript("OnClick", function(self)
            local clickedStep = self.stepData
            addon:SetActiveRouteStep(self.stepNum)

            -- Click handler for walk/fly
            if clickedStep.method == "walk" or clickedStep.method == "fly" then
                -- Handle waypoint destination specially
                if clickedStep.nodeID == "_WAYPOINT_DESTINATION" then
                    -- Use stored waypoint data
                    if clickedStep.waypointData then
                        SetWaypoint(clickedStep.waypointData.mapID, clickedStep.waypointData.x,
                            clickedStep.waypointData.y, "Waypoint", clickedStep.method)
                    else
                        print("[Mapzeroth] Error: No waypoint data")
                    end
                    return
                end

                -- Regular node - look it up
                local node = clickedStep.nodeID and addon.TravelGraph:GetNodeByID(clickedStep.nodeID)
                if node then
                    SetWaypoint(node.mapID, node.x, node.y, node.displayName or node.name, clickedStep.method)
                else
                    print("[Mapzeroth] Error: Could not find node")
                end
                return
            end

            -- Non-movement steps are completed manually by click.
            addon:CompleteRouteStep(self.stepNum)
        end)
    end

    frame:SetSize(FRAME_WIDTH - 30, STEP_HEIGHT - 5)

    -- Material backdrop (card)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        tile = false
    })
    frame:SetBackdropColor(unpack(COLOURS.cardBg))

    -- Store step data
    frame.stepData = stepData
    frame.stepNum = stepNum

    -- Hover effect
    frame:EnableMouse(true)
    frame:SetHighlightTexture("Interface\\Buttons\\WHITE8x8")
    local highlight = frame:GetHighlightTexture()
    highlight:SetVertexColor(unpack(COLOURS.hoverBg))
    highlight:SetAllPoints(frame)

    -- Step number
    local numText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    numText:SetPoint("LEFT", frame, "LEFT", 8, 0)
    numText:SetText(stepNum .. ".")
    numText:SetTextColor(unpack(COLOURS.textSecondary))

    -- Icon
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(28, 28)
    icon:SetPoint("LEFT", numText, "RIGHT", 8, 0)

    -- Get icon
    local iconPath
    if stepData.itemID then
        iconPath = C_Item.GetItemIconByID(stepData.itemID)
    elseif stepData.spellID then
        local spellInfo = C_Spell.GetSpellInfo(stepData.spellID)
        if spellInfo then
            iconPath = spellInfo.iconID
        end
    end

    if not iconPath then
        iconPath = addon.TRAVEL_ICONS[stepData.method] or addon.TRAVEL_ICONS["walk"]
    end
    icon:SetTexture(iconPath)

    local actionText = GetStepActionText(stepData)

    local destText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    destText:SetPoint("LEFT", icon, "RIGHT", 8, 0)
    destText:SetPoint("RIGHT", frame, "RIGHT", -60, 0)
    destText:SetJustifyH("LEFT")
    destText:SetText(actionText)
    destText:SetTextColor(unpack(COLOURS.text))

    -- Time text
    local timeText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    timeText:SetPoint("RIGHT", frame, "RIGHT", -8, 0)
    timeText:SetJustifyH("RIGHT")
    timeText:SetTextColor(unpack(COLOURS.textSecondary))
    timeText:SetText(string.format("%.0fs", stepData.time))

    -- Tooltip
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

        local tooltipText
        if stepData.method == "portal" then
            tooltipText = string.format("Use portal to %s",
                stepData.destinationName or stepData.destination or "destination")
        elseif stepData.method == "flightpath" then
            tooltipText = string.format("Take flight path to %s",
                stepData.destinationName or stepData.destination or "destination")
        elseif stepData.method == "walk" or stepData.method == "fly" then
            local dest = stepData.destinationName or stepData.destination or "destination"
            tooltipText = string.format("Click to set waypoint to %s", dest)
        elseif stepData.itemID or stepData.spellID then
            tooltipText = string.format("Click to use %s", stepData.abilityName or "ability")
        else
            -- Fallback for any other method
            tooltipText = actionText
        end

        GameTooltip:SetText(tooltipText, 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)

    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return frame
end

-----------------------------------------------------------
-- SHOW ROUTE IN EXECUTION FRAME
-----------------------------------------------------------

function addon:ShowRouteExecutionFrame(steps, totalTime)
    local frame = CreateExecutionFrame()

    frame:ClearAllPoints()

    -- Hide existing buttons
    for _, btn in ipairs(routeStepButtons) do
        btn:Hide()
        btn:SetParent(nil)
    end
    routeStepButtons = {}
    if routeFooter then
        routeFooter:Hide()
        routeFooter:SetParent(nil)
        routeFooter = nil
    end

    addon:BeginRouteNavigation(steps, totalTime)

    -- Create step buttons
    local yOffset = 0
    for i, stepData in ipairs(routeSteps) do
        local stepBtn = CreateStepButton(frame.container, stepData, i)
        stepBtn:SetPoint("TOPLEFT", frame.container, "TOPLEFT", 0, -yOffset)
        table.insert(routeStepButtons, stepBtn)
        yOffset = yOffset + STEP_HEIGHT
    end

    -- Create total time footer
    local footer = CreateFrame("Frame", nil, frame.container, "BackdropTemplate")
    footer:SetSize(FRAME_WIDTH - 30, 35)
    footer:SetPoint("TOPLEFT", frame.container, "TOPLEFT", 0, -yOffset)
    footer:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        tile = false
    })
    footer:SetBackdropColor(unpack(COLOURS.backgroundLight))

    local totalText = footer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    totalText:SetPoint("CENTER", footer, "CENTER")
    totalText:SetTextColor(unpack(COLOURS.text))

    if totalTime then
        local minutes = math.floor(totalTime / 60)
        local seconds = totalTime % 60
        if minutes > 0 then
            totalText:SetText(string.format("Total Time: %dm %.0fs", minutes, seconds))
        else
            totalText:SetText(string.format("Total Time: %.0fs", seconds))
        end
    else
        totalText:SetText("Total Time: N/A")
    end
    routeFooter = footer

    yOffset = yOffset + 35

    -- Resize frame to fit content
    local frameHeight = yOffset + 60
    frame:SetHeight(math.min(frameHeight, 600))

    -- Position frame
    if addon.MapzerothFrame and addon.MapzerothFrame:IsShown() then
        frame:SetPoint("TOPLEFT", addon.MapzerothFrame, "BOTTOMLEFT", 0, -10)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER")
    end

    SetStepVisuals()
    frame:Show()
end

-----------------------------------------------------------
-- HIDE EXECUTION FRAME
-----------------------------------------------------------

function addon:HideRouteExecutionFrame()
    if addon.RouteExecutionFrame then
        addon.RouteExecutionFrame:Hide()
    end
end
