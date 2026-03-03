-- Mapzeroth_Data_Nodes_Northrend.lua
-- Northrend (Wrath of the Lich King)
local _, ns = ...

ns.Nodes = ns.Nodes or {}

ns.Nodes.NORTHREND = {
    DALARAN_NORTHREND = {
        name = "Dalaran (Northrend)",
        mapID = 125,
        x = 0.5592,
        y = 0.4678
    },
    DALARAN_NORTHREND_STORMWIND_PORTAL = {
        name = "Portal to Stormwind",
        mapID = 125,
        faction = "ALLIANCE",
        x = 0.3998,
        y = 0.6265
    },
    DALARAN_NORTHREND_ORGRIMMAR_PORTAL = {
        name = "Portal to Orgrimmar",
        mapID = 125,
        faction = "HORDE",
        x = 0.5757,
        y = 0.1942
    },
    ARGENT_TOURNAMENT_GROUNDS = {
        name = "Argent Tournament Grounds",
        mapID = 118,
        x = 0.694,
        y = 0.226
    },
    RUBY_DRAGONSHRINE_MOLE = {
        name = "Ruby Dragonshrine (Dragonblight)",
        faction = "ALLIANCE",
        mapID = 115,
        x = 0.453,
        y = 0.499
    },
    ARGENT_TOURNAMENT_GROUNDS_MOLE = {
        name = "Argent Tournament Grounds (Icecrown)",
        faction = "ALLIANCE",
        mapID = 118,
        x = 0.770,
        y = 0.186
    },
    BOREAN_TUNDRA_WORMHOLE = {
        name = "Borean Tundra (Wormhole)",
        mapID = 114,
        x = 0.53,
        y = 0.15
    },
    HOWLING_FJORD_WORMHOLE = {
        name = "Howling Fjord (Wormhole)",
        mapID = 117,
        x = 0.58,
        y = 0.47
    },
    STORM_PEAKS_WORMHOLE = {
        name = "The Storm Peaks (Wormhole)",
        mapID = 120,
        x = 0.43,
        y = 0.25
    },
    SHOLAZAR_BASIN_WORMHOLE = {
        name = "Sholazar Basin (Wormhole)",
        mapID = 119,
        x = 0.492,
        y = 0.396
    },
    VALIANCE_KEEP_FLIGHT = {
        name = "Valiance Keep",
        faction = "ALLIANCE",
        mapID = 114,
        x = 0.604,
        y = 0.669
    },
    VALIANCE_KEEP_DOCK = {
        name = "Valiance Keep Dock",
        mapID = 114,
        x = 0.5946,
        y = 0.6914
    },
    FIZZCRANK_AIRSTRIP_FLIGHT = {
        name = "Fizzcrank Airstrip",
        faction = "ALLIANCE",
        mapID = 114,
        x = 0.563,
        y = 0.208
    },
    TRANSITUS_SHIELD_FLIGHT = {
        name = "Transitus Shield",
        mapID = 114,
        x = 0.325,
        y = 0.344
    },
    AMBER_LEDGE_FLIGHT = {
        name = "Amber Ledge",
        mapID = 114,
        x = 0.449,
        y = 0.337
    },
    UNUPE_FLIGHT = {
        name = "Unu'pe",
        mapID = 114,
        x = 0.775,
        y = 0.494
    },
    VALIANCE_LANDING_CAMP_FLIGHT = {
        name = "Valiance Landing Camp",
        faction = "ALLIANCE",
        mapID = 123,
        x = 0.720,
        y = 0.311
    },
    WARSONG_CAMP_FLIGHT = {
        name = "Warsong Camp",
        faction = "HORDE",
        mapID = 123,
        x = 0.2143,
        y = 0.3436
    },
    STARS_REST_FLIGHT = {
        name = "Stars' Rest",
        faction = "ALLIANCE",
        mapID = 115,
        x = 0.298,
        y = 0.549
    },
    MOAKI_FLIGHT = {
        name = "Moa'ki",
        mapID = 115,
        x = 0.474,
        y = 0.737
    },
    SUNREAVERS_COMMAND_FLIGHT = {
        name = "Sunreaver's Command",
        faction = "HORDE",
        mapID = 127,
        x = 0.7759,
        y = 0.4813
    },
    WYRMREST_TEMPLE_FLIGHT = {
        name = "Wyrmrest Temple",
        mapID = 115,
        x = 0.601,
        y = 0.504
    },
    FORDRAGON_HOLD_FLIGHT = {
        name = "Fordragon Hold",
        faction = "ALLIANCE",
        mapID = 115,
        x = 0.383,
        y = 0.260
    },
    WINTERGARDE_KEEP_FLIGHT = {
        name = "Wintergarde Keep",
        faction = "ALLIANCE",
        mapID = 115,
        x = 0.768,
        y = 0.499
    },
    AMBERPINE_LODGE_FLIGHT = {
        name = "Amberpine Lodge",
        faction = "ALLIANCE",
        mapID = 116,
        x = 0.313,
        y = 0.609
    },
    WESTFALL_BRIGADE_FLIGHT = {
        name = "Westfall Brigade",
        faction = "ALLIANCE",
        mapID = 116,
        x = 0.592,
        y = 0.268
    },
    WESTGUARD_KEEP_FLIGHT = {
        name = "Westguard Keep",
        faction = "ALLIANCE",
        mapID = 117,
        x = 0.321,
        y = 0.446
    },
    KAMAGUA_FLIGHT = {
        name = "Kamagua",
        mapID = 117,
        x = 0.250,
        y = 0.597
    },
    FORT_WILDERVAR_FLIGHT = {
        name = "Fort Wildervar",
        faction = "ALLIANCE",
        mapID = 117,
        x = 0.608,
        y = 0.170
    },
    VALGARDE_PORT_FLIGHT = {
        name = "Valgarde Port",
        faction = "ALLIANCE",
        mapID = 117,
        x = 0.593,
        y = 0.632
    },
    VALGARDE_PORT_DOCK = {
        name = "Valgarde Port Dock",
        mapID = 117,
        x = 0.6110,
        y = 0.6243
    },
    FROSTHOLD_FLIGHT = {
        name = "Frosthold",
        faction = "ALLIANCE",
        mapID = 120,
        x = 0.280,
        y = 0.744
    },
    BOULDERCRAGS_REFUGE_FLIGHT = {
        name = "Bouldercrag's Refuge",
        mapID = 120,
        x = 0.305,
        y = 0.358
    },
    ULDUAR_FLIGHT = {
        name = "Ulduar",
        mapID = 120,
        x = 0.460,
        y = 0.241
    },
    K3_FLIGHT = {
        name = "K3",
        mapID = 120,
        x = 0.420,
        y = 0.845
    },
    GROMARSH_CRASHSITE_FLIGHT = {
        name = "Grom'arsh Crash-Site",
        faction = "HORDE",
        mapID = 120,
        x = 0.3685,
        y = 0.4990
    },
    CAMP_TUNKALO_FLIGHT = {
        name = "Camp Tunka'lo",
        faction = "HORDE",
        mapID = 120,
        x = 0.6840,
        y = 0.4990
    },
    DUN_NIFFELEM_FLIGHT = {
        name = "Dun Niffelem",
        mapID = 120,
        x = 0.625,
        y = 0.613
    },
    WINDRUNNERS_OVERLOOK_FLIGHT = {
        name = "Windrunner's Overlook",
        faction = "ALLIANCE",
        mapID = 127,
        x = 0.726,
        y = 0.809
    },
    DALARAN_NORTHREND_FLIGHT = {
        name = "Dalaran (Northrend) Flightmaster",
        category = "city",
        mapID = 127,
        x = 0.366,
        y = 0.377
    },
    NESINGWARY_BASE_CAMP_FLIGHT = {
        name = "Nesingwary Base Camp",
        mapID = 119,
        x = 0.251,
        y = 0.580
    },
    RIVERS_HEART_FLIGHT = {
        name = "River's Heart",
        mapID = 119,
        x = 0.499,
        y = 0.611
    },
    EBON_WATCH_FLIGHT = {
        name = "Ebon Watch",
        mapID = 121,
        x = 0.153,
        y = 0.744
    },
    LIGHTS_BREACH_FLIGHT = {
        name = "Light's Breach",
        mapID = 121,
        x = 0.336,
        y = 0.742
    },
    THE_ARGENT_STAND_FLIGHT = {
        name = "The Argent Stand",
        mapID = 121,
        x = 0.423,
        y = 0.682
    },
    ZIMTORGA_FLIGHT = {
        name = "Zim'Torga",
        mapID = 121,
        x = 0.610,
        y = 0.576
    },
    GUNDRAK_FLIGHT = {
        name = "Gundrak",
        mapID = 121,
        x = 0.703,
        y = 0.229
    },
    DEATHS_RISE_FLIGHT = {
        name = "Death's Rise",
        mapID = 118,
        x = 0.192,
        y = 0.477
    },
    THE_SHADOW_VAULT_FLIGHT = {
        name = "The Shadow Vault",
        mapID = 118,
        x = 0.437,
        y = 0.270
    },
    ARGENT_TOURNAMENT_GROUNDS_FLIGHT = {
        name = "Argent Tournament Grounds",
        mapID = 118,
        x = 0.724,
        y = 0.225
    },
    CRUSADERS_PINNACLE_FLIGHT = {
        name = "Crusaders' Pinnacle",
        mapID = 118,
        x = 0.792,
        y = 0.721
    },
    THE_ARGENT_VANGUARD_FLIGHT = {
        name = "The Argent Vanguard",
        mapID = 118,
        x = 0.879,
        y = 0.757
    },
    VALGARDE_BOAT = {
        name = "Valgarde Port",
        faction = "ALLIANCE",
        mapID = 117,
        x = 0.593,
        y = 0.632
    },

    VENGEANCE_LANDING_ZEPPELIN = {
        name = "Vengeance Hold (Zeppelin)",
        faction = "HORDE",
        mapID = 117,
        x = 0.7770,
        y = 0.3029
    },
    -- Howling Fjord (NORTHREND)
    VENGEANCE_LANDING_FLIGHT = {
        name = "Vengeance Landing",
        faction = "HORDE",
        mapID = 117,
        x = 0.7864,
        y = 0.2959
    },
    NEW_AGAMAND_FLIGHT = {
        name = "New Agamand",
        faction = "HORDE",
        mapID = 117,
        x = 0.5074,
        y = 0.6967
    },
    APOTHECARY_CAMP_FLIGHT = {
        name = "Apothecary Camp",
        faction = "HORDE",
        mapID = 117,
        x = 0.2579,
        y = 0.2500
    },
    CAMP_WINTERHOOF_FLIGHT = {
        name = "Camp Winterhoof",
        faction = "HORDE",
        mapID = 117,
        x = 0.4992,
        y = 0.1034
    },
    -- Grizzly Hills (NORTHREND)
    CAMP_ONEQWAH_FLIGHT = {
        name = "Camp Oneqwah",
        faction = "HORDE",
        mapID = 116,
        x = 0.6628,
        y = 0.4661
    },
    CONQUEST_HOLD_FLIGHT = {
        name = "Conquest Hold",
        faction = "HORDE",
        mapID = 116,
        x = 0.2343,
        y = 0.6498
    },
    GRIZZLY_HILLS_DRUID = {
        name = "Ursoc's Den, Grizzly Hills",
        mapID = 116,
        x = 0.5043,
        y = 0.2975
    },
    -- Dragonblight (NORTHREND)
    VENOMSPITE_FLIGHT = {
        name = "Venomspite",
        faction = "HORDE",
        mapID = 115,
        x = 0.7547,
        y = 0.6208
    },
    AGMARS_HAMMER_FLIGHT = {
        name = "Agmar's Hammer",
        faction = "HORDE",
        mapID = 115,
        x = 0.3815,
        y = 0.4636
    },
    KORKRON_VANGUARD_FLIGHT = {
        name = "Kor'kron Vanguard",
        faction = "HORDE",
        mapID = 115,
        x = 0.4368,
        y = 0.1723
    },
    -- Borean Tundra (NORTHREND)
    WARSONG_HOLD_FLIGHT = {
        name = "Warsong Hold",
        faction = "HORDE",
        mapID = 114,
        x = 0.3921,
        y = 0.5138
    },
    TAUNKALE_VILLAGE_FLIGHT = {
        name = "Taunka'le Village",
        faction = "HORDE",
        mapID = 114,
        x = 0.7735,
        y = 0.3902
    },
    BORGOROK_OUTPOST_FLIGHT = {
        name = "Bor'gorok Outpost",
        faction = "HORDE",
        mapID = 114,
        x = 0.4980,
        y = 0.1271
    },
    WARSONG_HOLD_ZEPPELIN = {
        name = "Warsong Hold (Zeppelin)",
        faction = "HORDE",
        mapID = 114,
        x = 0.4145,
        y = 0.5272
    },
    -- Dungeons
    UTGARDE_KEEP_DUNGEON = {
        name = "Utgarde Keep",
        category = "dungeon",
        mapID = 117,
        x = 0.580,
        y = 0.500
    },
    UTGARDE_PINNACLE_DUNGEON = {
        name = "Utgarde Pinnacle",
        category = "dungeon",
        mapID = 117,
        x = 0.570,
        y = 0.480
    },
    THE_NEXUS_DUNGEON = {
        name = "The Nexus",
        category = "dungeon",
        mapID = 114,
        x = 0.270,
        y = 0.260
    },
    THE_OCULUS_DUNGEON = {
        name = "The Oculus",
        category = "dungeon",
        mapID = 114,
        x = 0.280,
        y = 0.250
    },
    AZJOLNERUB_DUNGEON = {
        name = "Azjol-Nerub",
        category = "dungeon",
        mapID = 115,
        x = 0.260,
        y = 0.490
    },
    AHNKAHET_THE_OLD_KINGDOM_DUNGEON = {
        name = "Ahn'kahet: The Old Kingdom",
        category = "dungeon",
        mapID = 115,
        x = 0.280,
        y = 0.520
    },
    DRAKTHARON_KEEP_DUNGEON = {
        name = "Drak'Tharon Keep",
        category = "dungeon",
        mapID = 121,
        x = 0.280,
        y = 0.870
    },
    THE_VIOLET_HOLD_DUNGEON = {
        name = "The Violet Hold",
        category = "dungeon",
        mapID = 125,
        x = 0.660,
        y = 0.680
    },
    GUNDRAK_DUNGEON = {
        name = "Gundrak",
        category = "dungeon",
        mapID = 121,
        x = 0.810,
        y = 0.290
    },
    HALLS_OF_STONE_DUNGEON = {
        name = "Halls of Stone",
        category = "dungeon",
        mapID = 120, -- The Storm Peaks
        x = 0.400,
        y = 0.270
    },
    HALLS_OF_LIGHTNING_DUNGEON = {
        name = "Halls of Lightning",
        category = "dungeon",
        mapID = 120, -- The Storm Peaks
        x = 0.420,
        y = 0.210
    },
    TRIAL_OF_THE_CHAMPION_DUNGEON = {
        name = "Trial of the Champion",
        category = "dungeon",
        mapID = 118, -- Icecrown
        x = 0.740,
        y = 0.200
    },
    THE_FORGE_OF_SOULS_DUNGEON = {
        name = "The Forge of Souls",
        category = "dungeon",
        mapID = 118, -- Icecrown
        x = 0.520,
        y = 0.890
    },
    PIT_OF_SARON_DUNGEON = {
        name = "Pit of Saron",
        category = "dungeon",
        mapID = 118, -- Icecrown
        x = 0.520,
        y = 0.890
    },
    HALLS_OF_REFLECTION_DUNGEON = {
        name = "Halls of Reflection",
        category = "dungeon",
        mapID = 118, -- Icecrown
        x = 0.520,
        y = 0.890
    },
    -- Raids
    NAXXRAMAS_RAID = {
        name = "Naxxramas",
        category = "raid",
        mapID = 115, -- Dragonblight
        x = 0.870,
        y = 0.510
    },
    THE_EYE_OF_ETERNITY_RAID = {
        name = "The Eye of Eternity",
        category = "raid",
        mapID = 114, -- Borean Tundra
        x = 0.280,
        y = 0.290
    },
    THE_OBSIDIAN_SANCTUM_RAID = {
        name = "The Obsidian Sanctum",
        category = "raid",
        mapID = 115, -- Dragonblight
        x = 0.600,
        y = 0.540
    },
    VAULT_OF_ARCHAVON_RAID = {
        name = "Vault of Archavon",
        category = "raid",
        mapID = 123, -- Wintergrasp
        x = 0.500,
        y = 0.160
    },
    ULDUAR_RAID = {
        name = "Ulduar",
        category = "raid",
        mapID = 120, -- The Storm Peaks
        x = 0.410,
        y = 0.180
    },
    TRIAL_OF_THE_CRUSADER_RAID = {
        name = "Trial of the Crusader",
        category = "raid",
        mapID = 118, -- Icecrown
        x = 0.750,
        y = 0.210
    },
    ICECROWN_CITADEL_RAID = {
        name = "Icecrown Citadel",
        category = "raid",
        mapID = 118, -- Icecrown
        x = 0.530,
        y = 0.860
    },
    THE_RUBY_SANCTUM_RAID = {
        name = "The Ruby Sanctum",
        category = "raid",
        mapID = 115, -- Dragonblight
        x = 0.610,
        y = 0.530
    }
}

