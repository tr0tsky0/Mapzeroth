-- Mapzeroth_Data_Nodes_IsolatedMaps.lua
-- Isolated zones with no continental connection
local _, ns = ...

ns.Nodes = ns.Nodes or {}

ns.Nodes.VINDICAAR_AZEROTH = {
    VINDICAAR_AZEROTH = {
        name = "The Vindicaar (Azeroth)",
        faction = "ALLIANCE",
        mapID = 940,
        x = 0.750,
        y = 0.750
    }
}


ns.Nodes.DARK_IRON_CITY = {
    SHADOWFORGE_CITY_MOLE = {
        name = "Shadowforge City",
        faction = "ALLIANCE",
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
}


ns.Nodes.ISLE_OF_GIANTS = {
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
}

