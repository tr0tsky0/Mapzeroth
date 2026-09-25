"""Generates Data/Forever/Borders.lua: zone-to-zone walking crossings.

Source of truth: tools/border_checklist.md, a table of hand-checked crossings.
Each row is one crossing seen from both zones' own maps:

    | Zone A | x, y | Zone B | x, y | optional note |

  * Coordinates are 0-100, as the map cursor shows them.
  * A row starting with `***` is NOT a walkable crossing (the note says why);
    it is left out of the data and listed in Borders.lua's header instead.
  * A note containing "requires quest N" gates the crossing behind quest N.
  * A note containing "not zero travel" marks a crossing with real travel
    inside it (a tunnel): its edge gets no fixed cost, so the engine works the
    cost out from the distance between the two entrances.

tools/grids.json (from `/mzdump grid` in the MapzerothDataTools addon) is only
used to give each zone its mapID and to list zones that touch on the map but
have no crossing.

A crossing is a PAIR of nodes, one just inside each zone, joined by a walk
edge, because ground travel never auto-connects zones.

    python tools/gen_borders.py
"""
import collections
import json
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
GRIDS = json.load(open(ROOT / "tools" / "grids.json"))
CHECKLIST = ROOT / "tools" / "border_checklist.md"

CONTINENT_PREFIX = {"1414": "kalimdor", "1415": "easternkingdoms"}

# Cities are separate maps on the continent grid but live inside their
# surrounding zone's container in our node data.
FOLD = {1454: 1411, 1456: 1412, 1457: 1438, 1453: 1429, 1455: 1426, 1458: 1420}


def slug(name):
    return re.sub(r"[^a-z0-9]+", "_", name.lower().replace("'", "")).strip("_")


def zone_slug(name):
    return {"The Hinterlands": "hinterlands"}.get(name, slug(name))


# Names as they're typed in the checklist -> the map's own zone name.
ALIASES = {"Hinterlands": "The Hinterlands"}


def parse_coord(text):
    text = re.sub(r"\.\s+(\d)", r".\1", text)  # tolerate "84. 1"
    x, y = [float(p) for p in text.split(",")]
    return x / 100.0, y / 100.0


def parse_checklist():
    """Returns (crossings, excluded). Each is a list of dicts."""
    crossings, excluded = [], []
    for line in CHECKLIST.read_text(encoding="utf-8").splitlines():
        flagged = line.lstrip().startswith("***")
        line = line.lstrip().removeprefix("***").strip()
        if not line.startswith("|"):
            continue
        cells = [c.strip() for c in line.strip("|").split("|")]
        if len(cells) < 4 or cells[0] in ("Zone A", "") or set(cells[0]) <= set("-: "):
            continue
        row = {
            "a": ALIASES.get(cells[0], cells[0]), "ac": parse_coord(cells[1]),
            "b": ALIASES.get(cells[2], cells[2]), "bc": parse_coord(cells[3]),
            "note": cells[4] if len(cells) > 4 else "",
        }
        # [areaA=254] / [areaB=...]: the client's area id for that side's doorway, so the client names
        # it ("Blackrock Mountain") instead of "<zone> / <zone> border".
        areas = dict(re.findall(r"\[area([AB])=(\d+)\]", row["note"]))
        row["area_a"] = int(areas["A"]) if "A" in areas else None
        row["area_b"] = int(areas["B"]) if "B" in areas else None
        row["note"] = re.sub(r"\s*\[area[AB]=\d+\]", "", row["note"]).strip()
        # "requires quest N" in a note gates the crossing behind that quest.
        quest = re.search(r"requires quest (\d+)", row["note"], re.I)
        row["quest"] = int(quest.group(1)) if quest else None
        # A gated crossing with no requirement to model it is held back rather
        # than offered to everyone as a shortcut.
        if "needs a key" in row["note"].lower() and not row["quest"]:
            row["note"] += " (gated: held back until the key can be modeled as a requirement)"
            flagged = True
        (excluded if flagged else crossings).append(row)
    return crossings, excluded


def main():
    crossings, excluded = parse_checklist()
    problems = []

    # Zone name -> (continent id, mapID) from the grid.
    zones = {}
    touching = collections.defaultdict(lambda: collections.Counter())
    for cont, g in GRIDS.items():
        n, rows, maps = g["n"], g["rows"], g["maps"]

        def zone(v, cont=cont):
            v = FOLD.get(v, v)
            return 0 if str(v) == cont else v

        for mid, m in maps.items():
            zones[m["name"]] = (cont, int(mid))
        for row in range(n):
            for col in range(n):
                a = zone(rows[row][col])
                if not a:
                    continue
                for drow, dcol in ((0, 1), (1, 0)):
                    r2, c2 = row + drow, col + dcol
                    if r2 < n and c2 < n:
                        b = zone(rows[r2][c2])
                        if b and b != a:
                            pair = tuple(sorted((maps[str(a)]["name"], maps[str(b)]["name"])))
                            touching[cont][pair] += 1

    out_nodes, out_edges, connected = [], [], collections.defaultdict(set)
    for row in crossings:
        unknown = [row[side] for side in ("a", "b") if row[side] not in zones]
        if unknown:
            problems.append(f"unknown zone name(s) {unknown}: row skipped")
            continue
        (cont_a, id_a), (cont_b, id_b) = zones[row["a"]], zones[row["b"]]
        if cont_a != cont_b:
            problems.append(f"{row['a']} and {row['b']} are on different continents")
            continue
        pair = tuple(sorted((row["a"], row["b"])))
        if touching[cont_a][pair] == 0:
            problems.append(f"note: {row['a']} / {row['b']} don't touch on the continent map (another zone lies between); generated anyway")
        connected[cont_a].add(pair)

        prefix = CONTINENT_PREFIX[cont_a]
        ids = []
        for side, other, zid, (x, y), area in ((row["a"], row["b"], id_a, row["ac"], row["area_a"]),
                                               (row["b"], row["a"], id_b, row["bc"], row["area_b"])):
            nid = f"BORDER_{zone_slug(side).upper()}_TO_{zone_slug(other).upper()}"
            if any(nid in line for line in out_nodes):
                nid += "_2"  # a second crossing between the same two zones
            ids.append(nid)
            out_nodes.append(
                f'    {{ id = "{nid}", container = "{prefix}.{zone_slug(side)}", mapID = {zid}, '
                f'x = {x:.4f}, y = {y:.4f}{f", area = {area}" if area else ""} }}, -- {side} side of the {side}/{other} crossing')
        tunnel = "not zero travel" in row["note"].lower()
        cost = "" if tunnel else ", cost = 0"
        if row["quest"]:
            cost += f", requirements = {{ quest = {row['quest']} }}"
        note = f" -- {row['a']} <-> {row['b']}" + (f" ({row['note']})" if row["note"] else "")
        out_edges.append(f'    {{ from = "{ids[0]}", to = "{ids[1]}", method = "walk"{cost} }},{note}')

    lines = [
        "-- Borders.lua (Forever) -- GENERATED by tools/gen_borders.py from",
        "-- tools/border_checklist.md (edit that and regenerate; hand edits here are lost).",
        "--",
        "-- Zone-to-zone walking crossings. Each is a pair of nodes, one just inside each",
        "-- zone, joined by a walk edge. Coordinates were read off the in-game world map, so",
        "-- they are rough: refine by walking a crossing and capturing `/mzdump here`.",
        "-- A crossing with no `cost` has real travel inside it (a tunnel); the engine works",
        "-- the cost out from the distance between its two ends.",
        "--",
        "-- Checked and NOT walkable (left out on purpose):",
    ]
    for row in excluded:
        lines.append(f"--   {row['a']} <-> {row['b']}: {row['note'] or 'no reason given'}")
    lines.append("--")
    lines.append("-- Zones that touch on the map but have no crossing (no walkable link found):")
    for cont, counter in touching.items():
        lines.append(f"-- {CONTINENT_PREFIX[cont]}:")
        for pair, count in counter.most_common():
            if pair not in connected[cont]:
                lines.append(f"--   {count:3d} cells  {pair[0]} <-> {pair[1]}")
    lines += [
        "",
        "local addonName, addon = ...",
        'if addon.RULESET ~= "forever" then return end   -- one addon for both games: this data is Forever\'s (Constants.lua)',
        "",
        "addon.Nodes = addon.Nodes or {}",
        "addon.Edges = addon.Edges or {}",
        "",
        "addon.Nodes.Borders = {",
        *out_nodes,
        "}",
        "",
        "for _, edge in ipairs({",
        *out_edges,
        "}) do",
        "    table.insert(addon.Edges, edge)",
        "end",
        "",
    ]
    (ROOT / "Data" / "Forever" / "Borders.lua").write_text("\n".join(lines), encoding="utf-8")
    print(f"{len(out_nodes)} nodes, {len(out_edges)} crossings, {len(excluded)} rows excluded")
    for p in problems:
        print("PROBLEM:", p)


if __name__ == "__main__":
    main()
