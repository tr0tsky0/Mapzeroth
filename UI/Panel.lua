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

local WIDTH, HEIGHT, PAD = 330, 440, 16
local INNER = WIDTH - 2 * PAD
local LIST_TOP = 86
local ROW_H, ROWS = 38, 8
local INDENT = 14                         -- how far an item of an accordion section sits in from its heading
local STEP_H, STEPS = 30, 7

local ui                                  -- the widgets, once built
local state = {
    hidden = false, entries = {}, results = {}, offset = 0, selected = 0,
    view = "list", entry = nil, plan = nil, ctx = nil,
    sections = {}, open = {}, priced = false, session = nil, waypoint = nil,     -- the accordion, and whether it has been priced
    pinned = false,       -- a trip is being followed: reopening the map shows its route, not the search page
    stepOffset = 0,       -- how many of the route's steps are scrolled past, when it has more than fit
}

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
    frame:SetScript("OnMouseWheel", function(_, delta) Panel:Scroll(-delta) end)
    ui.frame = frame

    ui.title = Theme:Text(frame, "title")
    ui.title:SetPoint("TOPLEFT", PAD, -PAD)
    ui.title:SetText(L["PANEL_TITLE"])

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
        ui.rows[i] = row
    end

    -- The route view.
    ui.back = Theme:Button(frame, L["ROUTE_BACK"], 70, 22)
    ui.back:SetPoint("TOPLEFT", PAD, -LIST_TOP)
    ui.back:SetScript("OnClick", function() Panel:Query(ui.search:GetText()) end)

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
    local stepsTop = LIST_TOP + 118
    for i = 1, STEPS do
        local row = makeRow(frame, stepsTop, i, STEP_H, true)
        row:EnableMouse(false)
        row.name:ClearAllPoints()
        row.name:SetPoint("LEFT", 14, 0)
        row.name:SetWidth(INNER - 14 - 60)
        row.name:SetWordWrap(true)
        row.name:SetMaxLines(2)
        ui.steps[i] = row
    end
    ui.more = Theme:Text(frame, "dim")
    ui.more:SetPoint("TOPLEFT", PAD + 14, -(stepsTop + STEPS * STEP_H + 2))

    ui.start = Theme:Button(frame, L["ROUTE_START"], 90, 22, true)
    ui.start:SetPoint("BOTTOMRIGHT", -PAD, PAD)
    ui.start:SetScript("OnClick", function() Panel:StartRoute() end)

    Panel:ApplyScale()
end

-- ---------------------------------------------------------------------------------------
-- Showing things

local function showList(show)
    for _, row in ipairs(ui.rows) do
        if not show then row:Hide() end
    end
end

local function showRouteWidgets(show)
    for _, widget in ipairs({ ui.back, ui.routeTitle, ui.routeTotal, ui.routeHint, ui.start, ui.more }) do
        widget:SetShown(show)
    end
    if not show then
        for _, row in ipairs(ui.steps) do row:Hide() end
    end
end

-- The second line of a result: "Trainer - Stormwind - One-Handed Swords, Staves" (the weapons a search matched,
-- else all it teaches), or "City - Stormwind City". Under a heading of the accordion the kind is already said,
-- so a city or town shows just its zone, and a pick the nearest place of its kind.
local function subtitle(entry)
    if entry.pick then
        return entry.where or (entry.eta == nil and state.priced and L["PICK_NO_ROUTE"]) or ""
    end
    if entry.inSection then return entry.zone or "" end
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
    if (entry.pick or entry.inSection) and entry.eta then return Journey:FormatTime(entry.eta) end
    return ""
end

-- Fills the list rows from state.results, starting at state.offset. A row is a search result, a section
-- heading of the accordion, or one of a section's items (shown with its travel time once priced).
function Panel:Render()
    for i = 1, ROWS do
        local row, entry = ui.rows[i], state.results[state.offset + i]
        if entry then
            row.index = state.offset + i
            -- An item of a section sits in from its heading: the marker, the name and the line under it together.
            local indent = (entry.pick or entry.inSection) and INDENT or 0
            row.marker:ClearAllPoints()
            row.marker:SetPoint("LEFT", 4 + indent, 0)
            row.name:ClearAllPoints()
            row.name:SetPoint("TOPLEFT", 14 + indent, -5)
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
            row.markerMethod = nil
            Theme:Restyle(row)
            row:SetSelected(row.index == state.selected)
            row:Show()
        else
            row:Hide()
        end
    end
end

local function setStatus(text)
    ui.status:SetText(text or "")
    ui.status:SetShown(text ~= nil and text ~= "")
end

-- What to offer before anything is typed: the accordion (Sections.lua). There is no "Home": the
-- hearthstone is one step of a route, and anyone can click it themselves. Nothing is priced until
-- a section is opened.
function Panel:ShowMenu(selectID)
    local rows = {}
    for _, section in ipairs(state.sections or {}) do
        local open = state.open[section.id] == true
        rows[#rows + 1] = { header = true, id = section.id, name = section.title, open = open, count = #section.items }
        if open then
            for _, item in ipairs(section.items) do
                item.inSection = true
                rows[#rows + 1] = item
            end
        end
    end
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

-- The times need where the player is and a search over the whole map, so it happens when a section is
-- first opened, not when the window is.
function Panel:PriceSections()
    if state.priced then return end
    local start = addon:GetPlayerStart()
    local session = start and Journey:Build(state.ctx, start, state.waypoint and { state.waypoint } or nil)
    if session then
        addon.Sections:Price(state.sections, session)
        state.session = session
    end
    state.priced = true
end

function Panel:ToggleSection(id)
    state.open[id] = not state.open[id]
    if state.open[id] then self:PriceSections() end
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
    state.selected = n
    if n <= state.offset then state.offset = n - 1 end
    if n > state.offset + ROWS then state.offset = n - ROWS end
    self:Render()
end

function Panel:Scroll(delta)
    if state.view == "route" and state.plan then
        local max = math.max(0, #state.plan.steps - STEPS)
        state.stepOffset = math.max(0, math.min(max, state.stepOffset + delta))
        self:RenderSteps()
        return
    end
    if state.view ~= "list" then return end
    local max = math.max(0, #state.results - ROWS)
    state.offset = math.max(0, math.min(max, state.offset + delta))
    self:Render()
end

-- The route to a destination, worked out now, from where the player is now.
function Panel:ShowRoute(entry)
    state.view, state.entry, state.plan = "route", entry, nil
    showList(false)
    showRouteWidgets(true)
    setStatus(nil)
    ui.routeTitle:SetText(entry.name)
    ui.routeTotal:SetText("")
    ui.routeHint:SetText("")
    ui.more:SetText("")
    for _, row in ipairs(ui.steps) do row:Hide() end
    ui.start:SetShown(false)

    local ctx = addon:GetPlayerContext()
    state.ctx = ctx
    local start = addon:GetPlayerStart()
    local session = start and Journey:Build(ctx, start, entry.dest and { entry.dest } or nil)
    if not session then
        ui.status:ClearAllPoints()
        ui.status:SetPoint("TOPLEFT", PAD, -(LIST_TOP + 74))
        setStatus(L["NOWHERE"])
        return
    end
    local plan = Journey:PlanEntry(session, entry)
    state.plan = plan
    ui.status:ClearAllPoints()
    ui.status:SetPoint("TOPLEFT", PAD, -(LIST_TOP + 74))
    if not plan then
        setStatus(L["ROUTE_NONE"])
        return
    end

    self:DisplayPlan(entry, plan)
end

-- Draw a plan's route: the total, the hint, and its steps (the one being followed is marked).
function Panel:DisplayPlan(entry, plan)
    state.view, state.entry, state.plan, state.stepOffset = "route", entry, plan, 0
    showList(false)
    showRouteWidgets(true)
    setStatus(nil)
    ui.routeTitle:SetText(entry.name)
    local total = plan.cost < 20 and L["ROUTE_ALREADY"] or L["ROUTE_TOTAL"]:format(Journey:FormatTime(plan.cost))
    if plan.fare and plan.fare > 0 then total = total .. " - " .. L["ROUTE_FARES"]:format(Journey:FormatMoney(plan.fare)) end
    ui.routeTotal:SetText(total)
    local hints = {}
    for _, text in ipairs({ Journey:FareText(plan), Journey:HintText(plan.hint) }) do
        if text then hints[#hints + 1] = text end
    end
    ui.routeHint:SetText(table.concat(hints, "\n"))
    ui.start:SetShown(#plan.steps > 0 and not state.pinned and not plan.unaffordable)
    self:RenderSteps()
end

-- Draw the STEPS-tall window of the route's steps starting at state.stepOffset (mouse wheel
-- moves it; more than fit is never lost, just scrolled to, like the search results list).
function Panel:RenderSteps()
    local plan = state.plan
    for i = 1, STEPS do
        local row, step = ui.steps[i], plan.steps[state.stepOffset + i]
        if step then
            local time = Journey:FormatTime(step.seconds)
            row.name:SetText(step.text)
            row.eta:SetText(step.approx and L["TIME_ABOUT"]:format(time) or time)
            row.markerMethod = step.method
            row.markerGroup = nil
            Theme:Restyle(row)
            row:Show()
        else
            row:Hide()
        end
    end
    local extra = #plan.steps - state.stepOffset - STEPS
    ui.more:SetText(extra > 0 and ("+" .. extra) or "")
    self:MarkCurrentStep()
end

-- Highlight the step the trip is on (only while this route is the one being followed), scrolling
-- it into view if the player has moved on to a step currently scrolled out of sight.
function Panel:MarkCurrentStep()
    if not ui then return end
    local model = state.pinned and addon.Navigation:Model()
    local current = model and not model.finished and model.index
    if current and (current <= state.stepOffset or current > state.stepOffset + STEPS) then
        state.stepOffset = math.max(0, math.min(#state.plan.steps - STEPS, current - 1))
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
    if entry.header then
        self:ToggleSection(entry.id)
    else
        self:ShowRoute(entry)
    end
end

-- Begin following the route on screen: the navigator takes over.
function Panel:StartRoute()
    if not (state.plan and state.entry and #state.plan.steps > 0) then return end
    addon.Navigation:Start(state.entry, state.plan)
    state.pinned = true
    ui.start:SetShown(false)
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

-- Beside the map when there is room on screen, otherwise inside its right edge.
function Panel:Reanchor()
    local frame, map = ui.frame, WorldMapFrame
    frame:ClearAllPoints()
    local room = (UIParent:GetRight() or 0) - (map:GetRight() or 0)
    if room >= WIDTH + 4 then
        frame:SetPoint("TOPLEFT", map, "TOPRIGHT", 2, 0)
    else
        frame:SetPoint("TOPRIGHT", map, "TOPRIGHT", -8, -68)
    end
end

-- Re-read the player and the world when the map opens: who they are, and the places to offer.
function Panel:Refresh()
    state.ctx = addon:GetPlayerContext()
    state.entries = addon.Destinations:Build(state.ctx)
    -- A new window: the sections start closed, and are priced from where the player is when one is opened.
    state.waypoint = addon:GetWaypoint()
    state.sections = addon.Sections:Build(state.entries, state.ctx, state.waypoint)
    state.open, state.priced, state.session = {}, false, nil
end

-- The player set or cleared their map waypoint: the accordion's first pick changes with it.
function Panel:OnWaypointChanged()
    if not (ui and ui.frame:IsShown()) or state.view ~= "list" or ui.search:GetText() ~= "" then return end
    self:Refresh()
    self:Query("")
end

function Panel:OnMapShown()
    if not WorldMapFrame then return end
    if not ui then build(WorldMapFrame) end
    self:Reanchor()
    ui.frame:SetShown(not state.hidden)
    if state.hidden then return end
    self:Refresh()
    if state.pinned and state.plan and addon.Navigation:IsActive() then
        self:DisplayPlan(state.entry, state.plan)       -- the trip in progress, not the search page
    else
        self:Query(ui.search:GetText())
    end
end

function Panel:Toggle()
    state.hidden = not state.hidden
    if ui then ui.frame:SetShown(not state.hidden) end
    if not state.hidden and WorldMapFrame and WorldMapFrame:IsShown() then self:OnMapShown() end
    return not state.hidden
end

-- Hooks the panel to the map opening. Returns false if the map isn't loaded yet.
function Panel:Init()
    if self.inited then return true end
    if not WorldMapFrame then return false end
    self.inited = true
    addon.Options:OnChange(function(key) if key == "scale" then Panel:ApplyScale() end end)
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
