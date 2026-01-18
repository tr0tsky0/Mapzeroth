-- RouteExecutionFrame.lua
-- Popup frame with clickable SecureActionButtons for executing routes
local addonName, addon = ...

local FRAME_WIDTH = 400
local STEP_HEIGHT = 40
local FRAME_PADDING = 10

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
    cardBg = {0.1, 0.1, 0.1, 0.8}
}

local stepButtons = {}

-----------------------------------------------------------
-- BUILD MACRO TEXT FOR STEP
-----------------------------------------------------------

local function BuildStepMacro(stepData)
    if stepData.spellID then
        local spellInfo = C_Spell.GetSpellInfo(stepData.spellID)
        
        if spellInfo then
           return string.format("/cast %s", spellInfo.name) 
        else
            -- Fallback to ID (might not work, but worth trying)
            return string.format("/cast %d", stepData.spellID)
        end
        
    elseif stepData.itemID then
        -- Get localized item name from ID
        local itemName = C_Item.GetItemInfo(stepData.itemID)
        
        if itemName then
            return string.format("/use %s", itemName)
        else
            -- Fallback to ID (might not work, but worth trying)
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
-- CREATE EXECUTION FRAME
-----------------------------------------------------------

local function CreateExecutionFrame()
    if addon.RouteExecutionFrame then
        return addon.RouteExecutionFrame
    end

    local frame = CreateFrame("Frame", "MapzerothRouteExecutionFrame", UIParent, "BackdropTemplate")
    frame:SetSize(FRAME_WIDTH, 200) -- Will be resized based on steps
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
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    frame:SetBackdropColor(unpack(COLOURS.background))
    frame:SetBackdropBorderColor(unpack(COLOURS.border))
    
    -- Close on Escape
    tinsert(UISpecialFrames, frame:GetName())
    
    -- Header bar
    local headerBar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    headerBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -6)
    headerBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
    headerBar:SetHeight(30)
    headerBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        tile = false
    })
    headerBar:SetBackdropColor(unpack(COLOURS.backgroundLight))
    
    -- Title
    local title = headerBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", headerBar, "LEFT", 10, 0)
    title:SetText("Route")
    title:SetTextColor(unpack(COLOURS.text))
    frame.title = title
    
    -- Close button
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
    symbol:SetText("×")
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
    
    -- Container for step buttons (regular frame, not scrollframe)
    local container = CreateFrame("Frame", nil, frame)
    container:SetPoint("TOPLEFT", headerBar, "BOTTOMLEFT", 0, -10)
    container:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
    container:SetClipsChildren(true)
    frame.container = container
    
    -- Apply saved scale
    local savedScale = MapzerothDB.settings.windowScale or 1.0
    frame:SetScale(savedScale)
    
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
        frame:RegisterForClicks("LeftButtonUp")
        
        -- Set macro
        local macroText = BuildStepMacro(stepData)
        if macroText then
            frame:SetAttribute("macrotext", macroText)
        end
    else
        frame = CreateFrame("Button", nil, parent, "BackdropTemplate")
        
        -- Click handler for walk/fly
        frame:SetScript("OnClick", function(self)
            local stepData = self.stepData
            
            -- Handle waypoint destination specially
            if stepData.nodeID == "_WAYPOINT_DESTINATION" then
                -- Use stored waypoint data
                if stepData.waypointData then
                    SetWaypoint(
                        stepData.waypointData.mapID,
                        stepData.waypointData.x,
                        stepData.waypointData.y,
                        "Waypoint",
                        stepData.method
                    )
                else
                    print("[Mapzeroth] Error: No waypoint data")
                end
                return
            end
            
            -- Regular node - look it up
            local node = stepData.nodeID and addon.TravelGraph:GetNodeByID(stepData.nodeID)
            if node then
                SetWaypoint(node.mapID, node.x, node.y, node.displayName or node.name, stepData.method)
            else
                print("[Mapzeroth] Error: Could not find node")
            end
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
    
    -- Action text
    local actionText
    if stepData.abilityName then
        if stepData.destinationName then
            actionText = string.format("Use %s to %s", stepData.abilityName, stepData.destinationName)
        else
            actionText = string.format("Use %s", stepData.abilityName)
        end
    else
        local methodPrefix = addon.METHOD_DISPLAY_TEXT[stepData.method] or "Go to"
        actionText = string.format("%s %s", methodPrefix, stepData.destination)
    end
    
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
        GameTooltip:SetText("Click to " .. string.lower(actionText), 1, 1, 1)
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
    
    -- Hide existing buttons
    for _, btn in ipairs(stepButtons) do
        btn:Hide()
        btn:SetParent(nil)
    end
    stepButtons = {}
    
    -- Create step buttons
    local yOffset = 0
    for i, stepData in ipairs(steps) do
        local stepBtn = CreateStepButton(frame.container, stepData, i)
        stepBtn:SetPoint("TOPLEFT", frame.container, "TOPLEFT", 0, -yOffset)
        table.insert(stepButtons, stepBtn)
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
    
    table.insert(stepButtons, footer) -- Track for cleanup
    yOffset = yOffset + 35
    
    -- Resize frame to fit content
    local frameHeight = yOffset + 60 -- 30 for header, 30 for padding
    frame:SetHeight(math.min(frameHeight, 600)) -- Cap at 600px
    
    -- Position frame
    if addon.MapzerothFrame and addon.MapzerothFrame:IsShown() then
        frame:SetPoint("TOPLEFT", addon.MapzerothFrame, "BOTTOMLEFT", 0, -10)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER")
    end
    
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