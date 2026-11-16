"""Binary-image helpers in plain numpy (no scipy): shift, dilate, erode, Zhang-Suen thinning."""
import numpy as np


def shift(a, dy, dx):
    out = np.zeros_like(a)
    H, W = a.shape
    out[max(dy, 0):H + min(dy, 0), max(dx, 0):W + min(dx, 0)] = \
        a[max(-dy, 0):H + min(-dy, 0), max(-dx, 0):W + min(-dx, 0)]
    return out


def dilate(a, r=1):
    out = a.copy()
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            if dy * dy + dx * dx <= r * r:
                out |= shift(a, dy, dx)
    return out


def erode(a, r=1):
    return ~dilate(~a, r)


def thin(img):
    img = img.copy().astype(np.uint8)
    while True:
        changed = False
        for step in (0, 1):
            P2 = shift(img, 1, 0); P3 = shift(img, 1, -1); P4 = shift(img, 0, -1)
            P5 = shift(img, -1, -1); P6 = shift(img, -1, 0); P7 = shift(img, -1, 1)
            P8 = shift(img, 0, 1); P9 = shift(img, 1, 1)
            nb = [P2, P3, P4, P5, P6, P7, P8, P9]
            B = sum(n.astype(np.int32) for n in nb)
            seq = nb + [P2]
            A = sum(((seq[i] == 0) & (seq[i + 1] == 1)).astype(np.int32) for i in range(8))
            if step == 0:
                c1 = (P2 * P4 * P6) == 0
                c2 = (P4 * P6 * P8) == 0
            else:
                c1 = (P2 * P4 * P8) == 0
                c2 = (P2 * P6 * P8) == 0
            rm = (img == 1) & (B >= 2) & (B <= 6) & (A == 1) & c1 & c2
            if rm.any():
                img[rm] = 0
                changed = True
        if not changed:
            return img.astype(bool)
