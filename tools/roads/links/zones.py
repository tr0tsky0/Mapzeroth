"""Hand-drawn road links for zones whose terrain roads miss a way (a bridge or path that is a model, not painted).

Workflow for one zone (the background is the client's own minimap, so art/ and editors/ stay out of git):
    python tools/roads/links/make_editor.py <name>   # editors/editor_<name>.html: the minimap with today's roads
    (draw the missing links in the editor; Claude reads them from the page into <name>.json)
    python tools/roads/gen_roads.py                  # Roads.lua, with each <name>.json joined to its continent's roads

Lines are pixels on the editor's picture: the zone's minimap tiles from `tiles` (x0, y0, x1, y1, inclusive) at `px`
pixels a tile. gen_roads turns them into world yards and snaps each line's ends onto the nearest road (SNAP_YD).
"""
import os

HERE = os.path.dirname(os.path.abspath(__file__))
EDITORS = os.path.join(HERE, "editors")
TILE = 533.3333333

# name -> zone
ZONES = {
    "zephras": {"title": "Zephras Isle", "wdt": 7198644, "instance": 2991, "ui_map": 2521,
                "tiles": (25, 22, 33, 29), "px": 192},
}

SNAP_YD = 25            # a drawn line's end this near a road joins it there


def px_to_world(zone, x, y):
    """Editor pixel -> world (X north, Y west), as Roads.lua has them."""
    tx0, ty0 = zone["tiles"][:2]
    p = zone["px"]
    return 32 * TILE - (ty0 + y / p) * TILE, 32 * TILE - (tx0 + x / p) * TILE


def world_to_px(zone, wx, wy):
    tx0, ty0 = zone["tiles"][:2]
    p = zone["px"]
    return ((32 * TILE - wy) / TILE - tx0) * p, ((32 * TILE - wx) / TILE - ty0) * p


def lines_path(name):
    return os.path.join(HERE, name + ".json")


# Big water a walk swims rather than runs across (RoadNet.WATER, RoadNet.SWIM): each line in <name>_water.json is a
# shore drawn round, closed back to its start (make_editor.py <name> --water).
def water_path(name):
    return os.path.join(HERE, name + "_water.json")
