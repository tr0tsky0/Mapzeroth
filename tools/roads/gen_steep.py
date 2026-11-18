"""Generate Data/Forever/Steep.lua: ground too steep to walk up, per continent, from Forever's own terrain heights.

    python tools/roads/gen_steep.py                # all continents (run after gen_roads.py: roads are kept clear)
    python tools/roads/gen_steep.py --view 31 37 40 45 0   # also render tiles x 31-36, y 40-44 of instance 0
                                                           # to tools/roads/steep_view.png (gitignored)

How: each root ADT's MCNK/MCVT outer heights (9x9 per chunk, ~4.17 yd apart) -> each quad's slope, the steepest of
its edges and diagonals -> steep where over LIMIT degrees -> 2x2 quads to one cell (~8.33 yd, 64 per tile) ->
closing (fills one-cell gaps in a cliff band) -> enclosed flat pockets up to FILL cells filled (a hilltop ringed by
cliffs can't be reached) -> pieces under MIN_CELLS dropped (rocks, banks) -> a corridor along every road in
Roads.lua cleared (a road is walkable whatever its banks).

Output: per continent { r0 = first row, "row", "row", ... }: row r covers world X from 32*TILE - r*CELL down by one
cell (southward); column c likewise world Y from 32*TILE - c*CELL (eastward). A row string is its steep runs as
(gap, length) pairs in cells, the first gap from column 0, each number base 32, low digit first: "0-9A-V" a last
digit, "W-Za-z-_" one with more to come.
"""
import os
import re
import struct
import sys
import time

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from casc import Casc                 # noqa: E402
from adt import Wdt, chunks, TILE     # noqa: E402
from raster import dilate, erode      # noqa: E402

REPO = os.path.dirname(os.path.dirname(HERE))
OUT = os.path.join(REPO, "Data", "Forever", "Steep.lua")
ROADS = os.path.join(REPO, "Data", "Forever", "Roads.lua")

Q = 128                 # quads per tile side
SP = TILE / Q           # ~4.17 yd
CPT = 64                # cells per tile side
CELL = TILE / CPT       # ~8.33 yd
ORIGIN = 32 * TILE
LIMIT = 50              # degrees: steeper ground can't be walked up
CLOSE = 1               # cells
FILL = 200              # cells (~14,000 sq yd): enclosed pockets up to this are filled
MIN_CELLS = 4
ROAD_CLEAR = 6.0        # yd either side of a road's centre-line

CONTINENTS = [          # (WDT file id, instance map id, name)
    (775971, 0, "Eastern Kingdoms"),
    (782779, 1, "Kalimdor"),
    (7198644, 2991, "Zephras Isle"),
]

DIGITS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_"


def tile_steep(d):
    """64x64 bool cells for one root ADT."""
    h = np.full((Q + 1, Q + 1), np.nan, np.float32)
    for cid, p, s in chunks(d):
        if cid != "MCNK":
            continue
        ix, iy = struct.unpack_from("<II", d, p + 4)
        z = struct.unpack_from("<f", d, p + 0x68 + 8)[0]
        for sid, q, sz in chunks(d, p + 128, p + s):
            if sid == "MCVT":
                v = np.frombuffer(d[q:q + 580], "<f4")
                outer = np.concatenate([v[r * 17:r * 17 + 9] for r in range(9)]).reshape(9, 9)
                h[iy * 8:iy * 8 + 9, ix * 8:ix * 8 + 9] = outer + z
                break
    a, b, c, e = h[:-1, :-1], h[:-1, 1:], h[1:, :-1], h[1:, 1:]
    with np.errstate(invalid="ignore"):
        g = np.nanmax(np.stack([np.abs(b - a), np.abs(e - c), np.abs(c - a), np.abs(e - b),
                                np.abs(e - a) / 2 ** 0.5, np.abs(c - b) / 2 ** 0.5]), axis=0) / SP
    steep = np.nan_to_num(g, nan=0.0) > np.tan(np.radians(LIMIT))
    return steep.reshape(CPT, 2, CPT, 2).any(axis=(1, 3))


def label(mask):
    """8-connected component labels (0 = background): each row's runs, joined (union-find) to the runs of the row
    above that touch them, diagonals included."""
    H, W = mask.shape
    parent = []

    def find(a):
        while parent[a] != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        return a
    rows = []                                    # per row: (starts, ends, run ids)
    prev = (np.zeros(0, int), np.zeros(0, int), [])
    for r in range(H):
        d = np.diff(np.concatenate([[0], mask[r].astype(np.int8), [0]]))
        s, e = np.nonzero(d == 1)[0], np.nonzero(d == -1)[0]
        ids = list(range(len(parent), len(parent) + len(s)))
        parent.extend(ids)
        ps, pe, pids = prev
        if len(ps) and len(s):
            # runs above touching [s-1, e]: those with ps <= e and pe >= s (end exclusive, so pe >= s means touching
            # diagonally at s-1)
            lo = np.searchsorted(pe, s, side="left")          # first run above ending at or after s
            hi = np.searchsorted(ps, e, side="right")         # past the last run above starting at or before e
            for k in range(len(s)):
                for j in range(lo[k], hi[k]):
                    a, b = find(ids[k]), find(pids[j])
                    if a != b:
                        parent[max(a, b)] = min(a, b)
        rows.append((s, e, ids))
        prev = (s, e, ids)
    root = np.array([find(i) for i in range(len(parent))], np.int64) + 1
    lab = np.zeros((H, W), np.int64)
    for r, (s, e, ids) in enumerate(rows):
        for k in range(len(s)):
            lab[r, s[k]:e[k]] = root[ids[k]]
    return lab


def road_polys(instance):
    text = open(ROADS, encoding="utf-8").read()
    m = re.search(r"\[%d\] = \{   -- .*?\n(.*?)\n    \}," % instance, text, re.S)
    if not m:
        return []
    out = []
    for line in m.group(1).splitlines():
        v = [int(t) for t in re.findall(r"-?\d+", line)]
        out.append(list(zip(v[0::2], v[1::2])))
    return out


def continent(c, wdt_id, instance, log):
    t0 = time.time()
    w = Wdt(c.read_fdid(wdt_id))
    tiles = [k for k, e in w.maid.items() if e[0]]
    xs, ys = [k[0] for k in tiles], [k[1] for k in tiles]
    tx0, ty0 = min(xs), min(ys)
    W, H = (max(xs) - tx0 + 1) * CPT, (max(ys) - ty0 + 1) * CPT
    steep = np.zeros((H, W), bool)
    for (x, y) in tiles:
        d = c.read_fdid(w.maid[(x, y)][0])
        if d:
            steep[(y - ty0) * CPT:(y - ty0 + 1) * CPT, (x - tx0) * CPT:(x - tx0 + 1) * CPT] = tile_steep(d)
    log("  %d tiles, %.1f%% steep (%.0fs)" % (len(tiles), 100 * steep.mean(), time.time() - t0))
    if CLOSE:
        steep = erode(dilate(steep, CLOSE), CLOSE)
    bg = label(~steep)
    edge = np.unique(np.concatenate([bg[0], bg[-1], bg[:, 0], bg[:, -1]]))
    sizes = np.bincount(bg.ravel())
    steep |= (bg > 0) & (sizes[bg] <= FILL) & ~np.isin(bg, edge)
    lab = label(steep)
    steep &= np.bincount(lab.ravel())[lab] >= MIN_CELLS
    r0, c0 = ty0 * CPT, tx0 * CPT
    img = Image.new("L", (W, H), 0)
    draw = ImageDraw.Draw(img)
    width = max(1, round(2 * ROAD_CLEAR / CELL)) + 1
    for p in road_polys(instance):
        draw.line([((ORIGIN - wy) / CELL - c0, (ORIGIN - wx) / CELL - r0) for wx, wy in p], fill=255, width=width)
    steep &= np.asarray(img) == 0
    log("  cleaned: %.1f%% steep (%.0fs)" % (100 * steep.mean(), time.time() - t0))
    return steep, r0, c0


def number(v):
    s = ""
    while v >= 32:
        s += DIGITS[32 + v % 32]
        v //= 32
    return s + DIGITS[v]


def encode(steep, r0, c0):
    rows = []
    for r in range(steep.shape[0]):
        d = np.diff(np.concatenate([[0], steep[r].astype(np.int8), [0]]))
        starts, ends = np.nonzero(d == 1)[0], np.nonzero(d == -1)[0]
        s, prev = "", -c0
        for a, b in zip(starts.tolist(), ends.tolist()):
            s += number(a - prev) + number(b - a)    # gap from the last run's end (the first: from column 0)
            prev = b
        rows.append(s)
    while rows and not rows[-1]:
        rows.pop()
    first = 0
    while first < len(rows) and not rows[first]:
        first += 1
    return r0 + first, rows[first:]


def view(args):
    x0, x1, y0, y1, instance = map(int, args)
    wdt_id = next(w for w, i, _ in CONTINENTS if i == instance)
    c = Casc()
    w = Wdt(c.read_fdid(wdt_id))
    steep, r0, c0 = continent(c, wdt_id, instance, print)
    import io
    P = 2 * CPT
    mos = Image.new("RGB", ((x1 - x0) * P, (y1 - y0) * P), "black")
    for x in range(x0, x1):
        for y in range(y0, y1):
            e = w.maid.get((x, y))
            d = e and c.read_fdid(e[7])
            if d:
                mos.paste(Image.open(io.BytesIO(d)).convert("RGB").resize((P, P)), ((x - x0) * P, (y - y0) * P))
    a = np.asarray(mos).astype(np.float32)
    s = steep[y0 * CPT - r0:y1 * CPT - r0, x0 * CPT - c0:x1 * CPT - c0]
    s = np.repeat(np.repeat(s, 2, 0), 2, 1)
    a[s] = a[s] * 0.35 + np.array([255, 0, 0]) * 0.65
    im = Image.fromarray(a.astype(np.uint8))
    draw = ImageDraw.Draw(im)
    for p in road_polys(instance):
        draw.line([((ORIGIN - wy) / CELL * 2 - x0 * P, (ORIGIN - wx) / CELL * 2 - y0 * P) for wx, wy in p],
                  fill=(0, 200, 255), width=2)
    im.save(os.path.join(HERE, "steep_view.png"))


def main():
    if "--view" in sys.argv:
        i = sys.argv.index("--view")
        return view(sys.argv[i + 1:i + 6])
    t0 = time.time()
    c = Casc()
    L = [
        "-- Steep.lua (Forever) -- GENERATED by tools/roads/gen_steep.py from the game's own terrain, do not hand-edit.",
        "-- Ground too steep to walk up, per continent: RoadNet keeps walks off it. Rows of %.4f-yd cells from" % CELL,
        "-- world X %.4f southward; each row is its steep runs, (gap, length) in cells from world Y %.4f eastward," % (ORIGIN, ORIGIN),
        "-- each number base 32, low digit first, \"0-9A-V\" a last digit and \"W-Za-z-_\" one with more to come.",
        "",
        "local addonName, addon = ...",
        'if addon.RULESET ~= "forever" then return end   -- one addon for both games: this data is Forever\'s (Constants.lua)',
        "",
        "addon.RoadSteep = {",
        "    cell = %.6f, origin = %.6f," % (CELL, ORIGIN),
    ]
    for wdt_id, instance, name in CONTINENTS:
        print("%s (WDT %d, instance %d)" % (name, wdt_id, instance), flush=True)
        steep, r0, c0 = continent(c, wdt_id, instance, lambda s: print(s, flush=True))
        first, rows = encode(steep, r0, c0)
        L.append("    [%d] = { r0 = %d,   -- %s" % (instance, first, name))
        for k in range(0, len(rows), 8):
            L.append("        " + " ".join('"%s",' % s for s in rows[k:k + 8]))
        L.append("    },")
    L.append("}")
    text = "\n".join(L) + "\n"
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    print("wrote %s (%.0f KB) in %.0fs" % (os.path.relpath(OUT, REPO), len(text) / 1024, time.time() - t0))


if __name__ == "__main__":
    main()
