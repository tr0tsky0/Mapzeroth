"""Minimal read-only reader for a local CASC install (WoW), by FileDataID.

Prototype for road extraction. Handles local .idx indices, BLTE (N/Z chunks),
the encoding file (targeted page lookup) and the MFST root file.
"""
import os
import struct
import zlib
import bisect

WOW_ROOT = r"D:\World of Warcraft"


def _hex(b):
    return b.hex()


class Casc:
    def __init__(self, product="wowf", root=WOW_ROOT):
        self.root = root
        self.data_dir = os.path.join(root, "Data", "data")
        bk = self._build_key(product)
        self.build_config = self._read_config(bk)
        self._load_indices()
        self._load_encoding()
        self._load_root()

    # ---------- config ----------
    def _build_key(self, product):
        with open(os.path.join(self.root, ".build.info"), encoding="utf-8") as f:
            lines = [l.rstrip("\r\n") for l in f if l.strip()]
        cols = [c.split("!")[0] for c in lines[0].split("|")]
        for l in lines[1:]:
            row = dict(zip(cols, l.split("|")))
            if row.get("Product") == product:
                return row["Build Key"]
        raise KeyError(product)

    def _read_config(self, key):
        p = os.path.join(self.root, "Data", "config", key[0:2], key[2:4], key)
        cfg = {}
        with open(p, encoding="utf-8") as f:
            for l in f:
                if "=" in l and not l.startswith("#"):
                    k, v = l.split("=", 1)
                    cfg[k.strip()] = v.split()
        return cfg

    # ---------- local indices ----------
    def _load_indices(self):
        latest = {}
        for n in os.listdir(self.data_dir):
            if n.endswith(".idx") and len(n) == 14:
                b, v = int(n[0:2], 16), int(n[2:10], 16)
                if b not in latest or v > latest[b][0]:
                    latest[b] = (v, n)
        self.index = {}
        for _, n in latest.values():
            with open(os.path.join(self.data_dir, n), "rb") as f:
                d = f.read()
            hsize = struct.unpack_from("<I", d, 0)[0]
            pos = 8 + hsize
            pos = (pos + 15) & ~15
            esize = struct.unpack_from("<I", d, pos)[0]
            pos += 8
            end = pos + esize
            while pos + 18 <= end:
                k = d[pos:pos + 9]
                off = int.from_bytes(d[pos + 9:pos + 14], "big")
                size = struct.unpack_from("<I", d, pos + 14)[0]
                pos += 18
                if k not in self.index:
                    self.index[k] = (off >> 30, off & ((1 << 30) - 1), size)

    def read_ekey(self, ekey):
        loc = self.index.get(ekey[:9])
        if loc is None:
            raise KeyError("ekey not local: " + _hex(ekey))
        arc, off, size = loc
        with open(os.path.join(self.data_dir, "data.%03d" % arc), "rb") as f:
            f.seek(off + 30)
            blte = f.read(size - 30)
        return blte_decode(blte)

    # ---------- encoding ----------
    def _load_encoding(self):
        ekey = bytes.fromhex(self.build_config["encoding"][1])
        d = self.read_ekey(ekey)
        assert d[0:2] == b"EN"
        ck, ek = d[3], d[4]
        ce_kb = struct.unpack_from(">H", d, 5)[0]
        ce_count = struct.unpack_from(">I", d, 9)[0]
        espec = struct.unpack_from(">I", d, 18)[0]
        pos = 22 + espec
        self._enc = d
        self._enc_first = []
        for i in range(ce_count):
            self._enc_first.append(d[pos + i * 32: pos + i * 32 + ck])
        self._enc_pages = pos + ce_count * 32
        self._enc_pagesize = ce_kb * 1024
        self._ck = ck

    def ckey_to_ekey(self, ckey):
        i = bisect.bisect_right(self._enc_first, ckey) - 1
        if i < 0:
            return None
        d = self._enc
        pos = self._enc_pages + i * self._enc_pagesize
        end = pos + self._enc_pagesize
        ck = self._ck
        while pos < end:
            n = d[pos]
            if n == 0:
                break
            key = d[pos + 6: pos + 6 + ck]
            if key == ckey:
                return d[pos + 6 + ck: pos + 6 + ck + 16]
            pos += 6 + ck + n * 16
        return None

    # ---------- root ----------
    def _load_root(self):
        ckey = bytes.fromhex(self.build_config["root"][0])
        d = self.read_ekey(self.ckey_to_ekey(ckey))
        self.fdid = {}
        pos = 0
        if d[0:4] == b"TSFM":
            hs, ver = struct.unpack_from("<II", d, 4)
            if hs in (24, 28) and ver in (1, 2):
                pos = hs
            else:
                ver = 0
                pos = 12
        else:
            raise ValueError("old root format not supported")
        n = len(d)
        while pos < n:
            if ver == 2:
                num, locale, f1, f2 = struct.unpack_from("<IIII", d, pos)
                f3 = d[pos + 16]
                content = f1 | f2 | (f3 << 17)
                pos += 17
            else:
                num, content, locale = struct.unpack_from("<III", d, pos)
                pos += 12
            deltas = struct.unpack_from("<%di" % num, d, pos)
            pos += 4 * num
            ckeys = pos
            pos += 16 * num
            if not (content & 0x10000000):
                pos += 8 * num
            ok = (locale & 0x2) or locale == 0xFFFFFFFF or locale == 0
            fid = -1
            for i in range(num):
                fid = fid + 1 + deltas[i]
                if ok:
                    self.fdid.setdefault(fid, []).append(d[ckeys + 16 * i: ckeys + 16 * i + 16])

    def read_fdid(self, fid):
        for ck in self.fdid.get(fid, ()):
            ek = self.ckey_to_ekey(ck)
            if ek is None or ek[:9] not in self.index:
                continue
            try:
                return self.read_ekey(ek)
            except (KeyError, ValueError):
                continue
        return None


def blte_decode(b):
    assert b[0:4] == b"BLTE", b[0:4]
    hsize = struct.unpack_from(">I", b, 4)[0]
    chunks = []
    if hsize == 0:
        chunks.append((b[8:], None))
    else:
        count = int.from_bytes(b[9:12], "big")
        pos = 12
        data = hsize
        for _ in range(count):
            cs, ds = struct.unpack_from(">II", b, pos)
            pos += 24
            chunks.append((b[data:data + cs], ds))
            data += cs
    out = []
    for c, ds in chunks:
        m = c[0:1]
        if m == b"N":
            out.append(c[1:])
        elif m == b"Z":
            out.append(zlib.decompress(c[1:]))
        elif m == b"E":
            if ds is None:
                raise ValueError("encrypted file")
            out.append(bytes(ds))                # encrypted (unreleased content): zeros, the rest still reads
        else:
            raise ValueError("BLTE mode %r" % m)
    return b"".join(out)


if __name__ == "__main__":
    import time
    t = time.time()
    c = Casc()
    print("index", len(c.index), "fdids", len(c.fdid), "%.1fs" % (time.time() - t))
    for fid in (775971, 782779):
        d = c.read_fdid(fid)
        print(fid, None if d is None else (len(d), d[:4]))
