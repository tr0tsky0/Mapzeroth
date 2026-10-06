"""Generates Data/Modern/Pois.lua: Modern's towns (anywhere with an inn that isn't a city) and their inns, the
same shape as Forever's (tools/gen_pois.py, Data/Forever/Pois.lua), so the hearthstone can find where a character is
bound and the picker can list the towns.

Source: tools/modern_source/innkeepers.tsv, scraped from retail Wowhead (tools/wowhead_scrape.js's approach, on
https://www.wowhead.com/npcs?filter=23;1;0 -- Wowhead's Innkeeper flag, which misses many -- merged with
https://www.wowhead.com/npcs/name-extended:innkeeper, NPCs titled Innkeeper and the like). One row per NPC per map:

    npcID  name  tag  zoneAreaID  uiMapID  floor  x,y (0-100: the middle of the biggest group of its spawns)  firstSeenPatch
    react ("a,h": 1 friendly to Alliance / Horde)

A row with no uiMapID gives a zone and a floor instead (a multi-floor city: Dalaran); INN_FLOORS maps that to a
map (or None: left out), else UiMapAssignment does when the zone has one map.

Steps:
  1. Keep rows on a map the Modern node data has, and not in INN_DROP.
  2. Innkeepers of one map standing a few steps apart are one inn. Its container is the one the map's unsplit nodes
     are in; on a phase-split map with no unsplit nodes, INN_PHASE says which side.
  3. An inn on a city's map belongs to that city. Anywhere else it is a town's: INN_TOWNS names it by hand, else the
     nearest flight master within FLIGHT_MASTER_RADIUS does (the client names flight masters in every language),
     else the nearest node with an area within AREA_RADIUS (the client names areas too). The town's key is that name.
  4. Faction: whoever the innkeepers are friendly to. Expansion: the earliest patch the town's innkeepers were seen
     in, except that an old-world town Classic had (one of Forever's towns, by name) that Cataclysm remade is
     Classic's (not in CATACLYSM_ZONES, the zones Cataclysm added).

    python tools/gen_modern_pois.py
"""
import collections
import csv
import math
import pathlib
import re
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import modern_manual as manual

ROOT = pathlib.Path(__file__).resolve().parent.parent
DATA = ROOT / "Data" / "Modern"
SOURCE = ROOT / "tools" / "modern_source"
OUT = DATA / "Pois.lua"

CLUSTER_RADIUS = 2.0            # map units (0-100): innkeepers this close are one inn
FLIGHT_MASTER_RADIUS = 15.0     # a flight master this close names the town (Modern's maps are drawn larger than Forever's)
FLIGHT_MASTER_SURE = 12.0       # one farther than this is reported, to check
AREA_RADIUS = 6.0               # else a node with an area this close does
TOWN_RADIUS = 6.0               # a town's inns stand within this of its first
CITY_RADIUS = 8.0               # on a map a city shares with its zone, an inn this close to the centre is the city's
OLD_WORLD = {12, 13}            # Kalimdor, the Eastern Kingdoms (UiMap continents)

NODE = re.compile(r'\{\s*id\s*=\s*"([^"]+)",\s*container\s*=\s*"([^"]+)",\s*mapID\s*=\s*(\d+),'
                  r'\s*x\s*=\s*([\d.]+),\s*y\s*=\s*([\d.]+)([^\n]*)')
AREA_FIELD = re.compile(r'area\s*=\s*(\d+)')


def dist(a, b):
    return math.hypot(a[0] - b[0], a[1] - b[1])


def slug(text):
    return re.sub(r"[^a-z0-9]+", "_", text.lower()).strip("_")


def load_nodes():
    """Every Modern node: id -> (container, mapID, (x, y) 0-100, area id or None)."""
    nodes = {}
    for path in sorted(DATA.glob("Nodes_*.lua")):
        for m in NODE.finditer(path.read_text(encoding="utf-8")):
            area = AREA_FIELD.search(m.group(6).split("}")[0])
            nodes[m.group(1)] = (m.group(2), int(m.group(3)), (float(m.group(4)) * 100, float(m.group(5)) * 100),
                                 int(area.group(1)) if area else None)
    return nodes


def map_containers(nodes):
    """mapID -> { outdoor container: how many nodes } (several on a phase-split map)."""
    out = collections.defaultdict(collections.Counter)
    for container, map_id, _, _ in nodes.values():
        if ".interior" not in container:
            out[map_id][container] += 1
    return out


def load_city_maps():
    """mapID -> [(city key, its centre 0-100)]: several when cities share a map (Pandaria's two shrines)."""
    text = (DATA / "Settlements.lua").read_text(encoding="utf-8")
    body = text[text.index("addon.Cities"):text.index("addon.Towns")]
    out = collections.defaultdict(list)
    for m in re.finditer(r"(\w+)\s*=\s*\{\s*mapID\s*=\s*\d+,\s*x\s*=\s*([\d.]+),\s*y\s*=\s*([\d.]+)[^\n]*"
                         r"maps\s*=\s*\{([\d,\s]+)\}", body):
        for map_id in m.group(4).split(","):
            if map_id.strip():
                out[int(map_id)].append((m.group(1), (float(m.group(2)) * 100, float(m.group(3)) * 100)))
    return out


def load_csv(name, key, value):
    with open(SOURCE / name, encoding="utf-8") as f:
        return {row[key]: row[value] for row in csv.DictReader(f)}


def load_area_maps():
    """zone area id -> the uiMaps assigned to it (UiMapAssignment), for rows that give a zone and floor."""
    out = collections.defaultdict(set)
    with open(SOURCE / "uimap_assignment_retail.csv", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            out[int(row["AreaID"])].add(int(row["UiMapID"]))
    return out


def load_continents():
    """uiMapID -> its continent's uiMapID (UiMap: the first ancestor of type 2), or None."""
    with open(SOURCE / "uimap_retail.csv", encoding="utf-8") as f:
        rows = {int(r["ID"]): (int(r["ParentUiMapID"] or 0), int(r["Type"] or 0)) for r in csv.DictReader(f)}
    out = {}
    for map_id in rows:
        cur, seen = map_id, set()
        while cur in rows and rows[cur][1] != 2 and cur not in seen:
            seen.add(cur)
            cur = rows[cur][0]
        out[map_id] = cur if cur in rows and rows[cur][1] == 2 else None
    return out


def load_forever_towns():
    """The English names of Forever's (Classic's) towns: an old-world town of one of these names is Classic's."""
    path = ROOT / "tools" / "poi_source" / "towns.tsv"
    return {line.split("\t")[4].strip().lower() for line in path.read_text(encoding="utf-8").splitlines()
            if line.strip() and not line.startswith("#")}


def faction_of(reacts):
    """Alliance, Horde or Both, from the innkeepers' reactions ("a,h": 1 friendly). An innkeeper who serves one faction
    says whose the town is: one who serves both (a visitor, a later event's) doesn't make a Horde town anyone's."""
    one_sided = [(a, h) for a, h in reacts if (a == "1") != (h == "1")]
    if one_sided:
        reacts = one_sided
    ally = any(a == "1" for a, _ in reacts)
    horde = any(h == "1" for _, h in reacts)
    if ally and not horde:
        return "Alliance"
    if horde and not ally:
        return "Horde"
    return "Both"


def main():
    nodes = load_nodes()
    containers = map_containers(nodes)
    city_maps = load_city_maps()
    taxi_names = load_csv("taxi_nodes_retail.csv", "ID", "Name_lang")
    area_names = {int(k): v for k, v in load_csv("area_table_retail.csv", "ID", "AreaName_lang").items()}
    area_maps = load_area_maps()
    continents = load_continents()
    forever_towns = load_forever_towns()
    floors = getattr(manual, "INN_FLOORS", {})
    drop = set(getattr(manual, "INN_DROP", ()))
    phase = getattr(manual, "INN_PHASE", {})
    town_overrides = getattr(manual, "INN_TOWNS", {})
    inn_cities = getattr(manual, "INN_CITIES", {})
    places = getattr(manual, "INN_PLACES", {})
    cataclysm_zones = set(getattr(manual, "CATACLYSM_ZONES", ()))
    city_zone_maps = set(getattr(manual, "CITY_ZONE_MAPS", ()))

    report = collections.defaultdict(list)
    npcs = []
    seen = set()
    with open(SOURCE / "innkeepers.tsv", encoding="utf-8") as f:
        for line in f:
            if not line.strip() or line.startswith("#"):
                continue
            npc, name, tag, zone, ui_map, floor, spot, patch, react = (line.rstrip("\n").split("\t") + [""] * 9)[:9]
            npc = int(npc)
            if npc in drop or (npc, int(ui_map or 0)) in drop:
                continue
            x, y = (float(v) for v in spot.split(","))
            if ui_map:
                map_id = int(ui_map)
            elif (int(zone), floor) in floors:
                map_id = floors[(int(zone), floor)]
                if map_id is None:
                    continue            # a floor left out on purpose
                if isinstance(map_id, str):     # a city's floor: the inn stands at the city's centre
                    map_id, (x, y) = next((m, c[1]) for m, cs in city_maps.items() for c in cs if c[0] == map_id)
            elif not floor and len(area_maps.get(int(zone), ())) == 1:      # a floor's spots are on its own plan
                map_id = next(iter(area_maps[int(zone)]))
            else:
                report["only a zone and floor (add to INN_FLOORS)"].append(f"{npc} {name} zone {zone} floor {floor}")
                continue
            if map_id not in containers:
                report["on a map the Modern data doesn't have"].append(f"{npc} {name} map {map_id}")
                continue
            if (npc, map_id) in seen:
                continue
            seen.add((npc, map_id))
            if npc in places and places[npc][0] == map_id:
                x, y = places[npc][1:]          # where they really stand (INN_PLACES)
            a, _, h = react.partition(",")
            npcs.append({"id": npc, "name": name, "map": map_id, "pos": (x, y), "patch": int(patch or 0), "react": (a, h)})

    # Innkeepers a few steps apart on one map are one inn (single linkage).
    inns = []
    by_map = collections.defaultdict(list)
    for n in npcs:
        by_map[n["map"]].append(n)
    for map_id, members in by_map.items():
        remaining = list(members)
        while remaining:
            group = [remaining.pop()]
            grew = True
            while grew:
                grew = False
                for n in remaining[:]:
                    if any(dist(n["pos"], g["pos"]) <= CLUSTER_RADIUS for g in group):
                        group.append(n)
                        remaining.remove(n)
                        grew = True
            group.sort(key=lambda g: g["id"])
            inns.append({"map": map_id, "members": group,
                         "pos": (sum(g["pos"][0] for g in group) / len(group),
                                 sum(g["pos"][1] for g in group) / len(group))})

    flight_masters = [(nid, m, p) for nid, (_, m, p, _) in nodes.items() if nid.startswith("TAXI_")]
    named = [(m, p, a) for _, m, p, a in nodes.values() if a]
    # Inns the node data already has (tools/modern_manual.py's NODE_KINDS: Silvermoon's): those stand for these.
    known_inns = [(nodes[nid][1], nodes[nid][2]) for nid, kind in getattr(manual, "NODE_KINDS", {}).items()
                  if kind == "inn" and nid in nodes]
    towns = {}
    out_nodes = []
    npc_maps = collections.Counter(inn["members"][0]["id"] for inn in inns)     # an innkeeper on several maps
    def nearest_flight_master(inn):
        on_map = [dist(f[2], inn["pos"]) for f in flight_masters if f[1] == inn["map"]]
        return min(on_map) if on_map else math.inf

    # The inn nearest its flight master goes first, so a flight master names the town it stands in, not whichever
    # camp farther off came first; inns named by hand come last, joining a town the others have made.
    for inn in sorted(inns, key=lambda i: (i["members"][0]["id"] in town_overrides, nearest_flight_master(i),
                                           i["map"], i["pos"])):
        lead = inn["members"][0]
        map_id = inn["map"]
        if any(m == map_id and dist(p, inn["pos"]) <= CLUSTER_RADIUS for m, p in known_inns):
            report["already an inn in the node data"].append(f"{lead['id']} {lead['name']} map {map_id}")
            continue
        options = containers[map_id]
        plain = [c for c in options if "_art" not in c]
        container = phase.get(lead["id"]) or (max(plain or options, key=lambda c: options[c]) if plain or len(options) == 1 else None)
        if not container:
            report["only phase sides on its map (add to INN_PHASE)"].append(
                f"{lead['id']} {lead['name']} map {map_id}: {sorted(options)}")
            continue
        # The city whose map this is: on a map a city shares with its zone, only near the city's centre.
        city = inn_cities.get(lead["id"])
        if not city and map_id in city_maps:
            key_, centre = min(city_maps[map_id], key=lambda c: dist(c[1], inn["pos"]))
            if map_id not in city_zone_maps or dist(centre, inn["pos"]) <= CITY_RADIUS:
                city = key_
        if city:
            owner = ("city", city)
        else:
            near = [f for f in flight_masters if f[1] == map_id and dist(f[2], inn["pos"]) <= FLIGHT_MASTER_RADIUS]
            near_area = [n for n in named if n[0] == map_id and dist(n[1], inn["pos"]) <= AREA_RADIUS]
            taxi = area = key = None
            if lead["id"] in town_overrides:
                if town_overrides[lead["id"]] is None:
                    name = None                 # no town's, by hand
                else:
                    key, area = town_overrides[lead["id"]]
                    name = area_names.get(area, key)
            elif near:
                taxi, _, taxi_pos = min(near, key=lambda f: dist(f[2], inn["pos"]))
                name = taxi_names.get(taxi[5:], taxi).split(",")[0]
                if dist(taxi_pos, inn["pos"]) > FLIGHT_MASTER_SURE:
                    report["named by a flight master a way off (check)"].append(
                        f"{lead['id']} {lead['name']} map {map_id}: {name} ({dist(taxi_pos, inn['pos']):.1f})")
            elif near_area:
                area = min(near_area, key=lambda n: dist(n[1], inn["pos"]))[2]
                name = area_names.get(area, str(area))
                report["named by a nearby area (check)"].append(f"{lead['id']} {lead['name']} map {map_id}: {name}")
            else:
                report["no flight master or area near: an inn of no town (name it in INN_TOWNS)"].append(
                    f"{lead['id']} {lead['name']} map {map_id} at {inn['pos'][0]:.1f},{inn['pos'][1]:.1f}")
                name = None
            if name and lead["id"] not in town_overrides:
                key = slug(name)
            if key and key in towns and towns[key]["map"] != map_id:
                key = f"{key}_{map_id}"                 # two places of one name (an old and a new one)
            # (A town named by hand takes the inn wherever it stands: a big town can have inns well apart.)
            if key and key in towns and lead["id"] not in town_overrides \
                    and dist(towns[key]["pos"], inn["pos"]) > TOWN_RADIUS:
                # A second inn the same flight master is nearest to, but well away from the first: another place.
                report["another inn's flight master, but far from it: an inn of no town (name it in INN_TOWNS)"].append(
                    f"{lead['id']} {lead['name']} map {map_id} at {inn['pos'][0]:.1f},{inn['pos'][1]:.1f} "
                    f"(nearest {towns[key]['name']})")
                key = None
        if not city and key is None:
            owner = None
        elif not city:
            town = towns.setdefault(key, {"map": map_id, "pos": inn["pos"], "taxi": taxi, "area": area, "name": name,
                                          "container": container, "reacts": [], "patch": None, "inns": 0})
            town["inns"] += 1
            town["reacts"] += [m["react"] for m in inn["members"]]
            patches = [m["patch"] for m in inn["members"] if m["patch"]]
            if patches:
                town["patch"] = min([town["patch"]] + patches) if town["patch"] else min(patches)
            owner = ("town", key)
        npc_list = ", ".join(f"{{ id = {m['id']} }}" for m in inn["members"])
        out_nodes.append(
            f'    {{ id = "INN_{lead["id"]}{"" if npc_maps[lead["id"]] == 1 else f"_{map_id}"}", container = "{container}", mapID = {map_id}, '
            f'x = {inn["pos"][0] / 100:.4f}, y = {inn["pos"][1] / 100:.4f}, kind = "inn", '
            + (f'{owner[0]} = "{owner[1]}", ' if owner else "") + f'npcs = {{ {npc_list} }} }}, -- {lead["name"]}')

    town_lines = []
    for key in sorted(towns):
        t = towns[key]
        fields = [f"mapID = {t['map']}", f"x = {t['pos'][0] / 100:.4f}", f"y = {t['pos'][1] / 100:.4f}"]
        if t["taxi"]:
            fields.append(f'taxi = "{t["taxi"]}"')
        if t["area"]:
            fields.append(f"area = {t['area']}")
        fields.append(f'faction = "{faction_of(t["reacts"])}"')
        expansion = t["patch"] // 10000 if t["patch"] else None
        # An old-world zone Cataclysm remade: a town Classic had is Classic's; one Cataclysm added stays Cataclysm's.
        if expansion == 4 and continents.get(t["map"]) in OLD_WORLD and t["map"] not in cataclysm_zones \
                and t["name"].lower() in forever_towns:
            expansion = 1
        if expansion:
            fields.append(f"expansion = {expansion}")
        t["expansion"] = expansion
        town_lines.append(f"    {key} = {{ {', '.join(fields)} }}, -- {t['name']}")

    OUT.write_text("\n".join([
        "-- Pois.lua (Modern) -- GENERATED by tools/gen_modern_pois.py, do not hand-edit.",
        "--",
        "-- Towns (anywhere with an inn that isn't a city) and the inns of towns and cities, the same shape as Forever's.",
        "-- A town is named by its flight master (`taxi`) or its area (`area`); its expansion is the earliest patch its",
        "-- innkeepers were seen in (an old-world town Classic had is Classic's, though Cataclysm remade it).",
        "",
        "local addonName, addon = ...",
        'if addon.RULESET ~= "modern" then return end   -- one addon for both games: this data is Modern\'s (Constants.lua)',
        "",
        "addon.Towns = {",
        *town_lines,
        "}",
        "",
        "-- A town has no centre node of its own: a trip to the town goes to its inn, the nearest when it has more than",
        "-- one (Destinations.lua). A city keeps its centre: it covers more ground, and has several inns.",
        "addon.Nodes = addon.Nodes or {}",
        "addon.Nodes.Inns = {",
        *out_nodes,
        "}",
        "",
    ]), encoding="utf-8")

    with open(SOURCE / "towns_review.tsv", "w", encoding="utf-8") as f:
        f.write("key\tname\tmapID\tx\ty\tfaction\texpansion\tinns\tnamed by\n")
        for key in sorted(towns, key=lambda k: (towns[k]["expansion"] or 0, towns[k]["map"], k)):
            t = towns[key]
            f.write(f"{key}\t{t['name']}\t{t['map']}\t{t['pos'][0]:.1f}\t{t['pos'][1]:.1f}\t{faction_of(t['reacts'])}\t"
                    f"{t['expansion']}\t{t['inns']}\t{'flight master' if t['taxi'] else 'area'}\n")

    print(f"{len(npcs)} innkeepers -> {len(inns)} inns, {len(out_nodes)} written; {len(towns)} towns "
          f"(tools/modern_source/towns_review.tsv)")
    for reason, items in report.items():
        print(f"\n{len(items)} {reason}:")
        for item in items:
            print("  " + item)


if __name__ == "__main__":
    main()
