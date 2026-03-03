-- Mapzeroth_Data_Nodes_Special.lua
-- Midnight expansion zones and miscellaneous
local _, ns = ...

ns.Nodes = ns.Nodes or {}

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
        mapArtID = 1942,
        x = 0.7589,
        y = 0.5477
    },
    HARANDAR_SILVERMOON_PORTAL = {
        name = "Rootway to Silvermoon City",
        mapID = 2576,
        mapArtID = 2078,
        x = 0.6413,
        y = 0.7066
    },
    HARATHIR_FLIGHT = {
        name = "Har'athir Flightmaster",
        mapID = 2413,
        mapArtID = 1942,
        x = 0.6940,
        y = 0.5257
    },
    HARMARA_FLIGHT = {
        name = "Har'mara Flightmaster",
        mapID = 2413,
        mapArtID = 1942,
        x = 0.3552,
        y = 0.2375
    },
    HARKUAI_FLIGHT = {
        name = "Har'kuai Flightmaster",
        mapID = 2413,
        mapArtID = 1942,
        x = 0.6461,
        y = 0.2319
    },
    THE_DEN_FLIGHT = {
        name = "The Den Flightmaster",
        mapID = 2576,
        mapArtID = 2078,
        x = 0.7090,
        y = 0.5321
    },
    HARALNOR_FLIGHT = {
        name = "Har'alnor Flightmaster",
        mapID = 2413,
        mapArtID = 1942,
        x = 0.3175,
        y = 0.6737
    },
    -- Dungeons
    THE_BLINDING_VALE_DUNGEON = {
        name = "The Blinding Vale",
        category = "dungeon",
        mapID = 2413,
        mapArtID = 1942,
        x = 0.2659,
        y = 0.7804
    },
    -- Raids
    THE_DREAMRIFT_RAID = {
        name = "The Dreamrift",
        category = "raid",
        mapID = 2413,
        mapArtID = 1942,
        x = 0.6102,
        y = 0.6266
    }
}


ns.Nodes.VOIDSTORM = {
    VOIDSTORM_INGRESS_PORTAL = {
        name = "Portal to Silvermoon",
        mapID = 2405,
        mapArtID = 1936,
        x = 0.3415,
        y = 0.6060
    },
    VOIDSTORM_SILVERMOON_PORTAL = {
        name = "Portal to Silvermoon",
        mapID = 2405,
        mapArtID = 1936,
        x = 0.5164,
        y = 0.7020
    },
    THE_INGRESS_FLIGHT = {
        name = "The Ingress Flightmaster",
        mapID = 2405,
        mapArtID = 1936,
        x = 0.3688,
        y = 0.5895
    },
    LOCUS_POINT_FLIGHT = {
        name = "Locus Point Flightmaster",
        mapID = 2405,
        mapArtID = 1936,
        x = 0.4223,
        y = 0.7368
    },
    HOWLING_RIDGE_FLIGHT = {
        name = "Howling Ridge Flightmaster",
        mapID = 2405,
        mapArtID = 1936,
        x = 0.5118,
        y = 0.6921
    },
    MASTERS_PERCH_FLIGHT = {
        name = "Masters' Perch Flightmaster",
        mapID = 2405,
        mapArtID = 1936,
        x = 0.4459,
        y = 0.3945
    },
    -- Dungeons
    VOIDSCAR_ARENA_DUNGEON = {
        name = "Voidscar Arena",
        category = "dungeon",
        mapID = 2405,
        mapArtID = 1936,
        x = 0.5156,
        y = 0.1901
    },
    NEXUS_POINT_XENAS_DUNGEON = {
        name = "Nexus Point Xenas",
        category = "dungeon",
        mapID = 2405,
        mapArtID = 1936,
        x = 0.6477,
        y = 0.6163
    },
    -- Raids
    VOIDSPIRE_RAID = {
        name = "Voidspire",
        category = "raid",
        mapID = 2405,
        mapArtID = 1936,
        x = 0.4520,
        y = 0.6494
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


ns.Nodes.ARCANTINA = {
    ARCANTINA_ENTRANCE = {
        name = "The Arcantina",
        mapID = 2541,
        mapArtID = 2048,
        x = 0.5093,
        y = 0.7880
    },
    ARCANTINA_EXIT = {
        name = "Exit",
        mapID = 2541,
        mapArtID = 2048,
        x = 0.5067,
        y = 0.8530
    }
}

