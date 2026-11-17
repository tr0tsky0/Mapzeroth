local addonName, addon = ...

-- Daylight UI plugin, whatever Mapzeroth theme is picked (the Daylight look itself is UI/Themes/Daylight.lua). Only
-- when DaylightUI is loaded, and only through DaylightUI.API (its plugin guide):
--   * a step that casts a spell or uses an item lights the action bar buttons holding it (API.Glow, 1.5);
--   * a data text, "Mapzeroth: Route", for the strip under the minimap or the data bar: the step the trip is on and the
--     time left, the steps to come in its tooltip, a click shows or hides the panel (AddDataText, 1.6).
-- The navigator tells it of each update of the trip (OnTrip).

local API = DaylightUI and DaylightUI.API
if type(API) ~= "table" or API.major ~= 1 or type(API.For) ~= "function" then return end

local L = addon.L
local PLUGIN = "Mapzeroth"          -- the name Daylight UI keeps our things under ("Mapzeroth:route"), dev build or not
local TIP_STEPS = 8                 -- steps to come listed in the data text's tooltip

if type(DaylightUI.RegisterPlugin) == "function" then
    -- Credits us on General > Plugins. It errors on a second plugin of the name (the release copy also enabled).
    pcall(DaylightUI.RegisterPlugin, DaylightUI, PLUGIN, { needs = { 1, 6 }, addon = addonName })
end
local my = API.For(PLUGIN)

local Plugin = {}
addon.DaylightPlugin = Plugin

-- The route's animations on the map (marching dots, the beacon) follow the player's Daylight motion setting.
if type(API.MotionOn) == "function" then
    addon.Theme.motionOff = function() return API.MotionOn() == false end
end

-- What the step on now asks the player to cast or use, as an action bar slot holds it: "item", itemID or
-- "spell", spellID. Nil for any other step (and for putting an item on, which no bar button does).
function Plugin.ActionOf(model)
    if not model or model.finished or model.offRoute or model.kind ~= "ability" then return nil end
    local step = model.step
    local source = step and step.method ~= "equip" and step.source
    if not source then return nil end
    if source.itemID then return "item", source.itemID end
    if source.spellID then return "spell", source.spellID end
    return nil
end

-- ---------------------------------------------------------------------------------------
-- The action bars

local lit = {}                      -- action buttons we lit: button -> true

-- Lights the buttons holding (kind, id) and puts out any others we lit. kind nil: puts them all out.
local function lightBars(kind, id)
    if type(API.Glow) ~= "function" then return end
    local want = {}
    if kind and type(API.Frames) == "function" and type(API.ButtonInfo) == "function" then
        for button in API.Frames("actionbutton") do
            local info = API.ButtonInfo(button)
            if info and not info.empty and info.type == kind and info.id == id then want[button] = true end
        end
    end
    for button in pairs(lit) do
        if not want[button] then
            API.Glow(button, false)
            lit[button] = nil
        end
    end
    for button in pairs(want) do
        if not lit[button] and API.Glow(button, true) then lit[button] = true end
    end
end

-- ---------------------------------------------------------------------------------------
-- The data text

-- label, value for the data text. Daylight UI shows a lone value (nil label) in the accent.
function Plugin.RouteText()
    local model = addon.Navigation:Model()
    if not model then return nil, L["PANEL_TITLE"] end
    if model.finished then return nil, L["NAV_ARRIVED"] end
    -- Short, for a narrow strip: the step itself (and an off-route flight) is in the tooltip.
    return ("%d/%d"):format(model.index, model.total), addon.Journey:FormatTime(model.remaining)
end

local function routeTooltip(tip)
    local model = addon.Navigation:Model()
    local plan = addon.Navigation:CurrentPlan()
    if model and not model.finished and plan then
        if model.destination then tip.Text(model.destination) end
        if model.offRoute then tip.Text(L["NAV_OFFROUTE"]:format(addon:GetNodeName(model.flyingTo))) end
        local steps, last = plan.steps, math.min(#plan.steps, model.index + TIP_STEPS - 1)
        for i = model.index, last do
            tip.Line(steps[i].text, addon.Journey:FormatTime(steps[i].seconds))
        end
        if last < #steps then tip.Text(L["ROUTE_MORE_BELOW"]:format(#steps - last)) end
        tip.Text(L["NAV_LEFT"]:format(addon.Journey:FormatTime(model.remaining)))
    end
    tip.Hint(L["MINIMAP_TIP_TOGGLE"])
end

local shown                         -- what the data text last said, to redraw it only when that changes

if type(my.AddDataText) == "function" then
    my.AddDataText("route", {
        label = L["PANEL_TITLE"],
        text = Plugin.RouteText,
        tooltip = routeTooltip,
        click = function(button) if button == "LeftButton" then addon.Panel:Toggle() end end,
        icon = "Interface\\AddOns\\" .. addonName .. "\\Media\\Logo",
        -- Shown only in Daylight's test mode from 1.9.1 (1.9.0 showed it always).
        sample = "2/5",
    })
end

local function redrawText()
    if type(my.UpdateDataText) ~= "function" then return end
    local label, value = Plugin.RouteText()
    local now = (label or "") .. "\n" .. value
    if now == shown then return end
    shown = now
    my.UpdateDataText("route")
end

-- ---------------------------------------------------------------------------------------

-- Each update of the trip, from the navigator: model nil when no trip is being followed.
function Plugin:OnTrip(model)
    lightBars(Plugin.ActionOf(model))
    redrawText()
end
