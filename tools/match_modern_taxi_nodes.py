"""tools/match_modern_taxi_nodes.py -- matches the old addon's *_FLIGHT nodes against the
real retail TaxiNodes table (tools/modern_source/taxi_nodes_retail.csv, pulled from
https://wago.tools/db2/TaxiNodes/csv) by name, so they can be renamed to TAXI_<realID> and
get a free, properly-localized name from the client (C_TaxiMap) at runtime -- the same way
Forever's own flight masters already work. This is an exploration/report pass: it doesn't
write any renamed data itself, just tools/modern_source/flight_node_matches.tsv for review
(one line per old node: its id, the match verdict, and the real taxi ID(s) if any), which
tools/gen_modern_nodes.py then reads for the ids marked with a single confident match.

    python tools/match_modern_taxi_nodes.py
"""
import csv
import pathlib
import re
from lupa.lua51 import LuaRuntime

ROOT = pathlib.Path(__file__).resolve().parent.parent
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
    return node_id[: -len("_FLIGHT")].replace("_", " ").lower()


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
    taxi_by_full = {}      # full name, comma and all -- for a MANUAL_FIXES value that keeps
                            # the zone qualifier on purpose to pick one of several same-base-name rows
    placed_by_base = {}    # same as taxi_by_base, but rows sitting at world (0,0,0) -- unplaced/dead data -- left out
    with open(TAXI_CSV, encoding="utf-8-sig", newline="") as f:
        for row in csv.DictReader(f):
            key = norm(row["Name_lang"])
            taxi_by_base.setdefault(key, []).append(row["ID"])
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
                if not node_id.endswith("_FLIGHT"):
                    continue
                if node_id in NOT_REAL_TAXI:
                    counts["skip"] = counts.get("skip", 0) + 1
                    rows.append((node_id, "skip", "", NOT_REAL_TAXI[node_id]))
                    continue
                name = node["name"] or ""
                key = norm(name)
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
