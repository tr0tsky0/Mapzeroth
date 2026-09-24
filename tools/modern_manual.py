"""Hand additions to the Modern data that the old addon's data doesn't have, read by
tools/gen_modern_nodes.py and tools/gen_modern_edges.py so a regeneration keeps them
(Data/Modern/*.lua is generated: hand edits there are lost on the next run).

NODES    places the old data lacks, usually captured in game with /mzdump here. Each is
         { "id", "out" (which Nodes_*.lua it goes in), "container", "mapID", "x", "y",
         optional "area" (the client's area id: gives the node a localized name), "note" }.
INDOOR   containers the old data didn't flag `interior` but are: no flying to or from them.
EDGES    connections the old data lacks: { "from", "to", "method", optional "cost", optional "oneway" }.
         Leave `cost` out for a walk and the engine works it out from distance and the default path
         factor, like any other walk.
"""

NODES = [
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
]

# The Lycaneum's own map: its portal room is an interior reached on foot from the entrance above,
# not a point you can fly to.
INDOOR = ["ek_overworld.map2649"]

EDGES = [
    # Running from the entrance to the portal inside, and back out: an explicit edge, since an interior
    # never auto-connects to the outdoors, but costed like any walk (distance and the default path factor).
    {"from": "LYCANEUM_ENTRANCE", "to": "MAGISTERS_SILVERMOON_PORTAL", "method": "walk"},
    {"from": "MAGISTERS_SILVERMOON_PORTAL", "to": "LYCANEUM_ENTRANCE", "method": "walk"},
]
