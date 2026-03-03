-- Mapzeroth_Data_Edges.lua
-- Travel edges, traversal group map, and group lookup helper
local _, ns = ...

ns.Edges = { 
-- Stormwind Mage Tower Interior
{
    from = "STORMWIND_BORALUS_PORTAL",
    to = "BORALUS",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "STORMWIND_DORNOGAL_PORTAL",
    to = "DORNOGAL_PORTAL_ROOM",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance",
        minLevel = 68
    }
}, {
    from = "STORMWIND_DALARAN_NORTHREND_PORTAL",
    to = "DALARAN_NORTHREND",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "DALARAN_NORTHREND_STORMWIND_PORTAL",
    to = "STORMWIND_PORTAL_ROOM_LOWER",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "STORMWIND_ORIBOS_PORTAL",
    to = "ORIBOS",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "STORMWIND_STORMSHIELD_PORTAL",
    to = "STORMSHIELD_ASHRAN",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "STORMWIND_SHATTRATH_OUTLANDS_PORTAL",
    to = "SHATTRATH_OUTLANDS",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "STORMWIND_VALDRAKKEN_PORTAL",
    to = "VALDRAKKEN",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "STORMWIND_EXODAR_PORTAL",
    to = "EXODAR",
    method = "portal",
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "STORMWIND_AZSUNA_PORTAL",
    to = "AZSUNA",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "AZSUNA",
    to = "STORMWIND_PORTAL_ROOM_LOWER",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "STORMWIND_PAWDON_VILLAGE_PORTAL",
    to = "PAWDON_VILLAGE_PORTAL",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "PAWDON_VILLAGE_PORTAL",
    to = "STORMWIND_PORTAL_ROOM_LOWER",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "STORMWIND_CAVERNS_OF_TIME_PORTAL",
    to = "CAVERNS_OF_TIME",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "STORMWIND_DARK_PORTAL_BL_NPC",
    to = "DARK_PORTAL_BL",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "STORMWIND_EXODAR_PORTAL",
    to = "EXODAR",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "EXODAR",
    to = "STORMWIND_PORTAL_ROOM_LOWER",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "STORMWIND_BELAMETH_PORTAL",
    to = "BELAMETH",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "STORMWIND_FOUNDERS_POINT_PORTAL",
    to = "FOUNDERS_POINT",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "FOUNDERS_POINT",
    to = "STORMWIND_PORTAL_ROOM_LOWER",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "STORMWIND_SILVERMOON_PORTAL",
    to = "SILVERMOON_PORTAL_ROOM",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance",
        minLevel = 78
    }
}, {
    from = "SILVERMOON_STORMWIND_PORTAL",
    to = "STORMWIND_PORTAL_ROOM_LOWER",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance",
        minLevel = 78
    }
}, {
    from = "STORMWIND_MAGE_TOWER_ENTRANCE",
    to = "STORMWIND_DARK_PORTAL_BL_NPC",
    method = "walk",
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "STORMWIND_DARK_PORTAL_BL_NPC",
    to = "STORMWIND_PORTAL_ROOM_LOWER",
    method = "walk",
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "STORMWIND_DORNOGAL_PORTAL",
    to = "STORMWIND_PORTAL_ROOM_LOWER",
    method = "walk",
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "STORMWIND_SILVERMOON_PORTAL",
    to = "STORMWIND_PORTAL_ROOM_LOWER",
    method = "walk",
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "STORMWIND_VALDRAKKEN_PORTAL",
    to = "STORMWIND_PORTAL_ROOM_LOWER",
    method = "walk",
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "STORMWIND_ORIBOS_PORTAL",
    to = "STORMWIND_PORTAL_ROOM_LOWER",
    method = "walk",
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "STORMWIND_FOUNDERS_POINT_PORTAL",
    to = "STORMWIND_PORTAL_ROOM_LOWER",
    method = "walk",
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "STORMWIND_PAWDON_VILLAGE_PORTAL",
    to = "STORMWIND_PORTAL_ROOM_LOWER",
    method = "walk",
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "STORMWIND_SHATTRATH_OUTLANDS_PORTAL",
    to = "STORMWIND_PORTAL_ROOM_LOWER",
    method = "walk",
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "STORMWIND_CAVERNS_OF_TIME_PORTAL",
    to = "STORMWIND_PORTAL_ROOM_LOWER",
    method = "walk",
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "STORMWIND_EXODAR_PORTAL",
    to = "STORMWIND_PORTAL_ROOM_LOWER",
    method = "walk",
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "STORMWIND_DALARAN_NORTHREND_PORTAL",
    to = "STORMWIND_PORTAL_ROOM_LOWER",
    method = "walk",
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "STORMWIND_BORALUS_PORTAL",
    to = "STORMWIND_PORTAL_ROOM_UPPER",
    method = "walk",
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "STORMWIND_PORTAL_ROOM_LOWER",
    to = "STORMWIND_PORTAL_ROOM_UPPER",
    method = "walk",
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "STORMWIND_BELAMETH_PORTAL",
    to = "STORMWIND_PORTAL_ROOM_UPPER",
    method = "walk",
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "STORMWIND_AZSUNA_PORTAL",
    to = "STORMWIND_PORTAL_ROOM_UPPER",
    method = "walk",
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "STORMWIND_STORMSHIELD_PORTAL",
    to = "STORMWIND_PORTAL_ROOM_UPPER",
    method = "walk",
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
},
{
    from = "SW_TRAM",
    to = "IF_TRAM",
    method = "tram"
},
 -- Orgrimmar
{
    from = "ORGRIMMAR_GROMGOL_ZEP",
    to = "GROMGOL_ZEPPELIN",
    method = "zeppelin",
    cost = 120
},
{
    from = "ORGRIMMAR_PORTAL_ROOM_ENTRANCE",
    to = "ORGRIMMAR_PORTAL_ROOM_STAIRS",
    method = "walk",
    requirements = {
        faction = "Horde"
    }
}, {
    from = "ORGRIMMAR_PORTAL_ROOM_STAIRS",
    to = "ORGRIMMAR_PORTAL_ROOM_UPPER",
    method = "walk",
    requirements = {
        faction = "Horde"
    }
}, {
    from = "ORGRIMMAR_PORTAL_ROOM_UPPER",
    to = "ORGRIMMAR_VALDRAKKEN_PORTAL",
    method = "walk",
    requirements = {
        faction = "Horde"
    }
}, {
    from = "ORGRIMMAR_PORTAL_ROOM_UPPER",
    to = "ORGRIMMAR_ORIBOS_PORTAL",
    method = "walk",
    requirements = {
        faction = "Horde"
    }
}, {
    from = "ORGRIMMAR_PORTAL_ROOM_UPPER",
    to = "ORGRIMMAR_RAZORWIND_SHORES_PORTAL",
    method = "walk",
    requirements = {
        faction = "Horde"
    }
}, {
    from = "ORGRIMMAR_PORTAL_ROOM_UPPER",
    to = "ORGRIMMAR_DORNOGAL_PORTAL",
    method = "walk",
    requirements = {
        minLevel = 68,
        faction = "Horde"
    }
}, {
    from = "ORGRIMMAR_PORTAL_ROOM_UPPER",
    to = "ORGRIMMAR_HONEYDEW_VILLAGE_PORTAL",
    method = "walk",
    requirements = {
        faction = "Horde"
    }
}, {
    from = "ORGRIMMAR_PORTAL_ROOM_UPPER",
    to = "ORGRIMMAR_DALARAN_NORTHREND_PORTAL",
    method = "walk",
    requirements = {
        faction = "Horde"
    }
}, {
    from = "ORGRIMMAR_PORTAL_ROOM_UPPER",
    to = "ORGRIMMAR_SILVERMOON_PORTAL",
    method = "walk",
    requirements = {
        faction = "Horde"
    }
}, {
    from = "ORGRIMMAR_VALDRAKKEN_PORTAL",
    to = "VALDRAKKEN",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Horde"
    }
}, {
    from = "ORGRIMMAR_ORIBOS_PORTAL",
    to = "ORIBOS",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Horde"
    }
}, {
    from = "ORGRIMMAR_RAZORWIND_SHORES_PORTAL",
    to = "RAZORWIND_SHORES",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Horde"
    }
}, {
    from = "ORGRIMMAR_DORNOGAL_PORTAL",
    to = "DORNOGAL_PORTAL_ROOM",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Horde"
    }
}, {
    from = "ORGRIMMAR_HONEYDEW_VILLAGE_PORTAL",
    to = "HONEYDEW_VILLAGE",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Horde"
    }
}, {
    from = "ORGRIMMAR_DALARAN_NORTHREND_PORTAL",
    to = "DALARAN_NORTHREND",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Horde"
    }
}, {
    from = "DALARAN_NORTHREND_ORGRIMMAR_PORTAL",
    to = "ORGRIMMAR_PORTAL_ROOM_UPPER",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Horde"
    }
}, {
    from = "ORGRIMMAR_SILVERMOON_PORTAL",
    to = "SILVERMOON_PORTAL_ROOM",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Horde",
        minLevel = 78
    }
}, {
    from = "SILVERMOON_ORGRIMMAR_PORTAL",
    to = "ORGRIMMAR_PORTAL_ROOM_UPPER",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Horde",
        minLevel = 78
    }
}, {
    from = "ORGRIMMAR_PORTAL_ROOM_STAIRS",
    to = "ORGRIMMAR_PORTAL_ROOM_LOWER",
    method = "walk",
    requirements = {
        faction = "Horde"
    }
}, {
    from = "ORGRIMMAR_PORTAL_ROOM_LOWER",
    to = "ORGRIMMAR_AZSUNA_PORTAL",
    method = "walk",
    requirements = {
        faction = "Horde"
    }
}, {
    from = "ORGRIMMAR_PORTAL_ROOM_LOWER",
    to = "ORGRIMMAR_DAZARALOR_PORTAL",
    method = "walk",
    requirements = {
        faction = "Horde"
    }
}, {
    from = "ORGRIMMAR_PORTAL_ROOM_LOWER",
    to = "ORGRIMMAR_SHATTRATH_OUTLANDS_PORTAL",
    method = "walk",
    requirements = {
        faction = "Horde"
    }
}, {
    from = "ORGRIMMAR_PORTAL_ROOM_LOWER",
    to = "ORGRIMMAR_CAVERNS_OF_TIME_PORTAL",
    method = "walk",
    requirements = {
        faction = "Horde"
    }
}, {
    from = "ORGRIMMAR_PORTAL_ROOM_LOWER",
    to = "ORGRIMMAR_WARSPEAR_PORTAL",
    method = "walk",
    requirements = {
        faction = "Horde"
    }
}, {
    from = "ORGRIMMAR_PORTAL_ROOM_LOWER",
    to = "ORGRIMMAR_BC_SILVERMOON_PORTAL",
    method = "walk",
    requirements = {
        faction = "Horde"
    }
}, {
    from = "ORGRIMMAR_PORTAL_ROOM_LOWER",
    to = "ORGRIMMAR_DARK_PORTAL_BL_NPC",
    method = "walk",
    requirements = {
        faction = "Horde"
    }
}, {
    from = "ORGRIMMAR_AZSUNA_PORTAL",
    to = "AZSUNA",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Horde"
    }
}, {
    from = "AZSUNA",
    to = "ORGRIMMAR_PORTAL_ROOM_UPPER",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Horde"
    }
}, {
    from = "ORGRIMMAR_DAZARALOR_PORTAL",
    to = "DAZARALOR_DOCK",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Horde"
    }
}, {
    from = "ORGRIMMAR_SHATTRATH_OUTLANDS_PORTAL",
    to = "SHATTRATH_OUTLANDS",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Horde"
    }
}, {
    from = "ORGRIMMAR_CAVERNS_OF_TIME_PORTAL",
    to = "CAVERNS_OF_TIME",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Horde"
    }
}, {
    from = "ORGRIMMAR_WARSPEAR_PORTAL",
    to = "WARSPEAR_ASHRAN",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Horde"
    }
}, {
    from = "WARSPEAR_ASHRAN",
    to = "ORGRIMMAR_PORTAL_ROOM_UPPER",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Horde"
    }
}, {
    from = "ORGRIMMAR_BC_SILVERMOON_PORTAL",
    to = "SILVERMOON",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Horde"
    }
}, {
    from = "SILVERMOON",
    to = "ORGRIMMAR_PORTAL_ROOM_UPPER",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Horde"
    }
}, {
    from = "ORGRIMMAR_DARK_PORTAL_BL_NPC",
    to = "DARK_PORTAL_BL",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Horde"
    }
}, -- Boralus
{
    from = "BORALUS",
    to = "STORMWIND_PORTAL_ROOM_LOWER",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "BORALUS",
    to = "SILITHUS",
    method = "portal",
    requirements = {
        quest = 47189,
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
    to = "STORMWIND_PORTAL_ROOM_LOWER",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "DALARAN_BROKEN_ISLES_PORTAL_HORDE",
    to = "ORGRIMMAR_PORTAL_ROOM_UPPER",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Horde"
    }
}, {
    from = "ACHERUS",
    to = "DALARAN_BROKEN_ISLES",
    method = "portal",
    oneway = true,
    requirements = {
        class = "DEATHKNIGHT"
    }
}, {
    from = "MONK_DALARAN_PORTAL",
    to = "DALARAN_BROKEN_ISLES",
    method = "portal",
    oneway = true,
    requirements = {
        class = "MONK"
    }
}, {
    from = "DALARAN_PALADIN_PORTAL_HORDE",
    to = "SANCTUM_OF_LIGHT",
    method = "portal",
    requirements = {
        class = "PALADIN",
        faction = "Horde"
    }
}, {
    from = "DALARAN_PALADIN_PORTAL_ALLIANCE",
    to = "SANCTUM_OF_LIGHT",
    method = "portal",
    requirements = {
        class = "PALADIN",
        faction = "Alliance"
    }
}, -- Oribos
{
    from = "ORIBOS",
    to = "ORIBOS_FLIGHT",
    method = "walk"
}, {
    from = "ORIBOS",
    to = "STORMWIND_PORTAL_ROOM_LOWER",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "ORIBOS",
    to = "ORGRIMMAR_PORTAL_ROOM_UPPER",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Horde"
    }
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
    from = "STORMSHIELD_ASHRAN",
    to = "STORMWIND_PORTAL_ROOM_LOWER",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "SHATTRATH_OUTLANDS",
    to = "QUELDANAS",
    method = "portal",
    oneway = true
}, {
    from = "SHATTRATH_OUTLANDS",
    to = "STORMWIND_PORTAL_ROOM_LOWER",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "SHATTRATH_OUTLANDS",
    to = "ORGRIMMAR_PORTAL_ROOM_UPPER",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Horde"
    }
}, {
    from = "DARK_PORTAL_BL",
    to = "DARK_PORTAL_OUTLANDS",
    method = "portal"
}, {
    from = "DARK_PORTAL_OUTLANDS",
    to = "STORMWIND_PORTAL_ROOM_LOWER",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "DARNASSUS",
    to = "DARK_PORTAL_OUTLANDS",
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
    from = "VALDRAKKEN",
    to = "STORMWIND_PORTAL_ROOM_LOWER",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "VALDRAKKEN_BADLANDS_PORTAL",
    to = "FUSELIGHT_FLIGHT",
    method = "portal",
    oneway = true
}, -- Night Elf Network
{
    from = "BELAMETH",
    to = "STORMWIND_PORTAL_ROOM_LOWER",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance"
    }
}, {
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
    from = "DORNOGAL_PORTAL_ROOM",
    to = "STORMWIND_PORTAL_ROOM_LOWER",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance",
        minLevel = 68
    }
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
    to = "ORGRIMMAR_THUNDER_BLUFF_ZEP",
    method = "zeppelin",
    cost = 275
}, {
    from = "HONEYDEW_VILLAGE",
    to = "ORGRIMMAR_PORTAL_ROOM_UPPER",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Horde"
    }
}, {
    from = "DORNOGAL_PORTAL_ROOM",
    to = "ORGRIMMAR_PORTAL_ROOM_UPPER",
    method = "portal",
    requirements = {
        faction = "Horde",
        minLevel = 68
    }
}, {
    from = "RAZORWIND_SHORES",
    to = "ORGRIMMAR_PORTAL_ROOM_UPPER",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Horde"
    }
}, -- {
--    from = "RAZORWIND_PORTAL_TO_FORBIDDEN_REACH",
--    to = "FORBIDDEN_REACH",
--    method = "portal",
--    oneway = true,
--    requirements = {
--        endeavor = "Dracthyr",
--        faction = "Horde"
--    }
-- }, {
--    from = "FORBIDDEN_REACH",
--    to = "RAZORWIND_SHORES",
--    method = "portal",
--    requirements = {
--        endeavor = "Dracthyr",
--        faction = "Horde"
--    }
-- }, 
{
    from = "VALDRAKKEN",
    to = "ORGRIMMAR_PORTAL_ROOM_UPPER",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Horde"
    }
}, {
    from = "CAVERNS_OF_TIME_STORMWIND_PORTAL",
    to = "STORMWIND_PORTAL_ROOM_LOWER",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Alliance"
    }
}, {
    from = "CAVERNS_OF_TIME_ORGRIMMAR_PORTAL",
    to = "ORGRIMMAR_PORTAL_ROOM_UPPER",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Horde"
    }
}, {
    from = "ORGRIMMAR_PORTAL_ROOM_UPPER",
    to = "DAZARALOR_DOCK",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Horde"
    }
}, {
    from = "ORGRIMMAR_PORTAL_ROOM_UPPER",
    to = "DARK_PORTAL_BL",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Horde"
    }
}, {
    from = "ORGRIMMAR_THUNDER_TOTEM_PORTAL",
    to = "THUNDER_TOTEM_ORGRIMMAR_PORTAL",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Horde"
    }
}, {
    from = "THUNDER_TOTEM_ORGRIMMAR_PORTAL",
    to = "ORGRIMMAR_EMBASSY",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Horde"
    }
}, {
    from = "ORGRIMMAR_NIGHTHOLD_PORTAL",
    to = "THE_NIGHTHOLD",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Horde"
    }
}, {
    from = "NIGHTHOLD_ORGRIMMAR_PORTAL",
    to = "ORGRIMMAR_EMBASSY",
    method = "portal",
    oneway = true,
    requirements = {
        faction = "Horde"
    }
}, {
    from = "DAZARALOR_PORTAL_ROOM",
    to = "ORGRIMMAR_PORTAL_ROOM_UPPER",
    method = "portal",
    oneway = true,
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
        quest = 55053,
        faction = "Horde"
    }
}, {
    from = "DAZARALOR_PORTAL_ROOM",
    to = "SILITHUS",
    method = "portal",
    requirements = {
        quest = 46931,
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
    from = "BLACKROCK_QUARRY_EXTERIOR",
    to = "BLACKROCK_DEPTHS_DUNGEON",
    method = "walk"
}, {
    from = "BLACKROCK_MOUNTAIN_MOLE",
    to = "BLACKROCK_DEPTHS_DUNGEON",
    method = "walk"
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
    from = "ORGRIMMAR_WARSONG_ZEP",
    to = "WARSONG_HOLD_ZEPPELIN",
    method = "zeppelin"
}, {
    from = "ORGRIMMAR_WAKING_SHORES_ZEP",
    to = "WAKING_SHORES_ORGRIMMAR_ZEP",
    method = "zeppelin",
    cost = 350
}, {
    from = "ORGRIMMAR_UNDERCITY_PORTAL",
    to = "UNDERCITY",
    method = "portal",
    requirements = {
        faction = "Horde"
    }
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
}, {
    from = "ARCANTINA_EXIT",
    to = "SILVERMOON_PORTAL_ROOM",
    method = "portal"
}, {
    from = "HARANDAR_EVERSONG_PORTAL",
    to = "EVERSONG_HARANDAR_PORTAL",
    method = "portal",
    requirements = {
        quest = 89402,
        questNotCompleted = 86898
    }
}, {
    from = "HARANDAR_SILVERMOON_PORTAL",
    to = "SILVERMOON_HARANDAR_PORTAL",
    method = "portal",
    requirements = {
        quest = 86898
    }
}, {
    from = "SILVERMOON_VOIDSTORM_PORTAL",
    to = "VOIDSTORM_INGRESS_PORTAL",
    method = "portal",
    requirements = {
        quest = 86549,
        questNotCompleted = 86510
    }
}, {
    from = "SILVERMOON_VOIDSTORM_PORTAL",
    to = "VOIDSTORM_SILVERMOON_PORTAL",
    method = "portal",
    requirements = {
        quest = 86510
    }
}, { -- DRUID EMERALD DREAMWAY
    from = "EMERALD_DREAMWAY",
    to = "EMERALD_DREAMWAY_MOONGLADE_PORTAL",
    method = "walk"
}, {
    from = "EMERALD_DREAMWAY",
    to = "EMERALD_DREAMWAY_AMIRDRASSIL_PORTAL",
    method = "walk"
}, {
    from = "EMERALD_DREAMWAY",
    to = "EMERALD_DREAMWAY_FERALAS_PORTAL",
    method = "walk"
}, {
    from = "EMERALD_DREAMWAY",
    to = "EMERALD_DREAMWAY_GRIZZLY_HILLS_PORTAL",
    method = "walk"
}, {
    from = "EMERALD_DREAMWAY",
    to = "EMERALD_DREAMWAY_DREAMGROVE_PORTAL",
    method = "walk"
}, {
    from = "EMERALD_DREAMWAY",
    to = "EMERALD_DREAMWAY_HYJAL_PORTAL",
    method = "walk"
}, {
    from = "EMERALD_DREAMWAY",
    to = "EMERALD_DREAMWAY_HINTERLANDS_PORTAL",
    method = "walk"
}, {
    from = "EMERALD_DREAMWAY",
    to = "EMERALD_DREAMWAY_DUSKWOOD_PORTAL",
    method = "walk"
}, {
    from = "EMERALD_DREAMWAY_MOONGLADE_PORTAL",
    to = "MOONGLADE_DRUID",
    method = "portal",
    requirements = {
        class = "DRUID"
    }
}, {
    from = "EMERALD_DREAMWAY_AMIRDRASSIL_PORTAL",
    to = "AMIRDRASSIL_DRUID",
    method = "portal",
    requirements = {
        class = "DRUID"
    }
}, {
    from = "EMERALD_DREAMWAY_FERALAS_PORTAL",
    to = "FERALAS_DRUID",
    method = "portal",
    requirements = {
        class = "DRUID"
    }
}, {
    from = "EMERALD_DREAMWAY_GRIZZLY_HILLS_PORTAL",
    to = "GRIZZLY_HILLS_DRUID",
    method = "portal",
    requirements = {
        class = "DRUID"
    }
}, {
    from = "EMERALD_DREAMWAY_DREAMGROVE_PORTAL",
    to = "VALSHARAH_DRUID",
    method = "portal",
    requirements = {
        class = "DRUID"
    }
}, {
    from = "EMERALD_DREAMWAY_HYJAL_PORTAL",
    to = "MOUNT_HYJAL_DRUID",
    method = "portal",
    requirements = {
        class = "DRUID"
    }
}, {
    from = "EMERALD_DREAMWAY_HINTERLANDS_PORTAL",
    to = "HINTERLANDS_DRUID",
    method = "portal",
    requirements = {
        class = "DRUID"
    }
}, {
    from = "EMERALD_DREAMWAY_DUSKWOOD_PORTAL",
    to = "DUSKWOOD_DRUID",
    method = "portal",
    requirements = {
        class = "DRUID"
    }
}}

-----------------------------------------------------------
-- TRAVERSAL GROUPS
-----------------------------------------------------------

ns.MapToTraversal = {
    -- Continent-level definitions
    [13] = "EK_OVERWORLD",
    [12] = "KALIMDOR_OVERWORLD",
    [101] = "OUTLANDS",
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
    [2413] = "HARANDAR",
    [2405] = "VOIDSTORM",

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
