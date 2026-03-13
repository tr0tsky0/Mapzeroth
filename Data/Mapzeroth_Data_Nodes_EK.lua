-- Mapzeroth_Data_Nodes_EK.lua
-- Eastern Kingdoms, Tol Barad, Deepholm, Founder's Point
local _, ns = ...

ns.Nodes = ns.Nodes or {}

ns.Nodes.EK_OVERWORLD = {
    -- Stormwind Portal Hub
    STORMWIND_PORTAL_ROOM_LOWER = {
        name = "Portal Room (Lower)",
        mapID = 84,
        interior = true,
        x = 0.4634,
        y = 0.9024
    },
    STORMWIND_PORTAL_ROOM_UPPER = {
        name = "Portal Room (Upper)",
        mapID = 84,
        interior = true,
        x = 0.4275,
        y = 0.9438
    },
    STORMWIND_DARK_PORTAL_BL_NPC = {
        name = "Honor Hold Mage",
        mapID = 84,
        interior = true,
        x = 0.4911,
        y = 0.8734
    },
    STORMWIND_DORNOGAL_PORTAL = {
        name = "Portal to Dornogal",
        mapID = 84,
        interior = true,
        x = 0.4797,
        y = 0.9211
    },
    STORMWIND_VALDRAKKEN_PORTAL = {
        name = "Portal to Valdrakken",
        mapID = 84,
        interior = true,
        x = 0.4874,
        y = 0.9356
    },
    STORMWIND_SILVERMOON_PORTAL = {
        name = "Portal to Silvermoon City",
        mapID = 84,
        interior = true,
        x = 0.4865,
        y = 0.9497
    },
    STORMWIND_BORALUS_PORTAL = {
        name = "Portal to Boralus",
        mapID = 84,
        interior = true,
        x = 0.4097,
        y = 0.9262
    },
    STORMWIND_ORIBOS_PORTAL = {
        name = "Portal to Oribos",
        mapID = 84,
        interior = true,
        x = 0.4772,
        y = 0.9478
    },
    STORMWIND_FOUNDERS_POINT_PORTAL = {
        name = "Portal to Founder's Point",
        mapID = 84,
        interior = true,
        x = 0.4701,
        y = 0.9326
    },
    STORMWIND_PAWDON_VILLAGE_PORTAL = {
        name = "Portal to Paw'don Village",
        mapID = 84,
        interior = true,
        x = 0.4559,
        y = 0.8730
    },
    STORMWIND_SHATTRATH_OUTLANDS_PORTAL = {
        name = "Portal to Shattrath",
        mapID = 84,
        interior = true,
        x = 0.4480,
        y = 0.8584
    },
    STORMWIND_CAVERNS_OF_TIME_PORTAL = {
        name = "Portal to Caverns of Time",
        mapID = 84,
        interior = true,
        x = 0.4379,
        y = 0.8550
    },
    STORMWIND_EXODAR_PORTAL = {
        name = "Portal to The Exodar",
        mapID = 84,
        interior = true,
        x = 0.4372,
        y = 0.8709
    },
    STORMWIND_DALARAN_NORTHREND_PORTAL = {
        name = "Portal to Northrend Dalaran",
        mapID = 84,
        interior = true,
        x = 0.4442,
        y = 0.8861
    },
    STORMWIND_BELAMETH_PORTAL = {
        name = "Portal to Bel'ameth",
        mapID = 84,
        interior = true,
        x = 0.4336,
        y = 0.9753
    },
    STORMWIND_AZSUNA_PORTAL = {
        name = "Portal to Bel'ameth",
        mapID = 84,
        interior = true,
        x = 0.4197,
        y = 0.9150
    },
    STORMWIND_STORMSHIELD_PORTAL = {
        name = "Portal to Stormshield",
        mapID = 84,
        interior = true,
        x = 0.4126,
        y = 0.8995
    },
    -- Stormwind City Locations
    STORMWIND_MAGE_TOWER_ENTRANCE = {
        name = "Mage Tower",
        mapID = 84,
        x = 0.4951,
        y = 0.8666
    },
    EASTERN_EARTHSHRINE_SW = {
        name = "Eastern Earthshrine",
        mapID = 84,
        x = 0.724,
        y = 0.164
    },
    SW_EMBASSY = {
        name = "Embassy",
        mapID = 84,
        x = 0.661,
        y = 0.228
    },
    SW_TRAM = {
        name = "Deeprun Tram",
        mapID = 84,
        x = 0.650,
        y = 0.323
    },
    STORMWIND_HARBOR = {
        name = "Harbour",
        mapID = 84,
        x = 0.268,
        y = 0.355
    },
    DARKMOON_FAIRE_ENTRANCE_ELWYNN = {
        name = "Darkmoon Faire Entrance",
        mapID = 37,
        x = 0.4179,
        y = 0.6940
    },
    -- Ironforge
    IF_TRAM = {
        name = "Deeprun Tram",
        mapID = 87,
        x = 0.706,
        y = 0.487
    },
    IRONFORGE = {
        name = "Hall of Mysteries",
        mapID = 87,
        x = 0.2551,
        y = 0.0843
    },
    IRONFORGE_ENTRANCE = {
        name = "Entrance",
        mapID = 87,
        x = 0.1734,
        y = 0.8316
    },
    -- Cataclysm Zones (via Eastern Earthshrine)
    HIGHBANK = {
        name = "Highbank",
        mapID = 1275,
        x = 0.800,
        y = 0.743
    },
    DRAGONMAW_PORT = {
        name = "Dragonmaw Port",
        mapID = 1275,
        x = 0.743,
        y = 0.508
    },
    CRUSHBLOW_FLIGHT = {
        name = "Crushblow",
        mapID = 1275,
        x = 0.4533,
        y = 0.7568
    },
    THE_GULLET_FLIGHT = {
        name = "The Gullet",
        mapID = 1275,
        x = 0.3827,
        y = 0.3806
    },
    BLOODGULCH_FLIGHT = {
        name = "Bloodgulch",
        mapID = 1275,
        x = 0.5475,
        y = 0.4266
    },
    THE_KRAZZWORKS_FLIGHT = {
        name = "The Krazzworks",
        mapID = 1275,
        x = 0.7488,
        y = 0.1758
    },
    DRAGONMAW_PORT_FLIGHT = {
        name = "Dragonmaw Port Flightmaster",
        mapID = 1275,
        x = 0.7347,
        y = 0.5254
    },
    -- Miscellaneous EK
    DARK_PORTAL_BL = {
        name = "The Dark Portal",
        mapID = 17,
        x = 0.5489,
        y = 0.5011
    },
    SHATTERED_LANDING_FLIGHT = {
        name = "Shattered Landing",
        mapID = 1246,
        x = 0.7288,
        y = 0.4838
    },
    BADLANDS = {
        name = "Uldaman",
        mapID = 15,
        x = 0.452,
        y = 0.125
    },
    GILNEAS = {
        name = "Gilneas City",
        mapID = 217,
        x = 0.5890,
        y = 0.4746
    },
    GILNEAS_DOCK = {
        name = "Dock",
        mapID = 217,
        x = 0.636,
        y = 0.956
    },
    FORSAKEN_FORWARD_COMMAND_FLIGHT = {
        name = "Forsaken Forward Command",
        mapID = 217,
        x = 0.5675,
        y = 0.1801
    },
    KARAZHAN = {
        name = "Karazhan",
        mapID = 42,
        x = 0.473,
        y = 0.753
    },
    DALARAN_CRATER = {
        name = "Dalaran Crater",
        mapID = 25,
        x = 0.200,
        y = 0.586
    },
    STONARD = {
        name = "Stonard",
        mapID = 76,
        x = 0.4984,
        y = 0.5581
    },
    UNDERCITY = {
        name = "Entrance",
        category = "city",
        mapID = 90,
        x = 0.663,
        y = 0.384
    },
    THE_BULWARK_FLIGHT = {
        name = "The Bulwark",
        mapID = 18,
        x = 0.8241,
        y = 0.6985
    },
    LIGHTS_HOPE_CHAPEL = {
        name = "Light's Hope Chapel",
        mapID = 23,
        x = 0.757,
        y = 0.533
    },
    SANCTUM_OF_LIGHT = {
        name = "Sanctum of Light",
        mapID = 24,
        x = 0.3942,
        y = 0.6146
    },
    BIZMOS_BRAWLPUB = {
        name = "Bizmo's Brawlpub",
        mapID = 84,
        x = 0.6943,
        y = 0.3133
    },
    STORMWIND_CITY_MOLE = {
        name = "Stormwind (Eastern Kingdoms)",
        mapID = 84,
        x = 0.633,
        y = 0.373
    },
    IRONFORGE_MOLE = {
        name = "Ironforge (Eastern Kingdoms)",
        mapID = 27,
        x = 0.613,
        y = 0.372
    },
    BLACKROCK_MOUNTAIN_MOLE = {
        name = "Blackrock Mountain (Eastern Kingdoms - The Masonary)",
        mapID = 35,
        x = 0.332,
        y = 0.251,
        interior = true
    },
    AERIE_PEAK_MOLE = {
        name = "Aerie Peak (Eastern Kingdoms)",
        mapID = 26,
        x = 0.134,
        y = 0.467
    },
    NETHERGARDE_KEEP_MOLE = {
        name = "Nethergarde Keep (Eastern Kingdoms)",
        mapID = 17,
        x = 0.620,
        y = 0.128
    },
    AERIE_PEAK_FLIGHT = {
        name = "Aerie Peak",
        mapID = 26,
        x = 0.108,
        y = 0.470
    },
    ANDORHAL_FLIGHT_ALLIANCE = {
        name = "Andorhal",
        mapID = 22,
        x = 0.392,
        y = 0.695
    },
    ANDORHAL_FLIGHT_HORDE = {
        name = "Andorhal",
        mapID = 22,
        x = 0.4674,
        y = 0.6473
    },
    THE_MENDERS_STEAD_FLIGHT = {
        name = "The Menders' Stead",
        mapID = 22,
        x = 0.514,
        y = 0.532
    },
    HEARTHGLEN_FLIGHT = {
        name = "Hearthglen",
        mapID = 22,
        x = 0.444,
        y = 0.153
    },
    BOOTY_BAY_FLIGHT_ALLIANCE = {
        name = "Booty Bay",
        mapID = 210,
        x = 0.414,
        y = 0.744
    },
    BOOTY_BAY_FLIGHT_HORDE = {
        name = "Booty Bay",
        mapID = 210,
        x = 0.4015,
        y = 0.7328
    },
    HARDWRENCH_HIDEAWAY_FLIGHT = {
        name = "Hardwrench Hideaway",
        mapID = 210,
        x = 0.3556,
        y = 0.2888
    },
    BOOTY_BAY_DOCK = {
        name = "Booty Bay Dock",
        mapID = 210,
        x = 0.3886,
        y = 0.6692
    },
    CAMP_EVERSTILL_FLIGHT = {
        name = "Camp Everstill",
        mapID = 49,
        x = 0.538,
        y = 0.551
    },
    CHILLWIND_CAMP_FLIGHT = {
        name = "Chillwind Camp",
        mapID = 22,
        x = 0.421,
        y = 0.836
    },
    DARKSHIRE_FLIGHT = {
        name = "Darkshire",
        mapID = 47,
        x = 0.774,
        y = 0.444
    },
    DUSKWOOD_DRUID = {
        name = "Twilight Grove",
        mapID = 47,
        x = 0.4659,
        y = 0.3706
    },
    DRAGONS_MOUTH_FLIGHT = {
        name = "Dragon's Mouth",
        mapID = 15,
        x = 0.222,
        y = 0.588
    },
    DUN_MODR_FLIGHT = {
        name = "Dun Modr",
        mapID = 56,
        x = 0.500,
        y = 0.185
    },
    DUSTWIND_DIG_FLIGHT = {
        name = "Dustwind Dig",
        mapID = 15,
        x = 0.484,
        y = 0.365
    },
    FUSELIGHT_FLIGHT = {
        name = "Fuselight",
        mapID = 15,
        x = 0.647,
        y = 0.351
    },
    EASTVALE_LOGGING_CAMP_FLIGHT = {
        name = "Eastvale Logging Camp",
        mapID = 37,
        x = 0.821,
        y = 0.656
    },
    EXPLORERS_LEAGUE_DIGSITE_FLIGHT = {
        name = "Explorers' League Digsite",
        mapID = 210,
        x = 0.560,
        y = 0.424
    },
    FARSTRIDER_LODGE_FLIGHT = {
        name = "Farstrider Lodge",
        mapID = 48,
        x = 0.836,
        y = 0.637
    },
    FIREBEARDS_PATROL_FLIGHT = {
        name = "Firebeard's Patrol",
        mapID = 241,
        x = 0.602,
        y = 0.585
    },
    FORT_LIVINGSTON_FLIGHT = {
        name = "Fort Livingston",
        mapID = 50,
        x = 0.526,
        y = 0.659
    },
    GROMGOL_ZEPPELIN = {
        name = "Grom'gol Zeppelin",
        mapID = 50,
        x = 0.4180,
        y = 0.3365
    },
    FURLBROWS_PUMPKIN_FARM_FLIGHT = {
        name = "Furlbrow's Pumpkin Farm",
        mapID = 52,
        x = 0.506,
        y = 0.186
    },
    GOLBOLAR_QUARRY_FLIGHT = {
        name = "Gol'Bolar Quarry",
        mapID = 27,
        x = 0.768,
        y = 0.537
    },
    GOLDSHIRE_FLIGHT = {
        name = "Goldshire",
        mapID = 37,
        x = 0.422,
        y = 0.654
    },
    GREENWARDENS_GROVE_FLIGHT = {
        name = "Greenwarden's Grove",
        mapID = 56,
        x = 0.553,
        y = 0.417
    },
    HIGHBANK_FLIGHT = {
        name = "Highbank Flightmaster",
        mapID = 241,
        x = 0.813,
        y = 0.766
    },
    IRONFORGE_FLIGHT = {
        name = "Flightmaster",
        category = "city",
        mapID = 87,
        x = 0.557,
        y = 0.479
    },
    KHARANOS_FLIGHT = {
        name = "Kharanos",
        mapID = 27,
        x = 0.544,
        y = 0.525
    },
    LAKESHIRE_FLIGHT = {
        name = "Lakeshire",
        mapID = 49,
        x = 0.292,
        y = 0.532
    },
    LIGHTS_HOPE_CHAPEL_FLIGHT_ALLIANCE = {
        name = "Light's Hope Chapel",
        mapID = 23,
        x = 0.754,
        y = 0.534
    },
    LIGHTS_HOPE_CHAPEL_FLIGHT_HORDE = {
        name = "Light's Hope Chapel",
        mapID = 23,
        x = 0.7488,
        y = 0.5360
    },
    THONDRORIL_RIVER_FLIGHT = {
        name = "Thondroril River",
        mapID = 23,
        x = 0.107,
        y = 0.649
    },
    PLAGUEWOOD_TOWER_FLIGHT = {
        name = "Plaguewood Tower",
        mapID = 23,
        x = 0.184,
        y = 0.289
    },
    CROWN_GUARD_TOWER_FLIGHT = {
        name = "Crown Guard Tower",
        mapID = 23,
        x = 0.366,
        y = 0.692
    },
    LIGHTS_SHIELD_TOWER_FLIGHT = {
        name = "Light's Shield Tower",
        mapID = 23,
        x = 0.540,
        y = 0.535
    },
    EASTWALL_TOWER_FLIGHT = {
        name = "Eastwall Tower",
        mapID = 23,
        x = 0.627,
        y = 0.428
    },
    NORTHPASS_TOWER_FLIGHT = {
        name = "Northpass Tower",
        mapID = 23,
        x = 0.511,
        y = 0.208
    },
    MARSHTIDE_WATCH_FLIGHT = {
        name = "Marshtide Watch",
        mapID = 51,
        x = 0.702,
        y = 0.352
    },
    BOGPADDLE_FLIGHT = {
        name = "Bogpaddle",
        mapID = 51,
        x = 0.712,
        y = 0.124
    },
    MENETHIL_HARBOR_FLIGHT = {
        name = "Menethil Harbor Flightmaster",
        mapID = 56,
        x = 0.090,
        y = 0.593
    },
    MENETHIL_HARBOR_DOCK = {
        name = "Menethil Harbor Dock",
        mapID = 56,
        x = 0.0613,
        y = 0.5890
    },
    MOONBROOK_FLIGHT = {
        name = "Moonbrook",
        mapID = 52,
        x = 0.416,
        y = 0.631
    },
    MORGANS_VIGIL_FLIGHT = {
        name = "Morgan's Vigil",
        mapID = 36,
        x = 0.719,
        y = 0.659
    },
    FLAMESTAR_POST_FLIGHT = {
        name = "Flamestar Post",
        mapID = 36,
        x = 0.165,
        y = 0.525
    },
    CHISELGRIP_FLIGHT = {
        name = "Chiselgrip",
        mapID = 36,
        x = 0.458,
        y = 0.432
    },
    RAVEN_HILL_FLIGHT = {
        name = "Raven Hill",
        mapID = 47,
        x = 0.205,
        y = 0.576
    },
    REBEL_CAMP_FLIGHT = {
        name = "Rebel Camp",
        mapID = 50,
        x = 0.479,
        y = 0.118
    },
    SENTINEL_HILL_FLIGHT = {
        name = "Sentinel Hill",
        mapID = 52,
        x = 0.560,
        y = 0.491
    },
    SHALEWIND_CANYON_FLIGHT = {
        name = "Shalewind Canyon",
        mapID = 49,
        x = 0.776,
        y = 0.649
    },
    SHATTERED_BEACHHEAD_FLIGHT = {
        name = "Shattered Beachhead",
        mapID = 17,
        x = 0.673,
        y = 0.275
    },
    SLABCHISELS_SURVEY_FLIGHT = {
        name = "Slabchisel's Survey",
        mapID = 56,
        x = 0.577,
        y = 0.715
    },
    STORMFEATHER_OUTPOST_FLIGHT = {
        name = "Stormfeather Outpost",
        mapID = 26,
        x = 0.662,
        y = 0.447
    },
    STORMWIND_FLIGHT = {
        name = "Flightmaster",
        category = "city",
        mapID = 84,
        x = 0.713,
        y = 0.724
    },
    THE_HARBORAGE_FLIGHT = {
        name = "The Harborage",
        mapID = 51,
        x = 0.294,
        y = 0.334
    },
    THELSAMAR_FLIGHT = {
        name = "Thelsamar",
        mapID = 48,
        x = 0.340,
        y = 0.506
    },
    THORIUM_POINT_FLIGHT_ALLIANCE = {
        name = "Thorium Point",
        mapID = 32,
        x = 0.377,
        y = 0.274
    },
    IRON_SUMMIT_FLIGHT = {
        name = "Iron Summit",
        mapID = 32,
        x = 0.408,
        y = 0.690
    },
    THUNDERMAR_FLIGHT = {
        name = "Thundermar",
        mapID = 241,
        x = 0.474,
        y = 0.296
    },
    VERMILLION_REDOUBT_FLIGHT = {
        name = "Vermillion Redoubt",
        mapID = 241,
        x = 0.296,
        y = 0.254
    },
    VICTORS_POINT_FLIGHT = {
        name = "Victor's Point",
        mapID = 241,
        x = 0.434,
        y = 0.570
    },
    -- Arathi Highlands (EK_OVERWORLD)
    REFUGE_POINTE_FLIGHT = {
        name = "Refuge Pointe",
        mapID = 14,
        x = 0.3944,
        y = 0.4725
    },
    -- Twilight Highlands (EK_OVERWORLD)
    KIRTHAVEN_FLIGHT = {
        name = "Kirthaven",
        mapID = 1275,
        x = 0.5781,
        y = 0.1582
    },
    -- Silverpine Forest (EK_OVERWORLD)
    THE_SEPULCHER_FLIGHT = {
        name = "The Sepulcher",
        mapID = 21,
        x = 0.4521,
        y = 0.4230
    },
    THE_FORSAKEN_FRONT_FLIGHT = {
        name = "The Forsaken Front",
        mapID = 21,
        x = 0.4992,
        y = 0.6367
    },
    FORSAKEN_REAR_GUARD_FLIGHT = {
        name = "Forsaken Rear Guard",
        mapID = 21,
        x = 0.4580,
        y = 0.2164
    },
    FORSAKEN_HIGH_COMMAND_FLIGHT = {
        name = "Forsaken High Command",
        mapID = 21,
        x = 0.5781,
        y = 0.1034
    },
    -- Hillsbrad Foothills (EK_OVERWORLD)
    TARREN_MILL_FLIGHT = {
        name = "Tarren Mill",
        mapID = 25,
        x = 0.5581,
        y = 0.4583
    },
    STRAHNBRAD_FLIGHT = {
        name = "Strahnbrad",
        mapID = 25,
        x = 0.5851,
        y = 0.2429
    },
    EASTPOINT_TOWER_FLIGHT = {
        name = "Eastpoint Tower",
        mapID = 25,
        x = 0.5934,
        y = 0.6349
    },
    RUINS_OF_SOUTHSHORE_FLIGHT = {
        name = "Ruins of Southshore",
        mapID = 25,
        x = 0.4886,
        y = 0.6526
    },
    SOUTHPOINT_GATE_FLIGHT = {
        name = "Southpoint Gate",
        mapID = 25,
        x = 0.2838,
        y = 0.6402
    },
    -- Arathi Highlands (EK_OVERWORLD)
    HAMMERFALL_FLIGHT = {
        name = "Hammerfall",
        mapID = 14,
        x = 0.6864,
        y = 0.3400
    },
    -- Stranglethorn Vale (EK_OVERWORLD)
    GROMGOL_FLIGHT = {
        name = "Grom'gol",
        mapID = 50,
        x = 0.3874,
        y = 0.5103
    },
    BAMBALA_FLIGHT = {
        name = "Bambala",
        mapID = 50,
        x = 0.6146,
        y = 0.3902
    },
    -- Badlands (EK_OVERWORLD)
    NEW_KARGATH_FLIGHT = {
        name = "New Kargath",
        mapID = 15,
        x = 0.1719,
        y = 0.4107
    },
    -- Swamp of Sorrows (EK_OVERWORLD)
    STONARD_FLIGHT = {
        name = "Stonard",
        mapID = 51,
        x = 0.4674,
        y = 0.5484
    },
    -- Burning Steppes (EK_OVERWORLD)
    FLAME_CREST_FLIGHT = {
        name = "Flame Crest",
        mapID = 36,
        x = 0.5581,
        y = 0.2447
    },
    -- Searing Gorge (EK_OVERWORLD)
    THORIUM_POINT_FLIGHT_HORDE = {
        name = "Thorium Point",
        mapID = 32,
        x = 0.3721,
        y = 0.2772
    },
    -- The Hinterlands (EK_OVERWORLD)
    REVANTUSK_VILLAGE_FLIGHT = {
        name = "Revantusk Village",
        mapID = 26,
        x = 0.8065,
        y = 0.8115
    },
    HIRIWATHA_RESEARCH_STATION_FLIGHT = {
        name = "Hiri'watha Research Station",
        mapID = 26,
        x = 0.3215,
        y = 0.5713
    },
    HINTERLANDS_DRUID = {
        name = "Seradane, Hinterlands",
        mapID = 26,
        x = 0.6249,
        y = 0.2350
    },
    -- Badlands (EK_OVERWORLD)
    BLOODWATCHER_POINT_FLIGHT = {
        name = "Bloodwatcher Point",
        mapID = 15,
        x = 0.5216,
        y = 0.5254
    },
    WHELGARS_RETREAT_FLIGHT = {
        name = "Whelgar's Retreat",
        mapID = 56,
        x = 0.399,
        y = 0.388
    },
    DARKBREAK_COVE_PORTAL = {
        name = "Darkbreak Cove Portal",
        mapID = 204,
        x = 0.5570,
        y = 0.7280
    },
    DARKBREAK_COVE_FLIGHT = {
        name = "Darkbreak Cove",
        mapID = 204,
        x = 0.578,
        y = 0.786
    },
    TRANQUIL_WASH_FLIGHT = {
        name = "Tranquil Wash",
        mapID = 205,
        x = 0.487,
        y = 0.576
    },
    SANDY_BEACH_FLIGHT_ALLIANCE = {
        name = "Sandy Beach",
        mapID = 205,
        x = 0.569,
        y = 0.173
    },
    SANDY_BEACH_FLIGHT_HORDE = {
        name = "Sandy Beach",
        mapID = 205,
        x = 0.6075,
        y = 0.2754
    },
    SILVER_TIDE_HOLLOW_FLIGHT = {
        name = "Silver Tide Hollow",
        mapID = 205,
        x = 0.493,
        y = 0.400
    },
    LEGIONS_REST_FLIGHT = {
        name = "Legion's Rest",
        mapID = 205,
        x = 0.5027,
        y = 0.6639
    },
    STYGIAN_BOUNTY_FLIGHT = {
        name = "Stygian Bounty",
        mapID = 205,
        x = 0.5381,
        y = 0.6551
    },
    SMUGGLERS_SCAR_FLIGHT = {
        name = "Smuggler's Scar",
        mapID = 201,
        x = 0.557,
        y = 0.342
    },
    VOLDRINS_HOLD_FLIGHT = {
        name = "Voldrin's Hold",
        mapID = 205,
        x = 0.566,
        y = 0.756
    },
    TENEBROUS_CAVERN_PORTAL = {
        name = "Tenebrous Cavern Portal",
        mapID = 204,
        x = 0.6004,
        y = 0.5625
    },
    TENEBROUS_CAVERN_FLIGHT = {
        name = "Tenebrous Cavern",
        mapID = 204,
        x = 0.6004,
        y = 0.5625
    },
    BLACKROCK_QUARRY_EXTERIOR = {
        name = "Blackrock Quarry Interior",
        mapID = 35,
        x = 0.5513,
        y = 0.8454,
        interior = false
    },
    SILVERMOON_CITY_FLIGHT = {
        name = "Silvermoon City Flightmaster",
        mapID = 2393,
        x = 0.5107,
        y = 0.7108
    },
    SILVERMOON_STORMWIND_PORTAL = {
        name = "Portal to Stormwind",
        mapID = 2393,
        x = 0.5275,
        y = 0.6471
    },
    SILVERMOON_ORGRIMMAR_PORTAL = {
        name = "Portal to Orgrimmar",
        mapID = 2393,
        x = 0.5225,
        y = 0.6532
    },
    SILVERMOON_HARANDAR_PORTAL = {
        name = "Rootway to Harandar",
        mapID = 2393,
        x = 0.3689,
        y = 0.6811
    },
    SILVERMOON_VOIDSTORM_PORTAL = {
        name = "Portal to Voidstorm",
        mapID = 2393,
        x = 0.3526,
        y = 0.6584
    },
    SILVERMOON_PORTAL_ROOM = {
        name = "Portal Room",
        mapID = 2393,
        x = 0.5274,
        y = 0.6535
    },
    SILVERMOON_INN = {
        name = "Wayfarer's Rest",
        mapID = 2393,
        x = 0.5628,
        y = 0.7037
    },
    SILVERMOON_ARCANTINA_PORTAL = {
        name = "Portal to the Arcantina",
        mapID = 2393,
        x = 0.5641,
        y = 0.7077
    },
    FAIRBREEZE_VILLAGE_FLIGHT = {
        name = "Fairbreeze Village Flightmaster",
        mapID = 2395,
        x = 0.4468,
        y = 0.4499
    },
    EVERSONG_HARANDAR_PORTAL = {
        name = "Rootway to Harandar",
        mapID = 2395,
        x = 0.4524,
        y = 0.4689
    },
    TRANQUILLIEN_FLIGHT = {
        name = "Tranquillien Flightmaster",
        mapID = 2395,
        x = 0.4784,
        y = 0.6715
    },
    SILVERGLADE_REFUGE_FLIGHT = {
        name = "Silverglade Refuge Flightmaster",
        mapID = 2395,
        x = 0.3103,
        y = 0.9008
    },
    ATALAMAN_FLIGHT = {
        name = "Atal'Aman Flightmaster",
        mapID = 2536,
        x = 0.4006,
        y = 0.4113
    },
    AMANIZAR_FLIGHT = {
        name = "Amani'Zar Flightmaster",
        mapID = 2437,
        x = 0.4483,
        y = 0.6544
    },
    TORNTUSK_OVERLOOK_FLIGHT = {
        name = "Torntusk Overlook Flightmaster",
        mapID = 2437,
        x = 0.3388,
        y = 0.7836
    },
    WITHERBARK_BLUFFS_FLIGHT = {
        name = "Witherbark Bluffs Flightmaster",
        mapID = 2437,
        x = 0.3887,
        y = 0.2323
    },
    SHADEBASIN_WATCH_FLIGHT = {
        name = "Shadebasin Watch Flightmaster",
        mapID = 2437,
        x = 0.4402,
        y = 0.3367
    },
    CAMP_STONEWASH_FLIGHT = {
        name = "Camp Stonewash Flightmaster",
        mapID = 2437,
        x = 0.4729,
        y = 0.2550
    },
    TERRACE_OF_THE_SUN_FLIGHT = {
        name = "Terrace of the Sun",
        mapID = 2424,
        x = 0.5762,
        y = 0.3382
    },
    -- Dungeons
    SHADOWFANG_KEEP_DUNGEON = {
        name = "Shadowfang Keep",
        category = "dungeon",
        mapID = 21,
        x = 0.450,
        y = 0.680
    },
    GNOMEREGAN_DUNGEON = {
        name = "Gnomeregan",
        category = "dungeon",
        mapID = 27,
        x = 0.3120,
        y = 0.3789
    },
    THE_STOCKADE_DUNGEON = {
        name = "The Stockade",
        category = "dungeon",
        mapID = 84,
        x = 0.510,
        y = 0.680
    },
    DEADMINES_DUNGEON = {
        name = "The Deadmines",
        category = "dungeon",
        mapID = 52,
        x = 0.4239,
        y = 0.7126
    },
    BLACKROCK_DEPTHS_DUNGEON = {
        name = "Blackrock Depths",
        category = "dungeon",
        mapID = 35,
        x = 0.3353,
        y = 0.2391,
        interior = true
    },
    LOWER_BLACKROCK_SPIRE_DUNGEON = {
        name = "Lower Blackrock Spire",
        category = "dungeon",
        mapID = 33,
        x = 0.8036,
        y = 0.4055
    },
    UPPER_BLACKROCK_SPIRE_DUNGEON = {
        name = "Upper Blackrock Spire",
        category = "dungeon",
        mapID = 33,
        x = 0.7897,
        y = 0.3373
    },
    BLACKROCK_CAVERNS_DUNGEON = {
        name = "Blackrock Caverns",
        category = "dungeon",
        mapID = 34,
        x = 0.7059,
        y = 0.5359
    },
    SCARLET_MONASTERY_DUNGEON = {
        name = "Scarlet Monastery",
        category = "dungeon",
        mapID = 18,
        x = 0.820,
        y = 0.330
    },
    SCARLET_HALLS_DUNGEON = {
        name = "Scarlet Halls",
        category = "dungeon",
        mapID = 18,
        x = 0.820,
        y = 0.330
    },
    STRATHOLME_DUNGEON = {
        name = "Stratholme",
        category = "dungeon",
        mapID = 23,
        x = 0.260,
        y = 0.140
    },
    SUNKEN_TEMPLE_DUNGEON = {
        name = "Sunken Temple",
        category = "dungeon",
        mapID = 51,
        x = 0.690,
        y = 0.540
    },
    ULDAMAN_DUNGEON = {
        name = "Uldaman",
        category = "dungeon",
        mapID = 15,
        x = 0.410,
        y = 0.100
    },
    ULDAMAN_LEGACY_OF_TYR_DUNGEON = {
        name = "Uldaman: Legacy of Tyr",
        category = "dungeon",
        mapID = 15,
        x = 0.410,
        y = 0.100
    },
    SCHOLOMANCE_DUNGEON = {
        name = "Scholomance",
        category = "dungeon",
        mapID = 22,
        x = 0.690,
        y = 0.730
    },
    RETURN_TO_KARAZHAN_DUNGEON = {
        name = "Return to Karazhan",
        category = "dungeon",
        mapID = 42, -- Deadwind Pass
        x = 0.470,
        y = 0.740
    },
    GRIM_BATOL_DUNGEON = {
        name = "Grim Batol",
        category = "dungeon",
        mapID = 241, -- Twilight Highlands
        x = 0.190,
        y = 0.540
    },
    ZULGURUB_DUNGEON = {
        name = "Zul'Gurub",
        category = "dungeon",
        mapID = 50,
        x = 0.670,
        y = 0.320
    },
    THRONE_OF_THE_TIDES_DUNGEON = {
        name = "Throne of the Tides",
        category = "dungeon",
        mapID = 204, -- Abyssal Depths
        x = 0.700,
        y = 0.300
    },
    MURDER_ROW_DUNGEON = {
        name = "Murder Row",
        category = "dungeon",
        mapID = 2393, -- Silvermoon City
        x = 0.5702,
        y = 0.6108
    },
    WINDRUNNER_SPIRE_DUNGEON = {
        name = "Windrunner Spire",
        category = "dungeon",
        mapID = 2395, -- Isle of Quel'Danas
        x = 0.3548,
        y = 0.7883
    },
    DEN_OF_NALORAKK_DUNGEON = {
        name = "Den of Nalorakk",
        category = "dungeon",
        mapID = 2437, -- Zul'Aman
        x = 0.2987,
        y = 0.8449
    },
    MAISARA_CAVERNS_DUNGEON = {
        name = "Maisara Caverns",
        category = "dungeon",
        mapID = 2437, -- Zul'Aman
        x = 0.4385,
        y = 0.3953
    },
    MAGISTERS_TERRACE_DUNGEON = {
        name = "Magisters' Terrace",
        category = "dungeon",
        mapID = 2424, -- Isle of Quel'Danas
        x = 0.6331,
        y = 0.1527
    },
    -- Raids
    MOLTEN_CORE_RAID = {
        name = "Molten Core",
        category = "raid",
        mapID = 35,
        x = 0.5446,
        y = 0.8361
    },
    BLACKWING_LAIR_RAID = {
        name = "Blackwing Lair",
        category = "raid",
        mapID = 33,
        x = 0.6432,
        y = 0.7080
    },
    BLACKWING_DESCENT_RAID = {
        name = "Blackwing Descent",
        category = "raid",
        mapID = 13,
        x = 0.4754,
        y = 0.6893
    },
    KARAZHAN_RAID = {
        name = "Karazhan (Burning Crusade)",
        category = "raid",
        mapID = 42,
        x = 0.4688,
        y = 0.7468
    },
    BASTION_OF_TWILIGHT_RAID = {
        name = "Bastion of Twilight",
        category = "raid",
        mapID = 241,
        x = 0.340,
        y = 0.770
    },
    MARCH_ON_QUELDANAS_RAID = {
        name = "March on Quel'Danas",
        category = "raid",
        mapID = 2424,
        x = 0.5230,
        y = 0.8537
    },

    -- Blasted Lands time phases (Zidormi)
    BLASTED_LANDS_ZIDORMI_PAST = {
        name = "Zidormi (Past Blasted Lands)",
        mapID = 17,
        mapArtID = 18,
        x = 0.4812,
        y = 0.0732
    },
    BLASTED_LANDS_ZIDORMI_PRESENT = {
        name = "Zidormi (Present Blasted Lands)",
        mapID = 17,
        mapArtID = 628,
        x = 0.4812,
        y = 0.0732
    }
}


ns.Nodes.TOL_BARAD = {
    TOL_BARAD_ALLIANCE = {
        name = "Tol Barad Camp",
        mapID = 245,
        x = 0.724,
        y = 0.562
    },
    TOL_BARAD_HORDE = {
        name = "Tol Barad Camp",
        mapID = 245,
        x = 0.531,
        y = 0.760
    },
    -- Raids
    BARADIN_HOLD = {
        name = "Baradin Hold",
        mapID = 244,
        x = 0.450,
        y = 0.470
    }
}


ns.Nodes.DEEPHOLM = {
    DEEPHOLM_STORMWIND_PORTAL = {
        name = "Stormwind Portal",
        mapID = 207,
        x = 0.4855,
        y = 0.5380
    },
    DEEPHOLM_ORGRIMMAR_PORTAL = {
        name = "Orgrimmar Portal",
        mapID = 207,
        x = 0.5089,
        y = 0.5307
    },
    TEMPLE_OF_EARTH_PORTAL = {
        name = "Portal to Therazane's Throne",
        mapID = 207,
        x = 0.4928,
        y = 0.5040
    },
    THERAZANES_THRONE_PORTAL = {
        name = "Portal to Temple of Earth",
        mapID = 207,
        x = 0.5703,
        y = 0.1346
    },
    THE_STONECORE_DUNGEON = {
        name = "The Stonecore",
        mapID = 207,
        x = 0.470,
        y = 0.520
    }
}


ns.Nodes.FOUNDERS_POINT = {
    FOUNDERS_POINT = {
        name = "Entrance Portal",
        mapID = 2352,
        x = 0.574,
        y = 0.268
    }
}

