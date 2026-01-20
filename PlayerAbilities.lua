-- PlayerAbilities.lua
-- Player-owned travel methods (hearthstones, toys, class abilities)
local addonName, addon = ...

-----------------------------------------------------------
-- HEARTHSTONES & TOYS
-----------------------------------------------------------
-- These are items/toys that teleport you somewhere
-- We check if the player owns them and if they're off cooldown

addon.TravelItems = {
    -- Standard Hearthstone (everyone has this)
    HEARTHSTONE = {
        id = "HEARTHSTONE",
        name = "Hearthstone",
        itemID = 6948,
        type = "hearthstone",
        castTime = 10,
        cooldown = 1200,
        destination = nil
    },

    -- Dalaran Hearthstone (Legion)
    DALARAN_HEARTHSTONE = {
        id = "DALARAN_HEARTHSTONE",
        name = "Dalaran Hearthstone",
        itemID = 140192,
        type = "toy",
        castTime = 10,
        cooldown = 1200,
        destination = "DALARAN_BROKEN_ISLES"
    },

    -- Garrison Hearthstone (WoD)
    GARRISON_HEARTHSTONE_ALLIANCE = {
        id = "GARRISON_HEARTHSTONE_ALLIANCE",
        name = "Garrison Hearthstone",
        itemID = 110560,
        type = "toy",
        castTime = 10,
        cooldown = 1200,
        destination = "LUNARFALL"
    },

    -- Garrison Hearthstone (WoD)
    GARRISON_HEARTHSTONE_HORDE = {
        id = "GARRISON_HEARTHSTONE_HORDE",
        name = "Garrison Hearthstone",
        itemID = 110560,
        type = "toy",
        castTime = 10,
        cooldown = 1200,
        destination = "FROSTWALL"
    },

    -- Admiral's Compass
    ADMIRALS_COMPASS_ALLIANCE = {
        id = "ADMIRALS_COMPASS_ALLIANCE",
        name = "Admiral's Compass",
        itemID = 128353,
        type = "inventory_item",
        castTime = 5,
        cooldown = 1200,
        destination = "LUNARFALL_SHIPYARD",
        faction = "ALLIANCE"
    },

    ADMIRALS_COMPASS_HORDE = {
        id = "ADMIRALS_COMPASS_HORDE",
        name = "Admiral's Compass",
        itemID = 128353,
        type = "inventory_item",
        castTime = 5,
        cooldown = 1200,
        destination = "FROSTWALL_SHIPYARD",
        faction = "HORDE"
    },

    TESSS_PEACEBLOOM = {
        id = "TESSS_PEACEBLOOM",
        name = "Tess's Peacebloom",
        itemID = 211788,
        type = "toy",
        castTime = 10,
        cooldown = 1800,
        destination = "GILNEAS",
        faction = "ALLIANCE"
    },

    -----------------------------------------------------------
    -- ENGINEERING TOYS
    -----------------------------------------------------------
    WORMHOLE_ARGUS = {
        id = "WORMHOLE_ARGUS",
        name = "Wormhole Generator: Argus",
        itemID = 151652,
        type = "toy",
        castTime = 3,
        cooldown = 900,
        destination = "VINDICAAR_ARGUS", -- Random
        isRandom = true
    },

    WORMHOLE_PANDARIA = {
        id = "WORMHOLE_PANDARIA",
        name = "Wormhole Generator: Pandaria",
        itemID = 87215,
        type = "toy",
        castTime = 3,
        cooldown = 900,
        destination = "JADE_TEMPLE_GROUNDS_FLIGHT", -- Random
        isRandom = true
    },

    WORMHOLE_CENTRIFUGE = {
        id = "WORMHOLE_CENTRIFUGE",
        name = "Wormhole Centrifuge",
        itemID = 112059,
        type = "toy",
        castTime = 5,
        cooldown = 600,
        destinations = { "FROSTFIRE_RIDGE_WORMHOLE", "SHADOWMOON_VALLEY_WORMHOLE", 
            "GORGROND_WORMHOLE", "NAGRAND_DRAENOR_WORMHOLE", "TALADOR_WORMHOLE", "SPIRES_OF_ARAK_WORMHOLE" },
        multiDestination = true
    },

    WORMHOLE_NORTHREND = {
        id = "WORMHOLE_NORTHREND",
        name = "Wormhole Generator: Northrend",
        itemID = 48933,
        type = "toy",
        castTime = 5,
        cooldown = 14400,
        destinations = { "BOREAN_TUNDRA_WORMHOLE", "HOWLING_FJORD_WORMHOLE", 
            "STORM_PEAKS_WORMHOLE", "SHOLAZAR_BASIN_WORMHOLE" },
        multiDestination = true
    },

    WORMHOLE_SHADOWLANDS = {
        id = "WORMHOLE_SHADOWLANDS",
        name = "Wormhole Generator: Shadowlands",
        itemID = 172924,
        type = "toy",
        castTime = 5,
        cooldown = 900,
        destinations = { "ORIBOS_WORMHOLE", "BASTION_WORMHOLE", 
            "MALDRAXXUS_WORMHOLE", "ARDENWEALD_WORMHOLE", "REVENDRETH_WORMHOLE", 
            "THE_MAW_WORMHOLE", "KORTHIA_WORMHOLE" },
        multiDestination = true
    },

    TRANSPORTER_GADGETZAN = {
        id = "TRANSPORTER_GADGETZAN",
        name = "Ultrasafe Transporter: Gadgetzan",
        itemID = 18986,
        type = "toy",
        castTime = 10,
        cooldown = 14400,
        destination = "GADGETZAN_TRANSPORTER",
    },

    TRANSPORTER_TOSHLEYS_STATION = {
        id = "TRANSPORTER_TOSHLEYS_STATION",
        name = "Ultrasafe Transporter: Toshley's Station",
        itemID = 30544,
        type = "toy",
        castTime = 10,
        cooldown = 14400,
        destination = "TOSHLEYS_STATION_TRANSPORTER",
    },

    DIMENSIONAL_RIPPER_EVERLOOK = {
        id = "DIMENSIONAL_RIPPER_EVERLOOK",
        name = "Dimensional Ripper - Everlook",
        itemID = 18984,
        type = "toy",
        castTime = 10,
        cooldown = 14400,
        destination = "EVERLOOK_RIPPER",
    },

    DIMENSIONAL_RIPPER_AREA_52 = {
        id = "DIMENSIONAL_RIPPER_AREA_52",
        name = "Dimensional Ripper - Area 52",
        itemID = 30542,
        type = "toy",
        castTime = 10,
        cooldown = 14400,
        destination = "AREA_52_RIPPER",
    },

    -- Jaina's Locket (WotLK - Dalaran)
    JAINAS_LOCKET = {
        id = "JAINAS_LOCKET",
        name = "Jaina's Locket",
        itemID = 52251,
        type = "inventory_item",
        castTime = 10,
        cooldown = 3600,
        destination = "DALARAN_NORTHREND"
    },

    -- Dalaran Signet Ring (WotLK - Dalaran)
    DALARAN_SIGNET = {
        id = "DALARAN_SIGNET",
        name = "Signet of the Kirin Tor",
        itemID = 40586,
        type = "inventory_item",
        castTime = 10,
        cooldown = 1800,
        destination = "DALARAN_NORTHREND"
    },

    -- Delver's Mana-Bound Ethergate
    DELVERS_ETHERGATE = {
        id = "DELVERS_ETHERGATE",
        name = "Delver's Mana-Bound Ethergate",
        itemID = 243056,
        type = "toy",
        castTime = 10,
        cooldown = 7200,
        destination = "DORNOGAL_DELVE_HALL"
    },

    -- Lucky Tortollan Charm
    LUCKY_TORTOLLAN_CHARM = {
        id = "LUCKY_TORTOLLAN_CHARM",
        name = "Lucky Tortollan Charm",
        itemID = 202046,
        type = "inventory_item",
        castTime = 10,
        cooldown = 3600,
        destination = "TORTOLLAN_BASE_CAMP"
    },

    -- Guild Cloaks (Alliance)
    CLOAK_OF_COORDINATION_ALLIANCE = {
        id = "CLOAK_OF_COORDINATION_ALLIANCE",
        name = "Cloak of Coordination",
        itemID = 65360,
        type = "inventory_item",
        castTime = 10,
        cooldown = 7200,
        destination = "STORMWIND_PORTAL_ROOM_LOWER",
    },

    WRAP_OF_UNITY_ALLIANCE = {
        id = "WRAP_OF_UNITY_ALLIANCE",
        name = "Wrap of Unity",
        itemID = 63206,
        type = "inventory_item",
        castTime = 10,
        cooldown = 14400,
        destination = "STORMWIND_PORTAL_ROOM_LOWER",
    },

    SHROUD_OF_COOPERATION_ALLIANCE = {
        id = "SHROUD_OF_COOPERATION_ALLIANCE",
        name = "Shroud of Cooperation",
        itemID = 63352,
        type = "inventory_item",
        castTime = 10,
        cooldown = 28800,
        destination = "STORMWIND_PORTAL_ROOM_LOWER",
    },

    -- Guild Cloaks (Horde)
    CLOAK_OF_COORDINATION_HORDE = {
        id = "CLOAK_OF_COORDINATION_HORDE",
        name = "Cloak of Coordination",
        itemID = 65274,
        type = "inventory_item",
        castTime = 10,
        cooldown = 7200,
        destination = "ORGRIMMAR_PORTAL_ROOM_UPPER",
    },

    WRAP_OF_UNITY_HORDE = {
        id = "WRAP_OF_UNITY_HORDE",
        name = "Wrap of Unity",
        itemID = 63207,
        type = "inventory_item",
        castTime = 10,
        cooldown = 14400,
        destination = "ORGRIMMAR_PORTAL_ROOM_UPPER",
    },

    SHROUD_OF_COOPERATION_HORDE = {
        id = "SHROUD_OF_COOPERATION_HORDE",
        name = "Shroud of Cooperation",
        itemID = 63353,
        type = "inventory_item",
        castTime = 10,
        cooldown = 28800,
        destination = "ORGRIMMAR_PORTAL_ROOM_UPPER",
    },

    TIME_LOST_ARTIFACT = {
        id = "TIME_LOST_ARTIFACT",
        name = "Time-Lost Artifact",
        itemID = 103678,
        type = "inventory_item",
        castTime = 10,
        cooldown = 60,
        destination = "TIMELESS_ISLE"
    },

    BARADINS_WARDENS_TABARD = {
        id = "BARADINS_WARDENS_TABARD",
        name = "Baradin's Wardens Tabard",
        itemID = 63379,
        type = "inventory_item",
        castTime = 10,
        cooldown = 14400,
        destination = "TOL_BARAD_ALLIANCE",
    },

    HELLSCREAMS_REACH_TABARD = {
        id = "HELLSCREAMS_REACH_TABARD",
        name = "Hellscream's Reach Tabard",
        itemID = 63378,
        type = "inventory_item",
        castTime = 10,
        cooldown = 14400,
        destination = "TOL_BARAD_HORDE",
    },

    ARGENT_CRUSADERS_TABARD = {
        id = "ARGENT_CRUSADERS_TABARD",
        name = "Argent Crusader's Tabard",
        itemID = 46874,
        type = "inventory_item",
        castTime = 10,
        cooldown = 1800,
        destination = "ARGENT_TOURNAMENT_GROUNDS"
    },

    PUGILISTS_POWERFUL_PUNCHING_RING_ALLIANCE = {
        id = "PUGILISTS_POWERFUL_PUNCHING_RING_ALLIANCE",
        name = "Pugilist's Powerful Punching Ring",
        itemID = 144391,
        type = "inventory_item",
        castTime = 10,
        cooldown = 3600,
        destination = "BIZMOS_BRAWLPUB"
    },

    PUGILISTS_POWERFUL_PUNCHING_RING_HORDE = {
        id = "PUGILISTS_POWERFUL_PUNCHING_RING_HORDE",
        name = "Pugilist's Powerful Punching Ring",
        itemID = 144392,
        type = "inventory_item",
        castTime = 10,
        cooldown = 3600,
        destination = "BRAWLGAR_ARENA"
    },

    BLESSED_MEDALLION_OF_KARABOR = {
        id = "BLESSED_MEDALLION_OF_KARABOR",
        name = "Blessed Medallion of Karabor",
        itemID = 32757,
        type = "inventory_item",
        castTime = 40,
        cooldown = 900,
        destination = "BLACK_TEMPLE"
    },

    VIOLET_SEAL_OF_THE_GRAND_MAGUS = {
        id = "VIOLET_SEAL_OF_THE_GRAND_MAGUS",
        name = "Violet Seal of the Grand Magus",
        itemID = 142469,
        type = "inventory_item",
        castTime = 0,
        cooldown = 14400,
        destination = "KARAZHAN"
    },

    ULTRASAFE_TRANSPORTER_MECHAGON = {
        id = "ULTRASAFE_TRANSPORTER_MECHAGON",
        name = "Ultrasafe Transporter: Mechagon",
        itemID = 167075,
        type = "inventory_item",
        castTime = 10,
        cooldown = 60,
        destination = "MECHAGON"
    },

    ATTENDANTS_POCKET_PORTAL_MALDRAXXUS = {
        id = "ATTENDANTS_POCKET_PORTAL_MALDRAXXUS",
        name = "Attendant's Pocket Portal: Maldraxxus",
        itemID = 184502,
        type = "inventory_item",
        castTime = 5,
        cooldown = 300,
        destination = "MALDRAXXUS_POCKET_PORTAL"
    },

    ATTENDANTS_POCKET_PORTAL_ARDENWEALD = {
        id = "ATTENDANTS_POCKET_PORTAL_ARDENWEALD",
        name = "Attendant's Pocket Portal: Ardenweald",
        itemID = 184503,
        type = "inventory_item",
        castTime = 5,
        cooldown = 300,
        destination = "ARDENWEALD_POCKET_PORTAL"
    },

    ATTENDANTS_POCKET_PORTAL_BASTION = {
        id = "ATTENDANTS_POCKET_PORTAL_BASTION",
        name = "Attendant's Pocket Portal: Bastion",
        itemID = 184500,
        type = "inventory_item",
        castTime = 5,
        cooldown = 300,
        destination = "BASTION_POCKET_PORTAL"
    },

    ATTENDANTS_POCKET_PORTAL_ORIBOS = {
        id = "ATTENDANTS_POCKET_PORTAL_ORIBOS",
        name = "Attendant's Pocket Portal: Oribos",
        itemID = 184504,
        type = "inventory_item",
        castTime = 5,
        cooldown = 300,
        destination = "ORIBOS"
    },

    ATTENDANTS_POCKET_PORTAL_REVENDRETH = {
        id = "ATTENDANTS_POCKET_PORTAL_REVENDRETH",
        name = "Attendant's Pocket Portal: Revendreth",
        itemID = 184501,
        type = "inventory_item",
        castTime = 5,
        cooldown = 300,
        destination = "REVENDRETH_POCKET_PORTAL"
    },
}

-----------------------------------------------------------
-- CLASS TELEPORTS
-----------------------------------------------------------
-- Spells that teleport you to specific locations
-- Checked based on player class

addon.ClassTeleports = {
    -- MAGE
    MAGE_TP_STORMWIND = {
        id = "MAGE_TP_STORMWIND",
        name = "Teleport: Stormwind",
        spellID = 3561,
        class = "MAGE",
        castTime = 10,
        cooldown = 0,
        destination = "STORMWIND_PORTAL_ROOM_LOWER",
    },

    MAGE_TP_ORGRIMMAR = {
        id = "MAGE_TP_ORGRIMMAR",
        name = "Teleport: Orgrimmar",
        spellID = 3567,
        class = "MAGE",
        castTime = 10,
        cooldown = 0,
        destination = "ORGRIMMAR_PORTAL_ROOM_UPPER",
    },

    MAGE_TP_IRONFORGE = {
        id = "MAGE_TP_IRONFORGE",
        name = "Teleport: Ironforge",
        spellID = 3562,
        class = "MAGE",
        castTime = 10,
        cooldown = 0,
        destination = "IRONFORGE",
    },

    MAGE_TP_THUNDER_BLUFF = {
        id = "MAGE_TP_THUNDER_BLUFF",
        name = "Teleport: Thunder Bluff",
        spellID = 3566,
        class = "MAGE",
        castTime = 10,
        cooldown = 0,
        destination = "THUNDER_BLUFF",
    },

    MAGE_TP_DARNASSUS = {
        id = "MAGE_TP_DARNASSUS",
        name = "Teleport: Darnassus",
        spellID = 3565,
        class = "MAGE",
        castTime = 10,
        cooldown = 0,
        destination = "DARNASSUS",
    },

    MAGE_TP_SILVERMOON = {
        id = "MAGE_TP_SILVERMOON",
        name = "Teleport: Silvermoon",
        spellID = 32272,
        class = "MAGE",
        castTime = 10,
        cooldown = 0,
        destination = "SILVERMOON",
    },

    MAGE_TP_UNDERCITY = {
        id = "MAGE_TP_UNDERCITY",
        name = "Teleport: Undercity",
        spellID = 3563,
        class = "MAGE",
        castTime = 10,
        cooldown = 0,
        destination = "UNDERCITY",
    },

    MAGE_TP_EXODAR = {
        id = "MAGE_TP_EXODAR",
        name = "Teleport: Exodar",
        spellID = 32271,
        class = "MAGE",
        castTime = 10,
        cooldown = 0,
        destination = "EXODAR",
    },

    MAGE_TP_THERAMORE = {
        id = "MAGE_TP_THERAMORE",
        name = "Teleport: Theramore",
        spellID = 49359,
        class = "MAGE",
        castTime = 10,
        cooldown = 0,
        destination = "THERAMORE",
    },

    MAGE_TP_STONARD = {
        id = "MAGE_TP_STONARD",
        name = "Teleport: Stonard",
        spellID = 49358,
        class = "MAGE",
        castTime = 10,
        cooldown = 0,
        destination = "STONARD",
    },

    MAGE_TP_SHATTRATH_1 = {
        id = "MAGE_TP_SHATTRATH_1",
        name = "Teleport: Shattrath",
        spellID = 33690,
        class = "MAGE",
        castTime = 10,
        cooldown = 0,
        destination = "SHATTRATH_OUTLANDS"
    },

    MAGE_TP_SHATTRATH_2 = {
        id = "MAGE_TP_SHATTRATH_1",
        name = "Teleport: Shattrath",
        spellID = 35715,
        class = "MAGE",
        castTime = 10,
        cooldown = 0,
        destination = "SHATTRATH_OUTLANDS"
    },

    MAGE_TP_DALARAN_NORTHREND = {
        id = "MAGE_TP_DALARAN_NORTHREND",
        name = "Teleport: Dalaran - Northrend",
        spellID = 53140,
        class = "MAGE",
        castTime = 10,
        cooldown = 0,
        destination = "DALARAN_NORTHREND"
    },

    MAGE_TP_TOL_BARAD_ALLIANCE = {
        id = "MAGE_TP_TOL_BARAD_ALLIANCE",
        name = "Teleport: Tol Barad",
        spellID = 88342,
        class = "MAGE",
        castTime = 10,
        cooldown = 0,
        destination = "TOL_BARAD_ALLIANCE",
    },
    
    MAGE_TP_TOL_BARAD_HORDE = {
        id = "MAGE_TP_TOL_BARAD_HORDE",
        name = "Teleport: Tol Barad",
        spellID = 88344,
        class = "MAGE",
        castTime = 10,
        cooldown = 0,
        destination = "TOL_BARAD_HORDE",
    },

    MAGE_TP_ANCIENT_DALARAN = {
        id = "MAGE_TP_ANCIENT_DALARAN",
        name = "Ancient Teleport: Dalaran",
        spellID = 120145,
        class = "MAGE",
        castTime = 10,
        cooldown = 0,
        destination = "DALARAN_CRATER"
    },

    MAGE_TP_VALE_OF_ETERNAL_BLOSSOMS_ALLIANCE = {
        id = "MAGE_TP_VALE_OF_ETERNAL_BLOSSOMS_ALLIANCE",
        name = "Teleport: Vale of Eternal Blossoms",
        spellID = 132621,
        class = "MAGE",
        castTime = 10,
        cooldown = 0,
        destination = "SHRINE_OF_SEVEN_STARS",
    },

    MAGE_TP_VALE_OF_ETERNAL_BLOSSOMS_HORDE= {
        id = "MAGE_TP_VALE_OF_ETERNAL_BLOSSOMS_HORDE",
        name = "Teleport: Vale of Eternal Blossoms",
        spellID = 132627,
        class = "MAGE",
        castTime = 10,
        cooldown = 0,
        destination = "SHRINE_OF_TWO_MOONS",
    },

    MAGE_TP_STORMSHIELD = {
        id = "MAGE_TP_STORMSHIELD",
        name = "Teleport: Stormshield",
        spellID = 176248,
        class = "MAGE",
        castTime = 10,
        cooldown = 0,
        destination = "STORMSHIELD_ASHRAN",
    },

    MAGE_TP_WARSPEAR = {
        id = "MAGE_TP_WARSPEAR",
        name = "Teleport: Warspear",
        spellID = 176242,
        class = "MAGE",
        castTime = 10,
        cooldown = 0,
        destination = "WARSPEAR_ASHRAN",
    },

    MAGE_TP_HALL_OF_THE_GUARDIAN = {
        id = "MAGE_TP_HALL_OF_THE_GUARDIAN",
        name = "Teleport: Hall of the Guardian",
        spellID = 193759,
        class = "MAGE",
        castTime = 10,
        cooldown = 0,
        destination = "HALL_OF_THE_GUARDIAN"
    },

    MAGE_TP_DALARAN_BROKEN_ISLES = {
        id = "MAGE_TP_DALARAN_BROKEN_ISLES",
        name = "Teleport: Dalaran - Broken Isles",
        spellID = 224869,
        class = "MAGE",
        castTime = 10,
        cooldown = 0,
        destination = "DALARAN_BROKEN_ISLES"
    },
  
    MAGE_TP_BORALUS = {
        id = "MAGE_TP_BORALUS",
        name = "Teleport: Boralus",
        spellID = 281403,
        class = "MAGE",
        castTime = 10,
        cooldown = 0,
        destination = "BORALUS",
    },

    MAGE_TP_DAZARALOR = {
        id = "MAGE_TP_DAZARALOR",
        name = "Teleport: Dazar'alor",
        spellID = 281404,
        class = "MAGE",
        castTime = 10,
        cooldown = 0,
        destination = "DAZARALOR_PORTAL_ROOM",
    },

    MAGE_TP_ORIBOS = {
        id = "MAGE_TP_ORIBOS",
        name = "Teleport: Oribos",
        spellID = 344587,
        class = "MAGE",
        castTime = 10,
        cooldown = 0,
        destination = "ORIBOS"
    },

    MAGE_TP_VALDRAKKEN = {
        id = "MAGE_TP_VALDRAKKEN",
        name = "Teleport: Valdrakken",
        spellID = 395277,
        class = "MAGE",
        castTime = 10,
        cooldown = 0,
        destination = "VALDRAKKEN"
    },

    MAGE_TP_DORNOGAL = {
        id = "MAGE_TP_DORNOGAL",
        name = "Teleport: Dornogal",
        spellID = 446540,
        class = "MAGE",
        castTime = 10,
        cooldown = 0,
        destination = "DORNOGAL_PORTAL_ROOM"
    },

    -- DRUID
    DRUID_TP_MOONGLADE = {
        id = "DRUID_TP_MOONGLADE",
        name = "Teleport: Moonglade",
        spellID = 18960,
        class = "DRUID",
        castTime = 10,
        cooldown = 0,
        destination = "MOONGLADE"
    },

    DRUID_TP_DREAMWALK = {
        id = "DRUID_TP_DREAMWALK",
        name = "Dreamwalk",
        spellID = 193753,
        class = "DRUID",
        castTime = 10,
        cooldown = 60,
        destination = "EMERALD_DREAMWAY"
    },

    -- DEATH KNIGHT
    DK_TP_ACHERUS = {
        id = "DK_TP_ACHERUS",
        name = "Death Gate",
        spellID = 50977,
        class = "DEATHKNIGHT",
        castTime = 10,
        cooldown = 60,
        destination = "ACHERUS"
    },

    -- MONK
    MONK_TP_PEAK = {
        id = "MONK_TP_PEAK",
        name = "Zen Pilgrimage",
        spellID = 126892,
        class = "MONK",
        castTime = 10,
        cooldown = 60,
        destination = "PEAK_OF_SERENITY"
    },

    -- SHAMAN (Astral Recall)
    SHAMAN_TP_HEARTH = {
        id = "SHAMAN_TP_HEARTH",
        name = "Astral Recall",
        spellID = 556,
        class = "SHAMAN",
        castTime = 10,
        cooldown = 900,
        type = "hearthstone",
        destination = nil
    },
}

-----------------------------------------------------------
-- RACIAL ABILITIES
-----------------------------------------------------------
-- Race-specific travel abilities

addon.RacialAbilities = {
    -- Dark Iron Dwarf - Mole Machine
    MOLE_MACHINE = {
        id = "MOLE_MACHINE",
        name = "Mole Machine",
        spellID = 265225,
        race = "DarkIronDwarf",
        castTime = 5,
        cooldown = 1800,
        destinations = { 
            "STORMWIND_CITY_MOLE",
            "IRONFORGE_MOLE",
            "SHADOWFORGE_CITY_MOLE",
            "BLACKROCK_MOUNTAIN_MOLE",
            "AERIE_PEAK_MOLE",
            "NETHERGARDE_KEEP_MOLE",
            "FIRE_PLUME_RIDGE_MOLE",
            "THE_GREAT_DIVIDE_MOLE",
            "THRONE_OF_FLAME_MOLE",
            "HONOR_HOLD_MOLE",
            "BLADES_EDGE_MOUNTAINS_MOLE",
            "SHADOWMOON_VALLEY_OUTLANDS_MOLE",
            "RUBY_DRAGONSHRINE_MOLE",
            "ARGENT_TOURNAMENT_GROUNDS_MOLE",
            "VALLEY_OF_THE_FOUR_WINDS_MOLE",
            "KUN_LAI_SUMMIT_MOLE",
            "GORGROND_MOLE", 
            "NAGRAND_DRAENOR_MOLE",
            "THE_BROKEN_SHORE_MOLE",
            "HIGHMOUNTAIN_MOLE",
            "ZULDAZAR_MOLE",
            "NAZMIR_MOLE",
            "TIRAGARDE_SOUND_MOLE",
            "STORMSONG_VALLEY_MOLE", 
            "MALDRAXXUS_MOLE",
            "REVENDRETH_MOLE",
            "ARDENWEALD_MOLE",
            "BASTION_MOLE",
            "THE_WAKING_SHORES_MOLE",
            "AZURE_SPAN_MOLE",
            "ZARALEK_CAVERN_MOLE",
        },
    },
    
    -- Potentially add later:
    -- Vulpera - Make Camp / Return to Camp (hearthstone-like)
}

-----------------------------------------------------------
-- DUNGEON TELEPORTS
-----------------------------------------------------------
-- Spells that teleport you to specific dungeons

addon.DungeonTeleports = {
    TELEPORT_TO_MANAFORGE_OMEGA = {
        id = "TELEPORT_TO_MANAFORGE_OMEGA",
        name = "Path of the All-Devouring",
        spellID = 1239155,
        castTime = 10,
        cooldown = 28800,
        destination = "MANAFORGE_OMEGA_RAID"
    },

    TELEPORT_TO_NELTHARIONS_LAIR = {
        id = "TELEPORT_TO_NELTHARIONS_LAIR",
        name = "Path of the Earth-Warder",
        spellID = 410078,
        castTime = 10,
        cooldown = 28800,
        destination = "NELTHARIONS_LAIR_DUNGEON"
    },

    TELEPORT_TO_KARAZHAN = {
        id = "TELEPORT_TO_KARAZHAN",
        name = "Path of the Fallen Guardian",
        spellID = 373262,
        castTime = 10,
        cooldown = 28800,
        destination = "KARAZHAN"
    },

    TELEPORT_TO_THE_ROOKERY = {
        id = "TELEPORT_TO_THE_ROOKERY",
        name = "Path of the Fallen Stormriders",
        spellID = 445443,
        castTime = 10,
        cooldown = 28800,
        destination = "THE_ROOKERY_DUNGEON"
    },

    TELEPORT_TO_HALLS_OF_ATONEMENT = {
        id = "TELEPORT_TO_HALLS_OF_ATONEMENT",
        name = "Path of the Sinful Soul",
        spellID = 354465,
        castTime = 10,
        cooldown = 28800,
        destination = "HALLS_OF_ATONEMENT_DUNGEON"
    },

    TELEPORT_TO_TAZAVESH_THE_VEILED_MARKET = {
        id = "TELEPORT_TO_TAZAVESH_THE_VEILED_MARKET",
        name = "Path of the Streetwise Merchant",
        spellID = 367416,
        castTime = 10,
        cooldown = 28800,
        destination = "TAZAVESH_THE_VEILED_MARKET_DUNGEON"
    },

    TELEPORT_TO_HALLS_OF_VALOR = {
        id = "TELEPORT_TO_HALLS_OF_VALOR",
        name = "Path of the Proven Worth",
        spellID = 393764,
        castTime = 10,
        cooldown = 28800,
        destination = "HALLS_OF_VALOR_DUNGEON"
    },

    TELEPORT_TO_COURT_OF_STARS = {
        id = "TELEPORT_TO_COURT_OF_STARS",
        name = "Path of the Grand Magistrix",
        spellID = 393766,
        castTime = 10,
        cooldown = 28800,
        destination = "COURT_OF_STARS_DUNGEON"
    },

    TELEPORT_TO_BLACK_ROOK_HOLD = {
        id = "TELEPORT_TO_BLACK_ROOK_HOLD",
        name = "Path of Ancient Horrors",
        spellID = 424153,
        castTime = 10,
        cooldown = 28800,
        destination = "BLACK_ROOK_HOLD_DUNGEON"
    },

    TELEPORT_TO_DARKHEART_THICKET = {
        id = "TELEPORT_TO_DARKHEART_THICKET",
        name = "Path of the Nightmare Lord",
        spellID = 424163,
        castTime = 10,
        cooldown = 28800,
        destination = "DARKHEART_THICKET_DUNGEON"
    },

    TELEPORT_TO_THE_DAWNBREAKER = {
        id = "TELEPORT_TO_THE_DAWNBREAKER",
        name = "Path of the Arathi Flagship",
        spellID = 445414,
        castTime = 10,
        cooldown = 28800,
        destination = "THE_DAWNBREAKER_DUNGEON"
    },

    TELEPORT_TO_OPERATION_FLOODGATE = {
        id = "TELEPORT_TO_OPERATION_FLOODGATE",
        name = "Path of the Circuit Breaker",
        spellID = 1216786,
        castTime = 10,
        cooldown = 28800,
        destination = "OPERATION_FLOODGATE_DUNGEON"
    },

    TELEPORT_TO_ECO_DOME_ALDANI = {
        id = "TELEPORT_TO_ECO_DOME_ALDANI",
        name = "Path of the Eco-Dome",
        spellID = 1237215,
        castTime = 10,
        cooldown = 28800,
        destination = "ECO_DOME_ALDANI_DUNGEON"
    },

    TELEPORT_TO_THE_VORTEX_PINNACLE = {
        id = "TELEPORT_TO_VORTEX_PINNACLE",
        name = "Path of Wind's Domain",
        spellID = 410080,
        castTime = 10,
        cooldown = 28800,
        destination = "THE_VORTEX_PINNACLE_DUNGEON"
    },
    TELEPORT_TO_PIT_OF_SARON = {
        id = "TELEPORT_TO_PIT_OF_SARON",
        name = "Path of Unyielding Blight",
        spellID = 1254555,
        castTime = 10,
        cooldown = 28800,
        destination = "PIT_OF_SARON_DUNGEON"
    },

    TELEPORT_TO_DAWN_OF_THE_INFINITES = {
        id = "TELEPORT_TO_DAWN_OF_THE_INFINITES",
        name = "Path of Twisted Time",
        spellID = 424197,
        castTime = 10,
        cooldown = 28800,
        destination = "DAWN_OF_THE_INFINITES_DUNGEON"
    },

    TELEPORT_TO_THE_NOKHUD_OFFENSIVE = {
        id = "TELEPORT_TO_THE_NOKHUD_OFFENSIVE",
        name = "Path of the Windswept Plains",
        spellID = 393262,
        castTime = 10,
        cooldown = 28800,
        destination = "THE_NOKHUD_OFFENSIVE_DUNGEON"
    },

    TELEPORT_TO_WINDRUNNER_SPIRE = {
        id = "TELEPORT_TO_WINDRUNNER_SPIRE",
        name = "Path of the Windrunners",
        spellID = 1254400,
        castTime = 10,
        cooldown = 28800,
        destination = "WINDRUNNER_SPIRE_DUNGEON"
    },

    TELEPORT_TO_CINDERBREW_MEADERY_1 = {
        id = "TELEPORT_TO_CINDERBREW_MEADERY_1",
        name = "Path of the Waterworks",
        spellID = 467546,
        castTime = 10,
        cooldown = 28800,
        destination = "CINDERBREW_MEADERY_DUNGEON"
    },

    TELEPORT_TO_ULDAMAN_LEGACY_OF_TYR = {
        id = "TELEPORT_TO_ULDAMAN_LEGACY_OF_TYR",
        name = "Path of the Watcher's Legacy",
        spellID = 393222,
        castTime = 10,
        cooldown = 28800,
        destination = "ULDAMAN_LEGACY_OF_TYR_DUNGEON"
    },

    TELEPORT_TO_DARKFLAME_CLEFT = {
        id = "TELEPORT_TO_DARKFLAME_CLEFT",
        name = "Path of the Warding Candles",
        spellID = 445441,
        castTime = 10,
        cooldown = 28800,
        destination = "DARKFLAME_CLEFT_DUNGEON"
    },

    TELEPORT_TO_AUCHINDOUN = {
        id = "TELEPORT_TO_AUCHINDOUN",
        name = "Path of the Vigilant",
        spellID = 159897,
        castTime = 10,
        cooldown = 28800,
        destination = "AUCHINDOUN_DUNGEON"
    },

    TELEPORT_TO_THE_EVERBLOOM = {
        id = "TELEPORT_TO_THE_EVERBLOOM",
        name = "Path of the Verdant",
        spellID = 159901,
        castTime = 10,
        cooldown = 28800,
        destination = "THE_EVERBLOOM_DUNGEON"
    },

    TELEPORT_TO_THEATER_OF_PAIN = {
        id = "TELEPORT_TO_THEATER_OF_PAIN",
        name = "Path of the Undefeated",
        spellID = 354467,
        castTime = 10,
        cooldown = 28800,
        destination = "THEATER_OF_PAIN_DUNGEON"
    },

    TELEPORT_TO_GRIM_BATOL = {
        id = "TELEPORT_TO_GRIM_BATOL",
        name = "Path of the Twilight Fortress",
        spellID = 445424,
        castTime = 10,
        cooldown = 28800,
        destination = "GRIM_BATOL_DUNGEON"
    },

    TELEPORT_TO_SANCTUM_OF_DOMINATION = {
        id = "TELEPORT_TO_SANCTUM_OF_DOMINATION",
        name = "Path of the Tormented Soul",
        spellID = 373191,
        castTime = 10,
        cooldown = 28800,
        destination = "SANCTUM_OF_DOMINATION_RAID"
    },

    TELEPORT_TO_HALLS_OF_INFUSION = {
        id = "TELEPORT_TO_HALLS_OF_INFUSION",
        name = "Path of the Titanic Reservoir",
        spellID = 393283,
        castTime = 10,
        cooldown = 28800,
        destination = "HALLS_OF_INFUSION_DUNGEON"
    },

    TELEPORT_TO_THRONE_OF_THE_TIDES = {
        id = "TELEPORT_TO_THRONE_OF_THE_TIDES",
        name = "Path of the Tidehunter",
        spellID = 424142,
        castTime = 10,
        cooldown = 28800,
        destination = "THRONE_OF_THE_TIDES_DUNGEON"
    },

    TELEPORT_TO_STORMSTOUT_BREWERY = {
        id = "TELEPORT_TO_STORMSTOUT_BREWERY",
        name = "Path of the Stout Brew",
        spellID = 131205,
        castTime = 10,
        cooldown = 28800,
        destination = "STORMSTOUT_BREWERY_DUNGEON"
    },

    TELEPORT_TO_SANGUINE_DEPTHS = {
        id = "TELEPORT_TO_SANGUINE_DEPTHS",
        name = "Path of the Stone Warden",
        spellID = 354469,
        castTime = 10,
        cooldown = 28800,
        destination = "SANGUINE_DEPTHS_DUNGEON"
    },

    TELEPORT_TO_SKYREACH = {
        id = "TELEPORT_TO_SKYREACH",
        name = "Path of the Skies",
        spellID = 159898,
        castTime = 10,
        cooldown = 28800,
        destination = "SKYREACH_DUNGEON"
    },

    TELEPORT_TO_CASTLE_NATHRIA = {
        id = "TELEPORT_TO_CASTLE_NATHRIA",
        name = "Path of the Sire",
        spellID = 373190,
        castTime = 10,
        cooldown = 28800,
        destination = "CASTLE_NATHRIA_RAID"
    },

    TELEPORT_TO_SHADOPAN_MONASTERY = {
        id = "TELEPORT_TO_SHADOPAN_MONASTERY",
        name = "Path of the Shado-Pan",
        spellID = 131206,
        castTime = 10,
        cooldown = 28800,
        destination = "SHADOPAN_MONASTERY_DUNGEON"
    },

    TELEPORT_TO_GATE_OF_THE_SETTING_SUN = {
        id = "TELEPORT_TO_GATE_OF_THE_SETTING_SUN",
        name = "Path of the Setting Sun",
        spellID = 131225,
        castTime = 10,
        cooldown = 28800,
        destination = "GATE_OF_THE_SETTING_SUN_DUNGEON"
    },

    TELEPORT_TO_OPERATION_MECHAGON = {
        id = "TELEPORT_TO_OPERATION_MECHAGON",
        name = "Path of the Scrappy Prince",
        spellID = 373274,
        castTime = 10,
        cooldown = 28800,
        destination = "OPERATION_MECHAGON_DUNGEON"
    },

    TELEPORT_TO_AMIRDRASSIL_THE_DREAMS_HOPE = {
        id = "TELEPORT_TO_AMIRDRASSIL_THE_DREAMS_HOPE",
        name = "Path of the Scorching Dream",
        spellID = 432258,
        castTime = 10,
        cooldown = 28800,
        destination = "AMIRDRASSIL_THE_DREAMS_HOPE_RAID"
    },

    TELEPORT_TO_DE_OTHER_SIDE = {
        id = "TELEPORT_TO_DE_OTHER_SIDE",
        name = "Path of the Scheming Loa",
        spellID = 354468,
        castTime = 10,
        cooldown = 28800,
        destination = "DE_OTHER_SIDE_DUNGEON"
    },

    TELEPORT_TO_SCARLET_MONASTERY = {
        id = "TELEPORT_TO_SCARLET_MONASTERY",
        name = "Path of the Scarlet Mitre",
        spellID = 131229,
        castTime = 10,
        cooldown = 28800,
        destination = "SCARLET_MONASTERY_DUNGEON"
    },

    TELEPORT_TO_SCARLET_HALLS = {
        id = "TELEPORT_TO_SCARLET_HALLS",
        name = "Path of the Scarlet Blade",
        spellID = 131231,
        castTime = 10,
        cooldown = 28800,
        destination = "SCARLET_HALLS_DUNGEON"
    },

    TELEPORT_TO_ARA_KARA_CITY_OF_ECHOES = {
        id = "TELEPORT_TO_ARA_KARA_CITY_OF_ECHOES",
        name = "Path of the Ruined City",
        spellID = 445417,
        castTime = 10,
        cooldown = 28800,
        destination = "ARA_KARA_CITY_OF_ECHOES_DUNGEON"
    },

    TELEPORT_TO_BRACKENHIDE_HOLLOW = {
        id = "TELEPORT_TO_BRACKENHIDE_HOLLOW",
        name = "Path of the Rotting Woods",
        spellID = 393267,
        castTime = 10,
        cooldown = 28800,
        destination = "BRACKENHIDE_HOLLOW_DUNGEON"
    },

    TELEPORT_TO_VAULT_OF_THE_INCARNATES = {
        id = "TELEPORT_TO_VAULT_OF_THE_INCARNATES",
        name = "Path of the Primal Prison",
        spellID = 432254,
        castTime = 10,
        cooldown = 28800,
        destination = "VAULT_OF_THE_INCARNATES_RAID"
    },

    TELEPORT_TO_PLAGUEFALL = {
        id = "TELEPORT_TO_PLAGUEFALL",
        name = "Path of the Plagued",
        spellID = 354463,
        castTime = 10,
        cooldown = 28800,
        destination = "PLAGUEFALL_DUNGEON"
    },

    TELEPORT_TO_NELTHARUS = {
        id = "TELEPORT_TO_NELTHARUS",
        name = "Path of the Obsidian Hoard",
        spellID = 393276,
        castTime = 10,
        cooldown = 28800,
        destination = "NELTHARUS_DUNGEON"
    },

    TELEPORT_TO_SCHOLOMANCE = {
        id = "TELEPORT_TO_SCHOLOMANCE",
        name = "Path of the Necromancer",
        spellID = 131232,
        castTime = 10,
        cooldown = 28800,
        destination = "SCHOLOMANCE_DUNGEON"
    },

    TELEPORT_TO_MOGUSHAN_PALACE = {
        id = "TELEPORT_TO_MOGUSHAN_PALACE",
        name = "Path of the Mogu King",
        spellID = 131222,
        castTime = 10,
        cooldown = 28800,
        destination = "MOGUSHAN_PALACE_DUNGEON"
    },

    TELEPORT_TO_MISTS_OF_TIRNA_SCITHE = {
        id = "TELEPORT_TO_MISTS_OF_TIRNA_SCITHE",
        name = "Path of the Misty Forest",
        spellID = 354464,
        castTime = 10,
        cooldown = 28800,
        destination = "MISTS_OF_TIRNA_SCITHE_DUNGEON"
    },

    TELEPORT_TO_PRIORY_OF_THE_SACRED_FLAME = {
        id = "TELEPORT_TO_PRIORY_OF_THE_SACRED_FLAME",
        name = "Path of the Light's Reverence",
        spellID = 445444,
        castTime = 10,
        cooldown = 28800,
        destination = "PRIORY_OF_THE_SACRED_FLAME_DUNGEON"
    },

    TELEPORT_TO_TEMPLE_OF_THE_JADE_SERPENT = {
        id = "TELEPORT_TO_TEMPLE_OF_THE_JADE_SERPENT",
        name = "Path of the Jade Serpent",
        spellID = 131204,
        castTime = 10,
        cooldown = 28800,
        destination = "TEMPLE_OF_THE_JADE_SERPENT_DUNGEON"
    },

    TELEPORT_TO_IRON_DOCKS = {
        id = "TELEPORT_TO_IRON_DOCKS",
        name = "Path of the Iron Prow",
        spellID = 159896,
        castTime = 10,
        cooldown = 28800,
        destination = "IRON_DOCKS_DUNGEON"
    },

    TELEPORT_TO_ATALDAZAR = {
        id = "TELEPORT_TO_ATALDAZAR",
        name = "Path of the Golden Tomb",
        spellID = 424187,
        castTime = 10,
        cooldown = 28800,
        destination = "ATALDAZAR_DUNGEON"
    },

    TELEPORT_TO_LIBERATION_OF_UNDERMINE = {
        id = "TELEPORT_TO_LIBERATION_OF_UNDERMINE",
        name = "Path of the Full House",
        spellID = 1226482,
        castTime = 10,
        cooldown = 28800,
        destination = "LIBERATION_OF_UNDERMINE_RAID"
    },

    TELEPORT_TO_FREEHOLD = {
        id = "TELEPORT_TO_FREEHOLD",
        name = "Path of the Freebooter",
        spellID = 410071,
        castTime = 10,
        cooldown = 28800,
        destination = "FREEHOLD_DUNGEON"
    },

    TELEPORT_TO_CINDERBREW_MEADERY_2 = {
        id = "TELEPORT_TO_CINDERBREW_MEADERY_2",
        name = "Path of the Flaming Brewery",
        spellID = 445440,
        castTime = 10,
        cooldown = 28800,
        destination = "CINDERBREW_MEADERY_DUNGEON"
    },

    TELEPORT_TO_SEPULCHER_OF_THE_FIRST_ONES = {
        id = "TELEPORT_TO_SEPULCHER_OF_THE_FIRST_ONES",
        name = "Path of the First Ones",
        spellID = 373192,
        castTime = 10,
        cooldown = 28800,
        destination = "SEPULCHER_OF_THE_FIRST_ONES_RAID"
    },

    TELEPORT_TO_ALGETHAR_ACADEMY = {
        id = "TELEPORT_TO_ALGETHAR_ACADEMY",
        name = "Path of the Draconic Diploma",
        spellID = 393272,
        castTime = 10,
        cooldown = 28800,
        destination = "ALGETHAR_ACADEMY_DUNGEON"
    },

    TELEPORT_TO_GRIMRAIL_DEPOT = {
        id = "TELEPORT_TO_GRIMRAIL_DEPOT",
        name = "Path of the Dark Rail",
        spellID = 159900,
        castTime = 10,
        cooldown = 28800,
        destination = "GRIMRAIL_DEPOT_DUNGEON"
    },

    TELEPORT_TO_SKYREACH_2 = {
        id = "TELEPORT_TO_SKYREACH_2",
        name = "Path of the Crowning Pinnacle",
        spellID = 1254557,
        castTime = 10,
        cooldown = 28800,
        destination = "SKYREACH_DUNGEON"
    },

    TELEPORT_TO_SHADOWMOON_BURIAL_GROUNDS = {
        id = "TELEPORT_TO_SHADOWMOON_BURIAL_GROUNDS",
        name = "Path of the Crescent Moon",
        spellID = 159899,
        castTime = 10,
        cooldown = 28800,
        destination = "SHADOWMOON_BURIAL_GROUNDS_DUNGEON"
    },

    TELEPORT_TO_THE_NECROTIC_WAKE = {
        id = "TELEPORT_TO_THE_NECROTIC_WAKE",
        name = "Path of the Courageous",
        spellID = 354462,
        castTime = 10,
        cooldown = 28800,
        destination = "THE_NECROTIC_WAKE_DUNGEON"
    },

    TELEPORT_TO_THE_STONEVAULT = {
        id = "TELEPORT_TO_THE_STONEVAULT",
        name = "Path of the Corrupted Foundry",
        spellID = 445269,
        castTime = 10,
        cooldown = 28800,
        destination = "THE_STONEVAULT_DUNGEON"
    },

    TELEPORT_TO_RUBY_LIFE_POOLS = {
        id = "TELEPORT_TO_RUBY_LIFE_POOLS",
        name = "Path of the Clutch Defender",
        spellID = 393256,
        castTime = 10,
        cooldown = 28800,
        destination = "RUBY_LIFE_POOLS_DUNGEON"
    },

    TELEPORT_TO_UPPER_BLACKROCK_SPIRE = {
        id = "TELEPORT_TO_UPPER_BLACKROCK_SPIRE",
        name = "Path of the Burning Mountain",
        spellID = 159902,
        castTime = 10,
        cooldown = 28800,
        destination = "UPPER_BLACKROCK_SPIRE_DUNGEON"
    },

    TELEPORT_TO_BLOODMAUL_SLAG_MINES = {
        id = "TELEPORT_TO_BLOODMAUL_SLAG_MINES",
        name = "Path of the Bloodmaul",
        spellID = 159895,
        castTime = 10,
        cooldown = 28800,
        destination = "BLOODMAUL_SLAG_MINES_DUNGEON"
    },

    TELEPORT_TO_SIEGE_OF_NIUZAO_TEMPLE = {
        id = "TELEPORT_TO_SIEGE_OF_NIUZAO_TEMPLE",
        name = "Path of the Black Ox",
        spellID = 131228,
        castTime = 10,
        cooldown = 28800,
        destination = "SIEGE_OF_NIUZAO_TEMPLE_DUNGEON"
    },

    TELEPORT_TO_ABERRUS_THE_SHADOWED_CRUCIBLE = {
        id = "TELEPORT_TO_ABERRUS_THE_SHADOWED_CRUCIBLE",
        name = "Path of the Bitter Legacy",
        spellID = 432257,
        castTime = 10,
        cooldown = 28800,
        destination = "ABERRUS_THE_SHADOWED_CRUCIBLE_RAID"
    },

    TELEPORT_TO_SIEGE_OF_BORALUS_ALLIANCE = {
        id = "TELEPORT_TO_SIEGE_OF_BORALUS_ALLIANCE",
        name = "Path of the Besieged Harbor",
        spellID = 445418,
        castTime = 10,
        cooldown = 28800,
        destination = "SIEGE_OF_BORALUS_DUNGEON_ALLIANCE",
        faction = "ALLIANCE"
    },

    TELEPORT_TO_SIEGE_OF_BORALUS_HORDE = {
        id = "TELEPORT_TO_SIEGE_OF_BORALUS_HORDE",
        name = "Path of the Besieged Harbor",
        spellID = 464256,
        castTime = 10,
        cooldown = 28800,
        destination = "SIEGE_OF_BORALUS_DUNGEON_HORDE",
        faction = "HORDE"
    },

    TELEPORT_TO_THE_MOTHERLODE_ALLIANCE = {
        id = "TELEPORT_TO_THE_MOTHERLODE_ALLIANCE",
        name = "Path of the Azerite Refinery",
        spellID = 467553,
        castTime = 10,
        cooldown = 28800,
        destination = "THE_MOTHERLODE_DUNGEON_ALLIANCE",
        faction = "ALLIANCE"
    },

    TELEPORT_TO_THE_MOTHERLODE_HORDE = {
        id = "TELEPORT_TO_THE_MOTHERLODE_HORDE",
        name = "Path of the Azerite Refinery",
        spellID = 467555,
        castTime = 10,
        cooldown = 28800,
        destination = "THE_MOTHERLODE_DUNGEON_HORDE",
        faction = "HORDE"
    },

    TELEPORT_TO_SPIRES_OF_ASCENSION = {
        id = "TELEPORT_TO_SPIRES_OF_ASCENSION",
        name = "Path of the Ascendant",
        spellID = 354466,
        castTime = 10,
        cooldown = 28800,
        destination = "SPIRES_OF_ASCENSION_DUNGEON"
    },

    TELEPORT_TO_CITY_OF_THREADS = {
        id = "TELEPORT_TO_CITY_OF_THREADS",
        name = "Path of Nerubian Ascension",
        spellID = 445416,
        castTime = 10,
        cooldown = 28800,
        destination = "CITY_OF_THREADS_DUNGEON"
    },

    TELEPORT_TO_WAYCREST_MANOR = {
        id = "TELEPORT_TO_WAYCREST_MANOR",
        name = "Path of Heart's Bane",
        spellID = 424167,
        castTime = 10,
        cooldown = 28800,
        destination = "WAYCREST_MANOR_DUNGEON"
    },

    TELEPORT_TO_THE_UNDERROT = {
        id = "TELEPORT_TO_THE_UNDERROT",
        name = "Path of Festering Rot",
        spellID = 410074,
        castTime = 10,
        cooldown = 28800,
        destination = "THE_UNDERROT_DUNGEON"
    },

    TELEPORT_TO_MAGISTERS_TERRACE = {
        id = "TELEPORT_TO_MAGISTERS_TERRACE",
        name = "Path of Devoted Magistry",
        spellID = 1254572,
        castTime = 10,
        cooldown = 28800,
        destination = "MAGISTERS_TERRACE_DUNGEON"
    },

    TELEPORT_TO_SEAT_OF_THE_TRIUMVIRATE = {
        id = "TELEPORT_TO_SEAT_OF_THE_TRIUMVIRATE",
        name = "Path of Dark Dereliction",
        spellID = 1254551,
        castTime = 10,
        cooldown = 28800,
        destination = "SEAT_OF_THE_TRIUMVIRATE_DUNGEON"
    },

    TELEPORT_TO_THE_AZURE_VAULT = {
        id = "TELEPORT_TO_THE_AZURE_VAULT",
        name = "Path of Arcane Secrets",
        spellID = 393279,
        castTime = 10,
        cooldown = 28800,
        destination = "THE_AZURE_VAULT_DUNGEON"
    },
}