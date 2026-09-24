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
check(addon.Panel:StatusText() == nil, "no \"nothing matches\" message while there are results")
addon.Panel:Query("zzzzqq")
check(#state.results == 0 and state.selected == 0, "nothing matches nonsense")
check(addon.Panel:StatusText() == "Nothing matches.", "and then it says so: " .. tostring(addon.Panel:StatusText()))
addon.Panel:Query("iron")
check(addon.Panel:StatusText() == nil, "and the message goes away when there are results again")
addon.Panel:Query("")
check(state.view == "list", "an empty box shows the accordion")

-- An X at the right end of the search box clears it, and only shows when there is something to clear.
local box = addon.Panel.widgets
check(box.clear and not box.clear._shown, "the clear button is hidden while the box is empty")
box.search:SetText("iron")
box.search._scripts.OnTextChanged(box.search)
check(box.clear._shown and not box.hint._shown, "typing shows it")
box.clear._scripts.OnClick()
check(box.search:GetText() == "" and not box.clear._shown and box.hint._shown, "clicking it empties the box and hides it again")
check(state.view == "list" and #state.results >= 1 and state.results[1].header, "and the search goes back to the sections")

-- The pop-out button: docked by default, and toggling it flips state, the Options setting and
-- the button's own label. (This mock frame has no real geometry -- GetLeft/GetTop return
-- nothing -- so SavePosition's "nothing to save yet" guard is what's under test here, not the
-- actual screen position, which only the game can tell us.)
check(state.docked == true, "docked by default")
check(box.pop.label:GetText() == "Pop out", "the button offers to pop out while docked")
box.pop._scripts.OnClick()
check(state.docked == false and addon.Options:Get("docked") == false, "clicking it undocks")
check(box.pop.label:GetText() == "Dock", "and now offers to dock again")
box.pop._scripts.OnClick()
check(state.docked == true and addon.Options:Get("docked") == true, "clicking it again re-docks")
check(box.pop.label:GetText() == "Pop out", "and the label flips back")

-- Choosing a result shows its route.
addon.Panel:Query("ironforge flight")
local flightMaster
for i, r in ipairs(state.results) do if r.group == "flight" then flightMaster = i end end
check(flightMaster, "the Ironforge flight master is a result")
addon.Panel:Choose(flightMaster)
check(state.view == "route" and state.plan, "choosing it plans the trip")
check(#state.plan.steps >= 2 and state.plan.steps[#state.plan.steps].method == "taxi", "walk to the flight master, then fly")
check(state.plan.cost > 0, "with a time")

-- A route with more steps than fit scrolls into view instead of losing the rest (previously
-- there was no way to see past the "+N" hint: reported after a real 8-step route), and the panel
-- says how many are out of sight, above as well as below (a scrolled-away first step was missed).
local function fakeStep(i) return { method = "walk", seconds = 10, text = "Step " .. i, approx = false } end
local longSteps = {}
for i = 1, 10 do longSteps[i] = fakeStep(i) end
local LAST = #box.steps                       -- how many rows the list has
addon.Panel:DisplayPlan({ name = "Somewhere far" }, { steps = longSteps, cost = 90 })
check(box.steps[1].name._text == "Step 1" and box.steps[LAST].name._text == "Step " .. LAST, "the first " .. LAST .. " show")
check(box.more._text == ("%d more below"):format(10 - LAST), "and how many are hidden below: " .. tostring(box.more._text))
addon.Panel:Scroll(1)
check(box.steps[1].name._text == "Step 2" and box.steps[LAST].name._text == "Step " .. (LAST + 1), "the wheel moves the window: " .. box.steps[1].name._text)
check(box.more._text == ("1 more above   %d more below"):format(10 - LAST - 1), "the hidden counts follow, both ways: " .. tostring(box.more._text))
addon.Panel:Scroll(1000)
check(box.steps[LAST].name._text == "Step 10" and box.more._text == ("%d more above"):format(10 - LAST),
    "scrolling clamps at the end, with only what is above left to hint: " .. tostring(box.more._text))
addon.Panel:Scroll(-1000)
check(box.steps[1].name._text == "Step 1", "and clamps back at the start")

-- A step the player has reached that's scrolled out of sight is scrolled back into view.
state.pinned = true
local realModel = addon.Navigation.Model
addon.Navigation.Model = function() return { index = 10, finished = false } end
addon.Panel:MarkCurrentStep()
check(box.steps[LAST].name._text == "Step 10" and box.steps[LAST].sel._shown, "the current step scrolls into view and is marked: " .. box.steps[LAST].name._text)
addon.Navigation.Model = realModel
state.pinned = false

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
local other = before == "classic" and "moderndark" or "classic"
Theme:Set(other)
check(Theme:Current().id == other, "switching changes theme: " .. Theme:Current().id)
addon.Panel:Query("iron")
addon.Panel:Choose(1)
Theme:Set(before)
check(Theme:Current().id == before, "and switches back")
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
addon.Panel:Query("ironforge flight")
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
addon.Navigation:Start({ name = "Ironforge" }, { steps = { { method = "taxi", fromID = "TAXI_2", nodeID = "TAXI_6", seconds = 200, text = "Fly" } } })
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
    addon.Panel:Query("ironforge flight")
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

-- Before anything is typed: an accordion of sections, closed, and nothing priced until one is opened.
maps[1416] = { name = "Alterac Mountains", mapType = 3, parentMapID = 1415 }
maps[1431] = { name = "Duskwood", mapType = 3, parentMapID = 1415 }
maps[1433] = { name = "Redridge Mountains", mapType = 3, parentMapID = 1415 }
addon:ClearNodeNameCache()
WorldMapFrame._hooks.OnShow()
addon.Panel:Query("")
local function headerIndex(id)
    for i, row in ipairs(state.results) do if row.header and row.id == id then return i end end
end
local function pickNamed(name)
    for _, row in ipairs(state.results) do if row.pick and row.name == name then return row end end
end
check(#state.results >= 2, "the empty window shows the accordion's sections")
for _, row in ipairs(state.results) do check(row.header and not row.open, "and they start closed: " .. tostring(row.name)) end
check(not state.priced, "nothing is priced just for opening the window")

-- Opening a section prices it, from where the player stands, and lists its items with their times.
local cities = headerIndex("cities")
check(cities, "there is a Cities section")
addon.Panel:Choose(cities)
check(state.priced and state.open.cities and state.results[cities].open, "opening Cities opens it and prices it")
local shown, timed = 0, 0
for _, row in ipairs(state.results) do
    if row.inSection then shown = shown + 1; if row.eta then timed = timed + 1 end end
end
check(shown >= 2 and timed >= 1, "its cities are listed with travel times: " .. shown .. " listed, " .. timed .. " timed")
local firstCity
for _, row in ipairs(state.results) do if row.inSection then firstCity = firstCity or row end end
check(addon.Panel.Subtitle(firstCity) == (firstCity.zone or ""), "under Cities a city says just its zone: " .. tostring(addon.Panel.Subtitle(firstCity)))
local asResult = {}
for k, v in pairs(firstCity) do asResult[k] = v end
asResult.inSection = nil
check(addon.Panel.EtaText(firstCity) ~= "" or firstCity.eta == nil, "an item of an open section shows its time")
check(addon.Panel.EtaText(asResult) == "", "but the same place as a search result shows none, though it was priced")
check(addon.Panel.Subtitle(asResult):find("^City %- ") or addon.Panel.Subtitle(asResult):find("^Town %- "),
    "in a search result it says what it is: " .. addon.Panel.Subtitle(asResult))
addon.Panel:Choose(cities)
check(not state.open.cities, "choosing the heading again closes it")

-- A section can hold sections (Modern's "Older content"): opening it shows its inner headings, a step in,
-- and opening one of those shows its places, a step further.
local function place(name) return { name = name, nodeID = "N_" .. name, nodeIDs = { "N_" .. name }, group = "place", kind = "city", zone = "Z" } end
local savedSections, savedOpen = state.sections, state.open
state.sections = { { id = "older", title = "Older", items = {}, children = {
    { id = "expansion5", title = "Pandaria", items = { place("Shrine") } },
    { id = "expansion4", title = "Cataclysm", items = {} },
} } }
state.open = {}
addon.Panel:Query("")
check(#state.results == 1 and state.results[1].count == 1, "a closed parent is one heading counting the places inside")
addon.Panel:Choose(1)
check(#state.results == 3 and state.results[2].header and state.results[2].depth == 1, "opened, its inner headings show, a step in")
addon.Panel:Choose(2)
check(#state.results == 4 and state.results[3].inSection and state.results[3].depth == 2 and state.results[3].name == "Shrine",
    "and opening one shows its places a step further in")
state.sections, state.open = savedSections, savedOpen
addon.Panel:Query("")

-- A character who can't read ley lines has no such pick; a Skyborne does.
local relevant = headerIndex("relevant")
check(relevant, "there is a Personally relevant section")
addon.Panel:Choose(relevant)
check(not pickNamed("Nearest Ley Line"), "no ley line pick for a character who can't read them")
check(pickNamed("Nearest Class Trainer"), "but their class trainer is there")
addon.Panel:Choose(relevant)
IsPlayerSpell = function(id) return id == 1259705 end       -- Read Ley Line: a Skyborne
WorldMapFrame._hooks.OnShow()
addon.Panel:Query("")
addon.Panel:Choose(headerIndex("relevant"))
local leyline = pickNamed("Nearest Ley Line")
check(leyline and leyline.group == "leyline" and #leyline.nodeIDs >= 4, "a Skyborne is offered the nearest ley line, over every one we know")
IsPlayerSpell = function() return false end

-- A waypoint set on the map is the first personally relevant pick, and the accordion follows it being set or cleared.
C_Map.HasUserWaypoint = function() return true end
C_Map.GetUserWaypoint = function() return { uiMapID = 1453, position = { GetXY = function() return 0.4, 0.3 end } } end
addon.Panel:OnWaypointChanged()
addon.Panel:Choose(headerIndex("relevant"))
local way = pickNamed("Your Waypoint")
check(way and way.dest and way.dest.mapID == 1453 and state.results[headerIndex("relevant") + 1] == way, "a waypoint is the first pick under Personally relevant")
check(way.eta ~= nil, "and priced when the section is opened")
C_Map.HasUserWaypoint = function() return false end
addon.Panel:OnWaypointChanged()
addon.Panel:Choose(headerIndex("relevant"))
check(not pickNamed("Your Waypoint"), "clearing it removes the pick")
C_Map.HasUserWaypoint, C_Map.GetUserWaypoint = nil, nil

-- Searching still works, and lists everything.
addon.Panel:Query("storm")
check(#state.results > 0 and not state.results[1].header, "typing searches as before")
WorldMapFrame._hooks.OnShow()

-- The route is drawn on the world map's canvas, follows the step the trip is on, and is taken down when the
-- route is left. (Frames here record what they are asked to draw.)
local drawn = {}
local realCreateFrame = CreateFrame
CreateFrame = function()
    local f = mock()
    f.GetWidth = function() return 1000 end
    f.GetHeight = function() return 500 end
    f.GetEffectiveScale = function() return 1 end
    f.SetFrameLevel = function(self, level) self._level = level end
    f.CreateLine = function()
        local line = mock()
        line.SetStartPoint = function(self, _, _, x, y) self._from = { x, y } end
        line.SetEndPoint = function(self, _, _, x, y) self._to = { x, y } end
        line.SetThickness = function(self, t) self._thickness = t end
        line.SetColorTexture = function(self, r, g, b, a) self._alpha = a end
        drawn[#drawn + 1] = line
        return line
    end
    return f
end
WorldMapFrame.GetCanvas = function() return mock() end
WorldMapFrame.GetMapID = function() return 1453 end
WorldMapFrame._shown = true
local RouteLines = addon.RouteLines
local function shown()
    local n = 0
    for _, line in ipairs(drawn) do if line._shown then n = n + 1 end end
    return n
end
C_Map.GetBestMapForUnit = function() return 1453 end
C_Map.GetPlayerMapPosition = function() return { GetXY = function() return 0.60, 0.60 end } end
WorldMapFrame._hooks.OnShow()
-- Looking at a route (chosen and priced) draws nothing: only a trip that has been started does.
addon.Panel:Query("ironforge flight")
local previewIndex
for i, r in ipairs(state.results) do if r.group == "flight" then previewIndex = i end end
addon.Panel:Choose(previewIndex)
check(state.view == "route" and state.plan and shown() == 0 and RouteLines.state.badgesUsed == 0, "a route that is only being looked at is not drawn on the map")
startTrip()
check(shown() > 10 and RouteLines.state.linesUsed == shown(), "started, a route on foot is drawn as many short dots: " .. shown())
check(RouteLines.state.badgesUsed >= 2, "with a badge for a step and one for the end: " .. RouteLines.state.badgesUsed)
local inside = true
for _, line in ipairs(drawn) do
    if line._shown and not (line._from[1] >= 0 and line._from[1] <= 1000 and line._from[2] <= 0 and line._from[2] >= -500) then inside = false end
end
check(inside, "all of it on the canvas")
local faded = 0
for _, line in ipairs(drawn) do if line._shown and line._alpha and line._alpha < 1 and line._alpha > 0.2 then faded = faded + 1 end end
RouteLines:SetCurrent(2)
check(shown() > 0, "moving on to the next step redraws it")
addon.Options:Set("showRouteOnMap", false)
check(shown() == 0, "switched off in the settings, the route leaves the map")
addon.Options:Set("showRouteOnMap", true)
check(shown() > 0, "and comes back when it is switched on")
-- The map's own art (its detail layers and explored-area overlays) hides anything under it, so the route goes just above.
local art = {}
art[{ GetFrameLevel = function() return 7 end }] = true
art[{ GetFrameLevel = function() return 12 end }] = true
WorldMapFrame.detailLayerPool = { EnumerateActive = function() return pairs(art) end }
WorldMapFrame.pinPools = {
    MapExplorationPinTemplate = { EnumerateActive = function() return pairs({ [{ GetFrameLevel = function() return 20 end }] = true }) end },
    QuestPinTemplate = { EnumerateActive = function() return pairs({ [{ GetFrameLevel = function() return 500 end }] = true }) end },
}
RouteLines:Redraw()
check(RouteLines.state.frame._level == 21, "above the highest art layer (the exploration overlays) but not above the points of interest: " .. tostring(RouteLines.state.frame._level))
WorldMapFrame.detailLayerPool, WorldMapFrame.pinPools = nil, nil
addon.Panel:Query("storm")
check(shown() > 0, "going back to the search page doesn't take it down: the trip goes on")
addon.Navigator:Stop()
check(shown() == 0 and RouteLines.state.badgesUsed == 0, "stopping the trip takes the lines down")

-- A failure while drawing never reaches the map.
startTrip()
check(shown() > 0, "drawn again for a new route")
WorldMapFrame.GetMapID = function() error("the map isn't ready") end
local ok = pcall(function() RouteLines:Redraw() end)
check(ok and shown() == 0 and RouteLines.state.error, "an error while drawing is caught and leaves it undrawn: " .. tostring(RouteLines.state.error))
WorldMapFrame.GetMapID = function() return 1453 end
addon.Navigator:Stop()
CreateFrame = realCreateFrame

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
check(addon.OptionsPanel:Open() and openedID == 42, "/mapzeroth settings opens the page")

-- Two on/off settings: the route on the map and on the minimap.
check(pw.routeMap.button.label._text:find("On", 1, true) and pw.routeMinimap.button.label._text:find("On", 1, true), "both route settings show On by default")
pw.routeMap:Select(false)
check(Options:Get("showRouteOnMap") == false and pw.routeMap.button.label._text:find("Off", 1, true), "choosing Off for the map turns it off")
pw.routeMinimap:Select(false)
check(Options:Get("showRouteOnMinimap") == false, "and the same for the minimap")
registeredFrame.OnDefault()
check(Options:Get("showRouteOnMap") == true and Options:Get("showRouteOnMinimap") == true and pw.routeMap.button.label._text:find("On", 1, true),
    "the Defaults button turns both back on")
check(pw.routeMinimap.hint._text ~= "This client's minimap can't show the route." or not addon.MinimapLines:IsAvailable(),
    "the minimap row only says it can't when the client can't")
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
