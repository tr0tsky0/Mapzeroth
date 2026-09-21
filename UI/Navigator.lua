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

local ui

function Navigator:ApplyScale()
    if ui then ui.frame:SetScale(addon.Options:Get("scale")) end
end

local function build()
    ui = {}
    Navigator.widgets = ui              -- for tests
    addon.Options:OnChange(function(key) if key == "scale" then Navigator:ApplyScale() end end)
    local frame = Theme:Panel(UIParent, "MapzerothRebuildNavigator")
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetPoint("TOP", UIParent, "TOP", 0, -160)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
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
    if source.itemID then
        ui.use:SetAttribute("type", "item")
        ui.use:SetAttribute("item", "item:" .. source.itemID)
        ui.use:SetAttribute("spell", nil)
        local name = GetItemInfo and GetItemInfo(source.itemID)
        label = name or label
    elseif source.spellID then
        ui.use:SetAttribute("type", "spell")
        ui.use:SetAttribute("spell", source.spellID)
        ui.use:SetAttribute("item", nil)
        local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(source.spellID)
        label = info and info.name or label
    end
    ui.use.label:SetText(label)
end

-- Show the current model of the trip.
function Navigator:Render(model)
    if not ui then return end
    if not model then
        ui.frame:Hide()
        addon.Panel:OnTripUpdate(nil)
        return
    end

    local combat = InCombatLockdown()
    ui.title:SetText(model.destination or "")

    if model.finished then
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
    ui.count:SetText(L["NAV_STEP_OF"]:format(model.index, model.total))
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
    ui.frame:Show()
    self:Tick()
end

function Navigator:Hide()
    if ui then ui.frame:Hide() end
end

-- Stop following the trip and close the window.
function Navigator:Stop()
    Navigation:Stop()
    self:Hide()
    addon.Panel:OnTripUpdate(nil)
end
