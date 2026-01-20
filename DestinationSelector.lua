-- DestinationSelector.lua
-- Categorised, filterable destination picker for Mapzeroth (MATERIAL EDITION)
local addonName, addon = ...

local CATEGORY_ORDER = {"all", "city", "dungeon", "raid"}
local CATEGORY_LABELS = {
    all = "All",
    city = "Cities",
    dungeon = "Dungeons",
    raid = "Raids"
}

local SEARCH_PLACEHOLDERS = {
    all = "Search destinations...",
    city = "Search cities...",
    dungeon = "Search dungeons...",
    raid = "Search raids..."
}

local SELECTOR_WIDTH = 370
local SELECTOR_HEIGHT = 300
local TAB_HEIGHT = 25
local SEARCH_BOX_HEIGHT = 30
local RESULT_BUTTON_HEIGHT = 22

-----------------------------------------------------------
-- BUILD DESTINATION SELECTOR FRAME
-----------------------------------------------------------

function addon:CreateDestinationSelector(parentFrame)
    -- Container frame
    local selector = CreateFrame("Frame", nil, parentFrame, "BackdropTemplate")
    selector:SetSize(SELECTOR_WIDTH, SELECTOR_HEIGHT)
    selector:SetBackdrop({
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
    selector:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    selector:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    -- State
    selector.activeCategory = "all"
    selector.searchText = ""
    selector.resultButtons = {}

    -----------------------------------------------------------
    -- CATEGORY TABS
    -----------------------------------------------------------

    local tabContainer = CreateFrame("Frame", nil, selector)
    tabContainer:SetPoint("TOPLEFT", selector, "TOPLEFT", 5, -5)
    tabContainer:SetSize(SELECTOR_WIDTH - 10, TAB_HEIGHT)

    local tabWidth = (SELECTOR_WIDTH - 10) / #CATEGORY_ORDER
    local tabs = {}

    for i, category in ipairs(CATEGORY_ORDER) do
        local tab = CreateFrame("Button", nil, tabContainer, "BackdropTemplate")
        tab:SetSize(tabWidth - 2, TAB_HEIGHT)
        tab:SetPoint("LEFT", tabContainer, "LEFT", (i - 1) * tabWidth, 0)

        tab:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = nil,
            tile = false
        })

        -- Visual state
        local function UpdateTabAppearance()
            if selector.activeCategory == category then
                tab:SetBackdropColor(0.2, 0.4, 0.6, 1)
            else
                tab:SetBackdropColor(0.15, 0.15, 0.15, 1)
            end
        end

        UpdateTabAppearance()

        -- Tab label
        local label = tab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("CENTER")
        label:SetText(CATEGORY_LABELS[category])

        -- Click handler
        tab:SetScript("OnClick", function()
            selector.activeCategory = category

            -- Update all tab appearances
            for _, t in ipairs(tabs) do
                t.updateAppearance()
            end

            local newPlaceholder = SEARCH_PLACEHOLDERS[category] or "Search destinations..."
            selector.placeholder:SetText(newPlaceholder)

            -- Refresh results
            addon:RefreshDestinationResults(selector)
        end)

        -- Hover effect
        tab:SetScript("OnEnter", function()
            if selector.activeCategory ~= category then
                tab:SetBackdropColor(0.25, 0.25, 0.25, 1)
            end
        end)
        tab:SetScript("OnLeave", function()
            UpdateTabAppearance()
        end)

        tab.updateAppearance = UpdateTabAppearance
        tabs[i] = tab
    end

    -----------------------------------------------------------
    -- SEARCH BOX
    -----------------------------------------------------------

    local searchBox = CreateFrame("EditBox", nil, selector, "InputBoxTemplate")
    searchBox:SetPoint("TOPLEFT", tabContainer, "BOTTOMLEFT", 10, -8)
    searchBox:SetSize(SELECTOR_WIDTH - 30, SEARCH_BOX_HEIGHT)
    searchBox:SetAutoFocus(false)
    searchBox:SetFontObject(GameFontNormal)
    searchBox:SetMaxLetters(50)

    -- Placeholder text (starts with "all" category)
    local placeholder = searchBox:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    placeholder:SetPoint("LEFT", searchBox, "LEFT", 5, 0)
    placeholder:SetText(SEARCH_PLACEHOLDERS["all"])
    selector.placeholder = placeholder

    searchBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            selector.searchText = self:GetText()
            addon:RefreshDestinationResults(selector)

            -- Hide/show placeholder
            if selector.searchText == "" then
                placeholder:Show()
            else
                placeholder:Hide()
            end
        end
    end)

    searchBox:SetScript("OnEditFocusGained", function()
        placeholder:Hide()
    end)

    searchBox:SetScript("OnEditFocusLost", function()
        if selector.searchText == "" then
            placeholder:Show()
        end
    end)

    searchBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    selector.searchBox = searchBox

    -----------------------------------------------------------
    -- RESULTS SCROLL FRAME
    -----------------------------------------------------------

    local scrollFrame = CreateFrame("ScrollFrame", nil, selector, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", -10, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", selector, "BOTTOMRIGHT", -30, 10)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(SELECTOR_WIDTH - 60, 1)
    scrollFrame:SetScrollChild(scrollChild)

    selector.scrollFrame = scrollFrame
    selector.scrollChild = scrollChild

    -----------------------------------------------------------
    -- INITIAL POPULATION
    -----------------------------------------------------------

    addon:RefreshDestinationResults(selector)

    return selector
end

-----------------------------------------------------------
-- FILTER & POPULATE RESULTS
-----------------------------------------------------------

function addon:RefreshDestinationResults(selector)
    local scrollChild = selector.scrollChild

    -- Hide existing buttons
    for _, btn in ipairs(selector.resultButtons) do
        btn:Hide()
    end

    -- Build filtered node list
    local nodeList = {}

    -- Add waypoint as special first entry
    table.insert(nodeList, {
        id = "_WAYPOINT",
        name = "[WAYPOINT] Active Waypoint",
        category = nil
    })

    -- Gather all nodes with filtering
    for traversalGroup, groupData in pairs(self.TravelGraph.nodes) do
        for nodeID, node in pairs(groupData) do
            local category = node.category or "other"
            local matchesCategory = (selector.activeCategory == "all") or (category == selector.activeCategory)

            local matchesSearch = true
            if selector.searchText and selector.searchText ~= "" then
                local lowerName = string.lower(node.name)
                local lowerDisplayName = string.lower(node.displayName)
                local lowerSearch = string.lower(selector.searchText)
                matchesSearch = string.find(lowerName, lowerSearch, 1, true) ~= nil or string.find(lowerDisplayName, lowerSearch, 1, true) ~= nil
            end

            local matchesFaction = true
            if node.faction then
                -- Node is faction-specific, must match player faction
                matchesFaction = (node.faction == addon.GetPlayerFaction())
            end

            if matchesCategory and matchesSearch and matchesFaction then
                table.insert(nodeList, {
                    id = nodeID,
                    name = node.displayName or node.name,
                    category = category
                })
            end
        end
    end

    -- Sort alphabetically (waypoint always first)
    table.sort(nodeList, function(a, b)
        if a.id == "_WAYPOINT" then
            return true
        end
        if b.id == "_WAYPOINT" then
            return false
        end
        return a.name < b.name
    end)

    -- Create/reuse result buttons
    local yOffset = 0
    for i, entry in ipairs(nodeList) do
        local btn = selector.resultButtons[i]

        if not btn then
            -- Create new button
            btn = CreateFrame("Button", nil, scrollChild, "BackdropTemplate")
            btn:SetSize(SELECTOR_WIDTH - 60, RESULT_BUTTON_HEIGHT)
            btn:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                tile = false
            })
            btn:SetBackdropColor(0, 0, 0, 0) -- Transparent by default

            local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            label:SetPoint("LEFT", btn, "LEFT", 5, 0)
            label:SetPoint("RIGHT", btn, "RIGHT", -5, 0)
            label:SetJustifyH("LEFT")
            btn.label = label

            -- Hover effect
            btn:SetScript("OnEnter", function(self)
                self:SetBackdropColor(0.2, 0.4, 0.6, 0.5)
            end)
            btn:SetScript("OnLeave", function(self)
                self:SetBackdropColor(0, 0, 0, 0)
            end)

            selector.resultButtons[i] = btn
        end

        -- Update button state
        btn.nodeID = entry.id
        btn.label:SetText(entry.name)
        btn:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
        btn:Show()

        -- Click handler (select this destination)
        btn:SetScript("OnClick", function(self)
            addon:SelectDestination(entry.id, entry.name)
        end)

        yOffset = yOffset + RESULT_BUTTON_HEIGHT + 2
    end

    -- Update scroll child height
    scrollChild:SetHeight(math.max(yOffset, scrollChild:GetParent():GetHeight()))
end

-----------------------------------------------------------
-- SELECT DESTINATION
-----------------------------------------------------------

function addon:SelectDestination(nodeID, nodeName)
    if not addon.MapzerothFrame then
        return
    end

    local frame = addon.MapzerothFrame
    frame.selectedDest = nodeID

    -- Update the selection display
    if frame.selectedDestLabel then
        frame.selectedDestLabel:SetText(nodeName)
    end

    -- Debug feedback
    if addon.DEBUG then
        print(string.format("[Mapzeroth] Selected destination: %s (%s)", nodeName, nodeID))
    end
end

-----------------------------------------------------------
-- TOGGLE SELECTOR VISIBILITY
-----------------------------------------------------------

function addon:ToggleDestinationSelector()
    if not addon.MapzerothFrame then
        return
    end

    local selector = addon.MapzerothFrame.destinationSelector
    if not selector then
        return
    end

    if selector:IsShown() then
        selector:Hide()
    else
        selector:Show()
        -- Clear search and reset to "All" when opening
        selector.searchText = ""
        selector.searchBox:SetText("")
        selector.activeCategory = "all"
        selector.placeholder:SetText(SEARCH_PLACEHOLDERS["all"])

        -- Update tab appearances
        for _, child in ipairs(selector:GetChildren()) do
            if child.updateAppearance then
                child.updateAppearance()
            end
        end

        addon:RefreshDestinationResults(selector)
    end
end
