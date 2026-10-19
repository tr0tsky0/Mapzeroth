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
    (HALLOWS, "Tricks and Treats of Midnight", [("midnight", None)]),
]

# Zone names that are more than one map with nodes, or that Wowhead writes its own way.
ZONE_MAPS = {
    "Silvermoon City (Burning Crusade)": 110,
    "Eversong Woods (Burning Crusade)": 94,
    "The Situation in Dalaran": 125,          # Wowhead's name for Northrend's Dalaran
    "Uldum": 249,                             # past Uldum: the buckets are only there (seen 2026-10-19); present is 1527
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

# Maps without nodes that a /way stop may name anyway: the client carries the position up to a map that has some
# (addon:PlaceAt).
CARRIED_MAPS = {
    2444,                                     # Slayer's Rise (Midnight)
}

FACTIONS = {"neutral": "neutral", "alliance": "alliance", "horde": "horde"}

# A holiday's quest per stop: tools/holiday_source/<holiday>/criteria.tsv ("questID\tZone, Place", from /mzr buckets),
# matched by place name. A stop no criterion names gets no quest and always stays in the route.
# Stops our lists name differently from the criteria: stop -> the criterion's place.
QUEST_ALIASES = {
    "Silvermoon City Inn": "The Royal Exchange",     # TBC Silvermoon: both turned in 2026-10-19 (12369, 12370)
    "Wayfarer's Rest": "The Bazaar",
    "The Exodar": "Seat of the Naaru",
    "Thunder Bluff": "Lower Rise",
    "Nordrassil Inn": "Nordrassil",
    "Northwatch Expedition Base Camp": "Northwatch Expedition Base",
}
# A stop's quest set by route, ahead of the name match: (route, stop) -> questID (0: none known). For a route whose stop
# names another route's buckets already have: Midnight's Eversong reuses the TBC names (Fairbreeze Village,
# Tranquillien), so its quests (achievement 63400, /mzr buckets 63400, 2026-10-19) are here, not in criteria.tsv.
# A key with a faction third is that side's bucket: a criterion that is "either side's quest" shows in /mzr buckets as
# criteriaID 0 with no quest (Slayer's Rise, Wild Coast), so those quests are as the user read them (2026-10-19).
MIDNIGHT = "Tricks and Treats of Midnight"
STOP_QUESTS = {
    (MIDNIGHT, "Arcantina"): 97213,
    (MIDNIGHT, "Fairbreeze Village"): 97143,
    (MIDNIGHT, "Silvermoon"): 97142,
    (MIDNIGHT, "Tranquillien"): 97148,
    (MIDNIGHT, "Har'alnor"): 97207,
    (MIDNIGHT, "Har'athir"): 97155,
    (MIDNIGHT, "Har'kuai"): 97154,
    (MIDNIGHT, "Har'mara"): 97208,
    (MIDNIGHT, "The Den"): 97206,
    (MIDNIGHT, "Locus Point"): 97209,
    (MIDNIGHT, "Slayer's Rise", "alliance"): 97211,
    (MIDNIGHT, "Slayer's Rise", "horde"): 97212,
    (MIDNIGHT, "The Ingress"): 97210,
    (MIDNIGHT, "Amani'Zar"): 97150,
    (MIDNIGHT, "Camp Stonewash"): 97151,
    (MIDNIGHT, "Witherbark Bluffs"): 97152,
    ("Tricks and Treats of the Dragon Isles", "Wild Coast", "alliance"): 75681,
    ("Tricks and Treats of the Dragon Isles", "Wild Coast", "horde"): 75682,
    # Deepholm's one bucket (the Chamber of Respite, Temple of Earth), a quest per side (achievements 5837 / 5838);
    # the Alliance one turned in there 2026-10-19, the Horde one taken to be the same bucket.
    ("Tricks and Treats of Eastern Kingdoms", "Temple of Earth", "alliance"): 29020,
    ("Tricks and Treats of Eastern Kingdoms", "Temple of Earth", "horde"): 29019,
}
# Stops only a reputation's side can use (Shattrath and Shadowmoon Valley: one quest, a bucket per side): stop -> factionID.
# The picker leaves such a stop out while that faction is below Neutral.
STOP_REPS = {"Aldor Rise": 932, "Altar of Sha'tar": 932, "Scryers Tier": 934, "Sanctum of the Stars": 934}
REPORT = ROOT / "tools" / "holiday_report.txt"


def key(name):
    """A place name compared loosely: no case, curly quotes, punctuation or leading "The"."""
    name = name.lower().replace("’", "'")
    name = re.sub(r"^the\s+", "", name)
    return re.sub(r"[^a-z0-9]", "", name)


def read_quests(path):
    """{ place key: [questID] } from a criteria file; "A or B" names both places."""
    quests = {}
    if not path.exists():
        return quests
    for raw in path.read_text(encoding="utf-8").splitlines():
        if not raw.strip() or raw.startswith("#"):
            continue
        quest, name = raw.split("\t")
        place = name.split(", ", 1)[1] if ", " in name else name.split(" - ", 1)[-1]
        inner = re.search(r"\(([^)]*)\)\s*$", place)          # "Valdrakken (The Parting Glass)"
        if inner:
            place = inner.group(1)
        for one in place.split(" or "):
            quests.setdefault(key(one), []).append(int(quest))
    return quests


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
        if map_id not in with_nodes and (zone, name) not in STOP_MAPS and map_id not in CARRIED_MAPS:
            problems.append(f"{path.name}: {name} is on map {map_id}, which has no nodes")
        stops[faction].append((map_id, x, y, name))
    return stops


def way_lines(stops):
    def num(v):
        return f"{v:.2f}".rstrip("0").rstrip(".")
    return "\n".join(f"/way #{m} {num(x)} {num(y)} {n}" for m, x, y, n in stops)


def main():
    by_name, with_nodes = maps_by_name(), maps_with_nodes()
    problems, out, report, used = [], [], [], {}
    quest_files = {}
    out += [
        "-- HolidayRoutes.lua (Modern) -- GENERATED by tools/gen_holiday_routes.py from tools/holiday_source/, do not hand-edit.",
        "-- The routes the picker offers while their holiday is on (MultiRoute:HolidayRoutes): each has its stops for everyone",
        "-- (neutral) and for each faction, as /way lines naming their maps. quests: each stop's quest, line for line (0: none",
        "-- known); reps: [line] = the factionID a stop needs to be at least Neutral with.",
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
        if holiday not in quest_files:
            quest_files[holiday] = read_quests(SOURCE / holiday / "criteria.tsv")
        known = quest_files[holiday]
        out.append(f'    {{ name = "{name}", holiday = "{holiday}",')
        quests, reps = [], []
        for faction in ("neutral", "alliance", "horde"):
            if not merged[faction]:
                continue
            out.append(f"      {faction} = [[\n{way_lines(merged[faction])}\n]],")
            ids, needs = [], []
            for i, (m, x, y, stop) in enumerate(merged[faction], 1):
                pinned = (name, stop, faction) if (name, stop, faction) in STOP_QUESTS else (name, stop)
                if pinned in STOP_QUESTS:
                    hits = [STOP_QUESTS[pinned]] if STOP_QUESTS[pinned] else []
                else:
                    hits = known.get(key(QUEST_ALIASES.get(stop, stop)), [])
                if len(hits) > 1:
                    problems.append(f"{name}: {stop} names more than one quest: {hits}: add it to QUEST_ALIASES")
                if not hits:
                    report.append(f"no quest: {name} / {faction} / {stop} (#{m} {x} {y})")
                ids.append(hits[0] if hits else 0)
                if hits:
                    used[hits[0]] = True
                rep = STOP_REPS.get(stop.replace("’", "'"))
                if rep:
                    needs.append(f"[{i}] = {rep}")
            quests.append(f"{faction} = {{ {', '.join(str(q) for q in ids)} }}")
            if needs:
                reps.append(f"{faction} = {{ {', '.join(needs)} }}")
        out.append(f"      quests = {{ {', '.join(quests)} }},")
        if reps:
            out.append(f"      reps = {{ {', '.join(reps)} }},")
        out.append("    },")
        print(f"{name}: {len(merged['neutral'])} neutral, {len(merged['alliance'])} Alliance, {len(merged['horde'])} Horde")
    out.append("}")
    if problems:
        raise SystemExit("not written:\n  " + "\n  ".join(problems))
    for holiday, known in quest_files.items():
        for place, ids in sorted(known.items()):
            for q in ids:
                if q not in used:
                    report.append(f"quest no stop has: {holiday} {q} ({place})")
    OUT.write_text("\n".join(out) + "\n", encoding="utf-8")
    REPORT.write_text("# gen_holiday_routes.py: stops without a quest, and quests no stop has.\n" + "\n".join(report) + "\n",
                      encoding="utf-8")
    print(f"wrote {OUT} ({len(report)} report lines in {REPORT.name})")


if __name__ == "__main__":
    main()
