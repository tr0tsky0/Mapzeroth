"""tools/gen_modern_abilities.py -- converts the original retail addon's four travel-ability
tables (../Mapzeroth/PlayerAbilities.lua: TravelItems, ClassTeleports, RacialAbilities,
DungeonTeleports) into the rebuild's schema (Data/Modern/Abilities.lua, addon.Abilities.
{Teleports,Hearthstones,Items} -- see Data/Forever/Abilities.lua for the shape and
PlayerAbilities.lua:GetKnownTeleports for how each is consumed). Run after
tools/gen_modern_nodes.py and gen_modern_edges.py (this script checks every destination
against that pass's node ids, applying the same TAXI_/INSTANCE_ renames, and drops --
reporting -- anything that doesn't resolve).

    python tools/gen_modern_abilities.py

Category mapping:
- TravelItems with `destination == nil` (only the real Hearthstone, itemID 6948) becomes
  Hearthstones: goes to wherever the player is bound (ctx.hearthNode), not a fixed spot.
- TravelItems with a fixed destination becomes Items (NEW category this pass adds to
  GetKnownTeleports): item-based, like Hearthstones, but a fixed `to` like Teleports.
  `faction` carries through (two entries can share one itemID with a different `to` each
  per faction -- Admiral's Compass does; GetKnownTeleports picks the one that matches).
- ClassTeleports and DungeonTeleports become Teleports (spell-based, fixed `to`).
- RacialAbilities' one entry (Dark Iron's Mole Machine) is a genuine multi-destination
  pick-one-of-many ability -- `destinations` becomes `toList`; GetKnownTeleports expands it
  into one route candidate per stop and the search picks whichever is actually cheapest.

Skipped, not silently dropped -- each is counted and listed in CONVERSION_NOTES.md:
- `isRandom` items (2): the client sends you to one of several unlisted spots at random: not
  a destination a deterministic search can promise, unlike a `destinations` list (see above)
  the player actually picks from. The old data itself draws this distinction (isRandom vs
  multiDestination), which this script trusts over guessing from outside knowledge.
- `destinationsByArtID` abilities (1, a Mage teleport phase-gated by Darkshore's state):
  same open item as the phase-tagged nodes/edges from the earlier passes -- needs the real
  phaseGroup/phaseSide wiring, not a coin-flip default, so it's left out until that exists.
- Anything whose destination doesn't resolve to a converted node id, even after the rename.
"""
import pathlib
from lupa.lua51 import LuaRuntime

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = pathlib.Path(r"C:\Users\shaun\Documents\Claude\Mapzeroth\Mapzeroth\PlayerAbilities.lua")
OUT = ROOT / "Data" / "Modern" / "Abilities.lua"
NOTES = ROOT / "Data" / "Modern" / "CONVERSION_NOTES.md"

MATCH_FILES = {
    "flight_node_matches.tsv": "TAXI_",
    "instance_node_matches.tsv": "INSTANCE_",
}

FACTION = {"ALLIANCE": "Alliance", "HORDE": "Horde"}


def load_renames():
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


def known_node_ids():
    ids = set()
    for path in sorted((ROOT / "Data" / "Modern").glob("Nodes_*.lua")):
        for line in path.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if line.startswith('{ id = "'):
                ids.add(line.split('"')[1])
    return ids


def main():
    lua = LuaRuntime(unpack_returned_tuples=True)
    loadstring = lua.eval("loadstring")
    ns = lua.eval("{}")
    src = SRC.read_text(encoding="utf-8-sig")
    chunk = loadstring(src, "@" + SRC.name)
    if isinstance(chunk, tuple):
        raise SystemExit(f"syntax error in {SRC.name}: {chunk[1]}")
    chunk("Mapzeroth", ns)

    renames = load_renames()
    node_ids = known_node_ids()
    if not node_ids:
        raise SystemExit("no Data/Modern/Nodes_*.lua found -- run tools/gen_modern_nodes.py first")

    def resolve(old_id):
        renamed = renames.get(old_id)
        return renamed if renamed and renamed in node_ids else old_id

    teleports, hearthstones, items = [], [], []
    dangling = []       # (ability id, destination) that never resolved to a real node
    skipped_random = []
    skipped_phase = []

    # TravelItems: hearthstone-style (no destination), fixed-destination items, or skipped.
    for ability_id, a in ns["TravelItems"].items():
        cost, cooldown, item_id = a["castTime"], a["cooldown"], a["itemID"]
        faction = FACTION.get(a["faction"]) if a["faction"] else None
        if a["isRandom"]:
            skipped_random.append((ability_id, a["name"]))
            continue
        if a["multiDestination"]:
            dest_list = [resolve(d) for d in a["destinations"].values()]
            missing = [d for d in dest_list if d not in node_ids]
            if missing:
                dangling.append((ability_id, ", ".join(missing)))
                continue
            items.append({"itemID": item_id, "toList": dest_list, "cost": cost,
                          "cooldown": cooldown, "faction": faction})
            continue
        if a["destination"] is None:
            hearthstones.append({"itemID": item_id, "cost": cost, "cooldown": cooldown})
            continue
        to = resolve(a["destination"])
        if to not in node_ids:
            dangling.append((ability_id, a["destination"]))
            continue
        items.append({"itemID": item_id, "to": to, "cost": cost, "cooldown": cooldown, "faction": faction})

    # ClassTeleports: spell-based, fixed destination (or skipped for a phase-gated one); a
    # spell with no destination at all (Astral Recall) goes to wherever the player is bound,
    # same as the item Hearthstone -- see PlayerAbilities.lua:GetKnownTeleports.
    for ability_id, a in ns["ClassTeleports"].items():
        if a["destinationsByArtID"]:
            skipped_phase.append((ability_id, a["name"]))
            continue
        if a["destination"] is None:
            hearthstones.append({"spellID": a["spellID"], "cost": a["castTime"], "cooldown": a["cooldown"]})
            continue
        to = resolve(a["destination"])
        if to not in node_ids:
            dangling.append((ability_id, a["destination"]))
            continue
        teleports.append({"spellID": a["spellID"], "to": to, "cost": a["castTime"], "cooldown": a["cooldown"]})

    # RacialAbilities: just the Mole Machine, a real multi-destination pick.
    for ability_id, a in ns["RacialAbilities"].items():
        dest_list = [resolve(d) for d in a["destinations"].values()]
        missing = [d for d in dest_list if d not in node_ids]
        if missing:
            dangling.append((ability_id, ", ".join(missing)))
            continue
        teleports.append({"spellID": a["spellID"], "toList": dest_list, "cost": a["castTime"],
                          "cooldown": a["cooldown"]})

    # DungeonTeleports: spell-based, fixed destination, sometimes faction-restricted.
    for ability_id, a in ns["DungeonTeleports"].items():
        to = resolve(a["destination"])
        if to not in node_ids:
            dangling.append((ability_id, a["destination"]))
            continue
        faction = FACTION.get(a["faction"]) if a["faction"] else None
        teleports.append({"spellID": a["spellID"], "to": to, "cost": a["castTime"],
                          "cooldown": a["cooldown"], "faction": faction})

    def fmt(entry):
        parts = []
        if "spellID" in entry:
            parts.append(f'spellID = {int(entry["spellID"])}')
        if "itemID" in entry:
            parts.append(f'itemID = {int(entry["itemID"])}')
        if "toList" in entry:
            parts.append('toList = { ' + ", ".join(f'"{d}"' for d in entry["toList"]) + ' }')
        elif "to" in entry:
            parts.append(f'to = "{entry["to"]}"')
        parts.append(f'cost = {int(entry["cost"])}')
        if entry.get("cooldown"):
            parts.append(f'cooldown = {int(entry["cooldown"])}')
        if entry.get("faction"):
            parts.append(f'faction = "{entry["faction"]}"')
        return "    { " + ", ".join(parts) + " },"

    lines = [
        "-- Abilities.lua (Modern) -- GENERATED by tools/gen_modern_abilities.py from the original",
        "-- addon's PlayerAbilities.lua, do not hand-edit. See the script's own docstring for the",
        "-- category mapping and what's skipped (and why) rather than silently dropped.",
        "",
        "local addonName, addon = ...",
        "",
        "addon.Abilities = addon.Abilities or {}",
        "",
        "addon.Abilities.Teleports = {",
    ]
    lines += [fmt(e) for e in teleports]
    lines += ["}", "", "addon.Abilities.Hearthstones = {"]
    lines += [fmt(e) for e in hearthstones]
    lines += ["}", "", "addon.Abilities.Items = {"]
    lines += [fmt(e) for e in items]
    lines += ["}"]
    OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")

    notes = [
        "",
        "## Ability conversion (tools/gen_modern_abilities.py)",
        "",
        f"{len(teleports)} Teleports, {len(hearthstones)} Hearthstones, {len(items)} Items written.",
        "",
    ]
    if skipped_random:
        notes.append(f"- {len(skipped_random)} item(s) skipped: the old data itself flags them `isRandom` "
                      "(the client sends you to one of several unlisted spots at random -- not a promise a "
                      "deterministic search can make, unlike a real `destinations` list the player picks from):")
        for aid, name in skipped_random:
            notes.append(f"  - `{aid}` ({name})")
    if skipped_phase:
        notes.append(f"- {len(skipped_phase)} ability(ies) skipped: phase-gated (`destinationsByArtID`), "
                      "same open item as the phase-tagged nodes/edges from the earlier passes -- needs the "
                      "real phaseGroup/phaseSide wiring, not a coin-flip default:")
        for aid, name in skipped_phase:
            notes.append(f"  - `{aid}` ({name})")
    if dangling:
        notes.append(f"- {len(dangling)} ability(ies) dropped: their destination didn't resolve to a "
                      "converted node even after the rename (worth checking by hand):")
        for aid, dest in dangling:
            notes.append(f"  - `{aid}` -> `{dest}`")
    if not (skipped_random or skipped_phase or dangling):
        notes.append("- Nothing skipped or dangling.")

    # Idempotent: drop this script's own section from a prior run before appending the
    # fresh one, so re-running it alone doesn't pile up duplicate sections.
    heading = "## Ability conversion (tools/gen_modern_abilities.py)"
    existing = NOTES.read_text(encoding="utf-8") if NOTES.exists() else ""
    if heading in existing:
        existing = existing[:existing.index(heading)].rstrip("\n") + "\n"
    NOTES.write_text(existing + "\n".join(notes) + "\n", encoding="utf-8")

    print(f"wrote {len(teleports)} Teleports, {len(hearthstones)} Hearthstones, {len(items)} Items to {OUT}")
    print(f"{len(skipped_random)} skipped (isRandom), {len(skipped_phase)} skipped (phase-gated), "
          f"{len(dangling)} dangling -- see {NOTES}")


if __name__ == "__main__":
    main()
