"""Score every ground texture on a continent by how road-like its painted coverage is.

Per tile and texture: mask = weight >= THRESH at ~2 yd/px, opened by 1 px to drop speckle.
  area    = core pixels
  thick   = core pixels that survive erosion by 4 px (wide patches survive, ~2-8 px roads don't)
  long    = core pixels in connected pieces whose bounding box spans >= LONG px
Summed over the continent:
  thin_frac = 1 - thick / area     (road ~1, ground cover low)
  long_frac = long / area          (road high, decals/speckle low)
Writes texture_scores_<map>.json.
"""
import json
import sys
import time
import numpy as np
from PIL import Image, ImageDraw
from casc import Casc
from adt import Wdt, Tex0
from raster import dilate, erode
THRESH = 0.35

R = 256
LONG = 50  # px, ~104 yd


def long_pixels(core):
    """Pixels belonging to connected pieces whose bbox spans >= LONG px (8-connected via floodfill)."""
    H, W = core.shape
    img = Image.fromarray(core.astype(np.uint8) * 255, "L").convert("RGB")
    ys, xs = np.nonzero(core)
    label = 1
    seen = np.zeros_like(core)
    total = 0
    arr = None
    for y, x in zip(ys.tolist(), xs.tolist()):
        if seen[y, x]:
            continue
        col = (label & 255, (label >> 8) & 255, (label >> 16) & 255 or 1)
        ImageDraw.floodfill(img, (x, y), col)
        arr = np.asarray(img)
        m = (arr[..., 0] == col[0]) & (arr[..., 1] == col[1]) & (arr[..., 2] == col[2])
        seen |= m
        py, px = np.nonzero(m)
        if max(py.max() - py.min(), px.max() - px.min()) >= LONG:
            total += int(m.sum())
        label += 1
    return total


def score(wdt_fdid, out):
    """Per texture: painted px (w>=0.2), closed px (closing r=5), closed px surviving erosion r=5."""
    t0 = time.time()
    c = Casc()
    w = Wdt(c.read_fdid(wdt_fdid))
    acc = {}
    tiles = sorted(w.maid)
    for n, (x, y) in enumerate(tiles):
        d = c.read_fdid(w.maid[(x, y)][3])
        if not d:
            continue
        t = Tex0(d, w.big_alpha)
        for ti, fid in enumerate(t.textures):
            m = t.weight({ti}).reshape(R, 4, R, 4).max(axis=(1, 3)) >= 0.2
            a = int(m.sum())
            if a == 0:
                continue
            cl = erode(dilate(m, 5), 5) | m
            ca = int(cl.sum())
            thick = int(erode(cl, 5).sum())
            s = acc.setdefault(fid, [0, 0, 0, 0, []])
            s[0] += a; s[1] += ca; s[2] += thick; s[3] += 1
            s[4].append((x, y, a, round(1 - thick / ca, 2)))
        if n % 50 == 0:
            print("%d/%d tiles %.0fs" % (n, len(tiles), time.time() - t0), flush=True)
    res = {}
    for fid, (a, ca, thick, nt, per) in acc.items():
        res[fid] = dict(area=a, thinC5=round(1 - thick / ca, 3), tiles=nt, per_tile=per)
    with open(out, "w") as f:
        json.dump(res, f)
    print("done %.0fs, %d textures" % (time.time() - t0, len(res)))


if __name__ == "__main__":
    fdid = int(sys.argv[1]) if len(sys.argv) > 1 else 775971
    score(fdid, "texture_scores_%d.json" % fdid)
