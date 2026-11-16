"""Review sheet for road-texture candidates: swatch + where it is painted (3x3 tiles over minimap)."""
import io
import json
import sys
import numpy as np
from PIL import Image, ImageDraw
from casc import Casc
from adt import Wdt, Tex0

MIN_AREA = 2000
MIN_THIN = 0.5
P = 128  # px per tile in the crop


def main(wdt_fdid, start=0, count=30):
    r = json.load(open("texture_scores_%d.json" % wdt_fdid))
    cands = sorted([(f, v) for f, v in r.items() if v["area"] >= MIN_AREA and v["thinC5"] >= MIN_THIN],
                   key=lambda kv: -kv[1]["thinC5"])
    print("candidates", len(cands))
    cands = cands[start:start + count]
    c = Casc()
    w = Wdt(c.read_fdid(wdt_fdid))
    tex_cache, mm_cache = {}, {}

    def tex0(x, y):
        if (x, y) not in tex_cache:
            e = w.maid.get((x, y))
            d = e and c.read_fdid(e[3])
            tex_cache[(x, y)] = Tex0(d, w.big_alpha) if d else None
        return tex_cache[(x, y)]

    def minimap(x, y):
        if (x, y) not in mm_cache:
            e = w.maid.get((x, y))
            d = e and c.read_fdid(e[7])
            mm_cache[(x, y)] = Image.open(io.BytesIO(d)).convert("RGB").resize((P, P)) if d else Image.new("RGB", (P, P))
        return mm_cache[(x, y)]

    S = 3 * P
    cols = 5
    rows = (len(cands) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * S, rows * (S + 16)), "white")
    dr = ImageDraw.Draw(sheet)
    for i, (f, v) in enumerate(cands):
        fid = int(f)
        # centre the crop on the 3x3 window with most painted area
        per = {(x, y): a for x, y, a, _ in v["per_tile"]}
        best = max(per, key=lambda t: sum(per.get((t[0] + dx, t[1] + dy), 0) for dx in (-1, 0, 1) for dy in (-1, 0, 1)))
        crop = Image.new("RGB", (S, S))
        mask = np.zeros((S, S), np.float32)
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                x, y = best[0] + dx, best[1] + dy
                crop.paste(minimap(x, y), ((dx + 1) * P, (dy + 1) * P))
                t = tex0(x, y)
                if t and fid in t.textures:
                    m = t.weight({t.textures.index(fid)}).reshape(P, 1024 // P, P, 1024 // P).max(axis=(1, 3))
                    mask[(dy + 1) * P:(dy + 2) * P, (dx + 1) * P:(dx + 2) * P] = m
        a = np.asarray(crop).astype(np.float32) * 0.75
        mm = np.clip(mask, 0, 1)[..., None]
        a = a * (1 - mm) + np.array([255, 0, 255], np.float32) * mm
        img = Image.fromarray(a.astype(np.uint8))
        try:
            sw = Image.open(io.BytesIO(c.read_fdid(fid))).convert("RGB").resize((72, 72))
            img.paste(sw, (S - 74, 2))
        except Exception:
            pass
        rr, k = divmod(i, cols)
        sheet.paste(img, (k * S, rr * (S + 16) + 16))
        dr.text((k * S + 3, rr * (S + 16) + 2), "%s thin %.2f area %d tiles %d @%d,%d" % (f, v["thinC5"], v["area"], v["tiles"], best[0], best[1]), fill="black")
    out = "review_%d_%d.png" % (wdt_fdid, start)
    sheet.save(out)
    print(out)


if __name__ == "__main__":
    main(int(sys.argv[1]), int(sys.argv[2]) if len(sys.argv) > 2 else 0, int(sys.argv[3]) if len(sys.argv) > 3 else 30)
