-- The Daylight UI plugin, with a stand-in for DaylightUI.API: nothing without DaylightUI; with it, a step that casts a
-- spell or uses an item lights the bar buttons holding it (and only those, and puts them out after), and the "Route"
-- data text says the step and time left, redrawn only when that changes.

check(addon.DaylightPlugin == nil, "without DaylightUI there is no plugin")

local slots = {}                    -- button -> what GetActionInfo would say
local glows, dataTexts, redraws, registered, painters = {}, {}, 0, nil, {}
local holders = {}                  -- quest row -> its API.Attach holder
local function button(kind, id) local b = {}; slots[b] = { type = kind, id = id, empty = kind == nil }; return b end
local hearth, teleport, macro, empty = button("item", 6948), button("spell", 3561), button("macro", 6948), button(nil)
local hearth2 = button("item", 6948)

DaylightUI = {
    RegisterPlugin = function(self, name, spec) registered = { name = name, spec = spec } end,
    API = {
        major = 1, minor = 9,
        For = function(name)
            return {
                AddDataText = function(key, spec) dataTexts[name .. ":" .. key] = spec; return true end,
                UpdateDataText = function() redraws = redraws + 1 end,
                Paint = function(kind, fn) painters[kind] = fn; return true end,
            }
        end,
        Attach = function(f)
            if not f.isRow then return nil end
            holders[f] = holders[f] or { isHolder = true }
            return holders[f]
        end,
        Accent = function() return 0.6, 0.4, 0.9 end,
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

-- The quest tracker's route arrow: a button on each quest row's holder, beside its first line below the title.
local paintRow = painters.questrow
check(paintRow == Plugin.PaintQuestRow, "it paints the quest tracker's rows")
local made = {}
local function stubRegion()
    local r = { shown = true, scripts = {}, points = {} }
    function r:SetSize(w, h) self.w, self.h = w, h end
    function r:SetPoint(...) self.points[#self.points + 1] = { ... } end
    function r:ClearAllPoints() self.points = {} end
    function r:SetScript(k, fn) self.scripts[k] = fn end
    function r:SetAlpha(a) self.alpha = a end
    function r:Show() self.shown = true end
    function r:Hide() self.shown = false end
    function r:RegisterForClicks() end
    function r:SetTexture(t) self.texture = t end
    function r:SetRotation(a) self.rotation = a end
    function r:SetVertexColor(...) self.color = { ... } end
    function r:CreateTexture() return stubRegion() end
    return r
end
local realCreateFrame = CreateFrame
CreateFrame = function(kind, name, parent)
    local b = stubRegion()
    b.kind, b.parent = kind, parent
    made[#made + 1] = b
    return b
end
local line = { GetFont = function() return "font", 12 end }
local rowA = { isRow = true }
paintRow(rowA, { objectives = { line } }, { questID = 42 })
local arrow = made[1]
check(#made == 1 and arrow.kind == "Button" and arrow.parent == holders[rowA], "the arrow goes on the row's holder")
check(arrow.questID == 42 and arrow.shown and arrow.points[1][2] == line and arrow.points[1][3] == "TOPLEFT",
      "beside the first line below the title, for that row's quest")
check(arrow.tex.texture:find("Media\\Arrow$") and arrow.tex.rotation < 0 and arrow.tex.color[1] == 0.6,
      "our arrow, tilted, in the Daylight accent")
paintRow(rowA, { objectives = { line } }, { questID = 43 })
check(#made == 1 and arrow.questID == 43, "a row reused for another quest keeps its arrow, now for that quest")
paintRow(rowA, { objectives = {} }, { questID = 43 })
check(not arrow.shown, "a folded quest (no line below its title) has none")
paintRow({}, { objectives = { line } }, { questID = 44 })
check(#made == 1, "a frame Daylight UI won't attach to gets nothing")

-- A click routes to the quest; one with no spot says so.
local routed, said
addon.Panel = addon.Panel or {}
local realRouteToQuest = addon.Panel.RouteToQuest
addon.Panel.RouteToQuest = function(_, id) routed = id; return id ~= 7 end
UIErrorsFrame = { AddMessage = function(_, text) said = text end }
paintRow(rowA, { objectives = { line } }, { questID = 43 })
arrow.scripts.OnClick(arrow)
check(routed == 43 and said == nil, "a click routes to its quest")
Plugin.RouteQuest(7)
check(said == addon.L["QUEST_NO_SPOT"], "a quest with no spot says why nothing happened")
addon.Panel.RouteToQuest, UIErrorsFrame, CreateFrame = realRouteToQuest, nil, realCreateFrame

model = { finished = true, total = 4 }
check(select(2, Plugin.RouteText()) == addon.L["NAV_ARRIVED"], "at the end it says so")
Plugin:OnTrip(nil)
check(next(glows) == nil, "a stopped trip lights nothing")
