"""tools/match_modern_area_nodes.py -- gives Modern nodes that have no name an area id, so the client names them in the
player's language (C_Map.GetAreaInfo, NodeNames.lua), the way Forever's nodes with an `area` are named.

    python tools/match_modern_area_nodes.py      # then python tools/gen_modern_nodes.py

Reads the old addon's English name of each node (the comment on its line in Data/Modern/Nodes_*.lua; the `area` this
script gave it last time doesn't count, so a re-run gives the same answer) and matches it
against retail's AreaTable (tools/modern_source/area_table_retail.csv, https://wago.tools/db2/AreaTable/csv), using
UiMap (tools/modern_source/uimap_retail.csv, https://wago.tools/db2/UiMap/csv) to know which zone the node is in, and
UiMapAssignment (tools/modern_source/uimap_assignment_retail.csv, https://wago.tools/db2/UiMapAssignment/csv) to know
which game map (continent) its map is on:

- Tried in order, most specific first: the place after " - " inside parentheses ("Un'Goro Crater (Kalimdor - Fire
  Plume Ridge)" -> Fire Plume Ridge), the parenthesised part ("Zaralek Cavern (Obsidian Rest)" -> Obsidian Rest), the
  part before the parentheses or a comma, then the whole name. A parenthesised part that is the node's own zone or
  continent ("Aerie Peak (Eastern Kingdoms)", "Ruby Dragonshrine (Dragonblight)") is a note, not the place: skipped.
- An area only counts if it lies in the node's zone (the area or one of its parent areas has the name of the node's map
  or one of that map's parents) and on the node's game map (Outland's Nagrand is not Draenor's). So a generic word can't
  pick an area on the other side of the world. Of several, the one sharing most names with the node's maps is taken.
  Failing that, a name that exactly one area on the node's game map has is taken too (verdict "continent"): the old
  data's map id is sometimes the zone next door.
- Generic labels ("Entrance", "Portal Room", "Pet Shop", ...) are never looked up: an area of that name would name the
  node wrongly even when it's in the right zone.

Writes tools/modern_source/area_node_matches.tsv (source id, Modern id, verdict one|many|continent|zero, area id, area name, the
name tried, old name), for review. gen_modern_nodes.py writes `area = <id>` for every "one", "many" and "continent" row ("many" takes
the first, as the other match files do); modern_manual.AREA_OVERRIDES corrects or adds any by hand.
"""
import csv
import pathlib
import re
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import modern_ids
import modern_manual as manual

ROOT = pathlib.Path(__file__).resolve().parent.parent
DATA = ROOT / "Data" / "Modern"
SOURCE = ROOT / "tools" / "modern_source"
OUT = SOURCE / "area_node_matches.tsv"

NAMED_BY_KIND = ("TAXI_", "FLIGHT_", "BORDER_", "DOCK_", "ZEPPELIN_", "TRAM_", "TELEPORT_", "PORTAL_", "INSTANCE_",
                 "CITY_", "TOWN_")
GENERIC = {"entrance", "exit", "dock", "harbour", "harbor", "embassy", "pet shop", "portal room", "entrance portal",
           "portal room lower", "portal room upper", "portal room stairs", "entrance to portal room",
           "dalaran pet shop", "the dark portal"}


def norm(text):
    return re.sub(r"[^a-z0-9 ]+", "", text.lower().replace("'", "")).strip()


def candidates(old_name, zone):
    names = []
    inside = re.search(r"\(([^)]*)\)", old_name)
    if inside:
        part = inside.group(1)
        if " - " in part:
            names.append(part.split(" - ", 1)[1])
        elif norm(part) not in zone:
            names.append(part)
    names.append(re.split(r" \(|, ", old_name)[0])
    names.append(old_name)
    out = []
    for name in names:
        if name and norm(name) not in GENERIC and name not in out:
            out.append(name)
    return out


def main():
    with open(SOURCE / "uimap_retail.csv", encoding="utf-8") as f:
        uimaps = {int(r["ID"]): (r["Name_lang"], int(r["ParentUiMapID"] or 0)) for r in csv.DictReader(f)}
    with open(SOURCE / "area_table_retail.csv", encoding="utf-8") as f:
        areas = {int(r["ID"]): (r["AreaName_lang"], int(r["ParentAreaID"] or 0)) for r in csv.DictReader(f)}
    with open(SOURCE / "area_table_retail.csv", encoding="utf-8") as f:
        continent_of = {int(r["ID"]): int(r["ContinentID"] or -1) for r in csv.DictReader(f)}
    game_maps = {}          # uiMapID -> { game map ids its regions are on }
    with open(SOURCE / "uimap_assignment_retail.csv", encoding="utf-8") as f:
        for r in csv.DictReader(f):
            game_maps.setdefault(int(r["UiMapID"]), set()).add(int(r["MapID"]))
    by_name = {}
    for area_id, (name, _parent) in areas.items():
        by_name.setdefault(norm(name), []).append(area_id)

    def map_chain(map_id):
        names, seen = set(), set()
        while map_id and map_id in uimaps and map_id not in seen:
            seen.add(map_id)
            names.add(norm(uimaps[map_id][0]))
            map_id = uimaps[map_id][1]
        return names

    def area_chain(area_id):
        names, seen = set(), set()
        while area_id and area_id in areas and area_id not in seen:
            seen.add(area_id)
            names.add(norm(areas[area_id][0]))
            area_id = areas[area_id][1]
        return names

    source_of = {new: source for source, new in modern_ids.load().items()}
    hand_areas = {n["id"] for n in manual.NODES if n.get("area")}
    rows = []
    for path in sorted(DATA.glob("Nodes_*.lua")):
        for line in path.read_text(encoding="utf-8").splitlines():
            m = re.search(r'id = "([^"]+)".*?mapID = (\d+).*?\}, -- (.*)$', line)
            if not m or m.group(1).startswith(NAMED_BY_KIND):
                continue
            node_id, map_id, old_name = m.group(1), int(m.group(2)), m.group(3)
            if source_of.get(node_id, node_id) in hand_areas or "journal = " in line:
                continue            # named already: by its own area in modern_manual.NODES, or by the journal
            old_name = re.sub(r" \(hand-added: .*\)$", "", old_name)
            zone = map_chain(map_id)
            on_maps = game_maps.get(map_id, set())
            verdict, found, tried = "zero", [], ""
            for name in candidates(old_name, zone):
                found = [a for a in by_name.get(norm(name), [])
                         if area_chain(a) & zone and (not on_maps or continent_of[a] in on_maps)]
                if found:
                    verdict, tried = ("one" if len(found) == 1 else "many"), name
                    break
            if not found:
                # Second, looser pass: the name alone, if exactly one area of it is on the node's game map
                # (the old data's map id is sometimes the zone next door, or the city's own map a level down).
                for name in candidates(old_name, zone):
                    loose = [a for a in by_name.get(norm(name), []) if on_maps and continent_of[a] in on_maps]
                    if len(loose) == 1:
                        verdict, found, tried = "continent", loose, name
                        break
            found.sort(key=lambda a: (-len(area_chain(a) & zone), a))
            area = found[0] if found else ""
            rows.append((source_of.get(node_id, node_id), node_id, verdict, ",".join(str(a) for a in found),
                         areas[area][0] if area else "", tried, old_name))

    lines = ["# GENERATED by tools/match_modern_area_nodes.py -- source id, Modern id, verdict, area id(s), area name, "
             "name tried, old name. See the script's docstring; correct by hand in modern_manual.AREA_OVERRIDES."]
    lines += ["\t".join(str(c) for c in row) for row in rows]
    OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    counts = {}
    for row in rows:
        counts[row[2]] = counts.get(row[2], 0) + 1
    print(f"{len(rows)} nameless nodes: " + ", ".join(f"{k} {v}" for k, v in sorted(counts.items())))


if __name__ == "__main__":
    main()
