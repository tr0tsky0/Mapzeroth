-- The Daylight UI plugin, with a stand-in for DaylightUI.API: nothing without DaylightUI; with it, a step that casts a
-- spell or uses an item lights the bar buttons holding it (and only those, and puts them out after), and the "Route"
-- data text says the step and time left, redrawn only when that changes; quests with a spot get "Route with Mapzeroth"
-- in their menu.

check(addon.DaylightPlugin == nil, "without DaylightUI there is no plugin")

local slots = {}                    -- button -> what GetActionInfo would say
local glows, dataTexts, redraws, registered, questMenus = {}, {}, 0, nil, {}
local function button(kind, id) local b = {}; slots[b] = { type = kind, id = id, empty = kind == nil }; return b end
local hearth, teleport, macro, empty = button("item", 6948), button("spell", 3561), button("macro", 6948), button(nil)
local hearth2 = button("item", 6948)

DaylightUI = {
    RegisterPlugin = function(self, name, spec) registered = { name = name, spec = spec } end,
    API = {
        major = 1, minor = 11,
        For = function(name)
            return {
                AddDataText = function(key, spec) dataTexts[name .. ":" .. key] = spec; return true end,
                UpdateDataText = function() redraws = redraws + 1 end,
                AddQuestMenu = function(key, spec) questMenus[name .. ":" .. key] = spec; return true end,
            }
        end,
        Frames = function(kind)
            local list = {}
            if kind == "actionbutton" then for b in pairs(slots) do list[#list + 1] = b end end
            local i = 0
            return function() i = i + 1; return list[i] end
        end,
        ButtonInfo = function(b) return slots[b] end,
        Glow = function(b, on) glows[b] = on or nil; return true end,
    },
}

local f = assert(io.open(ADDON_ROOT .. "/UI/DaylightPlugin.lua", "r"))
local src = f:read("*a")
f:close()
assert(loadstring(src, "DaylightPlugin.lua"))("Mapzeroth-Dev", addon)
local Plugin = addon.DaylightPlugin
check(Plugin, "with DaylightUI the plugin loads")
check(registered and registered.name == "Mapzeroth" and registered.spec.addon == "Mapzeroth-Dev",
      "it registers as Mapzeroth, its details from the dev build's TOC")
local route = dataTexts["Mapzeroth:route"]
check(route and route.label == "Mapzeroth" and route.text and route.tooltip and route.click, "it adds the Route data text")

-- The trip, as Navigation would have it.
local model, plan
addon.Navigation.Model = function() return model end
addon.Navigation.CurrentPlan = function() return plan end
local function step(method, source, text) return { method = method, source = source, text = text, seconds = 60 } end
plan = { steps = { step("hearthstone", { itemID = 6948 }, "Use Hearthstone"), step("walk", nil, "Walk to the inn"),
                   step("teleport", { spellID = 3561 }, "Cast Teleport: Stormwind"), step("equip", { itemID = 6948 }, "Equip it") } }
local function at(i, kind) model = { index = i, total = #plan.steps, step = plan.steps[i], kind = kind, remaining = 300 } end

-- Nothing to cast: nothing lit, and the data text names the addon.
check(select(2, Plugin.RouteText()) == "Mapzeroth" and select(1, Plugin.RouteText()) == nil, "no trip: just the name")
Plugin:OnTrip(nil)
check(next(glows) == nil, "no trip lights nothing")

at(1, "ability")
Plugin:OnTrip(model)
check(glows[hearth] and glows[hearth2], "a hearthstone step lights every button holding the hearthstone")
check(not glows[macro] and not glows[teleport] and not glows[empty], "and no other button (a macro isn't the item)")
local label, value = Plugin.RouteText()
check(label == "1/4" and value == addon.Journey:FormatTime(model.remaining),
      "the data text is short: the step number and the time left: " .. tostring(value))
local before = redraws
Plugin:OnTrip(model)
check(redraws == before, "the same text isn't redrawn")

at(2, "walk")
Plugin:OnTrip(model)
check(next(glows) == nil, "a walk puts the lights out")
check(redraws == before + 1, "a new step redraws the data text")

at(3, "ability")
Plugin:OnTrip(model)
check(glows[teleport] and not glows[hearth], "a teleport step lights the spell's button")

-- The player drags the spell to another slot: the old button goes dark, the new one lights.
slots[teleport] = { type = "spell", id = 118, empty = false }
slots[empty] = { type = "spell", id = 3561, empty = false }
Plugin:OnTrip(model)
check(glows[empty] and not glows[teleport], "the light follows the spell to its new button")

at(4, "ability")
Plugin:OnTrip(model)
check(next(glows) == nil, "putting an item on lights nothing")

-- The tooltip lists the steps to come and the time left.
at(2, "walk")
local tip = { lines = {} }
tip.Text = function(t) tip.lines[#tip.lines + 1] = t end
tip.Line = function(a, b) tip.lines[#tip.lines + 1] = a .. "|" .. b end
tip.Hint = function(t) tip.hint = t end
route.tooltip(tip)
check(tip.lines[1]:find("^Walk to the inn|") and #tip.lines == 4 and tip.hint, "the tooltip has the steps from here on")

-- The quest menu row: "Route with Mapzeroth" for a quest with a spot to route to; a click routes there.
local row = questMenus["Mapzeroth:route"]
check(row and row.label == addon.L["QUEST_ROUTE_MENU"] and row.show == Plugin.QuestHasRoute and row.onClick,
      "it adds Route with Mapzeroth to the quest menu")
local realTarget = addon.GetQuestTarget
addon.GetQuestTarget = function(_, id) if id == 42 then return { id = 42 } end end
check(row.show({ questID = 42, title = "A quest", state = "active" }), "shown for a quest with a spot")
check(not row.show({ questID = 7 }), "left out for a quest with no spot")
check(not row.show({}), "left out without a quest id")
addon.GetQuestTarget = realTarget
local routed, said
addon.Panel = addon.Panel or {}
local realRouteToQuest = addon.Panel.RouteToQuest
addon.Panel.RouteToQuest = function(_, id) routed = id; return id ~= 7 end
UIErrorsFrame = { AddMessage = function(_, text) said = text end }
row.onClick({ questID = 42 })
check(routed == 42 and said == nil, "a click routes to its quest")
addon.QuestArrow.Route(7)
check(said == addon.L["QUEST_NO_SPOT"], "a quest with no spot says why nothing happened")
addon.Panel.RouteToQuest, UIErrorsFrame = realRouteToQuest, nil

model = { finished = true, total = 4 }
check(select(2, Plugin.RouteText()) == addon.L["NAV_ARRIVED"], "at the end it says so")
Plugin:OnTrip(nil)
check(next(glows) == nil, "a stopped trip lights nothing")
