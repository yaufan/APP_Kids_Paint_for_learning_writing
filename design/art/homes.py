"""字母寵物's homes: one picture-book page per pet, the pet's background.

    python3 homes.py            # writes app/assets/art/homes/<id>.svg

Portrait 1080 x 1920, opaque. The pet stands at about y = 1450 in the
middle, so the middle stays quiet; the top 250 and the bottom 400 are
calm (the app's buttons go there). Soft layered hills or water, simple
trees and things with hand-drawn edges, gentle light and paper grain.
"""
import math
import pathlib

from storybook import INK, Doc, Path, dark, light, n, smooth

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "app" / "assets" / "art" / "homes"
W, H = 1080, 1920
PET_Y = 1450

LEAF, LEAF2, TRUNK = "#9DC08A", "#83AE7A", "#B98A64"
SUN = "#F7CD62"
CLOUD = "#FFFCF5"
JUNGLE_FLOOR = "#D4D49A"   # warmer than the dino's sage, so it stands out
MOUTH = "#9A5B45"


# ---------------------------------------------------------------- scenery
def backdrop(d, top, bottom, y1=H):
    """The whole page in one vertical wash (so the page is never see-through)."""
    return f'<rect width="{W}" height="{H}" fill="{bottom}"/><rect width="{W}" height="{y1}" fill="{d.grad(bottom, ("down", top))}"/>'


def band(d, y, amp, wl, color, phase=0.0, line=True, lw=3, bottom=H + 60, x0=-60, x1=W + 60, grad="flat", edge=None):
    """A wide soft hill (or water) from a wavy top line down to the bottom."""
    pts = []
    m = 28
    for i in range(m + 1):
        x = x0 + (x1 - x0) * i / m
        yy = y + amp * math.sin(2 * math.pi * x / wl + phase) + amp * 0.35 * math.sin(2 * math.pi * x / (wl * 0.43) + phase * 1.7)
        pts.append((x, yy))
    top = smooth(d.jit(pts, 1.5), closed=False)
    top.L((x1, bottom)).L((x0, bottom))
    top.closed = True
    return d.fill(top, color, line=line, lw=lw, grad=grad, edge=edge)


def glow(d, x, y, r, color, alpha=0.45):
    gid = d.uid("glow")
    d.defs.append(f'<radialGradient id="{gid}"><stop offset="0" stop-color="{color}" stop-opacity="{alpha}"/>'
                  f'<stop offset="1" stop-color="{color}" stop-opacity="0"/></radialGradient>')
    return f'<circle cx="{n(x)}" cy="{n(y)}" r="{n(r)}" fill="url(#{gid})"/>'


def face(d, x, y, s, sleepy=False, smile_w=1.0):
    """A little picture-book face: dot eyes, rosy cheeks, a small smile."""
    P = []
    for dx in (-1, 1):
        ex = x + dx * 15 * s
        if sleepy:
            P.append(d.stroke(smooth([(ex - 6 * s, y - 1 * s), (ex, y + 4 * s), (ex + 6 * s, y - 1 * s)], closed=False), INK, 3 * s))
        else:
            P.append(d.dot(ex, y, 4.6 * s, INK))
            P.append(d.dot(ex - 1.4 * s, y - 1.7 * s, 1.6 * s, "#FFFFFF"))
        P.append(f'<ellipse cx="{n(x + dx * 25 * s)}" cy="{n(y + 9 * s)}" rx="{n(7 * s)}" ry="{n(4.5 * s)}" fill="#F39A8F" opacity="0.55"/>')
    w = 7 * s * smile_w
    P.append(d.stroke(smooth([(x - w, y + 8 * s), (x, y + 13 * s), (x + w, y + 8 * s)], closed=False), MOUTH, 3 * s))
    return P


def sun(d, x, y, r, with_face=True):
    pts = []
    for i in range(28):
        a = 2 * math.pi * i / 28
        rr = r * (1.32 if i % 2 == 0 else 1.14)
        pts.append((x + rr * math.cos(a), y + rr * math.sin(a)))
    P = [glow(d, x, y, r * 3.2, "#FFF1C2", 0.7),
         d.fill(d.blob(pts, 1.2), light(SUN, 0.3), lw=3),
         d.fill(d.oval(x, y, r, r), SUN, lw=3)]
    if with_face:
        P += face(d, x, y + r * 0.05, r / 34)
    return P


def cloud(d, x, y, s=1.0, color=CLOUD, opacity=0.95):
    """A soft scalloped cloud, no outline."""
    puffs = [(-70, 6, 38), (-28, -22, 52), (30, -14, 46), (74, 6, 32), (0, 14, 50)]
    P = [f'<ellipse cx="{n(x)}" cy="{n(y + 22 * s)}" rx="{n(112 * s)}" ry="{n(24 * s)}"/>']
    for dx, dy, r in puffs:
        P.append(f'<circle cx="{n(x + dx * s)}" cy="{n(y + dy * s)}" r="{n(r * s)}"/>')
    shade = f'<ellipse cx="{n(x + 6 * s)}" cy="{n(y + 30 * s)}" rx="{n(96 * s)}" ry="{n(14 * s)}" fill="{dark(color, 0.08)}" opacity="0.6"/>'
    return f'<g fill="{color}" opacity="{opacity}">{"".join(P)}</g>{shade}'


def round_tree(d, x, y, s, leaf=LEAF, trunk=TRUNK, fruit=None):
    P = [d.fill(d.poly([(x - 13 * s, y), (x - 9 * s, y - 96 * s), (x + 9 * s, y - 96 * s), (x + 13 * s, y)], r=6 * s), trunk, lw=3)]
    pts = []
    for i in range(22):
        a = 2 * math.pi * i / 22
        rr = 74 * s * (1.0 if i % 2 == 0 else 1.09)
        pts.append((x + rr * math.cos(a), y - 150 * s + rr * 0.9 * math.sin(a)))
    P.append(d.fill(d.blob(pts, 1.5 * s), leaf, lw=3))
    for dx, dy, r in ((-30, -176, 9), (22, -190, 7), (34, -140, 8), (-18, -126, 6)):
        P.append(d.dot(x + dx * s, y + dy * s, r * s, fruit or light(leaf, 0.3), 0.9 if fruit else 0.8))
    return P


def bush(d, x, y, s, leaf=LEAF2):
    pts = []
    for i in range(16):
        a = math.pi + math.pi * i / 15
        rr = 60 * s * (1.0 if i % 2 == 0 else 1.1)
        pts.append((x + rr * 1.35 * math.cos(a), y + rr * 1.2 * math.sin(a)))
    P = [d.fill(d.blob(pts, 1.2 * s), leaf, lw=3)]
    P += [d.dot(x + dx * s, y + dy * s, 5 * s, light(leaf, 0.35), 0.8) for dx, dy in ((-40, -36), (10, -52), (48, -28))]
    return P


def flower(d, x, y, s, petal, stem=LEAF2):
    P = [d.stroke(d.curve([(x, y), (x + 2 * s, y - 18 * s), (x, y - 34 * s)], 0.4), dark(stem, 0.15), 4 * s)]
    for k in range(5):
        a = 2 * math.pi * k / 5 - math.pi / 2
        P.append(d.fill(d.oval(x + 10 * s * math.cos(a), y - 34 * s + 10 * s * math.sin(a), 8 * s, 8 * s), petal, lw=2))
    P.append(d.fill(d.oval(x, y - 34 * s, 6 * s, 6 * s), "#F6C65C", lw=1.8))
    return P


def tuft(d, x, y, s, color):
    c = dark(color, 0.22)
    return [d.stroke(d.curve([(x + dx * s, y), (x + dx * 1.6 * s, y - h * s)], 0.3), c, 3.2 * s)
            for dx, h in ((-8, 16), (0, 24), (8, 15))]


def picket_fence(d, x0, x1, top, bottom, step, color):
    P = [d.fill(d.poly([(x0 - 20, top + 34), (x1 + 20, top + 34), (x1 + 20, top + 52), (x0 - 20, top + 52)], r=6, j=1.5, bow=3), dark(color, 0.08), lw=3),
         d.fill(d.poly([(x0 - 20, bottom - 46), (x1 + 20, bottom - 46), (x1 + 20, bottom - 28), (x0 - 20, bottom - 28)], r=6, j=1.5, bow=3), dark(color, 0.08), lw=3)]
    x = x0
    while x <= x1:
        P.append(d.fill(d.poly([(x - 19, bottom), (x - 19, top + 20), (x, top), (x + 19, top + 20), (x + 19, bottom)], r=9, j=1.2, bow=1.5), color, lw=3))
        x += step
    return P


def palm(d, x, y, h, lean, s=1.0, leaf=LEAF, trunk="#C99B6E"):
    """A palm tree: a bending trunk with rings and drooping fronds."""
    top = (x + lean, y - h)
    trunk_path = d.curve([(x, y), (x + lean * 0.2, y - h * 0.5), top], 0.5)
    P = [d.tube(trunk_path, 30 * s, trunk, lw=3)]
    pts = trunk_path.points(10)
    for i in range(4, len(pts) - 3, 4):
        (ax, ay), (bx, by) = pts[i - 1], pts[i + 1]
        L = math.hypot(bx - ax, by - ay) or 1
        nx, ny = -(by - ay) / L, (bx - ax) / L
        px, py = pts[i]
        P.append(d.stroke(smooth([(px - nx * 13 * s, py - ny * 13 * s), (px + ny * 3 * s, py - nx * 3 * s), (px + nx * 13 * s, py + ny * 13 * s)], closed=False),
                          dark(trunk, 0.3), 2.6))
    for ang, L in ((-160, 150), (-125, 130), (-60, 130), (-20, 150), (-95, 110), (20, 120), (160, 120)):
        a = math.radians(ang)
        tip = (top[0] + L * s * math.cos(a), top[1] + L * s * math.sin(a) + 50 * s)
        mid = (top[0] + L * 0.55 * s * math.cos(a), top[1] + L * 0.55 * s * math.sin(a) - 4 * s)
        nx, ny = -math.sin(a), math.cos(a)
        w = 22 * s
        frond = [top, (mid[0] + nx * w, mid[1] + ny * w), tip, (mid[0] - nx * w * 0.6, mid[1] - ny * w * 0.6)]
        P.append(d.fill(d.blob(frond, 1.0), leaf, lw=3))
        P.append(d.stroke(smooth([top, mid, tip], closed=False), dark(leaf, 0.25), 2.4))
    for dx, dy in ((-12, 14), (10, 16), (0, 26)):
        P.append(d.fill(d.oval(top[0] + dx * s, top[1] + dy * s, 12 * s, 12 * s), "#A97A55", lw=2.4))
    return P


def grain(d, count=900):
    """Paper grain over the whole page."""
    return (d.speckle(0, 0, W, H, count, ["#6E5240"], 0.8, 2.2, 0.07)
            + d.speckle(0, 0, W, H, count // 2, ["#FFFFFF"], 0.8, 2.0, 0.22))


def leaf_shape(d, x, y, L, w, ang, color):
    """A big soft leaf with a vein (jungle, garden)."""
    a = math.radians(ang)
    ux, uy = math.cos(a), math.sin(a)
    nx, ny = -uy, ux
    tip = (x + ux * L, y + uy * L)
    pts = [(x, y), (x + ux * L * 0.35 + nx * w, y + uy * L * 0.35 + ny * w), (x + ux * L * 0.75 + nx * w * 0.7, y + uy * L * 0.75 + ny * w * 0.7),
           tip, (x + ux * L * 0.75 - nx * w * 0.7, y + uy * L * 0.75 - ny * w * 0.7), (x + ux * L * 0.35 - nx * w, y + uy * L * 0.35 - ny * w)]
    return [d.fill(d.blob(pts, 1.0), color, lw=3),
            d.stroke(d.curve([(x, y), (x + ux * L * 0.5, y + uy * L * 0.5), (tip[0] - ux * 10, tip[1] - uy * 10)], 0.5), dark(color, 0.25), 2.6)]


def waves(d, y, x0, x1, wl, amp, color, w=5, opacity=0.8):
    """A line of little wave crests."""
    p = Path((x0, y))
    x, k = x0, 0
    while x < x1:
        p.Q((x + wl / 4, y - amp if k % 2 == 0 else y + amp * 0.4), (x + wl / 2, y))
        x += wl / 2
        k += 1
    return d.stroke(p, color, w, opacity)


def shell(d, x, y, s, color, rot=0):
    """A scallop shell."""
    pts = []
    for i in range(11):
        a = math.radians(200 + 140 * i / 10)
        rr = 30 * s * (1.0 if i % 2 == 0 else 0.93)
        pts.append((rr * math.cos(a), rr * math.sin(a) + 12 * s))
    pts += [(8 * s, 16 * s), (5 * s, 24 * s), (-5 * s, 24 * s), (-8 * s, 16 * s)]
    body = d.blob(pts, 0.4)
    lines = [d.stroke(Path((0, 22 * s)).L((26 * s * math.cos(math.radians(a)), 26 * s * math.sin(math.radians(a)) + 12 * s)), dark(color, 0.25), 2)
             for a in (225, 250, 270, 290, 315)]
    return f'<g transform="translate({n(x)} {n(y)}) rotate({rot})">{d.fill(body, color, lw=2.6)}{"".join(lines)}</g>'


def starfish(d, x, y, s, color, rot=0):
    pts = []
    for k in range(10):
        a = math.radians(rot - 90 + 36 * k)
        rr = (30 if k % 2 == 0 else 13) * s
        pts.append((x + rr * math.cos(a), y + rr * math.sin(a)))
    P = [d.fill(d.poly(pts, r=5 * s, j=0.6, bow=1), color, lw=2.6)]
    P += [d.dot(x + 14 * s * math.cos(math.radians(rot - 90 + 72 * k)), y + 14 * s * math.sin(math.radians(rot - 90 + 72 * k)), 2.2 * s, light(color, 0.5)) for k in range(5)]
    return P


def bubbles(d, spots):
    out = []
    for x, y, r in spots:
        out.append(f'<circle cx="{n(x)}" cy="{n(y)}" r="{n(r)}" fill="#F4FBFC" fill-opacity="0.35" stroke="#F4FBFC" stroke-width="{n(max(2, r * 0.18))}" opacity="0.85"/>')
        out.append(d.dot(x - r * 0.35, y - r * 0.35, r * 0.22, "#FFFFFF", 0.9))
    return out


# ---------------------------------------------------------------- the homes
def puppy(d):
    grass = "#B9D69B"
    P = [backdrop(d, "#BEDCEA", "#EEF3E2", 1200)]
    P += sun(d, 860, 430, 70)
    P += [cloud(d, 230, 380, 1.0), cloud(d, 640, 620, 0.62)]
    P.append(band(d, 1000, 26, 900, "#CFE0B6", 0.6, lw=2.5))
    P += round_tree(d, 640, 1010, 0.55, "#AFCB94") + round_tree(d, 780, 1000, 0.42, "#A5C58C")
    P.append(band(d, 1080, 18, 1300, "#C2DBA4", 2.0, lw=2.5))
    P += picket_fence(d, 20, 1080, 1060, 1210, 74, "#FBEEDB")
    P.append(band(d, 1200, 8, 1600, grass, 1.0, lw=3))
    P += round_tree(d, 935, 1236, 1.35, "#9DC08A", fruit="#F2A08F")
    # the doghouse
    x, base, wallc = 220, 1340, "#F3C9A2"
    wall = d.poly([(x - 135, base), (x - 135, base - 170), (x, base - 290), (x + 135, base - 170), (x + 135, base)], r=12, j=1.5, bow=2)
    P.append(d.fill(wall, wallc))
    P.append(d.clipped(wall, lambda: [d.stroke(d.curve([(x - 140, yy), (x + 140, yy)], 1.0), dark(wallc, 0.16), 2.4) for yy in range(base - 250, base, 40)]))
    P.append(d.fill(d.poly([(x - 188, base - 148), (x, base - 324), (x + 188, base - 148), (x + 184, base - 106), (x, base - 272), (x - 184, base - 106)],
                           r=14, j=1.5, bow=2), "#E8907C"))
    door = Path((x - 56, base)).L((x - 56, base - 80)).C((x - 56, base - 160), (x + 56, base - 160), (x + 56, base - 80)).L((x + 56, base))
    door.closed = True
    P.append(d.fill(door, "#7D5A49"))
    P.append(d.fill(d.poly([(x - 40, base - 232), (x + 40, base - 232), (x + 40, base - 200), (x - 40, base - 200)], r=8), "#F6CF6A", lw=2.6))
    P.append(d.fill(d.oval(x + 112, base + 6, 46, 13), "#C98E86", lw=2.6))    # the water bowl beside it
    P.append(d.fill(d.oval(x + 112, base, 32, 6), "#A9D3EA", line=False, grad=None))
    bone = d.blob([(392, 1404), (400, 1396), (410, 1402), (446, 1400), (456, 1394), (464, 1402), (458, 1412), (464, 1420), (454, 1426),
                   (446, 1418), (410, 1420), (400, 1426), (392, 1420), (398, 1412)], 0.5)
    P.append(d.fill(bone, "#FFF6E6", lw=2.6))
    P.append(band(d, 1600, 10, 1300, light(grass, 0.12), 0.8, line=False))
    P += bush(d, 790, 1262, 0.9)
    for fx, fy, c in ((390, 1236, "#F4A7A1"), (430, 1244, "#F6CF6A"), (680, 1232, "#F4A7A1"), (1040, 1262, "#FFFFFF"), (620, 1226, "#F6CF6A")):
        P += flower(d, fx, fy, 0.9, c)
    for tx, ty in ((110, 1430), (500, 1300), (840, 1340), (960, 1470), (300, 1560), (660, 1290), (80, 1660), (1000, 1720)):
        P += tuft(d, tx, ty, 1.0, grass)
    return P


def kitten(d):
    wall, floor = "#F6E2CD", "#E4C29C"
    P = [f'<rect width="{W}" height="{H}" fill="{wall}"/>']
    for x in range(30, W, 90):
        P.append(f'<rect x="{x}" y="0" width="36" height="1190" fill="{light(wall, 0.35)}" opacity="0.55"/>')
    # the window
    wx0, wy0, wx1, wy1 = 130, 380, 560, 900
    P.append(d.fill(d.poly([(wx0 - 26, wy0 - 26), (wx1 + 26, wy0 - 26), (wx1 + 26, wy1 + 26), (wx0 - 26, wy1 + 26)], r=26, j=1.5, bow=3), "#FFF8EE"))
    pane = d.poly([(wx0, wy0), (wx1, wy0), (wx1, wy1), (wx0, wy1)], r=14, j=1, bow=2)
    P.append(d.fill(pane, "#BFE0F0", grad=("down", "#CFE7F3")))
    P.append(d.clipped(pane, lambda: [*sun(d, 470, 500, 46), cloud(d, 260, 560, 0.8), band(d, 820, 20, 500, "#B9D69B", 0.5, lw=2.5),
                                      *round_tree(d, 230, 850, 0.5, "#A5C58C")]))
    P.append(d.stroke(pane, dark("#FFF8EE", 0.35), 3))
    P.append(d.fill(d.poly([((wx0 + wx1) / 2 - 9, wy0), ((wx0 + wx1) / 2 + 9, wy0), ((wx0 + wx1) / 2 + 9, wy1), ((wx0 + wx1) / 2 - 9, wy1)], r=3, j=0.6, bow=1), "#FFF8EE", lw=2.6))
    P.append(d.fill(d.poly([(wx0, (wy0 + wy1) / 2 - 9), (wx1, (wy0 + wy1) / 2 - 9), (wx1, (wy0 + wy1) / 2 + 9), (wx0, (wy0 + wy1) / 2 + 9)], r=3, j=0.6, bow=1), "#FFF8EE", lw=2.6))
    P.append(d.fill(d.poly([(wx0 - 50, wy1 + 20), (wx1 + 50, wy1 + 20), (wx1 + 40, wy1 + 50), (wx0 - 40, wy1 + 50)], r=8, j=1, bow=2), "#E9C7A4"))
    for s, x in ((1, wx0 - 40), (-1, wx1 + 40)):
        cur = [(x - s * 30, wy0 - 60), (x + s * 70, wy0 - 60), (x + s * 56, wy0 + 220), (x + s * 30, wy0 + 300), (x + s * 50, wy1 + 10), (x - s * 26, wy1 + 10)]
        P.append(d.fill(d.blob(cur, 1.5), "#EE9F8C"))
        P.append(d.fill(d.oval(x + s * 30, wy0 + 290, 30, 12), "#F6CF6A", lw=2.6))
    P.append(d.fill(d.poly([(wx0 - 90, wy0 - 70), (wx1 + 90, wy0 - 70), (wx1 + 90, wy0 - 56), (wx0 - 90, wy0 - 56)], r=6, j=0.8, bow=1), "#C9996F", lw=2.6))
    # a framed picture of a fish
    fx0, fy0, fx1, fy1 = 720, 470, 940, 640
    P.append(d.fill(d.poly([(fx0, fy0), (fx1, fy0), (fx1, fy1), (fx0, fy1)], r=10, j=1, bow=2), "#D9A877"))
    P.append(d.fill(d.poly([(fx0 + 20, fy0 + 20), (fx1 - 20, fy0 + 20), (fx1 - 20, fy1 - 20), (fx0 + 20, fy1 - 20)], r=6, j=0.8, bow=1.5), "#DCEFF2", lw=2.4))
    fish = d.blob([(790, 556), (830, 528), (868, 548), (884, 556), (868, 566), (830, 586)], 0.6)
    P.append(d.fill(fish, "#F2A55E", lw=2.6))
    P.append(d.fill(d.poly([(792, 556), (764, 532), (768, 580)], r=5, j=0.4, bow=0.6), "#F2A55E", lw=2.6))
    P.append(d.dot(856, 550, 4, INK))
    P += bubbles(d, [(900, 520, 7), (912, 500, 4.5)])
    # skirting and floor
    P.append(d.fill(d.poly([(-20, 1170), (W + 20, 1170), (W + 20, 1206), (-20, 1206)], r=4, j=1, bow=2), "#EBCDB0", lw=3))
    P.append(f'<rect x="0" y="1204" width="{W}" height="{H - 1204}" fill="{d.grad(floor, ("down", light(floor, 0.15)))}"/>')
    for y in (1290, 1400, 1530, 1680, 1850):
        P.append(d.stroke(d.curve([(-10, y), (W / 2, y + 3), (W + 10, y)], 1.2), dark(floor, 0.14), 3))
    for x, y0, y1 in ((300, 1206, 1290), (760, 1206, 1290), (520, 1290, 1400), (160, 1400, 1530), (880, 1400, 1530), (420, 1530, 1680), (700, 1680, 1850)):
        P.append(d.stroke(d.curve([(x, y0), (x + 2, y1)], 0.6), dark(floor, 0.12), 2.6))
    # the rug, where the kitten sits
    P.append(d.fill(d.oval(540, 1440, 400, 118), "#EDA897"))
    P.append(d.fill(d.oval(540, 1440, 340, 92), "#F6CF8A", lw=2.6))
    P.append(d.fill(d.oval(540, 1440, 290, 74), "#EDA897", lw=2.6))
    for k in range(18):
        a = 2 * math.pi * k / 18
        P.append(d.dot(540 + 370 * math.cos(a), 1440 + 105 * math.sin(a), 6, "#FFF3E2", 0.9))
    # a floor cushion and a ball of wool
    P.append(d.fill(d.oval(170, 1290, 140, 64), "#B9A6D8"))
    P.append(d.fill(d.oval(170, 1262, 120, 44), light("#B9A6D8", 0.2), lw=2.6))
    P.append(d.fill(d.oval(170, 1262, 10, 8), dark("#B9A6D8", 0.2), lw=2))
    for a in (-120, -60, 0, 60, 120, 180):
        P.append(d.stroke(Path((170 + 20 * math.cos(math.radians(a)), 1262 + 8 * math.sin(math.radians(a))))
                          .L((170 + 100 * math.cos(math.radians(a)), 1262 + 36 * math.sin(math.radians(a)))), dark("#B9A6D8", 0.15), 2.4))
    yarn = d.oval(900, 1300, 50, 48)
    P.append(d.fill(yarn, "#93B5D6"))
    P.append(d.clipped(yarn, lambda: [d.stroke(d.curve([(850, 1300 + k), (900, 1270 + k), (952, 1300 + k)], 0.5), dark("#93B5D6", 0.22), 3) for k in (-30, -6, 18, 42)]))
    P.append(d.stroke(d.curve([(940, 1330), (990, 1362), (1050, 1352), (1100, 1380)], 0.8), "#93B5D6", 4))
    # a potted plant
    P.append(d.fill(d.poly([(944, 1160), (1050, 1160), (1036, 1240), (958, 1240)], r=8, j=1, bow=2), "#E59C82"))
    for ang, L in ((-120, 150), (-95, 190), (-70, 160), (-140, 110), (-45, 120)):
        P += leaf_shape(d, 997, 1162, L, 22, ang, LEAF)
    return P


def bunny(d):
    grass, soil = "#BBD79C", "#C9A07A"
    P = [backdrop(d, "#CBE5EE", "#F3F0DC", 1150)]
    P += sun(d, 210, 440, 66)
    P += [cloud(d, 760, 400, 0.95), cloud(d, 470, 640, 0.55)]
    P.append(band(d, 1010, 30, 1000, "#CFE1B4", 1.3, lw=2.5))
    P += round_tree(d, 140, 1030, 0.5, "#AFCB94") + round_tree(d, 900, 1010, 0.6, "#A5C58C", fruit="#F2A08F")
    P.append(band(d, 1100, 14, 1400, grass, 0.2, lw=3))
    P.append(band(d, 1620, 10, 1300, light(grass, 0.12), 2.1, line=False))
    # the path in the middle, where the bunny sits
    path = Path((470, 1100)).C((440, 1250), (330, 1500), (300, H + 20)).L((780, H + 20)).C((750, 1500), (640, 1250), (610, 1100))
    path.closed = True
    P.append(d.fill(path, "#F1DFBE", lw=2.6))
    # two vegetable beds
    for side in (-1, 1):
        cx = 540 + side * 330
        bed = d.blob([(cx - 190, 1290), (cx - 170, 1170), (cx, 1150), (cx + 170, 1170), (cx + 190, 1290), (cx, 1310)], 2)
        P.append(d.fill(bed, soil))
        for row, yy in enumerate((1196, 1250)):
            for k in range(4):
                x = cx - 120 + k * 80 + (row * 40) - 20
                if abs(x - 540) < 230:
                    continue
                for ang in (-110, -90, -70):
                    P += leaf_shape(d, x, yy, 54, 9, ang, LEAF2)[:1]
                P.append(d.fill(d.poly([(x - 16, yy - 2), (x + 16, yy - 2), (x + 4, yy + 26), (x - 4, yy + 26)], r=7, j=0.6, bow=1), "#F29A4C", lw=2.6))
    for fx, fy, c in ((90, 1360, "#F4A7A1"), (150, 1384, "#FFFFFF"), (960, 1364, "#F6CF6A"), (1010, 1390, "#F4A7A1"), (230, 1340, "#F6CF6A"),
                      (860, 1346, "#FFFFFF"), (60, 1450, "#F6CF6A"), (1030, 1470, "#FFFFFF")):
        P += flower(d, fx, fy, 1.0, c)
    # a watering can
    P.append(d.fill(d.poly([(160, 1520), (250, 1520), (244, 1600), (166, 1600)], r=12, j=1, bow=2), "#93B5D6"))
    P.append(d.tube(d.curve([(250, 1560), (300, 1520), (320, 1490)], 0.5), 12, "#93B5D6", lw=3))
    P.append(d.tube(d.curve([(176, 1520), (205, 1480), (234, 1520)], 0.5), 8, "#93B5D6", lw=3))
    for tx, ty in ((220, 1700), (860, 1660), (90, 1800), (980, 1820), (900, 1560)):
        P += tuft(d, tx, ty, 1.0, grass)
    return P


def dino(d):
    P = [backdrop(d, "#F7D8BA", "#F5EED6", 1200)]
    P += [cloud(d, 260, 420, 0.9, "#FFF8EF"), cloud(d, 860, 330, 0.7, "#FFF8EF")]
    # the friendly volcano, puffing little clouds
    vx, vb = 560, 1100
    volcano = d.blob([(vx - 330, vb + 40), (vx - 170, vb - 220), (vx - 90, vb - 360), (vx - 46, vb - 380), (vx + 46, vb - 380), (vx + 90, vb - 360),
                      (vx + 170, vb - 220), (vx + 330, vb + 40)], 2)
    P.append(d.fill(volcano, "#C9AE93"))
    P.append(d.fill(d.blob([(vx - 92, vb - 356), (vx - 46, vb - 384), (vx + 46, vb - 384), (vx + 92, vb - 356), (vx + 60, vb - 320), (vx + 20, vb - 340),
                            (vx - 10, vb - 314), (vx - 50, vb - 336)], 1), "#F2B07A", lw=2.6))
    P += face(d, vx, vb - 190, 2.2, sleepy=True)
    for k, (dx, dy, s) in enumerate(((0, -450, 0.42), (50, -540, 0.34), (10, -620, 0.26))):
        P.append(cloud(d, vx + dx, vb + dy, s, "#FFFDF8"))
    P.append(band(d, 1030, 30, 700, "#A9C9A6", 0.5, lw=2.5))
    for x, s in ((90, 0.5), (240, 0.42), (840, 0.46), (1000, 0.55)):
        P += round_tree(d, x, 1070, s, "#8FBA8E")
    P.append(band(d, 1150, 12, 1500, JUNGLE_FLOOR, 2.2, lw=3))
    P.append(band(d, 1600, 10, 1200, light(JUNGLE_FLOOR, 0.12), 1.4, line=False))
    P += palm(d, 110, 1330, 560, 60, 1.1, "#93BF7E")
    P += palm(d, 980, 1310, 500, -70, 1.0, "#9DC48A")
    for x, y, L, ang, c in ((20, 1300, 120, -75, "#86B47A"), (230, 1310, 110, -105, "#86B47A"), (1060, 1290, 120, -105, "#86B47A"),
                            (860, 1300, 110, -75, "#86B47A")):
        P += leaf_shape(d, x, y, L, 26, ang, c)
    P += bush(d, 90, 1356, 1.0, "#8FBA7E") + bush(d, 1000, 1346, 1.0, "#8FBA7E") + bush(d, 220, 1376, 0.6, "#A3C78C") + bush(d, 870, 1370, 0.6, "#A3C78C")
    for x, y, rot in ((330, 1530, -20), (390, 1600, -10), (330, 1680, -25)):
        prints = [d.fill(d.oval(0, 0, 13, 15), dark(JUNGLE_FLOOR, 0.12), line=False, grad=None)]
        prints += [d.dot(dx, -22, 5, dark(JUNGLE_FLOOR, 0.12)) for dx in (-11, 0, 11)]
        P.append(f'<g transform="translate({x} {y}) rotate({rot})">{"".join(prints)}</g>')
    for x, y, rx in ((330, 1420, 34), (780, 1440, 26), (200, 1640, 40), (900, 1700, 30)):
        P.append(d.fill(d.oval(x, y, rx, rx * 0.62), "#D8C9B4", lw=2.6))
    for tx, ty in ((420, 1320), (680, 1300), (120, 1520), (980, 1560), (520, 1760), (300, 1860)):
        P += tuft(d, tx, ty, 1.0, JUNGLE_FLOOR)
    for fx, fy, c in ((300, 1300, "#F4A7A1"), (760, 1310, "#F6CF6A")):
        P += flower(d, fx, fy, 0.9, c)
    return P


def dolphin(d):
    P = [backdrop(d, "#BBDBF0", "#F8E6D3", 1000)]
    P += sun(d, 800, 560, 68)
    P += [cloud(d, 230, 400, 0.95), cloud(d, 560, 300, 0.5), cloud(d, 960, 760, 0.5)]
    for x, y, s in ((330, 620, 1.0), (400, 680, 0.75)):
        P.append(d.stroke(smooth([(x - 22 * s, y), (x - 10 * s, y - 10 * s), (x, y), (x + 10 * s, y - 10 * s), (x + 22 * s, y)], closed=False), "#7E8FA6", 4 * s))
    # a little island far away
    P.append(d.fill(d.blob([(90, 1010), (150, 975), (240, 968), (320, 1004)], 1), "#E9D2A6", lw=2.6))
    P += palm(d, 200, 985, 120, 18, 0.32, "#93BF7E")
    # the sea, lighter far away
    sea = f'<rect x="0" y="1000" width="{W}" height="{H - 1000}" fill="{d.grad("#86B8DA", ("down", "#B3D8EA"))}"/>'
    P.append(sea)
    P.append(band(d, 1290, 10, 300, "#93C1DF", 0.3, line=False))
    P.append(band(d, 1700, 12, 360, "#80B3D7", 1.1, line=False))
    P.append(d.stroke(d.curve([(-10, 1000), (540, 1002), (1090, 1000)], 0.8), dark("#B3D8EA", 0.2), 3))
    for y, amp, wl, xs in ((1060, 5, 60, ((60, 260), (420, 640), (760, 1000))), (1140, 7, 80, ((0, 300), (700, 1080))),
                           (1240, 9, 100, ((-20, 260), (820, 1100))), (1420, 10, 120, ((-20, 180), (900, 1100)))):
        for x0, x1 in xs:
            P.append(waves(d, y, x0, x1, wl, amp, "#EAF5FB", 5, 0.75))
    for k, y in enumerate(range(1020, 1240, 26)):
        w = 70 - k * 6
        P.append(d.stroke(d.curve([(800 - w, y), (800 + w, y)], 0.8), "#FFF6DA", 6, 0.6))
    # ripples where the dolphin swims
    for rx, ry, o in ((240, 40, 0.75), (330, 60, 0.45)):
        P.append(d.stroke(d.oval(540, PET_Y - 6, rx, ry, wob=1.6), "#F2F9FC", 6, o))
    P += bubbles(d, [(160, 1460, 12), (190, 1420, 7), (900, 1500, 10), (930, 1462, 6)])
    return P


def octopus(d):
    sand = "#F1DDB2"
    P = [backdrop(d, "#C3E8EA", "#89C3D3", 1300)]
    for x, w in ((200, 70), (560, 54), (860, 80)):
        gid = d.uid("ray")
        d.defs.append(f'<linearGradient id="{gid}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0"/>'
                      f'<stop offset="0.3" stop-color="#FFFFFF" stop-opacity="0.16"/><stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/></linearGradient>')
        P.append(f'<path d="M{x - w / 2} 0L{x + w / 2} 0L{x + w * 1.6} 1250L{x - w * 0.6} 1250Z" fill="url(#{gid})"/>')
    # far reef
    P.append(band(d, 1080, 40, 520, "#7DB7C4", 0.9, lw=0, line=False))
    P.append(band(d, 1240, 16, 900, sand, 1.6, lw=3))
    for y, xs in ((1400, ((60, 300), (780, 1020))), (1560, ((420, 680),)), (1760, ((100, 360), (700, 980)))):
        for x0, x1 in xs:
            P.append(waves(d, y, x0, x1, 70, 6, dark(sand, 0.12), 3.5, 0.8))
    # seaweed swaying at both edges
    for x, h, c in ((40, 760, "#8DBE8A"), (110, 560, "#A3CB8F"), (1040, 720, "#8DBE8A"), (970, 520, "#A3CB8F")):
        pts = [(x + (18 if k % 2 else -18), 1300 - h * k / 6) for k in range(7)]
        P.append(d.tube(d.curve(pts, 2), 26, c, lw=3))
    # coral on the left and right
    def branch_coral(x, y, s, c):
        out = []
        for pts in ([(0, 0), (-4, -80), (-40, -150), (-46, -200)], [(-4, -80), (30, -140), (34, -190)], [(-24, -120), (-80, -150), (-92, -180)],
                    [(30, -140), (70, -160), (80, -196)]):
            out.append(d.tube(d.curve([(x + px * s, y + py * s) for px, py in pts], 1), 24 * s, c, lw=3))
        return out
    # a fan coral and tube corals behind
    fan = []
    for k in range(13):
        a = math.pi + math.pi * k / 12
        fan.append((70 + 130 * math.cos(a), 1290 + 150 * math.sin(a)))
    P.append(d.fill(d.blob(fan + [(70, 1300)], 2), "#C7A9DE"))
    P += [d.stroke(d.curve([(70, 1296), (70 + 110 * math.cos(math.pi + math.pi * k / 6), 1296 + 125 * math.sin(math.pi + math.pi * k / 6))], 1),
                   dark("#C7A9DE", 0.25), 3) for k in range(1, 6)]
    for x, h in ((960, 180), (1000, 240), (1040, 150)):
        P.append(d.fill(d.poly([(x - 18, 1310), (x - 20, 1310 - h), (x + 20, 1310 - h), (x + 18, 1310)], r=12, j=1, bow=2), "#F6C38E"))
        P.append(d.fill(d.oval(x, 1310 - h, 16, 7), dark("#F6C38E", 0.25), lw=2.4))
    for x, y, rx in ((120, 1330, 80), (980, 1330, 90), (420, 1346, 46), (650, 1352, 40)):
        P.append(d.fill(d.oval(x, y, rx, rx * 0.45), "#B9B2C9", lw=3))
    P += branch_coral(220, 1330, 1.25, "#F2A39A")
    P += branch_coral(880, 1320, 1.15, "#C7A9DE")
    P.append(d.fill(d.oval(330, 1316, 70, 48), "#F6C38E"))
    P += [d.stroke(d.curve([(278, 1310 + k), (330, 1290 + k), (382, 1310 + k)], 0.8), dark("#F6C38E", 0.25), 3) for k in (-14, 6, 26)]
    P.append(d.fill(d.oval(760, 1330, 60, 40), "#F2A39A"))
    for k in range(8):
        a = math.pi + math.pi * k / 7
        P.append(d.fill(d.oval(760 + 56 * math.cos(a), 1330 + 36 * math.sin(a), 12, 12), light("#F2A39A", 0.3), lw=2.2))
    # fish, bubbles, a starfish and shells
    for x, y, s, c, flip in ((200, 640, 1.0, "#F6C65C", 1), (880, 860, 0.85, "#F2A39A", -1), (780, 560, 0.6, "#C7A9DE", -1)):
        body = d.blob([(x - 40 * s * flip, y), (x - 6 * s * flip, y - 24 * s), (x + 30 * s * flip, y - 10 * s), (x + 36 * s * flip, y),
                       (x + 30 * s * flip, y + 10 * s), (x - 6 * s * flip, y + 24 * s)], 0.6)
        P.append(d.fill(d.poly([(x - 36 * s * flip, y), (x - 62 * s * flip, y - 22 * s), (x - 58 * s * flip, y + 22 * s)], r=6 * s, j=0.6, bow=1), c, lw=2.6))
        P.append(d.fill(body, c, lw=2.6))
        P.append(d.dot(x + 16 * s * flip, y - 4 * s, 4.5 * s, INK))
        P.append(d.dot(x + 14.6 * s * flip, y - 5.6 * s, 1.5 * s, "#FFFFFF"))
    P += bubbles(d, [(240, 560, 14), (262, 500, 9), (250, 450, 6), (860, 760, 12), (840, 700, 8), (850, 650, 5), (600, 380, 10), (620, 330, 6)])
    P += starfish(d, 170, 1460, 1.3, "#F29C84", 12)
    P.append(shell(d, 920, 1480, 1.3, "#F7D2C4", -12))
    P.append(shell(d, 380, 1720, 1.0, "#FBE3C2", 18))
    P += starfish(d, 900, 1760, 1.0, "#F6C65C", -8)
    return P


def turtle(d):
    sand = "#F5E1B8"
    P = [backdrop(d, "#C2E1F1", "#FBEBD8", 900)]
    P += sun(d, 230, 440, 70)
    P += [cloud(d, 760, 380, 0.95), cloud(d, 960, 650, 0.5)]
    P.append(f'<rect x="0" y="900" width="{W}" height="400" fill="{d.grad("#A6D6DE", ("down", "#93C6E0"))}"/>')
    P.append(d.stroke(d.curve([(-10, 900), (540, 902), (1090, 900)], 0.8), dark("#93C6E0", 0.2), 3))
    for y, xs in ((960, ((80, 300), (520, 760))), (1040, ((200, 460), (760, 1020)))):
        for x0, x1 in xs:
            P.append(waves(d, y, x0, x1, 70, 6, "#EAF6F8", 5, 0.8))
    P.append(band(d, 1104, 8, 160, "#FDF9F0", 0.4, line=False, bottom=1200))          # foam
    P.append(band(d, 1146, 10, 420, "#EDD3A2", 1.1, line=False))                       # wet sand
    foam = [f'<circle cx="{n(x)}" cy="{n(1112 + 10 * math.sin(x / 37))}" r="{n(9 + 6 * abs(math.sin(x / 23)))}"/>' for x in range(-10, W + 20, 34)]
    P.append(f'<g fill="#FDF9F0" opacity="0.9">{"".join(foam)}</g>')
    P.append(band(d, 1200, 10, 900, sand, 2.0, lw=3))
    P += palm(d, 1000, 1360, 600, -110, 1.1, "#93BF7E")
    # a sandcastle on the left
    P.append(d.fill(d.poly([(60, 1360), (60, 1270), (110, 1270), (110, 1240), (180, 1240), (180, 1270), (230, 1270), (230, 1360)], r=8, j=1.2, bow=2), "#EBCB94"))
    P.append(d.fill(d.poly([(90, 1360), (90, 1320), (110, 1300), (130, 1320), (130, 1360)], r=6), dark("#EBCB94", 0.2), lw=2.4))
    P.append(d.stroke(d.curve([(145, 1240), (145, 1180)], 0.3), "#B98A64", 4))
    P.append(d.fill(d.poly([(147, 1180), (190, 1194), (147, 1208)], r=4, j=0.5, bow=0.8), "#F29C84", lw=2.4))
    P.append(shell(d, 330, 1300, 1.1, "#F7D2C4", -14))
    P += starfish(d, 790, 1300, 1.1, "#F29C84", 10)
    P.append(shell(d, 880, 1450, 0.9, "#FBE3C2", 20))
    P.append(shell(d, 180, 1500, 0.9, "#F3C1B4", 6))
    P += starfish(d, 930, 1700, 0.9, "#F6C65C", -12)
    P.append(d.fill(d.oval(420, 1640, 10, 7), "#EFCFC4", lw=2))
    for x, y in ((610, 1320), (300, 1760), (700, 1820)):
        P.append(d.stroke(smooth([(x - 9, y), (x, y - 5), (x + 9, y)], closed=False), dark(sand, 0.2), 3))
    return P


HOMES = {"puppy": puppy, "kitten": kitten, "bunny": bunny, "dino": dino,
         "dolphin": dolphin, "octopus": octopus, "turtle": turtle}


def home_svg(hid):
    d = Doc(f"home-{hid}", lw=3)
    parts = HOMES[hid](d) + [grain(d)]
    return d.svg(parts, box=(0, 0, W, H))


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for hid in HOMES:
        (OUT / f"{hid}.svg").write_text(home_svg(hid))


if __name__ == "__main__":
    main()
