addon.World:Build()

-- Client stand-ins for the names we need (see test_names.lua).
local maps = {
    [1429] = { name = "Elwynn Forest", mapType = 3, parentMapID = 1415 },
    [1453] = { name = "Stormwind City", mapType = 3, parentMapID = 1415 },
    [1426] = { name = "Dun Morogh", mapType = 3, parentMapID = 1415 },
    [1455] = { name = "Ironforge", mapType = 3, parentMapID = 1415 },
    [1431] = { name = "Duskwood", mapType = 3, parentMapID = 1415 },
    [1415] = { name = "Eastern Kingdoms", mapType = 2, parentMapID = 947 },
    [947] = { name = "Azeroth", mapType = 1, parentMapID = 0 },
}
C_Map = {
    GetMapInfo = function(id) return maps[id] end,
    GetAreaInfo = function(id) return ({ [87] = "Goldshire", [279] = "Dalaran" })[id] end,
}
Enum = { UIMapType = { Continent = 2 } }
C_TaxiMap = { GetTaxiNodesForMap = function(id)
    if id == 1415 then
        return { { nodeID = 2, name = "Stormwind, Elwynn" }, { nodeID = 6, name = "Ironforge, Dun Morogh" },
                 { nodeID = 11, name = "Undercity, Tirisfal" } }
    end
    return {}
end }
LOCALIZED_CLASS_NAMES_MALE = { MAGE = "Mage", DRUID = "Druid", WARRIOR = "Warrior", HUNTER = "Hunter",
    PALADIN = "Paladin", PRIEST = "Priest", ROGUE = "Rogue", SHAMAN = "Shaman", WARLOCK = "Warlock" }
local weaponNames = { [196] = "One-Handed Axes", [197] = "Two-Handed Axes", [198] = "One-Handed Maces",
    [199] = "Two-Handed Maces", [200] = "Polearms", [201] = "One-Handed Swords", [202] = "Two-Handed Swords",
    [227] = "Staves", [264] = "Bows", [266] = "Guns", [1180] = "Daggers", [2567] = "Thrown", [5011] = "Crossbows",
    [15590] = "Fist Weapons" }
C_Spell = { GetSpellInfo = function(id) return { name = weaponNames[id] or ("Profession " .. id) } end }
addon:ClearNodeNameCache()

local ctx = makeCtx({ class = "MAGE" })
local entries = addon.Destinations:Build(ctx)
check(#entries > 100, "a real list: " .. #entries)

local function find(nodeID, group) return addon.Destinations:Find(entries, nodeID, group) end

-- Flight masters are named by the client and grouped as flights.
local sw = find("TAXI_2", "flight")
check(sw and sw.name == "Stormwind, Elwynn" and sw.group == "flight", "Stormwind's flight master")
check(sw.zone == "Stormwind City", "with its map's name as the zone: " .. tostring(sw.zone))

-- Border crossings are plumbing, not destinations; nodes with no name yet are left out.
for _, e in ipairs(entries) do
    check(not e.nodeID:find("^BORDER_"), "no border crossing is offered: " .. e.nodeID)
    check(e.name ~= e.nodeID, "nothing is listed by its raw id: " .. e.nodeID)
end

-- Cities and towns are places of their own, so a city and its flight master no longer share
-- a node. A city is entered through its entrances (both sides of each gate), so it routes to
-- whichever is nearest; a town routes to its centre.
local function place(list, name)
    for _, e in ipairs(list) do if e.group == "place" and e.name == name then return e end end
end
local stormwindCity = place(entries, "Stormwind")
check(stormwindCity and stormwindCity.kind == "city", "Stormwind is offered as a city")
check(#stormwindCity.nodeIDs == 2 and stormwindCity.nodeIDs[1]:find("^ENTRANCE_") and stormwindCity.nodeIDs[2]:find("^ENTRANCE_"),
    "entered through its two gate points, inside and outside the city")
check(find("TAXI_2", "place") == nil, "and no place borrows the flight master's node")
local goldshire = place(entries, "Goldshire")
check(goldshire and goldshire.kind == "town" and goldshire.nodeIDs[1] == "TOWN_GOLDSHIRE", "a town routes to its centre")

-- Entrances and centres are how a place is arrived at, never destinations of their own.
for _, e in ipairs(entries) do
    local node = addon.World:GetNode(e.nodeID)
    check(node.kind ~= "settlement" and node.kind ~= "entrance" or e.group == "place",
        "only a city or town entry may point at an entrance or centre: " .. e.nodeID)
end

-- A city with no entrances captured falls back to its centre.
local pois = addon.Nodes.Pois
local without = {}
for _, n in ipairs(pois) do
    if not (n.kind == "entrance" and n.city == "stormwind") then without[#without + 1] = n end
end
addon.Nodes.Pois = without
addon.World:Build()
local fallback = place(addon.Destinations:Build(ctx), "Stormwind")
check(fallback and fallback.nodeIDs[1] == "CITY_STORMWIND" and #fallback.nodeIDs == 1, "with no entrances, Stormwind uses its centre")
addon.Nodes.Pois = pois
addon.World:Build()

-- A city with entrances routes to them instead: Dalaran has one.
local dalaran
for _, e in ipairs(entries) do if e.group == "place" and e.name == "Dalaran" then dalaran = e end end
check(dalaran and dalaran.kind == "city" and dalaran.nodeIDs[1]:find("^ENTRANCE_"), "Dalaran is entered by its entrance: " .. tostring(dalaran and dalaran.nodeIDs[1]))

-- Relevance rides along: other classes' trainers are in the list but not relevant.
local mageTrainer, druidTrainer
for _, e in ipairs(entries) do
    local node = addon.World:GetNode(e.nodeID)
    if node and node.kind == "trainer" and node.city == "stormwind" then
        if node.trainer == "MAGE" then mageTrainer = e end
        if node.trainer == "DRUID" then druidTrainer = e end
    end
end
check(mageTrainer and mageTrainer.relevant, "a mage's own trainer is relevant")
check(druidTrainer and not druidTrainer.relevant, "a druid trainer isn't, for a mage")

-- Searching the list works end to end.
local hits = addon.Search:Query(entries, "stormwind", 5)
check(#hits > 0 and hits[1].score == 3, "searching finds Stormwind places first")

-- A weapon master says which weapons it teaches, and a search for a weapon finds it.
local stormwindWeapons = find("TRAINER_WEAPON_11867", "trainer")
check(stormwindWeapons and stormwindWeapons.details and #stormwindWeapons.details == 6, "Stormwind's weapon master lists what it teaches")
local taught = {}
for _, d in ipairs(stormwindWeapons.details) do taught[d.text] = d end
check(taught["One-Handed Swords"] and taught["Two-Handed Swords"] and taught["Staves"] and taught["Daggers"] and not taught["Bows"],
    "in the client's names: swords, staves and daggers but no bows")
check(taught["Staves"].alias and taught["Staves"].alias:find("staff"), "with the word a player types for a staff")
check(find("TAXI_2", "flight").details == nil, "other places have no details")

local function names(results)
    local out = {}
    for _, r in ipairs(results) do out[r.nodeID] = r end
    return out
end
local sword = names(addon.Search:Query(entries, "sword", 200))
check(sword["TRAINER_WEAPON_11867"], "\"sword\" finds Stormwind's weapon master")
check(sword["TRAINER_WEAPON_11867"].detailHit == "One-Handed Swords, Two-Handed Swords", "and says which swords: " .. tostring(sword["TRAINER_WEAPON_11867"].detailHit))
local staff = names(addon.Search:Query(entries, "staff", 200))
local withDetails, agree = 0, 0
for _, entry in ipairs(entries) do
    if entry.details then
        withDetails = withDetails + 1
        local teachesStaves = false
        for _, d in ipairs(entry.details) do if d.text == "Staves" then teachesStaves = true end end
        if (staff[entry.nodeID] ~= nil) == teachesStaves then agree = agree + 1 end
    end
end
check(withDetails >= 2 and agree == withDetails, "\"staff\" finds exactly the weapon masters that teach Staves: " .. agree .. " of " .. withDetails)
check(staff["TRAINER_WEAPON_11867"] and staff["TRAINER_WEAPON_11867"].detailHit == "Staves", "Stormwind's is one, and it names the client's word for it")
check(names(addon.Search:Query(entries, "dagger", 200))["TRAINER_WEAPON_11867"], "\"dagger\" finds a dagger trainer")
local plain = names(addon.Search:Query(entries, "weapon trainer", 200))
check(plain["TRAINER_WEAPON_11867"] and plain["TRAINER_WEAPON_11867"].detailHit == nil, "a name match doesn't claim a weapon")
check(names(addon.Search:Query(entries, "sword stormwind", 200))["TRAINER_WEAPON_11867"], "a weapon and a place can be searched together")

-- A flight master of the other faction can't be spoken to: it isn't a destination.
check(find("TAXI_11", "flight") == nil, "an Alliance player is not offered Undercity's flight master")
local horde = addon.Destinations:Build(makeCtx({ class = "MAGE", faction = "Horde" }))
check(addon.Destinations:Find(horde, "TAXI_11", "flight") ~= nil, "but a Horde player is")
check(addon.Destinations:Find(horde, "TAXI_2", "flight") == nil, "and not Stormwind's")
check(addon:GetFlightOwner("TAXI_2") == "Alliance" and addon:GetFlightOwner("TAXI_11") == "Horde" and addon:GetFlightOwner("TAXI_80") == nil,
    "flight points know their faction (Ratchet, used by both, has none)")
