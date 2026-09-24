-- The Modern picker's main page (Sections.lua / Destinations.lua with Data/Modern/Places.lua): current
-- expansion up front, everything else under "Older content", one section per expansion. Run against the
-- Modern TOC:  python tests/harness.py --toc Mapzeroth-Rebuild_Mainline.toc modern_picker
useTestDistances()
addon.World:Build()

local maps = {
    [84] = { name = "Stormwind City", mapType = 3, parentMapID = 13 },
    [87] = { name = "Ironforge", mapType = 3, parentMapID = 13 },
    [85] = { name = "Orgrimmar", mapType = 3, parentMapID = 12 },
    [125] = { name = "Dalaran", mapType = 5, parentMapID = 113 },
    [627] = { name = "Dalaran", mapType = 5, parentMapID = 619 },
    [1161] = { name = "Boralus", mapType = 3, parentMapID = 876 },
    [2112] = { name = "Valdrakken", mapType = 3, parentMapID = 1978 },
    [2339] = { name = "Dornogal", mapType = 3, parentMapID = 2274 },
    [2393] = { name = "Silvermoon City", mapType = 3, parentMapID = 13 },
    [13] = { name = "Eastern Kingdoms", mapType = 2, parentMapID = 946 },
    [12] = { name = "Kalimdor", mapType = 2, parentMapID = 946 },
    [113] = { name = "Northrend", mapType = 2, parentMapID = 946 },
    [619] = { name = "Broken Isles", mapType = 2, parentMapID = 946 },
    [876] = { name = "Kul Tiras", mapType = 2, parentMapID = 946 },
    [1978] = { name = "Dragon Isles", mapType = 2, parentMapID = 946 },
    [2274] = { name = "Khaz Algar", mapType = 2, parentMapID = 946 },
}
C_Map = { GetMapInfo = function(id) return maps[id] end }
Enum = { UIMapType = { Continent = 2 } }
C_TaxiMap = { GetTaxiNodesForMap = function() return {} end }
EJ_GetInstanceInfo = function(id) return "Instance " .. id end
EXPANSION_NAME0, EXPANSION_NAME3, EXPANSION_NAME10 = "Classic", "Cataclysm", "The War Within"
addon.GetZoneName = function(_, mapID) return "Zone " .. tostring(mapID) end

check(addon.CURRENT_EXPANSION == 12, "the current expansion is set in Data/Modern/Places.lua")
-- The season and the expansion are edited by hand each time: pin them (and which cities are hubs) here so the test
-- does not follow them. Modern's cities are addon.Cities (Data/Modern/Settlements.lua), Forever's shape; a city whose
-- map the client can't name (none of the maps above) has no name, so it isn't offered here.
addon.CURRENT_EXPANSION = 12
addon.SEASONAL_DUNGEONS = { 1201, 945, 476 }
check(addon.Cities.stormwind and addon.World:GetNode("CITY_STORMWIND"), "Modern's cities are addon.Cities, each with a centre node")
local pinned = {
    stormwind = { 1, true }, ironforge = { 1 }, orgrimmar = { 1, true }, dalaran_northrend = { 3 },
    dalaran_broken_isles = { 7, true }, boralus = { 8 }, valdrakken = { 10, true }, dornogal = { 11, true },
    silvermoon = { 12, true },
}
for key, city in pairs(addon.Cities) do
    local pin = pinned[key]
    if pin then city.expansion, city.hub = pin[1], pin[2] end
end
addon.Instances = {
    [1299] = { 12 }, [1201] = { 10 }, [476] = { 6 }, [67] = { 4 }, [1307] = { 12, true },
    [1273] = { 11, true }, [742] = { 1, true }, [63] = { 1 },
}

local function build(faction)
    local ctx = makeCtx({ faction = faction })
    return addon.Sections:Build(addon.Destinations:Build(ctx), ctx)
end
local function find(list, id) for _, s in ipairs(list) do if s.id == id then return s end end end
local function names(section)
    local set = {}
    for _, item in ipairs(section.items) do set[item.name] = item end
    return set
end

local sections = build("Alliance")
local order = {}
for _, s in ipairs(sections) do order[#order + 1] = s.id end
check(table.concat(order, ",") == "cities,dungeons,raids,older", "cities, dungeons, raids, older content: " .. table.concat(order, ","))

local cities = names(find(sections, "cities"))
check(cities["Stormwind City"] and cities["Dornogal"] and cities["Valdrakken"] and cities["Silvermoon City"],
    "the hub cities and the current expansion's, whatever their expansion")
check(cities["Dalaran (Broken Isles)"] and not cities["Dalaran (Northrend)"], "the hub Dalaran, told apart from the other by its continent")
check(not cities["Ironforge"] and not cities["Boralus"], "other cities wait under older content")
check(not cities["Orgrimmar"], "the other faction's city isn't listed")
check(names(find(build("Horde"), "cities"))["Orgrimmar"], "but is for a Horde character")

local dungeons = names(find(sections, "dungeons"))
check(dungeons["Instance 1299"] and dungeons["Instance 1201"] and dungeons["Instance 476"],
    "this expansion's dungeons and the season's older ones")
check(not dungeons["Instance 67"] and not dungeons["Instance 1307"], "not other old dungeons, nor raids")
local raids = names(find(sections, "raids"))
check(raids["Instance 1307"] and not raids["Instance 1273"] and not raids["Instance 742"], "raids: only the current expansion's")

local older = find(sections, "older")
check(older and #older.items == 0 and #older.children > 0, "older content holds sections, not places")
local ids = {}
for _, child in ipairs(older.children) do ids[#ids + 1] = child.id end
check(ids[1] == "expansion11" and ids[#ids] == "expansion1", "newest first, down to Classic: " .. table.concat(ids, ","))
local classic = names(find(older.children, "expansion1"))
check(classic["Ironforge"] and classic["Instance 742"] and classic["Instance 63"], "an expansion's cities, dungeons and raids")
check(find(older.children, "expansion1").title == "Classic" and find(older.children, "expansion11").title == "The War Within",
    "titled with the client's expansion names: " .. find(older.children, "expansion1").title)
check(names(find(older.children, "expansion6"))["Instance 476"], "a seasonal dungeon is still filed under its own expansion too")
check(addon.Sections:Count(older) > #older.children, "the heading counts every place inside")


-- Pricing reaches the sections inside a section.
-- The seasonal dungeons are made the farthest, so only the seasonal-first rule can put them ahead.
local farthest = { INSTANCE_ALGETHAR_ACADEMY = true, INSTANCE_SKYREACH = true }
addon.Journey.Nearest = function(_, nodeIDs) return nodeIDs[1], farthest[nodeIDs[1]] and 100 or 10 end
addon.Sections:Price(sections, {})
check(classic["Ironforge"].eta == 10, "older content is priced too")

-- The season's dungeons lead the Dungeons list, then the rest; each group nearest first once priced.
local dungeonSection = find(sections, "dungeons")
local seenOther = false
for _, item in ipairs(dungeonSection.items) do
    if not item.seasonal then seenOther = true end
    check(not (seenOther and item.seasonal), "no seasonal dungeon after a non-seasonal one: " .. item.name)
end
check(dungeonSection.items[1].seasonal, "and the list starts with one")

-- Entrances that aren't INSTANCE_<id> nodes (Data/Modern/Places.lua): a faction's own is offered to that faction only,
-- and two entrances to one instance are one destination reached by whichever is cheaper.
addon.Instances = { [1023] = { 8 }, [1180] = { 8, true }, [1300] = { 12 }, [249] = { 2 } }
local function entriesFor(faction)
    local ctx = makeCtx({ faction = faction })
    return addon.Destinations:Build(ctx)
end
local function entryFor(list, instanceID)
    local found = {}
    for _, e in ipairs(list) do if e.instanceID == instanceID then found[#found + 1] = e end end
    return found
end
local siegeA, siegeH = entryFor(entriesFor("Alliance"), 1023), entryFor(entriesFor("Horde"), 1023)
check(#siegeA == 1 and siegeA[1].nodeID == "INSTANCE_SIEGE_OF_BORALUS_ALLIANCE", "an Alliance character gets the Alliance entrance only: " .. #siegeA .. " " .. tostring(siegeA[1] and siegeA[1].nodeID))
check(#siegeH == 1 and siegeH[1].nodeID == "INSTANCE_SIEGE_OF_BORALUS_HORDE", "and a Horde one gets theirs")
local nyalotha = entryFor(entriesFor("Alliance"), 1180)
check(#nyalotha == 1 and #nyalotha[1].nodeIDs == 2, "Ny'alotha's two entrances are one destination")
check(nyalotha[1].name == "Instance 1180", "named from the journal, not the entrance's own map: " .. tostring(nyalotha[1].name))
local terrace = entryFor(entriesFor("Alliance"), 1300)
check(#terrace == 1 and terrace[1].nodeID == "INSTANCE_MAGISTERS_TERRACE" and terrace[1].expansion == 12, "the Midnight Magisters' Terrace is filed under Midnight")
check(#entryFor(entriesFor("Alliance"), 249) == 1, "and the old one under its own expansion")
check(addon.World:GetNode("INSTANCE_STRATHOLME_MAIN_GATE") and addon.World:GetNode("INSTANCE_STRATHOLME_SERVICE_ENTRANCE") and addon.World:GetNode("INSTANCE_THE_TEMPLE_OF_ATALHAKKAR")
    and addon.World:GetNode("INSTANCE_THE_EYE") and addon.World:GetNode("INSTANCE_DIRE_MAUL_CAPITAL_GARDENS") and addon.World:GetNode("INSTANCE_SPOREFALL") and addon.World:GetNode("INSTANCE_THE_TIDEBOUND_GROTTO"), "the hand-added dungeon and raid entrances exist")

-- A city the client can't name isn't offered; an instance with no expansion isn't filed.
check(not cities["Frostwall"], "no name, no city")
addon.Instances = {}
check(not find(build("Alliance"), "dungeons"), "with no instance data there are no dungeon or raid sections")

-- Finding 6 (suffix fallback): Modern's docks and portals are transport, not "other".
do
    local ctx = makeCtx({ faction = "Alliance" })
    local byID = {}
    for _, entry in ipairs(addon.Destinations:Build(ctx)) do byID[entry.nodeID] = entry end
    check(byID.BORALUS_DOCK == nil or byID.BORALUS_DOCK.group == "transport",
        "Boralus's dock is transport: " .. tostring(byID.BORALUS_DOCK and byID.BORALUS_DOCK.group))
    local transport = 0
    for _, entry in pairs(byID) do if entry.group == "transport" then transport = transport + 1 end end
    check(transport > 0, "Modern has transport destinations: " .. transport)
end
