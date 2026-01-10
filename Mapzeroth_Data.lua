-- Mapzeroth_Data.lua
-- Travel network data for Mapzeroth (World of Warcraft addon)
-- Nodes organized by traversal group, with comments for readability
local _, ns = ...

-----------------------------------------------------------
-- NODE REGISTRY
-- Structure: traversalGroup → nodeID → { name, mapID, x, y, faction? }
-----------------------------------------------------------

ns.Nodes = {
    EK_OVERWORLD = {
        -- Stormwind Portal Hub
        STORMWIND_PORTAL_ROOM = {
            name = "Mage Tower",
            faction = "ALLIANCE",
            mapID = 84,
            x = 0.480,
            y = 0.844
        },
        EASTERN_EARTHSHRINE_SW = {
            name = "Eastern Earthshrine",
            faction = "ALLIANCE",
            mapID = 84,
            x = 0.724,
            y = 0.164
        },
        -- Stormwind City Locations
        SW_EMBASSY = {
            name = "Embassy",
            faction = "ALLIANCE",
            mapID = 84,
            x = 0.661,
            y = 0.228
        },
        SW_TRAM = {
            name = "Deeprun Tram",
            faction = "ALLIANCE",
            mapID = 84,
            x = 0.650,
            y = 0.323
        },
        STORMWIND_HARBOR = {
            name = "Harbour",
            faction = "ALLIANCE",
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
            faction = "ALLIANCE",
            mapID = 87,
            x = 0.706,
            y = 0.487
        },
        IRONFORGE = {
            name = "Entrance",
            faction = "ALLIANCE",
            mapID = 87,
            x = 0.144,
            y = 0.833
        },
        -- Cataclysm Zones (via Eastern Earthshrine)
        HIGHBANK = {
            name = "Highbank",
            faction = "ALLIANCE",
            mapID = 1275,
            x = 0.800,
            y = 0.743
        },
        DRAGONMAW_PORT = {
            name = "Dragonmaw Port",
            faction = "HORDE",
            mapID = 1275,
            x = 0.743,
            y = 0.508
        },
        CRUSHBLOW_FLIGHT = {
            name = "Crushblow",
            faction = "HORDE",
            mapID = 1275,
            x = 0.4533,
            y = 0.7568
        },
        THE_GULLET_FLIGHT = {
            name = "The Gullet",
            faction = "HORDE",
            mapID = 1275,
            x = 0.3827,
            y = 0.3806
        },
        BLOODGULCH_FLIGHT = {
            name = "Bloodgulch",
            faction = "HORDE",
            mapID = 1275,
            x = 0.5475,
            y = 0.4266
        },
        THE_KRAZZWORKS_FLIGHT = {
            name = "The Krazzworks",
            faction = "HORDE",
            mapID = 1275,
            x = 0.7488,
            y = 0.1758
        },
        DRAGONMAW_PORT_FLIGHT = {
            name = "Dragonmaw Port Flightmaster",
            faction = "HORDE",
            mapID = 1275,
            x = 0.7347,
            y = 0.5254
        },
        -- Miscellaneous EK
        DARK_PORTAL_BL = {
            name = "The Dark Portal",
            mapID = 1246,
            x = 0.541,
            y = 0.512
        },
        SHATTERED_LANDING_FLIGHT = {
            name = "Shattered Landing",
            faction = "HORDE",
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
            faction = "HORDE",
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
            faction = "HORDE",
            mapID = 76,
            x = 0.4984,
            y = 0.5581
        },
        UNDERCITY = {
            name = "Entrance",
            category = "city",
            faction = "HORDE",
            mapID = 90,
            x = 0.663,
            y = 0.384
        },
        THE_BULWARK_FLIGHT = {
            name = "The Bulwark",
            faction = "HORDE",
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
        BIZMOS_BRAWLPUB = {
            name = "Bizmo's Brawlpub",
            faction = "ALLIANCE",
            mapID = 500,
            x = 0.511,
            y = 0.273
        },
        STORMWIND_CITY_MOLE = {
            name = "Stormwind (Eastern Kingdoms)",
            faction = "ALLIANCE",
            mapID = 84,
            x = 0.633,
            y = 0.373
        },
        IRONFORGE_MOLE = {
            name = "Ironforge (Eastern Kingdoms)",
            faction = "ALLIANCE",
            mapID = 27,
            x = 0.613,
            y = 0.372
        },
        BLACKROCK_MOUNTAIN_MOLE = {
            name = "Blackrock Mountain (Eastern Kingdoms - The Masonary)",
            faction = "ALLIANCE",
            mapID = 35,
            x = 0.332,
            y = 0.251
        },
        AERIE_PEAK_MOLE = {
            name = "Aerie Peak (Eastern Kingdoms)",
            faction = "ALLIANCE",
            mapID = 26,
            x = 0.134,
            y = 0.467
        },
        NETHERGARDE_KEEP_MOLE = {
            name = "Nethergarde Keep (Eastern Kingdoms)",
            faction = "ALLIANCE",
            mapID = 17,
            x = 0.620,
            y = 0.128
        },
        AERIE_PEAK_FLIGHT = {
            name = "Aerie Peak",
            faction = "ALLIANCE",
            mapID = 26,
            x = 0.108,
            y = 0.470
        },
        ANDORHAL_FLIGHT_ALLIANCE = {
            name = "Andorhal",
            faction = "ALLIANCE",
            mapID = 22,
            x = 0.392,
            y = 0.695
        },
        ANDORHAL_FLIGHT_HORDE = {
            name = "Andorhal",
            faction = "HORDE",
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
            faction = "ALLIANCE",
            mapID = 210,
            x = 0.414,
            y = 0.744
        },
        BOOTY_BAY_FLIGHT_HORDE = {
            name = "Booty Bay",
            faction = "HORDE",
            mapID = 210,
            x = 0.4015,
            y = 0.7328
        },
        HARDWRENCH_HIDEAWAY_FLIGHT = {
            name = "Hardwrench Hideaway",
            faction = "HORDE",
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
            faction = "ALLIANCE",
            mapID = 49,
            x = 0.538,
            y = 0.551
        },
        CHILLWIND_CAMP_FLIGHT = {
            name = "Chillwind Camp",
            faction = "ALLIANCE",
            mapID = 22,
            x = 0.421,
            y = 0.836
        },
        DARKSHIRE_FLIGHT = {
            name = "Darkshire",
            faction = "ALLIANCE",
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
            faction = "ALLIANCE",
            mapID = 15,
            x = 0.222,
            y = 0.588
        },
        DUN_MODR_FLIGHT = {
            name = "Dun Modr",
            faction = "ALLIANCE",
            mapID = 56,
            x = 0.500,
            y = 0.185
        },
        DUSTWIND_DIG_FLIGHT = {
            name = "Dustwind Dig",
            faction = "ALLIANCE",
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
            faction = "ALLIANCE",
            mapID = 37,
            x = 0.821,
            y = 0.656
        },
        EXPLORERS_LEAGUE_DIGSITE_FLIGHT = {
            name = "Explorers' League Digsite",
            faction = "ALLIANCE",
            mapID = 210,
            x = 0.560,
            y = 0.424
        },
        FARSTRIDER_LODGE_FLIGHT = {
            name = "Farstrider Lodge",
            faction = "ALLIANCE",
            mapID = 48,
            x = 0.836,
            y = 0.637
        },
        FIREBEARDS_PATROL_FLIGHT = {
            name = "Firebeard's Patrol",
            faction = "ALLIANCE",
            mapID = 241,
            x = 0.602,
            y = 0.585
        },
        FORT_LIVINGSTON_FLIGHT = {
            name = "Fort Livingston",
            faction = "ALLIANCE",
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
            faction = "ALLIANCE",
            mapID = 52,
            x = 0.506,
            y = 0.186
        },
        GOLBOLAR_QUARRY_FLIGHT = {
            name = "Gol'Bolar Quarry",
            faction = "ALLIANCE",
            mapID = 27,
            x = 0.768,
            y = 0.537
        },
        GOLDSHIRE_FLIGHT = {
            name = "Goldshire",
            faction = "ALLIANCE",
            mapID = 37,
            x = 0.422,
            y = 0.654
        },
        GREENWARDENS_GROVE_FLIGHT = {
            name = "Greenwarden's Grove",
            faction = "ALLIANCE",
            mapID = 56,
            x = 0.553,
            y = 0.417
        },
        HIGHBANK_FLIGHT = {
            name = "Highbank Flightmaster",
            faction = "ALLIANCE",
            mapID = 241,
            x = 0.813,
            y = 0.766
        },
        IRONFORGE_FLIGHT = {
            name = "Flightmaster",
            category = "city",
            faction = "ALLIANCE",
            mapID = 87,
            x = 0.557,
            y = 0.479
        },
        KHARANOS_FLIGHT = {
            name = "Kharanos",
            faction = "ALLIANCE",
            mapID = 27,
            x = 0.544,
            y = 0.525
        },
        LAKESHIRE_FLIGHT = {
            name = "Lakeshire",
            faction = "ALLIANCE",
            mapID = 49,
            x = 0.292,
            y = 0.532
        },
        LIGHTS_HOPE_CHAPEL_FLIGHT_ALLIANCE = {
            name = "Light's Hope Chapel",
            faction = "ALLIANCE",
            mapID = 23,
            x = 0.754,
            y = 0.534
        },
        LIGHTS_HOPE_CHAPEL_FLIGHT_HORDE = {
            name = "Light's Hope Chapel",
            faction = "HORDE",
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
            faction = "ALLIANCE",
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
            faction = "ALLIANCE",
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
            faction = "ALLIANCE",
            mapID = 52,
            x = 0.416,
            y = 0.631
        },
        MORGANS_VIGIL_FLIGHT = {
            name = "Morgan's Vigil",
            faction = "ALLIANCE",
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
            faction = "ALLIANCE",
            mapID = 47,
            x = 0.205,
            y = 0.576
        },
        REBEL_CAMP_FLIGHT = {
            name = "Rebel Camp",
            faction = "ALLIANCE",
            mapID = 50,
            x = 0.479,
            y = 0.118
        },
        SENTINEL_HILL_FLIGHT = {
            name = "Sentinel Hill",
            faction = "ALLIANCE",
            mapID = 52,
            x = 0.560,
            y = 0.491
        },
        SHALEWIND_CANYON_FLIGHT = {
            name = "Shalewind Canyon",
            faction = "ALLIANCE",
            mapID = 49,
            x = 0.776,
            y = 0.649
        },
        SHATTERED_BEACHHEAD_FLIGHT = {
            name = "Shattered Beachhead",
            faction = "ALLIANCE",
            mapID = 17,
            x = 0.673,
            y = 0.275
        },
        SLABCHISELS_SURVEY_FLIGHT = {
            name = "Slabchisel's Survey",
            faction = "ALLIANCE",
            mapID = 56,
            x = 0.577,
            y = 0.715
        },
        STORMFEATHER_OUTPOST_FLIGHT = {
            name = "Stormfeather Outpost",
            faction = "ALLIANCE",
            mapID = 26,
            x = 0.662,
            y = 0.447
        },
        STORMWIND_FLIGHT = {
            name = "Flightmaster",
            category = "city",
            faction = "ALLIANCE",
            mapID = 84,
            x = 0.713,
            y = 0.724
        },
        THE_HARBORAGE_FLIGHT = {
            name = "The Harborage",
            faction = "ALLIANCE",
            mapID = 51,
            x = 0.294,
            y = 0.334
        },
        THELSAMAR_FLIGHT = {
            name = "Thelsamar",
            faction = "ALLIANCE",
            mapID = 48,
            x = 0.340,
            y = 0.506
        },
        THORIUM_POINT_FLIGHT_ALLIANCE = {
            name = "Thorium Point",
            faction = "ALLIANCE",
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
            faction = "ALLIANCE",
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
            faction = "ALLIANCE",
            mapID = 241,
            x = 0.434,
            y = 0.570
        },
        -- Arathi Highlands (EK_OVERWORLD)
        REFUGE_POINTE_FLIGHT = {
            name = "Refuge Pointe",
            faction = "ALLIANCE",
            mapID = 14,
            x = 0.3944,
            y = 0.4725
        },
        -- Twilight Highlands (EK_OVERWORLD)
        KIRTHAVEN_FLIGHT = {
            name = "Kirthaven",
            faction = "ALLIANCE",
            mapID = 1275,
            x = 0.5781,
            y = 0.1582
        },
        -- Silverpine Forest (EK_OVERWORLD)
        THE_SEPULCHER_FLIGHT = {
            name = "The Sepulcher",
            faction = "HORDE",
            mapID = 21,
            x = 0.4521,
            y = 0.4230
        },
        THE_FORSAKEN_FRONT_FLIGHT = {
            name = "The Forsaken Front",
            faction = "HORDE",
            mapID = 21,
            x = 0.4992,
            y = 0.6367
        },
        FORSAKEN_REAR_GUARD_FLIGHT = {
            name = "Forsaken Rear Guard",
            faction = "HORDE",
            mapID = 21,
            x = 0.4580,
            y = 0.2164
        },
        FORSAKEN_HIGH_COMMAND_FLIGHT = {
            name = "Forsaken High Command",
            faction = "HORDE",
            mapID = 21,
            x = 0.5781,
            y = 0.1034
        },
        -- Hillsbrad Foothills (EK_OVERWORLD)
        TARREN_MILL_FLIGHT = {
            name = "Tarren Mill",
            faction = "HORDE",
            mapID = 25,
            x = 0.5581,
            y = 0.4583
        },
        STRAHNBRAD_FLIGHT = {
            name = "Strahnbrad",
            faction = "HORDE",
            mapID = 25,
            x = 0.5851,
            y = 0.2429
        },
        EASTPOINT_TOWER_FLIGHT = {
            name = "Eastpoint Tower",
            faction = "HORDE",
            mapID = 25,
            x = 0.5934,
            y = 0.6349
        },
        RUINS_OF_SOUTHSHORE_FLIGHT = {
            name = "Ruins of Southshore",
            faction = "HORDE",
            mapID = 25,
            x = 0.4886,
            y = 0.6526
        },
        SOUTHPOINT_GATE_FLIGHT = {
            name = "Southpoint Gate",
            faction = "HORDE",
            mapID = 25,
            x = 0.2838,
            y = 0.6402
        },
        -- Arathi Highlands (EK_OVERWORLD)
        HAMMERFALL_FLIGHT = {
            name = "Hammerfall",
            faction = "HORDE",
            mapID = 14,
            x = 0.6864,
            y = 0.3400
        },
        -- Stranglethorn Vale (EK_OVERWORLD)
        GROMGOL_FLIGHT = {
            name = "Grom'gol",
            faction = "HORDE",
            mapID = 50,
            x = 0.3874,
            y = 0.5103
        },
        BAMBALA_FLIGHT = {
            name = "Bambala",
            faction = "HORDE",
            mapID = 50,
            x = 0.6146,
            y = 0.3902
        },
        -- Badlands (EK_OVERWORLD)
        NEW_KARGATH_FLIGHT = {
            name = "New Kargath",
            faction = "HORDE",
            mapID = 15,
            x = 0.1719,
            y = 0.4107
        },
        -- Swamp of Sorrows (EK_OVERWORLD)
        STONARD_FLIGHT = {
            name = "Stonard",
            faction = "HORDE",
            mapID = 51,
            x = 0.4674,
            y = 0.5484
        },
        -- Burning Steppes (EK_OVERWORLD)
        FLAME_CREST_FLIGHT = {
            name = "Flame Crest",
            faction = "HORDE",
            mapID = 36,
            x = 0.5581,
            y = 0.2447
        },
        -- Searing Gorge (EK_OVERWORLD)
        THORIUM_POINT_FLIGHT_HORDE = {
            name = "Thorium Point",
            faction = "HORDE",
            mapID = 32,
            x = 0.3721,
            y = 0.2772
        },
        -- The Hinterlands (EK_OVERWORLD)
        REVANTUSK_VILLAGE_FLIGHT = {
            name = "Revantusk Village",
            faction = "HORDE",
            mapID = 26,
            x = 0.8065,
            y = 0.8115
        },
        HIRIWATHA_RESEARCH_STATION_FLIGHT = {
            name = "Hiri'watha Research Station",
            faction = "HORDE",
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
            faction = "HORDE",
            mapID = 15,
            x = 0.5216,
            y = 0.5254
        },
        WHELGARS_RETREAT_FLIGHT = {
            name = "Whelgar's Retreat",
            faction = "ALLIANCE",
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
            faction = "ALLIANCE",
            mapID = 204,
            x = 0.578,
            y = 0.786
        },
        TRANQUIL_WASH_FLIGHT = {
            name = "Tranquil Wash",
            faction = "ALLIANCE",
            mapID = 205,
            x = 0.487,
            y = 0.576
        },
        SANDY_BEACH_FLIGHT_ALLIANCE = {
            name = "Sandy Beach",
            faction = "ALLIANCE",
            mapID = 205,
            x = 0.569,
            y = 0.173
        },
        SANDY_BEACH_FLIGHT_HORDE = {
            name = "Sandy Beach",
            faction = "HORDE",
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
            faction = "HORDE",
            mapID = 205,
            x = 0.5027,
            y = 0.6639
        },
        STYGIAN_BOUNTY_FLIGHT = {
            name = "Stygian Bounty",
            faction = "HORDE",
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
            faction = "ALLIANCE",
            mapID = 205,
            x = 0.566,
            y = 0.756
        },
        TENEBROUS_CAVERN_PORTAL = {
            name = "Tenebrous Cavern Portal",
            faction = "HORDE",
            mapID = 204,
            x = 0.6004,
            y = 0.5625
        },
        TENEBROUS_CAVERN_FLIGHT = {
            name = "Tenebrous Cavern",
            faction = "HORDE",
            mapID = 204,
            x = 0.6004,
            y = 0.5625
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
            y = 0.2391
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
            mapID = 204, -- Abyssal Depths
            x = 0.700,
            y = 0.300
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
        BASTION_OF_TWILIGHT = {
            name = "Bastion of Twilight",
            category = "raid",
            mapID = 241,
            x = 0.340,
            y = 0.770
        }
    },
    TOL_BARAD = {
        TOL_BARAD_ALLIANCE = {
            name = "Tol Barad Camp",
            faction = "ALLIANCE",
            mapID = 245,
            x = 0.724,
            y = 0.562
        },
        TOL_BARAD_HORDE = {
            name = "Tol Barad Camp",
            faction = "HORDE",
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
    },

    DEEPHOLM = {
        DEEPHOLM_STORMWIND_PORTAL = {
            name = "Stormwind Portal",
            faction = "ALLIANCE",
            mapID = 207,
            x = 0.4855,
            y = 0.5380
        },
        DEEPHOLM_ORGRIMMAR_PORTAL = {
            name = "Orgrimmar Portal",
            faction = "HORDE",
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
    },

    FOUNDERS_POINT = {
        FOUNDERS_POINT = {
            name = "Entrance Portal",
            faction = "ALLIANCE",
            mapID = 2352,
            x = 0.574,
            y = 0.268
        }
    },

    KALIMDOR_OVERWORLD = {
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
        -- Horde Cities & Zones
        ORGRIMMAR_PORTAL_ROOM = {
            name = "Portal Room",
            faction = "HORDE",
            mapID = 85,
            x = 0.5710,
            y = 0.8981
        },
        WESTERN_EARTHSHRINE_OG = {
            name = "Western Earthshrine",
            faction = "HORDE",
            mapID = 85,
            x = 0.5007,
            y = 0.3779
        },
        ORGRIMMAR_ZEP = {
            name = "Zeppelin Tower",
            mapID = 85,
            x = 0.4827,
            y = 0.5791
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
    },

    TELDRASSIL = {
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
    },

    DRAENEI_HOME = {
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
    },

    RAZORWIND_SHORES = {
        RAZORWIND_SHORES = {
            name = "Entrance Portal",
            faction = "HORDE",
            mapID = 2351,
            x = 0.540,
            y = 0.496
        }
    },

    OUTLAND = {
        -- Dark Portal
        DARK_PORTAL_OUTLAND = {
            name = "The Dark Portal",
            mapID = 100,
            x = 0.892,
            y = 0.502
        },
        -- Hub
        SHATTRATH_OUTLAND = {
            name = "Shattrath",
            mapID = 111,
            x = 0.5497,
            y = 0.4023
        },
        SHATTRATH_OUTLAND_FLIGHT = {
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
            faction = "ALLIANCE",
            mapID = 100,
            x = 0.561,
            y = 0.631
        },
        BLADES_EDGE_MOUNTAINS_MOLE = {
            name = "Blade's Edge Mountains (Outland - Skald)",
            faction = "ALLIANCE",
            mapID = 105,
            x = 0.725,
            y = 0.176
        },
        SHADOWMOON_VALLEY_OUTLAND_MOLE = {
            name = "Shadowmoon Valley (Outland - Fel Pits)",
            faction = "ALLIANCE",
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
            faction = "ALLIANCE",
            mapID = 105,
            x = 0.607,
            y = 0.704
        },
        SYLVANAAR_FLIGHT = {
            name = "Sylvanaar",
            faction = "ALLIANCE",
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
            faction = "ALLIANCE",
            mapID = 102,
            x = 0.407,
            y = 0.279
        },
        TELREDOR_FLIGHT = {
            name = "Telredor",
            faction = "ALLIANCE",
            mapID = 102,
            x = 0.677,
            y = 0.516
        },
        TEMPLE_OF_TELHAMAT_FLIGHT = {
            name = "Temple of Telhamat",
            faction = "ALLIANCE",
            mapID = 100,
            x = 0.251,
            y = 0.392
        },
        HONOR_HOLD_FLIGHT = {
            name = "Honor Hold",
            faction = "ALLIANCE",
            mapID = 100,
            x = 0.556,
            y = 0.616
        },
        SHATTER_POINT_FLIGHT = {
            name = "Shatter Point",
            faction = "ALLIANCE",
            mapID = 100,
            x = 0.782,
            y = 0.349
        },
        HELLFIRE_PENINSULA_FLIGHT_ALLIANCE = {
            name = "Dark Portal Flightmaster",
            faction = "ALLIANCE",
            mapID = 100,
            x = 0.874,
            y = 0.494
        },
        HELLFIRE_PENINSULA_FLIGHT_HORDE = {
            name = "Dark Portal Flightmaster",
            faction = "HORDE",
            mapID = 100,
            x = 0.8747,
            y = 0.4908
        },
        SPINEBREAKER_RIDGE_FLIGHT = {
            name = "Spinebreaker Ridge",
            faction = "HORDE",
            mapID = 100,
            x = 0.6134,
            y = 0.8140
        },
        TELAAR_FLIGHT = {
            name = "Telaar",
            faction = "ALLIANCE",
            mapID = 107,
            x = 0.540,
            y = 0.728
        },
        ALLERIAN_STRONGHOLD_FLIGHT = {
            name = "Allerian Stronghold",
            faction = "ALLIANCE",
            mapID = 108,
            x = 0.592,
            y = 0.552
        },
        WILDHAMMER_STRONGHOLD_FLIGHT = {
            name = "Wildhammer Stronghold",
            faction = "ALLIANCE",
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
        -- Hellfire Peninsula (OUTLAND)
        THRALLMAR_FLIGHT = {
            name = "Thrallmar",
            faction = "HORDE",
            mapID = 100,
            x = 0.5734,
            y = 0.3708
        },
        FALCON_WATCH_FLIGHT = {
            name = "Falcon Watch",
            faction = "HORDE",
            mapID = 100,
            x = 0.2802,
            y = 0.6109
        },
        -- Zangarmarsh (OUTLAND)
        ZABRAJIN_FLIGHT = {
            name = "Zabra'jin",
            faction = "HORDE",
            mapID = 102,
            x = 0.3238,
            y = 0.5095
        },
        SWAMPRAT_POST_FLIGHT = {
            name = "Swamprat Post",
            faction = "HORDE",
            mapID = 102,
            x = 0.8606,
            y = 0.5325
        },
        -- Nagrand - Outland (OUTLAND)
        GARADAR_FLIGHT = {
            name = "Garadar",
            faction = "HORDE",
            mapID = 107,
            x = 0.5793,
            y = 0.3584
        },
        -- Shadowmoon Valley - Outland (OUTLAND)
        SHADOWMOON_VILLAGE_FLIGHT = {
            name = "Shadowmoon Village",
            faction = "HORDE",
            mapID = 104,
            x = 0.3109,
            y = 0.2924
        },
        -- Blade's Edge Mountains (OUTLAND)
        THUNDERLORD_STRONGHOLD_FLIGHT = {
            name = "Thunderlord Stronghold",
            faction = "HORDE",
            mapID = 105,
            x = 0.5157,
            y = 0.5360
        },
        MOKNATHAL_VILLAGE_FLIGHT = {
            name = "Mok'Nathal Village",
            faction = "HORDE",
            mapID = 105,
            x = 0.7594,
            y = 0.6561
        },
        -- Terokkar Forest (OUTLAND)
        STONEBREAKER_HOLD_FLIGHT = {
            name = "Stonebreaker Hold",
            faction = "HORDE",
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
    },

    NORTHREND = {
        DALARAN_NORTHREND = {
            name = "Dalaran (Northrend)",
            mapID = 125,
            x = 0.559,
            y = 0.468
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
    },

    PANDARIA = {
        PAWDON_VILLAGE_PORTAL = {
            name = "Paw'Don Village Portal",
            mapID = 371,
            x = 0.462,
            y = 0.851
        },
        SHRINE_OF_SEVEN_STARS = {
            name = "Shrine of Seven Stars",
            faction = "ALLIANCE",
            mapID = 390,
            x = 0.863,
            y = 0.611
        },
        SHRINE_OF_TWO_MOONS = {
            name = "Shrine of Two Moons",
            faction = "HORDE",
            mapID = 390,
            x = 0.6250,
            y = 0.2182
        },
        PEARLFIN_VILLAGE_FLIGHT = {
            name = "Pearlfin Village",
            faction = "ALLIANCE",
            mapID = 371,
            x = 0.588,
            y = 0.834
        },
        TIAN_MONASTERY_FLIGHT = {
            name = "Tian Monastery",
            mapID = 371,
            x = 0.444,
            y = 0.255
        },
        EMPERORS_OMEN_FLIGHT = {
            name = "Emperor's Omen",
            mapID = 371,
            x = 0.516,
            y = 0.276
        },
        SRILA_VILLAGE_FLIGHT = {
            name = "Sri-La Village",
            mapID = 371,
            x = 0.562,
            y = 0.243
        },
        DAWNS_BLOSSOM_FLIGHT = {
            name = "Dawn's Blossom",
            mapID = 371,
            x = 0.478,
            y = 0.470
        },
        THE_ARBORETUM_FLIGHT = {
            name = "The Arboretum",
            mapID = 371,
            x = 0.579,
            y = 0.450
        },
        SERPENTS_OVERLOOK_FLIGHT = {
            name = "Serpent's Overlook",
            mapID = 371,
            x = 0.429,
            y = 0.682
        },
        JADE_TEMPLE_GROUNDS_FLIGHT = {
            name = "Jade Temple Grounds",
            mapID = 371,
            x = 0.555,
            y = 0.627
        },
        VALLEY_OF_THE_FOUR_WINDS_MOLE = {
            name = "Valley of the Four Winds (Stormstout Brewery)",
            faction = "ALLIANCE",
            mapID = 376,
            x = 0.315,
            y = 0.736
        },
        KUN_LAI_SUMMIT_MOLE = {
            name = "Kun-Lai Summit (One Keg)",
            faction = "ALLIANCE",
            mapID = 379,
            x = 0.577,
            y = 0.628
        },
        PAWDON_VILLAGE_FLIGHT = {
            name = "Paw'Don Village",
            faction = "ALLIANCE",
            mapID = 371,
            x = 0.469,
            y = 0.861
        },
        LIONS_LANDING_FLIGHT = {
            name = "Lion's Landing",
            faction = "ALLIANCE",
            mapID = 418,
            x = 0.880,
            y = 0.344
        },
        THE_INCURSION_FLIGHT = {
            name = "The Incursion",
            faction = "ALLIANCE",
            mapID = 418,
            x = 0.676,
            y = 0.322
        },
        MARISTA_FLIGHT = {
            name = "Marista",
            mapID = 418,
            x = 0.524,
            y = 0.766
        },
        CRADLE_OF_CHIJI_FLIGHT = {
            name = "Cradle of Chi-Ji",
            mapID = 418,
            x = 0.310,
            y = 0.626
        },
        ZHUS_WATCH_FLIGHT = {
            name = "Zhu's Watch",
            mapID = 418,
            x = 0.766,
            y = 0.086
        },
        SENTINEL_BASECAMP_FLIGHT = {
            name = "Sentinel Basecamp",
            faction = "ALLIANCE",
            mapID = 418,
            x = 0.249,
            y = 0.332
        },
        THE_LIONS_REDOUBT_FLIGHT = {
            name = "The Lion's Redoubt",
            faction = "ALLIANCE",
            mapID = 422,
            x = 0.735,
            y = 0.329
        },
        KLAXXIVESS_FLIGHT = {
            name = "Klaxxi'vess",
            mapID = 422,
            x = 0.558,
            y = 0.348
        },
        THE_SUNSET_BREWGARDEN_FLIGHT = {
            name = "The Sunset Brewgarden",
            mapID = 422,
            x = 0.501,
            y = 0.123
        },
        THE_BRINY_MUCK_FLIGHT = {
            name = "The Briny Muck",
            mapID = 422,
            x = 0.424,
            y = 0.553
        },
        SOGGYS_GAMBLE_FLIGHT = {
            name = "Soggy's Gamble",
            mapID = 422,
            x = 0.460,
            y = 0.698
        },
        SHRINE_OF_SEVEN_STARS_FLIGHT = {
            name = "Shrine of Seven Stars",
            category = "city",
            faction = "ALLIANCE",
            mapID = 390,
            x = 0.850,
            y = 0.601
        },
        SHRINE_OF_TWO_MOONS_FLIGHT = {
            name = "Shrine of Two Moons",
            category = "city",
            faction = "HORDE",
            mapID = 390,
            x = 0.6281,
            y = 0.2181
        },
        SERPENTS_SPINE_FLIGHT_ALLIANCE = {
            name = "Serpent's Spine",
            faction = "ALLIANCE",
            mapID = 390,
            x = 0.136,
            y = 0.772
        },
        SERPENTS_SPINE_FLIGHT_HORDE = {
            name = "Serpent's Spine",
            faction = "HORDE",
            mapID = 379,
            x = 0.3577,
            y = 0.8358
        },
        EASTWIND_REST_FLIGHT = {
            name = "Eastwind Rest",
            faction = "HORDE",
            mapID = 379,
            x = 0.6205,
            y = 0.8062
        },
        MISTFALL_VILLAGE_FLIGHT = {
            name = "Mistfall Village",
            mapID = 390,
            x = 0.388,
            y = 0.724
        },
        WESTWIND_REST_FLIGHT = {
            name = "Westwind Rest",
            faction = "ALLIANCE",
            mapID = 379,
            x = 0.537,
            y = 0.842
        },
        WINTERS_BLOSSOM_FLIGHT = {
            name = "Winter's Blossom",
            mapID = 379,
            x = 0.345,
            y = 0.590
        },
        KOTA_BASECAMP_FLIGHT = {
            name = "Kota Basecamp",
            mapID = 379,
            x = 0.424,
            y = 0.694
        },
        SHADOPAN_FALLBACK_FLIGHT = {
            name = "Shado-Pan Fallback",
            mapID = 379,
            x = 0.438,
            y = 0.893
        },
        ONE_KEG_FLIGHT = {
            name = "One Keg",
            mapID = 379,
            x = 0.577,
            y = 0.595
        },
        BINAN_VILLAGE_FLIGHT = {
            name = "Binan Village",
            mapID = 379,
            x = 0.725,
            y = 0.942
        },
        TEMPLE_OF_THE_WHITE_TIGER_FLIGHT = {
            name = "Temple of the White Tiger",
            mapID = 379,
            x = 0.662,
            y = 0.506
        },
        ZOUCHIN_VILLAGE_FLIGHT = {
            name = "Zouchin Village",
            mapID = 379,
            x = 0.624,
            y = 0.299
        },
        PANGS_STEAD_FLIGHT = {
            name = "Pang's Stead",
            mapID = 376,
            x = 0.843,
            y = 0.210
        },
        GRASSY_CLINE_FLIGHT = {
            name = "Grassy Cline",
            mapID = 376,
            x = 0.706,
            y = 0.240
        },
        HALFHILL_FLIGHT = {
            name = "Halfhill",
            mapID = 376,
            x = 0.563,
            y = 0.501
        },
        STONEPLOW_FLIGHT = {
            name = "Stoneplow",
            mapID = 376,
            x = 0.200,
            y = 0.582
        },
        TAVERN_IN_THE_MISTS_FLIGHT = {
            name = "Tavern in the Mists",
            mapID = 433,
            x = 0.566,
            y = 0.754
        },
        LONGYING_OUTPOST_FLIGHT = {
            name = "Longying Outpost",
            mapID = 388,
            x = 0.710,
            y = 0.571
        },
        GAORAN_BATTLEFRONT_FLIGHT = {
            name = "Gao-Ran Battlefront",
            mapID = 388,
            x = 0.742,
            y = 0.811
        },
        RENSAIS_WATCHPOST_FLIGHT = {
            name = "Rensai's Watchpost",
            mapID = 388,
            x = 0.540,
            y = 0.788
        },
        -- Jade Forest (PANDARIA)
        GROOKIN_HILL_FLIGHT = {
            name = "Grookin Hill",
            faction = "HORDE",
            mapID = 371,
            x = 0.2838,
            y = 0.4891
        },
        HONEYDEW_VILLAGE_FLIGHT = {
            name = "Honeydew Village",
            faction = "HORDE",
            mapID = 371,
            x = 0.2744,
            y = 0.1571
        },
        HONEYDEW_VILLAGE = {
            name = "Honeydew Village",
            faction = "HORDE",
            mapID = 371,
            x = 0.2826,
            y = 0.1359
        },
        -- Krasarang Wilds (PANDARIA)
        THUNDER_CLEFT_FLIGHT = {
            name = "Thunder Cleft",
            faction = "HORDE",
            mapID = 418,
            x = 0.5887,
            y = 0.2436
        },
        DOMINATION_POINT_FLIGHT = {
            name = "Domination Point",
            faction = "HORDE",
            mapID = 418,
            x = 0.0943,
            y = 0.5244
        },
        DAWNCHASER_RETREAT_FLIGHT = {
            name = "Dawnchaser Retreat",
            faction = "HORDE",
            mapID = 418,
            x = 0.2850,
            y = 0.5050
        },
        SHADOPAN_GARRISON_FLIGHT = {
            name = "Shado-Pan Garrison",
            mapID = 388,
            x = 0.498,
            y = 0.716
        },
        SHADOPAN_ISLE_OF_THUNDER_PORTAL_HORDE = {
            name = "Isle of Thunder Portal",
            faction = "HORDE",
            mapID = 388,
            x = 0.5065,
            y = 0.7336
        },
        SHADOPAN_ISLE_OF_THUNDER_PORTAL_ALLIANCE = {
            name = "Isle of Thunder Portal",
            faction = "ALLIANCE",
            mapID = 388,
            x = 0.4974,
            y = 0.6871
        },
        -- Dungeons
        TEMPLE_OF_THE_JADE_SERPENT_DUNGEON = {
            name = "Temple of the Jade Serpent",
            category = "dungeon",
            mapID = 371, -- The Jade Forest
            x = 0.560,
            y = 0.580
        },
        STORMSTOUT_BREWERY_DUNGEON = {
            name = "Stormstout Brewery",
            category = "dungeon",
            mapID = 376, -- Valley of the Four Winds
            x = 0.360,
            y = 0.690
        },
        SHADOPAN_MONASTERY_DUNGEON = {
            name = "Shado-Pan Monastery",
            category = "dungeon",
            mapID = 379, -- Kun-Lai Summit
            x = 0.370,
            y = 0.480
        },
        MOGUSHAN_PALACE_DUNGEON = {
            name = "Mogu'shan Palace",
            category = "dungeon",
            mapID = 390, -- Vale of Eternal Blossoms
            x = 0.790,
            y = 0.340
        },
        GATE_OF_THE_SETTING_SUN_DUNGEON = {
            name = "Gate of the Setting Sun",
            category = "dungeon",
            mapID = 390, -- Vale of Eternal Blossoms
            x = 0.160,
            y = 0.740
        },
        SIEGE_OF_NIUZAO_TEMPLE_DUNGEON = {
            name = "Siege of Niuzao Temple",
            category = "dungeon",
            mapID = 388, -- Townlong Steppes
            x = 0.350,
            y = 0.820
        },
        -- Raids
        MOGUSHAN_VAULTS_RAID = {
            name = "Mogu'shan Vaults",
            category = "raid",
            mapID = 379, -- Kun-Lai Summit
            x = 0.600,
            y = 0.390
        },
        HEART_OF_FEAR_RAID = {
            name = "Heart of Fear",
            category = "raid",
            mapID = 422, -- Dread Wastes
            x = 0.400,
            y = 0.340
        },
        TERRACE_OF_ENDLESS_SPRING_RAID = {
            name = "Terrace of Endless Spring",
            category = "raid",
            mapID = 433, -- The Veiled Stair
            x = 0.490,
            y = 0.620
        },
        SIEGE_OF_ORGRIMMAR_RAID = {
            name = "Siege of Orgrimmar",
            category = "raid",
            mapID = 390, -- Vale of Eternal Blossoms
            x = 0.740,
            y = 0.420
        },
        NYALOTHA_THE_WAKING_CITY_RAID_PANDARIA = {
            name = "Ny'alotha, the Waking City (Pandaria)",
            category = "raid",
            mapID = 390, -- Vale of Eternal Blossoms
            x = 0.570,
            y = 0.480
        }
    },

    ISLE_OF_THUNDER = {
        KIRIN_TOR_BASE = {
            name = "Kirin Tor Base",
            faction = "ALLIANCE",
            mapID = 504,
            x = 0.6408,
            y = 0.7248
        },
        SUNREAVER_BASE = {
            name = "Sunreaver Base",
            faction = "HORDE",
            mapID = 504,
            x = 0.3262,
            y = 0.3425
        },
        -- Raids
        THRONE_OF_THUNDER_RAID = {
            name = "Throne of Thunder",
            category = "raid",
            mapID = 504,
            x = 0.630,
            y = 0.320
        }
    },

    BROKEN_ISLES = {
        AZSUNA = {
            name = "Faronaar",
            mapID = 630,
            x = 0.4682,
            y = 0.4136
        },
        DALARAN_BROKEN_ISLES = {
            name = "Dalaran (Broken Isles)",
            mapID = 627,
            x = 0.609,
            y = 0.447
        },
        DALARAN_BROKEN_ISLES_FLIGHT = {
            name = "Dalaran (Broken Isles) Flightmaster",
            category = "city",
            mapID = 627,
            x = 0.6985,
            y = 0.5108
        },
        DALARAN_BROKEN_ISLES_PORTAL_ALLIANCE = {
            name = "Dalaran (Broken Isles) Portal",
            faction = "ALLIANCE",
            mapID = 627,
            x = 0.3908,
            y = 0.6280
        },
        DALARAN_BROKEN_ISLES_PORTAL_HORDE = {
            name = "Dalaran (Broken Isles) Portal",
            faction = "HORDE",
            mapID = 627,
            x = 0.5781,
            y = 0.1924
        },
        DALARAN_BROKEN_ISLES_PET = {
            name = "Dalaran Pet Shop",
            mapID = 627,
            x = 0.5835,
            y = 0.3960
        },
        VALSHARAH = {
            name = "Lorlathil Portal",
            faction = "ALLIANCE",
            mapID = 641,
            x = 0.548,
            y = 0.730
        },
        VALSHARAH_DRUID = {
            name = "The Dreamgrove",
            mapID = 747,
            x = 0.5430,
            y = 0.2497
        },
        THE_BROKEN_SHORE = {
            name = "Aalgen Point",
            mapID = 646,
            x = 0.717,
            y = 0.480
        },
        THE_BROKEN_SHORE_MOLE = {
            name = "Allgen Point",
            faction = "ALLIANCE",
            mapID = 646,
            x = 0.717,
            y = 0.480
        },
        HIGHMOUNTAIN_MOLE = {
            name = "Frosthoof Watch",
            faction = "ALLIANCE",
            mapID = 650,
            x = 0.446,
            y = 0.729
        },
        FELBANE_CAMP_FLIGHT = {
            name = "Felbane Camp",
            mapID = 650,
            x = 0.2967,
            y = 0.3923
        },
        SHIPWRECK_COVE_FLIGHT = {
            name = "Shipwreck Cove",
            mapID = 650,
            x = 0.4172,
            y = 0.1013
        },
        PREPFOOT_FLIGHT = {
            name = "Prepfoot",
            mapID = 650,
            x = 0.5779,
            y = 0.2838
        },
        SKYHORN_FLIGHT = {
            name = "Skyhorn",
            mapID = 650,
            x = 0.5251,
            y = 0.4508
        },
        NESINGWARYS_RETREAT_FLIGHT = {
            name = "Nesingwary's Retreat",
            mapID = 650,
            x = 0.4034,
            y = 0.5231
        },
        THE_WITCHWOOD_FLIGHT = {
            name = "The Witchwood",
            mapID = 650,
            x = 0.3828,
            y = 0.3888
        },
        SYLVAN_FALLS_FLIGHT = {
            name = "Sylvan Falls",
            mapID = 650,
            x = 0.3587,
            y = 0.6574
        },
        OBSIDIAN_OVERLOOK_FLIGHT = {
            name = "Obsidian Overlook",
            mapID = 650,
            x = 0.4735,
            y = 0.8451
        },
        THUNDER_TOTEM_FLIGHT = {
            name = "Thunder Totem",
            mapID = 650,
            x = 0.4689,
            y = 0.5920
        },
        STONEHOOF_WATCH_FLIGHT = {
            name = "Stonehoof Watch",
            mapID = 650,
            x = 0.5917,
            y = 0.6505
        },
        IRONHORN_ENCLAVE_FLIGHT = {
            name = "Ironhorn Enclave",
            mapID = 650,
            x = 0.5664,
            y = 0.8399
        },
        SKYFIRE_TRIAGE_CAMP_FLIGHT = {
            name = "Skyfire Triage Camp",
            faction = "ALLIANCE",
            mapID = 634,
            x = 0.333,
            y = 0.505
        },
        LORNAS_WATCH_FLIGHT = {
            name = "Lorna's Watch",
            faction = "ALLIANCE",
            mapID = 634,
            x = 0.371,
            y = 0.637
        },
        GREYWATCH_FLIGHT = {
            name = "Greywatch",
            faction = "ALLIANCE",
            mapID = 634,
            x = 0.720,
            y = 0.598
        },
        STORMTORN_FOOTHILLS_FLIGHT = {
            name = "Stormtorn Foothills",
            mapID = 634,
            x = 0.5205,
            y = 0.3465
        },
        HAFR_FJALL_FLIGHT = {
            name = "Hafr Fjall",
            mapID = 634,
            x = 0.5538,
            y = 0.8733
        },
        VALDISDALL_FLIGHT = {
            name = "Valdisdall",
            mapID = 634,
            x = 0.6032,
            y = 0.5083
        },
        SHIELDS_REST_FLIGHT = {
            name = "Shield's Rest",
            mapID = 634,
            x = 0.8958,
            y = 0.1037
        },
        DELIVERANCE_POINT_FLIGHT = {
            name = "Deliverance Point",
            mapID = 646,
            x = 0.4494,
            y = 0.6392
        },
        VENGEANCE_POINT_FLIGHT = {
            name = "Vengeance Point",
            mapID = 646,
            x = 0.4976,
            y = 0.2088
        },
        AALGEN_POINT_FLIGHT = {
            name = "Aalgen Point",
            mapID = 646,
            x = 0.7053,
            y = 0.4722
        },
        WARDENS_REDOUBT_FLIGHT = {
            name = "Wardens' Redoubt",
            mapID = 630,
            x = 0.4815,
            y = 0.7270
        },
        -- Azsuna (BROKEN_ISLES)
        WATCHERS_AERIE_FLIGHT = {
            name = "Watchers' Aerie",
            mapID = 630,
            x = 0.5157,
            y = 0.8203
        },
        SHACKLES_DEN_FLIGHT = {
            name = "Shackle's Den",
            mapID = 630,
            x = 0.5618,
            y = 0.5858
        },
        ILLIDARI_STAND_FLIGHT = {
            name = "Illidari Stand",
            mapID = 630,
            x = 0.4448,
            y = 0.4377
        },
        ILLIDARI_PERCH_FLIGHT = {
            name = "Illidari Perch",
            mapID = 630,
            x = 0.3174,
            y = 0.4618
        },
        AZUREWING_REPOSE_FLIGHT = {
            name = "Azurewing Repose",
            mapID = 630,
            x = 0.4815,
            y = 0.2793
        },
        CHALLIANES_TERRACE_FLIGHT = {
            name = "Challiane's Terrace",
            mapID = 630,
            x = 0.4057,
            y = 0.0917
        },
        FELBLAZE_INGRESS_FLIGHT = {
            name = "Felblaze Ingress",
            mapID = 630,
            x = 0.6364,
            y = 0.2845
        },
        IRONGROVE_RETREAT_FLIGHT = {
            name = "Irongrove Retreat",
            mapID = 680,
            x = 0.2542,
            y = 0.3182
        },
        MEREDIL_FLIGHT = {
            name = "Meredil",
            mapID = 680,
            x = 0.3403,
            y = 0.4956
        },
        CRIMSON_THICKET_FLIGHT = {
            name = "Crimson Thicket",
            mapID = 680,
            x = 0.6410,
            y = 0.4181
        },
        GLOAMING_REEF_FLIGHT = {
            name = "Gloaming Reef",
            mapID = 641,
            x = 0.2600,
            y = 0.6626
        },
        BRADENSBROOK_FLIGHT = {
            name = "Bradensbrook",
            mapID = 641,
            x = 0.4230,
            y = 0.5851
        },
        LORLATHIL_FLIGHT = {
            name = "Lorlathil",
            mapID = 641,
            x = 0.5458,
            y = 0.7228
        },
        GARDEN_OF_THE_MOON_FLIGHT = {
            name = "Garden of the Moon",
            mapID = 641,
            x = 0.5664,
            y = 0.5799
        },
        -- Stormheim (BROKEN_ISLES)
        FORSAKEN_FOOTHOLD_FLIGHT = {
            name = "Forsaken Foothold",
            faction = "HORDE",
            mapID = 634,
            x = 0.3615,
            y = 0.3072
        },
        DREADWAKES_LANDING_FLIGHT = {
            name = "Dreadwake's Landing",
            faction = "HORDE",
            mapID = 634,
            x = 0.5416,
            y = 0.7275
        },
        CULLENS_POST_FLIGHT = {
            name = "Cullen's Post",
            faction = "HORDE",
            mapID = 634,
            x = 0.4483,
            y = 0.5902
        },
        STARSONG_REFUGE_FLIGHT = {
            name = "Starsong Refuge",
            mapID = 641,
            x = 0.6881,
            y = 0.5110
        },
        -- Dungeons
        BLACK_ROOK_HOLD_DUNGEON = {
            name = "Black Rook Hold",
            category = "dungeon",
            mapID = 641, -- Val'sharah
            x = 0.390,
            y = 0.530
        },
        DARKHEART_THICKET_DUNGEON = {
            name = "Darkheart Thicket",
            category = "dungeon",
            mapID = 641, -- Val'sharah
            x = 0.590,
            y = 0.310
        },
        COURT_OF_STARS_DUNGEON = {
            name = "Court of Stars",
            category = "dungeon",
            mapID = 680, -- Suramar
            x = 0.510,
            y = 0.650
        },
        THE_ARCWAY_DUNGEON = {
            name = "The Arcway",
            category = "dungeon",
            mapID = 680, -- Suramar
            x = 0.510,
            y = 0.650
        },
        EYE_OF_AZSHARA_DUNGEON = {
            name = "Eye of Azshara",
            category = "dungeon",
            mapID = 630, -- Azsuna
            x = 0.620,
            y = 0.410
        },
        HALLS_OF_VALOR_DUNGEON = {
            name = "Halls of Valor",
            category = "dungeon",
            mapID = 634, -- Stormheim
            x = 0.680,
            y = 0.660
        },
        MAW_OF_SOULS_DUNGEON = {
            name = "Maw of Souls",
            category = "dungeon",
            mapID = 634, -- Stormheim
            x = 0.530,
            y = 0.470
        },
        NELTHARIONS_LAIR_DUNGEON = {
            name = "Neltharion's Lair",
            category = "dungeon",
            mapID = 650, -- Highmountain
            x = 0.500,
            y = 0.680
        },
        VAULT_OF_THE_WARDENS_DUNGEON = {
            name = "Vault of the Wardens",
            category = "dungeon",
            mapID = 630, -- Azsuna
            x = 0.480,
            y = 0.830
        },
        ASSAULT_ON_VIOLET_HOLD_DUNGEON = {
            name = "Assault on Violet Hold",
            category = "dungeon",
            mapID = 627, -- Dalaran
            x = 0.660,
            y = 0.680
        },
        CATHEDRAL_OF_ETERNAL_NIGHT_DUNGEON = {
            name = "Cathedral of Eternal Night",
            category = "dungeon",
            mapID = 646, -- Broken Shore
            x = 0.650,
            y = 0.170
        },

        -- Raids
        THE_EMERALD_NIGHTMARE_RAID = {
            name = "The Emerald Nightmare",
            category = "raid",
            mapID = 641, -- Val'sharah
            x = 0.587,
            y = 0.400
        },
        TRIAL_OF_VALOR_RAID = {
            name = "Trial of Valor",
            category = "raid",
            mapID = 634, -- Stormheim
            x = 0.710,
            y = 0.730
        },
        THE_NIGHTHOLD_RAID = {
            name = "The Nighthold",
            category = "raid",
            mapID = 680, -- Suramar
            x = 0.440,
            y = 0.600
        },
        TOMB_OF_SARGERAS_RAID = {
            name = "Tomb of Sargeras",
            category = "raid",
            mapID = 646, -- Broken Shore
            x = 0.640,
            y = 0.210
        }
    },

    EYE_OF_AZSHARA = {
        EYE_OF_AZSHARA_FLIGHT = {
            name = "Eye of Azshara Flightmaster",
            mapID = 790,
            x = 0.3816,
            y = 0.4567
        }
    },

    DRAGON_ISLES = {
        VALDRAKKEN = {
            name = "Portal Room",
            mapID = 2112,
            x = 0.596,
            y = 0.414
        },
        VALDRAKKEN_FLIGHT = {
            name = "Flightmaster",
            category = "city",
            mapID = 2112,
            x = 0.4436,
            y = 0.6798
        },
        VALDRAKKEN_BADLANDS_PORTAL = {
            name = "Badlands Portal",
            mapID = 2112,
            x = 0.2597,
            y = 0.4078
        },
        BELAMETH = {
            name = "Bel'ameth",
            faction = "ALLIANCE",
            mapID = 2239,
            x = 0.5493,
            y = 0.6388
        },
        BELAMETH_FLIGHT = {
            name = "Bel'ameth Flightmaster",
            mapID = 2239,
            x = 0.5010,
            y = 0.5582
        },
        BELANAAR = {
            name = "Belanaar",
            faction = "ALLIANCE",
            mapID = 2239,
            x = 0.514,
            y = 0.158
        },
        AMIRDRASSIL_DRUID = {
            name = "Amirdrassil",
            mapID = 2239,
            x = 0.5834,
            y = 0.8477
        },
        THE_WAKING_SHORES_MOLE = {
            name = "The Waking Shores (The Slagmire)",
            faction = "ALLIANCE",
            mapID = 2022,
            x = 0.323,
            y = 0.549
        },
        WAKING_SHORES_DOCK = {
            name = "Alliance Dock",
            mapID = 2022,
            x = 0.8194,
            y = 0.3065
        },
        AZURE_SPAN_MOLE = {
            name = "The Azure Span (Vakthros Summit)",
            faction = "ALLIANCE",
            mapID = 2024,
            x = 0.801,
            y = 0.390
        },
        ZARALEK_CAVERN_MOLE = {
            name = "Zaralek Cavern (Obsidian Rest)",
            faction = "ALLIANCE",
            mapID = 2133,
            x = 0.527,
            y = 0.277
        },
        MORQUT_VILLAGE_FLIGHT = {
            name = "Morqut Village",
            mapID = 2151,
            x = 0.3552,
            y = 0.5920
        },
        OBSIDIAN_THRONE_FLIGHT = {
            name = "Obsidian Throne",
            mapID = 2022,
            x = 0.2428,
            y = 0.5851
        },
        APEX_OBSERVATORY_FLIGHT = {
            name = "Apex Observatory",
            mapID = 2022,
            x = 0.2370,
            y = 0.8313
        },
        UKTULUT_OUTPOST_FLIGHT = {
            name = "Uktulut Outpost",
            mapID = 2022,
            x = 0.1739,
            y = 0.8881
        },
        OBSIDIAN_BULWARK_FLIGHT = {
            name = "Obsidian Bulwark",
            mapID = 2022,
            x = 0.4230,
            y = 0.6626
        },
        RUBY_LIFE_POOLS_FLIGHT = {
            name = "Ruby Life Pools",
            mapID = 2022,
            x = 0.5766,
            y = 0.6797
        },
        DRAGONSCALE_BASECAMP_FLIGHT = {
            name = "Dragonscale Basecamp",
            mapID = 2022,
            x = 0.4772,
            y = 0.8337
        },
        LIFE_VAULT_RUINS_FLIGHT = {
            name = "Life Vault Ruins",
            mapID = 2022,
            x = 0.6514,
            y = 0.5713
        },
        SKYTOP_OBSERVATORY_FLIGHT = {
            name = "Skytop Observatory",
            mapID = 2022,
            x = 0.7283,
            y = 0.5197
        },
        WINGREST_EMBASSY_FLIGHT = {
            name = "Wingrest Embassy",
            mapID = 2022,
            x = 0.7604,
            y = 0.3509
        },
        UKTULUT_BACKWATER_FLIGHT = {
            name = "Uktulut Backwater",
            mapID = 2022,
            x = 0.5412,
            y = 0.3716
        },
        UKTULUT_PIER_FLIGHT = {
            name = "Uktulut Pier",
            mapID = 2022,
            x = 0.4574,
            y = 0.2717
        },
        SHADY_SANCTUARY_FLIGHT = {
            name = "Shady Sanctuary",
            mapID = 2023,
            x = 0.3001,
            y = 0.5806
        },
        TEERAKAI_FLIGHT = {
            name = "Teerakai",
            mapID = 2023,
            x = 0.3989,
            y = 0.6099
        },
        BROADHOOF_OUTPOST_FLIGHT = {
            name = "Broadhoof Outpost",
            mapID = 2023,
            x = 0.4643,
            y = 0.4154
        },
        OHNIRI_SPRINGS_FLIGHT = {
            name = "Ohn'iri Springs",
            mapID = 2023,
            x = 0.5664,
            y = 0.7648
        },
        FORKRIVER_CROSSING_FLIGHT = {
            name = "Forkriver Crossing",
            mapID = 2023,
            x = 0.7133,
            y = 0.7890
        },
        PINEWOOD_POST_FLIGHT = {
            name = "Pinewood Post",
            mapID = 2023,
            x = 0.8052,
            y = 0.5755
        },
        RUSZATHAR_REACH_FLIGHT = {
            name = "Rusza'thar Reach",
            mapID = 2023,
            x = 0.8741,
            y = 0.3691
        },
        MARUUKAI_FLIGHT = {
            name = "Maruukai",
            mapID = 2023,
            x = 0.6319,
            y = 0.4171
        },
        EMBERWATCH_FLIGHT = {
            name = "Emberwatch",
            mapID = 2023,
            x = 0.6674,
            y = 0.2501
        },
        TIMBERSTEP_OUTPOST_FLIGHT = {
            name = "Timberstep Outpost",
            mapID = 2023,
            x = 0.8499,
            y = 0.2380
        },
        THREEFALLS_LOOKOUT_FLIGHT = {
            name = "Three-Falls Lookout",
            mapID = 2024,
            x = 0.1923,
            y = 0.2373
        },
        AZURE_ARCHIVES_FLIGHT = {
            name = "Azure Archives",
            mapID = 2024,
            x = 0.3702,
            y = 0.6082
        },
        CAMP_ANTONIDAS_FLIGHT = {
            name = "Camp Antonidas",
            mapID = 2024,
            x = 0.4654,
            y = 0.3981
        },
        COBALT_ASSEMBLY_FLIGHT = {
            name = "Cobalt Assembly",
            mapID = 2024,
            x = 0.4884,
            y = 0.2253
        },
        RHONINS_SHIELD_FLIGHT = {
            name = "Rhonin's Shield",
            mapID = 2024,
            x = 0.6594,
            y = 0.2545
        },
        THERONS_WATCH_FLIGHT = {
            name = "Theron's Watch",
            mapID = 2024,
            x = 0.6514,
            y = 0.1633
        },
        CAMP_NOWHERE_FLIGHT = {
            name = "Camp Nowhere",
            mapID = 2024,
            x = 0.6341,
            y = 0.5851
        },
        GARDEN_SHRINE_FLIGHT = {
            name = "Garden Shrine",
            mapID = 2025,
            x = 0.3564,
            y = 0.7890
        },
        GELIKYR_POST_FLIGHT = {
            name = "Gelikyr Post",
            mapID = 2025,
            x = 0.5113,
            y = 0.6702
        },
        SHIFTING_SANDS_FLIGHT = {
            name = "Shifting Sands",
            mapID = 2025,
            x = 0.5733,
            y = 0.7907
        },
        VAULT_OF_THE_INCARNATES_FLIGHT = {
            name = "Vault of the Incarnates",
            mapID = 2025,
            x = 0.7191,
            y = 0.5634
        },
        VEILED_OSSUARY_FLIGHT = {
            name = "Veiled Ossuary",
            mapID = 2025,
            x = 0.6192,
            y = 0.1915
        },
        ALGETHERA_FLIGHT = {
            name = "Algeth'era",
            mapID = 2025,
            x = 0.4941,
            y = 0.4205
        },
        DRAGONSCALE_CAMP_FLIGHT = {
            name = "Dragonscale Camp",
            mapID = 2133,
            x = 0.4023,
            y = 0.6753
        },
        LOAMM_FLIGHT = {
            name = "Loamm",
            mapID = 2133,
            x = 0.4023,
            y = 0.6753
        },
        -- Azure Span (DRAGON_ISLES)
        ISKAARA_FLIGHT = {
            name = "Iskaara",
            mapID = 2024,
            x = 0.1310,
            y = 0.4888
        },
        -- Thaldraszus (DRAGON_ISLES)
        TEMPORAL_CONFLUX_FLIGHT = {
            name = "Temporal Conflux",
            mapID = 2025,
            x = 0.5982,
            y = 0.8136
        },
        OBSIDIAN_REST_FLIGHT = {
            name = "Obsidian Rest",
            mapID = 2133,
            x = 0.5102,
            y = 0.2587
        },
        -- Dungeons
        RUBY_LIFE_POOLS_DUNGEON = {
            name = "Ruby Life Pools",
            category = "dungeon",
            mapID = 2022, -- The Waking Shores
            x = 0.600,
            y = 0.750
        },
        THE_NOKHUD_OFFENSIVE_DUNGEON = {
            name = "The Nokhud Offensive",
            category = "dungeon",
            mapID = 2023, -- Ohn'ahran Plains
            x = 0.610,
            y = 0.390
        },
        BRACKENHIDE_HOLLOW_DUNGEON = {
            name = "Brackenhide Hollow",
            category = "dungeon",
            mapID = 2024, -- The Azure Span
            x = 0.110,
            y = 0.480
        },
        HALLS_OF_INFUSION_DUNGEON = {
            name = "Halls of Infusion",
            category = "dungeon",
            mapID = 2025, -- Thaldraszus
            x = 0.590,
            y = 0.600
        },
        NELTHARUS_DUNGEON = {
            name = "Neltharus",
            category = "dungeon",
            mapID = 2022, -- The Waking Shores
            x = 0.250,
            y = 0.560
        },
        ALGETHAR_ACADEMY_DUNGEON = {
            name = "Algeth'ar Academy",
            category = "dungeon",
            mapID = 2025, -- Thaldraszus
            x = 0.580,
            y = 0.420
        },
        THE_AZURE_VAULT_DUNGEON = {
            name = "The Azure Vault",
            category = "dungeon",
            mapID = 2024, -- The Azure Span
            x = 0.380,
            y = 0.640
        },
        DAWN_OF_THE_INFINITES_DUNGEON = {
            name = "Dawn of the Infinites",
            category = "dungeon",
            mapID = 2025, -- Thaldraszus
            x = 0.610,
            y = 0.840
        },

        -- Raids
        VAULT_OF_THE_INCARNATES_RAID = {
            name = "Vault of the Incarnates",
            category = "raid",
            mapID = 2025, -- Thaldraszus
            x = 0.730,
            y = 0.550
        },
        ABERRUS_THE_SHADOWED_CRUCIBLE_RAID = {
            name = "Aberrus, the Shadowed Crucible",
            category = "raid",
            mapID = 2133, -- Zaralek Cavern
            x = 0.480,
            y = 0.110
        }
    },

    EMERALD_DREAM = {
        AMIRDRASSIL = {
            name = "Amirdrassil",
            mapID = 2200,
            x = 0.506,
            y = 0.625
        },
        WELLSPRING_OVERLOOK_FLIGHT = {
            name = "Wellspring Overlook",
            mapID = 2200,
            x = 0.3564,
            y = 0.3362
        },
        EYE_OF_YSERA_FLIGHT = {
            name = "Eye of Ysera",
            mapID = 2200,
            x = 0.5538,
            y = 0.2931
        },
        CENTRAL_ENCAMPMENT_FLIGHT = {
            name = "Central Encampment",
            mapID = 2200,
            x = 0.5111,
            y = 0.6219
        },
        VERDANT_LANDING_FLIGHT = {
            name = "Verdant Landing",
            mapID = 2200,
            x = 0.6873,
            y = 0.5458
        },
        -- Raids
        AMIRDRASSIL_THE_DREAMS_HOPE_RAID = {
            name = "Amirdrassil, the Dream's Hope",
            category = "raid",
            mapID = 2200,
            x = 0.280,
            y = 0.310
        }
    },

    KHAZ_ALGAR = {
        DORNOGAL_PORTAL_ROOM = {
            name = "Portal Room",
            mapID = 2339,
            x = 0.4127,
            y = 0.2743
        },
        DORNOGAL_FLIGHT = {
            name = "Flightmaster",
            category = "city",
            mapID = 2339,
            x = 0.4471,
            y = 0.5100
        },
        DORNOGAL_UNDERMINE_PORTAL = {
            name = "Undermine Portal",
            mapID = 2339,
            x = 0.523,
            y = 0.507
        },
        DORNOGAL_AZJKAHET_PORTAL = {
            name = "Azj-Kahet Portal",
            mapID = 2339,
            x = 0.636,
            y = 0.521
        },
        DORNOGAL_KARESH_PORTAL = {
            name = "Karesh Portal",
            mapID = 2339,
            x = 0.404,
            y = 0.404
        },
        DORNOGAL_DELVE_HALL = {
            name = "Delver's Office",
            mapID = 2339,
            x = 0.4946,
            y = 0.4441
        },
        AZJKAHET = {
            name = "The Weaver's Lair",
            mapID = 2255,
            x = 0.574,
            y = 0.418
        },
        TRANQUIL_STRAND_FLIGHT = {
            name = "Tranquil Strand",
            mapID = 2248,
            x = 0.2967,
            y = 0.5816
        },
        RAMBLESHIRE_FLIGHT = {
            name = "Rambleshire",
            mapID = 2248,
            x = 0.5905,
            y = 0.2855
        },
        DURGAZ_CABIN_FLIGHT = {
            name = "Durgaz Cabin",
            mapID = 2248,
            x = 0.6732,
            y = 0.4353
        },
        FREYWOLD_VILLAGE_FLIGHT = {
            name = "Freywold Village",
            mapID = 2248,
            x = 0.4092,
            y = 0.7287
        },
        SHADOWVEIN_POINT_FLIGHT = {
            name = "Shadowvein Point",
            mapID = 2214,
            x = 0.5710,
            y = 0.4791
        },
        CAMP_MURROCH_FLIGHT = {
            name = "Camp Murroch",
            mapID = 2214,
            x = 0.5400,
            y = 0.6392
        },
        OPPORTUNITY_POINT_FLIGHT = {
            name = "Opportunity Point",
            mapID = 2214,
            x = 0.6020,
            y = 0.7821
        },
        GUTTERVILLE_FLIGHT = {
            name = "Gutterville",
            mapID = 2214,
            x = 0.7110,
            y = 0.8337
        },
        GUNDARGAZ_FLIGHT = {
            name = "Gundargaz",
            mapID = 2214,
            x = 0.4275,
            y = 0.3342
        },
        PRIORY_OF_THE_SACRED_FLAME_FLIGHT = {
            name = "Priory of the Sacred Flame",
            mapID = 2215,
            x = 0.4069,
            y = 0.3389
        },
        LORELS_CROSSING_FLIGHT = {
            name = "Lorel's Crossing",
            mapID = 2215,
            x = 0.4803,
            y = 0.4060
        },
        HILLHELM_FAMILY_FARM_FLIGHT = {
            name = "Hillhelm Family Farm",
            mapID = 2215,
            x = 0.6089,
            y = 0.3062
        },
        THE_AEGIS_WALL_FLIGHT = {
            name = "The Aegis Wall",
            mapID = 2215,
            x = 0.7110,
            y = 0.5644
        },
        LIGHTSPARK_FLIGHT = {
            name = "Lightspark",
            mapID = 2215,
            x = 0.5272,
            y = 0.6139
        },
        LIGHTS_REDOUBT_FLIGHT = {
            name = "Light's Redoubt",
            mapID = 2215,
            x = 0.4034,
            y = 0.7108
        },
        MERELDAR_FLIGHT = {
            name = "Mereldar",
            mapID = 2215,
            x = 0.4143,
            y = 0.5247
        },
        FAERINS_ADVANCE_FLIGHT = {
            name = "Faerin's Advance",
            mapID = 2255,
            x = 0.5951,
            y = 0.1881
        },
        WILDCAMP_ORLAY_FLIGHT = {
            name = "Wildcamp Or'lay",
            mapID = 2255,
            x = 0.2313,
            y = 0.5135
        },
        WILDCAMP_ULAR_FLIGHT = {
            name = "Wildcamp Ul'ar",
            mapID = 2255,
            x = 0.4436,
            y = 0.6702
        },
        MMARL_FLIGHT = {
            name = "Mmarl",
            mapID = 2255,
            x = 0.7684,
            y = 0.6426
        },
        WEAVERS_LAIR_FLIGHT = {
            name = "Weaver's Lair",
            mapID = 2255,
            x = 0.5689,
            y = 0.4676
        },
        -- Hallowfall (KHAZ_ALGAR)
        DUNELLES_KINDNESS_FLIGHT = {
            name = "Dunelle's Kindness",
            mapID = 2215,
            x = 0.6728,
            y = 0.4460
        },
        THE_BURROWS_FLIGHT = {
            name = "The Burrows",
            mapID = 2216,
            x = 0.5389,
            y = 0.4498
        },
        GUTTERVILLE_ROCKET = {
            name = "Gutterville Rocket",
            mapID = 2214,
            x = 0.7271,
            y = 0.7321
        },
        -- Dungeons
        ARA_KARA_CITY_OF_ECHOES_DUNGEON = {
            name = "Ara-Kara, City of Echoes",
            category = "dungeon",
            mapID = 2255,
            x = 0.490,
            y = 0.810
        },
        THE_DAWNBREAKER_DUNGEON = {
            name = "The Dawnbreaker",
            category = "dungeon",
            mapID = 2215,
            x = 0.547,
            y = 0.629
        },
        PRIORY_OF_THE_SACRED_FLAME_DUNGEON = {
            name = "Priory of the Sacred Flame",
            category = "dungeon",
            mapID = 2215,
            x = 0.412,
            y = 0.496
        },
        OPERATION_FLOODGATE_DUNGEON = {
            name = "Operation: Floodgate",
            category = "dungeon",
            mapID = 2214,
            x = 0.4209,
            y = 0.3948
        },
        THE_ROOKERY_DUNGEON = {
            name = "The Rookery",
            category = "dungeon",
            mapID = 2339,
            x = 0.317,
            y = 0.358
        },
        THE_STONEVAULT_DUNGEON = {
            name = "The Stonevault",
            category = "dungeon",
            mapID = 2248, -- Isle of Dorn
            x = 0.420,
            y = 0.090
        },
        CITY_OF_THREADS_DUNGEON = {
            name = "City of Threads",
            category = "dungeon",
            mapID = 2255, -- Azj-Kahet
            x = 0.470,
            y = 0.690
        },
        DARKFLAME_CLEFT_DUNGEON = {
            name = "Darkflame Cleft",
            category = "dungeon",
            mapID = 2214, -- The Ringing Deeps
            x = 0.560,
            y = 0.210
        },
        CINDERBREW_MEADERY_DUNGEON = {
            name = "Cinderbrew Meadery",
            category = "dungeon",
            mapID = 2248, -- Isle of Dorn
            x = 0.760,
            y = 0.450
        },

        -- Raids
        NERUBAR_PALACE_RAID = {
            name = "Nerub-ar Palace",
            category = "raid",
            mapID = 2255, -- Azj-Kahet
            x = 0.350,
            y = 0.720
        }
    },

    UNDERMINE = {
        UNDERMINE = {
            name = "Dornogal Portal",
            mapID = 2346,
            x = 0.276,
            y = 0.538
        },
        UNDERMINE_ROCKET_LAUNCH = {
            name = "Rocket Launch",
            mapID = 2346,
            x = 0.1892,
            y = 0.5099
        },
        SLAM_CENTRAL_STATION_FLIGHT = {
            name = "Slam Central Station",
            mapID = 2346,
            x = 0.2439,
            y = 0.5221
        },
        THE_INCONTINENTAL_HOTEL_FLIGHT = {
            name = "The Incontinental Hotel",
            mapID = 2346,
            x = 0.4289,
            y = 0.4618
        },
        DEMOLITION_DOME_FLIGHT = {
            name = "Demolition Dome",
            mapID = 2346,
            x = 0.5791,
            y = 0.0882
        },
        THE_GALLAGIO_FLIGHT = {
            name = "The Gallagio",
            mapID = 2346,
            x = 0.6135,
            y = 0.4791
        },
        THE_HEAPS_FLIGHT = {
            name = "The Heaps",
            mapID = 2346,
            x = 0.4344,
            y = 0.7907
        },
        -- Raids
        LIBERATION_OF_UNDERMINE_RAID = {
            name = "Liberation of Undermine",
            category = "raid",
            mapID = 2346,
            x = 0.420,
            y = 0.490
        }
    },

    SL_ORIBOS = {
        ORIBOS = {
            name = "Entrance",
            mapID = 1670,
            x = 0.203,
            y = 0.503
        },
        ORIBOS_FLIGHT = {
            name = "Flightmaster",
            category = "city",
            mapID = 1671,
            x = 0.607,
            y = 0.684
        },
        ORIBOS_WORMHOLE = {
            name = "Oribos, The Eternal City",
            mapID = 1670,
            x = 0.5208,
            y = 0.2613
        }
    },
    SL_MALDRAXXUS = {
        MALDRAXXUS_MOLE = {
            name = "Valley of a Thousand Legs",
            faction = "ALLIANCE",
            mapID = 1536,
            x = 0.535,
            y = 0.598
        },
        MALDRAXXUS_WORMHOLE = {
            name = "Citadel of the Necrolords",
            mapID = 1536,
            x = 0.4244,
            y = 0.4399
        },
        THEATER_OF_PAIN_FLIGHT = {
            name = "Theater of Pain",
            mapID = 1536,
            x = 0.500,
            y = 0.532
        },
        BLEAK_REDOUBT_FLIGHT = {
            name = "Bleak Redoubt",
            mapID = 1536,
            x = 0.5274,
            y = 0.6746
        },
        SPIDERS_WATCH_FLIGHT = {
            name = "Spider's Watch",
            mapID = 1536,
            x = 0.3770,
            y = 0.2907
        },
        KERES_REST_FLIGHT = {
            name = "Keres' Rest",
            mapID = 1536,
            x = 0.5366,
            y = 0.3027
        },
        RENOUNCED_BASTILLE_FLIGHT = {
            name = "Renounced Bastille",
            mapID = 1536,
            x = 0.6789,
            y = 0.4594
        },
        PLAGUE_WATCH_FLIGHT = {
            name = "Plague Watch",
            mapID = 1536,
            x = 0.5813,
            y = 0.7211
        },
        THE_SPEARHEAD_FLIGHT = {
            name = "The Spearhead",
            mapID = 1536,
            x = 0.3897,
            y = 0.5524
        },
        -- Dungeons
        PLAGUEFALL_DUNGEON = {
            name = "Plaguefall",
            category = "dungeon",
            mapID = 1536, -- Maldraxxus
            x = 0.590,
            y = 0.650
        },
        THEATER_OF_PAIN_DUNGEON = {
            name = "Theater of Pain",
            category = "dungeon",
            mapID = 1536, -- Maldraxxus
            x = 0.530,
            y = 0.530
        }
    },
    SL_BASTION = {
        BASTION_MOLE = {
            name = "The Eternal Forge",
            faction = "ALLIANCE",
            mapID = 1533,
            x = 0.518,
            y = 0.132
        },
        BASTION_WORMHOLE = {
            name = "Home of the Kyrian",
            mapID = 1533,
            x = 0.5186,
            y = 0.8776
        },
        -- Bastion (SL_BASTION)
        ELYSIAN_HOLD_FLIGHT = {
            name = "Elysian Hold",
            category = "city",
            mapID = 1533,
            x = 0.6534,
            y = 0.1705
        },
        HEROS_REST_FLIGHT = {
            name = "Hero's Rest",
            mapID = 1533,
            x = 0.5136,
            y = 0.4663
        },
        SAGEHAVEN_FLIGHT = {
            name = "Sagehaven",
            mapID = 1533,
            x = 0.4390,
            y = 0.3234
        },
        TERRACE_OF_THE_COLLECTORS_FLIGHT = {
            name = "Terrace of the Collectors",
            mapID = 1536,
            x = 0.3564,
            y = 0.2098
        },
        ASPIRANTS_REST_FLIGHT = {
            name = "Aspirant's Rest",
            mapID = 1533,
            x = 0.481,
            y = 0.742
        },
        -- Dungeons
        NECROTIC_WAKE_DUNGEON = {
            name = "The Necrotic Wake",
            category = "dungeon",
            mapID = 1533, -- Bastion
            x = 0.400,
            y = 0.550
        },
        SPIRES_OF_ASCENSION_DUNGEON = {
            name = "Spires of Ascension",
            category = "dungeon",
            mapID = 1533, -- Bastion
            x = 0.580,
            y = 0.290
        }
    },
    SL_REVENDRETH = {
        REVENDRETH_MOLE = {
            name = "Scorched Crypt",
            faction = "ALLIANCE",
            mapID = 1525,
            x = 0.199,
            y = 0.388
        },
        REVENDRETH_WORMHOLE = {
            name = "Court of the Venthyr",
            mapID = 1525,
            x = 0.3750,
            y = 0.7655
        },
        -- Revendreth (SL_REVENDRETH)
        SINFALL_FLIGHT = {
            name = "Sinfall",
            category = "city",
            mapID = 1525,
            x = 0.2979,
            y = 0.3948
        },
        DARKHAVEN_FLIGHT = {
            name = "Darkhaven",
            mapID = 1525,
            x = 0.6066,
            y = 0.6040
        },
        WANECRYPT_HILL_FLIGHT = {
            name = "Wanecrypt Hill",
            mapID = 1525,
            x = 0.4769,
            y = 0.6918
        },
        HALLS_OF_ATONEMENT_FLIGHT = {
            name = "Halls of Atonement",
            mapID = 1525,
            x = 0.7143,
            y = 0.4012
        },
        MENAGERIE_OF_THE_MASTER_FLIGHT = {
            name = "Menagerie of the Master",
            mapID = 1525,
            x = 0.5423,
            y = 0.2562
        },
        OLD_GATE_FLIGHT = {
            name = "Old Gate",
            mapID = 1525,
            x = 0.6089,
            y = 0.3871
        },
        CHARRED_RAMPARTS_FLIGHT = {
            name = "Charred Ramparts",
            mapID = 1525,
            x = 0.3885,
            y = 0.4904
        },
        SANCTUARY_OF_THE_MAD_FLIGHT = {
            name = "Sanctuary of the Mad",
            mapID = 1525,
            x = 0.3059,
            y = 0.4869
        },
        DOMINANCE_KEEP_FLIGHT = {
            name = "Dominance Keep",
            mapID = 1525,
            x = 0.2600,
            y = 0.2907
        },
        PRIDEFALL_HAMLET_FLIGHT = {
            name = "Pridefall Hamlet",
            mapID = 1525,
            x = 0.703,
            y = 0.811
        },
        -- Dungeons
        HALLS_OF_ATONEMENT_DUNGEON = {
            name = "Halls of Atonement",
            category = "dungeon",
            mapID = 1525,
            x = 0.7846,
            y = 0.4905
        },
        SANGUINE_DEPTHS_DUNGEON = {
            name = "Sanguine Depths",
            category = "dungeon",
            mapID = 1525, -- Revendreth
            x = 0.510,
            y = 0.300
        },
        -- Raids
        CASTLE_NATHRIA_RAID = {
            name = "Castle Nathria",
            category = "raid",
            mapID = 1525, -- Revendreth
            x = 0.460,
            y = 0.410
        }
    },
    SL_ARDENWEALD = {
        ARDENWEALD_MOLE = {
            name = "Soryn's Meadow",
            faction = "ALLIANCE",
            mapID = 1565,
            x = 0.665,
            y = 0.505
        },
        ARDENWEALD_WORMHOLE = {
            name = "Forest of the Night Fae",
            mapID = 1565,
            x = 0.5443,
            y = 0.6033
        },
        -- Ardenweald (SL_ARDENWEALD)
        HEART_OF_THE_FOREST_FLIGHT = {
            name = "Heart of the Forest",
            category = "city",
            mapID = 1565,
            x = 0.4557,
            y = 0.5325
        },
        GLITTERFALL_BASIN_FLIGHT = {
            name = "Glitterfall Basin",
            mapID = 1565,
            x = 0.5159,
            y = 0.3423
        },
        REFUGEE_CAMP_FLIGHT = {
            name = "Refugee Camp",
            mapID = 1565,
            x = 0.4930,
            y = 0.5197
        },
        ROOTHOME_FLIGHT = {
            name = "Root-Home",
            mapID = 1565,
            x = 0.3518,
            y = 0.5145
        },
        CLAWS_EDGE_FLIGHT = {
            name = "Claw's Edge",
            mapID = 1565,
            x = 0.5136,
            y = 0.7090
        },
        HIBERNAL_HOLLOW_FLIGHT = {
            name = "Hibernal Hollow",
            mapID = 1565,
            x = 0.6032,
            y = 0.5334
        },
        TIRNA_VAAL_FLIGHT = {
            name = "Tirna Vaal",
            mapID = 1565,
            x = 0.634,
            y = 0.375
        },
        -- Dungeons
        MISTS_OF_TIRNA_SCITHE_DUNGEON = {
            name = "Mists of Tirna Scithe",
            category = "dungeon",
            mapID = 1565, -- Ardenweald
            x = 0.350,
            y = 0.540
        },
        DE_OTHER_SIDE_DUNGEON = {
            name = "De Other Side",
            category = "dungeon",
            mapID = 1565, -- Ardenweald
            x = 0.690,
            y = 0.660
        }
    },
    SL_ZM = {
        ZERETH_MORTIS = {
            name = "Entrance Portal",
            mapID = 1970,
            x = 0.333,
            y = 0.694
        },
        PILGRIMS_GRACE_FLIGHT = {
            name = "Pilgrim's Grace",
            mapID = 1970,
            x = 0.6135,
            y = 0.4990
        },
        ZOVAALS_GRASP_FLIGHT = {
            name = "Zovaal's Grasp",
            mapID = 1970,
            x = 0.4585,
            y = 0.2253
        },
        ANTECEDENT_ISLE_FLIGHT = {
            name = "Antecedent Isle",
            mapID = 1970,
            x = 0.4723,
            y = 0.1271
        },
        FAITHS_REPOSE_FLIGHT = {
            name = "Faith's Repose",
            mapID = 1970,
            x = 0.3552,
            y = 0.4491
        },
        HAVEN_FLIGHT = {
            name = "Haven",
            mapID = 1970,
            x = 0.3564,
            y = 0.6522
        },
        SEPULCHER_OVERLOOK_FLIGHT = {
            name = "Sepulcher Overlook",
            mapID = 1970,
            x = 0.6479,
            y = 0.5403
        },
        SEPULCHER_OF_THE_FIRST_ONES_FLIGHT = {
            name = "Sepulcher Of The First Ones",
            mapID = 1970,
            x = 0.7283,
            y = 0.5317
        },
        -- Raids
        SEPULCHER_OF_THE_FIRST_ONES_RAID = {
            name = "Sepulcher of the First Ones",
            category = "raid",
            mapID = 1970, -- Zereth Mortis
            x = 0.810,
            y = 0.530
        }
    },
    SL_THE_MAW = {
        KORTHIA = {
            name = "Entrance Portal",
            mapID = 1961,
            x = 0.644,
            y = 0.241
        },
        THE_MAW = {
            name = "Entrance",
            mapID = 1543,
            x = 0.450,
            y = 0.410
        },
        THE_MAW_WORMHOLE = {
            name = "Wasteland of the Damned",
            mapID = 1543,
            x = 0.2246,
            y = 0.2816
        },
        KORTHIA_WORMHOLE = {
            name = "Korthia (Wormhole)",
            mapID = 1961,
            x = 0.6241,
            y = 0.2458
        },
        VENARIS_REFUGE_FLIGHT = {
            name = "Ve'nari's Refuge",
            mapID = 1543,
            x = 0.4723,
            y = 0.4319
        },
        KEEPERS_RESPITE_FLIGHT = {
            name = "Keeper's Respite",
            mapID = 1961,
            x = 0.6502,
            y = 0.2380
        },
        -- Raids    
        SANCTUM_OF_DOMINATION_RAID = {
            name = "Sanctum of Domination",
            category = "raid",
            mapID = 1543, -- The Maw
            x = 0.690,
            y = 0.310
        }
    },

    VINDICAAR_AZEROTH = {
        VINDICAAR_AZEROTH = {
            name = "The Vindicaar (Azeroth)",
            faction = "ALLIANCE",
            mapID = 940,
            x = 0.750,
            y = 0.750
        }
    },
    DARK_IRON_CITY = {
        SHADOWFORGE_CITY_MOLE = {
            name = "Shadowforge City",
            faction = "ALLIANCE",
            mapID = 1186,
            x = 0.614,
            y = 0.244
        }
    },

    -- Special Zones
    TIMELESS_ISLE = {
        TIMELESS_ISLE = {
            name = "The Celestial Court",
            mapID = 554,
            x = 0.342,
            y = 0.553
        },
        TUSHUI_LANDING_FLIGHT = {
            name = "Tushui Landing",
            faction = "ALLIANCE",
            mapID = 554,
            x = 0.230,
            y = 0.710
        },
        HUOJIN_LANDING_FLIGHT = {
            name = "Huojin Landing",
            faction = "HORDE",
            mapID = 554,
            x = 0.225,
            y = 0.381
        },
        GRIM_CAMPFIRE_PANDARIA = {
            name = "Grim Campfire",
            mapID = 554,
            x = 0.6790,
            y = 0.7690
        }
    },

    ISLE_OF_GIANTS = {
        BEEBLES_WRECK_FLIGHT = {
            name = "Beeble's Wreck",
            faction = "ALLIANCE",
            mapID = 507,
            x = 0.416,
            y = 0.792
        },
        BOZZLES_WRECK_FLIGHT = {
            name = "Bozzle's Wreck",
            faction = "HORDE",
            mapID = 507,
            x = 0.5157,
            y = 0.7504
        }
    },

    QUELDANAS = {
        QUELDANAS = {
            name = "Entrance Portal",
            mapID = 122,
            x = 0.500,
            y = 0.366
        },
        SHATTERED_SUN_STAGING_AREA_FLIGHT = {
            name = "Shattered Sun Staging Area",
            mapID = 122,
            x = 0.474,
            y = 0.251
        },
        -- Dungeons
        MAGISTERS_TERRACE_DUNGEON = {
            name = "Magisters' Terrace",
            category = "dungeon",
            mapID = 122,
            x = 0.610,
            y = 0.310
        },
        -- Raids
        SUNWELL_PLATEAU_RAID = {
            name = "Sunwell Plateau",
            category = "raid",
            mapID = 122,
            x = 0.480,
            y = 0.420
        }
    },

    NAZJATAR = {
        NAZJATAR_ALLIANCE = {
            name = "Mezzamere",
            faction = "ALLIANCE",
            mapID = 1355,
            x = 0.3996,
            y = 0.5884
        },
        NAZJATAR_HORDE = {
            name = "Newhome",
            faction = "HORDE",
            mapID = 1355,
            x = 0.4719,
            y = 0.6263
        },
        ASHEN_STRAND_FLIGHT_ALLIANCE = {
            name = "Ashen Strand",
            faction = "ALLIANCE",
            mapID = 1355,
            x = 0.316,
            y = 0.382
        },
        ASHEN_STRAND_FLIGHT_HORDE = {
            name = "Ashen Strand",
            faction = "HORDE",
            mapID = 1355,
            x = 0.3426,
            y = 0.3690
        },
        MEZZAMERE_FLIGHT = {
            name = "Mezzamere",
            faction = "ALLIANCE",
            mapID = 1355,
            x = 0.399,
            y = 0.542
        },
        WRECK_OF_THE_OLD_BLANCHY_FLIGHT = {
            name = "Wreck of the Old Blanchy",
            faction = "ALLIANCE",
            mapID = 1355,
            x = 0.441,
            y = 0.857
        },
        THE_TIDAL_CONFLUX_FLIGHT_ALLIANCE = {
            name = "The Tidal Conflux",
            faction = "ALLIANCE",
            mapID = 1355,
            x = 0.496,
            y = 0.236
        },
        THE_TIDAL_CONFLUX_FLIGHT_HORDE = {
            name = "The Tidal Conflux",
            faction = "HORDE",
            mapID = 1355,
            x = 0.5086,
            y = 0.2376
        },
        UTAMAS_STAND_FLIGHT = {
            name = "Utama's Stand",
            faction = "ALLIANCE",
            mapID = 1355,
            x = 0.614,
            y = 0.366
        },
        ORISES_VIGIL_FLIGHT = {
            name = "Orise's Vigil",
            faction = "ALLIANCE",
            mapID = 1355,
            x = 0.736,
            y = 0.399
        },
        KELYAS_GRAVE_FLIGHT = {
            name = "Kelya's Grave",
            mapID = 1355,
            x = 0.7397,
            y = 0.2466
        },
        ZINAZSHARI_FLIGHT = {
            name = "Zin'Azshari",
            faction = "HORDE",
            mapID = 1355,
            x = 0.7912,
            y = 0.3806
        },
        EKKAS_HIDEAWAY_FLIGHT = {
            name = "Ekka's Hideaway",
            faction = "HORDE",
            mapID = 1355,
            x = 0.6358,
            y = 0.5166
        },
        NEWHOME_FLIGHT = {
            name = "Newhome",
            faction = "HORDE",
            mapID = 1355,
            x = 0.4721,
            y = 0.6314
        },
        WRECK_OF_THE_HUNGRY_RIVERBEAST_FLIGHT = {
            name = "Wreck of the Hungry Riverbeast",
            faction = "HORDE",
            mapID = 1355,
            x = 0.3568,
            y = 0.8263
        },
        -- Raids
        THE_ETERNAL_PALACE_RAID = {
            name = "The Eternal Palace",
            category = "raid",
            mapID = 1355, -- Nazjatar
            x = 0.500,
            y = 0.120
        }
    },

    KUL_TIRAS = {
        BORALUS = {
            name = "Portal Room",
            category = "city",
            faction = "ALLIANCE",
            mapID = 1161,
            x = 0.706,
            y = 0.170
        },
        BORALUS_PET = {
            name = "Pet Shop",
            faction = "ALLIANCE",
            mapID = 1161,
            x = 0.5002,
            y = 0.4677
        },
        BORALUS_DOCK = {
            name = "Dock",
            mapID = 1161,
            x = 0.6805,
            y = 0.2651
        },
        TORTOLLAN_BASE_CAMP = {
            name = "Seekers Vista",
            mapID = 942,
            x = 0.403,
            y = 0.365
        },
        TIRAGARDE_SOUND_MOLE = {
            name = "Wailing Tideways",
            faction = "ALLIANCE",
            mapID = 895,
            x = 0.882,
            y = 0.715
        },
        STORMSONG_VALLEY_MOLE = {
            name = "Tidebreak Summit",
            faction = "ALLIANCE",
            mapID = 942,
            x = 0.642,
            y = 0.294
        },
        TRADEWINDS_MARKET_FLIGHT = {
            name = "Tradewinds Market",
            faction = "ALLIANCE",
            mapID = 1161,
            x = 0.667,
            y = 0.151
        },
        PROUDMOORE_KEEP_FLIGHT = {
            name = "Proudmoore Keep",
            faction = "ALLIANCE",
            mapID = 1161,
            x = 0.475,
            y = 0.649
        },
        MARINERS_ROW_FLIGHT = {
            name = "Mariner's Row",
            faction = "ALLIANCE",
            mapID = 1161,
            x = 0.763,
            y = 0.728
        },
        HATHERFORD_FLIGHT = {
            name = "Hatherford",
            faction = "ALLIANCE",
            mapID = 895,
            x = 0.665,
            y = 0.231
        },
        NORWINGTON_ESTATE_FLIGHT = {
            name = "Norwington Estate",
            faction = "ALLIANCE",
            mapID = 895,
            x = 0.525,
            y = 0.286
        },
        ROUGHNECK_CAMP_FLIGHT = {
            name = "Roughneck Camp",
            faction = "ALLIANCE",
            mapID = 895,
            x = 0.418,
            y = 0.224
        },
        OUTRIGGER_POST_FLIGHT = {
            name = "Outrigger Post",
            faction = "ALLIANCE",
            mapID = 895,
            x = 0.353,
            y = 0.247
        },
        BRIDGEPORT_FLIGHT = {
            name = "Bridgeport",
            faction = "ALLIANCE",
            mapID = 895,
            x = 0.755,
            y = 0.488
        },
        KENNINGS_LODGE_FLIGHT = {
            name = "Kennings Lodge",
            faction = "ALLIANCE",
            mapID = 895,
            x = 0.763,
            y = 0.653
        },
        VIGIL_HILL_FLIGHT = {
            name = "Vigil Hill",
            faction = "ALLIANCE",
            mapID = 895,
            x = 0.580,
            y = 0.612
        },
        CASTAWAY_POINT_FLIGHT = {
            name = "Castaway Point",
            mapID = 895,
            x = 0.8626,
            y = 0.8106
        },
        BARBTHORN_RIDGE_FLIGHT = {
            name = "Barbthorn Ridge",
            faction = "ALLIANCE",
            mapID = 896,
            x = 0.624,
            y = 0.237
        },
        FALLHAVEN_FLIGHT = {
            name = "Fallhaven",
            faction = "ALLIANCE",
            mapID = 896,
            x = 0.549,
            y = 0.348
        },
        HANGMANS_POINT_FLIGHT = {
            name = "Hangman's Point",
            faction = "ALLIANCE",
            mapID = 896,
            x = 0.708,
            y = 0.403
        },
        FLETCHERS_HOLLOW_FLIGHT = {
            name = "Fletcher's Hollow",
            faction = "ALLIANCE",
            mapID = 896,
            x = 0.700,
            y = 0.601
        },
        WATCHMANS_RISE_FLIGHT = {
            name = "Watchman's Rise",
            faction = "ALLIANCE",
            mapID = 896,
            x = 0.316,
            y = 0.303
        },
        FALCONHURST_FLIGHT = {
            name = "Falconhurst",
            faction = "ALLIANCE",
            mapID = 896,
            x = 0.271,
            y = 0.721
        },
        AROMS_STAND_FLIGHT = {
            name = "Arom's Stand",
            faction = "ALLIANCE",
            mapID = 896,
            x = 0.380,
            y = 0.526
        },
        ANYPORT_FLIGHT = {
            name = "Anyport",
            mapID = 896,
            x = 0.1900,
            y = 0.4326
        },
        ANYPORT_DOCK = {
            name = "Anyport Dock",
            faction = "HORDE",
            mapID = 896,
            x = 0.2056,
            y = 0.4553
        },
        WHITEGROVE_CHAPEL_FLIGHT = {
            name = "Whitegrove Chapel",
            mapID = 896,
            x = 0.2565,
            y = 0.1640
        },
        MILLSTONE_HAMLET_FLIGHT = {
            name = "Millstone Hamlet",
            faction = "ALLIANCE",
            mapID = 942,
            x = 0.305,
            y = 0.664
        },
        FORT_DAELIN_FLIGHT = {
            name = "Fort Daelin",
            faction = "ALLIANCE",
            mapID = 942,
            x = 0.340,
            y = 0.468
        },
        DEADWASH_FLIGHT = {
            name = "Deadwash",
            faction = "ALLIANCE",
            mapID = 942,
            x = 0.426,
            y = 0.571
        },
        THE_AMBER_WAVES_FLIGHT = {
            name = "The Amber Waves",
            faction = "ALLIANCE",
            mapID = 942,
            x = 0.506,
            y = 0.700
        },
        BRENNADAM_FLIGHT = {
            name = "Brennadam",
            faction = "ALLIANCE",
            mapID = 942,
            x = 0.594,
            y = 0.702
        },
        MILDENHALL_MEADERY_FLIGHT = {
            name = "Mildenhall Meadery",
            faction = "ALLIANCE",
            mapID = 942,
            x = 0.685,
            y = 0.650
        },
        TIDECROSS_FLIGHT = {
            name = "Tidecross",
            faction = "ALLIANCE",
            mapID = 942,
            x = 0.654,
            y = 0.478
        },
        SHRINE_OF_THE_STORM_FLIGHT_ALLIANCE = {
            name = "Shrine of the Storm",
            faction = "ALLIANCE",
            mapID = 942,
            x = 0.779,
            y = 0.291
        },
        -- Stormsong Valley (KUL_TIRAS)
        SHRINE_OF_THE_STORM_FLIGHT_HORDE = {
            name = "Shrine of the Storm",
            faction = "HORDE",
            mapID = 942,
            x = 0.7759,
            y = 0.2383
        },
        HILLCREST_PASTURE_FLIGHT = {
            name = "Hillcrest Pasture",
            faction = "HORDE",
            mapID = 942,
            x = 0.5228,
            y = 0.7974
        },
        WINDFALL_CAVERN_FLIGHT = {
            name = "Windfall Cavern",
            faction = "HORDE",
            mapID = 942,
            x = 0.6052,
            y = 0.2736
        },
        DIRETUSK_HOLLOW_FLIGHT = {
            name = "Diretusk Hollow",
            faction = "HORDE",
            mapID = 942,
            x = 0.5404,
            y = 0.4891
        },
        IRONMAUL_OVERLOOK_FLIGHT = {
            name = "Ironmaul Overlook",
            faction = "HORDE",
            mapID = 942,
            x = 0.7570,
            y = 0.6392
        },
        STONETUSK_WATCH_FLIGHT = {
            name = "Stonetusk Watch",
            faction = "HORDE",
            mapID = 942,
            x = 0.3874,
            y = 0.6692
        },
        WARFANG_HOLD_FLIGHT = {
            name = "Warfang Hold",
            faction = "HORDE",
            mapID = 942,
            x = 0.5098,
            y = 0.3372
        },
        WARFANG_HOLD_DOCK = {
            name = "Warfang Hold Dock",
            faction = "HORDE",
            mapID = 942,
            x = 0.5193,
            y = 0.2434
        },
        -- Tiragarde Sound (KUL_TIRAS)
        FREEHOLD_FLIGHT = {
            name = "Freehold",
            mapID = 895,
            x = 0.7723,
            y = 0.8263
        },
        WOLFS_DEN_FLIGHT = {
            name = "Wolf's Den",
            faction = "HORDE",
            mapID = 895,
            x = 0.6169,
            y = 0.1341
        },
        WANING_GLACIER_FLIGHT = {
            name = "Waning Glacier",
            faction = "HORDE",
            mapID = 895,
            x = 0.3933,
            y = 0.1836
        },
        STONEFIST_WATCH_FLIGHT = {
            name = "Stonefist Watch",
            faction = "HORDE",
            mapID = 895,
            x = 0.5275,
            y = 0.6286
        },
        TIMBERFELL_OUTPOST_FLIGHT = {
            name = "Timberfell Outpost",
            faction = "HORDE",
            mapID = 895,
            x = 0.7182,
            y = 0.5173
        },
        PLUNDER_HARBOR_FLIGHT = {
            name = "Plunder Harbor",
            faction = "HORDE",
            mapID = 895,
            x = 0.8547,
            y = 0.5014
        },
        PLUNDER_HARBOR_DOCK = {
            name = "Plunder Harbor",
            faction = "HORDE",
            mapID = 895,
            x = 0.8815,
            y = 0.5105
        },
        -- Drustvar (KUL_TIRAS)
        MUDFISHER_COVE_FLIGHT = {
            name = "Mudfisher Cove",
            faction = "HORDE",
            mapID = 896,
            x = 0.6181,
            y = 0.1695
        },
        SWIFTWIND_POST_FLIGHT = {
            name = "Swiftwind Post",
            faction = "HORDE",
            mapID = 896,
            x = 0.6628,
            y = 0.5915
        },
        KRAZZLEFRAZZ_OUTPOST_FLIGHT = {
            name = "Krazzlefrazz Outpost",
            faction = "HORDE",
            mapID = 896,
            x = 0.3709,
            y = 0.2419
        },
        SEEKERS_VISTA_FLIGHT = {
            name = "Seekers Vista",
            mapID = 942,
            x = 0.3989,
            y = 0.3723
        },
        -- Dungeons        
        FREEHOLD_DUNGEON = {
            name = "Freehold",
            category = "dungeon",
            mapID = 895,
            x = 0.850,
            y = 0.790
        },
        SIEGE_OF_BORALUS_DUNGEON_ALLIANCE = {
            name = "Siege of Boralus",
            category = "dungeon",
            faction = "ALLIANCE",
            mapID = 895,
            x = 0.720,
            y = 0.230
        },
        SIEGE_OF_BORALUS_DUNGEON_HORDE = {
            name = "Siege of Boralus",
            category = "dungeon",
            faction = "HORDE",
            mapID = 895,
            x = 0.880,
            y = 0.510
        },
        SHRINE_OF_THE_STORM_DUNGEON = {
            name = "Shrine of the Storm",
            category = "dungeon",
            mapID = 942, -- Stormsong Valley
            x = 0.780,
            y = 0.240
        },
        WAYCREST_MANOR_DUNGEON = {
            name = "Waycrest Manor",
            category = "dungeon",
            mapID = 896, -- Drustvar
            x = 0.340,
            y = 0.130
        },
        -- Raids
        BATTLE_OF_DAZARALOR_RAID_ALLIANCE = {
            name = "Battle of Dazar'alor",
            category = "raid",
            faction = "ALLIANCE",
            mapID = 1161, -- Boralus
            x = 0.700,
            y = 0.350
        },
        CRUCIBLE_OF_STORMS_RAID = {
            name = "Crucible of Storms",
            category = "raid",
            mapID = 942, -- Stormsong Valley
            x = 0.840,
            y = 0.470
        }
    },

    MECHAGON = {
        MECHAGON = {
            name = "Rustbolt",
            mapID = 1462,
            x = 0.739,
            y = 0.365
        },
        OVERSPARK_EXPEDITION_CAMP_FLIGHT = {
            name = "Overspark Expedition Camp",
            faction = "ALLIANCE",
            mapID = 1462,
            x = 0.775,
            y = 0.410
        },
        PROSPECTUS_BAY_FLIGHT = {
            name = "Prospectus Bay",
            faction = "HORDE",
            mapID = 1462,
            x = 0.7335,
            y = 0.2542
        },
        OPERATION_MECHAGON_DUNGEON = {
            name = "Operation: Mechagon",
            category = "dungeon",
            mapID = 1462, -- Mechagon Island
            x = 0.730,
            y = 0.360
        }
    },

    TOL_DAGOR = {
        TOL_DAGOR_FLIGHT_ALLIANCE = {
            name = "Tol Dagor Flightmaster",
            faction = "ALLIANCE",
            mapID = 974,
            x = 0.3744,
            y = 0.9210
        },
        TOL_DAGOR_FLIGHT_HORDE = {
            name = "Tol Dagor Flightmaster",
            faction = "HORDE",
            mapID = 974,
            x = 0.2296,
            y = 0.4654
        },
        -- Dungeons
        TOL_DAGOR_DUNGEON = {
            name = "Tol Dagor",
            category = "dungeon",
            mapID = 974,
            x = 0.390,
            y = 0.700
        }
    },

    QUELTHALAS = {
        SILVERMOON = {
            name = "Orgrimmar Portal",
            category = "city",
            faction = "HORDE",
            mapID = 110,
            x = 0.5826,
            y = 0.1924
        },
        ZULAMAN_FLIGHT = {
            name = "Zul'Aman",
            mapID = 95,
            x = 0.735,
            y = 0.671
        },
        -- Silvermoon City (QUELTHALAS)
        SILVERMOON_CITY_FLIGHT = {
            name = "Flightmaster",
            faction = "HORDE",
            mapID = 110,
            x = 0.6275,
            y = 0.9658
        },
        FALCONWING_SQUARE_FLIGHT = {
            name = "Falconwing Square",
            faction = "HORDE",
            mapID = 110,
            x = 0.3014,
            y = 0.7963
        },
        FAIRBREEZE_VILLAGE_FLIGHT = {
            name = "Fairbreeze Village",
            faction = "HORDE",
            mapID = 94,
            x = 0.4309,
            y = 0.6985
        },
        -- Ghostlands (QUELTHALAS)
        TRANQUILLIEN_FLIGHT = {
            name = "Tranquillien",
            faction = "HORDE",
            mapID = 95,
            x = 0.4592,
            y = 0.3054
        },
        ZULAMAN_DUNGEON = {
            name = "Zul'Aman",
            mapID = 95,
            x = 0.820,
            y = 0.640
        }
    },

    DRAENOR = {
        LUNARFALL = {
            name = "Lunarfall",
            faction = "ALLIANCE",
            mapID = 582,
            x = 0.299,
            y = 0.339
        },
        LUNARFALL_SHIPYARD = {
            name = "Lunarfall Shipyard",
            faction = "ALLIANCE",
            mapID = 539,
            x = 0.279,
            y = 0.112
        },
        LUNARFALL_GARRISON_FLIGHT = {
            name = "Lunarfall Flightmaster",
            category = "city",
            faction = "ALLIANCE",
            mapID = 582,
            x = 0.299,
            y = 0.339
        },
        FROSTWALL = {
            name = "Frostwall",
            faction = "HORDE",
            mapID = 525,
            x = 0.4792,
            y = 0.6808
        },
        FROSTWALL_SHIPYARD = {
            name = "Frostwall Shipyard",
            faction = "HORDE",
            mapID = 525,
            x = 0.4298,
            y = 0.7356
        },
        STORMSHIELD_ASHRAN = {
            name = "Stormshield",
            faction = "ALLIANCE",
            mapID = 622,
            x = 0.615,
            y = 0.399
        },
        -- Ashran (DRAENOR)
        STORMSHIELD_ALLIANCE_FLIGHT = {
            name = "Stormshield Flightmaster",
            faction = "ALLIANCE",
            mapID = 622,
            x = 0.3076,
            y = 0.4862
        },
        WARSPEAR_ASHRAN = {
            name = "Warspear",
            faction = "HORDE",
            mapID = 624,
            x = 0.5884,
            y = 0.5135
        },
        WARSPEAR_ASHRAN_FLIGHT = {
            name = "Warspear Flightmaster",
            faction = "HORDE",
            mapID = 624,
            x = 0.4420,
            y = 0.3419
        },
        GORGROND_MOLE = {
            name = "Gorgrond",
            faction = "ALLIANCE",
            mapID = 543,
            x = 0.467,
            y = 0.387
        },
        NAGRAND_DRAENOR_MOLE = {
            name = "Nagrand (Draenor)",
            faction = "ALLIANCE",
            mapID = 550,
            x = 0.657,
            y = 0.083
        },
        FROSTFIRE_RIDGE_WORMHOLE = {
            name = "Frostfire Ridge (Lava and snow)",
            mapID = 525,
            x = 0.500,
            y = 0.500
        },
        SHADOWMOON_VALLEY_WORMHOLE = {
            name = "Shadowmoon Valley (Shadows...)",
            mapID = 539,
            x = 0.500,
            y = 0.500
        },
        GORGROND_WORMHOLE = {
            name = "Gorgrond (Primal Forest)",
            mapID = 543,
            x = 0.500,
            y = 0.500
        },
        NAGRAND_DRAENOR_WORMHOLE = {
            name = "Nagrand (Grassy plains)",
            mapID = 550,
            x = 0.500,
            y = 0.500
        },
        TALADOR_WORMHOLE = {
            name = "Talador (A reddish-orange forest)",
            mapID = 535,
            x = 0.500,
            y = 0.500
        },
        SPIRES_OF_ARAK_WORMHOLE = {
            name = "Spires of Arak (A jagged landscape)",
            mapID = 542,
            x = 0.500,
            y = 0.500
        },
        IRON_SIEGEWORKS_FLIGHT = {
            name = "Iron Siegeworks",
            faction = "ALLIANCE",
            mapID = 525,
            x = 0.871,
            y = 0.623
        },
        BLOODMAUL_SLAG_MINES_FLIGHT = {
            name = "Bloodmaul Slag Mines",
            mapID = 525,
            x = 0.514,
            y = 0.213
        },
        HIGHPASS_FLIGHT = {
            name = "Highpass",
            faction = "ALLIANCE",
            mapID = 543,
            x = 0.523,
            y = 0.592
        },
        BASTION_RISE_FLIGHT_ALLIANCE = {
            name = "Bastion Rise",
            faction = "ALLIANCE",
            mapID = 543,
            x = 0.462,
            y = 0.922
        },
        BASTION_RISE_FLIGHT_HORDE = {
            name = "Bastion Rise",
            faction = "HORDE",
            mapID = 543,
            x = 0.4710,
            y = 0.9051
        },
        DEEPROOT_FLIGHT = {
            name = "Deeproot",
            faction = "ALLIANCE",
            mapID = 543,
            x = 0.4604,
            y = 0.7656
        },
        EVERMORN_SPRINGS_FLIGHT = {
            name = "Evermorn Springs",
            faction = "HORDE",
            mapID = 543,
            x = 0.4097,
            y = 0.8698
        },
        BEASTWATCH_FLIGHT = {
            name = "Beastwatch",
            faction = "HORDE",
            mapID = 543,
            x = 0.4545,
            y = 0.6932
        },
        GRIM_CAMPFIRE_GORGROND = {
            name = "Grim Campfire",
            mapID = 543,
            x = 0.740,
            y = 0.245
        },
        WILDWOOD_WASH_FLIGHT = {
            name = "Wildwood Wash",
            faction = "ALLIANCE",
            mapID = 534,
            x = 0.634,
            y = 0.574
        },
        IRON_DOCKS_FLIGHT = {
            name = "Iron Docks",
            mapID = 534,
            x = 0.430,
            y = 0.201
        },
        SKYSEA_RIDGE_FLIGHT = {
            name = "Skysea Ridge",
            mapID = 534,
            x = 0.393,
            y = 0.3664
        },
        BREAKERS_CROWN_FLIGHT = {
            name = "Breaker's Crown",
            mapID = 534,
            x = 0.4585,
            y = 0.5506
        },
        EVERBLOOM_WILDS_FLIGHT = {
            name = "Everbloom Wilds",
            mapID = 534,
            x = 0.5687,
            y = 0.4577
        },
        EVERBLOOM_OVERLOOK_FLIGHT = {
            name = "Everbloom Overlook",
            mapID = 534,
            x = 0.6869,
            y = 0.2897
        },
        THE_IRON_FRONT_FLIGHT_ALLIANCE = {
            name = "The Iron Front",
            faction = "ALLIANCE",
            mapID = 534,
            x = 0.095,
            y = 0.528
        },
        THE_IRON_FRONT_FLIGHT_HORDE = {
            name = "The Iron Front",
            faction = "HORDE",
            mapID = 534,
            x = 0.0919,
            y = 0.5590
        },
        VOLMAR_FLIGHT = {
            name = "Vol'mar",
            faction = "HORDE",
            mapID = 534,
            x = 0.6016,
            y = 0.4619
        },
        LIONS_WATCH_FLIGHT = {
            name = "Lion's Watch",
            faction = "ALLIANCE",
            mapID = 534,
            x = 0.573,
            y = 0.588
        },
        AKTARS_POST_FLIGHT = {
            name = "Aktar's Post",
            mapID = 534,
            x = 0.2623,
            y = 0.3871
        },
        SHANAARI_REFUGE_FLIGHT = {
            name = "Sha'naari Refuge",
            mapID = 534,
            x = 0.2933,
            y = 0.6281
        },
        MALOS_LOOKOUT_FLIGHT = {
            name = "Malo's Lookout",
            mapID = 534,
            x = 0.4356,
            y = 0.4215
        },
        VAULT_OF_THE_EARTH_FLIGHT = {
            name = "Vault of the Earth",
            mapID = 534,
            x = 0.4643,
            y = 0.7022
        },
        YRELS_WATCH_FLIGHT = {
            name = "Yrel's Watch",
            faction = "ALLIANCE",
            mapID = 550,
            x = 0.623,
            y = 0.406
        },
        TELAARI_STATION_FLIGHT = {
            name = "Telaari Station",
            faction = "ALLIANCE",
            mapID = 550,
            x = 0.633,
            y = 0.616
        },
        RILZITS_HOLDFAST_FLIGHT = {
            name = "Rilzit's Holdfast",
            mapID = 550,
            x = 0.5067,
            y = 0.3034
        },
        JOZS_RYLAKS_FLIGHT = {
            name = "Joz's Rylaks",
            mapID = 550,
            x = 0.6215,
            y = 0.3293
        },
        THRONE_OF_THE_ELEMENTS_FLIGHT = {
            name = "Throne of the Elements",
            mapID = 550,
            x = 0.7363,
            y = 0.2621
        },
        THE_RING_OF_TRIALS_FLIGHT = {
            name = "The Ring of Trials",
            mapID = 550,
            x = 0.7960,
            y = 0.4980
        },
        NIVEKS_OVERLOOK_FLIGHT = {
            name = "Nivek's Overlook",
            mapID = 550,
            x = 0.4930,
            y = 0.7562
        },
        EXARCHS_REFUGE_FLIGHT_ALLIANCE = {
            name = "Exarch's Refuge",
            faction = "ALLIANCE",
            mapID = 535,
            x = 0.542,
            y = 0.685
        },
        EXARCHS_REFUGE_FLIGHT_HORDE = {
            name = "Exarch's Refuge",
            faction = "HORDE",
            mapID = 535,
            x = 0.5428,
            y = 0.6755
        },
        DUROTANS_GRASP_FLIGHT = {
            name = "Durotan's Grasp",
            faction = "HORDE",
            mapID = 535,
            x = 0.5498,
            y = 0.4054
        },
        VOLJINS_PRIDE_FLIGHT = {
            name = "Vol'jin's Pride",
            faction = "HORDE",
            mapID = 535,
            x = 0.7029,
            y = 0.2941
        },
        FROSTWOLF_OVERLOOK_FLIGHT = {
            name = "Frostwolf Overlook",
            faction = "HORDE",
            mapID = 535,
            x = 0.6087,
            y = 0.1034
        },

        ANCHORITES_SOJOURN_FLIGHT = {
            name = "Anchorite's Sojourn",
            faction = "ALLIANCE",
            mapID = 535,
            x = 0.795,
            y = 0.568
        },
        REDEMPTION_RISE_FLIGHT = {
            name = "Redemption Rise",
            faction = "ALLIANCE",
            mapID = 535,
            x = 0.631,
            y = 0.258
        },
        FORT_WRYNN_ALLIANCE_FLIGHT = {
            name = "Fort Wrynn (Alliance)",
            faction = "ALLIANCE",
            mapID = 535,
            x = 0.695,
            y = 0.215
        },
        SHATTRATH_CITY_FLIGHT = {
            name = "Shattrath City (Draenor)",
            mapID = 535,
            x = 0.3185,
            y = 0.4791
        },
        RETRIBUTION_POINT_FLIGHT = {
            name = "Retribution Point",
            mapID = 535,
            x = 0.4207,
            y = 0.7648
        },
        TEROKKAR_REFUGE_FLIGHT = {
            name = "Terokkar Refuge",
            mapID = 535,
            x = 0.7030,
            y = 0.5703
        },
        ZANGARRA_FLIGHT = {
            name = "Zangarra",
            mapID = 535,
            x = 0.8017,
            y = 0.2518
        },
        SOUTHPORT_FLIGHT = {
            name = "Southport",
            faction = "ALLIANCE",
            mapID = 542,
            x = 0.389,
            y = 0.618
        },
        APEXIS_EXCAVATION_FLIGHT = {
            name = "Apexis Excavation",
            mapID = 542,
            x = 0.3679,
            y = 0.2459
        },
        CROWS_CROOK_FLIGHT = {
            name = "Crow's Crook",
            mapID = 542,
            x = 0.5159,
            y = 0.3079
        },
        AXEFALL_FLIGHT = {
            name = "Axefall",
            faction = "HORDE",
            mapID = 542,
            x = 0.3921,
            y = 0.4283
        },
        VEIL_TEROKK_FLIGHT = {
            name = "Veil Terokk",
            mapID = 542,
            x = 0.4585,
            y = 0.4370
        },
        TALON_WATCH_FLIGHT = {
            name = "Talon Watch",
            mapID = 542,
            x = 0.6181,
            y = 0.4232
        },
        PINCHWHISTLE_GEARWORKS_FLIGHT = {
            name = "Pinchwhistle Gearworks",
            mapID = 542,
            x = 0.6100,
            y = 0.7297
        },
        LUNARFALL_ALLIANCE_FLIGHT = {
            name = "Lunarfall (Alliance)",
            faction = "ALLIANCE",
            mapID = 539,
            x = 0.304,
            y = 0.177
        },
        EMBAARI_VILLAGE_FLIGHT = {
            name = "Embaari Village",
            faction = "ALLIANCE",
            mapID = 539,
            x = 0.453,
            y = 0.389
        },
        ELODOR_ALLIANCE_FLIGHT = {
            name = "Elodor (Alliance)",
            faction = "ALLIANCE",
            mapID = 539,
            x = 0.586,
            y = 0.315
        },
        PATH_OF_THE_LIGHT_FLIGHT = {
            name = "Path of the Light",
            faction = "ALLIANCE",
            mapID = 539,
            x = 0.594,
            y = 0.458
        },
        TRANQUIL_COURT_FLIGHT = {
            name = "Tranquil Court",
            faction = "ALLIANCE",
            mapID = 539,
            x = 0.703,
            y = 0.504
        },
        THE_DRAAKORIUM_FLIGHT = {
            name = "The Draakorium",
            faction = "ALLIANCE",
            mapID = 539,
            x = 0.568,
            y = 0.570
        },
        AKEETA_S_HOVEL_FLIGHT = {
            name = "Akeeta's Hovel",
            mapID = 539,
            x = 0.2336,
            y = 0.4456
        },
        EXILES_RISE_FLIGHT = {
            name = "Exile's Rise",
            mapID = 539,
            x = 0.4562,
            y = 0.2545
        },
        SOCRETHARS_RISE_FLIGHT = {
            name = "Socrethar's Rise",
            mapID = 539,
            x = 0.4390,
            y = 0.7727
        },
        TWILIGHT_GLADE_FLIGHT = {
            name = "Twilight Glade",
            faction = "ALLIANCE",
            mapID = 539,
            x = 0.402,
            y = 0.554
        },
        -- Nagrand - Draenor (DRAENOR)
        RIVERSIDE_POST_FLIGHT = {
            name = "Riverside Post",
            faction = "HORDE",
            mapID = 550,
            x = 0.4910,
            y = 0.4813
        },
        WORVAR_FLIGHT = {
            name = "Wor'var",
            faction = "HORDE",
            mapID = 550,
            x = 0.8288,
            y = 0.4442
        },
        -- Frostfire Ridge (DRAENOR)
        FROSTWALL_GARRISON_FLIGHT = {
            name = "Frostwall Garrison",
            category = "city",
            faction = "HORDE",
            mapID = 590,
            x = 0.5, -- TBD
            y = 0.5
        },
        WORGOL_FLIGHT = {
            name = "Wor'gol",
            faction = "HORDE",
            mapID = 525,
            x = 0.2120,
            y = 0.5590
        },
        BLADESPIRE_CITADEL_FLIGHT = {
            name = "Bladespire Citadel",
            faction = "HORDE",
            mapID = 525,
            x = 0.2402,
            y = 0.3700
        },
        THROMVAR_FLIGHT = {
            name = "Throm'Var",
            faction = "HORDE",
            mapID = 525,
            x = 0.3167,
            y = 0.0963
        },
        DARKSPEARS_EDGE_FLIGHT = {
            name = "Darkspear's Edge",
            faction = "HORDE",
            mapID = 525,
            x = 0.5145,
            y = 0.4089
        },
        STONEFANG_OUTPOST_FLIGHT = {
            name = "Stonefang Outpost",
            faction = "HORDE",
            mapID = 525,
            x = 0.4003,
            y = 0.5148
        },
        WOLFS_STAND_FLIGHT = {
            name = "Wolf's Stand",
            faction = "HORDE",
            mapID = 525,
            x = 0.7323,
            y = 0.5961
        },
        THUNDER_PASS_FLIGHT = {
            name = "Thunder Pass",
            faction = "HORDE",
            mapID = 525,
            x = 0.8347,
            y = 0.6084
        },
        DARKTIDE_ROOST_FLIGHT = {
            name = "Darktide Roost",
            mapID = 539,
            x = 0.5974,
            y = 0.8123
        },
        -- Dungeons
        BLOODMAUL_SLAG_MINES_DUNGEON = {
            name = "Bloodmaul Slag Mines",
            category = "dungeon",
            mapID = 525, -- Frostfire Ridge
            x = 0.490,
            y = 0.250
        },
        IRON_DOCKS_DUNGEON = {
            name = "Iron Docks",
            category = "dungeon",
            mapID = 543, -- Gorgrond
            x = 0.450,
            y = 0.130
        },
        AUCHINDOUN_DUNGEON = {
            name = "Auchindoun",
            category = "dungeon",
            mapID = 535, -- Talador
            x = 0.460,
            y = 0.740
        },
        SKYREACH_DUNGEON = {
            name = "Skyreach",
            category = "dungeon",
            mapID = 542, -- Spires of Arak
            x = 0.350,
            y = 0.330
        },
        SHADOWMOON_BURIAL_GROUNDS_DUNGEON = {
            name = "Shadowmoon Burial Grounds",
            category = "dungeon",
            mapID = 539, -- Shadowmoon Valley
            x = 0.320,
            y = 0.420
        },
        THE_EVERBLOOM_DUNGEON = {
            name = "The Everbloom",
            category = "dungeon",
            mapID = 543, -- Gorgrond
            x = 0.590,
            y = 0.450
        },
        GRIMRAIL_DEPOT_DUNGEON = {
            name = "Grimrail Depot",
            category = "dungeon",
            mapID = 543, -- Gorgrond
            x = 0.550,
            y = 0.320
        },
        -- Raids
        HIGHMAUL_RAID = {
            name = "Highmaul",
            category = "raid",
            mapID = 550, -- Nagrand
            x = 0.340,
            y = 0.380
        },
        BLACKROCK_FOUNDRY_RAID = {
            name = "Blackrock Foundry",
            category = "raid",
            mapID = 543, -- Gorgrond
            x = 0.510,
            y = 0.290
        },
        HELLFIRE_CITADEL_RAID = {
            name = "Hellfire Citadel",
            category = "raid",
            mapID = 534, -- Tanaan Jungle
            x = 0.470,
            y = 0.530
        }
    },

    ZANDALAR = {
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
    },

    ARGUS_VINDICAAR = {
        VINDICAAR_ARGUS = {
            name = "The Vindicaar (Argus)",
            mapID = 883,
            x = 0.5826,
            y = 0.8101
        }
    },

    ARGUS_KROKUUN = {
        VINDICAAR_KROKUUN_FLIGHT = {
            name = "The Vindicaar (Krokuun)",
            mapID = 830, -- Krokuun
            x = 0.6205,
            y = 0.8634
        },
        KROKUL_HOVEL_FLIGHT = {
            name = "Krokul Hovel",
            mapID = 830, -- Krokuun
            x = 0.5527,
            y = 0.6737
        },
        SHATTERED_FIELDS_FLIGHT = {
            name = "Shattered Fields",
            mapID = 830, -- Krokuun
            x = 0.3991,
            y = 0.6349
        },
        DESTINY_POINT_FLIGHT = {
            name = "Destiny Point",
            mapID = 830, -- Krokuun
            x = 0.6216,
            y = 0.4901
        }
    },
    ARGUS_ANTORAN_WASTES = {
        VINDICAAR_ANTORAN_WASTES_FLIGHT = {
            name = "The Vindicaar (Antoran Wastes)",
            mapID = 885, -- Antoran Wastes
            x = 0.7547,
            y = 0.3690
        },
        THE_VEILED_DEN_FLIGHT = {
            name = "The Veiled Den",
            mapID = 885, -- Antoran Wastes
            x = 0.7040,
            y = 0.2542
        },
        HOPES_LANDING_FLIGHT = {
            name = "Hope's Landing",
            mapID = 885, -- Antoran Wastes
            x = 0.7276,
            y = 0.5067
        },
        -- Raids
        ANTORUS_THE_BURNING_THRONE_RAID = {
            name = "Antorus, the Burning Throne",
            category = "raid",
            mapID = 885, -- Antoran Wastes, Argus
            x = 0.550,
            y = 0.620
        }
    },

    ARGUS_EREDATH = {
        VINDICAAR_EREDATH_FLIGHT = {
            name = "The Vindicaar (Eredath)",
            mapID = 882, -- Eredath
            x = 0.5157,
            y = 0.8609
        },
        TRIUMVIRATES_END_FLIGHT = {
            name = "Triumvirate's End",
            mapID = 882, -- Eredath
            x = 0.5275,
            y = 0.7568
        },
        CITY_CENTER_FLIGHT = {
            name = "City Center",
            mapID = 882, -- Eredath
            x = 0.4698,
            y = 0.5572
        },
        SHADOWGUARD_INCURSION_FLIGHT = {
            name = "Shadowguard Incursion",
            mapID = 882, -- Eredath
            x = 0.3003,
            y = 0.4972
        },
        PROPHETS_REFLECTION_FLIGHT = {
            name = "Prophet's Reflection",
            mapID = 882, -- Eredath
            x = 0.4368,
            y = 0.1458
        },
        CONSERVATORY_OF_THE_ARCANE_FLIGHT = {
            name = "Conservatory of the Arcane",
            mapID = 882, -- Eredath
            x = 0.6287,
            y = 0.3983
        },
        -- Dungeons
        SEAT_OF_THE_TRIUMVIRATE_DUNGEON = {
            name = "Seat of the Triumvirate",
            category = "dungeon",
            mapID = 882, -- Eredath, Argus
            x = 0.210,
            y = 0.570
        }
    },

    KARESH = {
        KARESH = {
            name = "Tazavesh Entrance Portal",
            mapID = 2472,
            x = 0.597,
            y = 0.840
        },
        TAZAVESH_FLIGHT = {
            name = "Tazavesh Flightmaster",
            mapID = 2472,
            x = 0.6330,
            y = 0.6843
        },
        HOSAAS_REST_FLIGHT = {
            name = "Hosaas Rest",
            mapID = 2472,
            x = 0.5415,
            y = 0.6277
        },
        ECODOME_RHOVAN_FLIGHT = {
            name = "Eco-Dome: Rhovan",
            mapID = 2472,
            x = 0.7022,
            y = 0.6083
        },
        OVERLOOK_ZO_SHUUL_FLIGHT = {
            name = "Overlook Zo'Shuul",
            mapID = 2472,
            x = 0.4773,
            y = 0.3709
        },
        THE_OASIS_FLIGHT = {
            name = "The Oasis",
            mapID = 2472,
            x = 0.7655,
            y = 0.3481
        },
        SHANDORAH_FLIGHT = {
            name = "Shan'dorah",
            mapID = 2472,
            x = 0.6055,
            y = 0.2911
        },
        SHADOW_POINT_FLIGHT = {
            name = "Shadow Point",
            mapID = 2472,
            x = 0.4244,
            y = 0.2304
        },
        -- Dungeons
        TAZAVESH_THE_VEILED_MARKET_DUNGEON = {
            name = "Tazavesh, the Veiled Market",
            category = "dungeon",
            mapID = 2472,
            x = 0.3619,
            y = 0.1245
        },
        ECO_DOME_ALDANI_DUNGEON = {
            name = "Eco-Dome Al'dani",
            category = "dungeon",
            mapID = 2472,
            x = 0.4380,
            y = 0.0447
        },
        -- Raids
        MANAFORGE_OMEGA_RAID = {
            name = "Manaforge Omega",
            category = "raid",
            mapID = 2472,
            x = 0.410,
            y = 0.210
        }
    },

    DARKMOON_FAIRE = {
        DARKMOON_ENTRANCE = {
            name = "Entrance",
            mapID = 407,
            x = 0.5129,
            y = 0.2386
        },
        DARKMOON_DOCK_EXIT = {
            name = "Dock",
            mapID = 407,
            x = 0.5056,
            y = 0.9055
        }
    }
}

-----------------------------------------------------------
-- EDGES
-----------------------------------------------------------

ns.Edges = { -- Stormwind Internal Navigation
{
    from = "STORMWIND_PORTAL_ROOM",
    to = "EASTERN_EARTHSHRINE_SW",
    method = "fly"
}, {
    from = "STORMWIND_PORTAL_ROOM",
    to = "STORMWIND_HARBOR",
    method = "fly"
}, {
    from = "STORMWIND_PORTAL_ROOM",
    to = "SW_EMBASSY",
    method = "fly"
}, {
    from = "STORMWIND_PORTAL_ROOM",
    to = "SW_TRAM",
    method = "fly"
}, {
    from = "SW_TRAM",
    to = "IF_TRAM",
    method = "tram"
}, {
    from = "IF_TRAM",
    to = "IRONFORGE",
    method = "fly"
}, -- Stormwind Mage Tower → Major Hubs
{
    from = "STORMWIND_PORTAL_ROOM",
    to = "BORALUS",
    method = "portal",
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "STORMWIND_PORTAL_ROOM",
    to = "DALARAN_NORTHREND",
    method = "portal",
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "STORMWIND_PORTAL_ROOM",
    to = "ORIBOS",
    method = "portal",
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "STORMWIND_PORTAL_ROOM",
    to = "STORMSHIELD_ASHRAN",
    method = "portal",
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "STORMWIND_PORTAL_ROOM",
    to = "SHATTRATH_OUTLAND",
    method = "portal",
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "STORMWIND_PORTAL_ROOM",
    to = "VALDRAKKEN",
    method = "portal",
    requirements = {
        faction = "Alliance"
    }
}, -- Stormwind Mage Tower → Zones
{
    from = "STORMWIND_PORTAL_ROOM",
    to = "EXODAR",
    method = "portal",
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "STORMWIND_PORTAL_ROOM",
    to = "AZSUNA",
    method = "portal",
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "STORMWIND_PORTAL_ROOM",
    to = "PAWDON_VILLAGE_PORTAL",
    method = "portal",
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "STORMWIND_PORTAL_ROOM",
    to = "CAVERNS_OF_TIME",
    method = "portal",
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "STORMWIND_PORTAL_ROOM",
    to = "DARK_PORTAL_BL",
    method = "portal",
    oneway = true
}, {
    from = "STORMWIND_PORTAL_ROOM",
    to = "BELAMETH",
    method = "portal",
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "STORMWIND_PORTAL_ROOM",
    to = "FOUNDERS_POINT",
    method = "portal",
    requirements = {
        faction = "Alliance"
    }
}, -- Stormwind Eastern Earthshrine → Cataclysm Zones
{
    from = "EASTERN_EARTHSHRINE_SW",
    to = "DARKBREAK_COVE_PORTAL",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance",
        quest = 14482
    }
}, {
    from = "EASTERN_EARTHSHRINE_SW",
    to = "HIGHBANK",
    method = "portal",
    requirements = {
        faction = "Alliance"
    }

}, {
    from = "EASTERN_EARTHSHRINE_SW",
    to = "TOL_BARAD_ALLIANCE",
    method = "portal",
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "EASTERN_EARTHSHRINE_SW",
    to = "DEEPHOLM_STORMWIND_PORTAL",
    method = "portal",
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "EASTERN_EARTHSHRINE_SW",
    to = "ULDUM",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "EASTERN_EARTHSHRINE_SW",
    to = "MOUNT_HYJAL",
    method = "portal",
    requirements = {
        faction = "Alliance"
    }
}, -- Stormwind Embassy & Harbour
{
    from = "SW_EMBASSY",
    to = "VINDICAAR_AZEROTH",
    method = "portal",
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "STORMWIND_HARBOR",
    to = "DARKSHORE",
    method = "portal",
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "STORMWIND_HARBOR",
    to = "BORALUS_DOCK",
    method = "ship",
    cost = 120
}, {
    from = "STORMWIND_HARBOR",
    to = "WAKING_SHORES_DOCK",
    method = "ship",
    cost = 120
}, {
    from = "STORMWIND_HARBOR",
    to = "VALIANCE_KEEP_DOCK",
    method = "ship",
    cost = 135
}, {
    from = "ORGRIMMAR_ZEP",
    to = "GROMGOL_ZEPPELIN",
    method = "zeppelin",
    cost = 120
}, -- Exodar
{
    from = "EXODAR",
    to = "STORMWIND_PORTAL_ROOM",
    method = "portal",
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "BORALUS",
    to = "SILITHUS",
    method = "portal",
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "BORALUS",
    to = "NAZJATAR_ALLIANCE",
    method = "portal",
    requirements = {
        faction = "Alliance",
        quest = 54972
    }
}, {
    from = "BORALUS",
    to = "IRONFORGE",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "BORALUS",
    to = "EXODAR",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance"
    }
}, -- Dalaran (Broken Isles)
{
    from = "DALARAN_BROKEN_ISLES",
    to = "VINDICAAR_ARGUS",
    method = "portal"
}, {
    from = "DALARAN_BROKEN_ISLES_PORTAL_ALLIANCE",
    to = "STORMWIND_PORTAL_ROOM",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "DALARAN_BROKEN_ISLES_PORTAL_HORDE",
    to = "ORGRIMMAR_PORTAL_ROOM",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Horde"
    }
}, -- Oribos
{
    from = "ORIBOS",
    to = "ORIBOS_FLIGHT",
    method = "walk"
}, {
    from = "ORIBOS_FLIGHT",
    to = "THEATER_OF_PAIN_FLIGHT",
    method = "flight"
}, {
    from = "ORIBOS_FLIGHT",
    to = "ASPIRANTS_REST_FLIGHT",
    method = "flight"
}, {
    from = "ORIBOS_FLIGHT",
    to = "PRIDEFALL_HAMLET_FLIGHT",
    method = "flight"
}, {
    from = "ORIBOS_FLIGHT",
    to = "TIRNA_VAAL_FLIGHT",
    method = "flight"
}, {
    from = "ORIBOS",
    to = "ZERETH_MORTIS",
    method = "portal"
}, {
    from = "ORIBOS",
    to = "KORTHIA",
    method = "portal"
}, {
    from = "ORIBOS",
    to = "THE_MAW",
    method = "portal"
}, -- Draenor / Outland
{
    from = "STORMSHIELD_ASHRAN",
    to = "DARK_PORTAL_BL",
    method = "portal",
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "SHATTRATH_OUTLAND",
    to = "QUELDANAS",
    method = "portal",
    oneway = true
}, {
    from = "DARK_PORTAL_BL",
    to = "DARK_PORTAL_OUTLAND",
    method = "portal"
}, {
    from = "DARK_PORTAL_OUTLAND",
    to = "STORMWIND_PORTAL_ROOM",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "DARNASSUS",
    to = "DARK_PORTAL_OUTLAND",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "RUTTHERAN_VILLAGE_DOCK",
    to = "AZUREMYST_ISLE_DOCK",
    method = "portal",
    requirements = {
        faction = "Alliance"
    }
}, -- Valdrakken
{
    from = "VALDRAKKEN",
    to = "AMIRDRASSIL",
    method = "portal",
    oneway = true
}, {
    from = "VALDRAKKEN_BADLANDS_PORTAL",
    to = "FUSELIGHT_FLIGHT",
    method = "portal",
    oneway = true
}, -- Night Elf Network
{
    from = "BELAMETH",
    to = "MOUNT_HYJAL",
    method = "portal"
}, {
    from = "BELAMETH",
    to = "VALSHARAH",
    method = "portal",
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "BELAMETH",
    to = "DARKSHORE",
    method = "portal",
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "BELAMETH",
    to = "BELANAAR",
    method = "fly"
}, {
    from = "BELANAAR",
    to = "GILNEAS_DOCK",
    method = "ship",
    cost = 210
}, {
    from = "BELANAAR",
    to = "FERALAS",
    method = "portal",
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "DORNOGAL_PORTAL_ROOM",
    to = "STORMWIND_PORTAL_ROOM",
    method = "portal",
    requirements = {
        faction = "Alliance",
        minLevel = 68
    }
}, {
    from = "TUSHUI_LANDING_FLIGHT",
    to = "PEARLFIN_VILLAGE_FLIGHT",
    method = "flight",
    cost = 81,
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "HUOJIN_LANDING_FLIGHT",
    to = "JADE_TEMPLE_GROUNDS_FLIGHT",
    method = "flight",
    cost = 120,
    requirements = {
        faction = "Horde"
    }
}, {
    from = "SHATTERED_SUN_STAGING_AREA_FLIGHT",
    to = "LIGHTS_HOPE_CHAPEL",
    method = "flight",
    cost = 180
}, {
    from = "DORNOGAL_UNDERMINE_PORTAL",
    to = "UNDERMINE",
    method = "portal",
    requirements = {
        minLevel = 68,
        quest = 86535
    }
}, {
    from = "DORNOGAL_AZJKAHET_PORTAL",
    to = "AZJKAHET",
    method = "portal",
    requirements = {
        minLevel = 68
    }
}, {
    from = "DORNOGAL_KARESH_PORTAL",
    to = "KARESH",
    method = "portal",
    requirements = {
        minLevel = 68,
        quest = 84957
    }
}, {
    from = "OVERSPARK_EXPEDITION_CAMP_FLIGHT",
    to = "FORT_DAELIN_FLIGHT",
    method = "flight",
    cost = 30,
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "PROSPECTUS_BAY_FLIGHT",
    to = "SEEKERS_VISTA_FLIGHT",
    method = "flight",
    cost = 45,
    requirements = {
        faction = "Horde"
    }
}, {
    from = "THERAMORE_DOCK",
    to = "MENETHIL_HARBOR_DOCK",
    method = "ship",
    cost = 115
}, {
    from = "VALGARDE_PORT_DOCK",
    to = "MENETHIL_HARBOR_DOCK",
    method = "ship",
    cost = 220
}, {
    from = "RATCHET_DOCK",
    to = "BOOTY_BAY_DOCK",
    method = "ship",
    cost = 115
}, {
    from = "THUNDER_BLUFF_ZEP",
    to = "ORGRIMMAR_ZEP",
    method = "zeppelin",
    cost = 275
}, {
    from = "DALARAN_NORTHREND",
    to = "ORGRIMMAR_PORTAL_ROOM",
    method = "portal",
    requirements = {
        faction = "Horde"
    }
}, {
    from = "HONEYDEW_VILLAGE",
    to = "ORGRIMMAR_PORTAL_ROOM",
    method = "portal",
    requirements = {
        faction = "Horde"
    }
}, {
    from = "DORNOGAL_PORTAL_ROOM",
    to = "ORGRIMMAR_PORTAL_ROOM",
    method = "portal",
    requirements = {
        faction = "Horde",
        minLevel = 68
    }
}, {
    from = "RAZORWIND_SHORES",
    to = "ORGRIMMAR_PORTAL_ROOM",
    method = "portal",
    requirements = {
        faction = "Horde"
    }
}, {
    from = "ORIBOS",
    to = "ORGRIMMAR_PORTAL_ROOM",
    method = "portal",
    requirements = {
        faction = "Horde"
    }
}, {
    from = "VALDRAKKEN",
    to = "ORGRIMMAR_PORTAL_ROOM",
    method = "portal",
    requirements = {
        faction = "Horde"
    }
}, {
    from = "CAVERNS_OF_TIME",
    to = "ORGRIMMAR_PORTAL_ROOM",
    method = "portal",
    requirements = {
        faction = "Horde"
    }
}, {
    from = "DAZARALOR_PORTAL_ROOM",
    to = "ORGRIMMAR_PORTAL_ROOM",
    method = "portal",
    requirements = {
        faction = "Horde"
    }
}, {
    from = "DAZARALOR_PORTAL_ROOM",
    to = "THUNDER_BLUFF",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Horde"
    }
}, {
    from = "DAZARALOR_PORTAL_ROOM",
    to = "SILVERMOON",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Horde"
    }
}, {
    from = "DAZARALOR_PORTAL_ROOM",
    to = "NAZJATAR_HORDE",
    method = "portal",
    requirements = {
        faction = "Horde"
    }
}, {
    from = "DAZARALOR_PORTAL_ROOM",
    to = "SILITHUS",
    method = "portal",
    requirements = {
        faction = "Horde"
    }
}, {
    from = "AZSUNA",
    to = "ORGRIMMAR_PORTAL_ROOM",
    method = "portal",
    requirements = {
        faction = "Horde"
    }
}, {
    from = "WARSPEAR_ASHRAN",
    to = "ORGRIMMAR_PORTAL_ROOM",
    method = "portal",
    requirements = {
        faction = "Horde"
    }
}, {
    from = "SHATTRATH_OUTLAND",
    to = "ORGRIMMAR_PORTAL_ROOM",
    method = "portal",
    requirements = {
        faction = "Horde"
    }
}, {
    from = "SILVERMOON",
    to = "ORGRIMMAR_PORTAL_ROOM",
    method = "portal",
    requirements = {
        faction = "Horde"
    }
}, {
    from = "WESTERN_EARTHSHRINE_OG",
    to = "TENEBROUS_CAVERN_PORTAL",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Horde",
        quest = 25924
    }
}, {
    from = "WESTERN_EARTHSHRINE_OG",
    to = "DRAGONMAW_PORT",
    method = "portal",
    requirements = {
        faction = "Horde"
    }
}, {
    from = "WESTERN_EARTHSHRINE_OG",
    to = "TOL_BARAD_HORDE",
    method = "portal",
    requirements = {
        faction = "Horde"
    }
}, {
    from = "WESTERN_EARTHSHRINE_OG",
    to = "DEEPHOLM_ORGRIMMAR_PORTAL",
    method = "portal",
    requirements = {
        faction = "Horde"
    }
}, {
    from = "WESTERN_EARTHSHRINE_OG",
    to = "ULDUM",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Horde"
    }
}, {
    from = "WESTERN_EARTHSHRINE_OG",
    to = "MOUNT_HYJAL",
    method = "portal",
    requirements = {
        faction = "Horde"
    }
}, {
    from = "UNUPE_FLIGHT",
    to = "MOAKI_FLIGHT",
    method = "ship",
    cost = 45
}, {
    from = "MOAKI_FLIGHT",
    to = "KAMAGUA_FLIGHT",
    method = "ship",
    cost = 60
}, {
    from = "WORLDS_END_TAVERN",
    to = "CAVERNS_OF_TIME",
    method = "portal",
    oneway = true
}, {
    from = "DALARAN_BROKEN_ISLES_PET",
    to = "WAILING_CAVERNS_DUNGEON",
    method = "portal",
    oneway = true,
    requirements = {
        quest = 45423
    }
}, {
    from = "DALARAN_BROKEN_ISLES_PET",
    to = "GNOMEREGAN_DUNGEON",
    method = "portal",
    oneway = true,
    requirements = {
        quest = 54185
    }
}, {
    from = "DALARAN_BROKEN_ISLES_PET",
    to = "DEADMINES_DUNGEON",
    method = "portal",
    oneway = true,
    requirements = {
        quest = 46291
    }
}, {
    from = "DALARAN_BROKEN_ISLES_PET",
    to = "BLACKROCK_DEPTHS_DUNGEON",
    method = "portal",
    oneway = true,
    requirements = {
        quest = 58457
    }
}, {
    from = "DALARAN_BROKEN_ISLES_PET",
    to = "STRATHOLME_DUNGEON",
    method = "portal",
    oneway = true,
    requirements = {
        quest = 56491
    }
}, {
    from = "BORALUS_PET",
    to = "WAILING_CAVERNS_DUNGEON",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance",
        quest = 45423
    }
}, {
    from = "BORALUS_PET",
    to = "GNOMEREGAN_DUNGEON",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance",
        quest = 54185
    }
}, {
    from = "BORALUS_PET",
    to = "DEADMINES_DUNGEON",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance",
        quest = 46291
    }
}, {
    from = "DAZARALOR_PET",
    to = "WAILING_CAVERNS_DUNGEON",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Horde",
        quest = 45423
    }
}, {
    from = "DAZARALOR_PET",
    to = "GNOMEREGAN_DUNGEON",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Horde",
        quest = 54185
    }
}, {
    from = "DAZARALOR_PET",
    to = "DEADMINES_DUNGEON",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Horde",
        quest = 46291
    }
}, {
    from = "DAZARALOR_PET",
    to = "STRATHOLME_DUNGEON",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Horde",
        quest = 56491
    }
}, {
    from = "BORALUS_PET",
    to = "STRATHOLME_DUNGEON",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance",
        quest = 56491
    }
}, {
    from = "DAZARALOR_PET",
    to = "BLACKROCK_DEPTHS_DUNGEON",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Horde",
        quest = 58457
    }
}, {
    from = "BORALUS_PET",
    to = "BLACKROCK_DEPTHS_DUNGEON",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance",
        quest = 58457
    }
}, {
    from = "UNDERCITY",
    to = "VENGEANCE_LANDING_ZEPPELIN",
    method = "zeppelin"
}, {
    from = "ORGRIMMAR_ZEP",
    to = "WARSONG_HOLD_ZEPPELIN",
    method = "zeppelin"
}, {
    from = "ECHO_ISLES_DOCK",
    to = "DAZARALOR_DOCK",
    method = "ship"
}, {
    from = "DAZARALOR_DOCK",
    to = "WARFANG_HOLD_DOCK",
    method = "portal",
    requirements = {
        faction = "Horde",
        quest = 51802
    }
}, {
    from = "DAZARALOR_DOCK",
    to = "PLUNDER_HARBOR_DOCK",
    method = "portal",
    requirements = {
        faction = "Horde",
        quest = 51800
    }
}, {
    from = "DAZARALOR_DOCK",
    to = "ANYPORT_DOCK",
    method = "portal",
    requirements = {
        faction = "Horde",
        quest = 51801
    }
}, {
    from = "BORALUS_DOCK",
    to = "SHATTERSTONE_HARBOR_DOCK",
    method = "portal",
    requirements = {
        faction = "Alliance",
        quest = 51572
    }
}, {
    from = "BORALUS_DOCK",
    to = "XIBALA_DOCK",
    method = "portal",
    requirements = {
        faction = "Alliance",
        quest = 51570
    }
}, {
    from = "BORALUS_DOCK",
    to = "FORT_VICTORY_DOCK",
    method = "portal",
    requirements = {
        faction = "Alliance",
        quest = 51571
    }
}, {
    from = "UNDERMINE_ROCKET_LAUNCH",
    to = "GUTTERVILLE_ROCKET",
    method = "portal",
    requirements = {
        quest = 83151
    }
}, {
    from = "UNDERMINE_ROCKET_LAUNCH",
    to = "KAJACOAST_ROCKET",
    method = "portal",
    requirements = {
        quest = 83933
    }
}, {
    from = "VINDICAAR_ARGUS",
    to = "VINDICAAR_EREDATH_FLIGHT",
    method = "portal"
}, {
    from = "VINDICAAR_ARGUS",
    to = "VINDICAAR_ANTORAN_WASTES_FLIGHT",
    method = "portal"
}, {
    from = "VINDICAAR_ARGUS",
    to = "VINDICAAR_KROKUUN_FLIGHT",
    method = "portal"
}, {
    from = "SHADOPAN_ISLE_OF_THUNDER_PORTAL_HORDE",
    to = "SUNREAVER_BASE",
    method = "portal",
    requirements = {
        faction = "Horde",
        quest = 32680
    }
}, {
    from = "SHADOPAN_ISLE_OF_THUNDER_PORTAL_ALLIANCE",
    to = "KIRIN_TOR_BASE",
    method = "portal",
    requirements = {
        faction = "Alliance",
        quest = 32681
    }
}, {
    from = "NORTHPASS_TOWER_FLIGHT",
    to = "ZULAMAN_FLIGHT",
    method = "flight",
    cost = 60
}, {
    from = "GRIM_CAMPFIRE_PANDARIA",
    to = "GRIM_CAMPFIRE_GORGROND",
    method = "portal"
}, {
    from = "DARKMOON_FAIRE_ENTRANCE_ELWYNN",
    to = "DARKMOON_ENTRANCE",
    method = "portal",
    requirements = {
        holiday = "Darkmoon Faire",
        faction = "Alliance"
    }
}, {
    from = "DARKMOON_FAIRE_ENTRANCE_ELWYNN",
    to = "DARKMOON_ENTRANCE",
    method = "portal",
    oneway = true,
    requirements = {
        holiday = "Darkmoon Faire",
        faction = "Horde"
    }
}, {
    from = "DARKMOON_FAIRE_ENTRANCE_MULGORE",
    to = "DARKMOON_ENTRANCE",
    method = "portal",
    requirements = {
        holiday = "Darkmoon Faire",
        faction = "Horde"
    }
}, {
    from = "DARKMOON_FAIRE_ENTRANCE_MULGORE",
    to = "DARKMOON_ENTRANCE",
    method = "portal",
    oneway = true,
    requirements = {
        holiday = "Darkmoon Faire",
        faction = "Alliance"
    }
}, {
    from = "DARKMOON_DOCK_EXIT",
    to = "DARKMOON_FAIRE_ENTRANCE_ELWYNN",
    method = "portal",
    oneway = true,
    requirements = {
        holiday = "Darkmoon Faire",
        faction = "Alliance"
    }
}, {
    from = "DARKMOON_DOCK_EXIT",
    to = "DARKMOON_FAIRE_ENTRANCE_MULGORE",
    method = "portal",
    oneway = true,
    requirements = {
        holiday = "Darkmoon Faire",
        faction = "Horde"
    }
}, {
    from = "SHATTERED_SUN_STAGING_AREA_FLIGHT",
    to = "ZULAMAN_FLIGHT",
    method = "flight",
    cost = 215
}, {
    from = "TEMPLE_OF_EARTH_PORTAL",
    to = "THERAZANES_THRONE_PORTAL",
    method = "portal"
}}

-----------------------------------------------------------
-- TRAVERSAL GROUPS
-----------------------------------------------------------

ns.MapToTraversal = {
    -- Continent-level definitions
    [13] = "EK_OVERWORLD",
    [12] = "KALIMDOR_OVERWORLD",
    [101] = "OUTLAND",
    [113] = "NORTHREND",
    [424] = "PANDARIA",
    [572] = "DRAENOR",
    [619] = "BROKEN_ISLES",
    [875] = "ZANDALAR",
    [876] = "KUL_TIRAS",
    [1978] = "DRAGON_ISLES",
    [2274] = "KHAZ_ALGAR",

    -- Isolated zones
    [207] = "DEEPHOLM",
    [245] = "TOL_BARAD",
    [89] = "TELDRASSIL",
    [407] = "DARKMOON_FAIRE",
    [464] = "TELDRASSIL",
    [110] = "QUELTHALAS",
    [95] = "QUELTHALAS",
    [94] = "QUELTHALAS",
    [974] = "TOL DAGOR",
    [504] = "ISLE_OF_THUNDER",
    [554] = "TIMELESS_ISLE",
    [1282] = "DEATH_KNIGHT_HALL",
    [2351] = "RAZORWIND_SHORES",
    [122] = "QUELDANAS",
    [1355] = "NAZJATAR",
    [1462] = "MECHAGON",
    [1670] = "SL_ORIBOS",
    [1533] = "SL_BASTION",
    [1536] = "SL_MALDRAXXUS",
    [1525] = "SL_REVENDRETH",
    [1565] = "SL_ARDENWEALD",
    [1543] = "SL_MAW",
    [1961] = "SL_KORTHIA",
    [1970] = "SL_ZM",
    [830] = "ARGUS_KROKUUN",
    [831] = "ARGUS_VINDICAAR",
    [882] = "ARGUS_EREDATH",
    [885] = "ARGUS_ANTORAN_WASTES",
    [2200] = "EMERALD_DREAM",
    [2346] = "UNDERMINE",
    [2472] = "KARESH",

    -- City-specific overrides
    [84] = "EK_OVERWORLD",
    [87] = "EK_OVERWORLD",
    [1014] = "ZANDALAR",
    [1161] = "KUL_TIRAS",
    [2112] = "DRAGON_ISLES",
    [2339] = "KHAZ_ALGAR"
}

-- Helper: Get traversal group, with parent map fallback
function ns.GetTraversalGroupForMap(mapID)
    if ns.MapToTraversal[mapID] then
        return ns.MapToTraversal[mapID]
    end

    local mapInfo = C_Map.GetMapInfo(mapID)
    if not mapInfo then
        return nil
    end

    local parentID = mapInfo.parentMapID
    local maxDepth = 10
    local depth = 0

    while parentID and parentID > 0 and depth < maxDepth do
        if ns.MapToTraversal[parentID] then
            ns.MapToTraversal[mapID] = ns.MapToTraversal[parentID]
            return ns.MapToTraversal[parentID]
        end

        local parentInfo = C_Map.GetMapInfo(parentID)
        if not parentInfo then
            break
        end

        parentID = parentInfo.parentMapID
        depth = depth + 1
    end

    return nil
end
