-- The panel and the themes, driven with stand-ins for WoW's frames. This catches typos, nil
-- errors and broken logic in the layout and skin code; whether the client draws it well is
-- only something the game can tell us.
useTestDistances()
addon.World:Build()

-- A frame that remembers the little state we read back and ignores every other call.
local function mock(isFontString)
    local obj = { _shown = true, _text = "", _scripts = {}, _hooks = {}, _isFontString = isFontString }
    return setmetatable(obj, { __index = function(_, key)
        if key:sub(1, 1) == "_" or key:sub(1, 2) == "mz" then return nil end     -- our own fields, unset until set
        local special = {
            -- What the client enforces: a label needs a font before it can show text.
            SetFontObject = function(self, font)
                if font == nil then error("SetFontObject: no such font", 2) end
                self._font = font
            end,
            SetText = function(self, v)
                if self._isFontString and not self._font then error("FontString:SetText(): Font not set", 2) end
                self._text = v
            end,
            GetText = function(self) return self._text end,
            Show = function(self) self._shown = true end,
            Hide = function(self) self._shown = false end,
            SetShown = function(self, v) self._shown = v and true or false end,
            IsShown = function(self) return self._shown end,
            SetScript = function(self, name, fn) self._scripts[name] = fn end,
            HookScript = function(self, name, fn) self._hooks[name] = fn end,
            SetAttribute = function(self, k, v) self._attrs = self._attrs or {}; self._attrs[k] = v end,
            SetAtlas = function(self, a) self._atlas = a end,
            SetValue = function(self, v) self._value = v end,
            SetScale = function(self, v) self._scale = v end,
            SetRotation = function(self, v) self._rotation = v end,
            SetTexture = function(self, v) self._texture = v end,
            SetThumbTexture = function(self, a) self._thumb = mock() end,
            GetThumbTexture = function(self) return self._thumb end,
            GetRight = function() return 1000 end,
            GetFrameLevel = function() return 5 end,
            CreateFontString = function() return mock(true) end,
            CreateTexture = function() return mock() end,
            -- The client wants an asset here (nil is an error), and has a texture only once set.
            SetNormalTexture = function(self, a) if a == nil then error("Usage: self:SetNormalTexture(asset)", 2) end self._normal = mock() end,
            SetPushedTexture = function(self, a) if a == nil then error("Usage: self:SetPushedTexture(asset)", 2) end self._pushed = mock() end,
            SetHighlightTexture = function(self, a) if a == nil then error("Usage: self:SetHighlightTexture(asset)", 2) end self._highlight = mock() end,
            GetNormalTexture = function(self) return self._normal end,
            GetPushedTexture = function(self) return self._pushed end,
            GetHighlightTexture = function(self) return self._highlight end,
        }
        return special[key] or function() end
    end })
end
CreateFrame = function() return mock() end
-- The font objects the themes name (the client defines these).
GameFontNormal, GameFontNormalLarge, GameFontHighlight, GameFontHighlightSmall = {}, {}, {}, {}
WorldMapFrame = mock()
WorldMapFrame._shown = false
InCombatLockdown = function() return false end
GetTime = function() return 100 end
UnitOnTaxi = function() return false end
UIParent = mock()

-- The client bits the panel reads.
local maps = {
    [1453] = { name = "Stormwind City", mapType = 3, parentMapID = 1415 },
    [1429] = { name = "Elwynn Forest", mapType = 3, parentMapID = 1415 },
    [1455] = { name = "Ironforge", mapType = 3, parentMapID = 1415 },
    [1426] = { name = "Dun Morogh", mapType = 3, parentMapID = 1415 },
    [1415] = { name = "Eastern Kingdoms", mapType = 2, parentMapID = 947 },
    [947] = { name = "Azeroth", mapType = 1, parentMapID = 0 },
}
C_Map = {
    GetMapInfo = function(id) return maps[id] end,
    GetBestMapForUnit = function() return 1453 end,
    GetPlayerMapPosition = function() return { GetXY = function() return 0.60, 0.60 end } end,
}
Enum = { UIMapType = { Continent = 2 } }
C_TaxiMap = { GetTaxiNodesForMap = function(id)
    if id == 1415 then
        return { { nodeID = 2, name = "Stormwind, Elwynn" }, { nodeID = 6, name = "Ironforge, Dun Morogh" } }
    end
    return {}
end }
LOCALIZED_CLASS_NAMES_MALE = { DRUID = "Druid", MAGE = "Mage", WARRIOR = "Warrior", HUNTER = "Hunter",
    PALADIN = "Paladin", PRIEST = "Priest", ROGUE = "Rogue", SHAMAN = "Shaman", WARLOCK = "Warlock" }
local skillNames = { [201] = "One-Handed Swords", [202] = "Two-Handed Swords", [227] = "Staves" }
C_Spell = { GetSpellInfo = function(id) return { name = skillNames[id] or ("Profession " .. id) } end }
addon:ClearNodeNameCache()

-- The player has read Stormwind's flight window: Ironforge is found.
addon.FlightKnowledge:Reset()
addon.FlightKnowledge:Record({ { nodeID = 2, state = 0 }, { nodeID = 6, state = 1 } }, makeCtx({}))

-- Themes: both are registered and both skin what we build.
local Theme = addon.Theme
check(#Theme:List() == 2, "two themes ship: " .. table.concat(Theme:List(), ","))
Theme:Init("moderndark")
check(Theme:Current().id == "moderndark", "Modern Dark is the default")

-- The panel attaches to the map.
check(addon.Panel:Init() == true, "the panel attaches when the map exists")
check(WorldMapFrame._hooks.OnShow, "and hooks the map opening")
WorldMapFrame._hooks.OnShow()
local state = addon.Panel:GetState()
check(#state.entries > 100, "opening the map loads the destinations: " .. #state.entries)
check(state.ctx ~= nil, "and reads who the player is (nothing is priced yet)")
check(state.view == "list", "and starts on the list")

-- Typing searches.
addon.Panel:Query("iron")
check(#state.results > 0 and state.results[1].name:lower():find("iron", 1, true), "typing 'iron' finds Ironforge places")
check(state.selected == 1, "the first result is selected")
addon.Panel:Move(1)
check(state.selected == 2, "the arrow keys move the selection")
addon.Panel:Move(-5)
check(state.selected == 1, "and stop at the top")
addon.Panel:Query("sword")
check(#state.results > 0 and state.results[1].detailHit and state.results[1].detailHit:find("Swords"),
    "typing a weapon finds the trainers that teach it, and says which: " .. tostring(state.results[1] and state.results[1].detailHit))
addon.Panel:Query("zzzzqq")
check(#state.results == 0 and state.selected == 0, "nothing matches nonsense")
addon.Panel:Query("")
check(state.view == "list", "an empty box shows the quick picks (none for a fresh character)")

-- Choosing a result shows its route.
addon.Panel:Query("ironforge, dun")
local flightMaster
for i, r in ipairs(state.results) do if r.group == "flight" then flightMaster = i end end
check(flightMaster, "the Ironforge flight master is a result")
addon.Panel:Choose(flightMaster)
check(state.view == "route" and state.plan, "choosing it plans the trip")
check(#state.plan.steps >= 2 and state.plan.steps[#state.plan.steps].method == "flight", "walk to the flight master, then fly")
check(state.plan.cost > 0, "with a time")

-- Escape goes back, then clears, then leaves the box.
addon.Panel:Escape()
check(state.view == "list", "Escape returns to the list")

-- Scrolling stays in range.
addon.Panel:Query("e")
addon.Panel:Scroll(1000)
check(state.offset <= math.max(0, #state.results - 8), "scrolling stops at the end")
addon.Panel:Scroll(-1000)
check(state.offset == 0, "and at the start")

-- Switching theme re-skins everything, and every widget has a skin.
local before = Theme:Current().id
Theme:Cycle()
check(Theme:Current().id ~= before, "cycling changes theme: " .. Theme:Current().id)
addon.Panel:Query("iron")
addon.Panel:Choose(1)
Theme:Cycle()
check(Theme:Current().id == before, "and cycles back")
local count, missing = Theme:Audit()
check(count > 30 and missing == 0, "every widget is themed: " .. count .. " widgets, " .. missing .. " without a skin")
check(Theme:Set("classic") and Theme:Set("moderndark") and not Theme:Set("nope"), "themes are set by id")

-- Colours come from the theme, never the panel.
local r, g, b = Theme:Color("accent")
check(r > 0.5 and g > 0.5 and b < 0.5, "Modern Dark's accent is brass")
Theme:Set("classic")
r, g, b = Theme:Color("accent")
check(r == 1 and math.abs(g - 0.82) < 0.01 and b == 0, "Classic's accent is Blizzard gold")
Theme:Set("moderndark")

-- Toggling hides and shows.
check(addon.Panel:Toggle() == false and addon.Panel:Toggle() == true, "the panel can be toggled off and on")

-- Route view: no waypoint, a Start button, and choosing does the pricing.
addon.Panel:Query("ironforge, dun")
local fm
for i, r in ipairs(state.results) do if r.group == "flight" then fm = i end end
addon.Panel:Choose(fm)
check(state.plan and #state.plan.steps > 0, "choosing plans it now, from where the player stands")

-- Start hands the trip to the navigator, which follows it.
check(not addon.Navigation:IsActive(), "no trip until Start")
addon.Panel:StartRoute()
check(addon.Navigation:IsActive(), "Start begins following the route")
local w = addon.Navigator.widgets
check(w and w.frame._shown, "and the navigator appears")
addon.Navigator:Tick()
local model = addon.Navigation:Model()
check(model and model.step and model.total == #state.plan.steps, "a tick reads the player and produces the current step")
check(w.step._text == model.step.text, "the navigator shows the step: " .. tostring(w.step._text))
check(w.count._text == "Step 1 of " .. model.total or w.count._text:find("Step"), "and where in the trip: " .. tostring(w.count._text))

-- An item-use step shows a button set up to use the item (the hearthstone).
local usePlan = { steps = { { method = "hearthstone", fromID = "YOU", nodeID = "TAXI_4", seconds = 25,
    source = { itemID = 6948 }, text = "Use your Hearthstone" } } }
addon.Navigation:Start({ name = "Home" }, usePlan)
addon.Navigator:Show()
check(w.use._attrs and w.use._attrs.type == "item" and w.use._attrs.item == "item:6948", "the button uses the hearthstone item")
check(w.use._shown and not w.bar._shown, "a button, no bar, for an item")
addon.Navigation:Start({ name = "Away" }, { steps = { { method = "teleport", fromID = "YOU", nodeID = "TAXI_4", seconds = 20,
    source = { spellID = 18960 }, text = "Teleport" } } })
addon.Navigator:Show()
check(w.use._attrs.type == "spell" and w.use._attrs.spell == 18960, "a spell step casts the spell")

-- In combat the button isn't reconfigured (secure attributes can't change then).
InCombatLockdown = function() return true end
addon.Navigation:Start({ name = "X" }, usePlan)
addon.Navigator:Show()
check(w.use._attrs.spell == 18960 and w.status._text == "Can't be used in combat", "in combat it leaves the button alone and says so")
InCombatLockdown = function() return false end

-- A flight shows a bar once flying; arriving shows the end message.
addon.Navigation:Start({ name = "Ironforge" }, { steps = { { method = "flight", fromID = "TAXI_2", nodeID = "TAXI_6", seconds = 200, text = "Fly" } } })
addon.Navigator:Show()
check(not w.bar._shown, "no bar while waiting to take off")
UnitOnTaxi = function() return true end
addon.Navigator:Tick()
check(w.bar._shown, "a bar once the taxi has left")
UnitOnTaxi = function() return false end
local ironforge = addon.World:GetNode("TAXI_6")
C_Map.GetBestMapForUnit = function() return ironforge.mapID end
C_Map.GetPlayerMapPosition = function() return { GetXY = function() return ironforge.x, ironforge.y end } end
addon.Navigator:Tick()
check(w.step._text == "Destination reached", "landing at the destination ends the trip: " .. tostring(w.step._text))
addon.Navigator:Stop()
check(not addon.Navigation:IsActive() and not w.frame._shown, "Stop clears the trip and closes the navigator")

-- Classic reads the quest log's own background from the game.
QuestScrollFrame = { Background = { GetAtlas = function() return "questlog-background" end } }
Theme:Set("classic")
local panelFrame = addon.Panel:GetFrame()
check(panelFrame.mzFill._atlas == "questlog-background", "Classic's panel uses the quest log's background: " .. tostring(panelFrame.mzFill._atlas))
QuestScrollFrame = nil
Theme:Set("moderndark")

-- A started route stays on screen: closing and reopening the map shows it again, and the search
-- page only comes back when the trip ends, or the player goes back or searches.
C_Map.GetBestMapForUnit = function() return 1453 end
C_Map.GetPlayerMapPosition = function() return { GetXY = function() return 0.60, 0.60 end } end
local function startTrip()
    addon.Panel:Query("ironforge, dun")
    local index
    for i, r in ipairs(state.results) do if r.group == "flight" then index = i end end
    addon.Panel:Choose(index)
    addon.Panel:StartRoute()
end

startTrip()
check(state.pinned and addon.Navigation:IsActive(), "starting pins the route")
local tripEntry, tripPlan = state.entry, state.plan
WorldMapFrame._hooks.OnShow()                      -- the map closed and opened again
check(state.view == "route" and state.entry == tripEntry and state.plan == tripPlan,
    "reopening the map shows the same route, not the search page")
addon.Navigator:Tick()
check(state.view == "route" and state.pinned, "and it stays while the trip is followed")

-- Going back leaves it; the trip carries on in the navigator, but the panel shows the search page.
addon.Panel:Escape()
check(state.view == "list" and not state.pinned and addon.Navigation:IsActive(), "Back returns to the search page; the trip continues")
WorldMapFrame._hooks.OnShow()
check(state.view == "list", "and it stays there when the map is reopened")

-- Stop returns to the search page, and a search does too.
startTrip()
addon.Navigator:Stop()
check(state.view == "list" and not state.pinned and not addon.Navigation:IsActive(), "Stop ends the trip and shows the search page")
startTrip()
addon.Panel:Query("storm")
check(state.view == "list" and not state.pinned, "searching something else leaves the route")

-- Arriving returns to the search page too.
startTrip()
addon.Panel:OnTripUpdate({ finished = true })
check(state.view == "list" and not state.pinned, "arriving at the destination shows the search page")
WorldMapFrame._hooks.OnShow()
check(state.view == "list", "and reopening the map keeps it there")
addon.Navigator:Stop()

-- A flight to the wrong place: the navigator says where it goes, then plans again on landing.
startTrip()
local oldPlan = state.plan
addon.Navigation:OnTakeTaxi({ "TAXI_8" }, 100)
UnitOnTaxi = function() return true end
addon.Navigator:Tick()
local nav = addon.Navigator.widgets
check(nav.step._text:find("Flying to") and not nav.bar._shown, "flying off the route: the window says where, with no bar: " .. tostring(nav.step._text))
UnitOnTaxi = function() return false end
addon.Navigator:Tick()
check(addon.Navigation:IsActive() and nav.count._text == "Route updated", "on landing the route is planned again and says so: " .. tostring(nav.count._text))
check(state.pinned and state.plan ~= oldPlan and state.plan and #state.plan.steps > 0, "the panel shows the new route")
addon.Navigator:Stop()

-- Before anything is typed: the nearest ley line for a Skyborne, and no "Home".
maps[1416] = { name = "Alterac Mountains", mapType = 3, parentMapID = 1415 }
maps[1431] = { name = "Duskwood", mapType = 3, parentMapID = 1415 }
maps[1433] = { name = "Redridge Mountains", mapType = 3, parentMapID = 1415 }
addon:ClearNodeNameCache()
addon.Panel:Query("")
check(#state.results == 0, "a character who can't read ley lines has no quick picks")
IsPlayerSpell = function(id) return id == 1259705 end       -- Read Ley Line: a Skyborne
state.ctx = addon:GetPlayerContext()
state.ctx.hearthNode = "TAXI_2"                            -- and a hearthstone bound somewhere
WorldMapFrame._hooks.OnShow()
local picks = addon.Panel:GetState().results
check(#picks == 1 and picks[1].group == "leyline" and picks[1].name == "Nearest ley line", "a Skyborne is offered the nearest ley line")
check(#picks[1].nodeIDs >= 4, "over every ley line we know: " .. #picks[1].nodeIDs)
IsPlayerSpell = function() return false end

-- The main window has no theme button any more: the theme is a setting.
check(addon.Panel.UpdateThemeLabel == nil, "the panel has no theme button to update")

-- The settings page: registered with the game's Settings window, showing and changing the settings.
local registeredFrame, openedID
Settings = {
    RegisterCanvasLayoutCategory = function(frame, name) registeredFrame = frame; return { GetID = function() return 42 end } end,
    RegisterAddOnCategory = function() end,
    OpenToCategory = function(id) openedID = id end,
}
local Options = addon.Options
Options:Reset()
check(addon.OptionsPanel:Register() and registeredFrame.name == "Mapzeroth", "the page registers with the Settings window as Mapzeroth")
local pw = addon.OptionsPanel.widgets
addon.OptionsPanel:Sync()
check(pw.tax.slider._value == 10 and pw.tax.value._text == "10 s", "it shows the loading screen time: " .. tostring(pw.tax.value._text))
check(pw.scale.slider._value == 1 and pw.scale.value._text == "100%", "and the scale: " .. tostring(pw.scale.value._text))
check(pw.theme.button.label._text:find("Modern Dark", 1, true), "and the theme: " .. tostring(pw.theme.button.label._text))

pw.tax.slider._scripts.OnValueChanged(pw.tax.slider, 15, true)
check(Options:Get("loadingScreenTax") == 15 and pw.tax.value._text == "15 s", "moving the loading screen slider changes the setting")
pw.scale.slider._scripts.OnValueChanged(pw.scale.slider, 1.2, true)
check(math.abs(Options:Get("scale") - 1.2) < 1e-9 and pw.scale.value._text == "120%", "moving the scale slider changes it")
check(math.abs(addon.Panel:GetFrame()._scale - 1.2) < 1e-9, "the panel resizes with it")
check(math.abs(addon.Navigator.widgets.frame._scale - 1.2) < 1e-9, "and so does the trip window")

pw.theme:Select("classic")
check(Theme:Current().id == "classic" and Options:Get("theme") == "classic", "choosing a theme in the dropdown applies it")
check(pw.theme.menu._shown == false, "and closes the list")

registeredFrame.OnDefault()
check(Options:Get("loadingScreenTax") == 10 and Options:Get("scale") == 1 and Theme:Current().id == "moderndark", "the Defaults button restores everything")
check(pw.tax.value._text == "10 s", "and the page shows it")
check(addon.OptionsPanel:Open() and openedID == 42, "/mzr settings opens the page")
Options:Reset()

-- On foot the navigator shows an arrow that turns to the destination.
addon.Navigation:Start({ name = "Stormwind" }, { steps = { { method = "walk", fromID = "YOU", nodeID = "TAXI_2", seconds = 60, text = "Walk to the flight master" } } })
local target = addon.World:GetNode("TAXI_2")
C_Map.GetBestMapForUnit = function() return target.mapID end
C_Map.GetPlayerMapPosition = function() return { GetXY = function() return target.x, target.y + 0.1 end } end
GetPlayerFacing = function() return math.pi / 2 end          -- facing west, the flight master is north of the player
addon.Navigator:Show()
local nw = addon.Navigator.widgets
check(nw.arrow._shown and math.abs(nw.arrow._rotation + math.pi / 2) < 1e-6, "the arrow points 90 degrees to the right: " .. tostring(nw.arrow._rotation))
check(nw.arrow._texture and nw.arrow._texture:find("ROTATING-MINIMAPARROW", 1, true), "and uses the theme's arrow: " .. tostring(nw.arrow._texture))
GetPlayerFacing = nil
addon.Navigator:Tick()
check(not nw.arrow._shown, "without a facing there is no arrow")
addon.Navigator:Stop()
