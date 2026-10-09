-- The accordion on the main window: what each section holds for a character, and its travel times.
useTestDistances()
addon.World:Build()

-- Names come from the client; stand-ins that keep every place named.
addon.GetNodeName = function(_, id) return "Place " .. id end
addon.GetZoneName = function(_, mapID) return "Zone " .. tostring(mapID) end
addon.GetCityName = function(_, key) return "City " .. key end
addon.GetTownName = function(_, key) return "Town " .. key end
addon.GetTrainerTypeName = function(_, token) return token:sub(1, 1) .. token:sub(2):lower() end
addon.GetSkillName = function(_, id) return "Skill " .. id end

local function sectionsFor(overrides)
    local ctx = makeCtx(overrides)
    local entries = addon.Destinations:Build(ctx)
    return addon.Sections:Build(entries, ctx), entries, ctx
end
local function section(sections, id)
    for _, s in ipairs(sections) do if s.id == id then return s end end
end
-- Every pick, by name: the top ones and the trainers.
local function allPicks(sections)
    local list = {}
    for _, item in ipairs(sections.top or {}) do list[#list + 1] = item end
    for _, item in ipairs(section(sections, "trainers") and section(sections, "trainers").items or {}) do list[#list + 1] = item end
    return list
end
local function picks(sections)
    local names = {}
    for _, item in ipairs(allPicks(sections)) do names[item.name] = item end
    return names
end

-- A mage: their class trainer and a weapon master (they can learn weapons), no pets, no ley lines.
local sections, entries = sectionsFor({ class = "MAGE", faction = "Alliance" })
check(#sections == 3 and sections[1].id == "trainers" and sections[2].id == "cities" and sections[3].id == "towns",
    "their nearest trainers, cities, towns, in that order")
check(sections[1].title == addon.L["SECTION_TRAINERS"], "under its own heading")
for _, item in ipairs(sections.top) do
    check(item.group ~= "trainer", "no trainer among the top picks: " .. item.name)
end
for _, item in ipairs(sections[1].items) do
    check(item.group == "trainer", "and only trainers under the heading: " .. item.name)
end
local mage = picks(sections)
check(mage["Class Trainer"] and #mage["Class Trainer"].nodeIDs >= 2, "a mage has a class trainer pick over every mage trainer")
check(mage["Weapon Trainer"], "and a weapon master that teaches something they can learn")
check(not mage["Pet Trainer"] and not mage["Demon Trainer"] and not mage["Nearest Ley Line"], "no pet or demon trainers, no ley lines")
for _, item in ipairs(allPicks(sections)) do
    if not item.action then
        check(item.nodeIDs and #item.nodeIDs > 0 and item.nodeID == item.nodeIDs[1], "each pick can be routed to: " .. item.name)
    end
end

-- The last top picks are tours: pasting coordinates always, TomTom's waypoints only when it has some (MultiRoute.lua).
do
    local items = sections.top
    check(items[#items].action == "paste" and items[#items].name == addon.L["PICK_PASTE"], "the last pick is pasting coordinates")
    local tomtom = false
    for _, item in ipairs(items) do if item.action == "tomtom" then tomtom = true end end
    check(not tomtom, "no TomTom pick without TomTom")
    local ctx = makeCtx({ class = "MAGE", faction = "Alliance" })
    local withTomTom = addon.Sections:Build(addon.Destinations:Build(ctx), ctx, nil, 5)
    local list = withTomTom.top
    check(list[#list - 1].action == "tomtom" and list[#list - 1].name == addon.L["PICK_TOMTOM"]:format(5),
        "with waypoints in TomTom, a pick for them comes before it: " .. tostring(list[#list - 1].name))
    check(#addon.Sections:Build(addon.Destinations:Build(ctx), ctx, nil, 0).top == #items,
        "and none for an empty TomTom")
end

-- A pick turned off on the settings page isn't offered; turned back on, it is.
do
    addon.Options:SetShowsPick("class", false)
    addon.Options:SetShowsPick("paste", false)
    local hidden = picks((sectionsFor({ class = "MAGE", faction = "Alliance" })))
    check(not hidden["Class Trainer"] and not hidden[addon.L["PICK_PASTE"]], "turned-off picks are left out")
    check(hidden["Weapon Trainer"], "the rest stay")
    addon.Options:SetShowsPick("class", true)
    addon.Options:SetShowsPick("paste", true)
    check(picks((sectionsFor({ class = "MAGE", faction = "Alliance" })))["Class Trainer"], "turned back on, it's there again")
    for _, item in ipairs(allPicks(sections)) do
        check(item.key, "every pick names the setting that hides it: " .. item.name)
    end
end

-- The settings page lists every pick this character could be offered, whether or not they are now.
do
    local function keys(list)
        local out = {}
        for _, c in ipairs(list) do out[c.key] = c.label end
        return out
    end
    local mageChoices = keys(addon.Sections:PickChoices("MAGE", "Alliance", false))
    check(mageChoices.waypoint and mageChoices.class and mageChoices.weapon and mageChoices.paste, "the waypoint, class, weapon and paste picks")
    check(mageChoices.prof_ALCHEMY == "Alchemy Trainer" and mageChoices.prof_MINING, "every profession, had or not")
    check(mageChoices.leyline == addon.L["PICK_LEYLINE"] and not mageChoices.pet and not mageChoices.tomtom,
        "the ley line pick, no pet trainer for a mage, no TomTom without it")
    local hunter = keys(addon.Sections:PickChoices("HUNTER", "Horde", true))
    check(hunter.pet == addon.L["PICK_PET"] and hunter.leyline == addon.L["PICK_CONVERGENCE"] and hunter.tomtom,
        "a Horde hunter with TomTom: a pet trainer, convergences, and TomTom's waypoints")
end

-- Only the professions they have, by the client's name for each.
local alchemist = picks((sectionsFor({ class = "MAGE", faction = "Alliance", spells = { addon.Professions.ALCHEMY } })))
check(alchemist["Alchemy Trainer"], "a known profession gets its trainer")
check(not alchemist["Mining Trainer"], "an unknown one doesn't")
check(not mage["Alchemy Trainer"], "and a character with no professions has none")

-- Pet trainers for hunters, demon trainers for warlocks.
check(picks((sectionsFor({ class = "HUNTER", faction = "Alliance" })))["Pet Trainer"], "a hunter has a pet trainer")
check(picks((sectionsFor({ class = "WARLOCK", faction = "Alliance" })))["Demon Trainer"], "a warlock has a demon trainer")
check(not picks((sectionsFor({ class = "WARRIOR", faction = "Alliance" })))["Pet Trainer"], "a warrior has neither")

-- Ley lines for Skyborne (whoever can read them).
local skyborne = picks((sectionsFor({ class = "DRUID", faction = "Alliance", spells = { 1259705 } })))
check(skyborne["Nearest Ley Line"] and #skyborne["Nearest Ley Line"].nodeIDs >= 4, "a Skyborne has the nearest ley line, over all of them")

-- Horde Skyborne get the nearest elemental convergence instead, and no ley line.
local hordeSky = picks((sectionsFor({ class = "DRUID", faction = "Horde", spells = { 1259686 } })))
check(hordeSky["Nearest Elemental Convergence"] and #hordeSky["Nearest Elemental Convergence"].nodeIDs >= 4, "a Horde Skyborne has the nearest convergence, over all of them")
check(not hordeSky["Nearest Ley Line"] and not skyborne["Nearest Elemental Convergence"], "each faction gets only its own")
do
    local top = (sectionsFor({ class = "DRUID", faction = "Alliance", spells = { 1259705 } })).top
    check(top[1].group == "leyline", "the ley line pick is a top pick, first without a waypoint")
end

-- Weapons already known aren't offered again: a character who knows all of a weapon master's skills gets no pick.
local knowsAll = {}
for _, class in pairs(addon.ClassWeapons) do for _, id in ipairs(class) do knowsAll[#knowsAll + 1] = id end end
check(not picks((sectionsFor({ class = "MAGE", faction = "Alliance", spells = knowsAll })))["Weapon Trainer"],
    "a character with every weapon skill has no weapon trainer pick")

-- Cities and towns are the player's own faction's, and neutral ones. The other faction's are still in the
-- list a search reads, just not relevant.
local function factions(items)
    local out = {}
    for _, item in ipairs(items) do out[item.faction or "none"] = (out[item.faction or "none"] or 0) + 1 end
    return out
end
local cities = factions(section(sections, "cities").items)
check(cities.Alliance and cities.Alliance >= 3 and not cities.Horde, "an Alliance player's cities are Alliance ones: " .. tostring(cities.Alliance))
local towns = factions(section(sections, "towns").items)
check(towns.Alliance and towns.Alliance > 5 and towns.Both and towns.Both >= 3 and not towns.Horde, "and their towns are Alliance and neutral, no Horde")
local hordeFound = 0
for _, entry in ipairs(entries) do
    if entry.group == "place" and entry.faction == "Horde" and entry.relevant == false then hordeFound = hordeFound + 1 end
end
check(hordeFound >= 10, "the Horde ones are still there for searching, marked not relevant: " .. hordeFound)
local horde = sectionsFor({ class = "WARRIOR", faction = "Horde" })
local hordeCities = factions(section(horde, "cities").items)
check(hordeCities.Horde and hordeCities.Horde >= 3 and not hordeCities.Alliance, "a Horde player gets theirs")
check(section(sections, "cities").items[1].faction ~= nil, "settlement entries say whose they are")

-- Nothing is priced until asked; then every place has a time (or none if there is no way there), and cities and towns
-- are nearest first. Picks are never priced: where they go is worked out when one is chosen.
check(section(sections, "cities").items[1].eta == nil and mage["Class Trainer"].eta == nil, "unpriced to begin with")
local ctx = makeCtx({ class = "MAGE", faction = "Alliance" })
local start = { id = "YOU_sections", mapID = addon.World:GetNode("TAXI_2").mapID, x = 0.55, y = 0.55 }
local session = addon.Journey:Build(ctx, start)
check(session, "a session builds where the player stands")
addon.Sections:Price(sections, session)
local classPick = picks(sections)["Class Trainer"]
check(classPick.eta == nil and classPick.nearest == nil and classPick.where == nil, "a pick has no time or place")
check(not addon.Sections:NeedsPricing(sections, "trainers") and addon.Sections:NeedsPricing(sections, "cities"),
    "so opening the trainers needs no route search, and opening cities does")
local last = -1
for _, item in ipairs(section(sections, "cities").items) do
    if item.eta then
        check(item.eta >= last, "cities are listed nearest first")
        last = item.eta
    end
end
check(last > 0, "and at least one city is reachable")

-- Dungeons and raids: those at or below this level by the client's group finder (its suggested range, across an
-- instance's wings), else by the dungeon finder's minimum; highest first, then by name; one line each with no time.
-- Levels are the Forever beta's own, from /mzr dungeons (an Alliance character: no Ragefire Chasm in the group finder).
do
    local mins = { [1] = 17, [2] = 57, [3] = 13, [5] = 16, [7] = 18, [9] = 22, [11] = 23, [13] = 25, [15] = 24, [17] = 30,
        [19] = 34, [21] = 35, [23] = 42, [25] = 42, [27] = 45, [29] = 48, [31] = 53, [33] = 54, [35] = 54, [37] = 54,
        [39] = 55, [41] = 60, [43] = 53, [45] = 60, [47] = 60, [49] = 60, [3271] = 28, [3272] = 15, [3273] = 13, [3274] = 26 }
    GetLFGDungeonInfo = function(id)
        if mins[id] then return "Dungeon " .. id, 0, 0, mins[id], mins[id] end
    end
    -- { activity, mapID, min, max }: the group finder's dungeons, Scarlet Monastery's four wings among them.
    local activities = {
        { 796, 43, 15, 24 }, { 797, 289, 58, 60 }, { 799, 36, 17, 26 }, { 800, 33, 20, 30 }, { 801, 48, 24, 32 },
        { 802, 34, 24, 32 }, { 803, 90, 29, 38 }, { 804, 47, 29, 38 }, { 805, 189, 30, 38 }, { 806, 129, 37, 46 },
        { 807, 70, 41, 51 }, { 808, 209, 44, 54 }, { 809, 349, 46, 55 }, { 810, 109, 50, 60 }, { 811, 230, 52, 60 },
        { 812, 229, 55, 60 }, { 813, 429, 54, 60 }, { 814, 429, 56, 60 }, { 815, 429, 56, 60 }, { 816, 329, 58, 60 },
        { 827, 189, 36, 44 }, { 828, 189, 38, 46 }, { 829, 189, 33, 41 }, { 837, 229, 59, 60 }, { 1603, 329, 58, 60 },
        { 1981, 2998, 26, 33 }, { 1982, 2999, 15, 22 }, { 1983, 2959, 28, 35 }, { 1984, 3065, 13, 20 },
    }
    local byID = {}
    for _, a in ipairs(activities) do byID[a[1]] = a end
    C_LFGList = {
        GetAvailableCategories = function() return { 2, 116 } end,
        GetAvailableActivities = function(category)
            if category ~= 2 then return { 1989 } end         -- a zone: no map, ignored
            local ids = {}
            for _, a in ipairs(activities) do ids[#ids + 1] = a[1] end
            return ids
        end,
        GetActivityInfoTable = function(id)
            local a = byID[id]
            if not a then return { mapID = 0, minLevelSuggestion = 33, maxLevelSuggestion = 54 } end
            return { mapID = a[2], minLevelSuggestion = a[3], maxLevelSuggestion = a[4] }
        end,
    }
    local function names(list)
        local out = {}
        for _, item in ipairs(list) do out[#out + 1] = item.name .. "=" .. item.minLevel .. "-" .. tostring(item.maxLevel) end
        return table.concat(out, ",")
    end
    local function byNode(list)
        local out = {}
        for _, item in ipairs(list or {}) do out[item.nodeID] = item end
        return out
    end
    local at30 = sectionsFor({ class = "MAGE", faction = "Alliance", level = 30 })
    local dungeons = section(at30, "dungeons")
    check(dungeons and not section(at30, "raids"), "a level 30 has dungeons and no raids")
    local last, ok = math.huge, true
    for i, item in ipairs(dungeons.items) do
        ok = ok and item.minLevel <= 30 and item.minLevel <= last
        if i > 1 and item.minLevel == dungeons.items[i - 1].minLevel then ok = ok and dungeons.items[i - 1].name < item.name end
        last = item.minLevel
    end
    check(ok, "at or below their level, highest first, then by name: " .. names(dungeons.items))
    local seen = byNode(dungeons.items)
    check(seen.INSTANCE_SCARLET_MONASTERY and seen.INSTANCE_SCARLET_MONASTERY.minLevel == 30 and seen.INSTANCE_SCARLET_MONASTERY.maxLevel == 46,
        "an instance with several group finder activities spans them all (Scarlet Monastery 30-46)")
    check(seen.INSTANCE_STORMWIND_STOCKADE and seen.INSTANCE_STORMWIND_STOCKADE.maxLevel == 32, "the group finder's range where it has one")
    check(seen.INSTANCE_RAGEFIRE_CHASM and seen.INSTANCE_RAGEFIRE_CHASM.minLevel == 13 and seen.INSTANCE_RAGEFIRE_CHASM.maxLevel == nil,
        "else the dungeon finder's minimum, with no top (Ragefire, which this faction's group finder doesn't list)")
    check(not seen.INSTANCE_ULDAMAN and not seen.INSTANCE_RAZORFEN_DOWNS, "Uldaman (41) and Razorfen Downs (37) wait")
    check(not addon.Sections:NeedsPricing(at30, "dungeons"), "opening them needs no route search")
    if addon.Panel and addon.Panel.Subtitle then
        local function sub(item)
            local row = {}
            for k, v in pairs(item) do row[k] = v end
            row.inSection = true
            return addon.Panel.Subtitle(row), addon.Panel.EtaText(row)
        end
        local text, eta = sub(seen.INSTANCE_SCARLET_MONASTERY)
        check(text:find(addon.L["SUB_LEVEL_RANGE"]:format(30, 46), 1, true) == 1 and eta == "", "a row says its range, and no time: " .. text)
        check((sub(seen.INSTANCE_RAGEFIRE_CHASM)):find(addon.L["SUB_MIN_LEVEL"]:format(13), 1, true) == 1, "or its minimum")
    end
    local at60 = sectionsFor({ class = "MAGE", faction = "Alliance", level = 60 })
    local raids = section(at60, "raids")
    local raidSeen = byNode(raids and raids.items)
    check(raids and #raids.items == 4 and raidSeen.INSTANCE_MOLTEN_CORE and raidSeen.INSTANCE_MOLTEN_CORE.minLevel == 60
        and not raidSeen.INSTANCE_NAXXRAMAS, "at 60 the raids the client knows, by the dungeon finder: " .. names(raids and raids.items or {}))
    local maul = byNode(section(at60, "dungeons").items).INSTANCE_DIRE_MAUL
    check(maul and maul.minLevel == 54 and maul.maxLevel == 60, "Dire Maul's wings make 54-60")
    C_LFGList = nil
    local finderOnly = byNode(section(sectionsFor({ class = "MAGE", faction = "Alliance", level = 30 }), "dungeons").items)
    check(finderOnly.INSTANCE_SCARLET_MONASTERY and finderOnly.INSTANCE_SCARLET_MONASTERY.maxLevel == nil,
        "without a group finder, the dungeon finder's minimums")
    GetLFGDungeonInfo = nil
    check(not section(sectionsFor({ class = "MAGE", faction = "Alliance", level = 60 }), "dungeons"), "and with neither, no such sections")
end

-- Finding 7: the page layout is what the dataset declares, not inferred from which tables are loaded. A Forever
-- dataset that one day gains CURRENT_EXPANSION keeps its cities and towns.
do
    check(addon.PICKER_LAYOUT == "settlements", "Forever declares the settlements page")
    local realCurrent = addon.CURRENT_EXPANSION
    addon.CURRENT_EXPANSION = 12
    local withExpansion = sectionsFor({ class = "MAGE", faction = "Alliance" })
    addon.CURRENT_EXPANSION = realCurrent
    check(section(withExpansion, "cities") and section(withExpansion, "towns"),
        "Forever with a CURRENT_EXPANSION set still lists cities and towns")
end
