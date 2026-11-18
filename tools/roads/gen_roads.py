"""Generate Data/Forever/Roads.lua: road centre-lines per continent, from Forever's own terrain files.

    python tools/roads/gen_roads.py            # reads D:\\World of Warcraft (product wowf)
    python tools/roads/gen_roads.py --only 2991    # rebuild one continent, keep the others as Roads.lua has them
                                                   # (no report written)

How: each map tile's ground-texture alpha (tex0 ADT) for the reviewed road textures in
road_textures.json (see autopick.py / review.py for how that list is made) -> mask at ~2 yd/px ->
closing -> Zhang-Suen thinning, in 8x8-tile blocks with a 1-tile margin -> one skeleton per continent ->
graph: trace, contract junction clusters, drop tiny loops, prune spurs, join facing dead ends (bridges are
models, not painted road), join remaining dead ends to nearby road, drop small pieces -> Douglas-Peucker.
Then any hand-drawn links for the continent (tools/roads/links/<zone>.json, see links/zones.py) are added, each
end snapped onto the nearest road.

Output coordinates are world yards as C_Map.GetWorldPosFromMapPos gives them: x = world X (north),
y = world Y (west), keyed by the continent's instance map id (0 Eastern Kingdoms, 1 Kalimdor).
Report: tools/roads_report.txt.
"""
import json
import os
import sys
import time
from collections import defaultdict

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from casc import Casc            # noqa: E402
from adt import Wdt, Tex0, TILE  # noqa: E402
from raster import dilate, erode, thin  # noqa: E402
sys.path.insert(0, os.path.join(HERE, "links"))
import zones as link_zones       # noqa: E402

REPO = os.path.dirname(os.path.dirname(HERE))
OUT = os.path.join(REPO, "Data", "Forever", "Roads.lua")
REPORT = os.path.join(REPO, "tools", "roads_report.txt")

R = 256                 # px per tile (~2.08 yd)
YD = TILE / R
THRESH = 0.35           # road weight at full alpha resolution
BLOCK = 8               # tiles per processing block (plus a 1-tile margin each side)
SHORT = 3               # px: junction-to-junction edges this short are contracted
MIN_SPUR = 14           # px (~29 yd): dead-end stubs shorter than this go
LOOP = 60               # px: closed loops shorter than this go (town plazas)
END_GAP = 60            # px (~125 yd): two dead ends facing each other are joined (bridges)
GAP = 28                # px (~58 yd): a dead end is joined to the nearest road ahead within this
MIN_COMP = 80           # px (~165 yd): pieces shorter than this in total go
DP_EPS = 1.5            # px (~3 yd)

CONTINENTS = [          # (WDT file id, instance map id, name, {build overrides})
    (775971, 0, "Eastern Kingdoms", {}),
    (782779, 1, "Kalimdor", {}),
    # Zephras Isle's two bridges are longer than the defaults reach: the lake bridge on the north-south road
    # (~140 yd, end to end) and the river bridge south of Shen'dar (~95 yd, landing on a bend, not a dead end).
    (7198644, 2991, "Zephras Isle", {"end_gap": 80, "gap": 50}),
]


# ---------------------------------------------------------------- skeleton
def continent_skeleton(c, wdt_id, roads, log):
    w = Wdt(c.read_fdid(wdt_id))
    tiles = sorted(w.maid)
    masks = {}
    t0 = time.time()
    for (x, y) in tiles:
        d = c.read_fdid(w.maid[(x, y)][3])
        if not d:
            continue
        t = Tex0(d, w.big_alpha)
        wanted = {i for i, fid in enumerate(t.textures) if fid in roads}
        if not wanted:
            continue
        m = (t.weight(wanted) >= THRESH).reshape(R, 4, R, 4).any(axis=(1, 3))
        if m.any():
            masks[(x, y)] = m
    log("  %d tiles, %d with road (%.0fs)" % (len(tiles), len(masks), time.time() - t0))
    xs = [k[0] for k in masks]
    ys = [k[1] for k in masks]
    pixels = set()
    for bx in range(min(xs), max(xs) + 1, BLOCK):
        for by in range(min(ys), max(ys) + 1, BLOCK):
            if not any((x, y) in masks for x in range(bx, bx + BLOCK) for y in range(by, by + BLOCK)):
                continue
            n = BLOCK + 2
            big = np.zeros((n * R, n * R), bool)
            for i in range(n):
                for j in range(n):
                    m = masks.get((bx - 1 + i, by - 1 + j))
                    if m is not None:
                        big[j * R:(j + 1) * R, i * R:(i + 1) * R] = m
            sk = thin(erode(dilate(big, 4), 3))
            inner = sk[R:(n - 1) * R, R:(n - 1) * R]
            py, px = np.nonzero(inner)
            gy0, gx0 = by * R, bx * R
            pixels.update(zip((py + gy0).tolist(), (px + gx0).tolist()))
    log("  skeleton %d px (%.0fs)" % (len(pixels), time.time() - t0))
    return pixels


# ---------------------------------------------------------------- graph
class Graph:
    def __init__(self):
        self.edges = {}
        self.at = defaultdict(set)
        self.nid = 0

    def add(self, poly):
        e = self.nid
        self.nid += 1
        self.edges[e] = poly
        self.at[poly[0]].add(e)
        self.at[poly[-1]].add(e)
        return e

    def remove(self, e):
        poly = self.edges.pop(e)
        for n in (poly[0], poly[-1]):
            s = self.at.get(n)
            if s is not None:
                s.discard(e)
                if not s:
                    del self.at[n]
        return poly

    def deg(self, n):
        return sum(2 if self.edges[e][0] == self.edges[e][-1] else 1 for e in self.at.get(n, ()))

    @staticmethod
    def length(poly):
        a = np.asarray(poly, float)
        return float(np.hypot(*np.diff(a, axis=0).T).sum()) if len(a) > 1 else 0.0


def trace(pixels):
    adj = {}
    for (y, x) in pixels:
        nb = []
        for dy, dx in ((0, 1), (1, 0), (0, -1), (-1, 0)):
            if (y + dy, x + dx) in pixels:
                nb.append((y + dy, x + dx))
        for dy, dx in ((1, 1), (1, -1), (-1, 1), (-1, -1)):
            if (y + dy, x + dx) in pixels and (y + dy, x) not in pixels and (y, x + dx) not in pixels:
                nb.append((y + dy, x + dx))
        adj[(y, x)] = nb
    g = Graph()
    nodes = {p for p, n in adj.items() if len(n) != 2}
    seen = set()
    for n in nodes:
        for q in adj[n]:
            if (n, q) in seen:
                continue
            path, prev, cur = [n, q], n, q
            while cur not in nodes:
                nxt = [r for r in adj[cur] if r != prev]
                if not nxt:
                    break
                prev, cur = cur, nxt[0]
                path.append(cur)
                if cur == n:
                    break
            seen.add((n, q))
            seen.add((path[-1], path[-2]))
            g.add(path)
    return g


def merge_deg2(g):
    changed = True
    while changed:
        changed = False
        for n in list(g.at):
            es = list(g.at.get(n, ()))
            if len(es) != 2:
                continue
            p1, p2 = g.edges[es[0]], g.edges[es[1]]
            if p1[0] == p1[-1] or p2[0] == p2[-1]:
                continue
            if p1[-1] != n:
                p1 = p1[::-1]
            if p2[0] != n:
                p2 = p2[::-1]
            g.remove(es[0])
            g.remove(es[1])
            g.add(p1 + p2[1:])
            changed = True


def contract_short(g):
    for e in list(g.edges):
        p = g.edges.get(e)
        if not p:
            continue
        a, b = p[0], p[-1]
        if a == b or len(p) > SHORT + 1 or (g.deg(a) < 3 and g.deg(b) < 3):
            continue
        g.remove(e)
        for e2 in list(g.at.get(b, ())):
            q = g.remove(e2)
            q = [a if q[0] == b else q[0]] + q[1:-1] + [a if q[-1] == b else q[-1]]
            g.add(q)


def drop_loops(g):
    for e in list(g.edges):
        p = g.edges.get(e)
        if p and p[0] == p[-1] and g.length(p) < LOOP:
            g.remove(e)


def prune_spurs(g):
    changed = True
    while changed:
        changed = False
        for e in list(g.edges):
            p = g.edges.get(e)
            if not p:
                continue
            da, db = g.deg(p[0]), g.deg(p[-1])
            if (da == 1) != (db == 1) and g.length(p) < MIN_SPUR:
                g.remove(e)
                changed = True
        merge_deg2(g)


def heading(g, n):
    (e0,) = tuple(g.at[n])
    p = g.edges[e0]
    t = p if p[0] == n else p[::-1]
    v = np.array(n, float) - np.array(t[min(10, len(t) - 1)], float)
    return v / (np.hypot(*v) or 1.0), e0, t


def bridge_ends(g, END_GAP=END_GAP):
    ends = [n for n in g.at if g.deg(n) == 1]
    cell = defaultdict(list)
    for n in ends:
        cell[(n[0] // END_GAP, n[1] // END_GAP)].append(n)
    head = {n: heading(g, n)[0] for n in ends}
    pairs = []
    for a in ends:
        cy, cx = a[0] // END_GAP, a[1] // END_GAP
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                for b in cell.get((cy + dy, cx + dx), ()):
                    if b <= a:
                        continue
                    d = np.array(b, float) - np.array(a, float)
                    L = np.hypot(*d)
                    if L == 0 or L > END_GAP:
                        continue
                    u = d / L
                    if head[a] @ u >= 0.6 and head[b] @ -u >= 0.6:
                        pairs.append((L, a, b))
    used, n = set(), 0
    for L, a, b in sorted(pairs):
        if a in used or b in used:
            continue
        g.add([a, b])
        used |= {a, b}
        n += 1
    return n


class UF:
    def __init__(self):
        self.p = {}

    def find(self, x):
        p = self.p
        while p.setdefault(x, x) != x:
            p[x] = p[p[x]]
            x = p[x]
        return x

    def union(self, a, b):
        self.p[self.find(a)] = self.find(b)


def bridge_gaps(g, C=GAP):
    grid = defaultdict(list)

    def register(e):
        for v in g.edges[e]:
            grid[(v[0] // C, v[1] // C)].append((v, e))
    for e in list(g.edges):
        register(e)
    uf = UF()
    for p in g.edges.values():
        uf.union(p[0], p[-1])
    added = 0
    for n in [n for n in g.at if g.deg(n) == 1]:
        if g.deg(n) != 1:
            continue
        u, e0, tail = heading(g, n)
        cy, cx = n[0] // C, n[1] // C
        best = None
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                for v, e in grid.get((cy + dy, cx + dx), ()):
                    if e == e0 or e not in g.edges:
                        continue
                    d = np.array(v, float) - np.array(n, float)
                    L = float(np.hypot(*d))
                    if L == 0 or L > C or d @ u < -2:
                        continue
                    same = uf.find(v) == uf.find(n) if v in uf.p else False
                    score = L * (1.6 if same else 1.0)
                    if (same and L * 1.6 > C):
                        continue
                    if best is None or score < best[0]:
                        best = (score, v, e)
        if best is None:
            continue
        _, v, te = best
        tp = g.edges[te]
        if v not in (tp[0], tp[-1]):
            k = tp.index(v)
            g.remove(te)
            register(g.add(tp[:k + 1]))
            register(g.add(tp[k:]))
        register(g.add([n, v]))
        uf.union(n, v)
        added += 1
    return added


def drop_small(g):
    uf = UF()
    for p in g.edges.values():
        uf.union(p[0], p[-1])
    total = defaultdict(float)
    for e, p in g.edges.items():
        total[uf.find(p[0])] += g.length(p)
    for e in list(g.edges):
        if total[uf.find(g.edges[e][0])] < MIN_COMP:
            g.remove(e)


def dp(points, eps=DP_EPS):
    if len(points) < 3:
        return list(points)
    P = np.asarray(points, float)
    a, b = P[0], P[-1]
    ab = b - a
    L = np.hypot(*ab)
    d = np.hypot(*(P - a).T) if L == 0 else np.abs(ab[0] * (P[:, 1] - a[1]) - ab[1] * (P[:, 0] - a[0])) / L
    i = int(np.argmax(d))
    if d[i] > eps:
        return dp(points[:i + 1], eps)[:-1] + dp(points[i:], eps)
    return [points[0], points[-1]]


def world(p):
    gy, gx = p
    return round(32 * TILE - gy * YD), round(32 * TILE - gx * YD)


def build(pixels, log, end_gap=END_GAP, gap=GAP):
    g = trace(pixels)
    log("  traced %d edges" % len(g.edges))
    contract_short(g)
    merge_deg2(g)
    drop_loops(g)
    prune_spurs(g)
    log("  joined %d facing ends, %d ends to nearby road" % (bridge_ends(g, end_gap), bridge_gaps(g, gap)))
    merge_deg2(g)
    prune_spurs(g)
    drop_loops(g)
    drop_small(g)
    merge_deg2(g)
    polys = []
    for p in g.edges.values():
        q = [world(v) for v in dp(p)]
        q = [v for i, v in enumerate(q) if i == 0 or v != q[i - 1]]
        if len(q) >= 2:
            polys.append(q)
    return polys


def add_links(polys, instance, log):
    """Hand-drawn links for this continent, each end snapped onto the nearest road (a point put into that road's
    line when it falls between two of its points), so RoadNet joins them: it joins lines where they share a point."""
    for name, zone in link_zones.ZONES.items():
        path = link_zones.lines_path(name)
        if zone["instance"] != instance or not os.path.exists(path):
            continue
        drawn = json.load(open(path, encoding="utf-8"))
        links = [[tuple(round(v) for v in link_zones.px_to_world(zone, x, y)) for x, y in line] for line in drawn]
        snapped = 0
        for link in links:
            for end in (0, -1):
                p = np.array(link[end], float)
                best = None
                for pi, poly in enumerate(polys):
                    for k in range(len(poly) - 1):
                        a, b = np.array(poly[k], float), np.array(poly[k + 1], float)
                        ab = b - a
                        t = min(1.0, max(0.0, float((p - a) @ ab) / (float(ab @ ab) or 1.0)))
                        q = a + ab * t
                        d = float(np.hypot(*(p - q)))
                        if d <= link_zones.SNAP_YD and (best is None or d < best[0]):
                            best = (d, pi, k, t, (round(q[0]), round(q[1])))
                if best is None:
                    continue
                _, pi, k, t, q = best
                poly = polys[pi]
                if q not in (poly[k], poly[k + 1]):
                    poly.insert(k + 1, q)
                link[end] = q
                snapped += 1
        links = [[v for i, v in enumerate(l) if i == 0 or v != l[i - 1]] for l in links]
        polys.extend(l for l in links if len(l) >= 2)
        log("  %s: %d hand-drawn links, %d ends joined to road" % (name, len(links), snapped))


def water_shapes(log):
    """instance -> [shore polygon in world yards], from every zone's hand-drawn <zone>_water.json."""
    out = defaultdict(list)
    for name, zone in link_zones.ZONES.items():
        path = link_zones.water_path(name)
        if not os.path.exists(path):
            continue
        for line in json.load(open(path, encoding="utf-8")):
            poly = [tuple(round(v) for v in link_zones.px_to_world(zone, x, y)) for x, y in line]
            if len(poly) > 1 and poly[-1] == poly[0]:
                poly.pop()
            poly = [v for i, v in enumerate(poly) if i == 0 or v != poly[i - 1]]
            if len(poly) >= 3:
                out[zone["instance"]].append(poly)
        log("%s water: %d shapes" % (name, len(out[zone["instance"]])))
    return out


def existing_roads():
    """instance -> (name, polys) as Roads.lua has them now (for --only)."""
    import re
    text = open(OUT, encoding="utf-8").read()
    out = {}
    for m in re.finditer(r"\[(\d+)\] = \{   -- (.*?)\n(.*?)\n    \},", text, re.S):
        polys = []
        for line in m.group(3).splitlines():
            v = [int(t) for t in re.findall(r"-?\d+", line)]
            polys.append(list(zip(v[0::2], v[1::2])))
        out[int(m.group(1))] = (m.group(2), polys)
    return out


def main():
    t0 = time.time()
    lines = []
    only = int(sys.argv[sys.argv.index("--only") + 1]) if "--only" in sys.argv else None

    def log(s):
        print(s, flush=True)
        lines.append(s)
    allow = json.load(open(os.path.join(HERE, "road_textures.json")))
    c = Casc()
    out = existing_roads() if only is not None else {}
    for wdt_id, instance, name, opts in CONTINENTS:
        if only is not None and instance != only:
            continue
        log("%s (WDT %d, instance %d)" % (name, wdt_id, instance))
        pixels = continent_skeleton(c, wdt_id, set(allow[str(wdt_id)]["roads"]), log)
        polys = build(pixels, log, **opts)
        add_links(polys, instance, log)
        verts = sum(len(p) for p in polys)
        length = sum(Graph.length(p) for p in polys)
        log("  %d polylines, %d points, %.0f yd of road" % (len(polys), verts, length))
        out[instance] = (name, sorted(polys))
    L = [
        "-- Roads.lua (Forever) -- GENERATED by tools/roads/gen_roads.py from the game's own terrain, do not hand-edit.",
        "-- Road centre-lines per continent, in world yards as C_Map.GetWorldPosFromMapPos gives them",
        "-- ({ x1, y1, x2, y2, ... }, x north, y west). RoadNet.lua draws walks along them and prices walk legs.",
        "",
        "local addonName, addon = ...",
        'if addon.RULESET ~= "forever" then return end   -- one addon for both games: this data is Forever\'s (Constants.lua)',
        "",
        "addon.RoadData = {",
    ]
    for instance, (name, polys) in sorted(out.items()):
        L.append("    [%d] = {   -- %s" % (instance, name))
        for p in polys:
            L.append("        { " + ",".join("%d,%d" % v for v in p) + " },")
        L.append("    },")
    L.append("}")
    water = water_shapes(log)
    if water:
        L += ["", "-- Big water, swum rather than run across (RoadNet.WATER, RoadNet.SWIM): shores drawn by hand",
              "-- (tools/roads/links/<zone>_water.json), { x1, y1, x2, y2, ... } closed back to the first point.",
              "addon.RoadWater = {"]
        for instance, polys in sorted(water.items()):
            L.append("    [%d] = {" % instance)
            for p in polys:
                L.append("        { " + ",".join("%d,%d" % v for v in p) + " },")
            L.append("    },")
        L.append("}")
    text = "\n".join(L) + "\n"
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    log("wrote %s (%.0f KB) in %.0fs" % (os.path.relpath(OUT, REPO), len(text) / 1024, time.time() - t0))
    if only is None:                         # a one-continent run would leave the others out of the report
        with open(REPORT, "w", encoding="utf-8", newline="\n") as f:
            f.write("\n".join(lines) + "\n")


if __name__ == "__main__":
    main()
