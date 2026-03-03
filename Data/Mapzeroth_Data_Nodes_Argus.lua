-- Mapzeroth_Data_Nodes_Argus.lua
-- Argus zones (Legion 7.3)
local _, ns = ...

ns.Nodes = ns.Nodes or {}

ns.Nodes.ARGUS_VINDICAAR = {
    VINDICAAR_ARGUS = {
        name = "The Vindicaar (Argus)",
        mapID = 883,
        x = 0.5826,
        y = 0.8101
    }
}


ns.Nodes.ARGUS_KROKUUN = {
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
}


ns.Nodes.ARGUS_ANTORAN_WASTES = {
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
}


ns.Nodes.ARGUS_EREDATH = {
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
}

