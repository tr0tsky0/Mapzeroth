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

-- The cities are in Settlements.lua, generated from tools/modern_manual.py's CITIES (Forever's addon.Cities shape).
