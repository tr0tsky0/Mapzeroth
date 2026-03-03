-- Mapzeroth_Data_Nodes_KhazAlgar.lua
-- Khaz Algar and Undermine (The War Within)
local _, ns = ...

ns.Nodes = ns.Nodes or {}

ns.Nodes.KHAZ_ALGAR = {
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
}


ns.Nodes.UNDERMINE = {
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
}

