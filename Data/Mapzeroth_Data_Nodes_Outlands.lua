-- Mapzeroth_Data_Nodes_Outlands.lua
-- Outlands (Burning Crusade)
local _, ns = ...

ns.Nodes = ns.Nodes or {}

ns.Nodes.OUTLANDS = {
    -- Dark Portal
    DARK_PORTAL_OUTLANDS = {
        name = "The Dark Portal",
        mapID = 100,
        x = 0.892,
        y = 0.502
    },
    -- Hub
    SHATTRATH_OUTLANDS = {
        name = "Shattrath",
        mapID = 111,
        x = 0.5497,
        y = 0.4023
    },
    SHATTRATH_OUTLANDS_FLIGHT = {
        name = "Shattrath (Outland)",
        category = "city",
        mapID = 111,
        x = 0.639,
        y = 0.416
    },
    WORLDS_END_TAVERN = {
        name = "World's End Tavern",
        mapID = 111,
        x = 0.748,
        y = 0.316
    },
    BLACK_TEMPLE = {
        name = "The Black Temple",
        mapID = 104,
        x = 0.662,
        y = 0.440
    },
    HONOR_HOLD_MOLE = {
        name = "Hellfire Peninsula (Outland - Honor Hold)",
        mapID = 100,
        x = 0.561,
        y = 0.631
    },
    BLADES_EDGE_MOUNTAINS_MOLE = {
        name = "Blade's Edge Mountains (Outland - Skald)",
        mapID = 105,
        x = 0.725,
        y = 0.176
    },
    SHADOWMOON_VALLEY_OUTLANDS_MOLE = {
        name = "Shadowmoon Valley (Outland - Fel Pits)",
        mapID = 104,
        x = 0.507,
        y = 0.353
    },
    AREA_52_RIPPER = {
        name = "Area 52",
        mapID = 109,
        x = 0.32,
        y = 0.64
    },
    TOSHLEYS_STATION_TRANSPORTER = {
        name = "Toshley's Station",
        mapID = 105,
        x = 0.60,
        y = 0.68
    },
    TOSHLEYS_STATION_FLIGHT = {
        name = "Toshley's Station Flightmaster",
        mapID = 105,
        x = 0.607,
        y = 0.704
    },
    SYLVANAAR_FLIGHT = {
        name = "Sylvanaar",
        mapID = 105,
        x = 0.375,
        y = 0.616
    },
    EVERGROVE_FLIGHT = {
        name = "Evergrove",
        mapID = 105,
        x = 0.614,
        y = 0.393
    },
    OREBOR_HARBORAGE_FLIGHT = {
        name = "Orebor Harborage",
        mapID = 102,
        x = 0.407,
        y = 0.279
    },
    TELREDOR_FLIGHT = {
        name = "Telredor",
        mapID = 102,
        x = 0.677,
        y = 0.516
    },
    TEMPLE_OF_TELHAMAT_FLIGHT = {
        name = "Temple of Telhamat",
        mapID = 100,
        x = 0.251,
        y = 0.392
    },
    HONOR_HOLD_FLIGHT = {
        name = "Honor Hold",
        mapID = 100,
        x = 0.556,
        y = 0.616
    },
    SHATTER_POINT_FLIGHT = {
        name = "Shatter Point",
        mapID = 100,
        x = 0.782,
        y = 0.349
    },
    HELLFIRE_PENINSULA_FLIGHT_ALLIANCE = {
        name = "Dark Portal Flightmaster",
        mapID = 100,
        x = 0.874,
        y = 0.494
    },
    HELLFIRE_PENINSULA_FLIGHT_HORDE = {
        name = "Dark Portal Flightmaster",
        mapID = 100,
        x = 0.8747,
        y = 0.4908
    },
    SPINEBREAKER_RIDGE_FLIGHT = {
        name = "Spinebreaker Ridge",
        mapID = 100,
        x = 0.6134,
        y = 0.8140
    },
    TELAAR_FLIGHT = {
        name = "Telaar",
        mapID = 107,
        x = 0.540,
        y = 0.728
    },
    ALLERIAN_STRONGHOLD_FLIGHT = {
        name = "Allerian Stronghold",
        mapID = 108,
        x = 0.592,
        y = 0.552
    },
    WILDHAMMER_STRONGHOLD_FLIGHT = {
        name = "Wildhammer Stronghold",
        mapID = 104,
        x = 0.372,
        y = 0.556
    },
    SANCTUM_OF_THE_STARS_FLIGHT = {
        name = "Sanctum of the Stars",
        mapID = 104,
        x = 0.577,
        y = 0.579
    },
    ALTAR_OF_SHATAR_FLIGHT = {
        name = "Altar of Sha'tar",
        mapID = 104,
        x = 0.628,
        y = 0.302
    },
    COSMOWRENCH_FLIGHT = {
        name = "Cosmowrench",
        mapID = 109,
        x = 0.650,
        y = 0.656
    },
    THE_STORMSPIRE_FLIGHT = {
        name = "The Stormspire",
        mapID = 109,
        x = 0.446,
        y = 0.365
    },
    -- Hellfire Peninsula (OUTLANDS)
    THRALLMAR_FLIGHT = {
        name = "Thrallmar",
        mapID = 100,
        x = 0.5734,
        y = 0.3708
    },
    FALCON_WATCH_FLIGHT = {
        name = "Falcon Watch",
        mapID = 100,
        x = 0.2802,
        y = 0.6109
    },
    -- Zangarmarsh (OUTLANDS)
    ZABRAJIN_FLIGHT = {
        name = "Zabra'jin",
        mapID = 102,
        x = 0.3238,
        y = 0.5095
    },
    SWAMPRAT_POST_FLIGHT = {
        name = "Swamprat Post",
        mapID = 102,
        x = 0.8606,
        y = 0.5325
    },
    -- Nagrand - Outland (OUTLANDS)
    GARADAR_FLIGHT = {
        name = "Garadar",
        mapID = 107,
        x = 0.5793,
        y = 0.3584
    },
    -- Shadowmoon Valley - Outland (OUTLANDS)
    SHADOWMOON_VILLAGE_FLIGHT = {
        name = "Shadowmoon Village",
        mapID = 104,
        x = 0.3109,
        y = 0.2924
    },
    -- Blade's Edge Mountains (OUTLANDS)
    THUNDERLORD_STRONGHOLD_FLIGHT = {
        name = "Thunderlord Stronghold",
        mapID = 105,
        x = 0.5157,
        y = 0.5360
    },
    MOKNATHAL_VILLAGE_FLIGHT = {
        name = "Mok'Nathal Village",
        mapID = 105,
        x = 0.7594,
        y = 0.6561
    },
    -- Terokkar Forest (OUTLANDS)
    STONEBREAKER_HOLD_FLIGHT = {
        name = "Stonebreaker Hold",
        mapID = 108,
        x = 0.4886,
        y = 0.4319
    },
    AREA_52_FLIGHT = {
        name = "Area 52",
        mapID = 109,
        x = 0.310,
        y = 0.659
    },
    -- Dungeons
    HELLFIRE_RAMPARTS_DUNGEON = {
        name = "Hellfire Ramparts",
        category = "dungeon",
        mapID = 100,
        x = 0.480,
        y = 0.550
    },
    THE_BLOOD_FURNACE_DUNGEON = {
        name = "The Blood Furnace",
        category = "dungeon",
        mapID = 100,
        x = 0.460,
        y = 0.510
    },
    THE_SHATTERED_HALLS_DUNGEON = {
        name = "The Shattered Halls",
        category = "dungeon",
        mapID = 100,
        x = 0.480,
        y = 0.520
    },
    THE_SLAVE_PENS_DUNGEON = {
        name = "The Slave Pens",
        category = "dungeon",
        mapID = 102,
        x = 0.490,
        y = 0.350
    },
    THE_UNDERBOG_DUNGEON = {
        name = "The Underbog",
        category = "dungeon",
        mapID = 102,
        x = 0.520,
        y = 0.340
    },
    THE_STEAMVAULT_DUNGEON = {
        name = "The Steamvault",
        category = "dungeon",
        mapID = 102,
        x = 0.500,
        y = 0.400
    },
    MANATOMBS_DUNGEON = {
        name = "Mana-Tombs",
        category = "dungeon",
        mapID = 108,
        x = 0.390,
        y = 0.610
    },
    AUCHENAI_CRYPTS_DUNGEON = {
        name = "Auchenai Crypts",
        category = "dungeon",
        mapID = 108,
        x = 0.370,
        y = 0.650
    },
    SETHEKK_HALLS_DUNGEON = {
        name = "Sethekk Halls",
        category = "dungeon",
        mapID = 108,
        x = 0.420,
        y = 0.650
    },
    SHADOW_LABYRINTH_DUNGEON = {
        name = "Shadow Labyrinth",
        category = "dungeon",
        mapID = 108,
        x = 0.390,
        y = 0.710
    },
    THE_ARCATRAZ_DUNGEON = {
        name = "The Arcatraz",
        category = "dungeon",
        mapID = 109,
        x = 0.740,
        y = 0.570
    },
    THE_MECHANAR_DUNGEON = {
        name = "The Mechanar",
        category = "dungeon",
        mapID = 109,
        x = 0.700,
        y = 0.690
    },
    THE_BOTANICA_DUNGEON = {
        name = "The Botanica",
        category = "dungeon",
        mapID = 109,
        x = 0.710,
        y = 0.550
    },
    -- Raids
    GRUULS_LAIR_RAID = {
        name = "Gruul's Lair",
        category = "raid",
        mapID = 105,
        x = 0.680,
        y = 0.240
    },
    MAGTHERIDONS_LAIR_RAID = {
        name = "Magtheridon's Lair",
        category = "raid",
        mapID = 100,
        x = 0.460,
        y = 0.530
    },
    SERPENTSHRINE_CAVERN_RAID = {
        name = "Serpentshrine Cavern",
        category = "raid",
        mapID = 102,
        x = 0.520,
        y = 0.340
    },
    TEMPEST_KEEP_RAID = {
        name = "Tempest Keep",
        category = "raid",
        mapID = 109,
        x = 0.520,
        y = 0.340
    },
    BLACK_TEMPLE_RAID = {
        name = "Black Temple",
        category = "raid",
        mapID = 104,
        x = 0.710,
        y = 0.460
    }
}

