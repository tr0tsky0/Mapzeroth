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
        return { { nodeID = 2, name = "Stormwind, Elwynn" }, { nodeID = 6, name = "Ironforge, Dun Morogh" } }
    end
    return {}
end }
LOCALIZED_CLASS_NAMES_MALE = { MAGE = "Mage", DRUID = "Druid", WARRIOR = "Warrior", HUNTER = "Hunter",
    PALADIN = "Paladin", PRIEST = "Priest", ROGUE = "Rogue", SHAMAN = "Shaman", WARLOCK = "Warlock" }
C_Spell = { GetSpellInfo = function(id) return { name = "Profession " .. id } end }
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
