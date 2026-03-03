-- Mapzeroth_Data_Nodes_Shadowlands.lua
-- Shadowlands zones
local _, ns = ...

ns.Nodes = ns.Nodes or {}

ns.Nodes.SL_ORIBOS = {
    ORIBOS = {
        name = "Entrance, Oribos",
        mapID = 1670,
        x = 0.203,
        y = 0.503
    },
    ORIBOS_FLIGHT = {
        name = "Flightmaster, Oribos",
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
}


ns.Nodes.SL_MALDRAXXUS = {
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
    MALDRAXXUS_POCKET_PORTAL = {
        name = "Theater of Pain",
        mapID = 1536,
        x = 0.520,
        y = 0.540
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
}


ns.Nodes.SL_BASTION = {
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
    BASTION_POCKET_PORTAL = {
        name = "Temple of Courage",
        mapID = 1533,
        x = 0.420,
        y = 0.480
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
    THE_NECROTIC_WAKE_DUNGEON = {
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
}


ns.Nodes.SL_REVENDRETH = {
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
    REVENDRETH_POCKET_PORTAL = {
        name = "Castle Nathria",
        mapID = 1525,
        x = 0.570,
        y = 0.510
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
}


ns.Nodes.SL_ARDENWEALD = {
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
    ARDENWEALD_POCKET_PORTAL = {
        name = "Heart of the Forest",
        mapID = 1565,
        x = 0.480,
        y = 0.480
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
}


ns.Nodes.SL_ZM = {
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
}


ns.Nodes.SL_THE_MAW = {
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
}

