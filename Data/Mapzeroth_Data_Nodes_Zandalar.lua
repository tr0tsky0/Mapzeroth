-- Mapzeroth_Data_Nodes_Zandalar.lua
-- Zandalar (Battle for Azeroth)
local _, ns = ...

ns.Nodes = ns.Nodes or {}

ns.Nodes.ZANDALAR = {
    DAZARALOR_PORTAL_ROOM = {
        name = "Portal Room",
        category = "city",
        faction = "HORDE",
        mapID = 1165,
        x = 0.6572,
        y = 0.7433
    },
    ZULDAZAR_MOLE = {
        name = "Xibala Incursion",
        faction = "ALLIANCE",
        mapID = 862,
        x = 0.382,
        y = 0.724
    },
    DAZARALOR_PET = {
        name = "Pet Shop",
        faction = "HORDE",
        mapID = 1165,
        x = 0.5633,
        y = 0.3097
    },
    DAZARALOR_DOCK = {
        name = "Dazar'alor Dock",
        faction = "HORDE",
        mapID = 862,
        x = 0.5769,
        y = 0.6480
    },
    NAZMIR_MOLE = {
        name = "Zalamar Invasion",
        faction = "ALLIANCE",
        mapID = 863,
        x = 0.344,
        y = 0.452
    },
    DEADWOOD_COVE_FLIGHT = {
        name = "Deadwood Cove",
        faction = "ALLIANCE",
        mapID = 864,
        x = 0.394,
        y = 0.836
    },
    VULTURES_NEST_FLIGHT = {
        name = "Vulture's Nest",
        faction = "ALLIANCE",
        mapID = 864,
        x = 0.533,
        y = 0.378
    },
    SHATTERSTONE_HARBOR_DOCK = {
        name = "Shatterstone Harbor",
        faction = "ALLIANCE",
        mapID = 864,
        x = 0.3665,
        y = 0.3414
    },
    TORTAKA_REFUGE_FLIGHT = {
        name = "Tortaka Refuge",
        mapID = 864,
        x = 0.6169,
        y = 0.2139
    },
    SANCTUARY_OF_THE_DEVOTED_FLIGHT = {
        name = "Sanctuary of the Devoted",
        mapID = 864,
        x = 0.2783,
        y = 0.5032
    },
    GRIMWATTS_CRASH_FLIGHT = {
        name = "Grimwatt's Crash",
        faction = "ALLIANCE",
        mapID = 863,
        x = 0.339,
        y = 0.632
    },
    REDFIELDS_WATCH_FLIGHT = {
        name = "Redfield's Watch",
        faction = "ALLIANCE",
        mapID = 863,
        x = 0.507,
        y = 0.207
    },
    FORT_VICTORY_FLIGHT = {
        name = "Fort Victory",
        faction = "ALLIANCE",
        mapID = 863,
        x = 0.618,
        y = 0.410
    },
    FORT_VICTORY_DOCK = {
        name = "Fort Victory Dock",
        faction = "ALLIANCE",
        mapID = 863,
        x = 0.6201,
        y = 0.4014
    },
    MUGAMBA_OVERLOOK_FLIGHT = {
        name = "Mugamba Overlook",
        faction = "ALLIANCE",
        mapID = 862,
        x = 0.446,
        y = 0.272
    },
    VEILED_GROTTO_FLIGHT = {
        name = "Veiled Grotto",
        faction = "ALLIANCE",
        mapID = 862,
        x = 0.446,
        y = 0.363
    },
    XIBALA_FLIGHT_ALLIANCE = {
        name = "Xibala",
        faction = "ALLIANCE",
        mapID = 862,
        x = 0.409,
        y = 0.714
    },
    XIBALA_DOCK = {
        name = "Xibala Dock",
        faction = "Alliance",
        mapID = 862,
        x = 0.4028,
        y = 0.7113
    },
    XIBALA_FLIGHT_HORDE = {
        name = "Xibala",
        faction = "HORDE",
        mapID = 862,
        x = 0.4451,
        y = 0.7222
    },
    KAJACOAST_ROCKET = {
        name = "Kaja'Coast Rocket",
        mapID = 862,
        x = 0.2234,
        y = 0.5415
    },
    MISTVINE_LEDGE_FLIGHT = {
        name = "Mistvine Ledge",
        faction = "ALLIANCE",
        mapID = 862,
        x = 0.642,
        y = 0.475
    },
    CASTAWAY_ENCAMPMENT_FLIGHT = {
        name = "Castaway Encampment",
        faction = "ALLIANCE",
        mapID = 862,
        x = 0.776,
        y = 0.547
    },
    VERDANT_HOLLOW_FLIGHT = {
        name = "Verdant Hollow",
        faction = "ALLIANCE",
        mapID = 862,
        x = 0.554,
        y = 0.246
    },
    SEEKERS_OUTPOST_FLIGHT = {
        name = "Seeker's Outpost",
        mapID = 862,
        x = 0.7042,
        y = 0.6495
    },
    ATALGRAL_FLIGHT = {
        name = "Atal'Gral",
        mapID = 862,
        x = 0.7994,
        y = 0.4119
    },
    SCALETRADER_POST_FLIGHT = {
        name = "Scaletrader Post",
        mapID = 862,
        x = 0.7042,
        y = 0.2948
    },
    -- Vol'dun (ZANDALAR)
    VORRIKS_SANCTUM_FLIGHT = {
        name = "Vorrik's Sanctum",
        faction = "HORDE",
        mapID = 864,
        x = 0.4686,
        y = 0.3506
    },
    VULPERA_HIDEAWAY_FLIGHT = {
        name = "Vulpera Hideaway",
        faction = "HORDE",
        mapID = 864,
        x = 0.5663,
        y = 0.4919
    },
    TEMPLE_OF_AKUNDA_FLIGHT = {
        name = "Temple of Akunda",
        faction = "HORDE",
        mapID = 864,
        x = 0.5357,
        y = 0.8927
    },
    SCORCHED_SANDS_OUTPOST_FLIGHT = {
        name = "Scorched Sands Outpost",
        faction = "HORDE",
        mapID = 864,
        x = 0.4368,
        y = 0.7557
    },
    -- Zuldazar (ZANDALAR)
    ISLE_OF_FANGS_FLIGHT = {
        name = "Isle of Fangs",
        faction = "HORDE",
        mapID = 862,
        x = 0.5428,
        y = 0.8733
    },
    TUSK_ISLE_FLIGHT = {
        name = "Tusk Isle",
        faction = "HORDE",
        mapID = 862,
        x = 0.5875,
        y = 0.7779
    },
    PORT_OF_ZANDALAR_FLIGHT = {
        name = "Port of Zandalar",
        faction = "HORDE",
        mapID = 1165,
        x = 0.5192,
        y = 0.8970
    },
    THE_GREAT_SEAL_FLIGHT = {
        name = "The Great Seal",
        faction = "HORDE",
        mapID = 1165,
        x = 0.5145,
        y = 0.4096
    },
    THE_SLIVER_FLIGHT = {
        name = "The Sliver",
        faction = "HORDE",
        mapID = 1165,
        x = 0.5286,
        y = 0.1907
    },
    THE_MUGAMBALA_FLIGHT = {
        name = "The Mugambala",
        faction = "HORDE",
        mapID = 862,
        x = 0.5310,
        y = 0.5643
    },
    WARPORT_RASTARI_FLIGHT = {
        name = "Warport Rastari",
        faction = "HORDE",
        mapID = 862,
        x = 0.4804,
        y = 0.5996
    },
    ATALDAZAR_FLIGHT = {
        name = "Atal'Dazar",
        faction = "HORDE",
        mapID = 862,
        x = 0.4557,
        y = 0.3595
    },
    GARDEN_OF_THE_LOA_FLIGHT = {
        name = "Garden of the Loa",
        faction = "HORDE",
        mapID = 862,
        x = 0.4898,
        y = 0.2588
    },
    ZEBAHARI_FLIGHT = {
        name = "Zeb'ahari",
        faction = "HORDE",
        mapID = 862,
        x = 0.7688,
        y = 0.1529
    },
    WARBEAST_KRAAL_FLIGHT = {
        name = "Warbeast Kraal",
        faction = "HORDE",
        mapID = 862,
        x = 0.6675,
        y = 0.4266
    },
    NESINGWARYS_GAMELAND_FLIGHT = {
        name = "Nesingwary's Gameland",
        mapID = 862,
        x = 0.6628,
        y = 0.1760
    },
    -- NAZMIR (ZANDALAR)
    ZOBAL_RUINS_FLIGHT = {
        name = "Zo'bal Ruins",
        faction = "HORDE",
        mapID = 863,
        x = 0.4003,
        y = 0.4301
    },
    ZULJAN_FLIGHT = {
        name = "Zul'jan",
        faction = "HORDE",
        mapID = 863,
        x = 0.3874,
        y = 0.7797
    },
    GLOOM_HOLLOW_FLIGHT = {
        name = "Gloom Hollow",
        faction = "HORDE",
        mapID = 863,
        x = 0.6675,
        y = 0.4319
    },
    FORLORN_RUINS_FLIGHT = {
        name = "Forlorn Ruins",
        faction = "HORDE",
        mapID = 863,
        x = 0.8147,
        y = 0.2606
    },
    -- Dungeons
    ATALDAZAR_DUNGEON = {
        name = "Atal'Dazar",
        category = "dungeon",
        mapID = 862, -- Zuldazar
        x = 0.440,
        y = 0.390
    },
    KINGS_REST_DUNGEON = {
        name = "Kings' Rest",
        category = "dungeon",
        mapID = 862, -- Zuldazar
        x = 0.380,
        y = 0.390
    },
    TEMPLE_OF_SETHRALISS_DUNGEON = {
        name = "Temple of Sethraliss",
        category = "dungeon",
        mapID = 864, -- Vol'dun
        x = 0.520,
        y = 0.250
    },
    THE_UNDERROT_DUNGEON = {
        name = "The Underrot",
        category = "dungeon",
        mapID = 863, -- Nazmir
        x = 0.520,
        y = 0.660
    },
    THE_MOTHERLODE_DUNGEON_ALLIANCE = {
        name = "The MOTHERLODE!!",
        category = "dungeon",
        mapID = 862, -- Zuldazar
        x = 0.400,
        y = 0.720
    },
    THE_MOTHERLODE_DUNGEON_HORDE = {
        name = "The MOTHERLODE!!",
        category = "dungeon",
        mapID = 862, -- Zuldazar
        x = 0.560,
        y = 0.600
    },
    -- Raids
    ULDIR_RAID = {
        name = "Uldir",
        category = "raid",
        mapID = 863, -- Nazmir
        x = 0.540,
        y = 0.530
    },
    BATTLE_OF_DAZARALOR_RAID_HORDE = {
        name = "Battle of Dazar'alor",
        category = "raid",
        faction = "HORDE",
        mapID = 1165, -- Zuldazar
        x = 0.390,
        y = 0.020
    }
}

