local addonName, addon = ...

-- The panel docked to the World Map: a search box, a list of matching places, and, once one
-- is chosen, its route as a list of steps with the total time. Nothing is priced until a
-- destination is chosen, so searching costs nothing; Start hands the route to the navigator
-- (UI/Navigator.lua), which follows it. This is the first slice of the design's docked panel
-- (boards E1 and E2); lines drawn on the map and the pop-out window come later.
--
-- All styling goes through addon.Theme. This file lays things out and moves data into them.
-- Frames are built on first use, never at load, so the file loads anywhere.

local Panel = {}
addon.Panel = Panel

local L = addon.L
local Theme = addon.Theme
local Journey = addon.Journey

local WIDTH, HEIGHT, PAD = 330, 500, 16
local INNER = WIDTH - 2 * PAD
local LIST_TOP = 86
local ROW_H = 38
local ROWS = math.floor((HEIGHT - PAD - LIST_TOP) / ROW_H)   -- as many result rows as the panel has room for
local INDENT = 14                         -- how far an item of an accordion section sits in from its heading
local STEP_H, STEPS = 30, 8               -- STEPS rows at most; fewer show when the route's notes take room (layoutSteps)
local STEPS_TOP = LIST_TOP + 118          -- where the steps start, or lower if the notes above run longer
local STEPS_BOTTOM = HEIGHT - PAD - 28    -- and where they must end: above Start and the "more" note
local PASTE_ROWS = 6                      -- list rows the open paste box takes, under "Multi-stop Route"

local ui                                  -- the widgets, once built
local state = {
    floatShown = false,   -- popped out: the window is open (it opens and closes on its own, not with the map)
    entries = {}, results = {}, offset = 0, selected = 0,
    view = "list", entry = nil, plan = nil, ctx = nil,
    sections = {}, open = {}, priced = false, session = nil, waypoint = nil,     -- the accordion, and whether it has been priced
    pinned = false,       -- a trip is being followed: reopening the map shows its route, not the search page
    stepOffset = 0,       -- how many of the route's steps are scrolled past, when it has more than fit
    stepRows = STEPS,     -- how many step rows fit under the route's notes (layoutSteps)
    stepsTop = STEPS_TOP, -- and where the first of them starts
    docked = true,         -- beside the map (Reanchor), or free-floating where the player dragged it
    dockedHidden = false,  -- docked, and the player hid the panel (the map opens without it)
    detached = false,      -- docked, but the map is closed and the panel is up on its own (Toggle)
}

local function isDocked()
    if ui then return state.docked end
    return addon.Options:Get("docked")
end

-- ---------------------------------------------------------------------------------------
-- Building

-- A row with a marker bar and a name; `withTime` adds a time on the right (route steps).
local function makeRow(parent, top, index, height, withTime)
    local row = Theme:Row(parent, INNER, height)
    row:SetPoint("TOPLEFT", PAD, -(top + (index - 1) * height))
    row.name = Theme:Text(row, "body")
    row.name:SetPoint("TOPLEFT", 14, -5)
    row.name:SetWidth(INNER - 14 - (withTime and 68 or 8))
    row.name:SetWordWrap(false)
    if withTime then
        row.eta = Theme:Text(row, "accent")
        row.eta:SetPoint("RIGHT", -6, 0)
        row.eta:SetJustifyH("RIGHT")
    end
    return row
end

local function build(parent)
    ui = {}
    Panel.widgets = ui                          -- for tests
    local frame = Theme:Panel(parent, "MapzerothRebuildPanel")
    frame:SetSize(WIDTH, HEIGHT)
    -- Stay in the map's strata (a child inherits it) and just sit above the map's own frames.
    frame:SetFrameLevel((parent:GetFrameLevel() or 1) + 20)
    frame:EnableMouse(true)                -- a click here must not reach the map underneath
    frame:EnableMouseWheel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnMouseWheel", function(_, delta) Panel:Scroll(-delta) end)
    -- Only free-floating (state.docked == false) actually moves: docked, a drag on the title
    -- bar is a no-op rather than fighting Reanchor's next map-open/resize repositioning.
    frame:SetScript("OnDragStart", function(self) if not state.docked or state.detached then self:StartMoving() end end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if not state.docked or state.detached then Panel:SavePosition() end
    end)
    ui.frame = frame

    ui.title = Theme:Text(frame, "title")
    ui.title:SetPoint("TOPLEFT", PAD, -PAD)
    ui.title:SetText(L["PANEL_TITLE"])

    -- Beside the map there's often another addon docked to its other side (WorldQuestList and
    -- the like) or the map's own tab row above it, with nowhere to move out of the way to --
    -- this lets the player drag the panel free of them instead.
    ui.pop = Theme:Button(frame, "", 64, 18)
    ui.pop:SetPoint("TOPRIGHT", -PAD, -PAD + 3)
    ui.pop:SetScript("OnClick", function() Panel:SetDocked(not state.docked) end)

    ui.search = Theme:EditBox(frame, INNER, 30)
    ui.search:SetPoint("TOPLEFT", PAD, -46)
    ui.hint = Theme:Text(ui.search, "dim")
    ui.hint:SetPoint("LEFT", 10, 0)
    ui.hint:SetText(L["SEARCH_HINT"])
    local function textChanged(self)
        ui.hint:SetShown(self:GetText() == "")
        ui.clear:SetShown(self:GetText() ~= "")
        Panel:Query(self:GetText())
    end
    -- An X at the right end to empty the box (shown only when there is something to clear).
    ui.clear = Theme:Button(ui.search, "x", 22, 22)
    ui.clear:SetPoint("RIGHT", -4, 0)
    ui.clear:Hide()
    ui.clear:SetScript("OnClick", function()
        ui.search:SetText("")
        textChanged(ui.search)
        ui.search:SetFocus()
    end)
    ui.search:SetTextInsets(8, 32, 0, 0)               -- typing stops short of the X
    ui.search:SetScript("OnTextChanged", textChanged)
    ui.search:SetScript("OnEnterPressed", function() Panel:Choose(state.selected) end)
    ui.search:SetScript("OnEscapePressed", function() Panel:Escape() end)
    ui.search:SetScript("OnArrowPressed", function(_, key)
        if key == "DOWN" then Panel:Move(1) elseif key == "UP" then Panel:Move(-1) end
    end)

    ui.status = Theme:Text(frame, "dim")
    ui.status:SetPoint("TOPLEFT", PAD, -LIST_TOP)
    ui.status:SetWidth(INNER)
    ui.status:SetWordWrap(true)

    -- The results list.
    ui.rows = {}
    for i = 1, ROWS do
        local row = makeRow(frame, LIST_TOP, i, ROW_H, true)
        row.sub = Theme:Text(row, "small")
        row.sub:SetPoint("BOTTOMLEFT", 14, 5)
        row.sub:SetWidth(INNER - 14 - 8)
        row.sub:SetWordWrap(false)
        row:SetScript("OnClick", function(self) Panel:Choose(self.index) end)
        row:HookScript("OnEnter", function(self) Panel:ShowRowTooltip(self) end)
        row:HookScript("OnLeave", function(self) Theme:HideTooltip(self) end)
        ui.rows[i] = row
    end

    -- The paste box: opened in the list under "Multi-stop Route" (Panel:TogglePaste), over the rows it takes.
    ui.paste = CreateFrame("Frame", nil, frame)
    ui.paste:SetSize(INNER - INDENT, PASTE_ROWS * ROW_H)
    ui.paste:Hide()
    ui.pasteArea = Theme:TextArea(ui.paste, INNER - INDENT, PASTE_ROWS * ROW_H - 40)
    ui.pasteArea:SetPoint("TOPLEFT", 0, -2)
    ui.pasteHint = Theme:Text(ui.pasteArea, "dim")
    ui.pasteHint:SetPoint("TOPLEFT", 10, -8)
    ui.pasteHint:SetWidth(INNER - INDENT - 20)
    ui.pasteHint:SetWordWrap(true)
    ui.pasteHint:SetText(L["PASTE_PROMPT"])
    local edit = ui.pasteArea.edit
    edit:SetScript("OnTextChanged", function(self)
        ui.pasteHint:SetShown(self:GetText() == "")
        ui.pasteStatus:SetText("")
    end)
    edit:SetScript("OnEscapePressed", function() Panel:TogglePaste(false) end)
    ui.pasteGo = Theme:Button(ui.paste, L["PASTE_ROUTE"], 80, 24, true)
    ui.pasteGo:SetPoint("BOTTOMRIGHT", 0, 6)
    ui.pasteGo:SetScript("OnClick", function() Panel:RoutePasted(edit:GetText()) end)
    ui.pasteCancel = Theme:Button(ui.paste, L["PASTE_CANCEL"], 80, 24)
    ui.pasteCancel:SetPoint("RIGHT", ui.pasteGo, "LEFT", -8, 0)
    ui.pasteCancel:SetScript("OnClick", function() Panel:TogglePaste(false) end)
    ui.pasteStatus = Theme:Text(ui.paste, "warn")
    ui.pasteStatus:SetPoint("BOTTOMLEFT", 2, 10)
    ui.pasteStatus:SetWidth(INNER - INDENT - 180)
    ui.pasteStatus:SetWordWrap(true)

    -- The route view.
    ui.back = Theme:Button(frame, L["ROUTE_BACK"], 70, 22)
    ui.back:SetPoint("TOPLEFT", PAD, -LIST_TOP)
    ui.back:SetScript("OnClick", function() Panel:Query(ui.search:GetText()) end)

    -- One way or a round trip (there and back to here): a pair that works like radio buttons, beside Back.
    ui.roundTrip = Theme:Checkbox(frame, L["ROUTE_ROUND_TRIP"], function() Panel:SetRoundTrip(true) end)
    ui.roundTrip:SetPoint("TOPRIGHT", -PAD, -LIST_TOP)
    ui.oneWay = Theme:Checkbox(frame, L["ROUTE_ONE_WAY"], function() Panel:SetRoundTrip(false) end)
    ui.oneWay:SetPoint("TOPRIGHT", ui.roundTrip, "TOPLEFT", -12, 0)

    ui.routeTitle = Theme:Text(frame, "title")
    ui.routeTitle:SetPoint("TOPLEFT", PAD, -(LIST_TOP + 30))
    ui.routeTitle:SetWidth(INNER)
    ui.routeTitle:SetWordWrap(false)

    ui.routeTotal = Theme:Text(frame, "accent")
    ui.routeTotal:SetPoint("TOPLEFT", PAD, -(LIST_TOP + 54))

    ui.routeHint = Theme:Text(frame, "warn")
    ui.routeHint:SetPoint("TOPLEFT", PAD, -(LIST_TOP + 74))
    ui.routeHint:SetWidth(INNER)
    ui.routeHint:SetWordWrap(true)

    ui.steps = {}
    for i = 1, STEPS do
        local row = makeRow(frame, STEPS_TOP, i, STEP_H, true)
        row:EnableMouse(false)
        row.name:ClearAllPoints()
        row.name:SetPoint("LEFT", 14, 0)
        row.name:SetWidth(INNER - 14 - 60)
        row.name:SetWordWrap(true)
        row.name:SetMaxLines(2)
        ui.steps[i] = row
    end
    -- The pointer to Skyborne Ley Line & Convergence Marker, under the last step of a ley line or convergence route
    -- (placed by RenderSteps, and only when there is room).
    ui.tip = makeRow(frame, 0, 1, ROW_H, false)
    ui.tip.name:SetPoint("TOPLEFT", 14, -5)
    ui.tip.name:SetText(L["SLLCM_TIP"])
    ui.tip.sub = Theme:Text(ui.tip, "small")
    ui.tip.sub:SetPoint("BOTTOMLEFT", 14, 5)
    ui.tip.sub:SetWidth(INNER - 14 - 8)
    ui.tip.sub:SetWordWrap(false)
    ui.tip.sub:SetText(addon.SLLCM_NAME)
    ui.tip.markerGroup = "hint"
    Theme:Restyle(ui.tip)
    ui.tip:SetScript("OnClick", function() Panel:ShowSllcmLink() end)
    ui.tip:Hide()

    ui.more = Theme:Text(frame, "dim")
    ui.more:SetPoint("BOTTOMLEFT", PAD + 14, PAD + 4)      -- beside Start, never under it

    ui.start = Theme:Button(frame, L["ROUTE_START"], 90, 22, true)
    ui.start:SetPoint("BOTTOMRIGHT", -PAD, PAD)
    ui.start:SetScript("OnClick", function() Panel:StartRoute() end)

    Panel:ApplyScale()
    Panel:SetDocked(addon.Options:Get("docked"), true)
end

-- ---------------------------------------------------------------------------------------
-- Showing things

local function hideList()
    for _, row in ipairs(ui.rows) do row:Hide() end
    ui.paste:Hide()
end

local function showRouteWidgets(show)
    for _, widget in ipairs({ ui.back, ui.routeTitle, ui.routeTotal, ui.routeHint, ui.start, ui.more }) do
        widget:SetShown(show)
    end
    if not show then
        for _, row in ipairs(ui.steps) do row:Hide() end
        ui.tip:Hide()
        ui.oneWay:Hide()
        ui.roundTrip:Hide()
    end
end

-- Whether a destination can be a round trip: anything but a tour (which has its own stops).
function Panel.CanRoundTrip(entry)
    return entry ~= nil and not entry.stops and not entry.action
end

-- The one way / round trip choice: shown for a route that can be either, until its trip is being followed.
local function showTripChoice()
    local shown = state.view == "route" and Panel.CanRoundTrip(state.entry) and not state.pinned
    local round = addon.Options:Get("roundTrip")
    ui.oneWay:SetShown(shown)
    ui.roundTrip:SetShown(shown)
    ui.oneWay:SetChecked(not round)
    ui.roundTrip:SetChecked(round)
end

-- Chosen on the route: one way or a round trip, kept for the next route, and this one planned again that way.
function Panel:SetRoundTrip(round)
    local changed = addon.Options:Get("roundTrip") ~= round
    addon.Options:Set("roundTrip", round)
    if changed and state.view == "route" and state.entry and not state.pinned then
        self:ShowRoute(state.entry)
    else
        showTripChoice()
    end
end

-- The second line of a result: "Trainer - Stormwind - One-Handed Swords, Staves" (the weapons a search matched,
-- else all it teaches), or "City - Stormwind City". Under a heading of the accordion the kind is already said,
-- so a city or town shows just its zone. A pick has none: it is one line (where it goes is chosen with its route).
local function subtitle(entry)
    if entry.pick then return "" end
    if entry.inSection then
        -- Older content mixes cities, dungeons and raids in one list: say which this is.
        local kind = entry.expansion and (entry.raid and "KIND_raid" or entry.group == "instance" and "KIND_dungeon"
            or entry.kind and "KIND_" .. entry.kind)
        if kind and addon:HasString(kind) then
            return entry.zone and (L[kind] .. " - " .. entry.zone) or L[kind]
        end
        -- A dungeon or raid listed by level says its levels: the group finder's range, or the least it allows.
        if entry.minLevel then
            local level = entry.maxLevel and L["SUB_LEVEL_RANGE"]:format(entry.minLevel, entry.maxLevel)
                or L["SUB_MIN_LEVEL"]:format(entry.minLevel)
            return entry.zone and (level .. " - " .. entry.zone) or level
        end
        return entry.zone or ""
    end
    local text = L["GROUP_" .. entry.group]
    if entry.group == "place" and entry.kind and addon:HasString("KIND_" .. entry.kind) then
        text = L["KIND_" .. entry.kind]                     -- "City" or "Town", not "Town or city"
    end
    if entry.zone then text = text .. " - " .. entry.zone end
    local detail = entry.detailHit
    if not detail and entry.details then
        local names = {}
        for _, d in ipairs(entry.details) do names[#names + 1] = d.text end
        detail = table.concat(names, ", ")
    end
    if detail and detail ~= "" then text = text .. " - " .. detail end
    return text
end

-- The travel time on the right of a row: only for the items of an opened section (priced then). A search
-- result shows none, even for a place that was priced when its section was opened; its route is worked out
-- when it is chosen.
function Panel.EtaText(entry)
    if entry.inSection and not entry.pick and entry.eta then return Journey:FormatTime(entry.eta) end
    return ""
end

-- Fills the list rows from state.results, starting at state.offset. A row is a search result, a section
-- heading of the accordion, or one of a section's items (shown with its travel time once priced).
function Panel:Render()
    local pasteAt                                     -- the list row the paste box's first spacer is in
    for i = 1, ROWS do
        local row, entry = ui.rows[i], state.results[state.offset + i]
        if entry and entry.spacer then
            row:Hide()
            local before = state.results[state.offset + i - 1]
            if not (before and before.spacer) then pasteAt = i end
        elseif entry then
            row.index = state.offset + i
            -- An item of a section sits in from its heading: the marker, the name and the line under it together.
            local indent = entry.header and INDENT * (entry.depth or 0)
                or (entry.pick or entry.inSection) and INDENT * (entry.depth or 1) or 0
            row.marker:ClearAllPoints()
            row.marker:SetPoint("LEFT", 4 + indent, 0)
            row.name:ClearAllPoints()
            if entry.pick then
                row.name:SetPoint("LEFT", 14 + indent, 0)          -- one line: in the middle of the row
            else
                row.name:SetPoint("TOPLEFT", 14 + indent, -5)
            end
            row.name:SetWidth(INNER - 14 - 76 - indent)
            row.sub:ClearAllPoints()
            row.sub:SetPoint("BOTTOMLEFT", 14 + indent, 5)
            row.sub:SetWidth(INNER - 14 - 8 - indent)
            if entry.header then
                row.name:SetText((entry.open and "- " or "+ ") .. entry.name)
                row.sub:SetText(L["SECTION_COUNT"]:format(entry.count))
                row.eta:SetText("")
                row.markerGroup = "place"
            else
                row.name:SetText(entry.name)
                row.sub:SetText(subtitle(entry))
                row.eta:SetText(Panel.EtaText(entry))
                row.markerGroup = entry.group
            end
            row.markerMethod, row.markerSource = nil, nil
            Theme:Restyle(row)
            row:SetSelected(row.index == state.selected)
            row:Show()
        else
            row:Hide()
        end
    end
    -- Only all of it or none: scrolled part way out of the list, the box waits until it's back.
    if pasteAt and pasteAt + PASTE_ROWS - 1 <= ROWS then
        ui.paste:ClearAllPoints()
        ui.paste:SetPoint("TOPLEFT", PAD + INDENT, -(LIST_TOP + (pasteAt - 1) * ROW_H))
        ui.paste:Show()
    else
        ui.paste:Hide()
    end
end

-- ---------------------------------------------------------------------------------------
-- The tooltip on a trainer (what it can do for this player)

local MAX_ABILITIES = 10               -- a class trainer's abilities listed by name; the rest are counted

local function professionLines(info, lines)
    if info.has then
        lines[#lines + 1] = { L["TIP_PROF_YOUR_RANK"]:format(info.rank > 0 and L["PROF_RANK_" .. info.rank] or "-"), "body" }
    else
        lines[#lines + 1] = { L["TIP_PROF_NOT_KNOWN"], "dim" }
    end
    local any = false
    for _, npc in ipairs(info.npcs) do
        local text
        if npc.specialty then
            text = L["TIP_PROF_SPECIALTY"]
        elseif npc.top then
            text = L["TIP_PROF_TRAINER"]:format(L["PROF_RANK_" .. npc.top], npc.cap or 75 * npc.top)
        else
            text = L["TIP_PROF_UNKNOWN"]
        end
        any = any or npc.useful
        lines[#lines + 1] = { text, (info.has and npc.useful and not npc.specialty) and "good" or "dim" }
    end
    if info.has and not any then lines[#lines + 1] = { L["TIP_NOTHING_NEW"], "warn" } end
end

local function weaponLines(info, lines)
    if #info.learnable == 0 then
        lines[#lines + 1] = { L["TIP_NOTHING_NEW"], "warn" }
        return
    end
    lines[#lines + 1] = { L["TIP_WEAPON_LEARN"], "body" }
    for _, spellID in ipairs(info.learnable) do
        lines[#lines + 1] = { "  " .. (addon:GetSkillName(spellID) or ("#" .. spellID)), "good" }
    end
end

-- Money as the client writes it (with coin icons), else "1g 24s", leaving out the units that are zero.
local function money(copper)
    local format = (C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString) or GetCoinTextureString or GetMoneyString
    if format then return format(copper) end
    local parts = {}
    for _, unit in ipairs({ { 10000, "g" }, { 100, "s" }, { 1, "c" } }) do
        local n = math.floor(copper / unit[1])
        if unit[1] < 10000 then n = n % 100 end
        if n > 0 then parts[#parts + 1] = n .. unit[2] end
    end
    return #parts > 0 and table.concat(parts, " ") or "0c"
end

local function classLines(status, lines)
    local learnable = status.learnable
    if #learnable == 0 then
        lines[#lines + 1] = { L["TIP_NOTHING_NEW"], "warn" }
    else
        lines[#lines + 1] = { L["TIP_CLASS_LEARN"]:format(#learnable), "body" }
        for i = 1, math.min(#learnable, MAX_ABILITIES) do
            local spell = learnable[i]
            lines[#lines + 1] = { "  " .. (addon.ClassTraining:Label(spell[1]) or ("#" .. spell[1])), "good" }
        end
        if #learnable > MAX_ABILITIES then
            lines[#lines + 1] = { "  " .. L["TIP_MORE"]:format(#learnable - MAX_ABILITIES), "dim" }
        end
        if status.cost > 0 then lines[#lines + 1] = { L["TIP_CLASS_COST"]:format(money(status.cost)), "body" } end
    end
    if status.nextLevel then lines[#lines + 1] = { L["TIP_CLASS_NEXT"]:format(status.nextLevel), "dim" } end
end

-- A trainer pick before a route has chosen which of its places to go to: what all of them together offer. A profession
-- says the player's rank (each trainer's own tiers are for the route's trainer); weapon masters, every weapon one of
-- them can teach this player. Nil for a class pick (it describes itself, every trainer teaching the same).
local function anyTrainerLines(entry, ctx, info)
    if info.kind == "profession" then
        local lines = { { entry.name, "title" } }
        if info.has then
            lines[#lines + 1] = { L["TIP_PROF_YOUR_RANK"]:format(info.rank > 0 and L["PROF_RANK_" .. info.rank] or "-"), "body" }
        else
            lines[#lines + 1] = { L["TIP_PROF_NOT_KNOWN"], "dim" }
        end
        return lines
    end
    if info.kind == "weapon" then
        local learnable, seen = {}, {}
        for _, id in ipairs(entry.nodeIDs or {}) do
            local each = addon.Trainers:Describe(addon.World:GetNode(id), ctx)
            for _, spellID in ipairs(each and each.learnable or {}) do
                if not seen[spellID] then
                    seen[spellID] = true
                    learnable[#learnable + 1] = spellID
                end
            end
        end
        table.sort(learnable)
        local lines = { { entry.name, "title" } }
        weaponLines({ learnable = learnable }, lines)
        if #learnable > 0 then lines[2][1] = L["TIP_WEAPON_LEARN_ANY"] end
        return lines
    end
end

local function trainerLines(entry, ctx)
    local nodeID = entry.pick and entry.nearest or entry.nodeID
    local node = nodeID and addon.World:GetNode(nodeID)
    if not node and entry.pick and entry.nodeIDs then node = addon.World:GetNode(entry.nodeIDs[1]) end
    local info = node and addon.Trainers:Describe(node, ctx)
    if not info then return nil end
    if entry.pick and not entry.nearest and info.kind ~= "class" then return anyTrainerLines(entry, ctx, info) end
    if info.kind == "class" and not info.own then return nil end      -- another class's
    local lines = { { entry.pick and entry.where or entry.name, "title" } }
    if info.otherFaction then
        -- The client's name for the faction ("Horde"), where it has one.
        local faction = _G["FACTION_" .. info.otherFaction:upper()] or info.otherFaction
        lines[#lines + 1] = { L["TIP_OTHER_FACTION"]:format(faction), "warn" }
        return lines
    end
    local status = info.kind == "class" and addon.ClassTraining:Status(ctx)
    if info.kind == "class" and not status then return nil end       -- no data (Modern)
    if info.kind == "profession" then
        professionLines(info, lines)
    elseif info.kind == "weapon" then
        weaponLines(info, lines)
    else
        classLines(status, lines)
    end
    return lines
end

-- The tooltip's lines for a row of the picker, or nil: trainers (what they can do for this player), ley lines and
-- convergences (only where one can be), and tours. A pick has no place chosen until it is routed, so a trainer pick
-- describes what its trainers offer between them; every class trainer of yours teaches the same anyway.
function Panel.TooltipLines(entry, ctx)
    if not entry or entry.header then return nil end
    if entry.action == "tomtom" or entry.action == "paste" then
        return { { entry.name, "title" }, { L[entry.action == "tomtom" and "TIP_TOUR_TOMTOM" or "TIP_TOUR_PASTE"], "body" } }
    elseif entry.group == "leyline" or entry.group == "convergence" then
        return { { entry.pick and entry.where or entry.name, "title" },
                 { L[entry.group == "leyline" and "TIP_LEYLINE" or "TIP_CONVERGENCE"], "body" } }
    elseif entry.group == "trainer" then
        return trainerLines(entry, ctx)
    end
end

function Panel:ShowRowTooltip(row)
    local entry = row.index and state.results[row.index]
    local lines = Panel.TooltipLines(entry, addon:GetPlayerContext())      -- fresh: what they know may have changed
    if lines then Theme:ShowTooltip(row, lines) end
end

local function setStatus(text)
    ui.status:SetText(text or "")
    ui.status:SetShown(text ~= nil and text ~= "")
end

-- Whether to point the player to Skyborne Ley Line & Convergence Marker (it shows where ley lines and convergences
-- have been found, which a "Nearest Potential ..." pick can't know): not once they have it, or said they don't want to see this.
local function sllcmHintWanted()
    if addon.Options:Get("hideSllcmHint") then return false end
    if Panel.ignoreSllcmInstall then return true end          -- set by /mzr sllcm (MapzerothDataTools), to see the pointer with the addon installed
    local isLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
    if isLoaded then
        for _, folder in ipairs(addon.SLLCM_FOLDERS) do
            if isLoaded(folder) then return false end
        end
    end
    return true
end

-- Choosing the pointer offers the address to copy, and a way to stop being shown it.
function Panel:ShowSllcmLink()
    addon.LinkPopup:Show(addon.SLLCM_NAME, addon.SLLCM_URL, function()
        addon.Options:Set("hideSllcmHint", true)
        if ui and state.view == "route" and state.plan then Panel:RenderSteps() end
    end)
end

-- A section's heading and, when it is open, the sections inside it and its items, each a step further in.
-- An item is a copy of its entry (taken once the section is priced), so the same place can sit in two
-- sections at different depths.
-- One item's row, `depth` steps in: a copy of it. inSection: it sits under a heading.
local function addItemRows(rows, item, depth, inSection)
    local row = {}
    for k, v in pairs(item) do row[k] = v end
    row.inSection, row.depth = inSection, depth
    rows[#rows + 1] = row
    -- The open paste box takes rows of its own under its pick (Panel:Render puts it over them).
    if item.action == "paste" and state.pasteOpen then
        for _ = 1, PASTE_ROWS do rows[#rows + 1] = { spacer = true } end
    end
end

local function addSectionRows(rows, section, depth)
    local open = state.open[section.id] == true
    rows[#rows + 1] = { header = true, id = section.id, name = section.title, open = open,
        count = addon.Sections:Count(section), depth = depth }
    if not open then return end
    for _, child in ipairs(section.children or {}) do addSectionRows(rows, child, depth + 1) end
    for _, item in ipairs(section.items) do addItemRows(rows, item, depth + 1, true) end
end

-- What to offer before anything is typed: the top picks, then the accordion (Sections.lua). There is no "Home": the
-- hearthstone is one step of a route, and anyone can click it themselves.
function Panel:ShowMenu(selectID)
    local rows = {}
    for _, item in ipairs(state.sections and state.sections.top or {}) do addItemRows(rows, item, 0) end
    for _, section in ipairs(state.sections or {}) do addSectionRows(rows, section, 0) end
    state.results = rows
    state.selected = #rows > 0 and 1 or 0
    for i, row in ipairs(rows) do
        if row.header and row.id == selectID then state.selected = i end
    end
    local keep = state.selected
    if keep <= state.offset then state.offset = math.max(0, keep - 1) end
    if keep > state.offset + ROWS then state.offset = keep - ROWS end
    self:Render()
end

-- The times need where the player is and a search over the whole map, so it happens when a section of places is first
-- opened, never for the window itself (picks have no time until one is routed).
function Panel:PriceSections()
    if state.priced then return end
    local start = addon:GetPlayerStart()
    state.ctx = addon:GetPlayerContext()         -- fresh, as a route's is: money and cooldowns move on
    local session = start and Journey:Build(state.ctx, start, state.waypoint and { state.waypoint } or nil)
    if session then
        addon.Sections:Price(state.sections, session)
        state.session = session
    end
    state.priced = true
end

function Panel:ToggleSection(id)
    state.open[id] = not state.open[id]
    if state.open[id] and addon.Sections:NeedsPricing(state.sections, id) then self:PriceSections() end
    self:ShowMenu(id)
end

-- What was typed changed (or "go back to the list"): show matching places.
function Panel:Query(text)
    if not ui then return end
    state.view = "list"
    state.pinned = false
    showRouteWidgets(false)
    text = text or ""
    if text == "" then
        state.offset = 0
        self:ShowMenu()
        if #state.results == 0 then setStatus(L["SEARCH_EMPTY"]) else setStatus(nil) end
        return
    end
    for _, entry in ipairs(state.entries) do entry.inSection = nil end
    state.results = addon.Search:Query(state.entries, text, 60)
    state.offset, state.selected = 0, (#state.results > 0) and 1 or 0
    self:Render()
    if #state.results > 0 then setStatus(nil) else setStatus(L["NO_RESULTS"]) end
end

function Panel:Move(delta)
    if state.view ~= "list" or #state.results == 0 then return end
    local n = math.max(1, math.min(#state.results, state.selected + delta))
    while state.results[n] and state.results[n].spacer do n = n + (delta > 0 and 1 or -1) end
    n = math.max(1, math.min(#state.results, n))
    state.selected = n
    if n <= state.offset then state.offset = n - 1 end
    if n > state.offset + ROWS then state.offset = n - ROWS end
    self:Render()
end

function Panel:Scroll(delta)
    if state.view == "route" and state.plan then
        local max = math.max(0, #(state.plan.shown or state.plan.steps) - state.stepRows)
        state.stepOffset = math.max(0, math.min(max, state.stepOffset + delta))
        self:RenderSteps()
        return
    end
    if state.view ~= "list" then return end
    local max = math.max(0, #state.results - ROWS)
    state.offset = math.max(0, math.min(max, state.offset + delta))
    self:Render()
end

-- The route to a destination, worked out now, from where the player is now. A tour (entry.stops) takes many searches:
-- it is planned over several frames (MultiRoute:Run), saying so meanwhile. onReady(plan) (optional) is called once the
-- route is on the panel (plan nil when there is none).
function Panel:ShowRoute(entry, onReady)
    state.view, state.entry, state.plan, state.planned = "route", entry, nil, nil
    hideList()
    showRouteWidgets(true)
    showTripChoice()
    setStatus(nil)
    ui.routeTitle:SetText(entry.name)
    ui.routeTotal:SetText("")
    ui.routeHint:SetText("")
    ui.more:SetText("")
    for _, row in ipairs(ui.steps) do row:Hide() end
    ui.tip:Hide()
    ui.start:SetShown(false)

    local ctx = addon:GetPlayerContext()
    state.ctx = ctx
    local start = addon:GetPlayerStart()
    local session = start and Journey:Build(ctx, start, Journey:ExtrasOf(entry))
    ui.status:ClearAllPoints()
    ui.status:SetPoint("TOPLEFT", PAD, -(LIST_TOP + 74))
    if not session then
        setStatus(L["NOWHERE"])
        if onReady then onReady(nil) end
        return
    end
    local function show(plan, why)
        if state.entry ~= entry then return end          -- the player moved on while it was planned
        state.plan = plan
        setStatus(nil)
        if not plan then
            -- No route: say so, and when only a flight this character may not have found is in the way, which.
            local reason = Journey:HintText(why)
            setStatus(reason and (L["ROUTE_NONE"] .. "\n\n" .. reason) or L["ROUTE_NONE"])
        else
            self:DisplayPlan(entry, plan)
        end
        if onReady then onReady(plan) end
    end
    if entry.stops then
        setStatus(L["ROUTE_PLANNING"])
        addon.MultiRoute:Run(function(yield) return Journey:PlanEntry(session, entry, yield) end, show)
    elseif self.CanRoundTrip(entry) and addon.Options:Get("roundTrip") then
        -- The way there and back, to whichever of its places makes that quickest: what is followed is that entry.
        local plan, trip = Journey:PlanRoundTrip(session, entry)
        state.planned = trip
        show(plan)
    else
        show(Journey:PlanEntry(session, entry))
    end
end

-- Draw a plan's route: the total, the hint, and its steps (the one being followed is marked).
-- The steps start under the route's notes (the hints can wrap to several lines), and as many rows show as fit
-- between there and the bottom; the rest are scrolled to.
local function layoutSteps()
    local hint = ui.routeHint:GetText()
    local height = (hint and hint ~= "" and ui.routeHint:GetStringHeight()) or 0
    local top = math.max(STEPS_TOP, LIST_TOP + 74 + math.ceil(height) + 10)
    state.stepsTop = top
    state.stepRows = math.max(1, math.min(STEPS, math.floor((STEPS_BOTTOM - top) / STEP_H)))
    for i, row in ipairs(ui.steps) do
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", PAD, -(top + (i - 1) * STEP_H))
    end
end

function Panel:DisplayPlan(entry, plan)
    state.view, state.entry, state.plan, state.stepOffset = "route", entry, plan, 0
    state.followedRow = nil                       -- shown afresh: the current step is scrolled to
    hideList()
    showRouteWidgets(true)
    showTripChoice()
    setStatus(nil)
    ui.routeTitle:SetText(entry.name)
    local total = plan.cost < 20 and L["ROUTE_ALREADY"] or L["ROUTE_TOTAL"]:format(Journey:FormatTime(plan.cost))
    -- A plan with legs (a round trip's way there and back, a tour's stops: Journey:Legs) lists each leg under its
    -- heading, if it has one (the navigator follows them all: Navigation:Start). rowOf maps the navigator's step number
    -- to its row in that list.
    plan.shown, plan.rowOf = nil, nil
    local legs = Journey:Legs(plan)
    if legs then
        if plan.back then
            total = L["ROUTE_ROUND_TOTAL"]:format(Journey:FormatTime(plan.cost), Journey:FormatTime(plan.back.cost),
                Journey:FormatTime(plan.cost + plan.back.cost))
        else
            total = L["ROUTE_TOUR_TOTAL"]:format(#legs, Journey:FormatTime(plan.cost))
        end
        plan.shown, plan.rowOf = {}, {}
        local index = 0
        for _, leg in ipairs(legs) do
            if leg.heading then
                plan.shown[#plan.shown + 1] = { heading = true, text = leg.heading }     -- times are on the steps only
            end
            for _, step in ipairs(leg.steps) do
                index = index + 1
                plan.shown[#plan.shown + 1] = step
                plan.rowOf[index] = #plan.shown
            end
        end
    end
    -- Fares go on the total's line, except with legs, whose line is long enough already: they head the notes below, for all of them.
    local fare = (plan.fare or 0) + (plan.back and plan.back.fare or 0)
    local fareNote = fare > 0 and L["ROUTE_FARES"]:format(Journey:FormatMoney(fare)) or nil
    if fareNote and not legs then total = total .. " - " .. fareNote end
    ui.routeTotal:SetText(total)
    -- Each may be nil, so not ipairs over one table (it would stop at the first nil: a route with no fare note lost
    -- its flight hint that way).
    local hints = {}
    local function add(text) if text then hints[#hints + 1] = text end end
    if legs then add(fareNote) end
    if plan.dropped and #plan.dropped > 0 then add(L["ROUTE_TOUR_DROPPED"]:format(table.concat(plan.dropped, ", "))) end
    if entry.unread and entry.unread > 0 then add(L["ROUTE_TOUR_UNREAD"]:format(entry.unread)) end
    add(Journey:FareText(plan))
    add(Journey:HintText(plan.hint))
    add(Journey:AssumedText(plan))
    ui.routeHint:SetText(table.concat(hints, "\n"))
    layoutSteps()
    ui.start:SetShown(#plan.steps > 0 and not state.pinned and not plan.unaffordable)
    self:RenderSteps()
end

-- Draw the STEPS-tall window of the route's steps starting at state.stepOffset (mouse wheel
-- moves it; more than fit is never lost, just scrolled to, like the search results list).
function Panel:RenderSteps()
    local plan = state.plan
    local list = plan.shown or plan.steps
    for i = 1, STEPS do
        local row, step = ui.steps[i], i <= state.stepRows and list[state.stepOffset + i]
        if step then
            local time = step.heading and "" or Journey:FormatTime(step.seconds)
            row.name:SetText(step.text)
            row.eta:SetText(step.approx and L["TIME_ABOUT"]:format(time) or time)
            row.markerMethod, row.markerSource = step.method, step.source or step.iconSource
            row.markerGroup = step.heading and "place" or nil
            Theme:Restyle(row)
            -- An icon is wider than the chip: the text moves over for it.
            local left = row.iconShown and 28 or 14
            row.name:ClearAllPoints()
            row.name:SetPoint("LEFT", left, 0)
            row.name:SetWidth(INNER - left - 60)
            row:Show()
        else
            row:Hide()
        end
    end
    -- Say when steps are out of sight, above or below: a route can be longer than the list, and the
    -- first step scrolled away was easy to miss.
    local above, below = state.stepOffset, #list - state.stepOffset - state.stepRows
    local notes = {}
    if above > 0 then notes[#notes + 1] = L["ROUTE_MORE_ABOVE"]:format(above) end
    if below > 0 then notes[#notes + 1] = L["ROUTE_MORE_BELOW"]:format(below) end
    ui.more:SetText(table.concat(notes, "   "))
    -- A ley line or convergence is where spawns vary: point to the addon that shows where they've been found, in
    -- the room under the last step (a route that fills the list has none).
    local entry, shown = state.entry, math.min(state.stepRows, #list - state.stepOffset)
    ui.tip:Hide()
    if entry and (entry.group == "leyline" or entry.group == "convergence") and sllcmHintWanted() then
        local tipTop = state.stepsTop + shown * STEP_H + 12
        if tipTop + ROW_H <= STEPS_BOTTOM then
            ui.tip:ClearAllPoints()
            ui.tip:SetPoint("TOPLEFT", PAD, -tipTop)
            ui.tip:Show()
        end
    end
    self:MarkCurrentStep()
end

-- Highlight the step the trip is on (only while this route is the one being followed). When that step changes (the
-- trip moved on, or the route was just put on the panel) it is scrolled into view if it is out of sight; otherwise
-- the list stays where the player scrolled it.
function Panel:MarkCurrentStep()
    if not ui then return end
    local model = state.pinned and addon.Navigation:Model()
    local current = model and not model.finished and model.index
    -- With legs, the headings take rows of their own: the navigator's step is further down the list.
    if current and state.plan and state.plan.rowOf then current = state.plan.rowOf[current] or current end
    local moved = current ~= state.followedRow
    state.followedRow = current
    if moved and current and (current <= state.stepOffset or current > state.stepOffset + state.stepRows) then
        state.stepOffset = math.max(0, math.min(#(state.plan.shown or state.plan.steps) - state.stepRows, current - 1))
        self:RenderSteps()
        return
    end
    for i, row in ipairs(ui.steps) do
        row:SetSelected(current == state.stepOffset + i)
    end
end

-- The navigator's word on the trip, each update: move the highlight along, and when the trip
-- has ended (stopped, or arrived) go back to the search page.
function Panel:OnTripUpdate(model)
    if not ui then return end
    if not model or model.finished then
        if state.pinned then
            state.pinned = false
            self:Query(ui.search:GetText())
        end
        return
    end
    if state.pinned and state.view == "route" then self:MarkCurrentStep() end
end

-- The trip was planned again (a flight went somewhere the route didn't): show the new route.
function Panel:OnRerouted(entry, plan)
    if state.pinned then self:DisplayPlan(entry, plan) end
end

function Panel:Choose(index)
    local entry = state.results[index]
    if not entry then return end
    if entry.spacer then
        return
    elseif entry.header then
        self:ToggleSection(entry.id)
    elseif entry.action == "paste" then
        self:TogglePaste()
    elseif entry.action == "tomtom" then
        self:RouteTour(L["TOUR_TOMTOM"], addon:GetTomTomPoints() or {})
    else
        self:ShowRoute(entry)
    end
end

-- Opens or closes the paste box under "Multi-stop Route" (open: true, false, or nil to flip it). Opened, the
-- list scrolls so all of it shows and the cursor goes in it; what was pasted stays for the next time.
function Panel:TogglePaste(open)
    if open == nil then open = not state.pasteOpen end
    state.pasteOpen = open or nil
    self:ShowMenu()
    if open then
        for i, entry in ipairs(state.results) do
            if entry.action == "paste" then
                state.selected = i
                local last = i + PASTE_ROWS
                if i <= state.offset then state.offset = i - 1 end
                if last > state.offset + ROWS then state.offset = last - ROWS end
                break
            end
        end
        self:Render()
        ui.pasteStatus:SetText("")
        ui.pasteArea.edit:SetFocus()
    else
        ui.pasteArea.edit:ClearFocus()
    end
end

-- Route plans the tour through what was pasted (MultiRoute.ParseWay): the player's own map stands in for lines that
-- name none. With no coordinates in it, the box says so and stays open.
function Panel:RoutePasted(text)
    local here = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local points, bad = addon.MultiRoute.ParseWay(text, here, function(name) return addon:MapByName(name) end)
    if #points == 0 then
        ui.pasteStatus:SetText(L["PASTE_NONE"])
        return
    end
    state.pasteOpen = nil
    ui.pasteArea.edit:ClearFocus()
    self:RouteTour(L["TOUR_PASTED"], points, #bad)
end

-- A tour through points ({ mapID, x, y, name }: pasted /way lines, TomTom's waypoints), planned and shown like any
-- route. unread: how many pasted lines couldn't be read (a note under the route says so).
function Panel:RouteTour(name, points, unread)
    local entry = addon.MultiRoute:Entry(name, points)
    entry.unread = unread
    self:ShowRoute(entry)
end

-- Begin following the route on screen: the navigator takes over.
function Panel:StartRoute()
    if not (state.plan and state.entry and #state.plan.steps > 0) then return end
    addon.Navigation:Start(state.planned or state.entry, state.plan)
    state.pinned = true
    ui.start:SetShown(false)
    showTripChoice()
    self:MarkCurrentStep()
    addon.Navigator:Show()
end

function Panel:Escape()
    if state.view == "route" then
        self:Query(ui.search:GetText())
    elseif ui.search:GetText() ~= "" then
        ui.search:SetText("")
    else
        ui.search:ClearFocus()
    end
end

-- The size setting (Options): our windows scale with it.
function Panel:ApplyScale()
    if ui then ui.frame:SetScale(addon.Options:Get("scale")) end
end

-- ---------------------------------------------------------------------------------------
-- Attaching to the map

-- Beside the map when there is room on screen, otherwise inside its right edge. A no-op while
-- free-floating (state.docked == false): RestorePosition/dragging own the frame's point then.
-- How far past the map frame's right edge its own chrome reaches: on retail the Quests / Events /
-- Map Legend tabs hang off the side of the quest panel, outside WorldMapFrame's rectangle, so a
-- panel anchored to the frame's edge sits under them. 0 when none are there (Forever, or the
-- quest panel closed).
local function mapChromeOverhang(map)
    local mapRight = map:GetRight()
    local overhang = 0
    local questMap = QuestMapFrame
    if mapRight and questMap then
        for _, name in ipairs({ "QuestsTab", "EventsTab", "MapLegendTab" }) do
            local tab = questMap[name]
            local right = tab and tab.IsShown and tab:IsShown() and tab:GetRight()
            if right and right - mapRight > overhang then overhang = right - mapRight end
        end
    end
    return overhang
end

function Panel:Reanchor()
    if not state.docked or state.detached then return end
    local frame, map = ui.frame, WorldMapFrame
    frame:ClearAllPoints()
    local overhang = mapChromeOverhang(map)
    local room = (UIParent:GetRight() or 0) - (map:GetRight() or 0) - overhang
    if room >= WIDTH + 4 then
        frame:SetPoint("TOPLEFT", map, "TOPRIGHT", 2 + overhang, 0)
    else
        frame:SetPoint("TOPRIGHT", map, "TOPRIGHT", -8, -68)
    end
end

-- Where a free-floating panel was left, read back by RestorePosition. Account-wide, same as
-- every other Options-backed setting.
function Panel:SavePosition()
    local left, top = ui.frame:GetLeft(), ui.frame:GetTop()
    if not (left and top) then return end
    MapzerothRebuildDB = MapzerothRebuildDB or {}
    MapzerothRebuildDB.panelPos = { x = left, y = top }
end

-- TOPLEFT anchored to UIParent's BOTTOMLEFT so saved x/y (from GetLeft/GetTop, screen-space
-- already) land back exactly where they were, whatever the panel happened to be docked beside
-- when it was popped out.
function Panel:RestorePosition(current)
    local frame = ui.frame
    frame:ClearAllPoints()
    local saved = MapzerothRebuildDB and MapzerothRebuildDB.panelPos
    if saved then
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", saved.x, saved.y)
        return
    end
    if not current then
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)        -- never placed, and nowhere it was: the middle
        return
    end
    -- First time popping out, nothing saved yet: stay exactly where it currently is (`current`,
    -- in screen units), not a jump to some default spot.
    local scale = frame:GetEffectiveScale() or 1
    frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", current.x / scale, current.y / scale)
end

-- Hang the panel on the map: its child, in the map's strata, above the map's own frames.
local function attachToMap()
    local frame, map = ui.frame, WorldMapFrame
    frame:SetParent(map)
    frame:SetFrameStrata(map:GetFrameStrata() or "HIGH")
    frame:SetFrameLevel((map:GetFrameLevel() or 1) + 20)
end

-- Stand it on the screen instead, off the map: popped out, or docked with the map closed.
local function attachToScreen()
    ui.frame:SetParent(UIParent)
    ui.frame:SetFrameStrata("HIGH")
    ui.frame:SetFrameLevel(20)
end

-- Toggle between docked (beside the map, Reanchor decides where) and free-floating (the player
-- drags it; RestorePosition puts it back where they left it). The button in the corner calls
-- this; so does build() (`initial`), to apply whatever was last saved. Docked, the panel is the map's child and
-- comes and goes with it; free-floating it belongs to the screen and is opened and closed on its own
-- (Toggle: /mz and the minimap button).
function Panel:SetDocked(docked, initial)
    docked = docked and true or false
    state.docked = docked
    addon.Options:Set("docked", docked)
    if not ui then return end
    ui.pop.label:SetText(docked and L["PANEL_POPOUT"] or L["PANEL_DOCK"])
    local frame, map = ui.frame, WorldMapFrame
    state.detached = false
    if docked and map then
        attachToMap()
        frame:SetShown(not state.dockedHidden)       -- it shows when the map does
        self:Reanchor()
        if not initial and map:IsShown() and not state.dockedHidden then self:ShowContent() end
    elseif not docked then
        -- Where it is on screen now, worked out before it changes parent (and so scale).
        local left, top, from = frame:GetLeft(), frame:GetTop(), frame:GetEffectiveScale()
        attachToScreen()
        if not initial then state.floatShown = true end               -- popped out just now: it stays up
        self:RestorePosition(left and top and from and { x = left * from, y = top * from })
        frame:SetShown(state.floatShown)
    end
end

-- Re-read the player and the world when the map opens: who they are, and the places to offer.
function Panel:Refresh()
    state.ctx = addon:GetPlayerContext()
    state.entries = addon.Destinations:Build(state.ctx)
    -- A new window: the sections start closed, and are priced from where the player is when one of places is opened.
    state.waypoint = addon:GetWaypoint()
    local tomtom = addon:GetTomTomPoints()
    state.sections = addon.Sections:Build(state.entries, state.ctx, state.waypoint, tomtom and #tomtom)
    state.open, state.priced, state.session = {}, false, nil
    state.pasteOpen = nil
end

-- The player set or cleared their map waypoint: the first top pick changes with it.
function Panel:OnWaypointChanged()
    if not (ui and ui.frame:IsShown()) or state.view ~= "list" or ui.search:GetText() ~= "" then return end
    self:Refresh()
    self:Query("")
end

-- What the window shows when it opens: fresh places, and the trip in progress if there is one, else the search page.
function Panel:ShowContent()
    self:Refresh()
    if state.pinned and state.plan and addon.Navigation:IsActive() then
        self:DisplayPlan(state.entry, state.plan)       -- the trip in progress, not the search page
    else
        self:Query(ui.search:GetText())
    end
end

-- Docked, the panel opens with the map. Popped out it doesn't (the map opening is none of its business).
function Panel:OnMapShown()
    if not WorldMapFrame or not isDocked() then return end
    if not ui then build(WorldMapFrame) end
    if not state.docked then return end
    if state.detached then
        state.detached = false                        -- the map is open now: the panel goes back beside it, and stays up
        state.dockedHidden = false
        attachToMap()
    end
    self:Reanchor()
    ui.frame:SetShown(not state.dockedHidden)
    if not state.dockedHidden then self:ShowContent() end
end

-- The window's on/off: /mz and the minimap button. Our code never opens or closes the map: from addon code that
-- taints it, and the game then blocks its own later calls (the map key in combat). So, docked with the map open,
-- it shows or hides the panel beside the map; docked with the map closed, the panel stands on its own (at
-- its popped-out position) until the map opens and it goes back beside it; popped out, it is the panel alone.
-- Returns whether the panel is up now.
function Panel:Toggle()
    if isDocked() then
        local map = WorldMapFrame
        if map and map:IsShown() then
            if not ui then self:OnMapShown() end
            state.dockedHidden = not state.dockedHidden
            ui.frame:SetShown(not state.dockedHidden)
            if not state.dockedHidden then self:ShowContent() end
            return not state.dockedHidden
        end
        if not ui then build(map or UIParent) end
        if state.detached then
            state.detached = false
            ui.frame:Hide()
            if map then attachToMap() end
            return false
        end
        state.detached, state.dockedHidden = true, false       -- asked for, so it is not "hidden" any more
        attachToScreen()
        self:RestorePosition()
        ui.frame:Show()
        self:ShowContent()
        return true
    end
    if not ui then build(UIParent) end
    state.floatShown = not (ui.frame:IsShown() and state.floatShown)
    ui.frame:SetShown(state.floatShown)
    if state.floatShown then self:ShowContent() end
    return state.floatShown
end

-- Hooks the panel to the map opening. Returns false if the map isn't loaded yet.
function Panel:Init()
    if self.inited then return true end
    if not WorldMapFrame then return false end
    self.inited = true
    addon.Options:OnChange(function(key)
        if key == "scale" then Panel:ApplyScale() end
        -- Icons or chips beside the steps (and a theme's icons) change how the steps are laid out.
        if (key == "stepMarkers" or key == "theme") and ui and state.view == "route" and state.plan then
            Panel:RenderSteps()
        end
        -- A pick turned on or off on the settings page: the open picker lists it, or doesn't, straight away.
        if key:find("^showPick_") and ui and ui.frame:IsShown() and state.view == "list" and ui.search:GetText() == "" then
            Panel:Refresh()
            Panel:Query("")
        end
    end)
    WorldMapFrame:HookScript("OnShow", function() Panel:OnMapShown() end)
    addon.RouteLines:Init()
    WorldMapFrame:HookScript("OnSizeChanged", function()
        if ui and ui.frame:IsShown() then Panel:Reanchor() end
    end)
    if WorldMapFrame:IsShown() then self:OnMapShown() end
    return true
end

function Panel:GetState() return state end
Panel.Subtitle = subtitle                 -- for tests
function Panel:StatusText() return ui and ui.status:IsShown() and ui.status:GetText() or nil end
function Panel:GetFrame() return ui and ui.frame end
