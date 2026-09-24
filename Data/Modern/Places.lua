-- Places.lua (Modern) -- HAND-MAINTAINED. What the picker's main page shows for Modern, and how the rest is filed
-- under "Older content" (see Sections.lua). Expansions are numbered by major version: Classic 1, The Burning
-- Crusade 2, ... The War Within 11, Midnight 12.

local addonName, addon = ...

-- The picker's main page is laid out by expansion (Sections.lua), not as Forever's cities and towns.
addon.PICKER_LAYOUT = "expansions"

-- Change when a new expansion launches: the main page shows this expansion's cities, dungeons and raids.
addon.CURRENT_EXPANSION = 12

-- Change each Mythic+ season: the older dungeons in the season's pool, listed on the main page with the
-- current expansion's own (by journal instance id; the name is only a note).
addon.SEASONAL_DUNGEONS = {
    1322,   -- Altar of Fangs
    1304,   -- Murder Row
    1313,   -- Voidscar Arena
    1311,   -- Den of Nalorakk
    1309,   -- The Blinding Vale
    1202,   -- Ruby Life Pools
    1041,   -- King's Rest
    1030    -- Temple of Sethraliss
}

-- Dungeon and raid nodes that never got a journal-instance id in their node id (INSTANCE_<id> carries it),
-- so which instance they are can't be read from it: [nodeID] = journalInstanceID, or { journalInstanceID,
-- faction = "Alliance" } for an entrance only one faction has. Two entrances to one instance become one destination.
addon.InstanceNodeAliases = {
    NEXUS_POINT_XENAS_DUNGEON = 1316,
    DAWN_OF_THE_INFINITES_DUNGEON = 1209,      -- two wings in Group Finder, one entrance
    BARADIN_HOLD = 75,
    LOST_CITY_OF_THE_TOLVIR = 69,
    INSTANCE_249 = 1300,                       -- the Midnight Magisters' Terrace (Quel'Thalas), not the old one
    MAGISTERS_TERRACE_BC_DUNGEON = 249,        -- the Burning Crusade one, Isle of Quel'Danas
    BATTLE_OF_DAZARALOR_RAID_ALLIANCE = { 1176, faction = "Alliance" },
    BATTLE_OF_DAZARALOR_RAID_HORDE = { 1176, faction = "Horde" },
    SIEGE_OF_BORALUS_DUNGEON_ALLIANCE = { 1023, faction = "Alliance" },
    SIEGE_OF_BORALUS_DUNGEON_HORDE = { 1023, faction = "Horde" },
    THE_MOTHERLODE_DUNGEON_ALLIANCE = { 1012, faction = "Alliance" },
    THE_MOTHERLODE_DUNGEON_HORDE = { 1012, faction = "Horde" },
    NYALOTHA_THE_WAKING_CITY_RAID_ULDUM = 1180,       -- two entrances that swap each week: one destination,
    NYALOTHA_THE_WAKING_CITY_RAID_PANDARIA = 1180,    -- whichever is nearer
}

-- The cities. `maps` are the uiMapIDs that make up the city (arriving on any node in them counts as arriving in
-- the city, and the client names it); a city none of whose maps hold a node is left out. `hub` cities are
-- also listed on the main page whatever their expansion, for the places people travel to every day.
addon.CityPlaces = {
    { maps = { 84 },   expansion = 1,  faction = "Alliance", hub = true },   -- Stormwind City
    { maps = { 87 },   expansion = 1,  faction = "Alliance" },               -- Ironforge
    { maps = { 89 },   expansion = 1,  faction = "Alliance" },               -- Darnassus
    { maps = { 85 },   expansion = 1,  faction = "Horde",    hub = true },   -- Orgrimmar
    { maps = { 88 },   expansion = 1,  faction = "Horde" },                  -- Thunder Bluff
    { maps = { 90 },   expansion = 1,  faction = "Horde" },                  -- Undercity
    { maps = { 103 },  expansion = 2,  faction = "Alliance" },               -- The Exodar
    { maps = { 110 },  expansion = 2,  faction = "Horde" },                  -- Silvermoon City (BC)
    { maps = { 111 },  expansion = 2,  faction = "Both" },                   -- Shattrath City
    { maps = { 125 },  expansion = 3,  faction = "Both",     hub = true },   -- Dalaran (Northrend)
    { maps = { 393 },  expansion = 5,  faction = "Alliance" },               -- Shrine of Seven Stars
    { maps = { 390 },  expansion = 5,  faction = "Horde" },                  -- Shrine of Two Moons
    { maps = { 582 },  expansion = 6,  faction = "Alliance" },               -- Lunarfall
    { maps = { 590 },  expansion = 6,  faction = "Horde" },                  -- Frostwall
    { maps = { 622 },  expansion = 6,  faction = "Alliance" },               -- Stormshield
    { maps = { 624 },  expansion = 6,  faction = "Horde" },                  -- Warspear
    { maps = { 627 },  expansion = 7,  faction = "Both",     hub = true },   -- Dalaran (Broken Isles)
    { maps = { 1161 }, expansion = 8,  faction = "Alliance" },               -- Boralus
    { maps = { 1165 }, expansion = 8,  faction = "Horde" },                  -- Dazar'alor
    { maps = { 1670, 1671 }, expansion = 9, faction = "Both", hub = true },  -- Oribos
    { maps = { 2112 }, expansion = 10, faction = "Both",     hub = true },   -- Valdrakken
    { maps = { 2339 }, expansion = 11, faction = "Both",     hub = true },   -- Dornogal
    { maps = { 2346 }, expansion = 11, faction = "Both" },                   -- Undermine
    { maps = { 2393 }, expansion = 12, faction = "Both",     hub = true },  -- Silvermoon City
}
