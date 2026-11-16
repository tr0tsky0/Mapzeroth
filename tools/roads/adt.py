"""WDT / tex0 ADT parsing: per-tile texture layers and alpha maps."""
import struct
import numpy as np

TILE = 533.3333333


def chunks(d, pos=0, end=None):
    end = len(d) if end is None else end
    while pos + 8 <= end:
        cid = d[pos:pos + 4][::-1].decode("latin1")
        size = struct.unpack_from("<I", d, pos + 4)[0]
        yield cid, pos + 8, size
        pos += 8 + size


class Wdt:
    def __init__(self, data):
        self.maid = {}
        self.flags = 0
        for cid, p, s in chunks(data):
            if cid == "MPHD":
                self.flags = struct.unpack_from("<I", data, p)[0]
            elif cid == "MAID":
                v = struct.unpack_from("<%dI" % (s // 4), data, p)
                per = (s // 4) // 4096
                for i in range(4096):
                    row = v[i * per:(i + 1) * per]
                    if row[0]:
                        y, x = divmod(i, 64)
                        self.maid[(x, y)] = row
        # entries: root, obj0, obj1, tex0, lod, mapTexture, mapTextureN, minimap

    @property
    def big_alpha(self):
        return bool(self.flags & 0x4 or self.flags & 0x80)


def decode_alpha(d, p, layer_flags, big):
    """Return (64x64 uint8, bytes consumed)."""
    if layer_flags & 0x200:  # compressed
        out = bytearray()
        q = p
        while len(out) < 4096:
            c = d[q]
            q += 1
            n = c & 0x7F
            if c & 0x80:
                out += bytes([d[q]]) * n
                q += 1
            else:
                out += d[q:q + n]
                q += n
        return np.frombuffer(bytes(out[:4096]), np.uint8).reshape(64, 64), q - p
    if big:
        return np.frombuffer(d[p:p + 4096], np.uint8).reshape(64, 64), 4096
    raw = np.frombuffer(d[p:p + 2048], np.uint8)
    a = np.empty(4096, np.uint8)
    a[0::2] = (raw & 0x0F) * 17
    a[1::2] = (raw >> 4) * 17
    return a.reshape(64, 64), 2048


class Tex0:
    """Per-texture weight maps for one ADT tile at 1024x1024 (16x16 chunks of 64x64)."""

    def __init__(self, data, big_alpha):
        self.textures = []  # names (MTEX) or fdids (MDID)
        self.layers = []  # per MCNK: list of (texid, weight 64x64 float)
        for cid, p, s in chunks(data):
            if cid == "MTEX":
                self.textures = [t.decode("latin1") for t in data[p:p + s].split(b"\0") if t]
            elif cid == "MDID":
                self.textures = list(struct.unpack_from("<%dI" % (s // 4), data, p))
            elif cid == "MCNK":
                self.layers.append(self._mcnk(data, p, s, big_alpha))

    def _mcnk(self, d, p, s, big):
        mcly, mcal = [], None
        for cid, q, sz in chunks(d, p, p + s):
            if cid == "MCLY":
                for i in range(sz // 16):
                    tex, fl, off, eff = struct.unpack_from("<IIIi", d, q + i * 16)
                    mcly.append((tex, fl, off))
            elif cid == "MCAL":
                mcal = (q, sz)
        out = []
        total = np.zeros((64, 64), np.float32)
        for i, (tex, fl, off) in enumerate(mcly):
            if i == 0:
                continue
            if mcal is None or not (fl & 0x100):
                continue
            a, _ = decode_alpha(d, mcal[0] + off, fl, big)
            w = a.astype(np.float32) / 255.0
            out.append((tex, w))
            total += w
        if mcly:
            if big:
                base = np.clip(1.0 - total, 0, 1)
            else:
                base = np.clip(1.0 - total, 0, 1)
            out.insert(0, (mcly[0][0], base))
        return out

    def weight(self, wanted):
        """1024x1024 float map of summed weight for texture indices in `wanted`."""
        m = np.zeros((1024, 1024), np.float32)
        for ci, layers in enumerate(self.layers):
            cy, cx = divmod(ci, 16)
            blk = m[cy * 64:(cy + 1) * 64, cx * 64:(cx + 1) * 64]
            for tex, w in layers:
                if tex in wanted:
                    blk += w
        return np.clip(m, 0, 1)
