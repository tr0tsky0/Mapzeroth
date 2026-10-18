local addonName, ns = ...

-- An About page in the game's Settings panel: the addon's version, the Discord button and the author's other
-- addons for this client, each with its CurseForge address in a box to copy (WoW can't open links).
--
-- Shared by all of tr0tsky's addons. The master copy is WoW Addons\shared\AboutPage.lua: change it there and copy
-- it over each addon's copy unchanged. The page needs DiscordLink.lua (ns.CreateDiscordButton) loaded first.
--
--   ns.RegisterAboutPage([parentCategory][, note]) -> the Settings category
--       With parentCategory, the page is an "About" subcategory under the addon's own settings. Without one (an
--       addon with no settings), it is the addon's only entry, under its title. note is an optional line of text
--       shown under the version (credits, a licence).
--   ns.OtherAddons() -> { { id, title, notes, url, installed }, ... }
--       The author's other addons for this client. Mapzeroth draws its own themed About page from it (and gives
--       each id's notes its own locale key), so it loads this file without DiscordLink.lua.
--
-- Strings go through ns.L when the addon has one. The page is filled the first time it is shown.

-- tr0tsky's addons. folders lists every folder name the addon can load under (release and dev), so the page can
-- tell which one it is in and which are installed. An entry without url (not on CurseForge yet) isn't listed.
local ADDONS = {
    {
        id = "mapzeroth",
        title = "Mapzeroth",
        notes = "Routes to anywhere by portal, flight, ship and hearthstone.",
        folders = { "Mapzeroth", "Mapzeroth-Rebuild" },
        url = "https://www.curseforge.com/wow/addons/mapzeroth",
        forever = true, retail = true,
    },
    {
        id = "sllcm",
        title = "Skyborne Leyline & Convergence Marker",
        notes = "Marks leylines and elemental convergences, shared live between players.",
        folders = { "SkyborneLeyLineConvergenceMarker", "SkyborneLeyLineConvergenceMarker-Dev" },
        url = "https://www.curseforge.com/wow/addons/sllcm",
        forever = true,
    },
    {
        id = "greyquestsmatter",
        title = "Grey Quests Matter",
        notes = "Warns when a grey quest leads to follow-up quests that are not grey.",
        folders = { "GreyQuestsMatter" },
        url = "https://www.curseforge.com/wow/addons/grey-quests-matter",
        forever = true,
    },
    {
        id = "housingreps",
        title = "Housing Reputations",
        notes = "Shows reputations that grant housing rewards.",
        folders = { "HousingReps", "HousingReps_Dev" },
        url = "https://www.curseforge.com/wow/addons/housing-reps",
        retail = true,
    },
}

local PAD, ROW_GAP = 16, 14
local BOX_WIDTH = 380

local function L(key)
    return ns.L and ns.L[key] or key
end

local function metadata(field)
    local get = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    return get and get(addonName, field)
end

local function addonExists(name)
    if C_AddOns and C_AddOns.DoesAddOnExist then
        return C_AddOns.DoesAddOnExist(name)
    end
    return GetAddOnInfo ~= nil and GetAddOnInfo(name) ~= nil
end

-- Forever reports interface 1.x (16001), Retail 12.x.
local function isRetail()
    return (select(4, GetBuildInfo())) >= 100000
end

local function contains(list, value)
    for _, v in ipairs(list) do
        if v == value then return true end
    end
    return false
end

local function anyInstalled(folders)
    for _, name in ipairs(folders) do
        if addonExists(name) then return true end
    end
    return false
end

function ns.OtherAddons()
    local retail = isRetail()
    local others = {}
    for _, entry in ipairs(ADDONS) do
        if entry.url and not contains(entry.folders, addonName)
            and ((retail and entry.retail) or (not retail and entry.forever)) then
            others[#others + 1] = { id = entry.id, title = entry.title, notes = entry.notes, url = entry.url,
                                    installed = anyInstalled(entry.folders) }
        end
    end
    return others
end

-- A box holding text to select and copy, not edit.
local function copyBox(parent, text)
    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetSize(BOX_WIDTH, 20)
    box:SetAutoFocus(false)
    box:SetText(text)
    box:SetCursorPosition(0)
    box:SetScript("OnTextChanged", function(self, byUser)
        if byUser then
            self:SetText(text)
            self:HighlightText()
        end
    end)
    box:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    box:SetScript("OnEditFocusLost", function(self) self:HighlightText(0, 0) end)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    box:SetScript("OnKeyUp", function(self, key)
        if key == "C" and IsControlKeyDown() then self:ClearFocus() end
    end)
    return box
end

local function fill(frame, note)
    local title = metadata("Title") or addonName
    local author = metadata("Author") or "tr0tsky"
    local version = metadata("Version") or "?"

    local heading = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    heading:SetPoint("TOPLEFT", PAD, -PAD)
    heading:SetText(title)

    local byline = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    byline:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -6)
    byline:SetText(string.format(L("Version %s by %s"), version, author))
    local last = byline

    if note then
        local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        text:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, -6)
        text:SetPoint("RIGHT", frame, "RIGHT", -PAD, 0)
        text:SetJustifyH("LEFT")
        text:SetText(note)
        last = text
    end

    local ask = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    ask:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, -ROW_GAP - 4)
    ask:SetText(L("Questions, bug reports and ideas:"))
    local discord = ns.CreateDiscordButton(frame)
    discord:SetPoint("LEFT", ask, "RIGHT", 10, 0)
    last = ask

    local others = ns.OtherAddons()
    if #others == 0 then return end

    local more = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    more:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, -ROW_GAP * 2)
    more:SetText(string.format(L("More addons by %s"), author))
    last = more

    local gap = ROW_GAP
    for _, entry in ipairs(others) do
        local name = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        name:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, -gap)
        if entry.installed then
            name:SetText(entry.title .. "  |cff40ff40" .. L("Installed") .. "|r")
        else
            name:SetText(entry.title)
        end

        local notes = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        notes:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -3)
        notes:SetText(L(entry.notes))

        -- The template draws its left edge outside the box, so the box sits a little in. The next row anchors to
        -- the notes line and clears the box by the gap.
        local box = copyBox(frame, entry.url)
        box:SetPoint("TOPLEFT", notes, "BOTTOMLEFT", 6, -3)
        last = notes
        gap = 3 + 20 + ROW_GAP
    end
end

function ns.RegisterAboutPage(parentCategory, note)
    if not (Settings and Settings.RegisterCanvasLayoutCategory) then return end

    local frame = CreateFrame("Frame")
    frame:Hide()
    frame:SetScript("OnShow", function(self)
        self:SetScript("OnShow", nil)
        fill(self, note)
    end)

    local category
    if parentCategory then
        category = Settings.RegisterCanvasLayoutSubcategory(parentCategory, frame, L("About"))
    else
        category = Settings.RegisterCanvasLayoutCategory(frame, metadata("Title") or addonName)
        Settings.RegisterAddOnCategory(category)
    end
    return category
end
