"""tools/match_modern_taxi_nodes.py -- matches the old addon's *_FLIGHT nodes against the
real retail TaxiNodes table (tools/modern_source/taxi_nodes_retail.csv, pulled from
https://wago.tools/db2/TaxiNodes/csv) by name, so they can be renamed to TAXI_<realID> and
get a free, properly-localized name from the client (C_TaxiMap) at runtime -- the same way
Forever's own flight masters already work. This is an exploration/report pass: it doesn't
write any renamed data itself, just tools/modern_source/flight_node_matches.tsv for review
(one line per old node: its id, the match verdict, and the real taxi ID(s) if any), which
tools/gen_modern_nodes.py then reads for the ids marked with a single confident match.

    python tools/match_modern_taxi_nodes.py

Nodes whose id carries _FLIGHT anywhere are matched (EVERLOOK_FLIGHT_HORDE as well as IRONFORGE_FLIGHT). By name
first; an id that says its faction (`..._ALLIANCE` / `..._HORDE`) keeps only the rows of that faction (the TaxiNodes
Flags bit: 1 Alliance, 2 Horde). What the name leaves open (no match, or several) is settled by in-game captures:
`/mzdump nodes <mapID>` (MapzerothDataTools) lists every flight master the client has under a map with its real id and
map position; paste the output into tools/modern_source/taxi_captures/<name>_<mapID>.txt. The node takes the captured flight
master at its map position (same map, within CAPTURE_RADIUS), of its faction; a faction twin of the same name that the
capture didn't list (one hidden behind a condition) is found through the name. And of several candidates, the one a
capture puts on the node's own continent is taken when it is the only one (a captured flight master is on the
continent of the map it was reported on: the Eastern Kingdoms dump lists Midnight's Quel'Thalas ones on Quel'Thalas).
"""
import csv
import math
import pathlib
import re
from lupa.lua51 import LuaRuntime

ROOT = pathlib.Path(__file__).resolve().parent.parent
CAPTURES = ROOT / "tools" / "modern_source" / "taxi_captures"
CAPTURE_RADIUS = 0.06       # map units: the old data's positions are rough (Everlook is 0.045 off)
FACTION_BITS = {"ALLIANCE": 1, "HORDE": 2}
SRC = pathlib.Path(r"C:\Users\shaun\Documents\Claude\Mapzeroth\Mapzeroth\Data")
TAXI_CSV = ROOT / "tools" / "modern_source" / "taxi_nodes_retail.csv"
OUT = ROOT / "tools" / "modern_source" / "flight_node_matches.tsv"

FILES = [
    "Mapzeroth_Data_Nodes_EK.lua", "Mapzeroth_Data_Nodes_Kalimdor.lua",
    "Mapzeroth_Data_Nodes_Outlands.lua", "Mapzeroth_Data_Nodes_Northrend.lua",
    "Mapzeroth_Data_Nodes_Pandaria.lua", "Mapzeroth_Data_Nodes_BrokenIsles.lua",
    "Mapzeroth_Data_Nodes_Draenor.lua", "Mapzeroth_Data_Nodes_DragonIsles.lua",
    "Mapzeroth_Data_Nodes_KhazAlgar.lua", "Mapzeroth_Data_Nodes_Shadowlands.lua",
    "Mapzeroth_Data_Nodes_Zandalar.lua", "Mapzeroth_Data_Nodes_Argus.lua",
    "Mapzeroth_Data_Nodes_BfA.lua", "Mapzeroth_Data_Nodes_IsolatedMaps.lua",
]

# Words the old data appends to a place's bare name that the client's own taxi-node name
# never carries (it's just the place, comma-zone -- see NodeNames.lua's own "flight masters
# read as a destination, not a zone label" note for Forever's equivalent).
TRAILING_NOISE = re.compile(
    r"\s+(Flightmaster|Flight Master|Windcaller|Wind Rider Master|Wingrider Roost|Sky Admiral)$",
    re.IGNORECASE,
)


def norm(name):
    name = TRAILING_NOISE.sub("", name.strip())
    name = re.sub(r"\s*\([^)]*\)\s*$", "", name)   # trailing "(Draenor)"/"(Antoran Wastes)" annotation
    return name.split(",")[0].strip().lower()


def id_derived_name(node_id):
    """IRONFORGE_FLIGHT -> "ironforge": a fallback for old names that are just the generic
    word "Flightmaster" (every faction capital's own flight master, it turns out)."""
    return node_id.split("_FLIGHT")[0].replace("_", " ").lower()


def faction_of(node_id):
    """The TaxiNodes Flags bit an id's trailing ALLIANCE / HORDE asks for, or None."""
    for word, bit in FACTION_BITS.items():
        if re.search(rf"_{word}(_|$)", node_id):
            return bit
    return None


def load_captures(continent_of):
    """[(taxi id, mapID, x, y)] from every pasted /mzdump nodes output, and { continent uiMapID: {taxi ids} } by the
    continent of the map each was reported on."""
    found, by_continent = [], {}
    for path in sorted(CAPTURES.glob("*.txt")) if CAPTURES.exists() else []:
        for line in path.read_text(encoding="utf-8").splitlines():
            m = re.search(r'id = "TAXI_(\d+)".*?mapID = (\d+), x = (-?[\d.]+), y = (-?[\d.]+)', line)
            if m:
                found.append((m.group(1), int(m.group(2)), float(m.group(3)), float(m.group(4))))
                by_continent.setdefault(continent_of(int(m.group(2))), set()).add(m.group(1))
    return found, by_continent


def continent_finder():
    """uiMapID -> its continent's uiMapID (UiMap type 2), from tools/modern_source/uimap_retail.csv."""
    with open(ROOT / "tools" / "modern_source" / "uimap_retail.csv", encoding="utf-8") as f:
        maps = {int(r["ID"]): (int(r["ParentUiMapID"] or 0), int(r["Type"])) for r in csv.DictReader(f)}

    def find(map_id):
        seen = set()
        while map_id in maps and map_id not in seen:
            seen.add(map_id)
            if maps[map_id][1] == 2:
                return map_id
            map_id = maps[map_id][0]
        return None
    return find


# A handful of old names the general rules above can't reconstruct the real name from --
# checked by hand against the live client (garrison-era faction variants mostly, where the
# real taxi name carries a "(Alliance)"/"(Horde)" tag or a zone the old name drops). Tried
# before falling back to "zero"; see CONVERSION_NOTES.md-style writeup in the module
# docstring history for why each one needed this instead of a general rule.
MANUAL_FIXES = {
    "AMANIZAR_FLIGHT": "amani'zar village",
    "ELODOR_ALLIANCE_FLIGHT": "elodor (alliance)",
    "FORT_WRYNN_ALLIANCE_FLIGHT": "fort wrynn (alliance)",
    "LUNARFALL_ALLIANCE_FLIGHT": "lunarfall (alliance)",
    # A real, live taxi node (confirmed: "Lunarfall (Alliance)", real id 1476, sits almost
    # exactly where a "Taxi from Iron Docks to Garrison" quest path lands -- it just carries
    # the "(Alliance)" tag instead of the word "Garrison" the way Frostwall's entry does).
    # Old capture split across the WoD-era map id and the current one for what's very
    # likely the same real spot; this old id tries the same real name on purpose, so if it
    # is the same spot the rename collision check catches it and leaves this one under its
    # old id rather than double-claiming TAXI_1476.
    "LUNARFALL_GARRISON_FLIGHT": "lunarfall (alliance)",
    "STORMSHIELD_ALLIANCE_FLIGHT": "stormshield (alliance)",
    "VINDICAAR_ANTORAN_WASTES_FLIGHT": "vindicaar, antoran wastes",
    "VINDICAAR_EREDATH_FLIGHT": "vindicaar, eredath",
    "VINDICAAR_KROKUUN_FLIGHT": "vindicaar, krokuun",
}

# Not a taxi at all -- a separate, in-zone flight network (confirmed by hand), so there's
# no real TaxiNodes row to find no matter how the name is normalized. Reported as "skip",
# not "zero", so a future re-run doesn't keep re-flagging it as a mystery.
NOT_REAL_TAXI = {
    "EASTERN_AMANI_OUTPOST_FLIGHT": "Vaults of Atal'Utek's own flight network, not the real taxi system",
    "NORTHERN_AMANI_BULWARK_FLIGHT": "Vaults of Atal'Utek's own flight network, not the real taxi system",
    "THE_UNDERBELLY_FLIGHT": "Vaults of Atal'Utek's own flight network, not the real taxi system",
    "THE_VENOMOUS_ABYSS_FLIGHT": "Vaults of Atal'Utek's own flight network, not the real taxi system",
}


def main():
    taxi_by_base = {}
    flags_of, name_of = {}, {}
    continent_of = continent_finder()
    captures, captured_on = load_captures(continent_of)
    taxi_by_full = {}      # full name, comma and all -- for a MANUAL_FIXES value that keeps
                            # the zone qualifier on purpose to pick one of several same-base-name rows
    placed_by_base = {}    # same as taxi_by_base, but rows sitting at world (0,0,0) -- unplaced/dead data -- left out
    with open(TAXI_CSV, encoding="utf-8-sig", newline="") as f:
        for row in csv.DictReader(f):
            key = norm(row["Name_lang"])
            taxi_by_base.setdefault(key, []).append(row["ID"])
            flags_of[row["ID"]] = int(row["Flags"] or 0)
            name_of[row["ID"]] = row["Name_lang"].strip().lower()
            taxi_by_full.setdefault(row["Name_lang"].strip().lower(), []).append(row["ID"])
            if (row["Pos_0"], row["Pos_1"], row["Pos_2"]) != ("0", "0", "0"):
                placed_by_base.setdefault(key, []).append(row["ID"])

    lua = LuaRuntime(unpack_returned_tuples=True)
    loadstring = lua.eval("loadstring")

    rows = []
    counts = {"one": 0, "zero": 0, "many": 0}
    for filename in FILES:
        ns = lua.eval("{}")
        src = (SRC / filename).read_text(encoding="utf-8-sig")
        chunk = loadstring(src, "@" + filename)
        if isinstance(chunk, tuple):
            raise SystemExit(f"syntax error in {filename}: {chunk[1]}")
        chunk("Mapzeroth", ns)
        for group_name, group in ns.Nodes.items():
            for node_id, node in group.items():
                if "_FLIGHT" not in node_id:
                    continue
                if node_id in NOT_REAL_TAXI:
                    counts["skip"] = counts.get("skip", 0) + 1
                    rows.append((node_id, "skip", "", NOT_REAL_TAXI[node_id]))
                    continue
                name = node["name"] or ""
                key = norm(name)
                faction = faction_of(node_id)
                # A capture at the node's map position: the flight masters there, and their same-named faction twins.
                x, y, map_id = float(node["x"]), float(node["y"]), int(node["mapID"])
                near = sorted((math.hypot(x - cx, y - cy), tid) for tid, cm, cx, cy in captures
                              if cm == map_id and math.hypot(x - cx, y - cy) <= CAPTURE_RADIUS)
                candidates = taxi_by_base.get(key, [])
                by = "name"
                if not candidates:
                    # The old name is often just the generic word "Flightmaster" for a
                    # faction capital -- try the place name the node id itself carries.
                    key = id_derived_name(node_id)
                    candidates = taxi_by_base.get(key, [])
                    by = "id" if candidates else by
                if not candidates and node_id in MANUAL_FIXES:
                    fix = MANUAL_FIXES[node_id]
                    if "," in fix:
                        # Keeps the zone qualifier on purpose to pick one of several
                        # same-base-name rows (e.g. the three separate Vindicaar landings).
                        candidates = taxi_by_full.get(fix, [])
                    else:
                        key = fix
                        candidates = taxi_by_base.get(key, [])
                    by = "manual" if candidates else by
                if len(candidates) > 1:
                    # Prefer rows that actually sit somewhere in the world -- a duplicate at
                    # world (0,0,0) is unplaced/dead data, not a real alternative.
                    placed = placed_by_base.get(key, [])
                    if placed:
                        candidates = placed
                if faction and len(candidates) > 1:
                    candidates = [tid for tid in candidates if flags_of.get(tid, 0) & faction] or candidates
                if len(candidates) != 1 and near:
                    # What the name leaves open, a capture at the node's position settles.
                    names = {name_of.get(tid) for _d, tid in near}
                    pool = [tid for _d, tid in near] + [tid for tid, n in name_of.items()
                                                        if n in names and tid not in {t for _d, t in near}]
                    if faction:
                        pool = [tid for tid in pool if flags_of.get(tid, 0) & faction]
                    if pool:
                        candidates, by = pool[:1], "capture"
                if len(candidates) > 1:
                    # A capture that lists exactly one of the candidates, wherever it put it (the client gives some
                    # flight masters continent coordinates -- Northrend's Dalaran -- so no position can match them),
                    # says which one is real.
                    captured_ids = captured_on.get(continent_of(map_id), set())
                    seen = [tid for tid in candidates if tid in captured_ids]
                    if len(seen) == 1:
                        candidates, by = seen, "capture"
                if len(candidates) == 1:
                    verdict = "one"
                elif not candidates:
                    verdict = "zero"
                else:
                    verdict = "many"
                counts[verdict] += 1
                rows.append((node_id, verdict, ",".join(candidates), f"{name} [{by}]" if candidates else name))

    rows.sort(key=lambda r: (r[1] != "one", r[0]))
    with open(OUT, "w", encoding="utf-8") as f:
        f.write("# old node id\tverdict (one|zero|many|skip)\treal taxi ID(s)\told name\n")
        f.write("# GENERATED by tools/match_modern_taxi_nodes.py. \"many\" lists every candidate it\n")
        f.write("# found, most-likely first, but gen_modern_nodes.py renames it to that first one\n")
        f.write("# regardless -- better than the old descriptive id for now; fix the specific ones\n")
        f.write("# that turn out wrong by editing this file directly (re-running the matcher won't\n")
        f.write("# lose a MANUAL_FIXES-driven correction, but won't reorder a \"many\" row's\n")
        f.write("# candidates from real data either, so a by-hand reorder here is safe to keep).\n")
        f.write("# \"zero\" rows are used as-is (the old descriptive id, unrenamed); \"skip\" means a\n")
        f.write("# node this genuinely isn't the real taxi system at all (see NOT_REAL_TAXI).\n")
        for node_id, verdict, ids, name in rows:
            f.write(f"{node_id}\t{verdict}\t{ids}\t{name}\n")

    print(f"{counts['one']} confident, {counts['zero']} no match, {counts['many']} ambiguous, "
          f"{counts.get('skip', 0)} skipped (of {sum(counts.values())} total) -- see {OUT}")


if __name__ == "__main__":
    main()
