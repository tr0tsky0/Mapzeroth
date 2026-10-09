"""Writes Data/Modern/HolidayRoutes.lua: the holiday routes the picker offers while their holiday is on (MultiRoute.lua),
from the lists in tools/holiday_source/<holiday>/*.txt.

A list file is lines of stops, in either of two shapes:
  - Wowhead's table, tab-separated: "<zone name>\\t<x>, <y>\\t<stop name>" (the zone by its English name);
  - TomTom's: "/way #<uiMapID> <x> <y> <stop name>".
Lines "Neutral (n)", "Alliance (n)", "Horde (n)" start whose stops follow (none: all neutral). A note in brackets at the
end of a stop's name ("(not for meta)") is dropped.

A zone name becomes the retail uiMapID of that name that Modern has nodes on (tools/modern_source/uimap_retail.csv), or
ZONE_MAPS's choice where the name means more than one map; one still ambiguous stops the run. Everything is written as
/way #map lines, so the client never has to read a zone name (its names are localized).

Run: python tools/gen_holiday_routes.py
"""
import csv
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCE = ROOT / "tools" / "holiday_source"
UIMAP = ROOT / "tools" / "modern_source" / "uimap_retail.csv"
OUT = ROOT / "Data" / "Modern" / "HolidayRoutes.lua"

# The routes, in the picker's order: (holiday key in addon.HOLIDAYS, name, source files, and for a file shared between
# routes, which of its zones go in this one).
HALLOWS = "hallows_end"
CATACLYSM_KALIMDOR = {"Mount Hyjal", "Uldum"}          # the rest of the Cataclysm list is Eastern Kingdoms (and Vashj'ir)
ROUTES = [
    (HALLOWS, "Tricks and Treats of Eastern Kingdoms", [("eastern_kingdoms", None), ("cataclysm", lambda z: z not in CATACLYSM_KALIMDOR)]),
    (HALLOWS, "Tricks and Treats of Kalimdor", [("kalimdor", None), ("cataclysm", lambda z: z in CATACLYSM_KALIMDOR)]),
    (HALLOWS, "Tricks and Treats of Outland", [("outland", None)]),
    (HALLOWS, "Tricks and Treats of Northrend", [("northrend", None)]),
    (HALLOWS, "Tricks and Treats of Pandaria", [("pandaria", None)]),
    (HALLOWS, "Tricks and Treats of the Dragon Isles", [("dragon_isles", None)]),
    (HALLOWS, "Tricks and Treats of Khaz Algar", [("khaz_algar", None)]),
]

# Zone names that are more than one map with nodes, or that Wowhead writes its own way.
ZONE_MAPS = {
    "Silvermoon City (Burning Crusade)": 110,
    "Eversong Woods (Burning Crusade)": 94,
    "The Situation in Dalaran": 125,          # Wowhead's name for Northrend's Dalaran
    "Uldum": 1527,                            # as the Cataclysm pet tamer route has it (Zidormi's other side is 249)
    "Vale of Eternal Blossoms": 390,          # the Vale as it was (Zidormi's other side is 1530)
    "Blasted Lands": 17,                      # Zidormi's other side is 1246
    "Tirisfal Glades": 18,                    # Zidormi's other side is 2070 (the Undercity bucket needs this side's city anyway)
    "Twilight Highlands": 241,
    "Orgrimmar": 85,                          # not the Cleft of Shadow (86)
    "Shadowmoon Valley": 104,                 # Outland's, not Draenor's (539)
    "Nagrand": 107,                           # Outland's, not Draenor's (550)
}
# Single stops on another map than their zone's: (zone, stop) -> uiMapID.
STOP_MAPS = {
    ("The Situation in Dalaran", "The Underbelly"): 126,     # Dalaran's sewers: placed through the map above them in game
}

FACTIONS = {"neutral": "neutral", "alliance": "alliance", "horde": "horde"}


def maps_with_nodes():
    found = {}
    for path in (ROOT / "Data" / "Modern").glob("*.lua"):
        for m in re.finditer(r"mapID = (\d+)", path.read_text(encoding="utf-8")):
            found[int(m.group(1))] = found.get(int(m.group(1)), 0) + 1
    return found


def maps_by_name():
    names = {}
    with UIMAP.open(encoding="utf-8") as f:
        for row in csv.DictReader(f):
            names.setdefault(row["Name_lang"].strip().lower(), []).append(int(row["ID"]))
    return names


def read_list(path, by_name, with_nodes, keep, problems):
    """{ faction: [ (mapID, x, y, name) ] } from one source file."""
    stops = {"neutral": [], "alliance": [], "horde": []}
    faction = "neutral"
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line:
            continue
        head = re.match(r"^(Neutral|Alliance|Horde)\s*\(\d+\)$", line, re.I)
        if head:
            faction = FACTIONS[head.group(1).lower()]
            continue
        way = re.match(r"^/way\s+#(\d+)\s+([\d.]+)[\s,]+([\d.]+)\s*(.*)$", line)
        if way:
            zone, map_id = None, int(way.group(1))
            x, y, name = float(way.group(2)), float(way.group(3)), way.group(4).strip()
        else:
            parts = raw.split("\t")
            if len(parts) != 3:
                problems.append(f"{path.name}: can't read: {raw!r}")
                continue
            zone = parts[0].strip()
            xy = re.match(r"^([\d.]+)[\s,]+([\d.]+)$", parts[1].strip())
            if not xy:
                problems.append(f"{path.name}: no coordinates in: {raw!r}")
                continue
            x, y, name = float(xy.group(1)), float(xy.group(2)), parts[2].strip()
            map_id = None
        name = re.sub(r"\s*\([^)]*\)\s*$", "", name)          # "(not part of meta achievement)"
        if keep and zone and not keep(zone):
            continue
        if map_id is None:
            map_id = STOP_MAPS.get((zone, name)) or ZONE_MAPS.get(zone)
            if map_id is None:
                candidates = [m for m in by_name.get(zone.lower(), []) if m in with_nodes]
                if len(candidates) != 1:
                    problems.append(f"{path.name}: zone {zone!r} is {candidates or 'no map with nodes'}: add it to ZONE_MAPS")
                    continue
                map_id = candidates[0]
        if map_id not in with_nodes and (zone, name) not in STOP_MAPS:
            problems.append(f"{path.name}: {name} is on map {map_id}, which has no nodes")
        stops[faction].append((map_id, x, y, name))
    return stops


def way_lines(stops):
    def num(v):
        return f"{v:.2f}".rstrip("0").rstrip(".")
    return "\n".join(f"/way #{m} {num(x)} {num(y)} {n}" for m, x, y, n in stops)


def main():
    by_name, with_nodes = maps_by_name(), maps_with_nodes()
    problems, out = [], []
    out += [
        "-- HolidayRoutes.lua (Modern) -- GENERATED by tools/gen_holiday_routes.py from tools/holiday_source/, do not hand-edit.",
        "-- The routes the picker offers while their holiday is on (MultiRoute:HolidayRoutes): each has its stops for everyone",
        "-- (neutral) and for each faction, as /way lines naming their maps.",
        "",
        "local addonName, addon = ...",
        'if addon.RULESET ~= "modern" then return end   -- one addon for both games: this data is Modern\'s (Constants.lua)',
        "",
        "addon.HolidayRoutes = {",
    ]
    for holiday, name, sources in ROUTES:
        merged = {"neutral": [], "alliance": [], "horde": []}
        for stem, keep in sources:
            got = read_list(SOURCE / holiday / f"{stem}.txt", by_name, with_nodes, keep, problems)
            for faction in merged:
                merged[faction] += got[faction]
        out.append(f'    {{ name = "{name}", holiday = "{holiday}",')
        for faction in ("neutral", "alliance", "horde"):
            if merged[faction]:
                out.append(f"      {faction} = [[\n{way_lines(merged[faction])}\n]],")
        out.append("    },")
        print(f"{name}: {len(merged['neutral'])} neutral, {len(merged['alliance'])} Alliance, {len(merged['horde'])} Horde")
    out.append("}")
    if problems:
        raise SystemExit("not written:\n  " + "\n  ".join(problems))
    OUT.write_text("\n".join(out) + "\n", encoding="utf-8")
    print(f"wrote {OUT}")


if __name__ == "__main__":
    main()
