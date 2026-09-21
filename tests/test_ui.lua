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
C_Spell = { GetSpellInfo = function(id) return { name = "Profession " .. id } end }
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
