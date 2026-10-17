"""Draws the white, tintable textures in Media/ that the route and the navigator use.

    python tools/gen_media.py

Every shape is drawn from a distance field in "design" pixels (how big it is on screen at full size), with an edge
about one screen pixel soft, so the game's filtering gives smooth edges at any size. All of them are white (tinted in
game); the line casings and marker edges are separate textures, tinted with the theme's casing colour.

Line tiles (Line*.tga): one repeat of a pattern, which RouteLines tiles along a line with texture coordinates. Each
is PERIOD x THICKNESS design pixels stretched over 64 x 32 texels, so the shapes are drawn squashed in texel space and
come out round on screen. RouteLines.LINE_TILES must match the PERIOD and THICKNESS here.
"""

import math
import os

from PIL import Image

MEDIA = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "Media")


def seg_dist(px, py, ax, ay, bx, by):
    dx, dy = bx - ax, by - ay
    t = 0.0
    if dx or dy:
        t = max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)))
    return math.hypot(px - (ax + t * dx), py - (ay + t * dy))


def poly_sdf(px, py, pts):
    """Signed distance to a closed polygon: negative inside."""
    d = min(seg_dist(px, py, *pts[i], *pts[(i + 1) % len(pts)]) for i in range(len(pts)))
    inside = False
    j = len(pts) - 1
    for i in range(len(pts)):
        xi, yi = pts[i]
        xj, yj = pts[j]
        if (yi > py) != (yj > py) and px < (xj - xi) * (py - yi) / (yj - yi) + xi:
            inside = not inside
        j = i
    return -d if inside else d


def cover(sdf, aa):
    return max(0.0, min(1.0, 0.5 - sdf / aa))


def render(path, w, h, dw, dh, layers, aa=1.0):
    """layers: list of (sdf(x, y) -> float, grey 0..1), drawn bottom to top, in design space dw x dh."""
    img = Image.new("RGBA", (w, h))
    px = img.load()
    for v in range(h):
        for u in range(w):
            x, y = (u + 0.5) / w * dw, (v + 0.5) / h * dh
            r = a = 0.0
            for sdf, grey in layers:
                c = cover(sdf(x, y), aa)
                r = grey * c + r * (1 - c)            # premultiplied "over"
                a = c + a * (1 - c)
            g = r / a if a > 0 else 1.0
            px[u, v] = (round(g * 255), round(g * 255), round(g * 255), round(a * 255))
    img.save(os.path.join(MEDIA, path))
    print("wrote", path)


# --- Line tiles -------------------------------------------------------------------------------------------------
TILE_W, TILE_H = 64, 32
CASE = 1.5                     # how far the casing reaches past the line, each side

# name: (period, thickness, core sdf); the casing is the core grown by CASE
def dot(period, t, r):
    return lambda x, y: math.hypot(x - period / 2, y - t / 2) - r


def dash(period, t, length, r):
    a, b = (period - length) / 2 + r, (period + length) / 2 - r
    return lambda x, y: seg_dist(x, y, a, t / 2, b, t / 2) - r


def band(t, half):
    return lambda x, y: abs(y - t / 2) - half


LINES = {
    "LineDot": (12, 8, dot(12, 8, 2.5)),
    "LineDash": (18, 8, dash(18, 8, 11, 2)),
    "LineSolid": (8, 8, band(8, 2.25)),
}

# --- Markers (64 x 64 over 20 x 20 design px) -------------------------------------------------------------------
def ring(cx, cy, r, half):
    return lambda x, y: abs(math.hypot(x - cx, y - cy) - r) - half


def union(*fs):
    return lambda x, y: min(f(x, y) for f in fs)


def arrow(ax, ay, bx, by, half, head):
    """A shaft from a to b with a triangular head at b, pointing from a to b."""
    dx, dy = bx - ax, by - ay
    n = math.hypot(dx, dy)
    ux, uy = dx / n, dy / n
    base = (bx - ux * head, by - uy * head)
    tri = [(bx, by), (base[0] - uy * head * 0.7, base[1] + ux * head * 0.7),
           (base[0] + uy * head * 0.7, base[1] - ux * head * 0.7)]
    shaft = lambda x, y: seg_dist(x, y, ax, ay, base[0] + ux * 0.5, base[1] + uy * 0.5) - half
    return union(shaft, lambda x, y: poly_sdf(x, y, tri))


# A ring round the spot with an arrow: leaving, it starts in the ring and points out of it; landing, it comes in from
# outside and points into it. Each ring sits a little off the middle so the arrow has room; at this size that is
# a pixel or two. Their edges are thinner than a line's casing (MARK_CASE): a full one closes up the ring.
RING_R, RING_HALF, MARK_CASE = 5.2, 0.9, 1.0
PORT_OUT = union(ring(7.5, 10, RING_R, RING_HALF), arrow(7.5, 10, 19.6, 10, 0.9, 4.0))
PORT_IN = union(ring(12.5, 10, RING_R, RING_HALF), arrow(0.4, 10, 12.5, 10, 0.9, 4.0))

# The other markers, each drawn over the size it shows at (RouteLines' MARKER, in design px): a step's start a dot;
# a tour stop a rounded square; the end a target (a ring round a dot). Their edges fill in between the target's ring
# and dot, so it reads on any map art.
def rounded_square(cx, cy, half, corner):
    def f(x, y):
        qx, qy = abs(x - cx) - (half - corner), abs(y - cy) - (half - corner)
        return math.hypot(max(qx, 0), max(qy, 0)) + min(max(qx, qy), 0) - corner
    return f


MARKERS = {   # name: (design size, shape)
    "Step": (7, lambda x, y: math.hypot(x - 3.5, y - 3.5) - 2.3),
    "Stop": (11, rounded_square(5.5, 5.5, 4.0, 1.6)),
    "Dest": (15, union(ring(7.5, 7.5, 5.0, 1.25), lambda x, y: math.hypot(x - 7.5, y - 7.5) - 1.9)),
}
HALO = ring(20, 20, 15, 2.2)       # 128 x 128 over 40 x 40 design px


# A Hallow's End stop (RouteLines' "bucket", 18 design px): a jack-o'-lantern pail, its handle an arc over the top. The
# face is cut out of the fill, so the dark edge picture under it shows through as the face.
def bucket_shape():
    body = ellipse(9, 10.9, 7.1, 5.9)
    handle_ring = ring(9, 8.2, 5.6, 0.7)
    handle = lambda x, y: max(handle_ring(x, y), y - 6.4)          # only its top: the arc over the pail
    rim = rounded_square(9, 5.4, 3.0, 1.0)
    rim_h = lambda x, y: max(rim(x, y), abs(y - 5.4) - 0.9)        # a flat strip where the handle meets the pail
    outline = union(body, handle, rim_h)
    eyes = [[(4.8, 10.2), (7.6, 10.2), (6.2, 8.0)], [(10.4, 10.2), (13.2, 10.2), (11.8, 8.0)]]
    mouth = [(4.4, 12.0), (13.6, 12.0), (12.6, 14.4), (11.0, 13.4), (9.0, 14.6), (7.0, 13.4), (5.4, 14.4)]
    face = lambda x, y: min(min(poly_sdf(x, y, e) for e in eyes), poly_sdf(x, y, mouth))
    return outline, (lambda x, y: max(outline(x, y), -face(x, y)))


# --- The navigator's arrow (256 x 256 over 72 x 72 design px), two-tone, its dark edge baked in ------------------
CHEVRON = [(36, 8), (61, 61), (36, 48), (11, 61)]
LEFT_HALF = [(36, 8), (36, 48), (11, 61)]


# --- The Discord logo (its mascot's face), white, for the settings page's Discord button: 64 x 48 over 24 x 18 ---------
DISCORD_BODY = [(6.5, 3.0), (10, 2.8), (12, 4.6), (14, 2.8), (17.5, 3.0), (20.5, 10), (21, 14.5), (18.5, 15.5), (17, 13.6),
                (12, 13.0), (7, 13.6), (5.5, 15.5), (3, 14.5), (3.5, 10)]


def ellipse(cx, cy, rx, ry):
    return lambda x, y: (math.hypot((x - cx) / rx, (y - cy) / ry) - 1) * min(rx, ry)


def discord(x, y):
    body = poly_sdf(x, y, DISCORD_BODY) - 1.2
    eyes = min(ellipse(9, 9.8, 1.8, 2.1)(x, y), ellipse(15, 9.8, 1.8, 2.1)(x, y))
    return max(body, -eyes)


def main():
    for name, (period, t, core) in LINES.items():
        render(name + ".tga", TILE_W, TILE_H, period, t, [(core, 1.0)])
        render(name + "Edge.tga", TILE_W, TILE_H, period, t, [(lambda x, y, f=core: f(x, y) - CASE, 1.0)])
    for name, shape in (("PortOut", PORT_OUT), ("PortIn", PORT_IN)):
        render(name + ".tga", 64, 64, 20, 20, [(shape, 1.0)], aa=0.8)
        render(name + "Edge.tga", 64, 64, 20, 20, [(lambda x, y, f=shape: f(x, y) - MARK_CASE, 1.0)], aa=0.8)
    for name, (size, shape) in MARKERS.items():
        render(name + ".tga", 64, 64, size, size, [(shape, 1.0)], aa=0.8)
        render(name + "Edge.tga", 64, 64, size, size, [(lambda x, y, f=shape: f(x, y) - 1.2, 1.0)], aa=0.8)
    bucket_outline, bucket = bucket_shape()
    render("Bucket.tga", 64, 64, 18, 18, [(bucket, 1.0)], aa=0.8)
    render("BucketEdge.tga", 64, 64, 18, 18, [(lambda x, y: bucket_outline(x, y) - 1.2, 1.0)], aa=0.8)
    # The ring round the flight point a route flies to, on the flight master's map (Theme:TaxiMark): drawn larger than
    # the route's markers, since it sits round the game's own node button.
    render("Halo.tga", 128, 128, 40, 40, [(HALO, 1.0)], aa=0.8)
    render("HaloEdge.tga", 128, 128, 40, 40, [(lambda x, y: HALO(x, y) - 1.2, 1.0)], aa=0.8)
    edge = lambda x, y: poly_sdf(x, y, CHEVRON) - 3
    render("Arrow.tga", 256, 256, 72, 72, [
        (edge, 0.06),
        (lambda x, y: poly_sdf(x, y, CHEVRON) - 0.5, 1.0),
        (lambda x, y: poly_sdf(x, y, LEFT_HALF), 0.68),
    ], aa=1.4)
    render("Discord.tga", 64, 48, 24, 18, [(discord, 1.0)], aa=0.6)


if __name__ == "__main__":
    main()
