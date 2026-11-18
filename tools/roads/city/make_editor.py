"""A street editor page for one city: its map art with its lines (<name>.json, if drawn yet) to edit.

    python tools/roads/city/make_editor.py <name>   # editors/editor_<name>.html (run mapart.py first)

The page keeps its lines in the browser (localStorage) and exposes them as MZR_LINES() for reading back. It also
shows Mapzeroth's own places on that map (entrances, lifts, trainers...) as markers, for reference.
"""
import base64
import glob
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from cities import CITIES, ART, EDITORS, ART_W, ART_H, SKIP_CONTAINERS   # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))


def markers(ui_map):
    """Mapzeroth's own nodes on this map, as art pixels."""
    pattern = re.compile(r'id = "([^"]+)".*?mapID = %d\b.*?x = ([\d.]+).*?y = ([\d.]+)' % ui_map)
    out = []
    for path in glob.glob(os.path.join(REPO, "Data", "Forever", "*.lua")):
        for line in open(path, encoding="utf-8"):
            m = pattern.search(line)
            if m:
                container = re.search(r'container = "([^"]+)"', line)
                out.append({"id": m.group(1), "x": round(float(m.group(2)) * ART_W, 1),
                            "y": round(float(m.group(3)) * ART_H, 1),
                            # Not for the streets (Undercity's ruins): shown grey, never checked.
                            "skip": bool(container and container.group(1) in SKIP_CONTAINERS)})
    return sorted(out, key=lambda m: m["id"])


name = sys.argv[1]
ui_map, title = CITIES[name]
html = open(os.path.join(HERE, "editor_template.html"), encoding="utf-8").read()
art = os.path.join(ART, name + ".png")
data = "data:image/png;base64," + base64.b64encode(open(art, "rb").read()).decode("ascii")
seed_path = os.path.join(HERE, name + ".json")
seed = open(seed_path, encoding="utf-8").read() if os.path.exists(seed_path) else "[]"
html = (html.replace("__TITLE__", title).replace("__NAME__", name)
        .replace("__SEED__", seed).replace("__MARKERS__", json.dumps(markers(ui_map))).replace("__BASE__", "[]")
        .replace("__IMG__", data))
os.makedirs(EDITORS, exist_ok=True)
out = os.path.join(EDITORS, "editor_%s.html" % name)
open(out, "w", encoding="utf-8").write(html)
print(out, len(html) // 1024, "KB")
