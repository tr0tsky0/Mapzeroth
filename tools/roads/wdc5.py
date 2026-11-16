"""Minimal WDC5 (DB2) reader: records as lists of field values, with ids and relationship (parent) ids."""
import struct


def bits(data, bit_off, nbits):
    byte = bit_off >> 3
    chunk = int.from_bytes(data[byte:byte + 9].ljust(9, b"\0"), "little")
    return (chunk >> (bit_off & 7)) & ((1 << nbits) - 1)


def read(data):
    assert data[:4] == b"WDC5", data[:4]
    (record_count, field_count, record_size, string_table_size, table_hash, layout_hash, min_id, max_id,
     locale) = struct.unpack_from("<9I", data, 136)
    flags, id_index = struct.unpack_from("<HH", data, 172)
    (total_field_count, bitpacked_offset, lookup_columns, fsi_size, common_size, pallet_size,
     section_count) = struct.unpack_from("<7I", data, 176)
    pos = 204
    sections = []
    for _ in range(section_count):
        s = struct.unpack_from("<Q8I", data, pos)
        sections.append(dict(key=s[0], offset=s[1], records=s[2], strings=s[3], records_end=s[4], id_list=s[5],
                             rel=s[6], offset_map=s[7], copy=s[8]))
        pos += 40
    pos += 4 * total_field_count                       # field_structure
    fsi = []
    for _ in range(fsi_size // 24):
        off_bits, size_bits, add_size, stype, v1, v2, v3 = struct.unpack_from("<HHIIIII", data, pos)
        fsi.append(dict(off=off_bits, size=size_bits, add=add_size, type=stype, v1=v1, v2=v2, v3=v3))
        pos += 24
    pallet_start = pos
    common_start = pos + pallet_size
    # Per-field pallet and common-data slices.
    p, cpos = pallet_start, common_start
    for f in fsi:
        if f["type"] in (3, 4):
            f["pallet"] = data[p:p + f["add"]]
            p += f["add"]
        if f["type"] == 2:
            f["common"] = {}
            for k in range(f["add"] // 8):
                rid, val = struct.unpack_from("<II", data, cpos + 8 * k)
                f["common"][rid] = val
            cpos += f["add"]
    out = []
    for s in sections:
        if s["key"] != 0 and s["records"] and False:
            continue
        rp = s["offset"]
        if flags & 1:
            raise NotImplementedError("sparse table")
        rec_start = rp
        str_start = rec_start + s["records"] * record_size
        idl_start = str_start + s["strings"]
        ids = list(struct.unpack_from("<%dI" % s["records"], data, idl_start)) if s["id_list"] else None
        cp = idl_start + s["id_list"]
        copies = [struct.unpack_from("<II", data, cp + 8 * k) for k in range(s["copy"])]
        rp2 = cp + 8 * s["copy"] + 6 * s["offset_map"]
        rel = {}
        if s["rel"]:
            n, rmin, rmax = struct.unpack_from("<III", data, rp2)
            for k in range(n):
                fid, idx = struct.unpack_from("<II", data, rp2 + 12 + 8 * k)
                rel[idx] = fid
        for r in range(s["records"]):
            rec = data[rec_start + r * record_size: rec_start + (r + 1) * record_size]
            vals = []
            for f in fsi:
                t = f["type"]
                if t == 0:
                    nbytes = f["size"] // 8
                    raw = rec[f["off"] // 8: f["off"] // 8 + nbytes]
                    vals.append(int.from_bytes(raw, "little") if nbytes <= 8 else raw)
                elif t == 1 or t == 5:
                    v = bits(rec, f["off"], f["size"])
                    if t == 5 and v >> (f["size"] - 1):
                        v -= 1 << f["size"]
                    vals.append(v)
                elif t == 3:
                    i = bits(rec, f["off"], f["size"])
                    vals.append(struct.unpack_from("<I", f["pallet"], 4 * i)[0])
                elif t == 4:
                    i = bits(rec, f["off"], f["size"])
                    cnt = f["v3"]
                    vals.append(list(struct.unpack_from("<%dI" % cnt, f["pallet"], 4 * i * cnt)))
                elif t == 2:
                    vals.append(None)                 # filled below, needs the id
                else:
                    vals.append(("?", t))
            rid = ids[r] if ids else vals[id_index]
            for k, f in enumerate(fsi):
                if f["type"] == 2:
                    vals[k] = f["common"].get(rid, f["v1"])
            out.append(dict(id=rid, vals=vals, parent=rel.get(r)))
        for new, old in copies:
            src = next((o for o in out if o["id"] == old), None)
            if src:
                out.append(dict(id=new, vals=list(src["vals"]), parent=src["parent"]))
    return out
