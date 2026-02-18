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
    accent = {0.2, 0.5, 0.9, 1},
    accentHover = {0.3, 0.6, 1, 1},
    hoverBg = {0.2, 0.4, 0.6, 0.5},
    cardBg = {0.1, 0.1, 0.1, 0.8}
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
        self:SetBackdropColor(0.4, 0.1, 0.1, 0.8)
        symbol:SetTextColor(1, 1, 1, 1)
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0, 0, 0, 0)
        symbol:SetTextColor(unpack(COLOURS.textSecondary))
    end)

    return btn
end

-----------------------------------------------------------
-- HELPER: APPLY WINDOW SCALE TO ALL FRAMES
-----------------------------------------------------------

function addon:ApplyWindowScale(scale)
    if addon.MapzerothFrame then
        addon.MapzerothFrame:SetScale(scale)
    end
    if addon.AboutFrame then
        addon.AboutFrame:SetScale(scale)
    end

    if addon.RouteExecutionFrame then
        addon.RouteExecutionFrame:SetScale(scale)
    end

    if addon.ApplyGPSScale then
        addon:ApplyGPSScale(scale)
    end
end

-----------------------------------------------------------
-- MAIN FRAME CREATION
-----------------------------------------------------------

function addon:CreateGUI()
    if addon.MapzerothFrame then
        return addon.MapzerothFrame
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

    -- Apply saved scale
    local savedScale = MapzerothDB.settings.windowScale or 1.0
    frame:SetScale(savedScale)

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
        logo:SetVertexColor(1, 1, 1)
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

    local routeContainer = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    routeContainer:SetPoint("TOPLEFT", selectorToggleBtn, "BOTTOMLEFT", 0, -10)
    routeContainer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
    routeContainer:Hide()
    routeContainer:SetClipsChildren(true) -- Clip overflow if route is too long
    frame.routeContainer = routeContainer

    -- No scroll child needed - route steps go directly in routeContainer
    frame.routeScrollChild = routeContainer

    -----------------------------------------------------------
    -- STORAGE & STATE
    -----------------------------------------------------------

    frame.routeSteps = {}
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

    -- Apply saved scale
    local savedScale = MapzerothDB.settings.windowScale or 1.0
    frame:SetScale(savedScale)

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

    -- Close button
    local closeBtn = CreateCloseButton(frame)
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -8)
    closeBtn:SetScript("OnClick", function()
        frame:Hide()
    end)

    -- Logo in About frame
    local aboutLogo = frame:CreateTexture(nil, "ARTWORK")
    aboutLogo:SetTexture("Interface\\AddOns\\Mapzeroth\\Mapzeroth_Logo")
    aboutLogo:SetSize(48, 48)
    aboutLogo:SetPoint("TOP", frame, "TOP", 0, -30)

    -- Content area
    local yOffset = -90

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
    curseLabel:SetWidth(60) 
    curseLabel:SetJustifyH("RIGHT")
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
    kofiLabel:SetWidth(60)
    kofiLabel:SetJustifyH("RIGHT")
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
    discordLabel:SetWidth(60)
    discordLabel:SetJustifyH("RIGHT")
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
    local frame = addon.MapzerothFrame

    if not dest then
        print("[Mapzeroth] Please select a destination")
        return
    end

    -- Hide destination selector when navigating
    if addon.MapzerothFrame.destinationSelector:IsShown() then
        addon.MapzerothFrame.destinationSelector:Hide()
    end

    -- Collapse main frame
    frame:SetHeight(FRAME_HEIGHT_COLLAPSED)
    frame.isExpanded = false

    if dest == "_WAYPOINT" then
        self:FindRoute("_WAYPOINT_DESTINATION")
    else
        self:FindRoute(dest)
    end
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
