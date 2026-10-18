local addonName, addon = ...

-- The settings page, in the game's own Settings window (Game Menu > Options > AddOns >
-- Mapzeroth, or /mapzeroth settings): how long a loading screen counts for in a route, the size of
-- our windows, the theme, whether the route is drawn on the map and on the minimap, icons or colour bars beside route steps, and (Forever) sharing ley line sightings. The page is built from our own themed widgets and handed to the
-- game as a canvas, so it follows the theme like everything else. What the settings mean and
-- how they are kept is Options.lua's; this file only draws them.
--
-- A second page under it, "Picker", has a checkbox for each pick the picker can offer above its places
-- (Sections:PickChoices), to leave out the ones a player doesn't want. A third, "About", has the version, the Discord
-- invite and the author's other addons.

local OptionsPanel = {}
addon.OptionsPanel = OptionsPanel

local L = addon.L
local Theme = addon.Theme
local Options = addon.Options

local PAD = 20
local CONTENT_HEIGHT = 864      -- how tall the settings are laid out; the page scrolls when the window is shorter
local SHARE_ROW = 104           -- and the extra rows for sharing ley line sightings, on a dataset with ley lines (Forever):
                                -- sharing, with its "How it works" link between its title and description,
local DETECT_ROW = 80           -- and finding nodes on the minimap
local widgets = {}
local menuHost                  -- where the dropdowns' lists go: outside the scrolled part, so they aren't clipped

-- One option per row: its label and description on the left, and its control (a dropdown, all one width) at the
-- right-hand edge, level with the label. The description stops short of the control, whatever width the page has
-- (fitTexts, below, sets that as the page is sized).
local CONTROL_WIDTH = 150
local GAP = 16                      -- between a description and the control beside it
local START_WIDTH = 600             -- the page's width until it has been laid out
local texts = {}                    -- the descriptions to fit: { hint = fontstring, beside = true when a control sits at its right }

local function textWidth(pageWidth, beside)
    return math.max(160, pageWidth - 2 * PAD - (beside and (CONTROL_WIDTH + GAP) or 0))
end

local function fitTexts(pageWidth)
    for _, t in ipairs(texts) do t.hint:SetWidth(textWidth(pageWidth, t.beside)) end
end

local function optionRow(parent, top, label, description)
    local title = Theme:Text(parent, "body")
    title:SetPoint("TOPLEFT", PAD, -top)
    title:SetText(label)
    local hint = Theme:Text(parent, "dim")
    hint:SetPoint("TOPLEFT", PAD, -(top + 20))
    hint:SetWidth(textWidth(START_WIDTH, true))
    hint:SetWordWrap(true)
    hint:SetText(description)
    texts[#texts + 1] = { hint = hint, beside = true }
    return title, hint
end

-- An on/off setting.
local function toggleRow(parent, top, key, label, description)
    local title, hint = optionRow(parent, top, label, description)
    local choices = { { id = true, label = L["OPT_ON"] }, { id = false, label = L["OPT_OFF"] } }
    local dropdown = Theme:Dropdown(parent, CONTROL_WIDTH, choices, function(id) Options:Set(key, id) end, menuHost)
    dropdown.button:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -PAD, -(top + 2))
    dropdown.title, dropdown.hint = title, hint
    dropdown.key = key
    return dropdown
end

-- A label, a description, and a slider bound to one numeric setting, with its value beside it.
local function sliderRow(parent, top, key, label, description, formatValue)
    local title = Theme:Text(parent, "body")
    title:SetPoint("TOPLEFT", PAD, -top)
    title:SetText(label)

    local hint = Theme:Text(parent, "dim")
    hint:SetPoint("TOPLEFT", PAD, -(top + 20))
    hint:SetWidth(textWidth(START_WIDTH, false))
    hint:SetWordWrap(true)
    hint:SetText(description)
    texts[#texts + 1] = { hint = hint, beside = false }

    local slider = Theme:Slider(parent, 300)
    slider:SetPoint("TOPLEFT", PAD, -(top + 58))
    local min, max, step = Options:Range(key)
    slider:SetMinMaxValues(min, max)
    slider:SetValueStep(step)

    local value = Theme:Text(parent, "accent")
    value:SetPoint("LEFT", slider, "RIGHT", 16, 0)
    slider:SetScript("OnValueChanged", function(_, raw)
        local kept = Options:Set(key, raw) or raw
        value:SetText(formatValue(kept))
    end)
    return { slider = slider, value = value, format = formatValue, key = key }
end

-- A themed panel filling `frame`, holding a page `height` tall that scrolls inside it, with a scroll bar at its right
-- when it doesn't fit. Returns the panel, the page to lay things out on, fit() (call it as the page is shown), and
-- { frame, bar, fit } for tests.
local function scrolledPage(frame, height)
    local panel = Theme:Panel(frame, nil)
    panel:SetPoint("TOPLEFT", 8, -8)
    panel:SetPoint("BOTTOMRIGHT", -8, 8)

    local scroll = CreateFrame("ScrollFrame", nil, panel)
    scroll:SetPoint("TOPLEFT", 12, -12)             -- inside Classic's frame border as well as Modern Dark's line
    scroll:SetPoint("BOTTOMRIGHT", -32, 12)
    local box = CreateFrame("Frame", nil, scroll)
    box:SetSize(START_WIDTH, height)
    scroll:SetScrollChild(box)

    local bar = Theme:Slider(panel, 100, true)
    bar:SetPoint("TOPRIGHT", -16, -16)
    bar:SetPoint("BOTTOMRIGHT", -16, 16)
    bar:SetValueStep(1)
    bar:SetScript("OnValueChanged", function(_, value)
        scroll:SetVerticalScroll(value)
        for _, w in pairs(widgets) do if w.menu then w.menu:Hide() end end     -- a list open under a moved button
    end)
    local function fit()
        local width = scroll:GetWidth()
        if width and width > 0 then
            box:SetWidth(width)
            fitTexts(width)
        end
        local range = math.max(0, height - (scroll:GetHeight() or height))
        bar:SetMinMaxValues(0, range)
        bar:SetShown(range > 0)
        if (bar:GetValue() or 0) > range then bar:SetValue(range) end
    end
    scroll:SetScript("OnSizeChanged", fit)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(_, delta)
        bar:SetValue((bar:GetValue() or 0) - delta * 40)
    end)
    return panel, box, fit, { frame = scroll, bar = bar, fit = fit }
end

-- The hooks the game's Settings window calls on a canvas page. onShow (optional): more to do as the page is shown.
local function settingsHooks(frame, fit, onShow)
    frame.OnCommit = function() end
    frame.OnDefault = function()
        Options:Reset()
        OptionsPanel:Sync()
    end
    frame.OnRefresh = function() OptionsPanel:Sync() end
    frame:SetScript("OnShow", function()
        fit()
        OptionsPanel:Sync()
        if onShow then onShow() end
    end)
end

local CHECK_ROW = 28                -- how far apart the picker page's checkboxes sit

-- The "Picker" page: a heading, what it does, and a checkbox per pick.
function OptionsPanel:BuildPicks()
    local frame = CreateFrame("Frame", "MapzerothRebuildOptionsPicks", UIParent)
    frame:Hide()                                      -- a new frame is shown, and OnShow (which fits it) only runs on a change
    frame.name = L["OPT_PICKS_TITLE"]
    frame.parent = L["OPT_TITLE"]                     -- older clients' options window files it under ours by this
    self.picksFrame = frame

    local faction = UnitFactionGroup and UnitFactionGroup("player")
    local class = UnitClass and select(2, UnitClass("player"))
    local choices = addon.Sections:PickChoices(class, faction, addon:GetTomTomPoints() ~= nil)
    local top = 84                                    -- where the first checkbox goes, under the heading and the text
    local _, box, fit, scroll = scrolledPage(frame, top + #choices * CHECK_ROW + PAD)
    widgets.picksScroll = scroll

    local title = Theme:Text(box, "title")
    title:SetPoint("TOPLEFT", PAD, -(PAD - 8))
    title:SetText(L["OPT_PICKS_TITLE"])
    local hint = Theme:Text(box, "dim")
    hint:SetPoint("TOPLEFT", PAD, -44)
    hint:SetWidth(textWidth(START_WIDTH, false))
    hint:SetWordWrap(true)
    hint:SetText(L["OPT_PICKS_DESC"])
    texts[#texts + 1] = { hint = hint, beside = false }

    widgets.picks = {}
    for i, choice in ipairs(choices) do
        local check = Theme:Checkbox(box, choice.label, function(on) Options:SetShowsPick(choice.key, on) end)
        check:SetPoint("TOPLEFT", PAD, -(top + (i - 1) * CHECK_ROW))
        check.key = choice.key
        widgets.picks[#widgets.picks + 1] = check
    end

    settingsHooks(frame, fit)
    return frame
end

local ABOUT_TOP = 164               -- where the first of the other addons goes, under the version, Discord and heading
local ABOUT_ROW = 84                -- and how far apart they sit: name, what it does, its address to copy
local LINK_WIDTH = 440               -- room for the longest address (grey-quests-matter) in the theme's font

local function metadata(field)
    local get = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    return get and get(addonName, field)
end

-- An address in a box, to select and copy (the game can't open links), not edit. It starts empty: the page fills it
-- when first shown (see BuildAbout).
local function linkBox(parent, url)
    local edit = Theme:EditBox(parent, LINK_WIDTH, 28)
    edit.url = url
    edit:SetScript("OnTextChanged", function(self, byUser)
        if byUser then
            self:SetText(url)
            self:HighlightText()
        end
    end)
    edit:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    edit:SetScript("OnEditFocusLost", function(self) self:HighlightText(0, 0) end)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    edit:SetScript("OnKeyUp", function(self, key)
        if key == "C" and IsControlKeyDown and IsControlKeyDown() then self:ClearFocus() end
    end)
    return edit
end

-- The "About" page: the version, the Discord invite, and the author's other addons for this client with their
-- CurseForge addresses (the list is the shared AboutPage.lua's, the same in all of them).
function OptionsPanel:BuildAbout()
    local frame = CreateFrame("Frame", "MapzerothRebuildOptionsAbout", UIParent)
    frame:Hide()                                      -- a new frame is shown, and OnShow (which fills it) only runs on a change
    frame.name = L["OPT_ABOUT_TITLE"]
    frame.parent = L["OPT_TITLE"]                     -- older clients' options window files it under ours by this
    self.aboutFrame = frame

    local others = addon.OtherAddons and addon.OtherAddons() or {}
    local _, box, fit, scroll = scrolledPage(frame, ABOUT_TOP + #others * ABOUT_ROW + PAD)
    widgets.aboutScroll = scroll
    local author = metadata("Author") or "tr0tsky"

    local title = Theme:Text(box, "title")
    title:SetPoint("TOPLEFT", PAD, -(PAD - 8))
    title:SetText(L["OPT_TITLE"])
    widgets.aboutVersion = Theme:Text(box, "body")
    widgets.aboutVersion:SetPoint("TOPLEFT", PAD, -44)
    widgets.aboutVersion:SetText(L["OPT_ABOUT_VERSION"]:format(metadata("Version") or "?", author))

    local ask = Theme:Text(box, "body")
    ask:SetPoint("TOPLEFT", PAD, -84)
    ask:SetText(L["OPT_ABOUT_ASK"])
    widgets.discord = Theme:BrandButton(box, "discord", "Discord", 24)
    widgets.discord:SetPoint("LEFT", ask, "RIGHT", 12, 0)
    widgets.discord:SetScript("OnClick", function() addon.LinkPopup:Show(L["DISCORD_TITLE"], addon.DISCORD_URL) end)

    widgets.others = {}
    if #others > 0 then
        local more = Theme:Text(box, "accent")
        more:SetPoint("TOPLEFT", PAD, -132)
        more:SetText(L["OPT_ABOUT_MORE"]:format(author))
    end
    for i, other in ipairs(others) do
        local top = ABOUT_TOP + (i - 1) * ABOUT_ROW
        local row = { id = other.id }
        row.name = Theme:Text(box, "body")
        row.name:SetPoint("TOPLEFT", PAD, -top)
        row.name:SetText(other.title)
        if other.installed then
            row.installed = Theme:Text(box, "accent")
            row.installed:SetPoint("LEFT", row.name, "RIGHT", 10, 0)
            row.installed:SetText(L["OPT_ABOUT_INSTALLED"])
        end
        row.notes = Theme:Text(box, "dim")
        row.notes:SetPoint("TOPLEFT", PAD, -(top + 20))
        row.notes:SetWidth(textWidth(START_WIDTH, false))
        row.notes:SetWordWrap(true)
        row.notes:SetText(L["ABOUT_NOTES_" .. other.id:upper()])
        texts[#texts + 1] = { hint = row.notes, beside = false }
        row.link = linkBox(box, other.url)
        row.link:SetPoint("TOPLEFT", PAD, -(top + 42))
        widgets.others[#widgets.others + 1] = row
    end

    -- The page is built hidden at login, and an edit box given its text before it has ever been shown sits scrolled
    -- to the end of it, blank. So the addresses go in once the page is on screen.
    settingsHooks(frame, fit, function()
        for _, row in ipairs(widgets.others) do
            if row.link:GetText() ~= row.link.url then
                row.link:SetText(row.link.url)
                row.link:SetCursorPosition(0)
            end
        end
    end)
    return frame
end

function OptionsPanel:Build()
    local frame = CreateFrame("Frame", "MapzerothRebuildOptions", UIParent)
    frame:Hide()                                      -- a new frame is shown, and OnShow (which fits it) only runs on a change
    frame.name = L["OPT_TITLE"]
    self.frame = frame

    local panel, box, fit, scroll = scrolledPage(frame, CONTENT_HEIGHT + (addon.LeyLineSpell and SHARE_ROW + DETECT_ROW or 0))
    menuHost = panel
    widgets.scroll = scroll

    local title = Theme:Text(box, "title")
    title:SetPoint("TOPLEFT", PAD, -(PAD - 8))
    title:SetText(L["OPT_TITLE"])

    widgets.tax = sliderRow(box, 64, "loadingScreenTax", L["OPT_TAX"], L["OPT_TAX_DESC"],
        function(v) return L["OPT_SECONDS"]:format(v) end)
    widgets.cooldown = sliderRow(box, 168, "maxCooldown", L["OPT_MAX_COOLDOWN"], L["OPT_MAX_COOLDOWN_DESC"],
        function(v)
            local _, top = Options:Range("maxCooldown")
            return (v >= top and L["OPT_HOURS_PLUS"] or L["OPT_HOURS"]):format(v)
        end)
    widgets.scale = sliderRow(box, 272, "scale", L["OPT_SCALE"], L["OPT_SCALE_DESC"],
        function(v) return L["OPT_PERCENT"]:format(math.floor(v * 100 + 0.5)) end)

    optionRow(box, 376, L["OPT_THEME"], L["OPT_THEME_DESC"])
    local choices = {}
    for _, id in ipairs(Theme:List()) do choices[#choices + 1] = { id = id, label = Theme:Label(id) } end
    widgets.theme = Theme:Dropdown(box, CONTROL_WIDTH, choices, function(id) Options:Set("theme", id) end, menuHost)
    widgets.theme.button:SetPoint("TOPRIGHT", box, "TOPRIGHT", -PAD, -378)

    widgets.routeMap = toggleRow(box, 456, "showRouteOnMap", L["OPT_ROUTE_MAP"], L["OPT_ROUTE_MAP_DESC"])
    widgets.routeMinimap = toggleRow(box, 536, "showRouteOnMinimap", L["OPT_ROUTE_MINIMAP"], L["OPT_ROUTE_MINIMAP_DESC"])
    if not (addon.MinimapLines and addon.MinimapLines:IsAvailable()) then
        widgets.routeMinimap.hint:SetText(L["OPT_MINIMAP_UNAVAILABLE"])       -- it can't be done here: say so
        widgets.routeMinimap.button:Disable()
    end
    widgets.assumeFlights = toggleRow(box, 616, "assumeFlightsFound", L["OPT_ASSUME_FLIGHTS"], L["OPT_ASSUME_FLIGHTS_DESC"])

    optionRow(box, 696, L["OPT_STEP_MARKERS"], L["OPT_STEP_MARKERS_DESC"])
    widgets.stepMarkers = Theme:Dropdown(box, CONTROL_WIDTH,
        { { id = "icon", label = L["OPT_MARKERS_ICON"] }, { id = "chip", label = L["OPT_MARKERS_CHIP"] } },
        function(id) Options:Set("stepMarkers", id) end, menuHost)
    widgets.stepMarkers.button:SetPoint("TOPRIGHT", box, "TOPRIGHT", -PAD, -698)

    widgets.hideMinimap = toggleRow(box, 776, "hideMinimapButton", L["OPT_HIDE_MINIMAP"], L["OPT_HIDE_MINIMAP_DESC"])

    if addon.LeyLineSpell then
        widgets.share = toggleRow(box, 856, "shareSightings", L["OPT_SHARE"], L["OPT_SHARE_DESC"])
        widgets.shareHow = Theme:Link(box, L["SHARE_HOW"], function() return addon.SharePrompt:HowItWorksLines() end)
        -- Under the sharing title, ahead of its description: it covers both sharing rows.
        widgets.shareHow:SetPoint("TOPLEFT", box, "TOPLEFT", PAD, -(856 + 20))
        widgets.share.hint:ClearAllPoints()
        widgets.share.hint:SetPoint("TOPLEFT", widgets.shareHow, "BOTTOMLEFT", 0, -6)
        widgets.detect = toggleRow(box, 856 + SHARE_ROW, "detectMinimapNodes", L["OPT_DETECT"], L["OPT_DETECT_DESC"])
        if addon.LeyShare:SllcmLoaded() then
            -- That addon shares and scans instead (and has its own settings): say so in the titles, grey the rows out.
            widgets.share.title:SetText(L["OPT_SHARE_SLLCM_TITLE"])
            widgets.detect.title:SetText(L["OPT_DETECT_SLLCM_TITLE"])
            for _, row in ipairs({ widgets.share, widgets.detect }) do
                Theme:SetTextStyle(row.title, "dim")
                row:SetEnabled(false)
            end
        end
    end

    settingsHooks(frame, fit)

    self.widgets = widgets
    return frame
end

-- Show the current settings in the controls.
function OptionsPanel:Sync()
    if not self.frame then return end
    widgets.tax.slider:SetValue(Options:Get("loadingScreenTax"))
    widgets.tax.value:SetText(widgets.tax.format(Options:Get("loadingScreenTax")))
    widgets.cooldown.slider:SetValue(Options:Get("maxCooldown"))
    widgets.cooldown.value:SetText(widgets.cooldown.format(Options:Get("maxCooldown")))
    widgets.scale.slider:SetValue(Options:Get("scale"))
    widgets.scale.value:SetText(widgets.scale.format(Options:Get("scale")))
    widgets.theme:SetValue(Options:Get("theme"))
    widgets.routeMap:SetValue(Options:Get("showRouteOnMap"))
    widgets.routeMinimap:SetValue(Options:Get("showRouteOnMinimap"))
    widgets.assumeFlights:SetValue(Options:Get("assumeFlightsFound"))
    widgets.stepMarkers:SetValue(Options:Get("stepMarkers"))
    widgets.hideMinimap:SetValue(Options:Get("hideMinimapButton"))
    -- Off while SLLCM is loaded, whatever is saved: Mapzeroth isn't sharing then.
    if widgets.share then widgets.share:SetValue(not widgets.share.disabled and Options:Get("shareSightings")) end
    if widgets.detect then widgets.detect:SetValue(not widgets.detect.disabled and Options:Get("detectMinimapNodes")) end
    for _, check in ipairs(widgets.picks or {}) do check:SetChecked(Options:ShowsPick(check.key)) end
end

-- Add the page to the game's Settings window (once).
function OptionsPanel:Register()
    if self.registered then return true end
    if not self.frame then self:Build() end
    if not self.picksFrame then self:BuildPicks() end
    if not self.aboutFrame then self:BuildAbout() end
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        self.category = Settings.RegisterCanvasLayoutCategory(self.frame, self.frame.name)
        if Settings.RegisterCanvasLayoutSubcategory then
            self.picksCategory = Settings.RegisterCanvasLayoutSubcategory(self.category, self.picksFrame, self.picksFrame.name)
            self.aboutCategory = Settings.RegisterCanvasLayoutSubcategory(self.category, self.aboutFrame, self.aboutFrame.name)
        end
        Settings.RegisterAddOnCategory(self.category)
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(self.frame)            -- older clients
        InterfaceOptions_AddCategory(self.picksFrame)
        InterfaceOptions_AddCategory(self.aboutFrame)
    else
        return false
    end
    self.registered = true
    return true
end

function OptionsPanel:Open()
    if not self:Register() then return false end
    if Settings and Settings.OpenToCategory and self.category then
        Settings.OpenToCategory(self.category:GetID())
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(self.frame)
    end
    return true
end
