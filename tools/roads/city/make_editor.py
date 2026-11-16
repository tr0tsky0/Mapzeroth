"""A street editor page for one city: its map art with its lines (<name>.json, if drawn yet) to edit.

    python tools/roads/city/make_editor.py <name>   # editors/editor_<name>.html (run mapart.py first)

The page keeps its lines in the browser (localStorage) and exposes them as MZR_LINES() for reading back.
"""
import base64
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from cities import CITIES, ART, EDITORS   # noqa: E402

name = sys.argv[1]
title = CITIES[name][1]
html = open(os.path.join(HERE, "editor_template.html"), encoding="utf-8").read()
art = os.path.join(ART, name + ".png")
data = "data:image/png;base64," + base64.b64encode(open(art, "rb").read()).decode("ascii")
seed_path = os.path.join(HERE, name + ".json")
seed = open(seed_path, encoding="utf-8").read() if os.path.exists(seed_path) else "[]"
html = (html.replace("__TITLE__", title).replace("__NAME__", name)
        .replace("__SEED__", seed).replace("__IMG__", data))
os.makedirs(EDITORS, exist_ok=True)
out = os.path.join(EDITORS, "editor_%s.html" % name)
open(out, "w", encoding="utf-8").write(html)
print(out, len(html) // 1024, "KB")
