-- Mapzeroth_Data_Nodes_Kalimdor.lua
-- Kalimdor, Teldrassil, Exodar, Razorwind Shores
local _, ns = ...

ns.Nodes = ns.Nodes or {}

ns.Nodes.KALIMDOR_OVERWORLD = {
    -- Alliance Cities & Zones
    DARKSHORE = {
        name = "Darkshore",
        faction = "ALLIANCE",
        mapID = 62,
        x = 0.5362,
        y = 0.1877
    },
    FERALAS = {
        name = "Feathermoon Stronghold",
        faction = "ALLIANCE",
        mapID = 69,
        x = 0.4514,
        y = 0.4173
    },
    FERALAS_DRUID = {
        name = "Dream Bough",
        mapID = 69,
        x = 0.5120,
        y = 0.1103
    },
    THERAMORE = {
        name = "Theramore",
        faction = "ALLIANCE",
        mapID = 70,
        x = 0.660,
        y = 0.490
    },
    THERAMORE_DOCK = {
        name = "Theramore Dock",
        mapID = 70,
        x = 0.7123,
        y = 0.5590
    },
    WESTERN_EARTHSHRINE_OG = {
        name = "Western Earthshrine",
        faction = "HORDE",
        mapID = 85,
        x = 0.5007,
        y = 0.3779
    },
    ORGRIMMAR_GROMGOL_ZEP = {
        name = "Zeppelin to Grom'gol",
        mapID = 85,
        x = 0.5236,
        y = 0.5334
    },
    ORGRIMMAR_UNDERCITY_PORTAL = {
        name = "Portal to Undercity",
        mapID = 85,
        x = 0.5081,
        y = 0.5547
    },
    ORGRIMMAR_THUNDER_BLUFF_ZEP = {
        name = "Zeppelin to Thunder Bluff",
        mapID = 85,
        x = 0.4310,
        y = 0.6487
    },
    ORGRIMMAR_WARSONG_ZEP = {
        name = "Zeppelin to Warsong Hold",
        mapID = 85,
        x = 0.4469,
        y = 0.6241
    },
    ORGRIMMAR_WAKING_SHORES_ZEP = {
        name = "Zeppelin to the Waking Shores",
        mapID = 1,
        x = 0.5599,
        y = 0.1310
    },
    BRAWLGAR_ARENA = {
        name = "Brawl'gar Arena",
        mapID = 85,
        x = 0.7055,
        y = 0.3117
    },
    ORGRIMMAR_EMBASSY = {
        name = "Embassy",
        mapID = 85,
        x = 0.4024,
        y = 0.7812
    },
    ORGRIMMAR_THUNDER_TOTEM_PORTAL = {
        name = "Portal to Thunder Totem",
        mapID = 85,
        x = 0.3813,
        y = 0.7536
    },
    ORGRIMMAR_NIGHTHOLD_PORTAL = {
        name = "Portal to The Nighthold",
        mapID = 85,
        x = 0.3813,
        y = 0.7536
    },
    ORGRIMMAR_PORTAL_ROOM_ENTRANCE = {
        name = "Entrance to Portal Room",
        mapID = 85,
        x = 0.5334,
        y = 0.9047
    },
    -- Orgrimmar Portal Room
    ORGRIMMAR_PORTAL_ROOM_STAIRS = {
        name = "Portal Room (Stairs)",
        faction = "HORDE",
        interior = true,
        mapID = 85,
        x = 0.5484,
        y = 0.9017
    },
    ORGRIMMAR_PORTAL_ROOM_UPPER = {
        name = "Portal Room (Upper)",
        faction = "HORDE",
        interior = true,
        mapID = 85,
        x = 0.5710,
        y = 0.8981
    },
    ORGRIMMAR_VALDRAKKEN_PORTAL = {
        name = "Portal to Valdrakken",
        faction = "HORDE",
        interior = true,
        mapID = 85,
        x = 0.5712,
        y = 0.8754
    },
    ORGRIMMAR_ORIBOS_PORTAL = {
        name = "Portal to Oribos",
        faction = "HORDE",
        interior = true,
        mapID = 85,
        x = 0.5822,
        y = 0.8803
    },
    ORGRIMMAR_RAZORWIND_SHORES_PORTAL = {
        name = "Portal to Razorwind Shores",
        faction = "HORDE",
        interior = true,
        mapID = 85,
        x = 0.5877,
        y = 0.8953
    },
    ORGRIMMAR_DORNOGAL_PORTAL = {
        name = "Portal to Dornogal",
        faction = "HORDE",
        interior = true,
        mapID = 85,
        x = 0.5847,
        y = 0.9121
    },
    ORGRIMMAR_HONEYDEW_VILLAGE_PORTAL = {
        name = "Portal to Honeydew Village",
        faction = "HORDE",
        interior = true,
        mapID = 85,
        x = 0.5745,
        y = 0.9193
    },
    ORGRIMMAR_SILVERMOON_PORTAL = {
        name = "Portal to Silvermoon",
        faction = "HORDE",
        interior = true,
        mapID = 85,
        x = 0.5745,
        y = 0.9193
    },
    ORGRIMMAR_DALARAN_NORTHREND_PORTAL = {
        name = "Portal to Northrend Dalaran",
        faction = "HORDE",
        interior = true,
        mapID = 85,
        x = 0.5634,
        y = 0.9148
    },
    ORGRIMMAR_PORTAL_ROOM_LOWER = {
        name = "Portal Room (Lower)",
        faction = "HORDE",
        interior = true,
        mapID = 85,
        x = 0.5625,
        y = 0.9031
    },
    ORGRIMMAR_AZSUNA_PORTAL = {
        name = "Portal to Azsuna",
        faction = "HORDE",
        interior = true,
        mapID = 85,
        x = 0.5716,
        y = 0.8836
    },
    ORGRIMMAR_DAZARALOR_PORTAL = {
        name = "Portal to Dazar'alor",
        faction = "HORDE",
        interior = true,
        mapID = 85,
        x = 0.5768,
        y = 0.8987
    },
    ORGRIMMAR_SHATTRATH_OUTLANDS_PORTAL = {
        name = "Portal to Shattrath (Outlands)",
        faction = "HORDE",
        interior = true,
        mapID = 85,
        x = 0.5739,
        y = 0.9143
    },
    ORGRIMMAR_CAVERNS_OF_TIME_PORTAL = {
        name = "Portal to Caverns of Time",
        faction = "HORDE",
        interior = true,
        mapID = 85,
        x = 0.5640,
        y = 0.9228
    },
    ORGRIMMAR_WARSPEAR_PORTAL = {
        name = "Portal to Warspear",
        faction = "HORDE",
        interior = true,
        mapID = 85,
        x = 0.5529,
        y = 0.9178
    },
    ORGRIMMAR_BC_SILVERMOON_PORTAL = {
        name = "Portal to Burning Crusade Silvermoon",
        faction = "HORDE",
        interior = true,
        mapID = 85,
        x = 0.5478,
        y = 0.9032
    },
    ORGRIMMAR_DARK_PORTAL_BL_NPC = {
        name = "Thrallmar Mage",
        faction = "HORDE",
        interior = true,
        mapID = 85,
        x = 0.5704,
        y = 0.9062
    },
    THUNDER_BLUFF = {
        name = "Entrance",
        category = "city",
        faction = "HORDE",
        mapID = 88,
        x = 0.2221,
        y = 0.1687
    },
    THUNDER_BLUFF_ZEP = {
        name = "Zeppelin Dock",
        mapID = 88,
        x = 0.1879,
        y = 0.2564
    },
    DARKMOON_FAIRE_ENTRANCE_MULGORE = {
        name = "Darkmoon Faire Entrance",
        mapID = 7,
        x = 0.3680,
        y = 0.3582
    },
    BLOODHOOF_VILLAGE_FLIGHT = {
        name = "Bloodhoof Village",
        faction = "HORDE",
        mapID = 7,
        x = 0.4768,
        y = 0.5872
    },
    SENJIN_VILLAGE_FLIGHT = {
        name = "Sen'jin Village",
        faction = "HORDE",
        mapID = 1,
        x = 0.5475,
        y = 0.7338
    },
    ECHO_ISLES_DOCK = {
        name = "Dock",
        mapID = 1,
        x = 0.7182,
        y = 0.7885
    },
    RAZOR_HILL_FLIGHT = {
        name = "Razor Hill",
        faction = "HORDE",
        mapID = 1,
        x = 0.5263,
        y = 0.4266
    },
    FIRE_PLUME_RIDGE_MOLE = {
        name = "Un'Goro Crater (Kalimdor - Fire Plume Ridge)",
        faction = "ALLIANCE",
        mapID = 78,
        x = 0.529,
        y = 0.559
    },
    THE_GREAT_DIVIDE_MOLE = {
        name = "Southern Barrens (Kalimdor - The Great Divide)",
        faction = "ALLIANCE",
        mapID = 199,
        x = 0.391,
        y = 0.093
    },
    THRONE_OF_FLAME_MOLE = {
        name = "Mount Hyjal (Kalimdor - Throne of Flame)",
        faction = "ALLIANCE",
        mapID = 198,
        x = 0.572,
        y = 0.771
    },
    GADGETZAN_TRANSPORTER = {
        name = "Gadgetzan",
        mapID = 71,
        x = 0.52,
        y = 0.27
    },
    EVERLOOK_RIPPER = {
        name = "Everlook",
        mapID = 83,
        x = 0.61,
        y = 0.39
    },
    -- Neutral Zones
    MOONGLADE = {
        name = "Nighthaven",
        mapID = 80,
        x = 0.567,
        y = 0.355
    },
    MOONGLADE_DRUID = {
        name = "Stormrage Barrow",
        mapID = 80,
        x = 0.6759,
        y = 0.6019
    },
    SILITHUS = {
        name = "Magni's Camp",
        mapID = 81,
        x = 0.415,
        y = 0.449
    },
    CAVERNS_OF_TIME = {
        name = "Caverns of Time",
        mapID = 74,
        x = 0.546,
        y = 0.283
    },
    CAVERNS_OF_TIME_STORMWIND_PORTAL = {
        name = "Portal to Stormwind",
        mapID = 74,
        faction = "ALLIANCE",
        x = 0.5883,
        y = 0.2689
    },
    CAVERNS_OF_TIME_ORGRIMMAR_PORTAL = {
        name = "Portal to Orgrimmar",
        mapID = 74,
        x = 0.5818,
        y = 0.2680
    },
    ULDUM = {
        name = "Ramkahen",
        mapID = 1527,
        x = 0.549,
        y = 0.342
    },
    MOUNT_HYJAL = {
        name = "Nordrassil",
        mapID = 198,
        x = 0.635,
        y = 0.234
    },
    MOUNT_HYJAL_DRUID = {
        name = "Nordrassil",
        mapID = 198,
        x = 0.5929,
        y = 0.2583
    },
    MOONGLADE_FLIGHT_ALLIANCE = {
        name = "Lake Elune'ara",
        faction = "ALLIANCE",
        mapID = 80,
        x = 0.476,
        y = 0.669
    },
    MOONGLADE_FLIGHT_HORDE = {
        name = "Lake Elune'ara",
        faction = "HORDE",
        mapID = 80,
        x = 0.3179,
        y = 0.6639
    },
    NIGHTHAVEN_FLIGHT_ALLIANCE = {
        name = "Nighthaven Flightmaster",
        faction = "ALLIANCE",
        mapID = 80,
        x = 0.440,
        y = 0.452
    },
    NIGHTHAVEN_FLIGHT_HORDE = {
        name = "Nighthaven Flightmaster",
        faction = "HORDE",
        mapID = 80,
        x = 0.4403,
        y = 0.4538
    },
    EVERLOOK_FLIGHT_ALLIANCE = {
        name = "Everlook",
        faction = "ALLIANCE",
        mapID = 83,
        x = 0.608,
        y = 0.496
    },
    EVERLOOK_FLIGHT_HORDE = {
        name = "Everlook",
        faction = "HORDE",
        mapID = 83,
        x = 0.5828,
        y = 0.4884
    },
    TALONBRANCH_GLADE_FLIGHT = {
        name = "Talonbranch Glade",
        faction = "ALLIANCE",
        mapID = 77,
        x = 0.606,
        y = 0.254
    },
    WHISPERWIND_GROVE_FLIGHT = {
        name = "Whisperwind Grove",
        mapID = 77,
        x = 0.433,
        y = 0.311
    },
    WILDHEART_POINT_FLIGHT = {
        name = "Wildheart Point",
        mapID = 77,
        x = 0.441,
        y = 0.620
    },
    EMERALD_SANCTUARY_FLIGHT = {
        name = "Emerald Sanctuary",
        mapID = 77,
        x = 0.514,
        y = 0.806
    },
    LORDANEL_FLIGHT = {
        name = "Lor'danel",
        faction = "ALLIANCE",
        mapID = 62,
        x = 0.515,
        y = 0.193
    },
    GROVE_OF_THE_ANCIENTS_FLIGHT = {
        name = "Grove of the Ancients",
        faction = "ALLIANCE",
        mapID = 62,
        x = 0.436,
        y = 0.754
    },
    BLACKFATHOM_CAMP_FLIGHT = {
        name = "Blackfathom Camp",
        faction = "ALLIANCE",
        mapID = 63,
        x = 0.178,
        y = 0.205
    },
    ASTRANAAR_FLIGHT = {
        name = "Astranaar",
        faction = "ALLIANCE",
        mapID = 63,
        x = 0.344,
        y = 0.480
    },
    STARDUST_SPIRE_FLIGHT = {
        name = "Stardust Spire",
        faction = "ALLIANCE",
        mapID = 63,
        x = 0.360,
        y = 0.706
    },
    FOREST_SONG_FLIGHT = {
        name = "Forest Song",
        faction = "ALLIANCE",
        mapID = 63,
        x = 0.845,
        y = 0.449
    },
    THALDARAH_OVERLOOK_FLIGHT = {
        name = "Thal'darah Overlook",
        faction = "ALLIANCE",
        mapID = 65,
        x = 0.383,
        y = 0.320
    },
    MIRKFALLON_POST_FLIGHT = {
        name = "Mirkfallon Post",
        faction = "ALLIANCE",
        mapID = 65,
        x = 0.493,
        y = 0.525
    },
    WINDSHEAR_HOLD_FLIGHT = {
        name = "Windshear Hold",
        faction = "ALLIANCE",
        mapID = 65,
        x = 0.586,
        y = 0.544
    },
    FARWATCHERS_GLEN_FLIGHT = {
        name = "Farwatcher's Glen",
        faction = "ALLIANCE",
        mapID = 65,
        x = 0.336,
        y = 0.608
    },
    NORTHWATCH_EXPEDITION_BASE_CAMP_FLIGHT = {
        name = "Northwatch Expedition Base Camp",
        faction = "ALLIANCE",
        mapID = 65,
        x = 0.708,
        y = 0.806
    },
    HONORS_STAND_FLIGHT = {
        name = "Honor's Stand",
        faction = "ALLIANCE",
        mapID = 199,
        x = 0.390,
        y = 0.097
    },
    NORTHWATCH_HOLD_FLIGHT = {
        name = "Northwatch Hold",
        faction = "ALLIANCE",
        mapID = 199,
        x = 0.662,
        y = 0.471
    },
    FORT_TRIUMPH_FLIGHT = {
        name = "Fort Triumph",
        faction = "ALLIANCE",
        mapID = 199,
        x = 0.488,
        y = 0.680
    },
    NIJELS_POINT_FLIGHT = {
        name = "Nijel's Point",
        faction = "ALLIANCE",
        mapID = 66,
        x = 0.651,
        y = 0.101
    },
    ETHEL_RETHOR_FLIGHT = {
        name = "Ethel Rethor",
        mapID = 66,
        x = 0.398,
        y = 0.282
    },
    THUNKS_ABODE_FLIGHT = {
        name = "Thunk's Abode",
        mapID = 66,
        x = 0.710,
        y = 0.325
    },
    KARNUMS_GLADE_FLIGHT = {
        name = "Karnum's Glade",
        mapID = 66,
        x = 0.569,
        y = 0.532
    },
    THARGADS_CAMP_FLIGHT = {
        name = "Thargad's Camp",
        faction = "ALLIANCE",
        mapID = 66,
        x = 0.371,
        y = 0.718
    },
    THERAMORE_FLIGHT = {
        name = "Theramore",
        faction = "ALLIANCE",
        mapID = 70,
        x = 0.674,
        y = 0.504
    },
    MUDSPROCKET_FLIGHT = {
        name = "Mudsprocket",
        mapID = 70,
        x = 0.420,
        y = 0.742
    },
    DREAMERS_REST_FLIGHT = {
        name = "Dreamer's Rest",
        faction = "ALLIANCE",
        mapID = 69,
        x = 0.509,
        y = 0.175
    },
    FEATHERMOON_FLIGHT = {
        name = "Feathermoon",
        faction = "ALLIANCE",
        mapID = 69,
        x = 0.464,
        y = 0.463
    },
    TOWER_OF_ESTULAN_FLIGHT = {
        name = "Tower of Estulan",
        faction = "ALLIANCE",
        mapID = 69,
        x = 0.566,
        y = 0.539
    },
    SHADEBOUGH_FLIGHT = {
        name = "Shadebough",
        faction = "ALLIANCE",
        mapID = 69,
        x = 0.768,
        y = 0.566
    },
    GADGETZAN_FLIGHT_ALLIANCE = {
        name = "Gadgetzan",
        faction = "ALLIANCE",
        mapID = 71,
        x = 0.511,
        y = 0.294
    },
    GADGETZAN_FLIGHT_HORDE = {
        name = "Gadgetzan",
        faction = "HORDE",
        mapID = 71,
        x = 0.5180,
        y = 0.2729
    },
    DAWNRISE_EXPEDITION_FLIGHT = {
        name = "Dawnrise Expedition",
        faction = "HORDE",
        mapID = 71,
        x = 0.3285,
        y = 0.7727
    },
    BOOTLEGGER_OUTPOST_FLIGHT = {
        name = "Bootlegger Outpost",
        mapID = 71,
        x = 0.565,
        y = 0.590
    },
    GUNSTANS_DIG_FLIGHT = {
        name = "Gunstan's Dig",
        faction = "ALLIANCE",
        mapID = 71,
        x = 0.400,
        y = 0.774
    },
    NORDRASSIL_FLIGHT = {
        name = "Nordrassil",
        mapID = 198,
        x = 0.622,
        y = 0.213
    },
    SHRINE_OF_AVIANA_FLIGHT = {
        name = "Shrine of Aviana",
        mapID = 198,
        x = 0.410,
        y = 0.427
    },
    GROVE_OF_AESSINA_FLIGHT = {
        name = "Grove of Aessina",
        mapID = 198,
        x = 0.204,
        y = 0.380
    },
    SANCTUARY_OF_MALORNE_FLIGHT = {
        name = "Sanctuary of Malorne",
        mapID = 198,
        x = 0.276,
        y = 0.632
    },
    GATES_OF_SOTHANN_FLIGHT = {
        name = "Gates of Sothann",
        mapID = 198,
        x = 0.726,
        y = 0.762
    },
    RATCHET_FLIGHT = {
        name = "Ratchet",
        mapID = 10,
        x = 0.681,
        y = 0.718
    },
    RATCHET_DOCK = {
        name = "Ratchet Dock",
        mapID = 10,
        x = 0.6993,
        y = 0.7338
    },
    MOSSY_PILE_FLIGHT = {
        name = "Mossy Pile",
        mapID = 78,
        x = 0.442,
        y = 0.410
    },
    MARSHALS_STAND_FLIGHT = {
        name = "Marshal's Stand",
        mapID = 78,
        x = 0.556,
        y = 0.630
    },
    RAMKAHEN_FLIGHT = {
        name = "Ramkahen Flightmaster",
        mapID = 249,
        x = 0.561,
        y = 0.334
    },

    IRONTREE_CLEARING_FLIGHT = {
        name = "Irontree Clearing",
        faction = "HORDE",
        mapID = 77,
        x = 0.5616,
        y = 0.0910
    },
    -- Southern Barrens (KALIMDOR_OVERWORLD)
    VENDETTA_POINT_FLIGHT = {
        name = "Vendetta Point",
        faction = "HORDE",
        mapID = 199,
        x = 0.4333,
        y = 0.4760
    },
    HUNTERS_HILL_FLIGHT = {
        name = "Hunter's Hill",
        faction = "HORDE",
        mapID = 199,
        x = 0.4062,
        y = 0.2023
    },
    DESOLATION_HOLD_FLIGHT = {
        name = "Desolation Hold",
        faction = "HORDE",
        mapID = 199,
        x = 0.4286,
        y = 0.7038
    },
    -- Thunder Bluff (KALIMDOR_OVERWORLD)
    THUNDER_BLUFF_FLIGHT = {
        name = "Flightmaster",
        faction = "HORDE",
        mapID = 88,
        x = 0.4627,
        y = 0.4961
    },
    -- Orgrimmar (KALIMDOR_OVERWORLD)
    ORGRIMMAR_FLIGHT = {
        name = "Flightmaster",
        category = "city",
        faction = "HORDE",
        mapID = 85,
        x = 0.5204,
        y = 0.6144
    },
    -- Northern Barrens (KALIMDOR_OVERWORLD)
    THE_CROSSROADS_FLIGHT = {
        name = "The Crossroads",
        faction = "HORDE",
        mapID = 10,
        x = 0.4898,
        y = 0.5950
    },
    NOZZLEPOTS_OUTPOST_FLIGHT = {
        name = "Nozzlepot's Outpost",
        faction = "HORDE",
        mapID = 10,
        x = 0.6252,
        y = 0.1730
    },
    -- Stonetalon Mountains (KALIMDOR_OVERWORLD)
    SUN_ROCK_RETREAT_FLIGHT = {
        name = "Sun Rock Retreat",
        faction = "HORDE",
        mapID = 65,
        x = 0.5016,
        y = 0.6120
    },
    THE_SLUDGEWERKS_FLIGHT = {
        name = "The Sludgewerks",
        faction = "HORDE",
        mapID = 65,
        x = 0.5451,
        y = 0.4001
    },
    CLIFFWALKER_POST_FLIGHT = {
        name = "Cliffwalker Post",
        faction = "HORDE",
        mapID = 65,
        x = 0.4604,
        y = 0.3224
    },
    KROMGAR_FORTRESS_FLIGHT = {
        name = "Krom'gar Fortress",
        faction = "HORDE",
        mapID = 65,
        x = 0.6758,
        y = 0.6261
    },
    MALAKAJIN_FLIGHT = {
        name = "Malaka'jin",
        faction = "HORDE",
        mapID = 65,
        x = 0.7040,
        y = 0.8945
    },
    -- Thousand Needles (KALIMDOR_OVERWORLD)
    WESTREACH_SUMMIT_FLIGHT = {
        name = "Westreach Summit",
        faction = "HORDE",
        mapID = 64,
        x = 0.1096,
        y = 0.1158
    },
    FIZZLE_POZZIKS_SPEEDBARGE_FLIGHT = {
        name = "Fizzle & Pozzik's Speedbarge",
        mapID = 64,
        x = 0.8065,
        y = 0.7091
    },
    -- Desolace (KALIMDOR_OVERWORLD)
    SHADOWPREY_VILLAGE_FLIGHT = {
        name = "Shadowprey Village",
        faction = "HORDE",
        mapID = 66,
        x = 0.2108,
        y = 0.7426
    },
    FURIENS_POST_FLIGHT = {
        name = "Furien's Post",
        faction = "HORDE",
        mapID = 66,
        x = 0.4333,
        y = 0.2959
    },
    -- Feralas (KALIMDOR_OVERWORLD)
    CAMP_MOJACHE_FLIGHT = {
        name = "Camp Mojache",
        faction = "HORDE",
        mapID = 69,
        x = 0.7464,
        y = 0.4424
    },
    STONEMAUL_HOLD_FLIGHT = {
        name = "Stonemaul Hold",
        faction = "HORDE",
        mapID = 69,
        x = 0.5074,
        y = 0.4813
    },
    CAMP_ATAYA_FLIGHT = {
        name = "Camp Ataya",
        faction = "HORDE",
        mapID = 69,
        x = 0.4050,
        y = 0.1546
    },
    -- Azshara (KALIMDOR_OVERWORLD)
    BILGEWATER_HARBOR_FLIGHT = {
        name = "Bilgewater Harbor",
        faction = "HORDE",
        mapID = 76,
        x = 0.5228,
        y = 0.4990
    },
    NORTHERN_ROCKETWAY_FLIGHT = {
        name = "Northern Rocketway",
        faction = "HORDE",
        mapID = 76,
        x = 0.6711,
        y = 0.2094
    },
    SOUTHERN_ROCKETWAY_FLIGHT = {
        name = "Southern Rocketway",
        faction = "HORDE",
        mapID = 76,
        x = 0.5133,
        y = 0.7426
    },
    VALORMOK_FLIGHT = {
        name = "Valormok",
        faction = "HORDE",
        mapID = 76,
        x = 0.1413,
        y = 0.6579
    },
    -- Dustwallow Marsh (KALIMDOR_OVERWORLD)
    BRACKENWALL_VILLAGE_FLIGHT = {
        name = "Brackenwall Village",
        faction = "HORDE",
        mapID = 70,
        x = 0.3485,
        y = 0.3171
    },
    -- Ashenvale (KALIMDOR_OVERWORLD)
    ZORAMGAR_OUTPOST_FLIGHT = {
        name = "Zoram'gar Outpost",
        faction = "HORDE",
        mapID = 63,
        x = 0.1001,
        y = 0.3506
    },
    SPLINTERTREE_POST_FLIGHT = {
        name = "Splintertree Post",
        faction = "HORDE",
        mapID = 63,
        x = 0.7311,
        y = 0.6296
    },
    SILVERWIND_REFUGE_FLIGHT = {
        name = "Silverwind Refuge",
        faction = "HORDE",
        mapID = 63,
        x = 0.4910,
        y = 0.6614
    },
    HELLSCREAMS_WATCH_FLIGHT = {
        name = "Hellscream's Watch",
        faction = "HORDE",
        mapID = 63,
        x = 0.3721,
        y = 0.4177
    },
    THE_MORSHAN_RAMPARTS_FLIGHT = {
        name = "The Mor'Shan Ramparts",
        faction = "HORDE",
        mapID = 63,
        x = 0.6770,
        y = 0.8998
    },
    -- Uldum (KALIMDOR_OVERWORLD)
    SCHNOTTZS_LANDING_FLIGHT = {
        name = "Schnottz's Landing",
        mapID = 249,
        x = 0.2190,
        y = 0.6473
    },
    OASIS_OF_VIRSAR_FLIGHT = {
        name = "Oasis of Vir'sar",
        mapID = 249,
        x = 0.263,
        y = 0.082
    },
    -- Dungeons
    RAGEFIRE_CHASM_DUNGEON = {
        name = "Ragefire Chasm",
        category = "dungeon",
        mapID = 86,
        x = 0.670,
        y = 0.510
    },
    WAILING_CAVERNS_DUNGEON = {
        name = "Wailing Caverns",
        category = "dungeon",
        mapID = 10,
        x = 0.390,
        y = 0.700
    },
    RAZORFEN_KRAUL_DUNGEON = {
        name = "Razorfen Kraul",
        category = "dungeon",
        mapID = 199,
        x = 0.420,
        y = 0.940
    },
    RAZORFEN_DOWNS_DUNGEON = {
        name = "Razorfen Downs",
        category = "dungeon",
        mapID = 64,
        x = 0.490,
        y = 0.260
    },
    MARAUDON_DUNGEON = {
        name = "Maraudon",
        category = "dungeon",
        mapID = 66,
        x = 0.300,
        y = 0.620
    },
    BLACKFATHOM_DEEPS_DUNGEON = {
        name = "Blackfathom Deeps",
        category = "dungeon",
        mapID = 63,
        x = 0.140,
        y = 0.150
    },
    ZULFARRAK_DUNGEON = {
        name = "Zul'Farrak",
        category = "dungeon",
        mapID = 71,
        x = 0.390,
        y = 0.220
    },
    DIRE_MAUL_DUNGEON = {
        name = "Dire Maul",
        category = "dungeon",
        mapID = 69,
        x = 0.620,
        y = 0.310
    },
    OLD_HILLSBRAD_FOOTHILLS_DUNGEON = {
        name = "Old Hillsbrad Foothills",
        category = "dungeon",
        mapID = 75,
        x = 0.2714,
        y = 0.3623
    },
    THE_BLACK_MORASS_DUNGEON = {
        name = "The Black Morass",
        category = "dungeon",
        mapID = 75,
        x = 0.3683,
        y = 0.8337
    },
    THE_CULLING_OF_STRATHOLME_DUNGEON = {
        name = "The Culling of Stratholme",
        category = "dungeon",
        mapID = 75,
        x = 0.5704,
        y = 0.8255
    },
    THE_VORTEX_PINNACLE_DUNGEON = {
        name = "The Vortex Pinnacle",
        category = "dungeon",
        mapID = 249,
        x = 0.760,
        y = 0.830
    },
    WELL_OF_ETERNITY_DUNGEON = {
        name = "Well of Eternity",
        category = "dungeon",
        mapID = 75,
        x = 0.2323,
        y = 0.6436
    },
    HOUR_OF_TWILIGHT_DUNGEON = {
        name = "Hour of Twilight",
        category = "dungeon",
        mapID = 75,
        x = 0.6645,
        y = 0.2940
    },
    END_TIME_DUNGEON = {
        name = "End Time",
        category = "dungeon",
        mapID = 75,
        x = 0.5751,
        y = 0.2980
    },
    HALLS_OF_ORIGINATION_DUNGEON = {
        name = "Halls of Origination",
        category = "dungeon",
        mapID = 75,
        x = 0.710,
        y = 0.520
    },
    LOST_CITY_OF_THE_TOLVIR = {
        name = "Lost City of the Tol'vir",
        category = "dungeon",
        mapID = 75,
        x = 0.600,
        y = 0.640
    },
    THE_VORTEX_PINNACLE = {
        name = "The Vortex Pinnacle",
        category = "dungeon",
        mapID = 75,
        x = 0.760,
        y = 0.830
    },
    -- Raids
    TEMPLE_OF_AHNQIRAJ_RAID = {
        name = "Temple of Ahn'Qiraj",
        category = "raid",
        mapID = 327,
        x = 0.470,
        y = 0.070
    },
    RUINS_OF_AHNQIRAJ_RAID = {
        name = "Ruins of Ahn'Qiraj",
        category = "raid",
        mapID = 327,
        x = 0.580,
        y = 0.140
    },
    THE_BATTLE_FOR_MOUNT_HYJAL_RAID = {
        name = "The Battle for Mount Hyjal",
        category = "raid",
        mapID = 75,
        x = 0.3592,
        y = 0.1585
    },
    ONYXIAS_LAIR_RAID = {
        name = "Onyxia's Lair",
        category = "raid",
        mapID = 70,
        x = 0.560,
        y = 0.710
    },
    NYALOTHA_THE_WAKING_CITY_RAID_ULDUM = {
        name = "Ny'alotha, the Waking City",
        category = "raid",
        mapID = 249,
        x = 0.380,
        y = 0.440
    },
    DRAGON_SOUL_RAID = {
        name = "Dragon Soul",
        category = "raid",
        mapID = 75,
        x = 0.6175,
        y = 0.2649
    },
    THRONE_OF_THE_FOUR_WINDS_RAID = {
        name = "Throne of the Four Winds",
        category = "raid",
        mapID = 249,
        x = 0.380,
        y = 0.800
    },
    FIRELANDS_RAID = {
        name = "Firelands",
        category = "raid",
        mapID = 198,
        x = 0.470,
        y = 0.770
    }
}


ns.Nodes.TELDRASSIL = {
    DARNASSUS = {
        name = "Entrance",
        faction = "ALLIANCE",
        mapID = 89,
        x = 0.435,
        y = 0.787
    },
    DOLANAAR_FLIGHT = {
        name = "Dolanaar",
        faction = "ALLIANCE",
        mapID = 57,
        x = 0.542,
        y = 0.501
    },
    DARNASSUS_FLIGHT = {
        name = "Flightmaster",
        category = "city",
        faction = "ALLIANCE",
        mapID = 89,
        x = 0.270,
        y = 0.480
    },
    RUTTHERAN_VILLAGE_FLIGHT = {
        name = "Rut'theran Village",
        faction = "ALLIANCE",
        mapID = 57,
        x = 0.115,
        y = 0.496
    },
    RUTTHERAN_VILLAGE_DOCK = {
        name = "Rut'theran Village Dock",
        faction = "ALLIANCE",
        mapID = 57,
        x = 0.5238,
        y = 0.8947
    }
}


ns.Nodes.DRAENEI_HOME = {
    EXODAR = {
        name = "Entrance",
        faction = "ALLIANCE",
        mapID = 103,
        x = 0.476,
        y = 0.598
    },
    THE_EXODAR_FLIGHT = {
        name = "Flightmaster",
        category = "city",
        faction = "ALLIANCE",
        mapID = 103,
        x = 0.541,
        y = 0.367
    },
    AZUREMYST_ISLE_DOCK = {
        name = "Azuremyst Isle Dock",
        faction = "ALLIANCE",
        mapID = 97,
        x = 0.2148,
        y = 0.5407
    },
    AZURE_WATCH_FLIGHT = {
        name = "Azure Watch",
        faction = "ALLIANCE",
        mapID = 97,
        x = 0.501,
        y = 0.501
    },
    BLOOD_WATCH_FLIGHT = {
        name = "Blood Watch",
        faction = "ALLIANCE",
        mapID = 106,
        x = 0.573,
        y = 0.542
    }
}


ns.Nodes.RAZORWIND_SHORES = {
    RAZORWIND_SHORES = {
        name = "Entrance Portal",
        faction = "HORDE",
        mapID = 2351,
        x = 0.540,
        y = 0.496
    },
    RAZORWIND_PORTAL_TO_FORBIDDEN_REACH = {
        name = "Portal to the Forbidden Reach",
        mapID = 2351,
        x = 0.5424,
        y = 0.5589
    }
}

