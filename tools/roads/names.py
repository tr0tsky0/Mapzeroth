"""CASC file lookup by name: Jenkins lookup3 hashlittle2 of the normalized path, matched to the root's name hashes."""
import struct

M = 0xFFFFFFFF


def rot(x, k):
    return ((x << k) | (x >> (32 - k))) & M


def hashlittle2(data, pc=0, pb=0):
    length = len(data)
    a = b = c = (0xDEADBEEF + length + pc) & M
    c = (c + pb) & M
    i = 0
    while length > 12:
        a = (a + struct.unpack_from("<I", data, i)[0]) & M
        b = (b + struct.unpack_from("<I", data, i + 4)[0]) & M
        c = (c + struct.unpack_from("<I", data, i + 8)[0]) & M
        a = (a - c) & M; a ^= rot(c, 4); c = (c + b) & M
        b = (b - a) & M; b ^= rot(a, 6); a = (a + c) & M
        c = (c - b) & M; c ^= rot(b, 8); b = (b + a) & M
        a = (a - c) & M; a ^= rot(c, 16); c = (c + b) & M
        b = (b - a) & M; b ^= rot(a, 19); a = (a + c) & M
        c = (c - b) & M; c ^= rot(b, 4); b = (b + a) & M
        i += 12
        length -= 12
    if length == 0:
        return c, b
    tail = data[i:] + b"\0" * (12 - length)
    a = (a + struct.unpack_from("<I", tail, 0)[0]) & M
    b = (b + struct.unpack_from("<I", tail, 4)[0]) & M
    c = (c + struct.unpack_from("<I", tail, 8)[0]) & M
    c ^= b; c = (c - rot(b, 14)) & M
    a ^= c; a = (a - rot(c, 11)) & M
    b ^= a; b = (b - rot(a, 25)) & M
    c ^= b; c = (c - rot(b, 16)) & M
    a ^= c; a = (a - rot(c, 4)) & M
    b ^= a; b = (b - rot(a, 14)) & M
    c ^= b; c = (c - rot(b, 24)) & M
    return c, b


def name_hash(path):
    norm = path.upper().replace("/", "\\").encode("ascii")
    c, b = hashlittle2(norm)
    return (c << 32) | b


def load_name_index(casc):
    """name hash -> fileDataID, from the root's blocks that carry name hashes."""
    d = casc.read_ekey(casc.ckey_to_ekey(bytes.fromhex(casc.build_config["root"][0])))
    hs, ver = struct.unpack_from("<II", d, 4)
    pos = hs
    index = {}
    while pos < len(d):
        if ver == 2:
            num, locale, f1, f2 = struct.unpack_from("<IIII", d, pos)
            content = f1 | f2 | (d[pos + 16] << 17)
            pos += 17
        else:
            num, content, locale = struct.unpack_from("<III", d, pos)
            pos += 12
        deltas = struct.unpack_from("<%di" % num, d, pos)
        pos += 4 * num + 16 * num
        if not (content & 0x10000000):
            hashes = struct.unpack_from("<%dQ" % num, d, pos)
            pos += 8 * num
            fid = -1
            for k in range(num):
                fid += 1 + deltas[k]
                index.setdefault(hashes[k], fid)
    return index
