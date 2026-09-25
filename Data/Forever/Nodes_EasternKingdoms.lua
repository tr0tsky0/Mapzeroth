-- Nodes_EasternKingdoms.lua (Forever)
--
-- Flight master candidates collected via MapzerothDataTools (/mzdump nodes
-- 1415), resolved to each node's own zone mapID. `container` is a
-- first-pass guess from the zone name in the original dump; double-check
-- against the real container tree once World.lua exists.
--
-- Dropped from the raw dump: "zzOLDBolder'ok, Riverglades" and
-- "zzOLDRiverglades, Farholde Keep" (Blizzard's own naming convention for
-- cut content — shared exact coordinates with Thorium Point and Southshore
-- respectively).
--
-- "Rog'mar" / "Farholde Keep" (Riverglades, mapID 2548) are real, active
-- content, distinct from the zzOLD-prefixed cut version above. Treated as
-- a regular Eastern Kingdoms zone (the placeholder edge dump's link to
-- Kalimdor nodes was most likely an artifact of the dump, not real). Can't
-- be verified in-game until the beta level cap rises (zone is ~level 35-45,
-- cap is currently 20).

local addonName, addon = ...
if addon.RULESET ~= "forever" then return end   -- one addon for both games: this data is Forever's (Constants.lua)

addon.Nodes = addon.Nodes or {}

addon.Nodes.EasternKingdoms = {
    { id = "TAXI_2",  container = "easternkingdoms.elwynn_forest",       mapID = 1453, x = 0.7098, y = 0.7293 }, -- Stormwind
    { id = "TAXI_4",  container = "easternkingdoms.westfall",            mapID = 1436, x = 0.5657, y = 0.5267 }, -- Sentinel Hill
    { id = "TAXI_5",  container = "easternkingdoms.redridge_mountains",  mapID = 1433, x = 0.2534, y = 0.5899 }, -- Lakeshire
    { id = "TAXI_6",  container = "easternkingdoms.dun_morogh",          mapID = 1455, x = 0.5589, y = 0.4787 }, -- Ironforge
    { id = "TAXI_7",  container = "easternkingdoms.wetlands",            mapID = 1437, x = 0.0952, y = 0.5966 }, -- Menethil Harbor
    { id = "TAXI_8",  container = "easternkingdoms.loch_modan",          mapID = 1432, x = 0.3394, y = 0.5079 }, -- Thelsamar
    { id = "TAXI_10", container = "easternkingdoms.silverpine_forest",   mapID = 1421, x = 0.4556, y = 0.4242 }, -- The Sepulcher
    { id = "TAXI_11", container = "easternkingdoms.tirisfal_glades",     mapID = 1458, x = 0.6308, y = 0.4832 }, -- Undercity
    { id = "TAXI_12", container = "easternkingdoms.duskwood",            mapID = 1431, x = 0.7759, y = 0.4438 }, -- Darkshire
    { id = "TAXI_13", container = "easternkingdoms.hillsbrad_foothills", mapID = 1424, x = 0.6021, y = 0.1875 }, -- Tarren Mill
    { id = "TAXI_14", container = "easternkingdoms.hillsbrad_foothills", mapID = 1424, x = 0.4944, y = 0.5210 }, -- Southshore
    { id = "TAXI_16", container = "easternkingdoms.arathi_highlands",    mapID = 1417, x = 0.4579, y = 0.4613 }, -- Refuge Pointe
    { id = "TAXI_17", container = "easternkingdoms.arathi_highlands",    mapID = 1417, x = 0.7306, y = 0.3262 }, -- Hammerfall
    { id = "TAXI_18", container = "easternkingdoms.stranglethorn_vale",  mapID = 1434, x = 0.2682, y = 0.7700 }, -- Booty Bay
    { id = "TAXI_19", container = "easternkingdoms.stranglethorn_vale",  mapID = 1434, x = 0.2753, y = 0.7767 }, -- Booty Bay
    { id = "TAXI_20", container = "easternkingdoms.stranglethorn_vale",  mapID = 1434, x = 0.3251, y = 0.2928 }, -- Grom'gol
    { id = "TAXI_21", container = "easternkingdoms.badlands",            mapID = 1418, x = 0.0406, y = 0.4489 }, -- Kargath
    { id = "TAXI_43", container = "easternkingdoms.hinterlands",         mapID = 1425, x = 0.1111, y = 0.4609 }, -- Aerie Peak
    { id = "TAXI_45", container = "easternkingdoms.blasted_lands",       mapID = 1419, x = 0.6549, y = 0.2443 }, -- Nethergarde Keep
    { id = "TAXI_56", container = "easternkingdoms.swamp_of_sorrows",    mapID = 1435, x = 0.4605, y = 0.5468 }, -- Stonard
    { id = "TAXI_66", container = "easternkingdoms.western_plaguelands", mapID = 1422, x = 0.4295, y = 0.8495 }, -- Chillwind Camp
    { id = "TAXI_67", container = "easternkingdoms.eastern_plaguelands", mapID = 1423, x = 0.7170, y = 0.4956 }, -- Light's Hope Chapel
    { id = "TAXI_68", container = "easternkingdoms.eastern_plaguelands", mapID = 1423, x = 0.7045, y = 0.4759 }, -- Light's Hope Chapel
    { id = "TAXI_70", container = "easternkingdoms.burning_steppes",     mapID = 1428, x = 0.6558, y = 0.2422 }, -- Flame Crest
    { id = "TAXI_71", container = "easternkingdoms.burning_steppes",     mapID = 1428, x = 0.8438, y = 0.6830 }, -- Morgan's Vigil
    { id = "TAXI_74", container = "easternkingdoms.searing_gorge",       mapID = 1427, x = 0.3789, y = 0.3043 }, -- Thorium Point
    { id = "TAXI_75", container = "easternkingdoms.searing_gorge",       mapID = 1427, x = 0.3483, y = 0.3058 }, -- Thorium Point
    { id = "TAXI_76", container = "easternkingdoms.hinterlands",         mapID = 1425, x = 0.8170, y = 0.8189 }, -- Revantusk Village
    { id = "TAXI_84", container = "easternkingdoms.eastern_plaguelands", mapID = 1423, x = 0.1845, y = 0.2417 }, -- Plaguewood Tower
    { id = "TAXI_85", container = "easternkingdoms.eastern_plaguelands", mapID = 1423, x = 0.4716, y = 0.2031 }, -- Northpass Tower
    { id = "TAXI_86", container = "easternkingdoms.eastern_plaguelands", mapID = 1423, x = 0.5780, y = 0.4160 }, -- Eastwall Tower
    { id = "TAXI_87", container = "easternkingdoms.eastern_plaguelands", mapID = 1423, x = 0.3259, y = 0.6398 }, -- Crown Guard Tower
    { id = "TAXI_3203", container = "easternkingdoms.riverglades",      mapID = 2548, x = 0.5961, y = 0.4506 }, -- Rog'mar (VERIFY in-game once level cap allows)
    { id = "TAXI_3276", container = "easternkingdoms.riverglades",      mapID = 2548, x = 0.6059, y = 0.8157 }, -- Farholde Keep (VERIFY in-game once level cap allows)
    -- Powderfuse Port flight master: appears in the Alliance flight-map slots but is absent from the C_TaxiMap dump, so there's no real taxi node ID (id is a placeholder). Position derived from the slot's map position + /mzdump resolve, not walked to.
    { id = "TAXI_POWDERFUSE", container = "easternkingdoms.riverglades", mapID = 2548, x = 0.7680, y = 0.5302 }, -- Powderfuse Port (no flight edges yet; connections unknown)

    -- Docks / zeppelin towers — estimated the same way as Nodes_Kalimdor.lua's
    -- (Atlas map calibration + /mzdump resolve). VERIFY IN-GAME.
    -- Powderfuse Port resolving to mapID 2548 (Riverglades) independently
    -- confirms that container assignment from the taxi-node dump.
    { id = "ZEPPELIN_TIRISFAL", container = "easternkingdoms.tirisfal_glades",     mapID = 1420, x = 0.8018, y = 0.4475 }, -- Tirisfal Zeppelin Towers (ESTIMATED)
    { id = "ZEPPELIN_GROMGOL",  container = "easternkingdoms.stranglethorn_vale",  mapID = 1434, x = 0.3450, y = 0.2647 }, -- Grom'gol Zeppelin Tower (ESTIMATED)
    { id = "DOCK_MENETHIL",     container = "easternkingdoms.wetlands",            mapID = 1437, x = 0.0464, y = 0.5716 }, -- Menethil pier for the Auberdine/Southshore loop (captured live; the earlier estimate was ~7% off in y)
    { id = "DOCK_MENETHIL_THERAMORE", container = "easternkingdoms.wetlands",    mapID = 1437, x = 0.0509, y = 0.6351 }, -- Menethil pier for the Theramore ship (captured live)
    { id = "DOCK_SOUTHSHORE",   container = "easternkingdoms.hillsbrad_foothills", mapID = 1424, x = 0.5053, y = 0.6975 }, -- Southshore Harbor (captured live; the earlier estimate was ~19% off in y)
    { id = "DOCK_STORMWIND",    container = "easternkingdoms.elwynn_forest",       mapID = 1453, x = 0.2255, y = 0.5613 }, -- Stormwind Harbor (captured live; the earlier Atlas-calibrated estimate, 0.3910/0.5082, was well off)
    { id = "DOCK_BOOTYBAY",     container = "easternkingdoms.stranglethorn_vale",  mapID = 1434, x = 0.3908, y = 0.6673 }, -- Booty Bay Harbor (ESTIMATED)
    -- Captured live with `/mzdump here` (exact, not estimated).
    { id = "DOCK_DALARAN",      container = "easternkingdoms.alterac_mountains",  mapID = 1416, x = 0.1262, y = 0.5203 }, -- Dalaran (ship to/from Zephras Isle). Forever's alternate-timeline Dalaran city, on the Alterac Mountains map -- not the Northrend one, no separate city mapID seen
    { id = "PORTAL_DALARAN_STORMWIND", container = "easternkingdoms.alterac_mountains", mapID = 1416, x = 0.1205, y = 0.5636 }, -- Dalaran: "Skyborne Portal to Stormwind" (Skyborne-only? UNTESTED; exit location unknown; no edge yet)
    -- Stormwind: the Dalaran portal exits inside the Wizard's Sanctum (captured live), so it's walled off from
    -- the rest of the city like a walled city's own gate, just within one map: the entrance pair below sits in
    -- its own nested container, joined to the main Stormwind container only by the zero-cost gate edge in
    -- Edges.lua, so a route out of the Sanctum reads "walk to the entrance" rather than a straight line through
    -- its walls.
    { id = "PORTAL_STORMWIND_DALARAN", container = "easternkingdoms.elwynn_forest.stormwind_wizards_sanctum", mapID = 1453, x = 0.4987, y = 0.8667 }, -- Stormwind: return portal to Dalaran, inside the Wizard's Sanctum (same faction/timing questions as the Dalaran-side portal)
    { id = "ENTRANCE_SW_WIZARDS_SANCTUM_OUTER", container = "easternkingdoms.elwynn_forest", mapID = 1453, x = 0.4944, y = 0.8677, kind = "entrance" }, -- Stormwind: Wizard's Sanctum entrance, outside (captured live)
    { id = "ENTRANCE_SW_WIZARDS_SANCTUM_INNER", container = "easternkingdoms.elwynn_forest.stormwind_wizards_sanctum", mapID = 1453, x = 0.4936, y = 0.8693, kind = "entrance" }, -- Stormwind: Wizard's Sanctum entrance, inside (captured live)
    { id = "TRAM_STORMWIND",    container = "easternkingdoms.elwynn_forest",      mapID = 1453, x = 0.6903, y = 0.3110 }, -- Deeprun Tram exterior entrance, Stormwind (captured live)
    { id = "TRAM_IRONFORGE",    container = "easternkingdoms.dun_morogh",         mapID = 1455, x = 0.7641, y = 0.5123 }, -- Deeprun Tram exterior entrance, Ironforge (captured live)
    { id = "DOCK_POWDERFUSE",   container = "easternkingdoms.riverglades",        mapID = 2548, x = 0.7222, y = 0.7603 }, -- Powderfuse Port (ESTIMATED)
}
