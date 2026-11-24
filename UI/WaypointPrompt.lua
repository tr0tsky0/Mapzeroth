local addonName, addon = ...

-- The question when the player sets a new waypoint on the map (placed on the world map, or from a map pin link in
-- chat): route there? Yes plans the route and starts the trip (Panel:RouteToWaypoint). Asked once per waypoint, never
-- about the one already set at login, nor one the trip being followed is going to. The setting askWaypointRoute (on
-- the settings page, and "Don't Ask Again" here) turns it off.
--
-- The same question comes for a quest newly followed in the quest tracker (super-tracked) when autoQuestRoute is
-- "ask"; at "on" the route starts without asking. Don't Ask Again sets it to "off".
--
-- With TomTom loaded, releasing your spirit (Corpse.lua, corpseWith "ask") asks who takes you back: Mapzeroth, TomTom or
-- both, on the same three buttons. The answer is kept in corpseWith; the settings page changes it.
--
-- All styling goes through addon.Theme. The frame is built on first use, never at load.

local WaypointPrompt = {}
addon.WaypointPrompt = WaypointPrompt

local L = addon.L
local Theme = addon.Theme

local WIDTH, PAD, BUTTON_W = 420, 16, 124
local SETTLE = 3                -- seconds after login or /reload before a waypoint counts as new
local SAME_SPOT = 25            -- yards: a waypoint this close to where we're going (or were just asked) is that place
local RECENT = 10               -- seconds a quest asked about or routed to still counts, while its route is planned

local ui
local seen                      -- the id of the waypoint last looked at (asked about, or already there), or nil
local seenQuest                 -- likewise the quest followed
local ready = false             -- past login: before that, a waypoint is the one the player already had
local lastSpot, lastAt          -- the place last asked about or routed to from here, and when (GetTime)
local following                 -- { questID, spot }: the quest a trip was started to, carried on to its next spot

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

-- The buttons' words: the waypoint and quest question, or the corpse one.
local function label(corpse)
    ui.never.label:SetText(L[corpse and "CORPSE_TOMTOM" or "WAYPOINT_ASK_NEVER"])
    ui.later.label:SetText(L[corpse and "CORPSE_BOTH" or "WAYPOINT_ASK_LATER"])
    ui.route.label:SetText(L[corpse and "CORPSE_MAPZEROTH" or "WAYPOINT_ASK_ROUTE"])
    ui.corpse = corpse or nil
end

local function remember(place)
    lastSpot, lastAt = place, GetTime()
end

local function open(title, text, spot)
    ui.spot = spot
    if spot then remember(spot) end
    ui.title:SetText(title)
    ui.text:SetText(text)
    ui.frame:Show()
    fit()
    place()
end

function WaypointPrompt:Show(waypoint)
    if not ui then build() end
    ui.questID = nil
    label(false)
    open(L["WAYPOINT_ASK_TITLE"], L["WAYPOINT_ASK_TEXT"]:format(addon:GetZoneName(waypoint.mapID) or "?"), waypoint)
end

-- The question about a quest (addon:GetQuestTarget's place, with its title).
function WaypointPrompt:ShowQuest(quest)
    if not ui then build() end
    ui.questID = quest.questID
    label(false)
    open(L["QUEST_ASK_TITLE"], L["QUEST_ASK_TEXT"]:format(quest.title or L["PICK_QUEST"]), quest)
end

-- Who takes the ghost back to its corpse (TomTom loaded).
function WaypointPrompt:ShowCorpse()
    if not ui then build() end
    ui.questID = nil
    label(true)
    open(L["CORPSE_ASK_TITLE"], L["CORPSE_ASK_TEXT"], nil)
end

function WaypointPrompt:IsCorpseShown()
    return self:IsShown() and ui.corpse == true
end

function WaypointPrompt:IsShown()
    return ui ~= nil and ui.frame:IsShown()
end

-- Whether the question up is about a quest.
function WaypointPrompt:IsQuestShown()
    return self:IsShown() and ui.questID ~= nil
end

-- Whether it is the waypoint question (not a quest's or the corpse's).
local function waypointShown()
    return WaypointPrompt:IsShown() and ui.questID == nil and not ui.corpse
end

function WaypointPrompt:Hide()
    if ui then ui.frame:Hide() end
end

-- "route": plan it and go; "later": not this one; "never": the setting goes off (the settings page turns it on).
function WaypointPrompt:Answer(answer)
    local questID, corpse = ui and ui.questID, ui and ui.corpse
    self:Hide()
    if corpse then
        local with = answer == "never" and "tomtom" or answer == "later" and "both" or "mapzeroth"
        addon.Options:Set("corpseWith", with)
        addon.Corpse:Lead(with)
    elseif answer == "never" then
        if questID then addon.Options:Set("autoQuestRoute", "off") else addon.Options:Set("askWaypointRoute", false) end
    elseif answer == "route" then
        if questID then addon.QuestArrow.Route(questID) else addon.Panel:RouteToWaypoint() end
    end
end

-- Whether two places ({ mapID, x, y }) are the same spot: within SAME_SPOT yards (a waypoint dropped on a quest's
-- marker lands near its pin, not on it).
local function sameSpot(a, b)
    if not (a and b and a.x and b.x) then return false end
    if a.mapID == b.mapID and math.abs(a.x - b.x) < 1e-4 and math.abs(a.y - b.y) < 1e-4 then return true end
    local measure = addon.TravelGraph and addon.TravelGraph.DistanceProvider
    local yards = measure and measure(a, b)
    return yards ~= nil and yards <= SAME_SPOT
end

-- Whether the trip being followed goes to the waypoint with this id, or to its spot.
local function headingThere(waypoint)
    local entry = addon.Navigation:ReplanTarget()
    local dest = entry and entry.dest
    return dest ~= nil and (dest.id == waypoint.id or sameSpot(dest, waypoint))
end

-- Whether it goes to this quest.
local function headingToQuest(questID)
    local entry = addon.Navigation:ReplanTarget()
    return entry ~= nil and entry.dest ~= nil and entry.dest.questID == questID
end

-- Whether this place was just dealt with here: the question up is about it, or it was asked about or routed to a
-- moment ago (a quest's route may still be planning when the waypoint on its marker comes in).
local function justAsked(place)
    if WaypointPrompt:IsShown() and ui.spot and sameSpot(ui.spot, place) then return true end
    return lastAt ~= nil and GetTime() - lastAt <= RECENT and sameSpot(lastSpot, place)
end

-- The map waypoint changed (Core.lua, USER_WAYPOINT_UPDATED and SUPER_TRACKING_CHANGED). A new one is asked about; one
-- cleared, or replaced, takes the question about it away. One where the trip already goes, or on the quest just asked
-- about or routed to, isn't asked about: that is one question, not two.
function WaypointPrompt:OnWaypointChanged()
    local waypoint = addon:GetWaypoint()
    local id = waypoint and waypoint.id
    if id == seen then return end
    seen = id
    if waypointShown() then self:Hide() end
    if not (waypoint and ready and addon.Options:Get("askWaypointRoute")) then return end
    if headingThere(waypoint) or justAsked(waypoint) then return end
    self:Show(waypoint)
end

local function trackedQuest()
    local track = C_SuperTrack
    local id = track and track.GetSuperTrackedQuestID and track.GetSuperTrackedQuestID()
    return id ~= 0 and id or nil
end

-- The quest followed changed (Core.lua, SUPER_TRACKING_CHANGED). A new one is routed to, or asked about, by the
-- autoQuestRoute setting; one dropped takes the question about it away, unless what took its place is a map waypoint on
-- its marker (an addon setting one where the quest was clicked): that is still the question. A quest with no spot we can
-- place is let be. At "on" it is routed to even when its spot was just asked about as a waypoint (that question goes);
-- at "ask" that question is the one asked.
function WaypointPrompt:OnQuestChanged()
    local questID = trackedQuest()
    if questID == seenQuest then return end
    seenQuest = questID
    if following and following.questID ~= questID then following = nil end   -- another quest (or none): that one is let go
    if self:IsQuestShown() and not (questID == nil and sameSpot(ui.spot, addon:GetWaypoint())) then self:Hide() end
    local mode = addon.Options:Get("autoQuestRoute")
    if not (questID and ready) or mode == "off" or headingToQuest(questID) then return end
    local quest = addon:GetQuestTarget(questID)
    if not quest then return end
    if mode == "on" then
        if waypointShown() and sameSpot(ui.spot, quest) then self:Hide() end
        remember(quest)
        addon.Panel:RouteToQuest(questID)
    elseif not justAsked(quest) then
        self:ShowQuest(quest)
    end
end

-- A trip started from the panel (Panel:StartRoute; its entry). One to a quest is followed on: when that quest's spot
-- moves (an objective done, the hand-in next) the route goes on to the new spot (OnQuestSpotChanged). Any other trip
-- ends that, but the run back to the corpse, which takes the quest trip up again after (Corpse.lua).
function WaypointPrompt:OnTripStarted(entry)
    local dest = entry and entry.dest
    if dest and dest.corpse then return end
    if dest and dest.questID then
        following = { questID = dest.questID, spot = dest }
    else
        following = nil
    end
end

-- The trip was stopped by the player (Navigator:Stop on the way, not on arriving): a quest's stops being followed on.
function WaypointPrompt:OnTripStopped(entry)
    local dest = entry and entry.dest
    if following and dest and dest.questID == following.questID then following = nil end
end

-- The quest log or its map markers changed (Core.lua, QUEST_LOG_UPDATE and QUEST_POI_UPDATE). The quest followed on,
-- still the one tracked, whose spot is now somewhere else: routed to there, whether the trip to its last spot has got
-- there or is still on the way. A trip going somewhere else is let be (the corpse run: the quest trip comes back
-- after it). A quest with no spot just now waits for the next change.
function WaypointPrompt:OnQuestSpotChanged()
    if not (following and ready) then return end
    if trackedQuest() ~= following.questID then
        following = nil
        return
    end
    local entry = addon.Navigation:ReplanTarget()
    if entry and not (entry.dest and entry.dest.questID == following.questID) then return end
    local quest = addon:GetQuestTarget(following.questID)
    if not quest or sameSpot(quest, following.spot) then return end
    following.spot = quest
    remember(quest)
    addon.Panel:RouteToQuest(following.questID)
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
