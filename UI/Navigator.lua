local addonName, addon = ...

-- The small window that follows a trip once it has started: the step you are on, and what
-- matters for that kind of step (distance on foot, a bar in flight or on a boat, a button for
-- a hearthstone or teleport), then "Destination reached". It hangs off the screen, not the
-- map, so it stays while you run around with the map closed; drag it where you like.
-- The what-to-show logic is Navigation.lua's; this file only draws its model. Styling goes
-- through addon.Theme, and frames are built on first use.

local Navigator = {}
addon.Navigator = Navigator

local L = addon.L
local Theme = addon.Theme
local Journey = addon.Journey
local Navigation = addon.Navigation

local WIDTH, HEIGHT, PAD = 330, 142, 14
local INNER = WIDTH - 2 * PAD
local INTERVAL = 0.5            -- seconds between updates
local POINTER_INTERVAL = 0.05   -- and between turns of the arrow (and the yards beside it) on foot, in between
local ARROW = 54                -- the direction arrow, in pixels
local LINGER = 5                -- seconds "arrived" stays up before the window closes itself

local ui

-- Each update of the trip goes to the panel, and to the Daylight UI plugin when that is loaded (nil: no trip now).
local function tripUpdate(model)
    addon.Panel:OnTripUpdate(model)
    if addon.DaylightPlugin then addon.DaylightPlugin:OnTrip(model) end
end

-- The window holds a secure button (ui.use), so in combat the game counts the whole window as protected: it can't be
-- shown, hidden, moved or scaled until combat ends (ADDON_ACTION_BLOCKED). The real hide, a show of a hidden window, its
-- placing and its scale wait for PLAYER_REGEN_ENABLED. A hide in combat leaves the window up, saying it closes when
-- combat ends: faded out instead, it still took clicks and its button still cast, unseen. (Render leaves it saying so.)
local function closingNotice()
    ui.count:SetText("")
    ui.step:SetText(L["NAV_CLOSES_AFTER_COMBAT"])
    ui.status:SetText("")
    ui.left:SetText("")
    ui.bar:Hide()
    ui.arrow:Hide()
    ui.pointing = false
end

local function setShown(on)
    local frame = ui.frame
    if InCombatLockdown() then
        ui.pending = on
        if not on and frame:IsShown() then closingNotice() end
        return                                                  -- a hidden window is shown and placed once combat ends
    end
    ui.pending = nil
    frame:SetShown(on)
end

function Navigator:ApplyScale()
    if not ui then return end
    if InCombatLockdown() then
        ui.rescale = true
        return
    end
    ui.frame:SetScale(addon.Options:Get("scale"))
end

local function onUpdate(_, elapsed)
    ui.timer = (ui.timer or 0) + elapsed
    ui.pointerTimer = (ui.pointerTimer or 0) + elapsed
    if ui.timer >= INTERVAL then
        ui.timer, ui.pointerTimer = 0, 0
        Navigator:Tick()
    elseif ui.pointerTimer >= POINTER_INTERVAL then
        ui.pointerTimer = 0
        Navigator:Point()
    end
end
Navigator.OnUpdate = onUpdate           -- for tests

local function running(on)
    ui.events:SetScript("OnUpdate", on and onUpdate or nil)
end

-- Combat is over: do what it held back.
local function afterCombat()
    if ui.rescale then
        ui.rescale = nil
        Navigator:ApplyScale()
    end
    local pending = ui.pending
    if pending == nil then return end
    if pending and not ui.frame:IsShown() then Navigator:Place() end
    setShown(pending)
    if pending then Navigator:Tick() end
end

-- Where the window sits. Where the player last dragged it, kept in the saved variables; until they have, just
-- below the panel (the picker), so a trip starts under it instead of somewhere across the screen. The panel's
-- position is read once, here, not followed: the trip window has to stay put when the map closes.
function Navigator:SavePosition()
    local left, top = ui.frame:GetLeft(), ui.frame:GetTop()
    if not (left and top) then return end
    MapzerothRebuildDB = MapzerothRebuildDB or {}
    MapzerothRebuildDB.navPos = { x = left, y = top }
end

function Navigator:Place()
    local frame = ui.frame
    frame:ClearAllPoints()
    local saved = MapzerothRebuildDB and MapzerothRebuildDB.navPos
    if saved then
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", saved.x, saved.y)
        return
    end
    local panel = addon.Panel and addon.Panel:GetFrame()
    local left, bottom = panel and panel:GetLeft(), panel and panel:GetBottom()
    if left and bottom then
        -- Screen units differ between the two frames (the panel lives under the map, which can be scaled).
        local ratio = panel:GetEffectiveScale() / frame:GetEffectiveScale()
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left * ratio, bottom * ratio - 4)
        return
    end
    frame:SetPoint("TOP", UIParent, "TOP", 0, -160)
end

local function build()
    ui = {}
    Navigator.widgets = ui              -- for tests
    addon.Options:OnChange(function(key) if key == "scale" then Navigator:ApplyScale() end end)
    local frame = Theme:Panel(UIParent, "MapzerothRebuildNavigator")
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetPoint("TOP", UIParent, "TOP", 0, -160)         -- until Place puts it where it belongs
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if not InCombatLockdown() then self:StartMoving() end      -- protected in combat (setShown)
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        Navigator:SavePosition()
    end)
    frame:Hide()
    ui.frame = frame
    -- The trip's clock runs on this frame, never hidden, so a trip goes on with the window put away; only while one runs.
    ui.events = CreateFrame("Frame")
    ui.events:RegisterEvent("PLAYER_REGEN_ENABLED")
    ui.events:SetScript("OnEvent", afterCombat)

    ui.title = Theme:Text(frame, "title")
    ui.title:SetPoint("TOPLEFT", PAD, -12)
    ui.title:SetWidth(INNER - 156)
    ui.title:SetWordWrap(false)

    ui.count = Theme:Text(frame, "dim")
    ui.count:SetPoint("TOPRIGHT", -(PAD + 82), -15)
    ui.count:SetJustifyH("RIGHT")

    ui.stop = Theme:Button(frame, L["NAV_STOP"], 50, 20)
    ui.stop:SetPoint("TOPRIGHT", -PAD, -12)
    ui.stop:SetScript("OnClick", function() Navigator:Stop() end)

    -- Plan the route again from where the player is (they left it, and the steps no longer fit).
    ui.recalc = Theme:IconButton(frame, 20, "reroute", L["NAV_RECALC"])
    ui.recalc:SetPoint("TOPRIGHT", -(PAD + 56), -12)
    ui.recalc:SetScript("OnClick", function() Navigator:Recalculate() end)

    ui.step = Theme:Text(frame, "body")
    ui.step:SetPoint("TOPLEFT", PAD, -38)
    ui.step:SetWidth(INNER)
    ui.step:SetWordWrap(true)
    ui.step:SetMaxLines(2)

    -- On foot: an arrow that turns to point at the destination, relative to where you face.
    ui.arrow = Theme:Arrow(frame, ARROW)
    ui.arrow:SetPoint("TOPLEFT", PAD, -68)
    ui.arrow:Hide()

    ui.status = Theme:Text(frame, "accent")
    ui.status:SetPoint("TOPLEFT", PAD, -74)
    ui.status:SetWidth(INNER - 90)
    ui.status:SetWordWrap(false)

    ui.left = Theme:Text(frame, "dim")
    ui.left:SetPoint("TOPRIGHT", -PAD, -74)
    ui.left:SetJustifyH("RIGHT")

    -- Bottom strip: a progress bar for flights and boats, or a button for something to use.
    ui.bar = Theme:Bar(frame, INNER, 12)
    ui.bar:SetPoint("BOTTOMLEFT", PAD, 16)

    -- A secure button: it can cast a spell or use an item on a click, but its attributes can only
    -- be changed out of combat.
    -- It shows the spell's or item's own icon beside its name.
    ui.use = Theme:ActionButton(frame, INNER, 34, "SecureActionButtonTemplate")
    ui.use:SetPoint("BOTTOMLEFT", PAD, 10)
    ui.use:RegisterForClicks("AnyUp", "AnyDown")
    -- For an "Equip" step the button is not secure (equipping isn't protected): after the click, put the item on.
    -- (Registered for both press and release: equip once, on the release.)
    ui.use:SetScript("PostClick", function(self, _, down)
        if self.equipItem and not down then addon.Equipment:Equip(self.equipItem) end
    end)

    Navigator:ApplyScale()
end

-- Sets what the use-button does for this step, if we can (not in combat).
local function configureUse(step)
    if InCombatLockdown() then
        ui.status:SetText(L["NAV_COMBAT"])
        return
    end
    ui.use:Enable()
    if ui.useStep == step then return end
    ui.useStep = step

    local source = step.source or {}
    local label = step.text
    ui.use:SetIcon(Theme:StepIcon(step.method, step.source))
    ui.use.equipItem = nil
    if step.method == "equip" then
        ui.use:SetAttribute("type", nil)
        ui.use:SetAttribute("item", nil)
        ui.use:SetAttribute("spell", nil)
        ui.use.equipItem = source.itemID
        ui.use.label:SetText(label)
        return
    end
    if source.itemID then
        ui.use:SetAttribute("type", "item")
        ui.use:SetAttribute("item", "item:" .. source.itemID)
        ui.use:SetAttribute("spell", nil)
        local name = addon:GetAbilityLabel(source)
        label = name and L["STEP_USE_ITEM"]:format(name) or label
    elseif source.spellID then
        ui.use:SetAttribute("type", "spell")
        ui.use:SetAttribute("spell", source.spellID)
        ui.use:SetAttribute("item", nil)
        local name = addon:GetAbilityLabel(source)
        label = name and L["STEP_CAST"]:format(name) or label
    end
    ui.use.label:SetText(label)
end

-- The player flew somewhere the route didn't go (a mis-click; to change their mind they can stop and pick
-- again): plan the way on from where they landed.
-- Follows `plan` instead of the trip being followed; false when there is no plan to follow.
local function restart(entry, plan)
    if not (plan and #plan.steps > 0) then return false end
    plan.holiday = entry and entry.holiday              -- a holiday route keeps its look on the map
    Navigation:Start(entry, plan, "NAV_REROUTED")
    addon.Panel:OnRerouted(entry, plan)
    ui.useStep = nil
    Navigator:Tick()
    return true
end

function Navigator:Replan(entry, returnTo)
    if not restart(entry, Journey:PlanFromHere(entry, returnTo)) then self:Stop() end
end

-- The recalculate button: the rest of the trip planned again from here. If no route can be found from here, the trip
-- goes on as it was.
function Navigator:Recalculate()
    local entry, returnTo = Navigation:ReplanTarget()
    if entry then restart(entry, Journey:PlanFromHere(entry, returnTo)) end
end

-- A trip to the map waypoint has got there: the waypoint goes, unless the player has set another one meanwhile.
local function clearReachedWaypoint(dest)
    if not (dest and dest.id and dest.id:find("^WAYPOINT_")) then return end
    local now = addon:GetWaypoint()
    if now and now.id == dest.id and C_Map.ClearUserWaypoint then C_Map.ClearUserWaypoint() end
end

-- Show the current model of the trip.
function Navigator:Render(model)
    if not ui then return end
    ui.pointing = false             -- until a step on foot says otherwise
    -- The map and the minimap show the route of the trip that has been started, over any the panel is previewing.
    local plan = model and not model.finished and not model.replan and Navigation:CurrentPlan() or nil
    local index = model and model.index or nil
    if addon.RouteLines then addon.RouteLines:Follow(plan, index) end
    if addon.MinimapLines then addon.MinimapLines:Follow(plan, index) end
    if model and model.replan then
        self:Replan(model.entry, model.returnTo)
        return
    end
    addon.Equipment:Sync(model)             -- put back what an equip step replaced, once the trip is past using it
    if not model then
        running(false)
        setShown(false)
        tripUpdate(nil)
        return
    end

    local combat = InCombatLockdown()
    -- Put away in combat (setShown): the trip goes on, the window keeps saying it closes when combat ends.
    if combat and ui.pending == false then
        if model.finished then
            if not ui.arrivedAt then clearReachedWaypoint(model.dest) end
            ui.arrivedAt = ui.arrivedAt or GetTime()
            if GetTime() - ui.arrivedAt >= LINGER then self:Stop() return end
        end
        tripUpdate(model)
        return
    end
    -- A new step, or the end: a theme that can draws the eye to the window (not as the trip first shows).
    local moment = model.finished and "end" or model.index
    if ui.moment ~= nil and moment ~= ui.moment then Theme:Pulse(ui.frame) end
    ui.moment = moment
    ui.title:SetText(model.destination or "")
    -- Planning again only makes sense standing on the ground: not once there, nor in the air or at sea.
    ui.recalc:SetShown(not (model.finished or model.offRoute or model.phase == "flying" or model.phase == "underway"))

    if model.finished then
        -- Arrived: leave it up for a moment, then clear the trip (the same as pressing Close).
        if not ui.arrivedAt then clearReachedWaypoint(model.dest) end
        ui.arrivedAt = ui.arrivedAt or GetTime()
        if GetTime() - ui.arrivedAt >= LINGER then
            self:Stop()
            return
        end
        ui.count:SetText("")
        ui.step:SetText(L["NAV_ARRIVED"])
        ui.status:SetText("")
        ui.left:SetText("")
        ui.bar:Hide()
        ui.arrow:Hide()
        if not combat then ui.use:Hide() end
        ui.stop.label:SetText(L["NAV_CLOSE"])
        tripUpdate(model)
        return
    end

    ui.stop.label:SetText(L["NAV_STOP"])
    ui.count:SetText(model.notice and L[model.notice] or L["NAV_STEP_OF"]:format(model.index, model.total))
    if model.offRoute then
        -- Somewhere the route doesn't go: say where, and that it will sort itself out on landing.
        ui.step:SetText(L["NAV_OFFROUTE"]:format(addon:GetNodeName(model.flyingTo)))
        ui.status:SetText("")
        ui.left:SetText("")
        ui.bar:Hide()
        ui.arrow:Hide()
        if not combat then ui.use:Hide() end
        tripUpdate(model)
        return
    end
    ui.step:SetText(model.step.text)
    ui.left:SetText(L["NAV_LEFT"]:format(Journey:FormatTime(model.remaining)))

    local status, showBar, showUse = "", false, false
    if model.kind == "walk" then
        ui.pointing = true          -- Point turns the arrow and counts the yards down between updates
        if model.distance then status = L["NAV_DISTANCE"]:format(math.floor(model.distance + 0.5)) end
    elseif model.kind == "flight" then
        status = model.phase == "flying" and L["NAV_FLYING"] or L["NAV_WAIT_FLIGHT"]
        if model.overrun then status = L["NAV_LONGER"] end
        showBar = model.phase == "flying"
    elseif model.kind == "transport" then
        status = model.phase == "underway" and L["NAV_UNDERWAY"] or L["NAV_WAIT_BOARD"]
        if model.overrun then status = L["NAV_LONGER"] end
        showBar = model.phase == "underway"
    elseif model.kind == "ability" then
        showUse = true
        -- An item just put on has a cooldown before it can be used: say how long is left.
        local itemID = model.step.source and model.step.source.itemID
        local wait = itemID and model.step.method ~= "equip" and addon.Equipment:CooldownLeft(itemID) or 0
        if wait > 0.5 then status = L["NAV_ITEM_READY_IN"]:format(math.ceil(wait)) end
    elseif model.kind == "portal" then
        status = model.step and model.step.clickPortal and L["NAV_PORTAL_CLICK"] or L["NAV_PORTAL"]
    end
    ui.status:SetText(status)

    -- The arrow, when we know which way the player is facing; the text moves aside for it.
    local heading = model.kind == "walk" and model.heading
    ui.arrow:SetShown(heading ~= nil and heading ~= false)
    if heading then ui.arrow:SetRotation(heading) end
    local indent = heading and (ARROW + 8) or 0
    ui.status:ClearAllPoints()
    ui.status:SetPoint("TOPLEFT", PAD + indent, heading and -88 or -74)     -- level with the arrow's middle
    ui.status:SetWidth(INNER - 90 - indent)
    ui.left:ClearAllPoints()
    ui.left:SetPoint("TOPRIGHT", -PAD, heading and -88 or -74)

    ui.bar:SetShown(showBar)
    if showBar then ui.bar:SetValue(model.progress or 0) end
    if not combat then ui.use:SetShown(showUse) end
    if showUse then configureUse(model.step) end
    tripUpdate(model)
end

-- Between updates on foot: turn the arrow and count the yards down from where the player is now, nothing else.
-- (The arrow's showing and the text beside it are laid out by Render; this only changes what it already shows.)
function Navigator:Point()
    if not (ui and ui.pointing) then return end
    local distance, heading = Navigation:Pointer()
    if heading and ui.arrow:IsShown() then ui.arrow:SetRotation(heading) end
    if distance then ui.status:SetText(L["NAV_DISTANCE"]:format(math.floor(distance + 0.5))) end
end

-- One update: read where the player is, move the trip on, redraw.
function Navigator:Tick()
    Navigator:Render(Navigation:Update(Navigation:Sample()))
    Navigator:CheckTomTom()
end

-- With the setting on, a tour of TomTom's waypoints drops the stops whose waypoint was deleted in TomTom, and the rest
-- is planned again from here (spread over frames, as the panel plans a tour). TomTom has no event for it: looked at once
-- a second, and not in the air or at sea (it waits for the landing). A rest that can't be planned leaves the trip as it
-- was, and isn't tried again for that trip.
local TOMTOM_CHECK_SECONDS = 1
function Navigator:CheckTomTom()
    if not (ui and addon.Options:Get("dropRemovedTomTom")) or ui.dropping then return end
    local now = GetTime and GetTime() or 0
    if ui.tomtomAt and now - ui.tomtomAt < TOMTOM_CHECK_SECONDS then return end
    ui.tomtomAt = now
    local plan = Navigation:CurrentPlan()
    if not plan or plan == ui.dropFailed then return end
    local model = Navigation:Model()
    if not model or model.finished or model.offRoute or model.phase == "flying" or model.phase == "underway" then return end
    local points = addon:GetTomTomPoints()
    local gone = points and Navigation:StopsGone(addon.MultiRoute.PlaceIDs(points))
    if gone then self:DropStops(gone) end
end

-- The trip without the stops in `gone` (a set of place ids): none left ends it.
function Navigator:DropStops(gone)
    local entry, returnTo = Navigation:ReplanTarget(gone)
    if not (entry and entry.stops) then return end
    if #entry.stops == 0 then
        self:Stop()
        return
    end
    local before = Navigation:CurrentPlan()
    ui.dropping = true
    addon.MultiRoute:Run(function(yield) return Journey:PlanFromHere(entry, returnTo, yield) end, function(plan)
        ui.dropping = nil
        if Navigation:CurrentPlan() ~= before then return end          -- the trip changed or stopped meanwhile
        if not restart(entry, plan) then ui.dropFailed = before end
    end)
end

-- Begin showing the trip that Navigation has been started on.
function Navigator:Show()
    if not ui then build() end
    ui.useStep = nil
    ui.arrivedAt = nil
    ui.moment = nil
    ui.away = not addon.Options:Get("showNavigator")       -- the setting off: the trip starts with the window put away
    if not (ui.away or InCombatLockdown()) then self:Place() end   -- in combat, a hidden window is placed when it ends
    setShown(not ui.away)
    running(true)
    self:Tick()
end

function Navigator:Hide()
    if ui then setShown(false) end
end

-- Whether the trip's window is put away (the panel's button, or the setting at the start).
function Navigator:IsAway()
    return ui ~= nil and ui.away == true
end

-- The panel's button: put the window away for this trip, or bring it back. Returns whether it is away now.
function Navigator:ToggleWindow()
    if not (ui and Navigation:IsActive()) then return false end
    ui.away = not ui.away
    if not (ui.away or ui.frame:IsShown() or InCombatLockdown()) then self:Place() end
    setShown(not ui.away)
    if not ui.away then self:Tick() end
    return ui.away
end

-- Stop following the trip and close the window.
function Navigator:Stop()
    if ui then
        ui.arrivedAt = nil
        running(false)
    end
    Navigation:Stop()
    addon.Equipment:Sync(nil)
    if addon.RouteLines then addon.RouteLines:Follow(nil) end
    if addon.MinimapLines then addon.MinimapLines:Follow(nil) end
    self:Hide()
    tripUpdate(nil)
end
