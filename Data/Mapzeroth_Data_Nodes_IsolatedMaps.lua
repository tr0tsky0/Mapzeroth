-- Mapzeroth_Data_Nodes_IsolatedMaps.lua
-- Isolated zones with no continental connection: Vindicaar, Dark Iron City, Timeless Isle,
-- Isle of Giants, Quel'danas, Nazjatar, Darkmoon Faire, Karesh, Harandar, Voidstorm, Arcantina
local _, ns = ...

ns.Nodes = ns.Nodes or {}

ns.Nodes.VINDICAAR_AZEROTH = {
    VINDICAAR_AZEROTH = {
        name = "The Vindicaar (Azeroth)",
        mapID = 940,
        x = 0.750,
        y = 0.750
    }
}


ns.Nodes.DARK_IRON_CITY = {
    SHADOWFORGE_CITY_MOLE = {
        name = "Shadowforge City",
        mapID = 1186,
        x = 0.614,
        y = 0.244
    }
}


ns.Nodes.TIMELESS_ISLE = {
    TIMELESS_ISLE = {
        name = "The Celestial Court",
        mapID = 554,
        x = 0.342,
        y = 0.553
    },
    TUSHUI_LANDING_FLIGHT = {
        name = "Tushui Landing",
        mapID = 554,
        x = 0.230,
        y = 0.710
    },
    HUOJIN_LANDING_FLIGHT = {
        name = "Huojin Landing",
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
}


ns.Nodes.ISLE_OF_GIANTS = {
    BEEBLES_WRECK_FLIGHT = {
        name = "Beeble's Wreck",
        mapID = 507,
        x = 0.416,
        y = 0.792
    },
    BOZZLES_WRECK_FLIGHT = {
        name = "Bozzle's Wreck",
        mapID = 507,
        x = 0.5157,
        y = 0.7504
    }
}


ns.Nodes.QUELDANAS = {
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
    MAGISTERS_TERRACE_BC_DUNGEON = {
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
}


ns.Nodes.NAZJATAR = {
    NAZJATAR_ALLIANCE = {
        name = "Mezzamere",
        mapID = 1355,
        x = 0.3996,
        y = 0.5884
    },
    NAZJATAR_HORDE = {
        name = "Newhome",
        mapID = 1355,
        x = 0.4719,
        y = 0.6263
    },
    ASHEN_STRAND_FLIGHT_ALLIANCE = {
        name = "Ashen Strand",
        mapID = 1355,
        x = 0.316,
        y = 0.382
    },
    ASHEN_STRAND_FLIGHT_HORDE = {
        name = "Ashen Strand",
        mapID = 1355,
        x = 0.3426,
        y = 0.3690
    },
    MEZZAMERE_FLIGHT = {
        name = "Mezzamere",
        mapID = 1355,
        x = 0.399,
        y = 0.542
    },
    WRECK_OF_THE_OLD_BLANCHY_FLIGHT = {
        name = "Wreck of the Old Blanchy",
        mapID = 1355,
        x = 0.441,
        y = 0.857
    },
    THE_TIDAL_CONFLUX_FLIGHT_ALLIANCE = {
        name = "The Tidal Conflux",
        mapID = 1355,
        x = 0.496,
        y = 0.236
    },
    THE_TIDAL_CONFLUX_FLIGHT_HORDE = {
        name = "The Tidal Conflux",
        mapID = 1355,
        x = 0.5086,
        y = 0.2376
    },
    UTAMAS_STAND_FLIGHT = {
        name = "Utama's Stand",
        mapID = 1355,
        x = 0.614,
        y = 0.366
    },
    ORISES_VIGIL_FLIGHT = {
        name = "Orise's Vigil",
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
        mapID = 1355,
        x = 0.7912,
        y = 0.3806
    },
    EKKAS_HIDEAWAY_FLIGHT = {
        name = "Ekka's Hideaway",
        mapID = 1355,
        x = 0.6358,
        y = 0.5166
    },
    NEWHOME_FLIGHT = {
        name = "Newhome",
        mapID = 1355,
        x = 0.4721,
        y = 0.6314
    },
    WRECK_OF_THE_HUNGRY_RIVERBEAST_FLIGHT = {
        name = "Wreck of the Hungry Riverbeast",
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
}


ns.Nodes.DARKMOON_FAIRE = {
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


ns.Nodes.KARESH = {
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
}


ns.Nodes.HARANDAR = {
    HARANDAR_EVERSONG_PORTAL = {
        name = "Rootway to Eversong",
        mapID = 2413,
        x = 0.7589,
        y = 0.5477
    },
    HARANDAR_SILVERMOON_PORTAL = {
        name = "Rootway to Silvermoon City",
        mapID = 2576,
        x = 0.6413,
        y = 0.7066
    },
    HARANDAR_VOIDSTORM_PORTAL = {
        name = "Portal to Voidstorm",
        mapID = 2405,
        x = 0.6186,
        y = 0.7318
    },
    HARATHIR_FLIGHT = {
        name = "Har'athir Flightmaster",
        mapID = 2413,
        x = 0.6940,
        y = 0.5257
    },
    HARMARA_FLIGHT = {
        name = "Har'mara Flightmaster",
        mapID = 2413,
        x = 0.3552,
        y = 0.2375
    },
    HARKUAI_FLIGHT = {
        name = "Har'kuai Flightmaster",
        mapID = 2413,
        x = 0.6461,
        y = 0.2319
    },
    THE_DEN_FLIGHT = {
        name = "The Den Flightmaster",
        mapID = 2576,
        x = 0.7090,
        y = 0.5321
    },
    HARALNOR_FLIGHT = {
        name = "Har'alnor Flightmaster",
        mapID = 2413,
        x = 0.3175,
        y = 0.6737
    },
    LOAKNIT_DEN_ZUL_AMAN = {
        name = "Loaknit Den",
        mapID = 2413,
        x = 0.316,
        y = 0.212
    },
    -- Dungeons
    THE_BLINDING_VALE_DUNGEON = {
        name = "The Blinding Vale",
        category = "dungeon",
        mapID = 2413,
        x = 0.2659,
        y = 0.7804
    },
    -- Raids
    THE_DREAMRIFT_RAID = {
        name = "The Dreamrift",
        category = "raid",
        mapID = 2413,
        x = 0.6102,
        y = 0.6266
    }
}


ns.Nodes.VOIDSTORM = {
    VOIDSTORM_INGRESS_PORTAL = {
        name = "Portal to Silvermoon",
        mapID = 2405,
        x = 0.3415,
        y = 0.6060
    },
    VOIDSTORM_SILVERMOON_PORTAL = {
        name = "Portal to Silvermoon",
        mapID = 2405,
        x = 0.5164,
        y = 0.7020
    },
    VOIDSTORM_HARANDAR_PORTAL = {
        name = "Portal to Harandar",
        mapID = 2405,
        x = 0.5171,
        y = 0.7037
    },
    THE_INGRESS_FLIGHT = {
        name = "The Ingress Flightmaster",
        mapID = 2405,
        x = 0.3688,
        y = 0.5895
    },
    LOCUS_POINT_FLIGHT = {
        name = "Locus Point Flightmaster",
        mapID = 2405,
        x = 0.4223,
        y = 0.7368
    },
    HOWLING_RIDGE_FLIGHT = {
        name = "Howling Ridge Flightmaster",
        mapID = 2405,
        x = 0.5118,
        y = 0.6921
    },
    MASTERS_PERCH_FLIGHT = {
        name = "Masters' Perch Flightmaster",
        mapID = 2405,
        x = 0.4459,
        y = 0.3945
    },
    -- Dungeons
    VOIDSCAR_ARENA_DUNGEON = {
        name = "Voidscar Arena",
        category = "dungeon",
        mapID = 2405,
        x = 0.5156,
        y = 0.1901
    },
    NEXUS_POINT_XENAS_DUNGEON = {
        name = "Nexus Point Xenas",
        category = "dungeon",
        mapID = 2405,
        x = 0.6477,
        y = 0.6163
    },
    -- Raids
    VOIDSPIRE_RAID = {
        name = "Voidspire",
        category = "raid",
        mapID = 2405,
        x = 0.4520,
        y = 0.6494
    }
}


ns.Nodes.ARCANTINA = {
    ARCANTINA_ENTRANCE = {
        name = "The Arcantina",
        mapID = 2541,
        x = 0.5093,
        y = 0.7880
    },
    ARCANTINA_EXIT = {
        name = "Exit",
        mapID = 2541,
        x = 0.5067,
        y = 0.8530
    }
}
