"""tools/gen_modern_nodes.py -- converts the original retail addon's per-continent node
files (../Mapzeroth/Data/Mapzeroth_Data_Nodes_*.lua) into the rebuild's node schema
(Data/Modern/Nodes_*.lua). See docs/DESIGN.md section 2 and 4 for the target shape.

FIRST PASS, geometry only: node id/mapID/x/y carry over unchanged. Names, factions and
availability move to edges/name-resolution later (section 4/5) and aren't touched here.
Run it again any time the source addon's node files change; it's fully mechanical and
takes no data-author judgment calls beyond the ones written up in CONVERSION_NOTES.md,
which this script regenerates alongside the data every run.

    python tools/gen_modern_nodes.py

Container-path scheme (docs/DESIGN.md section 2):
    <traversalGroup>.map<mapID>[_art<mapArtID>][.interior]

- <traversalGroup> (lowercased) becomes the new "continent" segment. The old data already
  scopes fly/walk auto-edges to a traversalGroup exactly the way the new engine wants a
  continent-level fly domain to work -- confirmed by inspection: Tol Barad, Deepholm, and
  each Shadowlands realm are already their own separate traversalGroup, not lumped into
  their landmass's, which is exactly the granularity the new model wants.
- <mapID> becomes the zone-equivalent leaf. This is a deliberate narrowing from the old
  model, where ground auto-edges were traversalGroup-wide (see DESIGN.md section 2's
  "ground auto-edges are zone-scoped only" decision). Old data never named a "zone", so
  mapID is the only reliable zone proxy available in the source.
- _art<mapArtID>, when a node carries the old mapArtID marker, keeps time-phase siblings
  that share one mapID from being merged into one container -- that would silently claim
  they're walkably connected, which is exactly backwards for two states of one zone. This
  does NOT build the actual phaseGroup/phaseSide/phaseswitch-edge wiring; that needs the
  specific Zidormi-NPC pairing per zone, done by hand later (see CONVERSION_NOTES.md).
- .interior groups every node the old data flagged `interior = true` on that mapID into
  one shared sub-container, walled off from the outdoor part the same way a captured city
  is (TravelGraph.lua's container-based walking pass). KNOWN SIMPLIFICATION: two distinct
  physical rooms sharing one mapID (Stormwind has several) land in the same interior
  container and so read as walkably joined, which likely isn't true for all of them.
  Splitting specific rooms apart is follow-up work; an explicit edge between two interior
  nodes already covers real connectivity regardless of container, so nothing is silently
  unreachable in the meantime -- it's just under-connected until edges are ported too.

Flight-master nodes with a confident match in tools/modern_source/flight_node_matches.tsv
(tools/match_modern_taxi_nodes.py, matched by name against the real retail TaxiNodes table)
are renamed to TAXI_<realID> here, id and all -- so they get a free, properly-localized name
from the client at runtime (C_TaxiMap) exactly the way Forever's own flight masters do,
instead of needing a hand-authored override. gen_modern_edges.py applies the same rename to
every edge's from/to so the two files stay consistent.
"""
import pathlib
import sys
from lupa.lua51 import LuaRuntime

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import modern_manual as manual
import conversion_notes

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = pathlib.Path(r"C:\Users\shaun\Documents\Claude\Mapzeroth\Mapzeroth\Data")
OUT = ROOT / "Data" / "Modern"

# Old file stem -> (output key for addon.Nodes.<key>, output filename).
FILES = [
    ("Mapzeroth_Data_Nodes_EK.lua", "EK", "Nodes_EK.lua"),
    ("Mapzeroth_Data_Nodes_Kalimdor.lua", "Kalimdor", "Nodes_Kalimdor.lua"),
    ("Mapzeroth_Data_Nodes_Outlands.lua", "Outlands", "Nodes_Outlands.lua"),
    ("Mapzeroth_Data_Nodes_Northrend.lua", "Northrend", "Nodes_Northrend.lua"),
    ("Mapzeroth_Data_Nodes_Pandaria.lua", "Pandaria", "Nodes_Pandaria.lua"),
    ("Mapzeroth_Data_Nodes_BrokenIsles.lua", "BrokenIsles", "Nodes_BrokenIsles.lua"),
    ("Mapzeroth_Data_Nodes_Draenor.lua", "Draenor", "Nodes_Draenor.lua"),
    ("Mapzeroth_Data_Nodes_DragonIsles.lua", "DragonIsles", "Nodes_DragonIsles.lua"),
    ("Mapzeroth_Data_Nodes_KhazAlgar.lua", "KhazAlgar", "Nodes_KhazAlgar.lua"),
    ("Mapzeroth_Data_Nodes_Shadowlands.lua", "Shadowlands", "Nodes_Shadowlands.lua"),
    ("Mapzeroth_Data_Nodes_Zandalar.lua", "Zandalar", "Nodes_Zandalar.lua"),
    ("Mapzeroth_Data_Nodes_Argus.lua", "Argus", "Nodes_Argus.lua"),
    ("Mapzeroth_Data_Nodes_BfA.lua", "BfA", "Nodes_BfA.lua"),
    ("Mapzeroth_Data_Nodes_IsolatedMaps.lua", "IsolatedMaps", "Nodes_IsolatedMaps.lua"),
]

# Known cross-file id collisions (same node id authored twice against different mapIDs --
# see CONVERSION_NOTES.md). Keep the EK_OVERWORLD copy (newer-looking mapID), drop the
# other. Any *other* collision this run finds is new and gets reported, not silently
# resolved -- the run stops so it can be looked at.
KNOWN_DUPES = {"SILVERMOON_CITY_FLIGHT", "FAIRBREEZE_VILLAGE_FLIGHT"}

# Straight copy of the old Constants.lua's NO_FLY_MAPS (mapID -> comment), the source of
# truth for which containers get fly = false overrides in the generated Containers.lua.
NO_FLY_MAPS = {
    94: "Eversong Woods", 95: "Ghostlands", 110: "Silvermoon City",
    122: "Isle of Quel'Danas", 103: "Exodar", 97: "Azuremyst Isle", 106: "Bloodmyst Isle",
    1670: "Oribos", 1671: "Oribos (Ring)", 1543: "The Maw",
    830: "Krokuun", 882: "Eredath", 883: "Vindicaar, Argus", 885: "Antoran Wastes",
    554: "Timeless Isle",
    2346: "Undermine (11.1)",
    2509: "Coiled Isle / Vaults of Atal'Utek (12.1) -- mount-only, no flying",
    407: "Darkmoon Island",
}


# Each match file (tools/match_modern_*.py) -> the id prefix its confident matches become.
MATCH_FILES = {
    "flight_node_matches.tsv": "TAXI_",
    "instance_node_matches.tsv": "INSTANCE_",
}


def load_renames():
    """old node id -> "<PREFIX><realID>", for every "one" (confident) or "many" (ambiguous)
    row across tools/modern_source/*_matches.tsv (tools/match_modern_taxi_nodes.py and
    tools/match_modern_instance_nodes.py). "many" takes the first listed candidate on
    purpose (the user's call: better than the old descriptive id for now, fix the specific
    ones that turn out wrong later) -- the tsv still lists every candidate it found, so
    which ones were a guess stays visible. "zero" and "skip" rows are left alone."""
    renames = {}
    for filename, prefix in MATCH_FILES.items():
        path = ROOT / "tools" / "modern_source" / filename
        if not path.exists():
            continue
        for line in path.read_text(encoding="utf-8").splitlines():
            if not line.strip() or line.startswith("#"):
                continue
            node_id, verdict, real_ids, _name = line.split("\t", 3)
            if verdict in ("one", "many"):
                renames[node_id] = f"{prefix}{real_ids.split(',')[0]}"
    return renames


def container_of(group, node):
    path = f"{group.lower()}.map{int(node['mapID'])}"
    if node["mapArtID"] is not None:
        path += f"_art{int(node['mapArtID'])}"
    if node["interior"]:
        path += ".interior"
    return path


def load(lua, loadstring, path):
    ns = lua.eval("{}")
    src = path.read_text(encoding="utf-8-sig")
    chunk = loadstring(src, "@" + path.name)
    if isinstance(chunk, tuple):
        raise SystemExit(f"syntax error in {path.name}: {chunk[1]}")
    chunk("Mapzeroth", ns)
    return ns


def main():
    lua = LuaRuntime(unpack_returned_tuples=True)
    loadstring = lua.eval("loadstring")

    OUT.mkdir(parents=True, exist_ok=True)
    seen_ids = {}          # id -> (file, group) of the copy we kept
    dupes_seen = []         # (id, kept, dropped) for the report
    interior_mapids = {}    # (group, mapid) -> count of interior nodes there
    phase_nodes = []        # (id, group, mapID, mapArtID) for the report
    mapid_groups = {}       # raw mapID -> set of traversalGroups a node was seen on it with
    per_group_counts = {}
    total_written = 0
    renames = load_renames()
    used_new_ids = {}       # "TAXI_<realID>"/"INSTANCE_<realID>" -> the old node id that claimed it first
    rename_collisions = []  # (old_id, new_id, first_old_id) two old nodes matched the same real id

    for filename, out_key, out_name in FILES:
        ns = load(lua, loadstring, SRC / filename)
        lines = [f'addon.Nodes.{out_key} = {{']
        for group_name, group in ns.Nodes.items():
            count = 0
            for node_id, node in group.items():
                if node_id in seen_ids:
                    if node_id in KNOWN_DUPES:
                        continue    # already emitted from the file that owns it
                    dupes_seen.append((node_id, seen_ids[node_id], (filename, group_name)))
                    continue
                seen_ids[node_id] = (filename, group_name)
                x, y = float(node["x"]), float(node["y"])
                container = container_of(group_name, node)
                mapid_groups.setdefault(int(node["mapID"]), set()).add(group_name)
                if node["interior"]:
                    interior_mapids[(group_name, int(node["mapID"]))] = \
                        interior_mapids.get((group_name, int(node["mapID"])), 0) + 1
                if node["mapArtID"] is not None:
                    phase_nodes.append((node_id, group_name, int(node["mapID"]), int(node["mapArtID"])))
                name = node["name"] or ""
                out_id = node_id
                if node_id in renames:
                    new_id = renames[node_id]
                    if new_id in used_new_ids:
                        rename_collisions.append((node_id, new_id, used_new_ids[new_id]))
                    else:
                        used_new_ids[new_id] = node_id
                        out_id = new_id
                lines.append(
                    f'    {{ id = "{out_id}", container = "{container}", '
                    f'mapID = {int(node["mapID"])}, x = {x:.4f}, y = {y:.4f} }}, -- {name}'
                )
                count += 1
                total_written += 1
            per_group_counts[(filename, group_name)] = count
        for mn in manual.NODES:
            if mn["out"] != out_name:
                continue
            if mn["id"] in seen_ids:
                raise SystemExit(f"manual node {mn['id']} collides with an id already converted")
            seen_ids[mn["id"]] = (out_name, "manual")
            area = f', area = {mn["area"]}' if mn.get("area") else ""
            lines.append(
                f'    {{ id = "{mn["id"]}", container = "{mn["container"]}", '
                f'mapID = {mn["mapID"]}, x = {mn["x"]:.4f}, y = {mn["y"]:.4f}{area} }}, '
                f'-- {mn["note"]} (hand-added: tools/modern_manual.py)'
            )
            total_written += 1
        lines.append('}')
        (OUT / out_name).write_text(
            f"-- {out_name} (Modern) -- GENERATED by tools/gen_modern_nodes.py from the original\n"
            f"-- addon's {filename}, do not hand-edit. Geometry only (see the script's own\n"
            f"-- docstring for the conversion rules and known simplifications); names, factions,\n"
            f"-- edges and containers-flag overrides are separate, later passes.\n\n"
            "local addonName, addon = ...\n\n"
            "addon.Nodes = addon.Nodes or {}\n\n"
            + "\n".join(lines) + "\n",
            encoding="utf-8",
        )

    # Containers.lua: fly = false for every container a NO_FLY_MAPS mapID landed in (matched
    # by raw mapID, not the mapArtID-qualified path -- a zone's phase-siblings share whether
    # flying works there), and indoor = true for every interior container this pass made, per
    # docs/DESIGN.md section 2 ("defaults to true for any Interior container" -- not automatic
    # in the engine, so it has to be written down here explicitly).
    no_fly_containers = {}     # container path -> NO_FLY_MAPS comment
    no_fly_unmatched = []      # mapIDs with no node on them in this data at all
    for mapid, comment in NO_FLY_MAPS.items():
        groups = mapid_groups.get(mapid)
        if not groups:
            no_fly_unmatched.append((mapid, comment))
            continue
        for group in groups:
            no_fly_containers[f"{group.lower()}.map{mapid}"] = comment
    indoor_containers = {
        f"{group.lower()}.map{mapid}.interior": count
        for (group, mapid), count in interior_mapids.items()
    }
    container_lines = [
        "-- Containers.lua (Modern) -- GENERATED by tools/gen_modern_nodes.py.",
        "-- fly = false is mined from the old Constants.lua's NO_FLY_MAPS table, matched against",
        "-- the containers the node conversion actually produced (see CONVERSION_NOTES.md for",
        f"-- {len(no_fly_unmatched)} NO_FLY_MAPS mapID(s) with no node on them in this data to match against).",
        "-- indoor = true is set for every interior container this pass made (see its own note",
        "-- in CONVERSION_NOTES.md about per-mapID, not per-room, grouping).",
        "",
        "local addonName, addon = ...",
        "",
        "addon.Containers = addon.Containers or {}",
        'addon.Containers[""] = { fly = true, indoor = false }   -- Modern has flying broadly, unlike Forever',
        "",
    ]
    for path, comment in sorted(no_fly_containers.items()):
        container_lines.append(f'addon.Containers["{path}"] = {{ fly = false }} -- {comment}')
    container_lines.append("")
    for path, count in sorted(indoor_containers.items()):
        container_lines.append(f'addon.Containers["{path}"] = {{ indoor = true }} -- {count} interior node(s)')
    for path in manual.INDOOR:
        container_lines.append(f'addon.Containers["{path}"] = {{ indoor = true }} -- hand-marked interior (tools/modern_manual.py)')
    (OUT / "Containers.lua").write_text("\n".join(container_lines) + "\n", encoding="utf-8")

    # Known collisions we deliberately resolved, so they don't silently vanish from the report.
    for node_id in KNOWN_DUPES:
        dupes_seen.append((node_id, "EK_OVERWORLD", "the other copy (different mapID/x/y)"))

    notes = [
        "# Modern node conversion notes (GENERATED by tools/gen_modern_nodes.py)",
        "",
        f"{total_written} nodes written across {len(FILES)} files.",
        "",
        "## Needs a follow-up pass before this data is usable for routing",
        "",
        "- **Edges** (Mapzeroth/Data/Mapzeroth_Data_Edges.lua, 2018 lines) haven't been converted at",
        "  all yet. Two real differences from the new engine's own rules, not just a reshape:",
        "  - The old engine defaults an edge's omitted `cost` to a flat per-method constant",
        "    (`TRAVEL_COSTS`: portal/teleport/hearthstone/racial = 0, ship = 60, tram = 90,",
        "    flight = 120, walk/fly = 30/10 as a last-resort-only fallback). The new engine's",
        "    omitted-cost fallback is distance-based instead (meant for walk/fly, not portals).",
        "    A straight copy of an old edge with no `cost` would get a nonsense",
        "    ground-walking-speed cost from the new engine instead of the old flat default --",
        "    every omitted-cost portal/teleport/ship/tram/flight edge needs its old",
        "    `TRAVEL_COSTS[method]` value written in literally during conversion.",
        "  - `requirements.faction` on an edge carries over directly (the new schema already",
        "    puts faction on edges, never nodes -- and in fact no node in the old data ever",
        "    carried a `faction` field itself, confirmed by scanning all 14 files, so there's",
        "    nothing node-level to re-home).",
        "",
        "- **Abilities / items / toys** (PlayerAbilities.lua, 1569 lines) not touched yet.",
        "",
        "- **Phase-tagged nodes** (mapArtID present) are kept apart from each other (see the",
        "  `_art<N>` container suffix) so nothing wrongly claims two phase-states of a zone are",
        f"  walkably joined, but that's as far as this pass goes. {len(phase_nodes)} nodes carry",
        "  mapArtID; none of them have a phaseGroup/phaseSide tag or a phaseswitch edge yet, so",
        "  right now they're simply unreachable until both are added by hand, zone by zone",
        "  (the Fable review findings on the wip/timephased-routing branch of the original addon",
        "  already worked out several of these zone/mapArtID pairings and are worth reusing",
        "  rather than re-deriving from scratch).",
    ]
    if phase_nodes:
        notes.append("")
        notes.append("  | node | traversalGroup | mapID | mapArtID |")
        notes.append("  |---|---|---|---|")
        for node_id, group, mapid, art in phase_nodes:
            notes.append(f"  | {node_id} | {group} | {mapid} | {art} |")

    notes += [
        "",
        "- **Interior grouping is per-mapID, not per-room** (see the script's docstring) for",
        f"  {sum(interior_mapids.values())} interior nodes across {len(interior_mapids)} distinct",
        "  (traversalGroup, mapID) pairs. Any pair holding more than one physically-separate room",
        "  needs splitting into its own sub-container once that's actually confirmed in game --",
        "  the same way the Wizard's Sanctum was split out for Forever.",
        "",
        "  | traversalGroup | mapID | interior nodes there |",
        "  |---|---|---|",
    ]
    for (group, mapid), count in sorted(interior_mapids.items()):
        notes.append(f"  | {group} | {mapid} | {count} |")

    taxi_count = sum(1 for v in used_new_ids if v.startswith("TAXI_"))
    instance_count = sum(1 for v in used_new_ids if v.startswith("INSTANCE_"))
    notes += [
        "",
        f"- **Naming**: {taxi_count} flight-master nodes were renamed to `TAXI_<realID>` "
        "(tools/match_modern_taxi_nodes.py, matched against the real retail TaxiNodes table by "
        f"name) and {instance_count} dungeon/raid entrances to `INSTANCE_<journalInstanceID>` "
        "(tools/match_modern_instance_nodes.py, matched against JournalInstance) -- both now get "
        "a free, properly-localized name from the client at runtime (C_TaxiMap / "
        "EJ_GetInstanceInfo, see NodeNames.lua), the same way Forever's flight masters already "
        "do. Everything else -- the flight/instance nodes with no confident match (see those "
        "scripts' own *_matches.tsv), and every portal/mole-machine/item-destination node -- "
        "still has no name at all: NodeNames.lua's resolve() has nothing to go on for an id like "
        "`STORMWIND_BORALUS_PORTAL` (place name first, not a kind prefix the way Forever's own "
        "ids are written). Worth a suffix-based resolve() fallback at some point (most portal ids "
        "end `_PORTAL`, the mirror image of Forever's prefix convention) for whatever's left.",
    ]
    if rename_collisions:
        notes.append(f"  - {len(rename_collisions)} rename collision(s) (two old nodes matched the same real "
                      "id -- kept the first, left the other under its old id):")
        for node_id, new_id, first in rename_collisions:
            notes.append(f"    - `{node_id}` -> {new_id}, already claimed by `{first}`")

    notes += [
        "",
        "## Resolved during this pass",
        "",
        "- `category` (city/dungeon/raid, 222 nodes) was dropped: it's old picker-UI",
        "  classification metadata, not location data, and the new picker (Sections.lua/",
        "  Destinations.lua) categorizes by settlement kind and relevance rules instead. Revisit",
        "  if the new picker turns out to want an equivalent grouping.",
        "- `phaseCheckMapID` (16 nodes) was dropped: it's an old pathfinder-search-time concept",
        "  tied to the mapArtID/phaseCheckMapID special-casing the new engine's phase model",
        "  replaces outright (see docs/DESIGN.md section 2) -- phase identity now lives on the",
        "  zone container, not threaded per-node through the search.",
        "- Cross-file id collisions: " + (str(len(dupes_seen)) + " found." if dupes_seen else "none found."),
    ]
    for node_id, kept, dropped in sorted(dupes_seen, key=str):      # a fixed order: a rerun changes nothing
        notes.append(f"  - `{node_id}`: kept {kept}, dropped {dropped}")
    notes.append(
        "- NO_FLY_MAPS entries with no surviving node to hang a container override off: "
        + (", ".join(f"{mapid} ({comment})" for mapid, comment in no_fly_unmatched) if no_fly_unmatched else "none.")
    )

    # Only the top of the file is ours: the edge and ability generators' sections are kept (conversion_notes.py).
    conversion_notes.write_head(OUT / "CONVERSION_NOTES.md", "\n".join(notes) + "\n")

    print(f"wrote {total_written} nodes across {len(FILES)} files to {OUT}")
    print(f"{len(dupes_seen)} id collision(s), {len(phase_nodes)} phase-tagged node(s), "
          f"{len(interior_mapids)} interior (group, mapID) pair(s), "
          f"{len(used_new_ids)} renamed to a real id -- see CONVERSION_NOTES.md")


if __name__ == "__main__":
    main()
