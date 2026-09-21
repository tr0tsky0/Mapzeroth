-- Nodes_Kalimdor.lua (Forever)
--
-- Flight master candidates collected via MapzerothDataTools (/mzdump nodes
-- 1414), resolved to each node's own zone mapID. Forever has no Cataclysm
-- content — no phasing, no Darkshore/Teldrassil split needed here, unlike
-- Modern's dataset. `container` is a first-pass guess from the zone name
-- in the original dump; double-check against the real container tree once
-- World.lua exists.
--
-- Dropped from the raw dump: "zzOLDPowderfuse Port, Riverglades" (Blizzard's
-- own naming convention for cut content — shared Ratchet's exact coords).
--
-- "Summit of Eternity" / "Tainted Foothills" (Mount Hyjal) don't match
-- vanilla-era Kalimdor geography from memory — Mount Hyjal wasn't a normal
-- open zone pre-Cataclysm. Possibly Forever-specific new content. Verify.
--
-- "Rog'mar" / "Farholde Keep" (Riverglades, mapID 2548) live in
-- Nodes_EasternKingdoms.lua instead — Riverglades is an Eastern Kingdoms
-- zone; the dump's link to Kalimdor was most likely an artifact.

local addonName, addon = ...

addon.Nodes = addon.Nodes or {}

addon.Nodes.Kalimdor = {
    { id = "TAXI_22", container = "kalimdor.mulgore",             mapID = 1456, x = 0.4665, y = 0.4990 }, -- Thunder Bluff
    { id = "TAXI_23", container = "kalimdor.durotar",              mapID = 1454, x = 0.4528, y = 0.6375 }, -- Orgrimmar
    { id = "TAXI_25", container = "kalimdor.the_barrens",          mapID = 1413, x = 0.5150, y = 0.3041 }, -- Crossroads
    { id = "TAXI_26", container = "kalimdor.darkshore",            mapID = 1439, x = 0.3640, y = 0.4562 }, -- Auberdine
    { id = "TAXI_27", container = "kalimdor.teldrassil.ruttheran",           mapID = 1438, x = 0.5840, y = 0.9393 }, -- Rut'theran Village
    { id = "TAXI_28", container = "kalimdor.ashenvale",            mapID = 1440, x = 0.3450, y = 0.4801 }, -- Astranaar
    { id = "TAXI_29", container = "kalimdor.stonetalon_mountains", mapID = 1442, x = 0.4516, y = 0.5989 }, -- Sun Rock Retreat
    { id = "TAXI_30", container = "kalimdor.thousand_needles",     mapID = 1441, x = 0.4502, y = 0.4913 }, -- Freewind Post
    { id = "TAXI_31", container = "kalimdor.feralas",              mapID = 1444, x = 0.8946, y = 0.4587 }, -- Thalanaar
    { id = "TAXI_32", container = "kalimdor.dustwallow_marsh",     mapID = 1445, x = 0.6746, y = 0.5120 }, -- Theramore
    { id = "TAXI_33", container = "kalimdor.stonetalon_mountains", mapID = 1442, x = 0.3654, y = 0.0723 }, -- Stonetalon Peak
    { id = "TAXI_37", container = "kalimdor.desolace",             mapID = 1443, x = 0.6467, y = 0.1044 }, -- Nijel's Point
    { id = "TAXI_38", container = "kalimdor.desolace",             mapID = 1443, x = 0.2156, y = 0.7404 }, -- Shadowprey Village
    { id = "TAXI_39", container = "kalimdor.tanaris",              mapID = 1446, x = 0.5095, y = 0.2933 }, -- Gadgetzan
    { id = "TAXI_40", container = "kalimdor.tanaris",              mapID = 1446, x = 0.5162, y = 0.2552 }, -- Gadgetzan
    { id = "TAXI_41", container = "kalimdor.feralas",              mapID = 1444, x = 0.3026, y = 0.4332 }, -- Feathermoon
    { id = "TAXI_42", container = "kalimdor.feralas",              mapID = 1444, x = 0.7543, y = 0.4431 }, -- Camp Mojache
    { id = "TAXI_44", container = "kalimdor.azshara",               mapID = 1447, x = 0.2195, y = 0.4969 }, -- Valormok
    { id = "TAXI_48", container = "kalimdor.felwood",               mapID = 1448, x = 0.3442, y = 0.5387 }, -- Bloodvenom Post
    { id = "TAXI_49", container = "kalimdor.moonglade",             mapID = 1450, x = 0.4791, y = 0.6711 }, -- Moonglade, Alliance flight master (confirmed: live capture 0.4807/0.6720)
    { id = "TAXI_52", container = "kalimdor.winterspring",          mapID = 1452, x = 0.6233, y = 0.3664 }, -- Everlook
    { id = "TAXI_53", container = "kalimdor.winterspring",          mapID = 1452, x = 0.6049, y = 0.3634 }, -- Everlook
    { id = "TAXI_55", container = "kalimdor.dustwallow_marsh",      mapID = 1445, x = 0.3557, y = 0.3183 }, -- Brackenwall Village
    { id = "TAXI_58", container = "kalimdor.ashenvale",             mapID = 1440, x = 0.1219, y = 0.3377 }, -- Zoram'gar Outpost
    { id = "TAXI_61", container = "kalimdor.ashenvale",             mapID = 1440, x = 0.7326, y = 0.6167 }, -- Splintertree Post
    { id = "TAXI_62", container = "kalimdor.moonglade",             mapID = 1450, x = 0.4428, y = 0.4534 }, -- Nighthaven "Darnassus Flightmaster" (druid-only; matches live capture 0.4424/0.4524; dialog flight to Rut'theran, confirmed 154s, not a taxi-map node)
    { id = "TAXI_63", container = "kalimdor.moonglade",             mapID = 1450, x = 0.4431, y = 0.4572 }, -- Nighthaven "Thunder Bluff Flightmaster" (druid-only; matches live capture 0.4434/0.4581; destination unconfirmed)
    { id = "TAXI_64", container = "kalimdor.azshara",               mapID = 1440, x = 0.9677, y = 0.5076 }, -- Talrendis Point (VERIFY mapID: raw dump gave 1440, same as Ashenvale, while Valormok/Azshara resolved to 1447 — likely a border quirk, re-check in-game)
    { id = "TAXI_65", container = "kalimdor.felwood",               mapID = 1448, x = 0.6246, y = 0.2419 }, -- Talonbranch Glade
    { id = "TAXI_69", container = "kalimdor.moonglade",             mapID = 1450, x = 0.3215, y = 0.6633 }, -- Moonglade, Horde flight master (assumed correct by analogy with the confirmed Alliance one; not visited)
    { id = "TAXI_72", container = "kalimdor.silithus",              mapID = 1451, x = 0.4883, y = 0.3672 }, -- Cenarion Hold
    { id = "TAXI_73", container = "kalimdor.silithus",              mapID = 1451, x = 0.5068, y = 0.3459 }, -- Cenarion Hold
    { id = "TAXI_77", container = "kalimdor.the_barrens",           mapID = 1413, x = 0.4446, y = 0.5910 }, -- Camp Taurajo
    { id = "TAXI_79", container = "kalimdor.ungoro_crater",         mapID = 1449, x = 0.4530, y = 0.0597 }, -- Marshal's Refuge
    { id = "TAXI_80", container = "kalimdor.the_barrens",           mapID = 1413, x = 0.6312, y = 0.3711 }, -- Ratchet
    { id = "TAXI_559", container = "kalimdor.mount_hyjal",          mapID = 2482, x = 0.6864, y = 0.4411 }, -- Summit of Eternity (VERIFY: new content?)
    { id = "TAXI_3242", container = "kalimdor.mount_hyjal",         mapID = 2482, x = 0.5510, y = 0.8255 }, -- Tainted Foothills (VERIFY: new content?)

    -- Docks / zeppelin towers — no API coverage exists for these (see
    -- Edges.lua header for why), so positions are ESTIMATED: calibrated by
    -- affine-fitting the Atlas Forever map's SVG coordinates against our
    -- own known flight-master positions, then resolved to zone-frame via
    -- the same client APIs (/mzdump resolve). Mean fit error was ~1.8% of
    -- normalized zone scale — good enough to place a node, not exact.
    -- VERIFY IN-GAME before trusting these coordinates precisely.
    { id = "DOCK_RUTTHERAN",     container = "kalimdor.teldrassil.ruttheran",           mapID = 1438, x = 0.5488, y = 0.9671 }, -- Rut'theran Village Harbor (captured live; the earlier estimate, 0.6757/0.7151, was far off)
    -- Auberdine has a separate pier per route (~2-3% of the map apart), all captured live:
    { id = "DOCK_AUBERDINE_STORMWIND", container = "kalimdor.darkshore",    mapID = 1439, x = 0.3077, y = 0.4101 }, -- Auberdine pier for the Stormwind ship
    { id = "DOCK_AUBERDINE_RUTTHERAN",  container = "kalimdor.darkshore",    mapID = 1439, x = 0.3318, y = 0.4013 }, -- Auberdine pier for the Rut'theran ferry
    { id = "DOCK_AUBERDINE_MENETHIL", container = "kalimdor.darkshore",     mapID = 1439, x = 0.3237, y = 0.4381 }, -- Auberdine pier for the Menethil/Southshore ship
    { id = "DOCK_RATCHET",      container = "kalimdor.the_barrens",          mapID = 1413, x = 0.6446, y = 0.5083 }, -- Ratchet Harbor (ESTIMATED)
    { id = "DOCK_THERAMORE",    container = "kalimdor.dustwallow_marsh",     mapID = 1445, x = 0.7150, y = 0.5635 }, -- Theramore Isle Harbor (captured live; the earlier estimate was ~16% off in y)
    { id = "DOCK_STEAMWHEEDLE", container = "kalimdor.tanaris",              mapID = 1446, x = 0.6538, y = 0.2245 }, -- Steamwheedle Port (ESTIMATED, new Forever route)
    { id = "DOCK_FEATHERMOON",  container = "kalimdor.feralas",              mapID = 1444, x = 0.2780, y = 0.3171 }, -- Feathermoon Stronghold Harbor (ESTIMATED)
    { id = "DOCK_FORGOTTENCOAST", container = "kalimdor.feralas",           mapID = 1444, x = 0.3542, y = 0.5040 }, -- Forgotten Coast Harbor (ESTIMATED)
    { id = "ZEPPELIN_ORGRIMMAR", container = "kalimdor.durotar",            mapID = 1411, x = 0.4768, y = 0.3067 }, -- Orgrimmar Zeppelin Towers (ESTIMATED)

    -- Captured live with `/mzdump here` (exact, not estimated).
    { id = "PORTAL_RUTTHERAN_DARNASSUS", container = "kalimdor.teldrassil.ruttheran",   mapID = 1438, x = 0.5592, y = 0.8969 }, -- Rut'theran Village portal to Darnassus
    { id = "PORTAL_DARNASSUS_RUTTHERAN", container = "kalimdor.teldrassil",   mapID = 1457, x = 0.3032, y = 0.4136 }, -- Darnassus portal to Rut'theran Village (city has no flight master of its own; mapID is Darnassus's own map, container is Teldrassil)
    { id = "TELEPORT_MOONGLADE", container = "kalimdor.moonglade",          mapID = 1450, x = 0.5627, y = 0.3241 }, -- Druid Teleport: Moonglade landing spot (captured live). Ability data (spell ID, cast time, cooldown) still to come
    { id = "DOCK_SKYWATCHER",   container = "kalimdor.mulgore",              mapID = 1412, x = 0.3430, y = 0.2576 }, -- Skywatcher Plateau (ship to/from Zephras Isle)
}
