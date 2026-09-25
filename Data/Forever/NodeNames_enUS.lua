-- NodeNames_enUS.lua (Forever)
--
-- English names for the nodes WE created, which the client has no name for
-- (docks, zeppelin towers, tram entrances, portals, teleport landings).
-- Keyed "NODE_<nodeID>" so a translator can override any of them in their
-- own locale's table. Flight masters and border crossings aren't listed:
-- the client names the first and zone names build the second.
--
-- Where a town has several piers, the route is in parentheses to tell them
-- apart. Names in-game we haven't seen yet are tentative.

local addonName, addon = ...
if addon.RULESET ~= "forever" then return end   -- one addon for both games: this data is Forever's (Constants.lua)

addon:RegisterLocale("enUS", {
    -- Kalimdor
    NODE_DOCK_AUBERDINE_MENETHIL   = "Auberdine Harbor (Menethil ship)",
    NODE_DOCK_AUBERDINE_RUTTHERAN  = "Auberdine Harbor (Rut'theran ferry)",
    NODE_DOCK_AUBERDINE_STORMWIND  = "Auberdine Harbor (Stormwind ship)",
    NODE_DOCK_FEATHERMOON          = "Feathermoon Stronghold Harbor",
    NODE_DOCK_FORGOTTENCOAST       = "Forgotten Coast Harbor",
    NODE_DOCK_RATCHET              = "Ratchet Harbor",
    NODE_DOCK_RUTTHERAN            = "Rut'theran Village Harbor",
    NODE_DOCK_SKYWATCHER           = "Skywatcher Plateau Airship Dock",
    NODE_DOCK_STEAMWHEEDLE         = "Steamwheedle Port",
    NODE_DOCK_THERAMORE            = "Theramore Isle Harbor",
    NODE_PORTAL_DARNASSUS_RUTTHERAN = "Gate to Rut'theran Village",
    NODE_PORTAL_RUTTHERAN_DARNASSUS = "Gate to Darnassus",
    NODE_TELEPORT_MOONGLADE        = "Moonglade Teleport Landing",
    NODE_ZEPPELIN_ORGRIMMAR        = "Orgrimmar Zeppelin Tower",

    -- Eastern Kingdoms
    NODE_DOCK_BOOTYBAY             = "Booty Bay Harbor",
    NODE_DOCK_DALARAN              = "Dalaran Airship Dock",
    NODE_DOCK_MENETHIL             = "Menethil Harbor (Southshore ship)",
    NODE_DOCK_MENETHIL_THERAMORE   = "Menethil Harbor (Theramore ship)",
    NODE_DOCK_POWDERFUSE           = "Powderfuse Port",
    NODE_DOCK_SOUTHSHORE           = "Southshore Harbor",
    NODE_DOCK_STORMWIND            = "Stormwind Harbor",
    NODE_ENTRANCE_SW_WIZARDS_SANCTUM_OUTER = "Wizard's Sanctum Entrance",
    NODE_ENTRANCE_SW_WIZARDS_SANCTUM_INNER = "Wizard's Sanctum",
    NODE_PORTAL_DALARAN_STORMWIND  = "Skyborne Portal to Stormwind",
    NODE_PORTAL_STORMWIND_DALARAN  = "Skyborne Portal to Dalaran",
    NODE_TAXI_POWDERFUSE           = "Powderfuse Port, Riverglades",
    NODE_TRAM_IRONFORGE            = "Deeprun Tram Entrance (Ironforge)",
    NODE_TRAM_STORMWIND            = "Deeprun Tram Entrance (Stormwind)",
    NODE_ZEPPELIN_GROMGOL          = "Grom'gol Zeppelin Tower",
    NODE_ZEPPELIN_TIRISFAL         = "Tirisfal Zeppelin Tower",

    -- Zephras Isle
    NODE_DOCK_ZEPHRAS_ALLIANCE     = "Zephras Isle Airship Dock (Dalaran)",
})
