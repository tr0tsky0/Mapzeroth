"""Generates Data/Forever/Pois.lua and Data/Forever/TownNames_enUS.lua.

Points of interest (inns, banks, auction houses) come from Wowhead's Forever
NPC data (tools/poi_source/*.tsv, produced by tools/wowhead_scrape.js) and from
in-game captures (tools/poi_source/captured.tsv).

A settlement is a CITY (a faction capital) or a TOWN (anything else with an
inn); tools/poi_source/towns.tsv lists them. With no inn, it isn't a town.

Steps:
  1. NPCs of one kind on one map that stand a few steps from each other are
     one place (a bank's tellers are one bank). Farther apart is another
     place: a city can have several inns, banks or auction houses.
  2. Each place joins its nearest settlement. A city map is a single city.
  3. Each settlement gets a name source: its flight master (the client names
     those), else a locale string. An `area` id can be added later once the
     client's area name has been checked against the expected name.

New-content maps (Zephras Isle, Riverglades, Dalaran, Mount Hyjal, Shen'dralas)
are held back: Wowhead's Forever data for them is unconfirmed, and some of it
is known to be non-functional in game. Confirm in game, then capture with
`/mzdump poi` into captured.tsv.

    python tools/gen_pois.py
"""
import collections
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "tools" / "poi_source"
GRIDS = json.load(open(ROOT / "tools" / "grids.json"))

CONTINENT_PREFIX = {"1414": "kalimdor", "1415": "easternkingdoms"}
# City maps live inside their surrounding zone's container in our node data.
FOLD = {1454: 1411, 1456: 1412, 1457: 1438, 1453: 1429, 1455: 1426, 1458: 1420}
CITY_MAPS = set(FOLD)
HELD_BACK_MAPS = {2521: "Zephras Isle", 2548: "Riverglades", 1416: "Alterac Mountains (Dalaran)",
                  2482: "Mount Hyjal", 2652: "Shen'dralas"}

# Maps not on a continent grid, with the container we gave them by hand.
EXTRA_CONTAINERS = {2521: "zephras_isle.zephras_isle"}

KINDS = {"innkeepers.tsv": "inn", "bankers.tsv": "bank", "auctioneers.tsv": "auction",
         "battlemasters.tsv": "battlemaster", "stable_masters.tsv": "stable"}
TRAINER_FILES = ["class_trainers.tsv", "class_trainers_towns.tsv", "class_trainers_worldmap.tsv",
                 "weapon_riding_trainers.tsv", "pet_trainers.tsv", "demon_trainers.tsv",
                 "profession_trainers.tsv"]
PREFIX = {"inn": "INN", "bank": "BANK", "auction": "AUCTION", "trainer": "TRAINER",
          "battlemaster": "BATTLEMASTER", "stable": "STABLE", "entrance": "ENTRANCE",
          "leyline": "LEYLINE"}
# Places that are out in the world and never join a settlement, whatever is nearby, so
# they are named after their zone ("Zephras Isle Ley Line"). Ley lines are for the
# Skyborne racial Find Ley Line.
WORLD_KINDS = {"leyline"}

CLASS_TOKENS = ["WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID"]
# Wowhead's title for an NPC ("<Mage Trainer>") -> what it trains. Class trainers use
# the client's own class token, so their names come from the client.
SPECIAL_TAGS = {"Master Mage": "MAGE", "High Priest": "PRIEST", "High Priestess": "PRIEST",
                "Weapon Master": "WEAPON", "Mechanostrider Pilot": "RIDING",
                "Pet Trainer": "PET", "Demon Trainer": "DEMON"}


# Profession trainers: the profession is worked out from the NPC's title, and what it
# teaches is the profession's rank spells ("Apprentice Tailoring", ...), which Wowhead
# lists under the bare profession name.
PROFESSION_WORDS = [
    ("LEATHERWORKING", ("leather",)), ("TAILORING", ("tailor",)), ("BLACKSMITHING", ("blacksmith",)),
    ("ALCHEMY", ("alchem",)), ("ENGINEERING", ("engineer",)), ("ENCHANTING", ("enchant",)),
    ("HERBALISM", ("herbal",)), ("MINING", ("mining", "miner")), ("SKINNING", ("skinn", "butcher")),
    ("COOKING", ("cook",)), ("FIRSTAID", ("first aid", "physician")), ("FISHING", ("fish",)),
]
PROFESSION_TOKENS = {t for t, _ in PROFESSION_WORDS}
OTHER_TRAINER_TOKENS = {"WEAPON", "RIDING", "PET", "DEMON"}

# Rank spells of each profession, Apprentice first, as listed on Wowhead's trainer pages.
# Only the ranks seen there are listed. A trainer captured in game has no NPC data, so
# what it teaches comes from this rule: gathering professions train up to Artisan, every
# other profession up to Journeyman (the Skyborne trainers, confirmed in game).
def load_rank_spells():
    """addon.ProfessionRanks in Data/Forever/Professions.lua, one profession per line."""
    text = (ROOT / "Data" / "Forever" / "Professions.lua").read_text(encoding="utf-8")
    body = text[text.index("addon.ProfessionRanks"):]
    return {m.group(1): [int(n) for n in m.group(2).split(",") if n.strip()]
            for m in re.finditer(r"(\w+)\s*=\s*\{([\d,\s]+)\}", body)}


RANK_SPELLS = load_rank_spells()
GATHERING = {"HERBALISM", "MINING", "SKINNING"}


TIER_RANKS = {"journeyman": 2, "expert": 3, "artisan": 4}


def captured_teaches(trainer, tier=None):
    """A captured trainer has no NPC page, so what it teaches is the profession's ranks up
    to the tier noted in game (`tier`), or by default the Skyborne rule."""
    ranks = RANK_SPELLS.get(trainer, [])
    if tier:
        return ranks[:TIER_RANKS[tier]]
    return ranks if trainer in GATHERING else ranks[:2]


# What `/mzdump poi <kind> <key>` may carry in its key. Besides the settlement key it can note
# the highest rank a profession trainer offers ("dalaran_including_expert") and number
# repeats ("dalaran_2"). Returns settlementKey, tier or None, and a default town name.
CAPTURE_KEY = re.compile(r"(.+?)(?:_including_(journeyman|expert|artisan))?(?:_(\d+))?")
# `/mzdump poi` calls a stable master's kind stable_master.
CAPTURE_KINDS = {"stable_master": "stable", "ley_line": "leyline"}


def parse_capture_key(raw):
    raw = raw.strip().lower()
    if raw == "-":
        return None, None, ""
    m = CAPTURE_KEY.fullmatch(raw)
    town, tier = m.group(1), m.group(2)
    return town, tier, town.replace("_", " ").title()
PROFESSION_BASE_NAMES = {"Alchemy", "Blacksmithing", "Enchanting", "Engineering", "Herbalism",
                         "Leatherworking", "Mining", "Skinning", "Tailoring", "Cooking", "First Aid", "Fishing"}


def profession_from_tag(tag):
    lowered = tag.lower()
    for token, words in PROFESSION_WORDS:
        if any(w in lowered for w in words):
            return token
    return None


# What a trainer teaches is stored as spell ids, whose names the client supplies in
# the player's language. Weapon masters and riding instructors keep everything (weapon
# skills, riding ranks and mount types); others keep only skill-rank spells ("Journeyman Blacksmithing", "Apprentice Riding"), not recipes.
RANK_SPELL = re.compile(r"^(Apprentice|Journeyman|Expert|Artisan|Master|Grand Master) ")


def teaches_ids(kind, column):
    ids = []
    for entry in column.split("|"):
        if not entry or ":" not in entry:
            continue
        spell_id, name = entry.split(":", 1)
        if kind in ("WEAPON", "RIDING"):
            ids.append(int(spell_id))
        elif kind in PROFESSION_TOKENS:
            # Only this profession's own ranks (a page can list another profession's too).
            if int(spell_id) in RANK_SPELLS.get(kind, []):
                ids.append(int(spell_id))
        elif RANK_SPELL.match(name):
            ids.append(int(spell_id))
    return sorted(set(ids))


# Trainers of a specialization (Dragonscale, Shadoweave, Goblin ...) are only useful once
# the player has chosen it, so the picker keeps them out of the default list.
SPECIALTY_WORDS = ("dragonscale", "elemental", "tribal", "shadoweave", "goblin", "gnome")


def trainer_type(tag):
    if tag in SPECIAL_TAGS:
        return SPECIAL_TAGS[tag]
    if tag.endswith(" Trainer") and tag[:-8].upper() in CLASS_TOKENS:
        return tag[:-8].upper()
    if "Riding" in tag:
        return "RIDING"
    return profession_from_tag(tag)

# NPCs within this many map units (0-100) of each other are one place: about
# 20-50 yards, "a few steps". Larger halls can be listed in HALL_RADIUS.
CLUSTER_RADIUS = 2.0
# A class's trainers stand together in one hall or enclave, a bit wider than an inn.
CLUSTER_RADIUS_BY_KIND = {"trainer": 6.0}
# Places that are really one big room: the Undercity auction house is a ring of
# auctioneers around a central hall, and Thunder Bluff's two auctioneers (about
# 2.8 units apart) share one auction house.
HALL_RADIUS = {("auction", 1458): 12.0, ("auction", 1456): 5.0}
SETTLEMENT_RADIUS = 12.0       # zone maps only
FLIGHT_MASTER_RADIUS = 8.0     # zone maps only


def slug(name):
    return re.sub(r"[^a-z0-9]+", "_", name.lower().replace("'", "")).strip("_")


def zone_slug(name):
    return {"The Hinterlands": "hinterlands"}.get(name, slug(name))


def dist(a, b):
    return ((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2) ** 0.5


def load_frames():
    """{ mapID: (ax, bx, ay, by) }: Forever = a * Classic + b per axis, least squares over map_frames.tsv's pairs."""
    pairs = collections.defaultdict(list)
    path = SRC / "map_frames.tsv"
    if path.exists():
        for line in path.read_text(encoding="utf-8").splitlines():
            if line.strip() and not line.startswith("#"):
                map_id, cx, cy, fx, fy = line.split("\t")[:5]
                pairs[int(map_id)].append((float(cx), float(cy), float(fx), float(fy)))

    def fit(xs, ys):
        n = len(xs)
        mx, my = sum(xs) / n, sum(ys) / n
        sxx = sum((x - mx) ** 2 for x in xs)
        a = sum((x - mx) * (y - my) for x, y in zip(xs, ys)) / sxx
        return a, my - a * mx

    frames = {}
    for map_id, ps in pairs.items():
        if len(ps) < 2:
            sys.exit(f"map_frames.tsv: map {map_id} needs two or more pairs to fit a conversion")
        ax, bx = fit([p[0] for p in ps], [p[2] for p in ps])
        ay, by = fit([p[1] for p in ps], [p[3] for p in ps])
        worst = max(max(abs(ax * p[0] + bx - p[2]), abs(ay * p[1] + by - p[3])) for p in ps)
        print(f"map {map_id}: Forever = {ax:.3f}x + {bx:.2f}, {ay:.3f}y + {by:.2f} (worst pair off by {worst:.2f})")
        frames[map_id] = (ax, bx, ay, by)
    return frames


FRAMES = None


def to_forever(map_id, pos):
    """A Wowhead (Classic) position on a map, in Forever's coordinates (map_frames.tsv)."""
    global FRAMES
    if FRAMES is None:
        FRAMES = load_frames()
    frame = FRAMES.get(map_id)
    if not frame:
        return pos
    ax, bx, ay, by = frame
    return (ax * pos[0] + bx, ay * pos[1] + by)


def load_maps():
    """mapID -> container path, via the continent grid."""
    result = {}
    for cont, g in GRIDS.items():
        for mid in g["maps"]:
            mid = int(mid)
            zone_name = g["maps"][str(FOLD.get(mid, mid))]["name"]
            result[mid] = f"{CONTINENT_PREFIX[cont]}.{zone_slug(zone_name)}"
    result.update(EXTRA_CONTAINERS)
    return result


def load_npcs():
    npcs = []
    for filename, kind in KINDS.items():
        for line in (SRC / filename).read_text(encoding="utf-8").splitlines():
            if not line.strip():
                continue
            npc_id, name, _tag, map_id, _map_name, coords = line.split("\t")
            pts = [tuple(float(v) for v in c.split(",")) for c in coords.split()]
            pos = to_forever(int(map_id), (sum(p[0] for p in pts) / len(pts), sum(p[1] for p in pts) / len(pts)))
            npcs.append({"kind": kind, "trainer": None, "id": int(npc_id), "label": npc_id,
                         "captured": False, "map": int(map_id), "pos": pos, "teaches": []})
    return npcs


def load_trainers():
    trainers, skipped = [], collections.Counter()
    for filename in TRAINER_FILES:
        for line in (SRC / filename).read_text(encoding="utf-8").splitlines():
            if not line.strip():
                continue
            cols = line.split("	")
            npc_id, name, tag, map_id, _map_name, coords = cols[:6]
            kind = trainer_type(tag)
            if not kind:
                skipped[tag] += 1
                continue
            pts = [tuple(float(v) for v in c.split(",")) for c in coords.split()]
            pos = to_forever(int(map_id), (sum(p[0] for p in pts) / len(pts), sum(p[1] for p in pts) / len(pts)))
            teaches = teaches_ids(kind, cols[6]) if len(cols) > 6 else []
            specialty = kind in PROFESSION_TOKENS and any(w in tag.lower() for w in SPECIALTY_WORDS)
            trainers.append({"kind": "trainer", "trainer": kind, "id": int(npc_id), "label": npc_id,
                             "captured": False, "map": int(map_id), "pos": pos, "teaches": teaches,
                             "specialty": specialty})
    return trainers, skipped


def load_instances():
    """tools/poi_source/instances.tsv: key, category, mapID, x, y, English name, areaID, level."""
    instances = []
    path = SRC / "instances.tsv"
    if not path.exists():
        return instances
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.strip() or line.startswith("#"):
            continue
        key, category, map_id, x, y, name, area, _level, container = (line.split("\t") + [""] * 9)[:9]
        fx, fy = to_forever(int(map_id), (float(x), float(y)))
        instances.append({"key": key, "category": category, "map": int(map_id), "x": fx, "y": fy,
                          "name": name, "area": int(area) if area else None, "container": container or None})
    return instances


def load_settlements():
    settlements = {}
    for line in (SRC / "towns.tsv").read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        cols = line.split("\t")
        key, map_id, x, y, name, kind = cols[:6]
        settlements[key] = {"map": int(map_id), "pos": to_forever(int(map_id), (float(x), float(y))), "name": name, "type": kind,
                            "area": int(cols[6]) if len(cols) > 6 and cols[6] else None}
    return settlements


def load_captured(settlements):
    """In-game captures (`/mzdump poi`), one per line:
        kind <tab> mapID <tab> x <tab> y <tab> settlementKey <tab> name [<tab> areaID]
    x and y are 0-100. The area id (from `/mzdump area`) lets the client name a new town. A key not in towns.tsv defines a new TOWN (an inn is
    what makes one), named by the last column. Captured positions beat
    Wowhead's for the same place, and captured places are never held back."""
    path = SRC / "captured.tsv"
    captured = []
    if not path.exists():
        return captured
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.strip() or line.startswith("#"):
            continue
        cols = line.split("\t")
        kind, map_id, x, y, key, name = cols[:6]
        area = int(cols[6]) if len(cols) > 6 and cols[6] else None
        kind, _, trainer = kind.partition(":")     # "trainer:MAGE" for a class trainer
        kind = kind.lower()
        kind = CAPTURE_KINDS.get(kind, kind)
        trainer = trainer.upper().replace(" ", "").replace("_", "")
        key, tier, default_name = parse_capture_key(key)
        if name.strip().lower() == cols[4].strip().lower():
            name = default_name                     # no name given, so `/mzdump poi` echoed the key
        map_id, x, y = int(map_id), float(x), float(y)
        if key is None:
            pass                                    # outside any settlement: named after its zone
        elif key not in settlements:
            settlements[key] = {"map": map_id, "pos": (x, y), "name": name, "type": "town", "area": area,
                                "from_capture": True}
        if key and settlements[key].get("from_capture"):
            if kind == "inn":                       # a town is centred on its inn(s)
                inns = settlements[key].setdefault("inns", [])
                inns.append((x, y))
                settlements[key]["pos"] = (sum(p[0] for p in inns) / len(inns), sum(p[1] for p in inns) / len(inns))
            if area:
                settlements[key]["area"] = area
        captured.append({"kind": kind, "trainer": trainer or None,
                         "teaches": captured_teaches(trainer, tier) if kind == "trainer" else [], "id": 0, "label": f"C{map_id}_{round(x * 10)}_{round(y * 10)}",
                         "captured": True, "map": map_id, "pos": (x, y), "settlement": key, "area": area})
    return captured


def load_flight_masters():
    fms = []
    pattern = re.compile(r'\{\s*id\s*=\s*"(TAXI_\d+)",\s*container\s*=\s*"[^"]+",\s*mapID\s*=\s*(\d+),'
                         r'\s*x\s*=\s*([\d.]+),\s*y\s*=\s*([\d.]+)')
    for path in sorted((ROOT / "Data" / "Forever").glob("Nodes_*.lua")):
        for m in pattern.finditer(path.read_text(encoding="utf-8")):
            fms.append({"id": m.group(1), "map": int(m.group(2)),
                        "pos": (float(m.group(3)) * 100, float(m.group(4)) * 100)})
    return fms


def load_ignored():
    """NPC ids from tools/poi_source/ignored_npcs.tsv: Wowhead listings the game has shown to be wrong. An id with a
    trainer type after a colon (1300:MAGE) leaves out only that listing of the NPC."""
    path = SRC / "ignored_npcs.tsv"
    ids = set()
    if path.exists():
        for line in path.read_text(encoding="utf-8").splitlines():
            if line.strip() and not line.startswith("#"):
                ids.add(line.split("\t")[0].strip())
    return ids


def cluster(npcs):
    """Single-linkage clusters of same-kind, same-map NPCs."""
    groups = collections.defaultdict(list)
    for n in npcs:
        groups[(n["kind"], n["trainer"], n["map"])].append(n)
    places = []
    for (kind, trainer, map_id), members in groups.items():
        radius = HALL_RADIUS.get((kind, map_id), CLUSTER_RADIUS_BY_KIND.get(kind, CLUSTER_RADIUS))
        remaining = list(members)
        while remaining:
            group = [remaining.pop()]
            grew = True
            while grew:
                grew = False
                for n in remaining[:]:
                    if any(dist(n["pos"], g["pos"]) <= radius for g in group):
                        group.append(n)
                        remaining.remove(n)
                        grew = True
            # A captured position (standing there) beats Wowhead's.
            basis = [g for g in group if g["captured"]] or group
            lead = min(group, key=lambda g: (g["id"], g["label"]))
            captured_members = [g for g in group if g["captured"]]
            # A capture's settlement column is authoritative when given: "-" (settlement None) means
            # someone stood there and confirmed it belongs to no settlement, which must stick even if
            # it happens to fall within SETTLEMENT_RADIUS of one (the radius is a straight-line guess,
            # blind to water and mountains in between). Only fall through to that guess when nothing
            # captured said anything either way.
            standalone = bool(captured_members) and captured_members[0]["settlement"] is None
            places.append({
                "kind": kind, "trainer": trainer, "map": map_id, "label": lead["label"], "npcs": len(group),
                "members": sorted(group, key=lambda g: (g["captured"], g["id"])),
                "pos": (sum(g["pos"][0] for g in basis) / len(basis), sum(g["pos"][1] for g in basis) / len(basis)),
                "settlement": next((g["settlement"] for g in group if g["captured"]), None),
                "standalone": standalone,
            })
    return places


def load_settlement_factions():
    """{key: "Alliance" | "Horde" | "Both"} from tools/poi_source/settlement_factions.tsv."""
    out = {}
    path = ROOT / "tools" / "poi_source" / "settlement_factions.tsv"
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.strip() and not line.startswith("#"):
            key, faction = line.split("\t")[:2]
            out[key] = faction
    return out


def lua_table(name, entries, taxi):
    factions = load_settlement_factions()
    lines = [f"addon.{name} = {{"]
    for key, t in sorted(entries.items()):
        extra = f', taxi = "{taxi[key]}"' if key in taxi else ""
        if t.get("area"):
            extra += f", area = {t['area']}"
        if key in factions:
            extra += f', faction = "{factions[key]}"'
        else:
            print(f"  no faction for {name[:-1].lower()} {key}: shown to everyone until it is added to settlement_factions.tsv")
        lines.append(f'    {key} = {{ mapID = {t["map"]}, x = {t["pos"][0] / 100:.4f}, y = {t["pos"][1] / 100:.4f}{extra} }},')
    lines.append("}")
    return lines


def main():
    containers = load_maps()
    npcs = load_npcs()
    trainers, skipped_tags = load_trainers()
    npcs += trainers
    settlements = load_settlements()
    fms = load_flight_masters()
    npcs += load_captured(settlements)
    ignored = load_ignored()
    before = len(npcs)
    npcs = [n for n in npcs if n.get("captured") or not (str(n["id"]) in ignored
                                                         or f'{n["id"]}:{n["trainer"]}' in ignored)]
    if before != len(npcs):
        print(f"  left out {before - len(npcs)} Wowhead NPC(s) listed in ignored_npcs.tsv")

    # A held-back NPC counts as confirmed once someone captured a place of the same
    # kind standing right next to it in game.
    captured_places = [n for n in npcs if n["captured"]]

    def confirmed(n):
        return any(c["kind"] == n["kind"] and c["trainer"] == n["trainer"] and c["map"] == n["map"]
                   and dist(c["pos"], n["pos"]) <= CLUSTER_RADIUS for c in captured_places)

    held = collections.Counter()
    kept = []
    for n in npcs:
        if n["map"] in (1414, 1415):
            held[("a continent map (no exact position)", n["kind"])] += 1
        elif n["map"] in HELD_BACK_MAPS and not n["captured"] and not confirmed(n):
            held[(HELD_BACK_MAPS[n["map"]], n["kind"])] += 1
        else:
            kept.append(n)
    places = cluster(kept)

    # Names: the flight master at the settlement when there is one, else a locale string.
    taxi = {}
    for key, t in settlements.items():
        same_map = [f for f in fms if f["map"] == t["map"]]
        if t["map"] not in CITY_MAPS:
            same_map = [f for f in same_map if dist(f["pos"], t["pos"]) <= FLIGHT_MASTER_RADIUS]
        if same_map:
            taxi[key] = min(same_map, key=lambda f: dist(f["pos"], t["pos"]))["id"]

    unassigned, out_nodes, counts = [], [], collections.Counter()
    used_ids = set()
    for p in sorted(places, key=lambda p: (p["map"], p["kind"], p["label"])):
        if p["kind"] in WORLD_KINDS or p["standalone"]:
            key = None
        elif p["settlement"]:
            key = p["settlement"]
        elif p["map"] in CITY_MAPS:
            same = [k for k, t in settlements.items() if t["map"] == p["map"]]
            key = same[0] if same else None
        else:
            near = sorted((dist(p["pos"], t["pos"]), k) for k, t in settlements.items() if t["map"] == p["map"])
            key = near[0][1] if near and near[0][0] <= SETTLEMENT_RADIUS else None
        ident = PREFIX[p["kind"]] + (f"_{p['trainer']}" if p["trainer"] else "") + f"_{p['label']}"
        if ident in used_ids:                  # the same NPC can stand in several places
            ident += f"_{p['map']}"
        used_ids.add(ident)
        trainer_field = f', trainer = "{p["trainer"]}"' if p["trainer"] else ""
        if not key:
            unassigned.append(p)   # outside any settlement: named after its zone
            where = ""
        else:
            field = "city" if settlements[key]["type"] == "city" else "town"
            where = f', {field} = "{key}"'
            counts[(key, p["kind"], p["trainer"])] += 1
        npc_entries = []
        for m in p["members"]:
            if m["captured"] and not m["teaches"]:
                continue                       # nothing known about a captured NPC but where it is
            teaches = f"teaches = {{ {', '.join(str(t) for t in m['teaches'])} }}" if m["teaches"] else ""
            ident_part = "" if m["captured"] else f"id = {m['id']}"
            specialty = "specialty = true" if m.get("specialty") else ""
            npc_entries.append("{ " + ", ".join(x for x in (ident_part, specialty, teaches) if x) + " }")
        npc_field = f", npcs = {{ {', '.join(npc_entries)} }}" if npc_entries else ""
        area_field = ""
        if p["kind"] == "entrance":
            area = next((m.get("area") for m in p["members"] if m.get("area")), None)
            if area:
                area_field = f", area = {area}"
        out_nodes.append(
            f'    {{ id = "{ident}", container = "{containers[p["map"]]}", mapID = {p["map"]}, '
            f'x = {p["pos"][0] / 100:.4f}, y = {p["pos"][1] / 100:.4f}, kind = "{p["kind"]}"{trainer_field}{where}{npc_field}{area_field} }},')

    # A city or town is a region, so it gets a node of its own at its centre: what "go to
    # Goldshire" routes to. (A city is entered through its entrances when it has them, and
    # its centre is then only the fallback.)
    for key, t in sorted(settlements.items()):
        if t["map"] not in containers:
            continue
        field = "city" if t["type"] == "city" else "town"
        out_nodes.append(
            f'    {{ id = "{field.upper()}_{key.upper()}", container = "{containers[t["map"]]}", mapID = {t["map"]}, '
            f'x = {t["pos"][0] / 100:.4f}, y = {t["pos"][1] / 100:.4f}, kind = "settlement", {field} = "{key}" }},')

    instances = load_instances()
    for inst in instances:
        area = f", area = {inst['area']}" if inst["area"] else ""
        raid = ", raid = true" if inst["category"] == "raid" else ""
        out_nodes.append(
            f'    {{ id = "INSTANCE_{inst["key"].upper()}", container = "{inst["container"] or containers[inst["map"]]}", '
            f'mapID = {inst["map"]}, x = {inst["x"] / 100:.4f}, y = {inst["y"] / 100:.4f}, '
            f'kind = "instance"{raid}{area} }},')

    cities = {k: t for k, t in settlements.items() if t["type"] == "city"}
    towns = {k: t for k, t in settlements.items() if t["type"] == "town"}

    lines = [
        "-- Pois.lua (Forever) -- GENERATED by tools/gen_pois.py, do not hand-edit.",
        "--",
        "-- Cities (the faction capitals), towns (anywhere else with an inn), and the places in",
        "-- them that people route to: inns, banks, auction houses. A city can hold several of",
        "-- each. Settlement names are not stored here: one takes its name from its flight master",
        "-- (`taxi`), the client's area name (`area`), or a locale string CITY_<KEY> / TOWN_<KEY>,",
        "-- in that order. Place names are built from a kind pattern and the settlement's name",
        "-- (\"Goldshire Inn\"), so a place needs no string of its own.",
        "--",
        "-- Held back (unconfirmed new Forever content; confirm in game and capture with",
        "-- `/mzdump poi`):",
    ]
    for (zone, kind), count in sorted(held.items()):
        lines.append(f"--   {zone}: {count} {kind} NPC(s)")
    if unassigned:
        lines += ["--", f"-- {len(unassigned)} places outside any city or town (starter areas and the like);",
                  "-- they keep a zone-based name:"]
        for p in unassigned:
            what = p["trainer"] and f"{p['trainer']} trainer" or p["kind"]
            lines.append(f"--   {what} on map {p['map']} at ({p['pos'][0]:.1f}, {p['pos'][1]:.1f})")
    if skipped_tags:
        lines += ["--", "-- Trainer roles not modeled yet: " + ", ".join(f"{t} ({n})" for t, n in sorted(skipped_tags.items()))]
    lines += ["", "local addonName, addon = ...", "if addon.RULESET ~= \"forever\" then return end   -- one addon for both games: this data is Forever's (Constants.lua)", "", "addon.Nodes = addon.Nodes or {}", ""]
    lines += lua_table("Cities", cities, taxi) + [""]
    lines += lua_table("Towns", towns, taxi) + [""]
    lines += ["addon.Nodes.Pois = {", *out_nodes, "}", ""]
    (ROOT / "Data" / "Forever" / "Pois.lua").write_text("\n".join(lines), encoding="utf-8")

    strings = [
        "-- TownNames_enUS.lua (Forever) -- GENERATED by tools/gen_pois.py.",
        "--",
        "-- English names for cities and towns that have no flight master to take a name from.",
        "-- Move one out of here by giving it an `area` id whose client name matches.",
        "",
        "local addonName, addon = ...",
        "if addon.RULESET ~= \"forever\" then return end   -- one addon for both games: this data is Forever's (Constants.lua)",
        "",
        'addon:RegisterLocale("enUS", {',
    ]
    for key, t in sorted(settlements.items()):
        if key not in taxi and not t.get("area"):
            strings.append(f'    {"CITY" if t["type"] == "city" else "TOWN"}_{key.upper()} = "{t["name"]}",')
    strings += ["})", ""]
    (ROOT / "Data" / "Forever" / "TownNames_enUS.lua").write_text("\n".join(strings), encoding="utf-8")

    # An instance is named by the client from its area id; until that is checked in game,
    # it takes an English string.
    inst_strings = [
        "-- InstanceNames_enUS.lua (Forever) -- GENERATED by tools/gen_pois.py.",
        "--",
        "-- English names for instance entrances whose area id hasn't been checked in game yet.",
        "-- Give the instance an area id in tools/poi_source/instances.tsv to have the client",
        "-- name it instead (and this string goes away).",
        "",
        "local addonName, addon = ...",
        "if addon.RULESET ~= \"forever\" then return end   -- one addon for both games: this data is Forever's (Constants.lua)",
        "",
        'addon:RegisterLocale("enUS", {',
    ]
    for inst in instances:
        if not inst["area"]:
            inst_strings.append(f'    NODE_INSTANCE_{inst["key"].upper()} = "{inst["name"]}",')
    inst_strings += ["})", ""]
    (ROOT / "Data" / "Forever" / "InstanceNames_enUS.lua").write_text("\n".join(inst_strings), encoding="utf-8")

    by_kind = collections.Counter(p["kind"] for p in places)
    print(f"{len(instances)} instance entrances")
    print(f"{len(cities)} cities, {len(towns)} towns ({len(taxi)} named by a flight master); "
          f"{len(out_nodes)} places {dict(by_kind)}; {len(unassigned)} outside any settlement; "
          f"{sum(held.values())} NPCs held back")
    for (key, kind, trainer), n in sorted(counts.items(), key=lambda kv: str(kv[0])):
        if n > 1:
            print(f"  {key}: {n} {trainer or kind} places")


if __name__ == "__main__":
    main()
