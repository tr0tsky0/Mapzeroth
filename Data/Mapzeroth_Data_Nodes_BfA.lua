-- Mapzeroth_Data_Nodes_BfA.lua
-- Kul Tiras, Mechagon, Tol Dagor, Quel'thalas (Battle for Azeroth)
local _, ns = ...

ns.Nodes = ns.Nodes or {}

ns.Nodes.KUL_TIRAS = {
    BORALUS = {
        name = "Portal Room",
        category = "city",
        mapID = 1161,
        x = 0.706,
        y = 0.170
    },
    BORALUS_PET = {
        name = "Pet Shop",
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
        mapID = 895,
        x = 0.882,
        y = 0.715
    },
    STORMSONG_VALLEY_MOLE = {
        name = "Tidebreak Summit",
        mapID = 942,
        x = 0.642,
        y = 0.294
    },
    TRADEWINDS_MARKET_FLIGHT = {
        name = "Tradewinds Market",
        mapID = 1161,
        x = 0.667,
        y = 0.151
    },
    PROUDMOORE_KEEP_FLIGHT = {
        name = "Proudmoore Keep",
        mapID = 1161,
        x = 0.475,
        y = 0.649
    },
    MARINERS_ROW_FLIGHT = {
        name = "Mariner's Row",
        mapID = 1161,
        x = 0.763,
        y = 0.728
    },
    HATHERFORD_FLIGHT = {
        name = "Hatherford",
        mapID = 895,
        x = 0.665,
        y = 0.231
    },
    NORWINGTON_ESTATE_FLIGHT = {
        name = "Norwington Estate",
        mapID = 895,
        x = 0.525,
        y = 0.286
    },
    ROUGHNECK_CAMP_FLIGHT = {
        name = "Roughneck Camp",
        mapID = 895,
        x = 0.418,
        y = 0.224
    },
    OUTRIGGER_POST_FLIGHT = {
        name = "Outrigger Post",
        mapID = 895,
        x = 0.353,
        y = 0.247
    },
    BRIDGEPORT_FLIGHT = {
        name = "Bridgeport",
        mapID = 895,
        x = 0.755,
        y = 0.488
    },
    KENNINGS_LODGE_FLIGHT = {
        name = "Kennings Lodge",
        mapID = 895,
        x = 0.763,
        y = 0.653
    },
    VIGIL_HILL_FLIGHT = {
        name = "Vigil Hill",
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
        mapID = 896,
        x = 0.624,
        y = 0.237
    },
    FALLHAVEN_FLIGHT = {
        name = "Fallhaven",
        mapID = 896,
        x = 0.549,
        y = 0.348
    },
    HANGMANS_POINT_FLIGHT = {
        name = "Hangman's Point",
        mapID = 896,
        x = 0.708,
        y = 0.403
    },
    FLETCHERS_HOLLOW_FLIGHT = {
        name = "Fletcher's Hollow",
        mapID = 896,
        x = 0.700,
        y = 0.601
    },
    WATCHMANS_RISE_FLIGHT = {
        name = "Watchman's Rise",
        mapID = 896,
        x = 0.316,
        y = 0.303
    },
    FALCONHURST_FLIGHT = {
        name = "Falconhurst",
        mapID = 896,
        x = 0.271,
        y = 0.721
    },
    AROMS_STAND_FLIGHT = {
        name = "Arom's Stand",
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
        mapID = 942,
        x = 0.305,
        y = 0.664
    },
    FORT_DAELIN_FLIGHT = {
        name = "Fort Daelin",
        mapID = 942,
        x = 0.340,
        y = 0.468
    },
    DEADWASH_FLIGHT = {
        name = "Deadwash",
        mapID = 942,
        x = 0.426,
        y = 0.571
    },
    THE_AMBER_WAVES_FLIGHT = {
        name = "The Amber Waves",
        mapID = 942,
        x = 0.506,
        y = 0.700
    },
    BRENNADAM_FLIGHT = {
        name = "Brennadam",
        mapID = 942,
        x = 0.594,
        y = 0.702
    },
    MILDENHALL_MEADERY_FLIGHT = {
        name = "Mildenhall Meadery",
        mapID = 942,
        x = 0.685,
        y = 0.650
    },
    TIDECROSS_FLIGHT = {
        name = "Tidecross",
        mapID = 942,
        x = 0.654,
        y = 0.478
    },
    SHRINE_OF_THE_STORM_FLIGHT_ALLIANCE = {
        name = "Shrine of the Storm",
        mapID = 942,
        x = 0.779,
        y = 0.291
    },
    -- Stormsong Valley (KUL_TIRAS)
    SHRINE_OF_THE_STORM_FLIGHT_HORDE = {
        name = "Shrine of the Storm",
        mapID = 942,
        x = 0.7759,
        y = 0.2383
    },
    HILLCREST_PASTURE_FLIGHT = {
        name = "Hillcrest Pasture",
        mapID = 942,
        x = 0.5228,
        y = 0.7974
    },
    WINDFALL_CAVERN_FLIGHT = {
        name = "Windfall Cavern",
        mapID = 942,
        x = 0.6052,
        y = 0.2736
    },
    DIRETUSK_HOLLOW_FLIGHT = {
        name = "Diretusk Hollow",
        mapID = 942,
        x = 0.5404,
        y = 0.4891
    },
    IRONMAUL_OVERLOOK_FLIGHT = {
        name = "Ironmaul Overlook",
        mapID = 942,
        x = 0.7570,
        y = 0.6392
    },
    STONETUSK_WATCH_FLIGHT = {
        name = "Stonetusk Watch",
        mapID = 942,
        x = 0.3874,
        y = 0.6692
    },
    WARFANG_HOLD_FLIGHT = {
        name = "Warfang Hold",
        mapID = 942,
        x = 0.5098,
        y = 0.3372
    },
    WARFANG_HOLD_DOCK = {
        name = "Warfang Hold Dock",
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
        mapID = 895,
        x = 0.6169,
        y = 0.1341
    },
    WANING_GLACIER_FLIGHT = {
        name = "Waning Glacier",
        mapID = 895,
        x = 0.3933,
        y = 0.1836
    },
    STONEFIST_WATCH_FLIGHT = {
        name = "Stonefist Watch",
        mapID = 895,
        x = 0.5275,
        y = 0.6286
    },
    TIMBERFELL_OUTPOST_FLIGHT = {
        name = "Timberfell Outpost",
        mapID = 895,
        x = 0.7182,
        y = 0.5173
    },
    PLUNDER_HARBOR_FLIGHT = {
        name = "Plunder Harbor",
        mapID = 895,
        x = 0.8547,
        y = 0.5014
    },
    PLUNDER_HARBOR_DOCK = {
        name = "Plunder Harbor",
        mapID = 895,
        x = 0.8815,
        y = 0.5105
    },
    -- Drustvar (KUL_TIRAS)
    MUDFISHER_COVE_FLIGHT = {
        name = "Mudfisher Cove",
        mapID = 896,
        x = 0.6181,
        y = 0.1695
    },
    SWIFTWIND_POST_FLIGHT = {
        name = "Swiftwind Post",
        mapID = 896,
        x = 0.6628,
        y = 0.5915
    },
    KRAZZLEFRAZZ_OUTPOST_FLIGHT = {
        name = "Krazzlefrazz Outpost",
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
        mapID = 895,
        x = 0.720,
        y = 0.230
    },
    SIEGE_OF_BORALUS_DUNGEON_HORDE = {
        name = "Siege of Boralus",
        category = "dungeon",
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
}


ns.Nodes.MECHAGON = {
    MECHAGON = {
        name = "Rustbolt",
        mapID = 1462,
        x = 0.739,
        y = 0.365
    },
    OVERSPARK_EXPEDITION_CAMP_FLIGHT = {
        name = "Overspark Expedition Camp",
        mapID = 1462,
        x = 0.775,
        y = 0.410
    },
    PROSPECTUS_BAY_FLIGHT = {
        name = "Prospectus Bay",
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
}


ns.Nodes.TOL_DAGOR = {
    TOL_DAGOR_FLIGHT_ALLIANCE = {
        name = "Tol Dagor Flightmaster",
        mapID = 974,
        x = 0.3744,
        y = 0.9210
    },
    TOL_DAGOR_FLIGHT_HORDE = {
        name = "Tol Dagor Flightmaster",
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
}


ns.Nodes.QUELTHALAS = {
    SILVERMOON = {
        name = "Orgrimmar Portal",
        category = "city",
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
        mapID = 110,
        x = 0.6275,
        y = 0.9658
    },
    FALCONWING_SQUARE_FLIGHT = {
        name = "Falconwing Square",
        mapID = 110,
        x = 0.3014,
        y = 0.7963
    },
    FAIRBREEZE_VILLAGE_FLIGHT = {
        name = "Fairbreeze Village",
        mapID = 94,
        x = 0.4309,
        y = 0.6985
    },
    -- Ghostlands (QUELTHALAS)
    TRANQUILLIEN_BC_FLIGHT = {
        name = "Tranquillien",
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
}

