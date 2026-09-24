"""tools/modern_ids.py -- the node ids the Modern dataset uses, from the old addon's ids ("source ids").

One rule for every generator (gen_modern_nodes.py writes the map, gen_modern_edges.py and gen_modern_abilities.py
read it), so a node, the edges touching it and the abilities landing on it always agree. Ids follow Forever's
convention, <KIND>_<PLACE>, so the engine reads a node's kind from the front of its id in both flavours:

- A flight master matched to a real TaxiNodes row (tools/match_modern_taxi_nodes.py): TAXI_<taxiNodeID>. The client
  names it, as it does Forever's.
- A dungeon or raid entrance with a journal instance (tools/match_modern_instance_nodes.py, or
  modern_manual.INSTANCE_JOURNALS for the ones the match can't make): INSTANCE_<NAME>, and the node carries
  `kind = "instance"`, `journal = <journalInstanceID>` (the client's Dungeon Journal names it and says its expansion)
  and, for an entrance only one faction has, `faction`. <NAME> is the source id without its DUNGEON/RAID word
  (SIEGE_OF_BORALUS_DUNGEON_ALLIANCE -> INSTANCE_SIEGE_OF_BORALUS_ALLIANCE), or the journal's name for a hand-added
  INSTANCE_<journalInstanceID> node. An entrance with no journal instance keeps its source id and isn't an instance.
- A transport whose source id ends with its kind (BORALUS_DOCK, WAKING_SHORES_ORGRIMMAR_ZEP,
  DALARAN_PALADIN_PORTAL_HORDE, TOL_DAGOR_FLIGHT_ALLIANCE): the kind moves to the front, a trailing faction, floor or
  phase word stays at the end (DOCK_BORALUS, ZEPPELIN_WAKING_SHORES_ORGRIMMAR, PORTAL_DALARAN_PALADIN_HORDE,
  FLIGHT_TOL_DAGOR_ALLIANCE). FLIGHT is a flight master the TaxiNodes match didn't find.
- Anything else keeps its source id (a place: STORMWIND_PORTAL_ROOM_LOWER, DARK_PORTAL_BL, ORIBOS).
"""
import csv
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCE = ROOT / "tools" / "modern_source"
MAP_FILE = SOURCE / "id_map.tsv"

KINDS = {"PORTAL": "PORTAL", "DOCK": "DOCK", "ZEPPELIN": "ZEPPELIN", "ZEP": "ZEPPELIN", "TRAM": "TRAM",
         "TELEPORT": "TELEPORT", "FLIGHT": "FLIGHT"}
QUALIFIERS = {"ALLIANCE", "HORDE", "UPPER", "LOWER", "PAST", "PRESENT"}
INSTANCE_WORDS = {"DUNGEON", "RAID"}


def _matches(filename):
    """source id -> first real id, for every "one" or "many" row of a match file (see gen_modern_nodes.py)."""
    found = {}
    path = SOURCE / filename
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.strip() or line.startswith("#"):
            continue
        node_id, verdict, real_ids, _name = line.split("\t", 3)
        if verdict in ("one", "many"):
            found[node_id] = int(real_ids.split(",")[0])
    return found


def _journal_names():
    with open(SOURCE / "journal_instance_retail.csv", encoding="utf-8") as f:
        return {int(r["ID"]): r["Name_lang"] for r in csv.DictReader(f)}


def slug(text):
    return re.sub(r"[^A-Z0-9]+", "_", text.upper().replace("'", "")).strip("_")


def _kind_first(source_id):
    tokens = source_id.split("_")
    end = len(tokens)
    while end > 1 and tokens[end - 1] in QUALIFIERS:
        end -= 1
    kind = KINDS.get(tokens[end - 1])
    if not kind or end < 2 or tokens[0] in KINDS.values():
        return None
    return "_".join([kind] + tokens[:end - 1] + tokens[end:])


def _without_instance_word(source_id):
    tokens = [t for t in source_id.split("_") if t not in INSTANCE_WORDS]
    return "INSTANCE_" + "_".join(tokens)


def plan(source_ids, instance_journals):
    """{ source id: (new id, journal or None, faction or None) } for source ids in file order, and the list of
    (source id, id it couldn't have, earlier source id) collisions: the later one takes the next rule (a flight
    master whose TaxiNodes match is taken becomes FLIGHT_<PLACE>), or at worst keeps its source id.
    instance_journals: modern_manual.INSTANCE_JOURNALS."""
    taxi = _matches("flight_node_matches.tsv")
    instances = _matches("instance_node_matches.tsv")
    names = _journal_names()
    out, taken, collisions = {}, {}, []
    for source in source_ids:
        journal, faction, new = None, None, None
        manual = instance_journals.get(source)
        if manual is not None:
            journal, faction = (manual[0], manual[1]) if isinstance(manual, tuple) else (manual, None)
        elif source in instances:
            journal = instances[source]
        elif re.fullmatch(r"INSTANCE_\d+", source):
            journal = int(source.split("_")[1])
        candidates = []
        if source in taxi:
            candidates.append(f"TAXI_{taxi[source]}")
        if journal is not None:
            candidates.append(("INSTANCE_" + slug(names[journal])) if re.fullmatch(r"INSTANCE_\d+", source)
                              else _without_instance_word(source))
        candidates += [_kind_first(source), source]
        for candidate in candidates:
            if candidate is None:
                continue
            if candidate in taken and taken[candidate] != source:
                collisions.append((source, candidate, taken[candidate]))    # the next rule, or its source id
                continue
            new = candidate
            break
        taken[new] = source
        out[source] = (new, journal, faction)
    return out, collisions


def write(mapping):
    lines = ["# GENERATED by tools/gen_modern_nodes.py (tools/modern_ids.py): source id, Modern id, journal, faction."]
    for source, (new, journal, faction) in mapping.items():
        lines.append(f"{source}\t{new}\t{journal if journal is not None else ''}\t{faction or ''}")
    MAP_FILE.write_text("\n".join(lines) + "\n", encoding="utf-8")


def load():
    """{ source id: Modern id } from the map gen_modern_nodes.py wrote."""
    if not MAP_FILE.exists():
        raise SystemExit("no tools/modern_source/id_map.tsv -- run tools/gen_modern_nodes.py first")
    mapping = {}
    for line in MAP_FILE.read_text(encoding="utf-8").splitlines():
        if line and not line.startswith("#"):
            source, new, _journal, _faction = line.split("\t")
            mapping[source] = new
    return mapping
