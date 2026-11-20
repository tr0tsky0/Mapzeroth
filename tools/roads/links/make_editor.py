"""A road-link editor page for one zone: its minimap with today's roads (cyan, not editable) and the links drawn so
far (<name>.json, editable), using the city street editor's page.

    python tools/roads/links/make_editor.py <name>   # editors/editor_<name>.html

Mapzeroth's own places on the zone's map show as markers, placed through the client's UiMapAssignment.
"""
import base64
import glob
import io
import json
import os
import re
import struct
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROADS = os.path.dirname(HERE)
sys.path.insert(0, ROADS)
sys.path.insert(0, HERE)
from casc import Casc                         # noqa: E402
from adt import Wdt                           # noqa: E402
import wdc5                                   # noqa: E402
from zones import ZONES, EDITORS, world_to_px, lines_path, water_path, drop_path   # noqa: E402

REPO = os.path.dirname(os.path.dirname(ROADS))
TEMPLATE = os.path.join(ROADS, "city", "editor_template.html")
UI_MAP_ASSIGNMENT = 1957219                   # DBFilesClient/UiMapAssignment.db2: parent = uiMapID


def map_region(c, ui_map):
    """The world box a map's 0-1 covers: (minX, minY, maxX, maxY)."""
    for r in wdc5.read(c.read_fdid(UI_MAP_ASSIGNMENT)):
        if r["parent"] == ui_map:
            f = struct.unpack("<6f", r["vals"][2])
            return f[0], f[1], f[3], f[4]
    raise SystemExit("no UiMapAssignment for map %d" % ui_map)


def road_lines(instance):
    text = open(os.path.join(REPO, "Data", "Forever", "Roads.lua"), encoding="utf-8").read()
    m = re.search(r"\[%d\] = \{.*?\n(.*?)\n    \}," % instance, text, re.S)
    out = []
    for line in (m.group(1).splitlines() if m else []):
        v = [int(t) for t in re.findall(r"-?\d+", line)]
        out.append(list(zip(v[0::2], v[1::2])))
    return out


def base_lines(zone):
    """The zone's generated roads as the editor's fixed lines (pixels): points the roads share stay the same pixel."""
    return [[[round(v, 2) for v in world_to_px(zone, wx, wy)] for wx, wy in line]
            for line in road_lines(zone["instance"])]


def markers(zone, region):
    minX, minY, maxX, maxY = region
    pattern = re.compile(r'id = "([^"]+)".*?mapID = %d\b.*?x = ([\d.]+).*?y = ([\d.]+)' % zone["ui_map"])
    out = []
    for path in glob.glob(os.path.join(REPO, "Data", "Forever", "*.lua")):
        for line in open(path, encoding="utf-8"):
            m = pattern.search(line)
            if m:
                mx, my = float(m.group(2)), float(m.group(3))
                x, y = world_to_px(zone, maxX - my * (maxX - minX), maxY - mx * (maxY - minY))
                out.append({"id": m.group(1), "x": round(x, 1), "y": round(y, 1), "skip": False})
    return sorted(out, key=lambda m: m["id"])


def picture(c, zone):
    w = Wdt(c.read_fdid(zone["wdt"]))
    x0, y0, x1, y1 = zone["tiles"]
    p = zone["px"]
    img = Image.new("RGB", ((x1 - x0 + 1) * p, (y1 - y0 + 1) * p))
    for (x, y), e in w.maid.items():
        if x0 <= x <= x1 and y0 <= y <= y1:
            d = c.read_fdid(e[7])
            if d:
                img.paste(Image.open(io.BytesIO(d)).convert("RGB").resize((p, p)), ((x - x0) * p, (y - y0) * p))
    buf = io.BytesIO()
    img.save(buf, "PNG")
    return buf.getvalue()


def main(name):
    zone = ZONES[name]
    c = Casc()
    # --water: the same page for drawing big water's shores (each line round and back to its start), with no roads
    # under it to snap onto.
    water = "--water" in sys.argv
    # --drop: shapes drawn round roads the terrain gives wrongly (riverbanks painted like road); gen_roads drops every
    # stretch of road inside one. Today's roads are shown under it, to draw round.
    drop = "--drop" in sys.argv
    kind = "_water" if water else "_drop" if drop else ""
    path = water_path(name) if water else drop_path(name) if drop else lines_path(name)
    seed = open(path, encoding="utf-8").read() if os.path.exists(path) else "[]"
    html = open(TEMPLATE, encoding="utf-8").read()
    title = " water:" if water else " roads to remove (draw round them):" if drop else " road links:"
    html = (html.replace("__TITLE__", zone["title"] + title)
            .replace("__NAME__", name + kind if kind else "links-" + name)
            .replace("__SEED__", seed).replace("__MARKERS__", json.dumps(markers(zone, map_region(c, zone["ui_map"]))))
            .replace("__BASE__", "[]" if water else json.dumps(base_lines(zone)))
            .replace("__IMG__", "data:image/png;base64," + base64.b64encode(picture(c, zone)).decode("ascii")))
    os.makedirs(EDITORS, exist_ok=True)
    out = os.path.join(EDITORS, "editor_%s%s.html" % (name, kind))
    open(out, "w", encoding="utf-8").write(html)
    print(out, len(html) // 1024, "KB")


if __name__ == "__main__":
    main(sys.argv[1])
