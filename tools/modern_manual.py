"""Hand additions to the Modern data that the old addon's data doesn't have, read by
tools/gen_modern_nodes.py and tools/gen_modern_edges.py so a regeneration keeps them
(Data/Modern/*.lua is generated: hand edits there are lost on the next run).

NODES    places the old data lacks, usually captured in game with /mzdump here. Each is
         { "id", "out" (which Nodes_*.lua it goes in), "container", "mapID", "x", "y",
         optional "area" (the client's area id: gives the node a localized name), optional "faction" (a place only
         one faction can use: a one-faction flight master), "note" }.
INDOOR   containers the old data didn't flag `interior` but are: no flying to or from them.
EDGES    connections the old data lacks: { "from", "to", "method", optional "cost", optional "oneway",
         optional "loadingScreens", optional "inPhase" = (group, side): only on that side of a phase group,
         optional "requirements" = { key: value } as the engine's EdgeRequirements has them (faction = "Horde") }.
         Leave `cost` out for a walk and the engine works it out from distance and the default path
         factor, like any other walk.
CONSUMABLES  { itemID }: teleport items used up when used; routing prefers anything else as quick.
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
TELEPORTS  spells the old data lacks: { "spellID", "to" (the node it lands on), optional "cost" (cast seconds, 10),
         optional "faction" }.
CAMPS    abilities that go back to a spot the player set themselves (Vulpera's Return to Camp): { "spellID" (the one
         that goes there), "setSpellID" (the one that sets the spot: its cast saves the position, Core.lua), optional
         "cost" (cast seconds, 10), optional "cooldown" (seconds) }. Written to addon.Abilities.Camps.
CITIES   the cities, in the same shape as Forever's (addon.Cities, Data/Forever/Pois.lua): key -> { "maps" (the
         uiMapIDs the city is, the first its own), "expansion" (major version), "faction", optional "hub" (also on
         the picker's main page whatever its expansion), optional "nodes" (the node ids its centre is the average of,
         when the default -- every outdoor node on its first map -- would be wrong: a city that is part of a zone's
         map), optional "taxi" (its flight master, which names it when its map's name isn't its own) }.
         gen_modern_nodes.py writes them to Data/Modern/Settlements.lua with a CITY_<KEY> centre node each.
"""

NODES = [
    # The Burning Crusade Quel'Thalas is no-fly (the old Ghostlands, Eversong, Silvermoon and the Isle of Quel'Danas;
    # checked in game 2026-09-24), so its zones are joined on foot, Forever-style: a border node on each side of the
    # zone line, and the same for old Silvermoon's gate (a border, not a city entrance: portals land inside the city,
    # and a city with entrances is routed to its gates). Captured with /mzdump here.
    {"id": "BORDER_GHOSTLANDS_EVERSONG_BC", "out": "Nodes_BfA.lua", "container": "quelthalas.map95", "mapID": 95,
     "x": 0.4843, "y": 0.1068, "note": "Old Ghostlands: the road north into old Eversong"},
    {"id": "BORDER_EVERSONG_GHOSTLANDS_BC", "out": "Nodes_BfA.lua", "container": "quelthalas.map94", "mapID": 94,
     "x": 0.4862, "y": 0.9147, "note": "Old Eversong: the road south into the old Ghostlands"},
    {"id": "BORDER_EVERSONG_SILVERMOON_BC", "out": "Nodes_BfA.lua", "container": "quelthalas.map94", "mapID": 94,
     "x": 0.5621, "y": 0.4917, "note": "Old Eversong: outside old Silvermoon's gate"},
    {"id": "BORDER_SILVERMOON_EVERSONG_BC", "out": "Nodes_BfA.lua", "container": "quelthalas.map110", "mapID": 110,
     "x": 0.7054, "y": 0.8903, "note": "Old Silvermoon: inside its gate"},
    {"id": "PORTAL_SHATTRATH_QUELDANAS", "out": "Nodes_Outlands.lua", "container": "outlands.map111", "mapID": 111,
     "x": 0.4876, "y": 0.4210, "note": "Shattrath: the portal to the Isle of Quel'Danas (captured in game 2026-09-24)"},
    # Midnight's Silvermoon has two flight masters; the old data had only the Sanctum of Light one. The Royal Exchange
    # one is Horde only (captured in game 2026-09-24).
    {"id": "TAXI_3132", "out": "Nodes_EK.lua", "container": "ek_overworld.map2393", "mapID": 2393,
     "x": 0.6944, "y": 0.6341, "faction": "Horde", "note": "Silvermoon City: the Royal Exchange flight master (Horde)"},
    # The Burning Crusade Quel'Thalas, entered by portal (captured with /mzdump here, 2026-09-24). EPL's Zidormi and
    # old Ghostlands' Zidormi take you to the same spots as the portals beside them, so the portals stand for both.
    {"id": "PORTAL_EPL_GHOSTLANDS", "out": "Nodes_EK.lua", "container": "ek_overworld.map23", "mapID": 23,
     "x": 0.5406, "y": 0.0846, "note": "Eastern Plaguelands: the portal to the old Ghostlands (Quel'Lithien Lodge)"},
    {"id": "PORTAL_GHOSTLANDS_EPL", "out": "Nodes_BfA.lua", "container": "quelthalas.map95", "mapID": 95,
     "x": 0.5208, "y": 0.9783, "note": "Old Ghostlands: the portal to the Eastern Plaguelands (Sanctum of the Sun)"},
    {"id": "PORTAL_RUINS_OF_LORDAERON_BC_SILVERMOON", "out": "Nodes_EK.lua", "container": "ek_overworld.map2070_art1136",
     "mapID": 2070, "x": 0.5946, "y": 0.6745, "note": "Ruins of Lordaeron (present Tirisfal): the portal to the old Silvermoon"},
    {"id": "PORTAL_TIRISFAL_PAST_BC_SILVERMOON", "out": "Nodes_EK.lua", "container": "ek_overworld.map18_art19",
     "mapID": 18, "x": 0.5947, "y": 0.6743,
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
    # The Timeways (map 2266): reached by a portal in Silvermoon, with a portal back, and by Dornogal's old portal
    # (one way now: it still works, but the Timeways' only way out to a city is Silvermoon's). Ground mounts, no flying
    # (gen_modern_nodes.py's NO_FLY_MAPS). The season's Mythic+ portals out of it are below (MPLUS_SEASON_*).
    # Captured with /mzdump here.
    {"id": "PORTAL_SILVERMOON_TIMEWAYS", "out": "Nodes_EK.lua", "container": "ek_overworld.map2393", "mapID": 2393,
     "x": 0.4218, "y": 0.5827, "note": "Silvermoon: the portal to the Timeways, and where the way back lands"},
    {"id": "PORTAL_DORNOGAL_TIMEWAYS", "out": "Nodes_KhazAlgar.lua", "container": "khaz_algar.map2339", "mapID": 2339,
     "x": 0.5380, "y": 0.3872, "note": "Dornogal: the portal to the Timeways (one way: the way back goes to Silvermoon)"},
    {"id": "PORTAL_TIMEWAYS_SILVERMOON", "out": "Nodes_IsolatedMaps.lua", "container": "timeways.map2266", "mapID": 2266,
     "x": 0.4930, "y": 0.5190, "note": "The Timeways: the portal to Silvermoon, and where the way in lands"},
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
INDOOR = ["ek_overworld.map2649", "deeprun_tram", "ek_overworld.map2393.interior", "brawlgar_arena",
          "ek_overworld.map30", "ek_overworld.map30.upper"]     # Gnomeregan's two underground levels        # the tram and Bizmo's Brawlpub are both under it

EDGES = [
    # EPL <-> the old Ghostlands, each landing by the other side's portal. Tirisfal <-> the old Silvermoon (confirmed in
    # game 2026-09-24): present Tirisfal's Ruins of Lordaeron and past Tirisfal's Balnir Farmstead each have a portal in,
    # and the old Silvermoon's one portal back goes to whichever Tirisfal the player is in (Zidormi's tirisfal group).
    # All four are the Horde's (the Undercity's old orb).
    {"from": "PORTAL_EPL_GHOSTLANDS", "to": "PORTAL_GHOSTLANDS_EPL", "method": "portal", "cost": 0},
    # Across the old Quel'Thalas zone lines and through old Silvermoon's gate (the two points of each are a step apart,
    # on two maps whose distance the client may not give, so a few seconds each).
    {"from": "BORDER_GHOSTLANDS_EVERSONG_BC", "to": "BORDER_EVERSONG_GHOSTLANDS_BC", "method": "walk", "cost": 3},
    {"from": "BORDER_EVERSONG_SILVERMOON_BC", "to": "BORDER_SILVERMOON_EVERSONG_BC", "method": "walk", "cost": 3},
    {"from": "PORTAL_SHATTRATH_QUELDANAS", "to": "QUELDANAS", "method": "portal", "cost": 0, "oneway": True},
    {"from": "PORTAL_RUINS_OF_LORDAERON_BC_SILVERMOON", "to": "PORTAL_BC_SILVERMOON_TIRISFAL", "method": "portal",
     "cost": 0, "oneway": True, "requirements": {"faction": "Horde"}},
    {"from": "PORTAL_TIRISFAL_PAST_BC_SILVERMOON", "to": "PORTAL_BC_SILVERMOON_TIRISFAL", "method": "portal",
     "cost": 0, "oneway": True, "requirements": {"faction": "Horde"}},
    {"from": "PORTAL_BC_SILVERMOON_TIRISFAL", "to": "PORTAL_RUINS_OF_LORDAERON_BC_SILVERMOON", "method": "portal",
     "cost": 0, "oneway": True, "inPhase": ("tirisfal", 1136), "requirements": {"faction": "Horde"}},
    {"from": "PORTAL_BC_SILVERMOON_TIRISFAL", "to": "PORTAL_TIRISFAL_PAST_BC_SILVERMOON", "method": "portal",
     "cost": 0, "oneway": True, "inPhase": ("tirisfal", 19), "requirements": {"faction": "Horde"}},
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
    # Silvermoon <-> the Timeways: a portal each way, clicked, a loading screen each (confirmed in game). Each lands
    # by the other side's portal.
    {"from": "PORTAL_SILVERMOON_TIMEWAYS", "to": "PORTAL_TIMEWAYS_SILVERMOON", "method": "portal", "cost": 0,
     "oneway": True},
    {"from": "PORTAL_TIMEWAYS_SILVERMOON", "to": "PORTAL_SILVERMOON_TIMEWAYS", "method": "portal", "cost": 0,
     "oneway": True},
    # Dornogal -> the Timeways, one way (confirmed in game); lands where Silvermoon's does.
    {"from": "PORTAL_DORNOGAL_TIMEWAYS", "to": "PORTAL_TIMEWAYS_SILVERMOON", "method": "portal", "cost": 0,
     "oneway": True},
    # The Vaults of Atal'Utek's Windcaller network, from the Amani Foothold Windcaller (see DROP_EDGES): the old
    # data's times for these legs, which it gave the flight master a few steps away.
    {"from": "AMANI_FOOTHOLD_FLIGHT_2", "to": "FLIGHT_NORTHERN_AMANI_BULWARK", "method": "taxi", "cost": 33},
    {"from": "AMANI_FOOTHOLD_FLIGHT_2", "to": "FLIGHT_EASTERN_AMANI_OUTPOST", "method": "taxi", "cost": 22},
    {"from": "AMANI_FOOTHOLD_FLIGHT_2", "to": "FLIGHT_THE_VENOMOUS_ABYSS", "method": "taxi", "cost": 27},
    {"from": "AMANI_FOOTHOLD_FLIGHT_2", "to": "FLIGHT_THE_UNDERBELLY", "method": "taxi", "cost": 43},
]

# The current Mythic+ season's portals out of the Timeways: one to each of the season's dungeons from older
# expansions, one way, clicked, a loading screen each, no requirements (as far as is known). Swap these two
# lists each season and regenerate (gen_modern_nodes.py, then gen_modern_edges.py). Each lands near the dungeon,
# and the walk on to its entrance (INSTANCE_*) is worked out like any other. Captured with /mzdump here.
MPLUS_SEASON_NODES = [
    {"id": "PORTAL_TIMEWAYS_KINGS_REST", "out": "Nodes_IsolatedMaps.lua", "container": "timeways.map2266",
     "mapID": 2266, "x": 0.7339, "y": 0.4821, "note": "The Timeways: the season's portal to Kings' Rest"},
    {"id": "PORTAL_TIMEWAYS_RUBY_LIFE_POOLS", "out": "Nodes_IsolatedMaps.lua", "container": "timeways.map2266",
     "mapID": 2266, "x": 0.7655, "y": 0.6135, "note": "The Timeways: the season's portal to the Ruby Life Pools"},
    {"id": "PORTAL_TIMEWAYS_TEMPLE_OF_SETHRALISS", "out": "Nodes_IsolatedMaps.lua", "container": "timeways.map2266",
     "mapID": 2266, "x": 0.7014, "y": 0.7152, "note": "The Timeways: the season's portal to the Temple of Sethraliss"},
    {"id": "TIMEWAYS_ARRIVAL_KINGS_REST", "out": "Nodes_Zandalar.lua", "container": "zandalar.map862", "mapID": 862,
     "x": 0.4368, "y": 0.4543, "area": 9404, "note": "Zuldazar: where the Timeways portal to Kings' Rest lands"},
    {"id": "TIMEWAYS_ARRIVAL_RUBY_LIFE_POOLS", "out": "Nodes_DragonIsles.lua", "container": "dragon_isles.map2022",
     "mapID": 2022, "x": 0.5804, "y": 0.7840, "area": 13944,
     "note": "The Waking Shores: where the Timeways portal to the Ruby Life Pools lands"},
    {"id": "TIMEWAYS_ARRIVAL_TEMPLE_OF_SETHRALISS", "out": "Nodes_Zandalar.lua", "container": "zandalar.map864",
     "mapID": 864, "x": 0.5092, "y": 0.3822, "area": 9347,
     "note": "Vol'dun: where the Timeways portal to the Temple of Sethraliss lands"},
]
MPLUS_SEASON_EDGES = [
    {"from": "PORTAL_TIMEWAYS_KINGS_REST", "to": "TIMEWAYS_ARRIVAL_KINGS_REST", "method": "portal", "cost": 0,
     "oneway": True},
    {"from": "PORTAL_TIMEWAYS_RUBY_LIFE_POOLS", "to": "TIMEWAYS_ARRIVAL_RUBY_LIFE_POOLS", "method": "portal",
     "cost": 0, "oneway": True},
    {"from": "PORTAL_TIMEWAYS_TEMPLE_OF_SETHRALISS", "to": "TIMEWAYS_ARRIVAL_TEMPLE_OF_SETHRALISS", "method": "portal",
     "cost": 0, "oneway": True},
]
NODES += MPLUS_SEASON_NODES
EDGES += MPLUS_SEASON_EDGES

# The pet battle portals (Dalaran, Dazar'alor, Boralus) land by an NPC near each dungeon, not at its entrance where the
# old data had them (captured in game 2026-10-09). Stratholme's land by its Eastwall gate (STRATHOLME_DUNGEON stays the
# main entrance); Wailing Caverns' just inside its small cave, given as the cave mouth outside. Gnomeregan's, the
# Deadmines' and Blackrock Depths' land within a few yards of their entrances, which stay their landings (Gnomeregan's
# entrance moved underground: GNOMEREGAN_NODES). DROP_EDGES has the old landings.
PET_PORTAL_NODES = [
    {"id": "PET_PORTAL_ARRIVAL_STRATHOLME", "out": "Nodes_EK.lua", "container": "ek_overworld.map23", "mapID": 23,
     "x": 0.4320, "y": 0.1998, "area": 2275,
     "note": "Eastern Plaguelands: where the pet battle portals to Stratholme land, by the Eastwall gate"},
    {"id": "PET_PORTAL_ARRIVAL_WAILING_CAVERNS", "out": "Nodes_Kalimdor.lua", "container": "kalimdor_overworld.map10",
     "mapID": 10, "x": 0.3874, "y": 0.6860, "area": 386,
     "note": "Northern Barrens: the Wailing Caverns' cave mouth, for the pet battle portals that land just inside"},
]
PET_PORTAL_EDGES = [
    {"from": "DALARAN_BROKEN_ISLES_PET", "to": "PET_PORTAL_ARRIVAL_STRATHOLME", "method": "portal", "cost": 0,
     "oneway": True, "requirements": {"quest": 56491}},
    {"from": "DAZARALOR_PET", "to": "PET_PORTAL_ARRIVAL_STRATHOLME", "method": "portal", "cost": 0,
     "oneway": True, "requirements": {"quest": 56491, "faction": "Horde"}},
    {"from": "BORALUS_PET", "to": "PET_PORTAL_ARRIVAL_STRATHOLME", "method": "portal", "cost": 0,
     "oneway": True, "requirements": {"quest": 56491, "faction": "Alliance"}},
]
for _quest, _arrival in [(45423, "PET_PORTAL_ARRIVAL_WAILING_CAVERNS")]:
    PET_PORTAL_EDGES += [
        {"from": "DALARAN_BROKEN_ISLES_PET", "to": _arrival, "method": "portal", "cost": 0, "oneway": True,
         "requirements": {"quest": _quest}},
        {"from": "DAZARALOR_PET", "to": _arrival, "method": "portal", "cost": 0, "oneway": True,
         "requirements": {"quest": _quest, "faction": "Horde"}},
        {"from": "BORALUS_PET", "to": _arrival, "method": "portal", "cost": 0, "oneway": True,
         "requirements": {"quest": _quest, "faction": "Alliance"}},
    ]

NODES += PET_PORTAL_NODES
EDGES += PET_PORTAL_EDGES

# Gnomeregan (captured in game 2026-10-09). Its entrance is underground (map 30, under New Tinkertown), beside where the
# pet battle portals land: two levels, no mount at all (INDOOR), joined by an elevator (D = 5, T = 10: 2T + D = 25 s).
# From the top a tunnel comes out in New Tinkertown (map 469, over Dun Morogh, open to fly in and out: its two nodes are
# put on Dun Morogh's map, where a player in New Tinkertown is placed too, by the client's map table); a
# teleporter beside the elevator goes one way to the surface (a loading screen). Elite guards stand at the tunnel's
# mouth and New Tinkertown is the Alliance's: the tunnel and the teleporter are Alliance only. The Horde's way in is a
# teleporter at Grom'gol Base Camp straight into the dungeon (leaving the dungeon goes back there), so the Horde has an
# entrance of its own (INSTANCE_JOURNALS).
GNOMEREGAN_NODES = [
    {"id": "GNOMEREGAN_ELEVATOR_BASE", "out": "Nodes_EK.lua", "container": "ek_overworld.map30", "mapID": 30,
     "x": 0.6808, "y": 0.8287, "note": "Gnomeregan, underground: the foot of the elevator"},
    {"id": "GNOMEREGAN_TELEPORTER", "out": "Nodes_EK.lua", "container": "ek_overworld.map30", "mapID": 30,
     "x": 0.6730, "y": 0.8380, "note": "Gnomeregan, underground: the teleporter up to New Tinkertown"},
    {"id": "GNOMEREGAN_ELEVATOR_TOP", "out": "Nodes_EK.lua", "container": "ek_overworld.map30.upper", "mapID": 30,
     "x": 0.7147, "y": 0.8296, "note": "Gnomeregan, underground: the top of the elevator"},
    {"id": "GNOMEREGAN_TUNNEL", "out": "Nodes_EK.lua", "container": "ek_overworld.map30.upper", "mapID": 30,
     "x": 0.8125, "y": 0.8431, "note": "Gnomeregan: the tunnel's end, under New Tinkertown (captured on Dun Morogh's map)"},
    {"id": "NEW_TINKERTOWN_TUNNEL", "out": "Nodes_EK.lua", "container": "ek_overworld.map27", "mapID": 27,
     "x": 0.3135, "y": 0.3803, "note": "New Tinkertown: the tunnel down to Gnomeregan (captured on map 469)"},
    {"id": "NEW_TINKERTOWN_TELEPORT_EXIT", "out": "Nodes_EK.lua", "container": "ek_overworld.map27", "mapID": 27,
     "x": 0.3388, "y": 0.3859, "note": "New Tinkertown: where Gnomeregan's teleporter comes out (captured on map 469)"},
    {"id": "GNOMEREGAN_DUNGEON_HORDE", "out": "Nodes_EK.lua", "container": "ek_overworld.map50", "mapID": 50,
     "x": 0.3684, "y": 0.5099, "note": "Grom'gol Base Camp: the Horde's teleporter into Gnomeregan"},
]
GNOMEREGAN_EDGES = [
    {"from": "GNOMEREGAN_ELEVATOR_BASE", "to": "GNOMEREGAN_ELEVATOR_TOP", "method": "walk", "cost": 25},
    {"from": "GNOMEREGAN_TELEPORTER", "to": "NEW_TINKERTOWN_TELEPORT_EXIT", "method": "portal", "cost": 0, "oneway": True,
     "requirements": {"faction": "Alliance"}},
    {"from": "GNOMEREGAN_TUNNEL", "to": "NEW_TINKERTOWN_TUNNEL", "method": "walk", "requirements": {"faction": "Alliance"}},
]
NODES += GNOMEREGAN_NODES
EDGES += GNOMEREGAN_EDGES

# The old data walked straight from Oribos to the flight master: two maps, so no distance. The pad route above
# replaces it (left in, it would undercut the real route).
DROP_EDGES = [
    {"from": "ORIBOS", "to": "TAXI_2395", "method": "walk"},
    # The Vaults of Atal'Utek's Windcallers are a network of their own (checked in game 2026-10-06): the old data
    # flew them from the zone's flight master, Amani Foothold (TAXI_3288), which only flies out of the Vaults. They
    # leave from the Amani Foothold Windcaller instead (EDGES).
    {"from": "TAXI_3288", "to": "FLIGHT_NORTHERN_AMANI_BULWARK", "method": "taxi"},
    {"from": "TAXI_3288", "to": "FLIGHT_EASTERN_AMANI_OUTPOST", "method": "taxi"},
    {"from": "TAXI_3288", "to": "FLIGHT_THE_VENOMOUS_ABYSS", "method": "taxi"},
    {"from": "TAXI_3288", "to": "FLIGHT_THE_UNDERBELLY", "method": "taxi"},
    # The Burning Crusade Quel'Thalas is shut off from the rest of the world since Midnight (checked in game
    # 2026-09-24): these pre-Midnight flights into it no longer exist. Its ways in are EPL's portal, Orgrimmar's and
    # Tirisfal's portals (Horde), and Shattrath's portal to the Isle of Quel'Danas (one way).
    {"from": "TAXI_85", "to": "TAXI_205", "method": "taxi"},
    {"from": "TAXI_213", "to": "LIGHTS_HOPE_CHAPEL", "method": "taxi"},
    # Shattrath's portal to the Isle of Quel'Danas leaves from the portal itself (PORTAL_SHATTRATH_QUELDANAS, below).
    {"from": "SHATTRATH_OUTLANDS", "to": "QUELDANAS", "method": "portal"},
    # The pet battle portals land by Stratholme's Eastwall gate (PET_PORTAL_ARRIVAL_STRATHOLME), not at its main entrance.
    {"from": "DALARAN_BROKEN_ISLES_PET", "to": "STRATHOLME_DUNGEON", "method": "portal"},
    {"from": "DAZARALOR_PET", "to": "STRATHOLME_DUNGEON", "method": "portal"},
    {"from": "BORALUS_PET", "to": "STRATHOLME_DUNGEON", "method": "portal"},
    {"from": "DALARAN_BROKEN_ISLES_PET", "to": "INSTANCE_WAILING_CAVERNS", "method": "portal"},
    {"from": "DAZARALOR_PET", "to": "INSTANCE_WAILING_CAVERNS", "method": "portal"},
    {"from": "BORALUS_PET", "to": "INSTANCE_WAILING_CAVERNS", "method": "portal"},
]

# Seconds an equip step takes, per item (see above). The rest of the equippable teleport items can be used at once
# (measured in game 2026-09-24: 40586, 65360, 63206, 63352, 65274, 63207, 63353, 103678, 63379, 63378, 46874,
# 144391, 144392, 142469), which is the default.
# Teleport items that are used up when used (`consumable = true`): routing spends one only when nothing else as
# quick will do (PlayerAbilities.lua's AbilityBias).
CONSUMABLES = {
    167075,     # Ultrasafe Transporter: Mechagon
    184500,     # Attendant's Pocket Portal: Bastion
    184501,     # Attendant's Pocket Portal: Revendreth
    184502,     # Attendant's Pocket Portal: Maldraxxus
    184503,     # Attendant's Pocket Portal: Ardenweald
    184504,     # Attendant's Pocket Portal: Oribos
    252607,     # Abundant Beacon
}

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
    "GNOMEREGAN_DUNGEON": (231, "Alliance"),        # underground in Dun Morogh (GNOMEREGAN_NODES)
    "GNOMEREGAN_DUNGEON_HORDE": (231, "Horde"),     # the teleporter at Grom'gol
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
    # The Vaults of Atal'Utek's Windcallers (by the old data's ids), by the place each stands at (a FLIGHT_ id would read
    # "Vaults of Atal'Utek Flight Master", all five alike). The Venomous Abyss has no area of its own in the Vaults:
    # the dungeon's is the nearest name.
    "AMANI_FOOTHOLD_FLIGHT_2": 17650,           # Amani Foothold
    "NORTHERN_AMANI_BULWARK_FLIGHT": 17729,     # Northern Amani Bulwark
    "EASTERN_AMANI_OUTPOST_FLIGHT": 17730,      # Eastern Amani Outpost
    "THE_UNDERBELLY_FLIGHT": 16990,             # The Underbelly (the Vaults')
    "THE_VENOMOUS_ABYSS_FLIGHT": 16915,         # The Venomous Abyss
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
    # Gnomeregan's entrance is underground, beside where the pet battle portals land (GNOMEREGAN_NODES).
    "GNOMEREGAN_DUNGEON": {"container": "ek_overworld.map30", "mapID": 30, "x": 0.3194, "y": 0.7170},
}

CONFIRMED_TAXI_IDS = {
    "SILVERMOON_CITY_BC_FLIGHT": "82",          # /mzdump nodes 110: "Silvermoon City" on old Eversong's map
    "FAIRBREEZE_VILLAGE_BC_FLIGHT": "625",      # old Fairbreeze Village
    "SILVERMOON_CITY_FLIGHT": "3131",           # Midnight's Silvermoon: Sanctum of Light (captured in game)
}

# Teleports the old data lacks (see the docstring). Midnight split the mage's Silvermoon teleport (checked in game
# 2026-09-24): 32272 is now "Teleport: Silvermoon (Burning Crusade)" and still lands in the old Silvermoon (the old
# data has it); 1259190 "Teleport: Silvermoon City" is new and lands in Midnight Silvermoon's portal room.
TELEPORTS = [
    {"spellID": 1259190, "to": "SILVERMOON_PORTAL_ROOM"},
]

# Vulpera: a successful Make Camp (312370) sets the camp; Return to Camp (312372) goes there: 10 s cast, a loading screen,
# 60 min cooldown (the user's figures, 2026-10-08; retail's SpellCooldowns table has no row for it).
CAMPS = [
    {"spellID": 312372, "setSpellID": 312370, "cooldown": 3600},
]

# Inns (tools/gen_modern_pois.py). Wowhead gives some innkeepers as a zone and a floor, not a map: the map each is
# (None: left out -- a duplicate of a row that does give a map, or a place the Modern data doesn't have).
INN_FLOORS = {
    (139, "0"): 23,         # Eastern Plaguelands (Light's Hope Chapel)
    (139, "20"): None,
    (4395, "1"): 125,       # Dalaran (Northrend)
    (4395, "2"): None,      # the Underbelly (map 126: no nodes)
    (6611, "0"): None, (6611, "1"): None, (6611, "2"): None,     # Dalaran (Northrend) again
    (7502, "10"): 627,      # Dalaran (Broken Isles)
    (7503, "0"): 650,       # Highmountain
    (7503, "31"): None,     # Thunder Totem (map 750: no nodes)
    (10565, "1"): 1670,     # Oribos
    # The Shrines (a city's name: the inn stands at the city's centre; a bind there is found by the city's name).
    (5840, "1"): "shrine_of_two_moons", (5840, "2"): "shrine_of_two_moons",
    (5840, "3"): "shrine_of_seven_stars", (5840, "0"): None,
    (6141, "1"): None, (6141, "2"): None, (6142, "3"): None,     # the same innkeepers again
    # Places the Modern data has no nodes for, or that aren't a hearthstone's: garrisons, the Vindicaar's decks,
    # covenant sanctums, scenarios.
    (6720, "0"): None, (6720, "1"): None, (6720, "2"): None, (6738, "4"): None,
    (8574, "0"): None, (8574, "1"): None, (8701, "0"): None, (8701, "3"): None,
    (8899, "0"): None, (8899, "5"): None, (8899, "6"): None,
    (12858, "1"): None, (14753, "1"): None,
    (4714, ""): None, (9598, ""): None, (1584, ""): None, (12876, ""): None, (11012, ""): None,
    (15177, ""): None, (15716, ""): None, (15921, ""): None,
}
# Maps a city shares with the zone around it (Pandaria's shrines are on the Vale's): an inn there is the city's only
# when it stands within CITY_RADIUS of the city's centre.
CITY_ZONE_MAPS = [390]
# NPC ids to leave out (listed as innkeepers, but not ones a player binds with), or (NPC id, map id) for one map only.
INN_DROP = [
    (123395, 882), (123395, 885),   # the Vindicaar's innkeeper: the ship is on all three Argus maps, Krokuun's stands for it
    186012, 186013,                 # Innkeeper Renee in present Tirisfal: Brill has no inn there now (past Tirisfal's is 5688)
]
# An inn on a map whose nodes are all on one side of a phase group or the other: which side, by NPC id.
INN_PHASE = {
    143442: "kalimdor_overworld.map62_art1176",    # Krekthi: Darkshore as it is now
    43420: "kalimdor_overworld.map62_art67",       # Innkeeper Kyteran (Lor'danel): Darkshore before the burning
    5688: "ek_overworld.map18_art19",              # Innkeeper Renee (Brill): past Tirisfal only
}
# Towns named by hand, by the lead innkeeper's NPC id: (key, area id), or None for an inn that is no town's (out in
# the world, or a camp too small to list). From the review of the inns the generator couldn't place (2026-10-06).
INN_TOWNS = {
    5688: ("brill", 159),                       # Innkeeper Renee (past Tirisfal)
    15174: ("cenarion_hold", 3425),             # Calandrath
    18907: ("cenarion_refuge", 3565),           # Innkeeper Coryth Stoktron (not Swamprat Post)
    21088: ("mok_nathal_village", 3844),        # Matron Varah
    23143: ("netherwing_ledge", 3759),          # Horus
    29904: ("k3", 4418),                        # Smilin' Slirk Brassknob
    30005: ("brunnhildar_village", 4422),       # Lodge-Matron Embla (not Dun Niffelem)
    41618: ("legion_s_fate", 5052),             # Erunak Stonespeaker
    43946: ("grol_dom_farm", 1704),             # Innkeeper Kerntis
    44006: ("swiftgear_station", 5304),         # Innkeeper Daughny
    44309: ("dreadmaul_hold", 1437),            # Innkeeper Grak
    44334: ("surwich", 5084),                   # Donna Berrymore
    45272: ("freewind_post", 484),              # Innkeeper Abeqwa
    45300: ("temple_of_earth", 5303),           # Caretaker Nuunwa
    49498: ("dragonmaw_port", 5136),            # Innkeeper Lutz
    49574: ("kirthaven", 5143),                 # Vaughn Blusterbeard
    49747: ("crushblow", 5471),                 # Innkeeper Krum
    49762: ("bloodgulch", 5138),                # Innkeeper Turk
    49783: ("the_krazzworks", 5137),            # Innkeeper Geno
    62869: ("crane_wing_refuge", 6049),         # Ni the Merciful
    67668: ("dawnseeker_promontory", 6584),     # Uda the Beast
    70182: ("violet_rise", 6583),               # Isirami Fairwind
    73622: ("the_celestial_court", 6830),       # Graceful Swan
    79758: ("telaari_station", 7081),           # Caregiver Felaani
    82110: ("admiral_taylor_s_garrison", 6999), # Alice Finn
    98945: ("temple_of_five_dawns", 7903),      # Lao Shu (the Legion Wandering Isle)
    129354: ("atul_aman", 8960),                # Rhan'ka
    133695: ("suramar_city", 8148),             # Maribeth (not the Nighthold)
    171015: ("dreamsong_fenn", 11519),          # Flitterbit
    187403: ("wingrest_embassy", 13939),        # Sil'nori Crestshade
    187412: ("wingrest_embassy", 13939),        # Happy Hal
    191025: ("ruby_life_pools", 13728),         # Lifecaller Tzadrak
    203293: ("loamm", 14520),                   # Floressa
    206947: ("bel_ameth", 15115),               # Willa Stronghinge: Bel'ameth's second inn
    210940: ("stormglen_village", 5714),        # Willa Arnes
    217167: ("gilneas_city", 5435),             # Gwen Armstead
    240404: ("the_den", 15921),                 # Yinaa
    249879: ("tranquillien", 16001),            # Innkeeper Areyn: Tranquillien's second inn
    # No town's.
    92001: None, 99207: None, 100746: None, 109304: None, 112864: None, 115002: None, 163252: None, 164722: None,
    168758: None, 175621: None, 59405: None, 65976: None, 84237: None, 85830: None, 86994: None,
}
# Inns that are a city's, though they stand on another map than the city's own (by NPC id: city key).
INN_CITIES = {
    62996: "shrine_of_two_moons",       # Madam Vee Luo, on the present Vale's map
    64149: "shrine_of_seven_stars",     # Matron Vi Vinh, the same
    137331: "dazaralor",                # Shado, on Zuldazar's map (the Great Seal)
}
# Where an innkeeper really stands, when Wowhead has it wrong: NPC id -> (map id, x, y), 0-100.
INN_PLACES = {
    46271: (18, 83.0, 71.8),            # Provisioner Elda: at the Bulwark (Wowhead puts her at 26.4, 59.2)
}
# The zones Cataclysm added to the old world (uiMap ids): a town in one is Cataclysm's, whatever its name.
CATACLYSM_ZONES = [174, 194, 198, 201, 203, 204, 205, 207, 217, 241, 244, 245, 249, 1527]
