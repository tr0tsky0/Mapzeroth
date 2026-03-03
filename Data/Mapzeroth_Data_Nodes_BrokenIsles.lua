-- Mapzeroth_Data_Nodes_BrokenIsles.lua
-- Broken Isles, Temple of Five Dawns, Eye of Azshara (Legion)
local _, ns = ...

ns.Nodes = ns.Nodes or {}

ns.Nodes.BROKEN_ISLES = {
    AZSUNA = {
        name = "Faronaar",
        mapID = 630,
        x = 0.4682,
        y = 0.4136
    },
    DALARAN_BROKEN_ISLES = {
        name = "Dalaran (Broken Isles)",
        mapID = 627,
        x = 0.6092,
        y = 0.4472
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
        x = 0.6173,
        y = 0.1400
    },
    DALARAN_BROKEN_ISLES_PET = {
        name = "Dalaran Pet Shop",
        mapID = 627,
        x = 0.5835,
        y = 0.3960
    },
    HALL_OF_THE_GUARDIAN = {
        name = "Hall of the Guardian",
        mapID = 734,
        interior = true,
        x = 0.5763,
        y = 0.8614
    },
    DALARAN_PALADIN_PORTAL_ALLIANCE = {
        name = "Sanctum of Light Portal",
        faction = "ALLIANCE",
        mapID = 627,
        x = 0.3285,
        y = 0.6952
    },
    DALARAN_PALADIN_PORTAL_HORDE = {
        name = "Sanctum of Light Portal",
        faction = "HORDE",
        mapID = 627,
        x = 0.3285,
        y = 0.6952
    },
    ACHERUS = {
        name = "Acherus",
        mapID = 648,
        x = 0.2743,
        y = 0.3043
    },
    EMERALD_DREAMWAY = {
        name = "Emerald Dreamway",
        mapID = 715,
        interior = true,
        x = 0.3533,
        y = 0.5315
    },
    EMERALD_DREAMWAY_MOONGLADE_PORTAL = {
        name = "Portal to Moonglade",
        mapID = 715,
        interior = true,
        x = 0.2651,
        y = 0.7818
    },
    EMERALD_DREAMWAY_AMIRDRASSIL_PORTAL = {
        name = "Portal to Amirdrassil",
        mapID = 715,
        interior = true,
        x = 0.1998,
        y = 0.5910
    },
    EMERALD_DREAMWAY_FERALAS_PORTAL = {
        name = "Portal to Feralas",
        mapID = 715,
        interior = true,
        x = 0.2358,
        y = 0.3881
    },
    EMERALD_DREAMWAY_GRIZZLY_HILLS_PORTAL = {
        name = "Portal to Grizzly Hills",
        mapID = 715,
        interior = true,
        x = 0.3189,
        y = 0.2692
    },
    EMERALD_DREAMWAY_DREAMGROVE_PORTAL = {
        name = "Portal to The Dreamgrove",
        mapID = 715,
        interior = true,
        x = 0.4538,
        y = 0.2500
    },
    EMERALD_DREAMWAY_HYJAL_PORTAL = {
        name = "Portal to Mount Hyjal",
        mapID = 715,
        interior = true,
        x = 0.5284,
        y = 0.5256
    },
    EMERALD_DREAMWAY_HINTERLANDS_PORTAL = {
        name = "Portal to Moonglade",
        mapID = 715,
        interior = true,
        x = 0.5029,
        y = 0.6520
    },
    EMERALD_DREAMWAY_DUSKWOOD_PORTAL = {
        name = "Portal to Moonglade",
        mapID = 715,
        interior = true,
        x = 0.3981,
        y = 0.6892
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
    THUNDER_TOTEM_ORGRIMMAR_PORTAL = {
        name = "Portal to Orgrimmar",
        mapID = 652,
        x = 0.4546,
        y = 0.6388
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
    THE_NIGHTHOLD = {
        name = "The Nighthold",
        mapID = 680,
        x = 0.5957,
        y = 0.8526
    },
    NIGHTHOLD_ORGRIMMAR_PORTAL = {
        name = "Portal to Orgrimmar",
        mapID = 680,
        faction = "HORDE",
        x = 0.5821,
        y = 0.8729
    },
    NIGHTHOLD_SHALARAN_PORTAL = {
        name = "Portal to Shal'Aran",
        mapID = 680,
        faction = "HORDE",
        x = 0.5803,
        y = 0.8660
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
}


ns.Nodes.TEMPLE_OF_FIVE_DAWNS = {
    PEAK_OF_SERENITY = {
        name = "Peak of Serenity",
        mapID = 709,
        x = 0.5145,
        y = 0.4865
    },
    MONK_DALARAN_PORTAL = {
        name = "Portal to Dalaran",
        mapID = 709,
        x = 0.5236,
        y = 0.5722
    }
}


ns.Nodes.EYE_OF_AZSHARA = {
    EYE_OF_AZSHARA_FLIGHT = {
        name = "Eye of Azshara Flightmaster",
        mapID = 790,
        x = 0.3816,
        y = 0.4567
    }
}

