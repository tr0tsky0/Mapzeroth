"""Converts a Data/<ruleset>/Geometry.lua in the old expanded form into the packed form
(`addon.GeometryPacked`, see TravelGraph.lua) without a trip into the game:

    python tools/pack_geometry.py Data/Modern/Geometry.lua

/mzr dumpgeometry writes the packed form itself; this is for files dumped before that. Each edge must have an
identical reverse (it's stored once and mirrored), or the conversion stops.
"""
import re
import sys


def num(x):
    t = f"{x:.1f}"
    return t[:-2] if t.endswith(".0") else t


def convert(text):
    ruleset = re.search(r'RULESET ~= "(\w+)"', text).group(1)
    header = text[:text.index("local addonName")].replace("(walk/gate/fly edges):", "(walk/gate/fly edges), packed:")
    node_count = int(re.search(r"nodeCount = (\d+)", text).group(1))
    geo = {}
    for m in re.finditer(r'\["([^"]+)"\] = \{(.*)\},?\n', text):
        geo[m.group(1)] = [(a, float(d), k) for a, d, k in re.findall(r'\{"([^"]+)",([0-9.]+),"(\w+)"\}', m.group(2))]
    ids = sorted(geo)
    index = {i: n + 1 for n, i in enumerate(ids)}
    # Rounded the way the dump rounds (one decimal, ".0" dropped); the reverse must match after rounding.
    lookup = {(a, b, k): num(d) for a, l in geo.items() for b, d, k in l}
    for (a, b, k), d in lookup.items():
        if lookup.get((b, a, k)) != d:
            sys.exit(f"{a} -> {b} ({k}) has no identical reverse")
    out = [header.rstrip("\n"), "", "local addonName, addon = ...",
           f'if addon.RULESET ~= "{ruleset}" then return end   -- one addon for both games: this data is {ruleset.capitalize()}\'s (Constants.lua)',
           "", "addon.GeometryPacked = {", f"    nodeCount = {node_count},", "    ids = {"]
    for i in range(0, len(ids), 4):
        out.append("        " + ", ".join(f'"{x}"' for x in ids[i:i + 4]) + ",")
    out.append("    },")
    for kind in ("walk", "gate", "fly"):
        rows = []
        for a in ids:
            parts = [f"{index[b]},{lookup[(a, b, k)]}" for b, d, k in geo[a] if k == kind and index[b] > index[a]]
            if parts:
                rows.append(f"        {{ {index[a]}, {', '.join(parts)} }},")
        if rows:
            out += [f"    {kind} = {{"] + rows + ["    },"]
    out.append("}")
    return "\n".join(out) + "\n"


if __name__ == "__main__":
    path = sys.argv[1]
    with open(path, encoding="utf-8") as f:
        text = f.read()
    if "addon.GeometryPacked" in text:
        sys.exit("already packed")
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(convert(text))
