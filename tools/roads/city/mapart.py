"""A city's world map art as one picture, from the Forever client's own tables (UiMapXMapArt -> UiMapArtTile).

    python tools/roads/city/mapart.py <name>        # writes art/<name>.png (1002 x 668, the map's 0-1)
"""
import io
import os
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
sys.path.insert(0, HERE)
from casc import Casc                    # noqa: E402
import wdc5                              # noqa: E402
from cities import CITIES, ART, ART_W, ART_H   # noqa: E402

UI_MAP_X_MAP_ART = 1957217               # DBFilesClient/UiMapXMapArt.db2: parent = uiMapID, vals[1] = UiMapArtID
UI_MAP_ART_TILE = 1957210                # DBFilesClient/UiMapArtTile.db2: parent = UiMapArtID, vals = row, col, layer, file


def main(name):
    ui_map = CITIES[name][0]
    c = Casc()
    art_ids = [r["vals"][1] for r in wdc5.read(c.read_fdid(UI_MAP_X_MAP_ART)) if r["parent"] == ui_map]
    if not art_ids:
        raise SystemExit("no map art for %d" % ui_map)
    tiles = [r["vals"] for r in wdc5.read(c.read_fdid(UI_MAP_ART_TILE)) if r["parent"] == art_ids[0] and r["vals"][2] == 0]
    rows, cols = max(t[0] for t in tiles) + 1, max(t[1] for t in tiles) + 1
    first = Image.open(io.BytesIO(c.read_fdid(tiles[0][3])))
    tw, th = first.size
    mosaic = Image.new("RGB", (cols * tw, rows * th))
    for row, col, _, fid in tiles:
        mosaic.paste(Image.open(io.BytesIO(c.read_fdid(fid))).convert("RGB"), (col * tw, row * th))
    os.makedirs(ART, exist_ok=True)
    out = os.path.join(ART, name + ".png")
    mosaic.crop((0, 0, ART_W, ART_H)).save(out)
    print(out, "art", art_ids[0], "tiles", len(tiles))


if __name__ == "__main__":
    main(sys.argv[1])
