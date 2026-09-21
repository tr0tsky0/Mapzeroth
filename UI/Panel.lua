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
local STEP_H, STEPS = 30, 7

local ui                                  -- the widgets, once built
local state = {
    hidden = false, entries = {}, results = {}, offset = 0, selected = 0,
    view = "list", entry = nil, plan = nil, ctx = nil,
    pinned = false,       -- a trip is being followed: reopening the map shows its route, not the search page
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

    ui.themeButton = Theme:Button(frame, "", 104, 22)
    ui.themeButton:SetPoint("TOPRIGHT", -PAD, -PAD + 3)
    ui.themeButton:SetScript("OnClick", function()
        Theme:Cycle()
        Panel:UpdateThemeLabel()
    end)

    ui.search = Theme:EditBox(frame, INNER, 30)
    ui.search:SetPoint("TOPLEFT", PAD, -46)
    ui.hint = Theme:Text(ui.search, "dim")
    ui.hint:SetPoint("LEFT", 10, 0)
    ui.hint:SetText(L["SEARCH_HINT"])
    ui.search:SetScript("OnTextChanged", function(self)
        ui.hint:SetShown(self:GetText() == "")
        Panel:Query(self:GetText())
    end)
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
        local row = makeRow(frame, LIST_TOP, i, ROW_H, false)
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

    Panel:UpdateThemeLabel()
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

local function subtitle(entry)
    local group = L["GROUP_" .. entry.group]
    if entry.zone then return group .. " - " .. entry.zone end
    return group
end

-- Fills the list rows from state.results, starting at state.offset.
function Panel:Render()
    for i = 1, ROWS do
        local row, entry = ui.rows[i], state.results[state.offset + i]
        if entry then
            row.index = state.offset + i
            row.name:SetText(entry.name)
            row.sub:SetText(subtitle(entry))
            row.markerGroup = entry.group
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

-- What to offer before anything is typed: the nearest ley line, for those who can use one (a
-- single entry over every ley line; the nearest is worked out when it is chosen). There is no
-- "Home": the hearthstone is one step of a route, and anyone can click it themselves.
local function quickPicks()
    local picks = {}
    local lines = {}
    for _, entry in ipairs(state.entries) do
        if entry.group == "leyline" and entry.relevant then lines[#lines + 1] = entry.nodeID end
    end
    if #lines > 0 then
        picks[#picks + 1] = {
            nodeID = lines[1], nodeIDs = lines, group = "leyline", relevant = true, name = L["QUICK_LEYLINE"],
        }
    end
    return picks
end

-- What was typed changed (or "go back to the list"): show matching places.
function Panel:Query(text)
    if not ui then return end
    state.view = "list"
    state.pinned = false
    showRouteWidgets(false)
    text = text or ""
    if text == "" then
        state.results = quickPicks()
    else
        state.results = addon.Search:Query(state.entries, text, 60)
    end
    state.offset, state.selected = 0, (#state.results > 0) and 1 or 0
    self:Render()
    if #state.results > 0 then
        setStatus(nil)
    else
        setStatus(text == "" and L["SEARCH_EMPTY"] or L["NO_RESULTS"])
    end
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
    local session = start and Journey:Build(ctx, start)
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
    state.view, state.entry, state.plan = "route", entry, plan
    showList(false)
    showRouteWidgets(true)
    setStatus(nil)
    ui.routeTitle:SetText(entry.name)
    ui.routeTotal:SetText(plan.cost < 20 and L["ROUTE_ALREADY"] or L["ROUTE_TOTAL"]:format(Journey:FormatTime(plan.cost)))
    ui.routeHint:SetText(Journey:HintText(plan.hint) or "")
    ui.start:SetShown(#plan.steps > 0 and not state.pinned)
    for i = 1, STEPS do
        local row, step = ui.steps[i], plan.steps[i]
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
    local extra = #plan.steps - STEPS
    ui.more:SetText(extra > 0 and ("+" .. extra) or "")
    self:MarkCurrentStep()
end

-- Highlight the step the trip is on (only while this route is the one being followed).
function Panel:MarkCurrentStep()
    if not ui then return end
    local model = state.pinned and addon.Navigation:Model()
    for i, row in ipairs(ui.steps) do
        row:SetSelected(model and not model.finished and model.index == i or false)
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

function Panel:Choose(index)
    local entry = state.results[index]
    if entry then self:ShowRoute(entry) end
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

function Panel:UpdateThemeLabel()
    if ui and Theme:Current() then
        ui.themeButton.label:SetText(Theme:Label(Theme:Current().id))
    end
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
end

function Panel:OnMapShown()
    if not WorldMapFrame then return end
    if not ui then build(WorldMapFrame) end
    self:Reanchor()
    ui.frame:SetShown(not state.hidden)
    if state.hidden then return end
    self:Refresh()
    self:UpdateThemeLabel()
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
    WorldMapFrame:HookScript("OnShow", function() Panel:OnMapShown() end)
    WorldMapFrame:HookScript("OnSizeChanged", function()
        if ui and ui.frame:IsShown() then Panel:Reanchor() end
    end)
    if WorldMapFrame:IsShown() then self:OnMapShown() end
    return true
end

function Panel:GetState() return state end
function Panel:GetFrame() return ui and ui.frame end
