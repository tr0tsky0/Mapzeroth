"""Hand additions to the Modern data that the old addon's data doesn't have, read by
tools/gen_modern_nodes.py and tools/gen_modern_edges.py so a regeneration keeps them
(Data/Modern/*.lua is generated: hand edits there are lost on the next run).

NODES    places the old data lacks, usually captured in game with /mzdump here. Each is
         { "id", "out" (which Nodes_*.lua it goes in), "container", "mapID", "x", "y",
         optional "area" (the client's area id: gives the node a localized name), optional "faction" (a place only
         one faction can use: a one-faction flight master), "note" }.
INDOOR   containers the old data didn't flag `interior` but are: no flying to or from them.
EDGES    connections the old data lacks: { "from", "to", "method", optional "cost", optional "oneway",
         optional "loadingScreens", optional "inPhase" = (group, side): only on that side of a phase group }.
         Leave `cost` out for a walk and the engine works it out from distance and the default path
         factor, like any other walk.
EQUIP_COOLDOWNS  { itemID: seconds }: how long an equippable teleport item is on cooldown after it is put on, which
         is what its "Equip" step is priced at (the route then "Uses" it). An item not listed gets
         addon.DEFAULT_EQUIP_SECONDS (Constants.lua, 0). Only items that have to be worn matter; the game says which.
NODE_CONTAINERS  { nodeID: container path }: put an old-data node in another container (usually an interior the old
         data didn't know about, alongside INDOOR).
DROP_NODES  old-data nodes to leave out, by id (usually because a NODES entry of the same id replaces them, in
         the right place).
DROP_EDGES  old-data edges to leave out (usually because a hand-added route replaces them):
         { "from", "to", "method" }.
INSTANCE_JOURNALS  { source node id: journalInstanceID, or (journalInstanceID, "Alliance"/"Horde") }: the dungeon
         and raid entrances tools/match_modern_instance_nodes.py can't match, or matches wrongly; the faction for an
         entrance only one faction has. Two entrances to one instance become one destination.
AREA_OVERRIDES  { source node id: areaID }: the area that names a node, where tools/match_modern_area_nodes.py found
         none or the wrong one (area_node_matches.tsv). Capture one in game with /mzdump at the spot.
NODE_KINDS  { source node id: kind }: a place of a kind Forever's POIs have ("inn", "bank", ...), for the few Modern
         nodes that are one. Named by the kind's pattern unless the node has an area (NodeNames.lua).
SECOND_COPY_IDS  { old id: id of its second copy }: the old data authored some ids twice for two real places (the
         Burning Crusade and the Midnight Silvermoon flight masters); the second copy in file order gets this id.
NODE_PLACES  { source id: { "container", "mapID", "x", "y" } }: where a node really is, when the old data had it wrong
         (captured in game).
CONFIRMED_TAXI_IDS  { source id: "taxiNodeID" or None }: a flight master's id settled by hand from a capture the
         matcher can't read (continent-relative coordinates); None keeps it unmatched until someone captures it.
CITIES   the cities, in the same shape as Forever's (addon.Cities, Data/Forever/Pois.lua): key -> { "maps" (the
         uiMapIDs the city is, the first its own), "expansion" (major version), "faction", optional "hub" (also on
         the picker's main page whatever its expansion), optional "nodes" (the node ids its centre is the average of,
         when the default -- every outdoor node on its first map -- would be wrong: a city that is part of a zone's
         map), optional "taxi" (its flight master, which names it when its map's name isn't its own) }.
         gen_modern_nodes.py writes them to Data/Modern/Settlements.lua with a CITY_<KEY> centre node each.
"""

NODES = [
    {"id": "PORTAL_SHATTRATH_QUELDANAS", "out": "Nodes_Outlands.lua", "container": "outlands.map111", "mapID": 111,
     "x": 0.4876, "y": 0.4210, "note": "Shattrath: the portal to the Isle of Quel'Danas (captured in game 2026-09-24)"},
    # Midnight's Silvermoon has two flight masters; the old data had only the Sanctum of Light one. The Royal Exchange
    # one is Horde only (captured in game 2026-09-24).
    {"id": "TAXI_3132", "out": "Nodes_EK.lua", "container": "ek_overworld.map2393", "mapID": 2393,
     "x": 0.6944, "y": 0.6341, "faction": "Horde", "note": "Silvermoon City: the Royal Exchange flight master (Horde)"},
    # The Burning Crusade Quel'Thalas, entered by portal (captured with /mzdump here, 2026-09-24). EPL's Zidormi and
    # old Ghostlands' Zidormi take you to the same spots as the portals beside them, so the portals stand for both.
    {"id": "PORTAL_EPL_GHOSTLANDS", "out": "Nodes_EK.lua", "container": "ek_overworld.map23", "mapID": 23,
     "x": 0.5406, "y": 0.0846, "area": 2276, "note": "Eastern Plaguelands: the portal to the old Ghostlands (Quel'Lithien Lodge)"},
    {"id": "PORTAL_GHOSTLANDS_EPL", "out": "Nodes_BfA.lua", "container": "quelthalas.map95", "mapID": 95,
     "x": 0.5208, "y": 0.9783, "area": 3493, "note": "Old Ghostlands: the portal to the Eastern Plaguelands (Sanctum of the Sun)"},
    {"id": "PORTAL_RUINS_OF_LORDAERON_BC_SILVERMOON", "out": "Nodes_EK.lua", "container": "ek_overworld.map2070_art1136",
     "mapID": 2070, "x": 0.5946, "y": 0.6745, "note": "Ruins of Lordaeron (present Tirisfal): the portal to the old Silvermoon"},
    {"id": "PORTAL_TIRISFAL_PAST_BC_SILVERMOON", "out": "Nodes_EK.lua", "container": "ek_overworld.map18_art19",
     "mapID": 18, "x": 0.5947, "y": 0.6743, "area": 165,
     "note": "Past Tirisfal (Balnir Farmstead): the portal to the old Silvermoon, and where its way back lands"},
    {"id": "PORTAL_BC_SILVERMOON_TIRISFAL", "out": "Nodes_BfA.lua", "container": "quelthalas.map110", "mapID": 110,
     "x": 0.5068, "y": 0.1643, "note": "Old Silvermoon: the portal to Tirisfal, and where the ways in from Tirisfal land"},
    # The outside door of the Lycaneum, the Silvermoon-side portal room on the Isle of Quel'Danas
    # (the Omnium Folio portal). Captured with /mzdump here.
    {"id": "LYCANEUM_ENTRANCE", "out": "Nodes_EK.lua", "container": "ek_overworld.map2424",
     "mapID": 2424, "x": 0.6409, "y": 0.2895, "area": 16754,
     "note": "Entrance to the Lycaneum (Court of the Phoenix)"},
    # Dungeon and raid entrances the old data lacked. Named INSTANCE_<journalInstanceID>, so the client's own
    # Dungeon Journal names them; the coordinates are the entrances' map positions as given by the player.
    {"id": "INSTANCE_236", "out": "Nodes_EK.lua", "container": "ek_overworld.map23", "mapID": 23,
     "x": 0.266, "y": 0.118, "note": "Stratholme - Main Gate (Eastern Plaguelands)"},
    {"id": "INSTANCE_1292", "out": "Nodes_EK.lua", "container": "ek_overworld.map23", "mapID": 23,
     "x": 0.433, "y": 0.190, "note": "Stratholme - Service Entrance (the back door)"},
    {"id": "INSTANCE_237", "out": "Nodes_EK.lua", "container": "ek_overworld.map51", "mapID": 51,
     "x": 0.701, "y": 0.543, "note": "The Temple of Atal'hakkar (Swamp of Sorrows)"},
    {"id": "INSTANCE_230", "out": "Nodes_Kalimdor.lua", "container": "kalimdor_overworld.map69", "mapID": 69,
     "x": 0.596, "y": 0.405, "note": "Dire Maul (Feralas): one entrance for all three wings, listed under Capital Gardens"},
    {"id": "INSTANCE_1317", "out": "Nodes_EK.lua", "container": "ek_overworld.map2509", "mapID": 2509,
     "x": 0.600, "y": 0.664, "note": "The Tidebound Grotto (Coiled Isle): a single-boss raid, entered from the open world"},
    {"id": "INSTANCE_1305", "out": "Nodes_IsolatedMaps.lua", "container": "harandar.map2413", "mapID": 2413,
     "x": 0.736, "y": 0.665, "note": "Sporefall (Harandar): a single-boss raid, entered from the open world"},
    {"id": "INSTANCE_749", "out": "Nodes_Outlands.lua", "container": "outlands.map109", "mapID": 109,
     "x": 0.737, "y": 0.642, "note": "The Eye, Tempest Keep (Netherstorm)"},
    # Oribos: the flight master is on the Ring, a floor of its own (a separate map), reached from the pad on the
    # main floor. Same coordinates on both floors (given by the player).
    {"id": "ORIBOS_TRANSFERENCE_PAD", "out": "Nodes_Shadowlands.lua", "container": "sl_oribos.map1670",
     "mapID": 1670, "x": 0.486, "y": 0.506, "note": "The pad up to the Ring of Transference (main floor)"},
    {"id": "ORIBOS_TRANSFERENCE_RING", "out": "Nodes_Shadowlands.lua", "container": "sl_oribos.map1671",
     "mapID": 1671, "x": 0.486, "y": 0.506, "note": "Where the pad lands on the Ring (flight master floor)"},
    # Bizmo's Brawlpub, off the Deeprun Tram: the Pugilist's Powerful Punching Ring lands you in it. Its own map
    # (500), and the tram is another (499); both are interiors of a container of their own. The old data had
    # BIZMOS_BRAWLPUB on Stormwind's street (the tram's door), so it is dropped and put where the ring lands.
    {"id": "BIZMOS_BRAWLPUB", "out": "Nodes_EK.lua", "container": "deeprun_tram.map500", "mapID": 500,
     "x": 0.5111, "y": 0.2731, "note": "Bizmo's Brawlpub: where the Pugilist's ring lands you"},
    {"id": "BIZMOS_TO_TRAM", "out": "Nodes_EK.lua", "container": "deeprun_tram.map500", "mapID": 500,
     "x": 0.7221, "y": 0.0324, "note": "Bizmo's Brawlpub: the way out to the tram"},
    {"id": "TRAM_TO_BIZMOS", "out": "Nodes_EK.lua", "container": "deeprun_tram.map499", "mapID": 499,
     "x": 0.5249, "y": 0.7033, "note": "Deeprun Tram: the way in to Bizmo's Brawlpub"},
    {"id": "DEEPRUN_TRAM_TO_STORMWIND", "out": "Nodes_EK.lua", "container": "deeprun_tram.map499", "mapID": 499,
     "x": 0.4242, "y": 0.1214, "note": "Deeprun Tram: the way up to Stormwind"},
    {"id": "STORMWIND_TO_DEEPRUN_TRAM", "out": "Nodes_EK.lua", "container": "ek_overworld.map84", "mapID": 84,
     "x": 0.6937, "y": 0.3138, "note": "Stormwind (Dwarven District): the way down to the Deeprun Tram"},
    # Silvermoon's portal room (Stormwind and Orgrimmar): a small room off the street, an interior. Its door,
    # street side and room side, captured in game.
    {"id": "SILVERMOON_PORTAL_ROOM_ENTRANCE", "out": "Nodes_EK.lua", "container": "ek_overworld.map2393",
     "mapID": 2393, "x": 0.5323, "y": 0.6611, "note": "Silvermoon: the portal room's door, street side"},
    {"id": "SILVERMOON_PORTAL_ROOM_EXIT", "out": "Nodes_EK.lua", "container": "ek_overworld.map2393.interior",
     "mapID": 2393, "x": 0.5316, "y": 0.6604, "note": "Silvermoon: the portal room's door, room side"},
    # Brawl'gar Arena, Orgrimmar's brawlers' guild: a map of its own (503) off Orgrimmar's street, an interior. The
    # Pugilist's ring (Horde) lands you in it. The old data had BRAWLGAR_ARENA on the street (the door), so it is
    # dropped and put where the ring lands, like Bizmo's.
    {"id": "BRAWLGAR_ARENA", "out": "Nodes_Kalimdor.lua", "container": "brawlgar_arena.map503", "mapID": 503,
     "x": 0.4222, "y": 0.7481, "note": "Brawl'gar Arena: where the Pugilist's ring lands you"},
    {"id": "BRAWLGAR_TO_ORGRIMMAR", "out": "Nodes_Kalimdor.lua", "container": "brawlgar_arena.map503", "mapID": 503,
     "x": 0.5553, "y": 0.1426, "note": "Brawl'gar Arena: the way out to Orgrimmar"},
    {"id": "ORGRIMMAR_TO_BRAWLGAR", "out": "Nodes_Kalimdor.lua", "container": "kalimdor_overworld.map85", "mapID": 85,
     "x": 0.7055, "y": 0.3103, "note": "Orgrimmar (Valley of Strength): the way in to Brawl'gar Arena"},
]

# Old-data nodes that are inside Silvermoon's portal room (the room's own portals, and where its incoming portals
# arrive). The street's other portals (Harandar, Voidstorm, Coiled Isle, Magisters', the Arcantina) stay outside.
NODE_CONTAINERS = {
    "SILVERMOON_STORMWIND_PORTAL": "ek_overworld.map2393.interior",
    "SILVERMOON_ORGRIMMAR_PORTAL": "ek_overworld.map2393.interior",
    "SILVERMOON_PORTAL_ROOM": "ek_overworld.map2393.interior",
}

# Old-data nodes replaced by a NODES entry of the same id.
DROP_NODES = ["BIZMOS_BRAWLPUB", "BRAWLGAR_ARENA"]

# The Lycaneum's own map: its portal room is an interior reached on foot from the entrance above,
# not a point you can fly to.
INDOOR = ["ek_overworld.map2649", "deeprun_tram", "ek_overworld.map2393.interior", "brawlgar_arena"]        # the tram and Bizmo's Brawlpub are both under it

EDGES = [
    # EPL <-> the old Ghostlands, each landing by the other side's portal. Tirisfal <-> the old Silvermoon (confirmed in
    # game 2026-09-24): present Tirisfal's Ruins of Lordaeron and past Tirisfal's Balnir Farmstead each have a portal in,
    # and the old Silvermoon's one portal back goes to whichever Tirisfal the player is in (Zidormi's tirisfal group).
    {"from": "PORTAL_EPL_GHOSTLANDS", "to": "PORTAL_GHOSTLANDS_EPL", "method": "portal", "cost": 0},
    {"from": "PORTAL_SHATTRATH_QUELDANAS", "to": "QUELDANAS", "method": "portal", "cost": 0, "oneway": True},
    {"from": "PORTAL_RUINS_OF_LORDAERON_BC_SILVERMOON", "to": "PORTAL_BC_SILVERMOON_TIRISFAL", "method": "portal",
     "cost": 0, "oneway": True},
    {"from": "PORTAL_TIRISFAL_PAST_BC_SILVERMOON", "to": "PORTAL_BC_SILVERMOON_TIRISFAL", "method": "portal",
     "cost": 0, "oneway": True},
    {"from": "PORTAL_BC_SILVERMOON_TIRISFAL", "to": "PORTAL_RUINS_OF_LORDAERON_BC_SILVERMOON", "method": "portal",
     "cost": 0, "oneway": True, "inPhase": ("tirisfal", 1136)},
    {"from": "PORTAL_BC_SILVERMOON_TIRISFAL", "to": "PORTAL_TIRISFAL_PAST_BC_SILVERMOON", "method": "portal",
     "cost": 0, "oneway": True, "inPhase": ("tirisfal", 19)},
    # Running from the entrance to the portal inside, and back out: an explicit edge, since an interior
    # never auto-connects to the outdoors, but costed like any walk (distance and the default path factor).
    {"from": "LYCANEUM_ENTRANCE", "to": "MAGISTERS_SILVERMOON_PORTAL", "method": "walk"},
    {"from": "MAGISTERS_SILVERMOON_PORTAL", "to": "LYCANEUM_ENTRANCE", "method": "walk"},
    # Oribos: up to the Ring and back down by the pad, a few seconds and no loading screen (confirmed in game
    # 2026-09-24). From the pad to the flight master, and from the Oribos entrance to
    # the pad, are ordinary walks the engine works out from distance within each floor.
    {"from": "ORIBOS_TRANSFERENCE_PAD", "to": "ORIBOS_TRANSFERENCE_RING", "method": "portal", "cost": 3,
     "loadingScreens": 0},
    # Bizmo's Brawlpub <-> the Deeprun Tram <-> Stormwind: the doors between three maps, whose distances the
    # client can't measure, so each is an explicit walk (a few seconds through the door). The walks inside each map
    # are costed from distance as usual. No loading screen between Bizmo's and the tram; one between the tram and
    # Stormwind (confirmed in game 2026-09-24).
    # Silvermoon's portal room: in and out by the one door (costed from distance, on the same map).
    {"from": "SILVERMOON_PORTAL_ROOM_ENTRANCE", "to": "SILVERMOON_PORTAL_ROOM_EXIT", "method": "walk"},
    # Brawl'gar Arena <-> Orgrimmar: the one door between two maps, so an explicit walk through it. One loading
    # screen is a guess (the arena is a map of its own, like the Deeprun Tram): correct it if the door doesn't load.
    {"from": "BRAWLGAR_TO_ORGRIMMAR", "to": "ORGRIMMAR_TO_BRAWLGAR", "method": "walk", "cost": 2, "loadingScreens": 1},
    {"from": "BIZMOS_TO_TRAM", "to": "TRAM_TO_BIZMOS", "method": "walk", "cost": 2, "loadingScreens": 0},
    {"from": "DEEPRUN_TRAM_TO_STORMWIND", "to": "STORMWIND_TO_DEEPRUN_TRAM", "method": "walk", "cost": 2,
     "loadingScreens": 1},
]

# The old data walked straight from Oribos to the flight master: two maps, so no distance. The pad route above
# replaces it (left in, it would undercut the real route).
DROP_EDGES = [
    {"from": "ORIBOS", "to": "TAXI_2395", "method": "walk"},
    # The Burning Crusade Quel'Thalas is shut off from the rest of the world since Midnight (checked in game
    # 2026-09-24): these pre-Midnight flights into it no longer exist. Its ways in are EPL's portal, Orgrimmar's and
    # Tirisfal's portals (Horde), and Shattrath's portal to the Isle of Quel'Danas (one way).
    {"from": "TAXI_85", "to": "TAXI_205", "method": "taxi"},
    {"from": "TAXI_213", "to": "LIGHTS_HOPE_CHAPEL", "method": "taxi"},
    # Shattrath's portal to the Isle of Quel'Danas leaves from the portal itself (PORTAL_SHATTRATH_QUELDANAS, below).
    {"from": "SHATTRATH_OUTLANDS", "to": "QUELDANAS", "method": "portal"},
]

# Seconds an equip step takes, per item (see above). The rest of the equippable teleport items can be used at once
# (measured in game 2026-09-24: 40586, 65360, 63206, 63352, 65274, 63207, 63353, 103678, 63379, 63378, 46874,
# 144391, 144392, 142469), which is the default.
EQUIP_COOLDOWNS = {
    32757: 30,      # Blessed Medallion of Karabor: on cooldown for 30 s once equipped (its cast time is 10 s)
}

# Faction for an item-based teleport whose old data doesn't say, by (itemID, destination node): the two Garrison
# Hearthstones share an item and go to each faction's own garrison, so each player is offered only theirs.
ABILITY_FACTIONS = {
    (110560, "LUNARFALL"): "Alliance",
    (110560, "FROSTWALL"): "Horde",
}

# Item costs (seconds to cast) where the old data's is wrong now that equipping is a step of its own: the old
# Medallion cost of 40 was its 10 s cast plus the 30 s equip wait.
ITEM_COSTS = {
    32757: 10,
}

# The cities (see the docstring). Moved here from Data/Modern/Places.lua's CityPlaces (2026-09-24), so Modern's cities
# are the same addon.Cities shape as Forever's.
CITIES = {
    "stormwind":            {"maps": [84],   "expansion": 1,  "faction": "Alliance", "hub": True},
    "ironforge":            {"maps": [87],   "expansion": 1,  "faction": "Alliance"},
    "darnassus":            {"maps": [89],   "expansion": 1,  "faction": "Alliance"},
    "orgrimmar":            {"maps": [85],   "expansion": 1,  "faction": "Horde", "hub": True},
    "thunder_bluff":        {"maps": [88],   "expansion": 1,  "faction": "Horde"},
    "undercity":            {"maps": [90],   "expansion": 1,  "faction": "Horde"},
    "exodar":               {"maps": [103],  "expansion": 2,  "faction": "Alliance"},
    "silvermoon_bc":        {"maps": [110],  "expansion": 2,  "faction": "Horde"},
    "shattrath":            {"maps": [111],  "expansion": 2,  "faction": "Both"},
    "dalaran_northrend":    {"maps": [125],  "expansion": 3,  "faction": "Both", "hub": True},
    # Both shrines are part of the Vale of Eternal Blossoms' map (390); map 393 holds no node.
    "shrine_of_seven_stars": {"maps": [390], "expansion": 5,  "faction": "Alliance",
                              "nodes": ["SHRINE_OF_SEVEN_STARS", "TAXI_1057"], "taxi": "TAXI_1057"},
    "shrine_of_two_moons":  {"maps": [390],  "expansion": 5,  "faction": "Horde",
                             "nodes": ["SHRINE_OF_TWO_MOONS", "TAXI_1058"], "taxi": "TAXI_1058"},
    "lunarfall":            {"maps": [582],  "expansion": 6,  "faction": "Alliance"},
    "frostwall":            {"maps": [590],  "expansion": 6,  "faction": "Horde"},
    "stormshield":          {"maps": [622],  "expansion": 6,  "faction": "Alliance"},
    "warspear":             {"maps": [624],  "expansion": 6,  "faction": "Horde"},
    "dalaran_broken_isles": {"maps": [627],  "expansion": 7,  "faction": "Both", "hub": True},
    "boralus":              {"maps": [1161], "expansion": 8,  "faction": "Alliance"},
    "dazaralor":            {"maps": [1165], "expansion": 8,  "faction": "Horde"},
    "oribos":               {"maps": [1670, 1671], "expansion": 9, "faction": "Both", "hub": True},
    "valdrakken":           {"maps": [2112], "expansion": 10, "faction": "Both", "hub": True},
    "dornogal":             {"maps": [2339], "expansion": 11, "faction": "Both", "hub": True},
    "undermine":            {"maps": [2346], "expansion": 11, "faction": "Both"},
    "silvermoon":           {"maps": [2393], "expansion": 12, "faction": "Both", "hub": True},
}

# Moved here from Data/Modern/Places.lua's InstanceNodeAliases (2026-09-24): the journal id is a field on the node now.
INSTANCE_JOURNALS = {
    "NEXUS_POINT_XENAS_DUNGEON": 1316,
    "DAWN_OF_THE_INFINITES_DUNGEON": 1209,          # two wings in Group Finder, one entrance
    "BARADIN_HOLD": 75,
    "LOST_CITY_OF_THE_TOLVIR": 69,
    "MAGISTERS_TERRACE_DUNGEON": 1300,              # the Midnight Magisters' Terrace (Quel'Thalas), not the old one
    "MAGISTERS_TERRACE_BC_DUNGEON": 249,            # the Burning Crusade one, Isle of Quel'Danas
    "BATTLE_OF_DAZARALOR_RAID_ALLIANCE": (1176, "Alliance"),
    "BATTLE_OF_DAZARALOR_RAID_HORDE": (1176, "Horde"),
    "SIEGE_OF_BORALUS_DUNGEON_ALLIANCE": (1023, "Alliance"),
    "SIEGE_OF_BORALUS_DUNGEON_HORDE": (1023, "Horde"),
    "THE_MOTHERLODE_DUNGEON_ALLIANCE": (1012, "Alliance"),
    "THE_MOTHERLODE_DUNGEON_HORDE": (1012, "Horde"),
    "NYALOTHA_THE_WAKING_CITY_RAID_ULDUM": 1180,    # two entrances that swap each week: one destination,
    "NYALOTHA_THE_WAKING_CITY_RAID_PANDARIA": 1180, # whichever is nearer
}

# Area ids by hand (see the docstring): none yet.
AREA_OVERRIDES = {
}

# Places of a POI kind (see the docstring). Silvermoon's inn: the hearthstone can resolve to it.
NODE_KINDS = {
    "SILVERMOON_INN": "inn",
}

# The Burning Crusade Quel'Thalas (maps 94, 95, 110) is still live beside Midnight's: a region of its own, entered by
# portal (Orgrimmar, the Ruins of Lordaeron, EPL; confirmed in game 2026-09-24). The old data authored its flight masters
# under the same ids as Midnight's; these give them their own.
SECOND_COPY_IDS = {
    "SILVERMOON_CITY_FLIGHT": "SILVERMOON_CITY_BC_FLIGHT",
    "FAIRBREEZE_VILLAGE_FLIGHT": "FAIRBREEZE_VILLAGE_BC_FLIGHT",
}

NODE_PLACES = {
    # Where Shattrath's portal lands on the Isle of Quel'Danas (captured in game 2026-09-24).
    "QUELDANAS": {"container": "queldanas.map122", "mapID": 122, "x": 0.4825, "y": 0.3448},
    # /mzdump nodes 110: Falconwing Square is in old Eversong, not in old Silvermoon.
    "FALCONWING_SQUARE_FLIGHT": {"container": "quelthalas.map94", "mapID": 94, "x": 0.4629, "y": 0.4665},
}

CONFIRMED_TAXI_IDS = {
    "SILVERMOON_CITY_BC_FLIGHT": "82",          # /mzdump nodes 110: "Silvermoon City" on old Eversong's map
    "FAIRBREEZE_VILLAGE_BC_FLIGHT": "625",      # old Fairbreeze Village
    "SILVERMOON_CITY_FLIGHT": "3131",           # Midnight's Silvermoon: Sanctum of Light (captured in game)
}

