local addonName, addon = ...

-- The question when the player sets a new waypoint on the map (placed on the world map, or from a map pin link in
-- chat): route there? Yes plans the route and starts the trip (Panel:RouteToWaypoint). Asked once per waypoint, never
-- about the one already set at login, nor one the trip being followed is going to. The setting askWaypointRoute (on
-- the settings page, and "Don't Ask Again" here) turns it off.
--
-- The same question comes for a quest newly followed in the quest tracker (super-tracked) when autoQuestRoute is
-- "ask"; at "on" the route starts without asking. Don't Ask Again sets it to "off".
--
-- All styling goes through addon.Theme. The frame is built on first use, never at load.

local WaypointPrompt = {}
addon.WaypointPrompt = WaypointPrompt

local L = addon.L
local Theme = addon.Theme

local WIDTH, PAD, BUTTON_W = 420, 16, 124
local SETTLE = 3                -- seconds after login or /reload before a waypoint counts as new

local ui
local seen                      -- the id of the waypoint last looked at (asked about, or already there), or nil
local seenQuest                 -- likewise the quest followed
local ready = false             -- past login: before that, a waypoint is the one the player already had

local function build()
    ui = {}
    WaypointPrompt.widgets = ui             -- for tests
    local name = "MapzerothRebuildWaypointPrompt"
    local frame = Theme:Panel(UIParent, name)
    frame:SetWidth(WIDTH)
    frame:SetClampedToScreen(true)          -- a map near the bottom of the screen: it stays in view
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:EnableMouse(true)
    frame:Hide()
    ui.frame = frame
    if type(UISpecialFrames) == "table" then table.insert(UISpecialFrames, name) end   -- Escape closes it

    ui.title = Theme:Text(frame, "title")
    ui.title:SetPoint("TOPLEFT", PAD, -PAD)
    ui.title:SetWidth(WIDTH - 2 * PAD)
    ui.title:SetWordWrap(true)

    ui.text = Theme:Text(frame, "body")
    ui.text:SetPoint("TOPLEFT", ui.title, "BOTTOMLEFT", 0, -12)
    ui.text:SetWidth(WIDTH - 2 * PAD)
    ui.text:SetWordWrap(true)

    ui.never = Theme:Button(frame, L["WAYPOINT_ASK_NEVER"], BUTTON_W, 24)
    ui.never:SetPoint("BOTTOMLEFT", PAD, PAD)
    ui.never:SetScript("OnClick", function() WaypointPrompt:Answer("never") end)

    ui.route = Theme:Button(frame, L["WAYPOINT_ASK_ROUTE"], BUTTON_W, 24, true)
    ui.route:SetPoint("BOTTOMRIGHT", -PAD, PAD)
    ui.route:SetScript("OnClick", function() WaypointPrompt:Answer("route") end)

    ui.later = Theme:Button(frame, L["WAYPOINT_ASK_LATER"], BUTTON_W, 24)
    ui.later:SetPoint("RIGHT", ui.route, "LEFT", -8, 0)
    ui.later:SetScript("OnClick", function() WaypointPrompt:Answer("later") end)
end

-- Height from the wrapped text: the frame grows to fit the language it is in.
local function fit()
    local h = PAD + (ui.title:GetStringHeight() or 0) + 12 + (ui.text:GetStringHeight() or 0) + 16 + 24 + PAD
    ui.frame:SetHeight(math.ceil(h))
end

-- Under the map when it is open (the waypoint was most likely just placed on it), so it covers none of it, or over it
-- when there is no room below (a map near the bottom of the screen); else near the top of the screen. Needs the
-- frame's height (fit) first.
local GAP = 8
local function place()
    local frame, map = ui.frame, WorldMapFrame
    frame:ClearAllPoints()
    if map and map:IsShown() then
        -- Room below the map, in screen pixels (the map and the prompt can be at different scales).
        local bottom, mapScale, scale = map:GetBottom(), map:GetEffectiveScale(), frame:GetEffectiveScale()
        local below = bottom and mapScale and bottom * mapScale
        local needed = ((frame:GetHeight() or 0) + GAP) * (scale or 1)
        if below and below < needed then
            frame:SetPoint("BOTTOM", map, "TOP", 0, GAP)
        else
            frame:SetPoint("TOP", map, "BOTTOM", 0, -GAP)
        end
    else
        frame:SetPoint("TOP", UIParent, "TOP", 0, -120)
    end
end

local function open(title, text)
    ui.title:SetText(title)
    ui.text:SetText(text)
    ui.frame:Show()
    fit()
    place()
end

function WaypointPrompt:Show(waypoint)
    if not ui then build() end
    ui.questID = nil
    open(L["WAYPOINT_ASK_TITLE"], L["WAYPOINT_ASK_TEXT"]:format(addon:GetZoneName(waypoint.mapID) or "?"))
end

-- The question about a quest (addon:GetQuestTarget's place, with its title).
function WaypointPrompt:ShowQuest(quest)
    if not ui then build() end
    ui.questID = quest.questID
    open(L["QUEST_ASK_TITLE"], L["QUEST_ASK_TEXT"]:format(quest.title or L["PICK_QUEST"]))
end

function WaypointPrompt:IsShown()
    return ui ~= nil and ui.frame:IsShown()
end

-- Whether the question up is about a quest.
function WaypointPrompt:IsQuestShown()
    return self:IsShown() and ui.questID ~= nil
end

function WaypointPrompt:Hide()
    if ui then ui.frame:Hide() end
end

-- "route": plan it and go; "later": not this one; "never": the setting goes off (the settings page turns it on).
function WaypointPrompt:Answer(answer)
    local questID = ui and ui.questID
    self:Hide()
    if answer == "never" then
        if questID then addon.Options:Set("autoQuestRoute", "off") else addon.Options:Set("askWaypointRoute", false) end
    elseif answer == "route" then
        if questID then addon.QuestArrow.Route(questID) else addon.Panel:RouteToWaypoint() end
    end
end

-- Whether the trip being followed goes to the waypoint with this id.
local function headingThere(id)
    local entry = addon.Navigation:ReplanTarget()
    return entry ~= nil and entry.dest ~= nil and entry.dest.id == id
end

-- Whether it goes to this quest.
local function headingToQuest(questID)
    local entry = addon.Navigation:ReplanTarget()
    return entry ~= nil and entry.dest ~= nil and entry.dest.questID == questID
end

-- The map waypoint changed (Core.lua, USER_WAYPOINT_UPDATED and SUPER_TRACKING_CHANGED). A new one is asked about; one
-- cleared, or replaced, takes the question about it away.
function WaypointPrompt:OnWaypointChanged()
    local waypoint = addon:GetWaypoint()
    local id = waypoint and waypoint.id
    if id == seen then return end
    seen = id
    if not self:IsQuestShown() then self:Hide() end
    if not (waypoint and ready and addon.Options:Get("askWaypointRoute")) or headingThere(id) then return end
    self:Show(waypoint)
end

local function trackedQuest()
    local track = C_SuperTrack
    local id = track and track.GetSuperTrackedQuestID and track.GetSuperTrackedQuestID()
    return id ~= 0 and id or nil
end

-- The quest followed changed (Core.lua, SUPER_TRACKING_CHANGED). A new one is routed to, or asked about, by the
-- autoQuestRoute setting; one dropped takes the question about it away. A quest with no spot we can place is let be.
function WaypointPrompt:OnQuestChanged()
    local questID = trackedQuest()
    if questID == seenQuest then return end
    seenQuest = questID
    if self:IsQuestShown() then self:Hide() end
    local mode = addon.Options:Get("autoQuestRoute")
    if not (questID and ready) or mode == "off" or headingToQuest(questID) then return end
    local quest = addon:GetQuestTarget(questID)
    if not quest then return end
    if mode == "on" then
        addon.Panel:RouteToQuest(questID)
    else
        self:ShowQuest(quest)
    end
end

-- Login and /reload: the waypoint set then is the one the player already had, so it isn't asked about.
function WaypointPrompt:Settle()
    local waypoint = addon:GetWaypoint()
    seen = waypoint and waypoint.id
    seenQuest = trackedQuest()
    ready = true
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:SetScript("OnEvent", function(_, _, isLogin, isReload)
    if not (isLogin or isReload) then return end           -- zoning leaves the waypoint as it was
    ready = false
    C_Timer.After(SETTLE, function() WaypointPrompt:Settle() end)
end)
