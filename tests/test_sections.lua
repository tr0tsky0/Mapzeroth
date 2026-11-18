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
-- One of Nearest's groups ("nearest_trainers", ...), or nil.
local function group(sections, id)
    local nearest = section(sections, "nearest")
    for _, child in ipairs(nearest and nearest.children or {}) do if child.id == id then return child end end
end
-- Every pick, by name: the top ones and Nearest's.
local function allPicks(sections)
    local list = {}
    for _, item in ipairs(sections.top or {}) do list[#list + 1] = item end
    local nearest = section(sections, "nearest")
    for _, child in ipairs(nearest and nearest.children or {}) do
        for _, item in ipairs(child.items) do list[#list + 1] = item end
    end
    return list
end
local function picks(sections)
    local names = {}
    for _, item in ipairs(allPicks(sections)) do names[item.name] = item end
    return names
end

-- A mage: their class trainer and a weapon master (they can learn weapons), no pets, no ley lines.
local sections, entries = sectionsFor({ class = "MAGE", faction = "Alliance" })
check(#sections == 3 and sections[1].id == "nearest" and sections[2].id == "cities" and sections[3].id == "towns",
    "Nearest, cities, towns, in that order")
check(sections[1].title == addon.L["SECTION_NEAREST"] and #sections[1].items == 0, "Nearest holds sections, not places")
do
    local ids = {}
    for _, child in ipairs(sections[1].children) do ids[#ids + 1] = child.id end
    check(table.concat(ids, ",") == "nearest_trainers,nearest_vendors,nearest_other", "Trainers, Vendors, Other: " .. table.concat(ids, ","))
    check(group(sections, "nearest_trainers").title == addon.L["SECTION_NEAREST_TRAINERS"], "each under its own heading")
end
for _, item in ipairs(sections.top) do
    check(item.group ~= "trainer", "no trainer among the top picks: " .. item.name)
end
for _, item in ipairs(group(sections, "nearest_trainers").items) do
    check(item.group == "trainer", "and only trainers under Trainers: " .. item.name)
end
local mage = picks(sections)
check(mage["Class Trainer"] and #mage["Class Trainer"].nodeIDs >= 2, "a mage has a class trainer pick over every mage trainer")
check(mage["Weapon Trainer"], "and a weapon master that teaches something they can learn")
check(not mage["Pet Trainer"] and not mage["Demon Trainer"] and not mage["Nearest Ley Line"], "no pet or demon trainers, no ley lines")
for _, item in ipairs(allPicks(sections)) do
    if not item.action and item.group ~= "leyline" and item.group ~= "convergence" then  -- those get their places when planned
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
    check(mageChoices.riding == addon.L["PICK_RIDING"] and mageChoices.inn == addon.L["PICK_INN"] and mageChoices.auction
        and mageChoices.bank and mageChoices.flight == addon.L["PICK_FLIGHT"] and not mageChoices.stable,
        "riding, innkeeper, auction house, bank, flight master; no stable master for a mage")
    local order = {}
    for _, c in ipairs(addon.Sections:PickChoices("HUNTER", "Alliance", false)) do order[#order + 1] = c.key end
    order = table.concat(order, ","):gsub("prof_[A-Z]+,", "")
    check(order:find("paste,class,pet,riding,weapon,inn,auction,bank,stable,flight", 1, true),
        "listed in the picker's order: " .. order)
    check(mageChoices.reagent == addon.L["PICK_REAGENT"] and not mageChoices.poison, "a mage: the reagent vendor, no poison vendor")
    local rogue = keys(addon.Sections:PickChoices("ROGUE", "Alliance", false))
    check(rogue.poison == addon.L["PICK_POISON"] and not rogue.reagent, "a rogue: the poison vendor instead")
    local warrior = keys(addon.Sections:PickChoices("WARRIOR", "Alliance", false))
    local hunterChoices = keys(addon.Sections:PickChoices("HUNTER", "Alliance", false))
    check(not warrior.poison and not warrior.reagent and not hunterChoices.reagent and not hunterChoices.poison,
        "warriors and hunters: neither")
    check(mageChoices.prof_ALCHEMY == "Alchemy Trainer" and mageChoices.prof_MINING, "every profession, had or not")
    check(mageChoices.leyline == addon.L["PICK_LEYLINE"] and not mageChoices.pet and not mageChoices.tomtom,
        "the ley line pick, no pet trainer for a mage, no TomTom without it")
    local hunter = keys(addon.Sections:PickChoices("HUNTER", "Horde", true))
    check(hunter.pet == addon.L["PICK_PET"] and hunter.leyline == addon.L["PICK_CONVERGENCE"] and hunter.tomtom,
        "a Horde hunter with TomTom: a pet trainer, convergences, and TomTom's waypoints")
end

-- Trainers in order: class, pet or demon, riding, weapon, then professions.
do
    local list = group((sectionsFor({ class = "HUNTER", faction = "Alliance", level = 40, spells = { addon.Professions.ALCHEMY } })), "nearest_trainers")
    local keys = {}
    for _, item in ipairs(list.items) do keys[#keys + 1] = item.key end
    check(table.concat(keys, ",") == "class,pet,riding,weapon,prof_ALCHEMY", "trainers in order: " .. table.concat(keys, ","))
end

-- A riding instructor while they have a riding rank to learn and are old enough for it (Apprentice at 40, Journeyman
-- at 60); once they know what their level allows, none.
do
    local function ridingFor(level, spells)
        return picks((sectionsFor({ class = "MAGE", faction = "Alliance", level = level, spells = spells })))["Riding Trainer"]
    end
    check(not mage["Riding Trainer"] and not ridingFor(39), "below 40, no riding trainer pick")
    local at40 = ridingFor(40)
    check(at40 and #at40.nodeIDs > 0 and at40.key == "riding", "at 40, one who can't ride has a riding trainer pick")
    check(not ridingFor(59, { 33388 }), "with Apprentice Riding, none until 60")
    check(ridingFor(60, { 33388 }), "at 60 with Apprentice Riding, back for Journeyman")
    local ranks = {}
    for _, skill in ipairs(addon.RidingSkills) do ranks[#ranks + 1] = skill.spellID end
    check(not ridingFor(60, ranks), "and one who knows every rank has none")
    for _, id in ipairs(at40.nodeIDs) do
        local npc = addon.World:GetNode(id).npcs[1]
        check(not npc.faction or npc.faction == "Alliance", "only their faction's riding instructors: " .. id)
    end
end

-- Vendors: the innkeeper. Other: the auction house, the bank, the flight master (and stable master, below). Inns,
-- banks and auction houses of their faction's settlements and neutral ones; flight masters of theirs or neutral.
do
    local function whose(node)
        local s = (node.city and addon.Cities[node.city]) or (node.town and addon.Towns[node.town])
        return s and s.faction
    end
    local vendors = group(sections, "nearest_vendors").items
    check(#vendors == 2 and vendors[1].key == "reagent" and vendors[2].name == addon.L["PICK_INN"] and vendors[2].key == "inn"
        and vendors[2].group == "inn", "a mage's Vendors: the reagent vendor, then the innkeeper")
    vendors = { vendors[2] }
    local other = group(sections, "nearest_other").items
    local keys = {}
    for _, item in ipairs(other) do keys[#keys + 1] = item.key end
    check(table.concat(keys, ",") == "auction,bank,flight", "a mage's Other: auction house, bank, flight master: " .. table.concat(keys, ","))
    for _, item in ipairs({ vendors[1], other[1], other[2] }) do
        local kinds, sawNeutral = {}, false
        for _, id in ipairs(item.nodeIDs) do
            local node = addon.World:GetNode(id)
            kinds[node.kind] = true
            local owner = whose(node)
            check(owner ~= "Horde", item.key .. ": no Horde settlement's: " .. id)
            if owner == "Both" then sawNeutral = true end
        end
        check(kinds[item.group] and next(kinds, next(kinds)) == nil, item.key .. ": only places of its kind")
        check(sawNeutral, item.key .. ": neutral ones included (Booty Bay, Gadgetzan and the like)")
    end
    local flight = other[3]
    check(flight.name == addon.L["PICK_FLIGHT"] and #flight.nodeIDs > 10, "the flight master pick, over many flight masters")
    for _, id in ipairs(flight.nodeIDs) do
        local owner = addon:GetFlightOwner(id)
        check(not owner or owner == "Alliance", "only flight masters they can talk to: " .. id)
    end
    local hordeInns = picks((sectionsFor({ class = "WARRIOR", faction = "Horde" })))[addon.L["PICK_INN"]]
    local hordeSet = {}
    for _, id in ipairs(hordeInns.nodeIDs) do hordeSet[id] = true end
    for _, id in ipairs(vendors[1].nodeIDs) do
        if whose(addon.World:GetNode(id)) == "Alliance" then check(not hordeSet[id], "a Horde player has no Alliance inn: " .. id) end
    end
end

-- Reagent vendors (Forever's, Wowhead's sellers of class reagents): the Reagent Vendor for the classes with reagents,
-- the Poison Vendor for rogues (those that sell poison ingredients), of their faction or both's; none for a warrior or
-- hunter.
do
    local function servesClass(id, class, faction)
        local node = addon.World:GetNode(id)
        if node.kind ~= "reagent" then return false end
        for _, npc in ipairs(node.npcs) do
            local sells = false
            for _, c in ipairs(npc.classes or {}) do if c == class then sells = true end end
            if sells and (not npc.faction or npc.faction == faction) then return true end
        end
        return false
    end
    for _, case in ipairs({ { "MAGE", "Alliance" }, { "PRIEST", "Horde" }, { "WARLOCK", "Alliance" }, { "DRUID", "Horde" } }) do
        local pick = picks((sectionsFor({ class = case[1], faction = case[2] })))[addon.L["PICK_REAGENT"]]
        check(pick and pick.key == "reagent" and pick.group == "reagent" and #pick.nodeIDs >= 5,
            case[1] .. " (" .. case[2] .. ") has a reagent vendor pick")
        local ok = true
        for _, id in ipairs(pick and pick.nodeIDs or {}) do ok = ok and servesClass(id, case[1], case[2]) end
        check(ok, "every one sells them their reagents and serves their faction")
    end
    local rogue = sectionsFor({ class = "ROGUE", faction = "Horde" })
    local poison = picks(rogue)[addon.L["PICK_POISON"]]
    check(poison and poison.key == "poison" and #poison.nodeIDs >= 5 and not picks(rogue)[addon.L["PICK_REAGENT"]],
        "a rogue has the poison vendor pick, not the reagent vendor")
    local vendorKeys = {}
    for _, item in ipairs(group(rogue, "nearest_vendors").items) do vendorKeys[#vendorKeys + 1] = item.key end
    check(table.concat(vendorKeys, ",") == "poison,inn", "a rogue's Vendors: poison vendor, innkeeper: " .. table.concat(vendorKeys, ","))
    local ok = true
    for _, id in ipairs(poison.nodeIDs) do ok = ok and servesClass(id, "ROGUE", "Horde") end
    check(ok, "every one sells poison ingredients and serves the Horde")    for _, class in ipairs({ "WARRIOR", "HUNTER" }) do
        local p = picks((sectionsFor({ class = class, faction = "Alliance" })))
        check(not p[addon.L["PICK_REAGENT"]] and not p[addon.L["PICK_POISON"]], class .. ": no reagent or poison vendor")
    end
end

-- Stable masters for hunters only, of their faction (or both's).
do
    local hunter = picks((sectionsFor({ class = "HUNTER", faction = "Horde" })))
    local stable = hunter[addon.L["PICK_STABLE"]]
    check(stable and stable.group == "stable" and #stable.nodeIDs > 5, "a hunter has a stable master pick")
    for _, id in ipairs(stable.nodeIDs) do
        local node = addon.World:GetNode(id)
        check(node.kind == "stable" and node.faction ~= "Alliance", "a Horde hunter's stables aren't the Alliance's: " .. id)
    end
    check(not mage[addon.L["PICK_STABLE"]], "a mage has none")
end

-- Each Nearest pick can be turned off on its own; a group left with none isn't there.
do
    addon.Options:SetShowsPick("inn", false)
    addon.Options:SetShowsPick("reagent", false)
    addon.Options:SetShowsPick("bank", false)
    local s = sectionsFor({ class = "MAGE", faction = "Alliance" })
    local p = picks(s)
    check(not group(s, "nearest_vendors") and not p[addon.L["PICK_BANK"]] and p[addon.L["PICK_AUCTION"]],
        "no innkeeper or reagent vendor (so no Vendors) and no bank, the auction house stays")
    addon.Options:SetShowsPick("inn", true)
    addon.Options:SetShowsPick("reagent", true)
    addon.Options:SetShowsPick("bank", true)
    for _, key in ipairs({ "class", "riding", "weapon", "auction", "bank", "flight" }) do addon.Options:SetShowsPick(key, false) end
    s = sectionsFor({ class = "MAGE", faction = "Alliance" })
    check(group(s, "nearest_vendors") and not group(s, "nearest_trainers") and not group(s, "nearest_other"), "only Vendors left")
    addon.Options:SetShowsPick("inn", false)
    addon.Options:SetShowsPick("reagent", false)
    check(not section(sectionsFor({ class = "MAGE", faction = "Alliance" }), "nearest"), "and with every pick off, no Nearest")
    for _, key in ipairs({ "class", "riding", "weapon", "auction", "bank", "flight", "inn", "reagent" }) do
        addon.Options:SetShowsPick(key, true)
    end
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

-- Ley lines for Skyborne (whoever can read them). The places come from SLLCM when the pick is planned
-- (LeyShare:PlacesFor), so the pick holds none; without SLLCM the row points to it instead (action "sllcm").
local skyborne = picks((sectionsFor({ class = "DRUID", faction = "Alliance", spells = { 1259705 } })))
check(skyborne["Nearest Ley Line"] and skyborne["Nearest Ley Line"].action == "sllcm", "without SLLCM a Skyborne's row points to it")
addon.Options:Set("hideSllcmHint", true)
skyborne = picks((sectionsFor({ class = "DRUID", faction = "Alliance", spells = { 1259705 } })))
check(not skyborne["Nearest Ley Line"], "and once that's dismissed, there is no row")
addon.Options:Set("hideSllcmHint", false)
SLLCM_GetNodes = function() return {} end
skyborne = picks((sectionsFor({ class = "DRUID", faction = "Alliance", spells = { 1259705 } })))
check(skyborne["Nearest Ley Line"] and not skyborne["Nearest Ley Line"].action and #skyborne["Nearest Ley Line"].nodeIDs == 0
    and skyborne["Nearest Ley Line"].group == "leyline", "with SLLCM, a Skyborne has the nearest ley line pick")

-- Horde Skyborne get the nearest elemental convergence instead, and no ley line.
local hordeSky = picks((sectionsFor({ class = "DRUID", faction = "Horde", spells = { 1259686 } })))
check(hordeSky["Nearest Elemental Convergence"] and hordeSky["Nearest Elemental Convergence"].group == "convergence", "a Horde Skyborne has the nearest convergence")
check(not hordeSky["Nearest Ley Line"] and not skyborne["Nearest Elemental Convergence"], "each faction gets only its own")
do
    local top = (sectionsFor({ class = "DRUID", faction = "Alliance", spells = { 1259705 } })).top
    check(top[1].group == "leyline", "the ley line pick is a top pick, first without a waypoint")
end
SLLCM_GetNodes = nil

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
check(not addon.Sections:NeedsPricing(sections, "nearest") and not addon.Sections:NeedsPricing(sections, "nearest_other")
    and addon.Sections:NeedsPricing(sections, "cities"), "so opening Nearest needs no route search, and opening cities does")
do
    local keys = {}
    for _, item in ipairs(group(sections, "nearest_other").items) do keys[#keys + 1] = item.key end
    check(table.concat(keys, ",") == "auction,bank,flight", "and pricing leaves the picks in their order")
end
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

-- An easter egg: Mankrik's wife is a destination, filed in no section and no pick, so only a search finds her.
do
    local all, list = sectionsFor({ class = "WARRIOR", faction = "Horde", level = 60 })
    local wife = addon.Destinations:Find(list, "MANKRIKS_WIFE")
    check(wife and wife.group == "other", "Mankrik's wife is a destination of no kind")
    local function holds(items)
        for _, item in ipairs(items or {}) do
            for _, id in ipairs(item.nodeIDs or { item.nodeID }) do
                if id == "MANKRIKS_WIFE" then return true end
            end
        end
    end
    local listed = holds(all.top) or all.index.MANKRIKS_WIFE ~= nil
    for _, s in ipairs(all) do listed = listed or holds(s.items) end
    check(not listed, "but no section or pick lists her")
    local found = addon.Search:Query(list, "mankrik", 5)
    check(found[1] and found[1].nodeID == "MANKRIKS_WIFE", "searching finds her")
    check(addon.L["NODE_MANKRIKS_WIFE"] == "Mankrik's Wife", "by her name")
end
