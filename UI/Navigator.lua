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

local WIDTH, HEIGHT, PAD = 330, 124, 14
local INNER = WIDTH - 2 * PAD
local INTERVAL = 0.5            -- seconds between updates
local ARROW = 44                -- the direction arrow, in pixels
local LINGER = 5                -- seconds "arrived" stays up before the window closes itself

local ui

function Navigator:ApplyScale()
    if ui then ui.frame:SetScale(addon.Options:Get("scale")) end
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
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        Navigator:SavePosition()
    end)
    frame:SetScript("OnUpdate", function(_, elapsed)
        ui.timer = (ui.timer or 0) + elapsed
        if ui.timer >= INTERVAL then
            ui.timer = 0
            Navigator:Tick()
        end
    end)
    frame:Hide()
    ui.frame = frame

    ui.title = Theme:Text(frame, "title")
    ui.title:SetPoint("TOPLEFT", PAD, -12)
    ui.title:SetWidth(INNER - 130)
    ui.title:SetWordWrap(false)

    ui.count = Theme:Text(frame, "dim")
    ui.count:SetPoint("TOPRIGHT", -(PAD + 56), -15)
    ui.count:SetJustifyH("RIGHT")

    ui.stop = Theme:Button(frame, L["NAV_STOP"], 50, 20)
    ui.stop:SetPoint("TOPRIGHT", -PAD, -12)
    ui.stop:SetScript("OnClick", function() Navigator:Stop() end)

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
    ui.use = Theme:Button(frame, "", INNER, 26, true, "SecureActionButtonTemplate")
    ui.use:SetPoint("BOTTOMLEFT", PAD, 10)
    ui.use:RegisterForClicks("AnyUp", "AnyDown")
    -- For an "Equip" step the button is not secure (equipping isn't protected): after the click, put the item on.
    ui.use:SetScript("PostClick", function(self)
        if self.equipItem then addon.Equipment:Equip(self.equipItem) end
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
        label = addon:GetAbilityLabel(source) or label
    elseif source.spellID then
        ui.use:SetAttribute("type", "spell")
        ui.use:SetAttribute("spell", source.spellID)
        ui.use:SetAttribute("item", nil)
        label = addon:GetAbilityLabel(source) or label
    end
    ui.use.label:SetText(label)
end

-- The player flew somewhere the route didn't go (a mis-click; to change their mind they can stop and pick
-- again): plan the way on from where they landed.
function Navigator:Replan(entry)
    local plan = Journey:PlanFromHere(entry)
    if plan and #plan.steps > 0 then
        Navigation:Start(entry, plan, "NAV_REROUTED")
        addon.Panel:OnRerouted(entry, plan)
        ui.useStep = nil
        self:Tick()
    else
        self:Stop()
    end
end

-- Show the current model of the trip.
function Navigator:Render(model)
    if not ui then return end
    -- The map and the minimap show the route of the trip that has been started (not what the panel is showing).
    local plan = model and not model.finished and not model.replan and Navigation:CurrentPlan() or nil
    local index = model and model.index or nil
    if addon.RouteLines then addon.RouteLines:Follow(plan, index) end
    if addon.MinimapLines then addon.MinimapLines:Follow(plan, index) end
    if model and model.replan then
        self:Replan(model.entry)
        return
    end
    addon.Equipment:Sync(model)             -- put back what an equip step replaced, once the trip is past using it
    if not model then
        ui.frame:Hide()
        addon.Panel:OnTripUpdate(nil)
        return
    end

    local combat = InCombatLockdown()
    ui.title:SetText(model.destination or "")

    if model.finished then
        -- Arrived: leave it up for a moment, then clear the trip (the same as pressing Close).
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
        addon.Panel:OnTripUpdate(model)
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
        addon.Panel:OnTripUpdate(model)
        return
    end
    ui.step:SetText(model.step.text)
    ui.left:SetText(L["NAV_LEFT"]:format(Journey:FormatTime(model.remaining)))

    local status, showBar, showUse = "", false, false
    if model.kind == "walk" then
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
        status = L["NAV_PORTAL"]
    end
    ui.status:SetText(status)

    -- The arrow, when we know which way the player is facing; the text moves aside for it.
    local heading = model.kind == "walk" and model.heading
    ui.arrow:SetShown(heading ~= nil and heading ~= false)
    if heading then ui.arrow:SetRotation(heading) end
    local indent = heading and (ARROW + 8) or 0
    ui.status:ClearAllPoints()
    ui.status:SetPoint("TOPLEFT", PAD + indent, heading and -78 or -74)
    ui.status:SetWidth(INNER - 90 - indent)
    ui.left:ClearAllPoints()
    ui.left:SetPoint("TOPRIGHT", -PAD, heading and -78 or -74)

    ui.bar:SetShown(showBar)
    if showBar then ui.bar:SetValue(model.progress or 0) end
    if not combat then ui.use:SetShown(showUse) end
    if showUse then configureUse(model.step) end
    addon.Panel:OnTripUpdate(model)
end

-- One update: read where the player is, move the trip on, redraw.
function Navigator:Tick()
    Navigator:Render(Navigation:Update(Navigation:Sample()))
end

-- Begin showing the trip that Navigation has been started on.
function Navigator:Show()
    if not ui then build() end
    ui.useStep = nil
    ui.arrivedAt = nil
    self:Place()
    ui.frame:Show()
    self:Tick()
end

function Navigator:Hide()
    if ui then ui.frame:Hide() end
end

-- Stop following the trip and close the window.
function Navigator:Stop()
    if ui then ui.arrivedAt = nil end
    Navigation:Stop()
    addon.Equipment:Sync(nil)
    if addon.RouteLines then addon.RouteLines:Follow(nil) end
    if addon.MinimapLines then addon.MinimapLines:Follow(nil) end
    self:Hide()
    addon.Panel:OnTripUpdate(nil)
end
