-- GUI.lua
-- Main interface window for Mapzeroth (MATERIAL DESIGN EDITION)
local addonName, addon = ...

-- Localise frequently-used globals
local CreateFrame = CreateFrame
local UIParent = UIParent

-----------------------------------------------------------
-- CONSTANTS & CONFIG
-----------------------------------------------------------

local FRAME_WIDTH = 400
local FRAME_HEIGHT_COLLAPSED = 100
local FRAME_HEIGHT_EXPANDED = 400 -- Will grow dynamically
local STEP_HEIGHT = 40

-- Material colour palette (matching DestinationSelector)
local COLOURS = {
    background = {0.05, 0.05, 0.05, 0.95},
    backgroundLight = {0.1, 0.1, 0.1, 1},
    border = {0.3, 0.3, 0.3, 1},
    text = {1, 1, 1, 1},
    textSecondary = {0.7, 0.7, 0.7, 1},
    accent = {0.2, 0.5, 0.9, 1}, -- Blue for interactables
    accentHover = {0.3, 0.6, 1, 1},
    hoverBg = {0.2, 0.4, 0.6, 0.5},
    cardBg = {0.1, 0.1, 0.1, 0.8}
}

-- Travel method icons (we'll use built-in WoW icons for now)
local TRAVEL_ICONS = {
    portal = "Interface\\Icons\\Spell_Arcane_PortalOrgrimmar",
    ship = "Interface\\Icons\\Spell_Frost_SummonWaterElemental",
    tram = "Interface\\Icons\\INV_Misc_EngGizmos_20",
    flight = "Interface\\Icons\\Ability_Mount_JungleTiger",
    fly = "Interface\\Icons\\Ability_Druid_FlightForm",
    walk = "Interface\\Icons\\Ability_Rogue_Sprint",
    teleport = "Interface\\Icons\\Spell_Arcane_Teleportorgrimmar",
    hearthstone = "Interface\\Icons\\INV_Misc_Rune_01",
    racial = "Interface\\Icons\\INV_Misc_Gear_01"
}

local METHOD_DISPLAY_TEXT = {
    portal = "Portal to",
    ship = "Boat to",
    tram = "Tram to",
    flight = "Flightpath to",
    fly = "Fly to",
    walk = "Walk to",
    teleport = "Teleport to",
    hearthstone = "Hearth to",
    racial = "Use", -- Will be "Use Mole Machine to..."
    zeppelin = "Zeppelin to"
}

-----------------------------------------------------------
-- HELPER: CREATE FLAT BUTTON
-----------------------------------------------------------

local function CreateFlatButton(parent, width, height, text)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, height)

    -- Flat background
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = nil,
        tile = false
    })
    btn:SetBackdropColor(unpack(COLOURS.backgroundLight))

    -- Text
    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("CENTER")
    label:SetText(text)
    label:SetTextColor(unpack(COLOURS.accent))
    btn.label = label

    -- Hover effect
    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(unpack(COLOURS.hoverBg))
        label:SetTextColor(unpack(COLOURS.accentHover))
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(COLOURS.backgroundLight))
        label:SetTextColor(unpack(COLOURS.accent))
    end)

    return btn
end

-----------------------------------------------------------
-- HELPER: CREATE CLOSE BUTTON
-----------------------------------------------------------

local function CreateCloseButton(parent)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(24, 24)

    -- Transparent background
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        tile = false
    })
    btn:SetBackdropColor(0, 0, 0, 0)

    -- "×" symbol
    local symbol = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    symbol:SetPoint("CENTER", 0, 1)
    symbol:SetText("×")
    symbol:SetTextColor(unpack(COLOURS.textSecondary))
    btn.symbol = symbol

    -- Hover effect
    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.4, 0.1, 0.1, 0.8) -- Red tint
        symbol:SetTextColor(1, 1, 1, 1)
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0, 0, 0, 0)
        symbol:SetTextColor(unpack(COLOURS.textSecondary))
    end)

    return btn
end

-----------------------------------------------------------
-- MAIN FRAME CREATION
-----------------------------------------------------------

function addon:CreateGUI()
    if addon.MapzerothFrame then
        return addon.MapzerothFrame -- Already exists
    end

    -- Create main frame (flat material panel)
    local frame = CreateFrame("Frame", "MapzerothMainFrame", UIParent, "BackdropTemplate")
    addon.MapzerothFrame = frame
    frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT_COLLAPSED)
    frame:SetPoint("CENTER", UIParent, "CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)

    -- Backdrop (flat dark material)
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

    -----------------------------------------------------------
    -- HEADER BAR (Title + Close Button)
    -----------------------------------------------------------

    local headerBar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    headerBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -6)
    headerBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
    headerBar:SetHeight(30)

    headerBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        tile = false
    })
    headerBar:SetBackdropColor(unpack(COLOURS.backgroundLight))

    -- Logo button (clickable region)
    local logoButton = CreateFrame("Button", nil, headerBar)
    logoButton:SetSize(28, 28)
    logoButton:SetPoint("LEFT", headerBar, "LEFT", 10, 0)

    -- Logo texture (child of button)
    local logo = logoButton:CreateTexture(nil, "ARTWORK")
    logo:SetTexture("Interface\\AddOns\\Mapzeroth\\Mapzeroth_Logo")
    logo:SetAllPoints(logoButton) -- Fill the button area

    -- Click handler
    logoButton:SetScript("OnClick", function()
        addon:ToggleAboutFrame()
    end)

    -- Hover effect with tooltip
    logoButton:SetScript("OnEnter", function(self)
        logo:SetVertexColor(1.2, 1.2, 1.2) -- Slight brightness boost
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("About Mapzeroth", 1, 1, 1)
        GameTooltip:AddLine("Click for community links and info", 0.7, 0.7, 0.7, true)
        GameTooltip:Show()
    end)
    logoButton:SetScript("OnLeave", function(self)
        logo:SetVertexColor(1, 1, 1) -- Back to normal
        GameTooltip:Hide()
    end)

    -- Store reference
    frame.logoButton = logoButton

    -- Title text (anchored to the right of the logo)
    local title = headerBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", logo, "RIGHT", 8, 0) -- 8px gap after logo
    title:SetText("Mapzeroth")
    title:SetTextColor(unpack(COLOURS.text))
    frame.title = title

    -- Close button (top-right of header)
    local closeBtn = CreateCloseButton(headerBar)
    closeBtn:SetPoint("RIGHT", headerBar, "RIGHT", -4, 0)
    closeBtn:SetScript("OnClick", function()
        frame:Hide()
    end)
    frame.closeButton = closeBtn

    -----------------------------------------------------------
    -- DESTINATION SELECTOR SECTION
    -----------------------------------------------------------

    -- "Destination:" label
    local destLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    destLabel:SetPoint("TOPLEFT", headerBar, "BOTTOMLEFT", 10, -12)
    destLabel:SetText("Destination:")
    destLabel:SetTextColor(unpack(COLOURS.text))

    -- Current selection display
    local selectedDestDisplay = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    selectedDestDisplay:SetPoint("LEFT", destLabel, "RIGHT", 8, 0)
    selectedDestDisplay:SetText("[WAYPOINT] Active Waypoint")
    selectedDestDisplay:SetTextColor(unpack(COLOURS.textSecondary))
    frame.selectedDestLabel = selectedDestDisplay

    -- Flat "Choose Destination" button
    local selectorToggleBtn = CreateFlatButton(frame, 140, 26, "Choose Destination")
    selectorToggleBtn:SetPoint("TOPLEFT", destLabel, "BOTTOMLEFT", 0, -8)
    selectorToggleBtn:SetScript("OnClick", function()
        addon:ToggleDestinationSelector()
    end)
    frame.selectorToggleBtn = selectorToggleBtn

    -- Create the actual destination selector (hidden by default)
    -- Instead of creating it as a child of the frame positioned outside,
    -- we'll position it to overlay the route container area
    local destinationSelector = addon:CreateDestinationSelector(frame)

    -- Clear the fixed size and let it stretch to fill the space
    destinationSelector:ClearAllPoints()
    destinationSelector:SetPoint("TOPLEFT", selectorToggleBtn, "BOTTOMLEFT", 0, -10)
    destinationSelector:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)

    destinationSelector:Hide()
    frame.destinationSelector = destinationSelector

    -- Initialize selection state
    frame.selectedDest = "_WAYPOINT"

    -----------------------------------------------------------
    -- NAVIGATE BUTTON
    -----------------------------------------------------------

    local navButton = CreateFlatButton(frame, 90, 26, "Navigate")
    navButton:SetPoint("LEFT", selectorToggleBtn, "RIGHT", 10, 0)
    navButton:SetScript("OnClick", function()
        addon:OnNavigateClicked()
    end)
    frame.navButton = navButton

    -----------------------------------------------------------
    -- ROUTE DISPLAY CONTAINER (initially hidden)
    -----------------------------------------------------------

    local routeContainer = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    routeContainer:SetPoint("TOPLEFT", selectorToggleBtn, "BOTTOMLEFT", 0, -10)
    routeContainer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 10)
    routeContainer:Hide()
    frame.routeContainer = routeContainer

    -- ScrollChild (where route steps will live)
    local scrollChild = CreateFrame("Frame", nil, routeContainer)
    scrollChild:SetSize(FRAME_WIDTH - 40, 1) -- Height grows dynamically
    routeContainer:SetScrollChild(scrollChild)
    frame.routeScrollChild = scrollChild

    -----------------------------------------------------------
    -- STORAGE & STATE
    -----------------------------------------------------------

    frame.routeSteps = {} -- Will hold step frames
    frame.isExpanded = false
    frame.selectedDest = nil

    return frame
end

-----------------------------------------------------------
-- ABOUT FRAME (Community Links & Info)
-----------------------------------------------------------

function addon:CreateAboutFrame()
    if addon.AboutFrame then
        return addon.AboutFrame
    end

    local frame = CreateFrame("Frame", "MapzerothAboutFrame", UIParent, "BackdropTemplate")
    addon.AboutFrame = frame

    frame:SetSize(320, 280)
    frame:SetPoint("CENTER", UIParent, "CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)

    -- Backdrop
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        edgeSize = 12,
        insets = {
            left = 4,
            right = 4,
            top = 4,
            bottom = 4
        }
    })
    frame:SetBackdropColor(unpack(COLOURS.background))
    frame:SetBackdropBorderColor(unpack(COLOURS.border))

    -- Close button (top-right corner of frame, using our flat material style)
    local closeBtn = CreateCloseButton(frame)
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -8)
    closeBtn:SetScript("OnClick", function()
        frame:Hide()
    end)

    -- Logo in About frame (start higher since no header bar)
    local aboutLogo = frame:CreateTexture(nil, "ARTWORK")
    aboutLogo:SetTexture("Interface\\AddOns\\Mapzeroth\\Mapzeroth_Logo")
    aboutLogo:SetSize(48, 48)
    aboutLogo:SetPoint("TOP", frame, "TOP", 0, -30) -- Closer to top now

    -- Content area (start below the logo)
    local yOffset = -90 -- Start below logo

    -- Version info (pulled from TOC)
    local versionNumber = C_AddOns.GetAddOnMetadata("Mapzeroth", "Version") or "Unknown"
    local version = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    version:SetPoint("TOP", frame, "TOP", 0, yOffset)
    version:SetText("Mapzeroth v" .. versionNumber)
    version:SetTextColor(unpack(COLOURS.accent))
    yOffset = yOffset - 25

    -- Author (pulled from TOC)
    local authorName = C_AddOns.GetAddOnMetadata("Mapzeroth", "Author") or "tr0tsky"
    local author = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    author:SetPoint("TOP", frame, "TOP", 0, yOffset)
    author:SetText("by " .. authorName)
    author:SetTextColor(unpack(COLOURS.textSecondary))
    yOffset = yOffset - 30

    -- Links section header
    local linksHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    linksHeader:SetPoint("TOP", frame, "TOP", 0, yOffset)
    linksHeader:SetText("Community & Support")
    linksHeader:SetTextColor(unpack(COLOURS.text))
    yOffset = yOffset - 25

    -- CurseForge link
    local curseLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    curseLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, yOffset)
    curseLabel:SetWidth(60) -- Fixed width
    curseLabel:SetJustifyH("RIGHT") -- Right-aligned text
    curseLabel:SetText("Share:")
    curseLabel:SetTextColor(unpack(COLOURS.textSecondary))

    local curseBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    curseBox:SetSize(220, 20)
    curseBox:SetPoint("LEFT", curseLabel, "RIGHT", 10, 0)
    curseBox:SetText("https://www.curseforge.com/wow/addons/mapzeroth")
    curseBox:SetAutoFocus(false)
    curseBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    curseBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)
    yOffset = yOffset - 30

    -- Ko-fi link
    local kofiLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    kofiLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, yOffset)
    kofiLabel:SetWidth(60) -- Fixed width
    kofiLabel:SetJustifyH("RIGHT") -- Right-aligned text
    kofiLabel:SetText("Support:")
    kofiLabel:SetTextColor(unpack(COLOURS.textSecondary))

    local kofiBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    kofiBox:SetSize(220, 20)
    kofiBox:SetPoint("LEFT", kofiLabel, "RIGHT", 10, 0)
    kofiBox:SetText("https://ko-fi.com/tr0tsky")
    kofiBox:SetAutoFocus(false)
    kofiBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    kofiBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)
    yOffset = yOffset - 30

    -- Discord (placeholder for future)
    local discordLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    discordLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, yOffset)
    discordLabel:SetWidth(60) -- Fixed width
    discordLabel:SetJustifyH("RIGHT") -- Right-aligned text
    discordLabel:SetText("Chat:")
    discordLabel:SetTextColor(unpack(COLOURS.textSecondary))

    local discordBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    discordBox:SetSize(220, 20)
    discordBox:SetPoint("LEFT", discordLabel, "RIGHT", 10, 0)
    discordBox:SetText("Coming soon!")
    discordBox:SetAutoFocus(false)
    discordBox:SetTextColor(0.5, 0.5, 0.5, 1)
    discordBox:Disable()

    frame:Hide()
    return frame
end

-----------------------------------------------------------
-- TOGGLE ABOUT FRAME
-----------------------------------------------------------

function addon:ToggleAboutFrame()
    if not addon.AboutFrame then
        self:CreateAboutFrame()
    end

    local frame = addon.AboutFrame
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end

-----------------------------------------------------------
-- SHOW/HIDE FUNCTIONS
-----------------------------------------------------------

function addon:ShowGUI()
    if not addon.MapzerothFrame then
        self:CreateGUI()
    end

    -- Ensure default selection is set
    if not addon.MapzerothFrame.selectedDest then
        addon.MapzerothFrame.selectedDest = "_WAYPOINT"
        addon.MapzerothFrame.selectedDestLabel:SetText("[WAYPOINT] Active Waypoint")
    end

    addon.MapzerothFrame:Show()
end

function addon:HideGUI()
    if addon.MapzerothFrame then
        addon.MapzerothFrame:Hide()
    end
end

function addon:ToggleGUI()
    if addon.MapzerothFrame and addon.MapzerothFrame:IsShown() then
        self:HideGUI()
    else
        self:ShowGUI()
    end
end

-----------------------------------------------------------
-- NAVIGATE BUTTON HANDLER
-----------------------------------------------------------

function addon:OnNavigateClicked()
    local dest = addon.MapzerothFrame.selectedDest

    if not dest then
        print("[Mapzeroth] Please select a destination")
        return
    end

    -- Hide destination selector when navigating
    if addon.MapzerothFrame.destinationSelector:IsShown() then
        addon.MapzerothFrame.destinationSelector:Hide()
    end

    if dest == "_WAYPOINT" then
        self:RouteToWaypoint()
    else
        self:FindRoute(dest)
    end
end

-----------------------------------------------------------
-- DISPLAY ROUTE IN GUI
-----------------------------------------------------------

function addon:DisplayRouteInGUI(path, totalCost, previous, atNode, initialTime, initialMethod, startNodeName,
    usedTeleport)
    if not addon.MapzerothFrame then
        return
    end

    local frame = addon.MapzerothFrame
    local scrollChild = frame.routeScrollChild

    -- Clear existing route steps
    for _, step in ipairs(frame.routeSteps) do
        step:Hide()
        step:SetParent(nil)
    end
    frame.routeSteps = {}

    -- Build step list
    local steps = {}
    local stepNum = 1

    -- Handle teleport start
    if usedTeleport then
        local firstPrev = previous[path[1]]
        local abilityName = firstPrev.abilityName

        if abilityName == "Hearthstone" then
            table.insert(steps, {
                num = stepNum,
                method = firstPrev.method,
                time = firstPrev.cost,
                abilityName = abilityName,
                itemID = firstPrev.itemID,
                spellID = firstPrev.spellID
            })
        else
            table.insert(steps, {
                num = stepNum,
                method = firstPrev.method,
                destination = self.TravelGraph:GetNodeByID(path[1]).name,
                time = firstPrev.cost,
                abilityName = abilityName,
                destinationName = firstPrev.destinationName,
                itemID = firstPrev.itemID,
                spellID = firstPrev.spellID
            })
            stepNum = stepNum + 1
        end
    else
        -- Normal walking start
        if not atNode then
            local methodText = initialMethod == "fly" and "fly" or "walk"
            table.insert(steps, {
                num = stepNum,
                method = methodText,
                destination = startNodeName,
                time = initialTime
            })
            stepNum = stepNum + 1
        end
    end

    -- Add path steps
    for i = 1, #path do
        local nodeID = path[i]
        local node = self.TravelGraph:GetNodeByID(nodeID)

        if i == 1 and (usedTeleport or atNode) then
            -- Skip or show as "Start"
        elseif i > 1 then
            local prevInfo = previous[nodeID]

            -- Handle synthetic waypoint node
            if nodeID == "_WAYPOINT_DESTINATION" then
                table.insert(steps, {
                    num = stepNum,
                    method = prevInfo.method,
                    destination = "Waypoint",
                    time = prevInfo.cost,
                    abilityName = prevInfo.abilityName,
                    destinationName = prevInfo.destinationName,
                    itemID = prevInfo.itemID,
                    spellID = prevInfo.spellID
                })
                stepNum = stepNum + 1
            elseif node then
                table.insert(steps, {
                    num = stepNum,
                    method = prevInfo.method,
                    destination = node.name,
                    time = prevInfo.cost,
                    abilityName = prevInfo.abilityName,
                    itemID = prevInfo.itemID,
                    spellID = prevInfo.spellID
                })
                stepNum = stepNum + 1
            end
        end
    end

    -- Create step frames
    local yOffset = 0
    for _, stepData in ipairs(steps) do
        local stepFrame = self:CreateRouteStepFrame(scrollChild, stepData)
        stepFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
        table.insert(frame.routeSteps, stepFrame)
        yOffset = yOffset + STEP_HEIGHT
    end

    -- Calculate actual total time
    local actualTotal = totalCost
    if not atNode and not usedTeleport then
        actualTotal = actualTotal + initialTime
    end

    -- Create/update total time footer AS THE LAST CARD (inside scroll child)
    if not frame.totalTimeFooter then
        frame.totalTimeFooter = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
        frame.totalTimeFooter:SetSize(FRAME_WIDTH - 50, 35)
        frame.totalTimeFooter:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            tile = false
        })
        frame.totalTimeFooter:SetBackdropColor(unpack(COLOURS.backgroundLight))

        local totalText = frame.totalTimeFooter:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        totalText:SetPoint("CENTER", frame.totalTimeFooter, "CENTER")
        totalText:SetTextColor(unpack(COLOURS.text))
        frame.totalTimeFooter.text = totalText
    end

    -- Position footer as the next card after the last step (no gap)
    frame.totalTimeFooter:ClearAllPoints()
    frame.totalTimeFooter:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
    frame.totalTimeFooter:SetParent(scrollChild)
    frame.totalTimeFooter:Show()

    -- Update total time text
    local minutes = math.floor(actualTotal / 60)
    local seconds = actualTotal % 60
    if minutes > 0 then
        frame.totalTimeFooter.text:SetText(string.format("Total Time: %dm %.0fs", minutes, seconds))
    else
        frame.totalTimeFooter.text:SetText(string.format("Total Time: %.0fs", seconds))
    end

    -- Add footer height to total offset
    yOffset = yOffset + 35

    -- Resize scroll child to fit all content including footer
    scrollChild:SetHeight(math.max(yOffset, 100))

    -- Expand frame
    frame:SetHeight(FRAME_HEIGHT_COLLAPSED + math.min(yOffset + 40, 300))
    frame.routeContainer:Show()
    frame.isExpanded = true
end

-----------------------------------------------------------
-- CREATE ROUTE STEP FRAME (Material Style)
-----------------------------------------------------------

function addon:CreateRouteStepFrame(parent, stepData)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetSize(FRAME_WIDTH - 50, STEP_HEIGHT - 5)

    -- Material backdrop (flat dark card)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        tile = false
    })
    frame:SetBackdropColor(unpack(COLOURS.cardBg))

    -- Step number (left side, small)
    local numText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    numText:SetPoint("LEFT", frame, "LEFT", 8, 0)
    numText:SetText(stepData.num .. ".")
    numText:SetTextColor(unpack(COLOURS.textSecondary))

    -- Icon
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(28, 28)
    icon:SetPoint("LEFT", numText, "RIGHT", 8, 0)

    -- Fetch real icon if available
    local iconPath = nil
    if stepData.itemID then
        iconPath = C_Item.GetItemIconByID(stepData.itemID)
    elseif stepData.spellID then
        local spellInfo = C_Spell.GetSpellInfo(stepData.spellID)
        if spellInfo then
            iconPath = spellInfo.iconID
        end
    end

    -- Fall back to method-based icon
    if not iconPath then
        iconPath = TRAVEL_ICONS[stepData.method] or TRAVEL_ICONS["walk"]
    end
    icon:SetTexture(iconPath)

    -- Build action text
    local actionText
    if stepData.abilityName then
        if stepData.destinationName then
            actionText = string.format("Use %s to %s", stepData.abilityName, stepData.destinationName)
        else
            actionText = string.format("Use %s", stepData.abilityName)
        end
    else
        local methodPrefix = METHOD_DISPLAY_TEXT[stepData.method] or "Go to"
        actionText = string.format("%s %s", methodPrefix, stepData.destination)
    end

    -- Action text (left-aligned after icon)
    local destText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    destText:SetPoint("LEFT", icon, "RIGHT", 8, 0)
    destText:SetPoint("RIGHT", frame, "RIGHT", -60, 0)
    destText:SetJustifyH("LEFT")
    destText:SetText(actionText)
    destText:SetTextColor(unpack(COLOURS.text))

    -- Time text (right-aligned)
    local timeText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    timeText:SetPoint("RIGHT", frame, "RIGHT", -8, 0)
    timeText:SetJustifyH("RIGHT")
    timeText:SetTextColor(unpack(COLOURS.textSecondary))
    timeText:SetText(string.format("%.0fs", stepData.time))

    return frame
end

-----------------------------------------------------------
-- TOGGLE DESTINATION SELECTOR
-----------------------------------------------------------

function addon:ToggleDestinationSelector()
    local frame = addon.MapzerothFrame
    if not frame then
        return
    end

    local selector = frame.destinationSelector

    if selector:IsShown() then
        selector:Hide()
        -- Collapse frame when hiding selector
        frame:SetHeight(FRAME_HEIGHT_COLLAPSED)
        frame.isExpanded = false
    else
        -- Hide route display when opening destination selector
        if frame.routeContainer:IsShown() then
            frame.routeContainer:Hide()
            if frame.totalTimeFooter then
                frame.totalTimeFooter:Hide()
            end
        end

        -- Expand frame to fit selector
        frame:SetHeight(FRAME_HEIGHT_EXPANDED)
        frame.isExpanded = true

        selector:Show()
    end
end
