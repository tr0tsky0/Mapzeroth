"""tools/strip_geometry_phase_fly.py -- removes the `fly` entries that touch a phase-split container from the
shipped Data/Modern/Geometry.lua.

TravelGraph.lua's fly pass now leaves out every node whose container path has `_art` in it (one state of a
phase-split zone: Zidormi's past or present -- finding 3 of docs/REVIEW-2026-09-24.md), but the shipped Geometry.lua
was dumped before that and still holds fly entries into and out of those nodes. Its node count still matches, so it
is used as it stands. This drops those entries so it agrees with what the live pass would now compute, without a
re-dump in the retail client (which should still be done at the next opportunity: /mzr dumpgeometry).

    python tools/strip_geometry_phase_fly.py

Only `fly` entries whose own node or destination is in an `_art` container are removed; walk and gate entries, the
file's layout and its `nodeCount` are left as they are. Node -> container comes from Data/Modern/Nodes_*.lua.
Running it again changes nothing.
"""
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
DATA = ROOT / "Data" / "Modern"
GEOMETRY = DATA / "Geometry.lua"

NODE = re.compile(r'\{ id = "([^"]+)", container = "([^"]+)"')
ROW = re.compile(r'^(\s*\["([^"]+)"\] = )\{ (.*) \}(,?)(\r?)$')
ENTRY = re.compile(r'\{"([^"]+)",[^,]+,"([a-z]+)"\}')


def phase_nodes():
    """Ids of the nodes whose container path contains `_art`."""
    ids = set()
    for path in sorted(DATA.glob("Nodes_*.lua")):
        for line in path.read_text(encoding="utf-8").splitlines():
            m = NODE.match(line.strip())
            if m and "_art" in m.group(2):
                ids.add(m.group(1))
    return ids


def main():
    phased = phase_nodes()
    text = GEOMETRY.read_text(encoding="utf-8", newline="")
    out, removed = [], 0
    for line in text.split("\n"):
        m = ROW.match(line)
        if m:
            prefix, from_id, body, comma, cr = m.groups()
            kept = []
            for entry in re.findall(r'\{[^{}]*\}', body):
                e = ENTRY.fullmatch(entry)
                if e and e.group(2) == "fly" and (from_id in phased or e.group(1) in phased):
                    removed += 1
                    continue
                kept.append(entry)
            line = prefix + ("{ " + ",".join(kept) + " }" if kept else "{ }") + comma + cr
        out.append(line)
    GEOMETRY.write_text("\n".join(out), encoding="utf-8", newline="")
    print(f"{len(phased)} node(s) in phase-split containers; removed {removed} fly entr(y/ies) from {GEOMETRY.name}")


if __name__ == "__main__":
    main()
