"""The capitals with their own maps, and where their street work lives.

Workflow for one city (art comes from the local Forever install; it is Blizzard's, so art/ and editors/ stay out
of git):
    python tools/roads/city/mapart.py <name>        # art/<name>.png from the client's own map art tables
    python tools/roads/city/make_editor.py <name>   # editors/editor_<name>.html, seeded with <name>.json if any
    (draw the streets in the editor; Claude reads them from the page into <name>.json)
    python tools/roads/city/gen_city_paths.py       # Data/Forever/CityPaths.lua from every <name>.json
"""
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ART = os.path.join(HERE, "art")
EDITORS = os.path.join(HERE, "editors")

# name -> (uiMapID, title)
CITIES = {
    "stormwind": (1453, "Stormwind"),
    "ironforge": (1455, "Ironforge"),
    "darnassus": (1457, "Darnassus"),
    "orgrimmar": (1454, "Orgrimmar"),
    "thunder_bluff": (1456, "Thunder Bluff"),
    "undercity": (1458, "Undercity"),
}

ART_W, ART_H = 1002, 668        # a world map's art: its map runs 0-1 across this many pixels

# Containers on a city's map that its streets aren't for: Undercity's map shows the Ruins of Lordaeron above it, and
# the ruins' corridor to the lift tops runs over the underground's streets. Walks there stay straight.
SKIP_CONTAINERS = [
    "easternkingdoms.tirisfal_glades.undercity_ruins",
]
