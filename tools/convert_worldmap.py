"""Converts Wowhead's world-map pixel positions (tools/poi_source/worldmap_pois.tsv) to
game map coordinates: which map each point is on, and its 0-100 x, y there.

The pixel space is an axis-aligned scale and shift of our continent-normalized frame; the
constants in tools/worldmap_fit.json were fitted on 45 innkeepers whose positions we know
from both sources (mean error under 0.01% of the continent map).

    python tools/convert_worldmap.py [category ...]     # default: dungeon raid
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
GRIDS = json.load(open(ROOT / "tools" / "grids.json"))
FIT = json.load(open(ROOT / "tools" / "worldmap_fit.json"))
EK_CANVAS_X = 32768          # Wowhead's Eastern Kingdoms starts here on its canvas


def convert(px, py):
    cont = "1415" if px >= EK_CANVAS_X else "1414"
    ax, ay = FIT[cont]
    cx, cy = ax[0] * px + ax[1] * py + ax[2], ay[0] * px + ay[1] * py + ay[2]
    g = GRIDS[cont]
    n = g["n"]
    col, row = min(max(int(cx * n), 0), n - 1), min(max(int(cy * n), 0), n - 1)
    map_id = g["rows"][row][col]
    info = g["maps"].get(str(map_id))
    if not info or not info.get("rect") or str(map_id) == cont:
        return cont, None, cx, cy, None, None
    l, r, t, b = info["rect"]
    return cont, map_id, cx, cy, (cx - l) / (r - l) * 100, (cy - t) / (b - t) * 100, info["name"]


def slug(name):
    return re.sub(r"[^a-z0-9]+", "_", name.lower().replace("'", "")).strip("_")


def write_instances():
    """Writes tools/poi_source/instances.tsv: key, category, mapID, x, y, English name, area id
    (blank until checked in game), Wowhead's level tag. Keeps any area ids already filled in."""
    path = ROOT / "tools/poi_source/instances.tsv"
    known_areas, known_containers = {}, {}
    if path.exists():
        for line in path.read_text(encoding="utf-8").splitlines():
            cols = line.split("\t")
            if not line.startswith("#") and len(cols) > 6 and cols[6]:
                known_areas[cols[0]] = cols[6]
            if not line.startswith("#") and len(cols) > 8 and cols[8]:
                known_containers[cols[0]] = cols[8]
    rows = ["# key, category, mapID, x, y (0-100), English name (dev only), areaID, Wowhead level tag",
            "# Positions are Wowhead's map markers converted by tools/convert_worldmap.py: good to a few",
            "# hundred yards. Fill in the area id once `/mzdump areas <id>` shows the client's name for it."]
    for line in (ROOT / "tools/poi_source/worldmap_pois.tsv").read_text(encoding="utf-8").splitlines():
        if line.startswith("#") or not line.strip():
            continue
        cat, name, x, y, side, level = line.split("\t")
        if cat not in ("dungeon", "raid"):
            continue
        cont, map_id, cx, cy, *rest = convert(float(x), float(y))
        if map_id is None:
            continue
        key = slug(name)
        rows.append("\t".join([key, cat, str(map_id), f"{rest[0]:.1f}", f"{rest[1]:.1f}", name,
                               known_areas.get(key, ""), level, known_containers.get(key, "")]).rstrip("\t"))
    path.write_text("\n".join(rows) + "\n", encoding="utf-8")
    print("wrote", len(rows) - 3, "instances to", path)


def write_npcs():
    """Converts tools/poi_source/worldmap_npcs.tsv into battlemasters.tsv and stable_masters.tsv,
    in the same columns as the other NPC files: id, name, tag, mapID, map name, "x,y"."""
    files = {"battlemaster": "battlemasters.tsv", "stable": "stable_masters.tsv",
             "class": "class_trainers_worldmap.tsv"}
    rows = {c: [] for c in files}
    skipped = 0
    for line in (ROOT / "tools/poi_source/worldmap_npcs.tsv").read_text(encoding="utf-8").splitlines():
        if line.startswith("#") or not line.strip():
            continue
        cat, npc, name, x, y, side = line.split("\t")
        cont, map_id, cx, cy, *rest = convert(float(x), float(y))
        if map_id is None:
            skipped += 1
            continue
        tag = cat
        if cat.startswith("class-"):
            tag, cat = cat[len("class-"):].title() + " Trainer", "class"
        rows[cat].append("\t".join([npc, name, tag, str(map_id), rest[2], f"{rest[0]:.1f},{rest[1]:.1f}"]))
    for cat, name in files.items():
        (ROOT / "tools/poi_source" / name).write_text("\n".join(rows[cat]) + "\n", encoding="utf-8")
        print("wrote", len(rows[cat]), name)
    print("skipped (not inside a zone map):", skipped)


def main():
    if "--write-npcs" in sys.argv:
        write_npcs()
        return
    if "--write-instances" in sys.argv:
        write_instances()
        return
    wanted = set(sys.argv[1:]) or {"dungeon", "raid"}
    for line in (ROOT / "tools/poi_source/worldmap_pois.tsv").read_text(encoding="utf-8").splitlines():
        if line.startswith("#") or not line.strip():
            continue
        cat, name, x, y, side, level = line.split("\t")
        if cat not in wanted:
            continue
        cont, map_id, cx, cy, *rest = convert(float(x), float(y))
        if map_id is None:
            print(f"{cat:8s} {name:28s} continent {cont} ({cx:.4f}, {cy:.4f})  -- not inside any zone map")
        else:
            zx, zy, zname = rest
            print(f"{cat:8s} {name:28s} {zname} (map {map_id})  {zx:5.1f}, {zy:5.1f}   level tag {level}")


if __name__ == "__main__":
    main()
