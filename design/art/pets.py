"""字母寵物's pets, eggs, items and growth wear, in the picture-book style
of storybook.py.

    python3 pets.py           # writes app/assets/art/{pets,eggs,items,wear}/

Pets
- pets/<id>.svg: the pet, cropped close; its lowest point is the bottom
  edge of the picture (the app stands pets on their feet).
- pets/<id>_happy.svg (eyes ^ ^) and pets/<id>_sleep.svg (eyes closed):
  the same picture and size with other eyes, to swap in place.
- pets/pets.json: per pet, in its picture's units: the size, where food
  goes (mouth), the head (a hat; where the eyes look from), the eye
  centres (and size), the body (where the sponge scrubs), and whether it
  lives in the sea.
Eggs: eggs/<id>.svg, and eggs/<id>_top.svg / _bottom.svg cracked in two
along a zigzag (same size as the whole egg); eggs/eggs.json: the size, the
wobble pivot (bottom centre) and the crack's points.
Items: items/<name>.svg, 120 x 120.  Wear: wear/bib.svg, wear/cap.svg and
wear/wear.json (where each one is pinned).
"""
import json
import math
import pathlib
import random
import zlib

from storybook import INK, Doc, Path, dark, light, mirror_pts, n, smooth

ROOT = pathlib.Path(__file__).resolve().parents[2]
ART = ROOT / "app" / "assets" / "art"

MOUTH_LINE = "#7A4B3A"
TONGUE = "#EE8F8C"
SEA = {"dolphin", "octopus", "turtle"}
PET_IDS = ["puppy", "kitten", "bunny", "dino", "dolphin", "octopus", "turtle"]


# ---------------------------------------------------------------- face bits
def toes(d, x, y, color, rx):
    """Two little lines on a foot."""
    c = dark(color, 0.5)
    return [d.stroke(d.curve([(x + dx, y - 4), (x + dx, y + 6)], 0.3), c, 2.4) for dx in (-rx * 0.28, rx * 0.28)]


def w_mouth(d, x, y, w=14, drop=7):
    """A little 'w' mouth hanging from the nose."""
    return [d.stroke(d.curve([(x, y - drop), (x, y)], 0.2), MOUTH_LINE, 3),
            d.stroke(smooth([(x - w, y - 3), (x - w * 0.5, y + 5), (x, y)], closed=False), MOUTH_LINE, 3),
            d.stroke(smooth([(x, y), (x + w * 0.5, y + 5), (x + w, y - 3)], closed=False), MOUTH_LINE, 3)]


def smile(d, x, y, w=16, h=8):
    return d.stroke(smooth([(x - w, y - h * 0.4), (x, y + h * 0.6), (x + w, y - h * 0.4)], closed=False), MOUTH_LINE, 3.2)


def face_meta(d, head, mouth, body):
    d.meta.update(head={"cx": head[0], "cy": head[1], "r": head[2]},
                  mouth={"x": mouth[0], "y": mouth[1]},
                  body={"x": body[0], "y": body[1], "w": body[2], "h": body[3]})


def chibi_body(d, fur, belly, y=334, rx=80, ry=74, feet_y=402, foot=(33, 21), paw_color=None, belly_line=False):
    """A small round body with feet and two little paws resting on the tummy."""
    P = [d.fill(d.oval(200, y, rx, ry), fur)]
    if belly:
        P.append(d.fill(d.oval(200, y + 18, rx * 0.62, ry * 0.62), belly, line=belly_line, lw=2.2))
    for x in (200 - rx * 0.5, 200 + rx * 0.5):
        P.append(d.fill(d.oval(x, feet_y, foot[0], foot[1]), paw_color or fur))
        P += toes(d, x, feet_y + 6, paw_color or fur, foot[0])
    for x, r in ((200 - rx * 0.42, 14), (200 + rx * 0.42, -14)):
        P.append(d.fill(d.oval(x, y + 30, 21, 18, rot=r), paw_color or fur))
    return P


# ---------------------------------------------------------------- the pets
PUPPY_FUR = "#E3B17D"


def puppy(d, hug=None):
    """The puppy. [hug](d) may add something it holds in front of its body
    (the app icon's letter block); it draws with its own random numbers,
    so the puppy itself comes out the same either way."""
    fur, ear, cream, spot, nose = PUPPY_FUR, "#A97750", "#FBECD6", "#CC9560", "#4E362E"
    P = [d.fill(d.blob([(256, 352), (282, 326), (302, 296), (316, 266), (330, 256), (338, 270), (326, 306), (302, 348), (274, 378)]), fur)]
    P += chibi_body(d, fur, cream)
    if hug:
        saved, d.rng = d.rng, random.Random(zlib.crc32(b"hug"))
        P += hug(d)
        d.rng = saved
    P.append(d.fill(d.oval(200, 180, 122, 106), fur))
    P.append(d.fill(d.oval(252, 172, 34, 31, rot=-12), spot, line=False))
    P.append(d.fill(d.oval(200, 230, 52, 35), cream, line=False))
    ear_pts = [(126, 92), (100, 100), (78, 132), (64, 180), (68, 226), (84, 254), (108, 252), (124, 222), (132, 176), (144, 118)]
    P.append(d.fill(d.blob(ear_pts), ear))
    P.append(d.fill(d.blob(mirror_pts(ear_pts, 200)), ear))
    P.append(d.eyes((155, 186, 13.5), (245, 186, 13.5)))
    P += [d.cheek(136, 222), d.cheek(264, 222)]
    tongue = Path((193, 231)).Q((200, 250), (207, 231))
    tongue.closed = True
    P.append(d.fill(tongue, TONGUE, lw=2.2))
    P += w_mouth(d, 200, 230)
    P.append(d.fill(d.oval(200, 213, 15, 10.5), nose, line=False))
    P.append(d.dot(195, 209.5, 3.6, "#FFFFFF", 0.55))
    face_meta(d, (200, 180, 114), (200, 236), (120, 260, 160, 160))
    return P


def kitten(d):
    fur, stripe, cream, pink, nose = "#F2A55E", "#D97F3E", "#FCEBD4", "#F5B2A6", "#E8847F"
    tail = d.curve([(250, 384), (296, 380), (328, 348), (334, 302), (320, 266), (298, 252)], 0.4)
    P = [d.tube(tail, 26, fur)]
    pts = tail.points(10)
    for i in (18, 28, 38, 46):
        (x0, y0), (x1, y1) = pts[i - 1], pts[i + 1]
        L = math.hypot(x1 - x0, y1 - y0) or 1
        nx, ny = -(y1 - y0) / L, (x1 - x0) / L
        x, y = pts[i]
        P.append(d.stroke(Path((x - nx * 9, y - ny * 9)).L((x + nx * 9, y + ny * 9)), stripe, 6))
    ear = [(100, 132), (110, 50), (124, 38), (138, 44), (184, 98)]
    inner = [(118, 118), (122, 66), (130, 60), (166, 100)]
    for pts_ in (ear, mirror_pts(ear, 200)):
        P.append(d.fill(d.poly(pts_, r=16), fur))
    for pts_ in (inner, mirror_pts(inner, 200)):
        P.append(d.fill(d.poly(pts_, r=12), pink, line=False))
    P += chibi_body(d, fur, cream, paw_color=None)
    for s in (1, -1):
        for y in (312, 334):
            x = 200 - s * 70
            P.append(d.stroke(d.curve([(x, y), (x + s * 12, y + 3)], 0.4), stripe, 5))
    P.append(d.fill(d.oval(200, 182, 122, 102), fur))
    for x, y0, y1 in ((200, 84, 110), (178, 90, 106), (222, 90, 106)):
        P.append(d.stroke(d.curve([(x, y0), (x + (x - 200) * 0.08, y1)], 0.3), stripe, 7))
    for s in (1, -1):
        for y in (164, 182):
            P.append(d.stroke(d.curve([(200 - s * 120, y), (200 - s * 100, y + 2)], 0.3), stripe, 6))
    P += [d.fill(d.oval(186, 228, 22, 17), cream, line=False), d.fill(d.oval(214, 228, 22, 17), cream, line=False)]
    P.append(d.eyes((154, 186, 13.5), (246, 186, 13.5)))
    P += [d.cheek(136, 216), d.cheek(264, 216)]
    whisk = dark(fur, 0.55)
    for s in (1, -1):
        P.append(d.stroke(d.curve([(200 - s * 52, 214), (200 - s * 98, 204)], 0.4), whisk, 2.4))
        P.append(d.stroke(d.curve([(200 - s * 52, 226), (200 - s * 96, 234)], 0.4), whisk, 2.4))
    P += w_mouth(d, 200, 228, 12, 6)
    P.append(d.fill(d.poly([(190, 211), (210, 211), (200, 221)], r=4, j=0.3, bow=0.6), nose, line=False))
    face_meta(d, (200, 182, 112), (200, 232), (120, 260, 160, 160))
    return P


def bunny(d):
    fur, inner, nose = "#F8F0E8", "#F3B4AE", "#EE9C9C"
    edge = dark(fur, 0.5)
    P = [d.fill(d.oval(270, 374, 24, 22), "#FFFDF8", edge=edge)]
    for cx, cy, rot in ((158, 58, -10), (244, 60, 12)):
        P.append(d.fill(d.oval(cx, cy, 28, 74, rot=rot), fur, edge=edge))
        P.append(d.fill(d.oval(cx + rot * 0.15, cy + 8, 14, 54, rot=rot), inner, line=False))
    body = d.oval(200, 334, 78, 72)
    P.append(d.fill(body, fur, edge=edge))
    for x in (160, 240):
        P.append(d.fill(d.oval(x, 404, 36, 20), fur, edge=edge))
        P.append(d.fill(d.oval(x, 408, 12, 8), inner, line=False))
    for x, r in ((167, 14), (233, -14)):
        P.append(d.fill(d.oval(x, 364, 20, 17, rot=r), fur, edge=edge))
    P.append(d.fill(d.oval(200, 190, 112, 98), fur, edge=edge))
    P.append(d.eyes((158, 194, 13), (242, 194, 13)))
    P += [d.cheek(140, 226), d.cheek(260, 226)]
    P += w_mouth(d, 200, 230, 11, 7)
    P.append(d.fill(d.poly([(189, 213), (211, 213), (200, 224)], r=5, j=0.3, bow=0.6), nose, line=False))
    face_meta(d, (200, 190, 105), (200, 233), (122, 262, 156, 150))
    return P


def dino(d):
    skin, belly, plate = "#A6C68E", "#F6E9C6", "#F0B566"
    spot = dark(skin, 0.16)
    tail = [(244, 318), (292, 334), (336, 356), (372, 372), (378, 384), (356, 392), (300, 398), (250, 396)]
    P = []
    for x, y, s in ((300, 336, 15), (336, 356, 12)):
        P.append(d.fill(d.poly([(x - s, y + 4), (x + s * 0.2, y - s * 1.7), (x + s * 1.2, y + 4)], r=7), plate))
    P.append(d.fill(d.blob(tail), skin))
    for x, y, s in ((200, 82, 28), (160, 92, 22), (240, 92, 22)):
        P.append(d.fill(d.poly([(x - s, y + 10), (x, y - s * 1.3), (x + s, y + 10)], r=10), plate))
    P += chibi_body(d, skin, belly)
    for y in (344, 366):
        P.append(d.stroke(d.curve([(176, y), (200, y + 5), (224, y)], 0.3), dark(belly, 0.3), 2.4))
    P.append(d.fill(d.oval(200, 180, 118, 104), skin))
    P += [d.dot(146, 116, 10, spot), d.dot(170, 100, 6, spot), d.dot(250, 106, 8, spot), d.dot(272, 126, 5, spot),
          d.dot(132, 300, 7, spot), d.dot(268, 304, 6, spot)]
    P.append(d.eyes((158, 186, 13.5), (242, 186, 13.5)))
    P += [d.cheek(138, 220), d.cheek(262, 220)]
    P += [d.dot(190, 212, 3.4, dark(skin, 0.6)), d.dot(210, 212, 3.4, dark(skin, 0.6))]
    P.append(smile(d, 200, 228, 18, 9))
    face_meta(d, (200, 180, 111), (200, 232), (120, 260, 160, 160))
    return P


def dolphin(d):
    skin, belly = "#90B6D8", "#F3F1E8"
    body = d.blob([(226, 60), (274, 68), (306, 96), (320, 128), (346, 138), (368, 150), (370, 167), (350, 177),
                   (316, 182), (302, 214), (290, 262), (268, 314), (240, 352), (212, 380), (192, 396),
                   (162, 398), (150, 368), (140, 318), (134, 258), (136, 190), (148, 126), (178, 80)], 0.6)
    fin = d.blob([(146, 178), (112, 168), (88, 176), (100, 200), (138, 244)], 0.6)
    flukes = d.blob([(178, 384), (150, 392), (116, 392), (96, 404), (114, 420), (150, 424), (177, 414),
                     (204, 424), (240, 420), (258, 404), (238, 392), (204, 392)], 0.6)
    P = [d.fill(fin, skin), d.fill(flukes, skin), d.fill(body, skin)]
    P.append(d.clipped(body, lambda: [d.fill(d.oval(332, 268, 70, 180, rot=26), belly, line=False)]))
    P.append(d.fill(body, skin, grad=None).replace(f'fill="{skin}"', 'fill="none"'))
    P.append(d.fill(d.oval(296, 282, 36, 16, rot=48), skin))
    P.append(d.eyes((272, 128, 13.5)))
    P.append(d.cheek(296, 158, 13, 8))
    P.append(d.stroke(smooth([(364, 162), (340, 169), (318, 163), (311, 154)], closed=False), MOUTH_LINE, 3))
    face_meta(d, (236, 140, 84), (360, 165), (136, 150, 166, 240))
    return P


def octopus(d):
    skin, sucker = "#C3A2D3", "#F6E0EC"
    left = [[(150, 232), (110, 248), (76, 250), (56, 236), (62, 218)],                    # waving, behind
            [(156, 258), (120, 300), (92, 336), (78, 366), (86, 388), (106, 386)],
            [(186, 268), (182, 326), (172, 370), (162, 394), (142, 400), (130, 390)]]
    arms = [d.curve(pts, 0.5) for pts in left] + [d.curve(mirror_pts(pts, 200), 0.5) for pts in left]
    order = [0, 3, 1, 4, 2, 5]
    P = [d.tube(arms[k], 30, skin) for k in order]
    for k in order:
        pts = arms[k].points(10)
        for i in range(len(pts) - 16, len(pts) - 2, 5):
            x, y = pts[i]
            P.append(d.dot(x, y, 3.6, sucker))
    P.append(d.fill(d.oval(200, 182, 128, 122), skin))
    P += [d.dot(150, 108, 13, light(skin, 0.3)), d.dot(250, 92, 9, light(skin, 0.3)), d.dot(274, 130, 6, light(skin, 0.3))]
    P.append(d.eyes((160, 212, 14), (240, 212, 14)))
    P += [d.cheek(130, 240), d.cheek(270, 240)]
    P.append(smile(d, 200, 240, 14, 8))
    face_meta(d, (200, 182, 124), (200, 244), (72, 60, 256, 250))
    return P


def turtle(d):
    skin, shell, scute = "#A2CDB0", "#C9995E", "#E0B97A"
    P = []
    for s in (1, -1):
        P.append(d.fill(d.oval(200 - s * 140, 270, 46, 22, rot=s * 28), skin))
    shell_path = d.oval(200, 230, 154, 120)
    P.append(d.fill(shell_path, shell))
    def scutes():
        out = []
        for cx, cy, r in ((200, 170, 42), (122, 200, 36), (278, 200, 36), (146, 278, 34), (254, 278, 34), (200, 108, 30),
                          (60, 250, 32), (340, 250, 32)):
            pts = [(cx + r * math.cos(math.radians(60 * k + 30)), cy + r * math.sin(math.radians(60 * k + 30))) for k in range(6)]
            out.append(d.fill(d.poly(pts, r=8, j=1.2), scute, lw=2.6))
        return out
    P.append(d.clipped(shell_path, scutes))
    P.append(d.fill(shell_path, shell, grad=None).replace(f'fill="{shell}"', 'fill="none"'))
    for s in (1, -1):
        P.append(d.fill(d.oval(200 - s * 92, 392, 38, 20, rot=s * 10), skin))
        P += toes(d, 200 - s * 92, 398, skin, 38)
    P.append(d.fill(d.oval(200, 318, 96, 86), skin))
    P += [d.dot(150, 266, 7, dark(skin, 0.14)), d.dot(254, 262, 5, dark(skin, 0.14)), d.dot(240, 250, 4, dark(skin, 0.14))]
    P.append(d.eyes((162, 320, 13), (238, 320, 13)))
    P += [d.cheek(144, 350), d.cheek(256, 350)]
    P.append(smile(d, 200, 352, 15, 8))
    face_meta(d, (200, 318, 90), (200, 356), (46, 110, 308, 240))
    return P


PETS = {"puppy": puppy, "kitten": kitten, "bunny": bunny, "dino": dino,
        "dolphin": dolphin, "octopus": octopus, "turtle": turtle}


def draw_pet(pid, mode="open"):
    d = Doc(pid)
    d.eye_mode = mode
    parts = PETS[pid](d)
    return d, parts


def shift(meta, dx, dy):
    """[meta]'s points moved into the cropped picture."""
    r = lambda v: round(v, 1)
    return {
        "mouth": {"x": r(meta["mouth"]["x"] + dx), "y": r(meta["mouth"]["y"] + dy)},
        "head": {"cx": r(meta["head"]["cx"] + dx), "cy": r(meta["head"]["cy"] + dy), "r": meta["head"]["r"]},
        "eyes": [{"x": r(e["x"] + dx), "y": r(e["y"] + dy), "r": e["r"]} for e in meta["eyes"]],
        "body": {"x": r(meta["body"]["x"] + dx), "y": r(meta["body"]["y"] + dy), "w": meta["body"]["w"], "h": meta["body"]["h"]},
    }


def write_pets():
    out = ART / "pets"
    out.mkdir(parents=True, exist_ok=True)
    info = {}
    for pid in PET_IDS:
        d, parts = draw_pet(pid)
        (out / f"{pid}.svg").write_text(d.svg(parts))
        box = d.box[:]
        for mode in ("happy", "sleep"):
            v, vparts = draw_pet(pid, mode)
            # the same crop as the open eyes, so the files swap in place
            (out / f"{pid}_{mode}.svg").write_text(v.svg(vparts, box=(box[0] - 5, box[1] - 5, box[2] + 5, box[3])))
        dx, dy = d.offset
        w, h = d.size
        info[pid] = {"viewBox": {"width": w, "height": h}, **shift(d.meta, dx, dy), "sea": pid in SEA}
    (out / "pets.json").write_text(json.dumps(info, indent=2, ensure_ascii=False) + "\n")
    return info


# ---------------------------------------------------------------- eggs
EGG_W, EGG_H, EGG_LW = 200, 250, 4.0
CRACK_Y = 124


def egg_outline():
    """The one egg shape every egg shares (narrower at the top)."""
    R = random.Random(zlib.crc32(b"egg-shape"))
    pts = []
    for i in range(48):
        a = 2 * math.pi * i / 48
        x = 100 + 84 * math.cos(a) * (1 + 0.09 * math.sin(a))
        y = 134 + 112 * math.sin(a)
        pts.append((x + R.uniform(-0.6, 0.6), y + R.uniform(-0.6, 0.6)))
    path = smooth(pts)
    low = max(y for _, y in path.points())
    return path.moved(0, EGG_H - EGG_LW / 2 - low)


def zigzag():
    """Where the egg cracks: a zigzag across, a little above the middle."""
    teeth = [-11, 10, -9, 12, -10, 9, -12, 10, -9, 11, -10, 12, -9]
    return [(-10 + 18.5 * k, CRACK_Y + t) for k, t in enumerate(teeth)]


def egg_halves(outline):
    """The egg cut along the zigzag: (top, bottom) as closed paths."""
    pts = outline.points(6)[:-1]
    zig = zigzag()

    def z(x):
        for (x0, y0), (x1, y1) in zip(zig, zig[1:]):
            if x0 <= x <= x1:
                return y0 + (y1 - y0) * (x - x0) / (x1 - x0)
        return CRACK_Y

    f = [p[1] - z(p[0]) for p in pts]
    m = len(pts)
    start = next(i for i in range(m) if f[i] < 0 <= f[i - 1])     # going into the top half (left side)
    end = next(i for i in range(m) if f[i - 1] < 0 <= f[i])       # coming out of it (right side)

    def cross(i):
        (x0, y0), (x1, y1) = pts[i - 1], pts[i]
        t = f[i - 1] / (f[i - 1] - f[i])
        return (x0 + (x1 - x0) * t, y0 + (y1 - y0) * t)

    a, b = cross(start), cross(end)
    run = lambda i, j: [pts[k % m] for k in range(i, j if j > i else j + m)]
    inner = [p for p in zig if a[0] < p[0] < b[0]]
    top = [a, *run(start, end), b, *reversed(inner)]
    bottom = [b, *run(end, start), a, *inner]

    def poly(ps):
        path = Path(ps[0])
        for p in ps[1:]:
            path.L(p)
        path.closed = True
        return path
    return poly(top), poly(bottom)


def carrot(d, x, y, rot, s=1.0):
    body = d.poly([(-9 * s, -11 * s), (9 * s, -11 * s), (1.8 * s, 17 * s), (-1.8 * s, 17 * s)], r=4 * s, j=0.3, bow=0.6)
    leaves = [d.fill(d.oval(dx * s, -16 * s, 3.6 * s, 7 * s, rot=dx * 6), "#86B86A", lw=1.8) for dx in (-4, 0, 4)]
    lines = [d.stroke(Path((-5 * s, yy * s)).L((-1 * s, yy * s)), "#D9793A", 1.8) for yy in (-3, 5)]
    return f'<g transform="translate({n(x)} {n(y)}) rotate({rot})">{"".join(leaves)}{d.fill(body, "#F29A4C", lw=2)}{"".join(lines)}</g>'


def hexagon(cx, cy, r):
    return [(cx + r * math.cos(math.radians(60 * k + 30)), cy + r * math.sin(math.radians(60 * k + 30))) for k in range(6)]


def wave_band(y, amp, wl, fill, crest, d):
    """Sea below a wavy line at [y], with a light crest along it."""
    top = Path((-10, y))
    x = -10
    k = 0
    while x < 210:
        top.Q((x + wl / 4, y - amp if k % 2 == 0 else y + amp), (x + wl / 2, y))
        x += wl / 2
        k += 1
    line = top.d()
    area = Path(top.start)
    area.segs = list(top.segs)
    area.L((210, 260)).L((-10, 260))
    area.closed = True
    return [f'<path d="{area.d()}" fill="{fill}"/>',
            f'<path d="{line}" fill="none" stroke="{crest}" stroke-width="5" stroke-linecap="round"/>']


def egg_pattern(d, pid):
    """What is painted on each egg: a hint of the pet inside."""
    P = []
    if pid == "puppy":
        for x, y, rx, ry, rot in ((62, 84, 24, 20, 20), (136, 60, 15, 12, -10), (150, 152, 28, 24, 15), (56, 190, 21, 17, -20),
                                  (112, 226, 14, 11, 0), (186, 104, 16, 22, 0), (98, 134, 9, 8, 0), (18, 130, 14, 20, 0)):
            P.append(d.fill(d.oval(x, y, rx, ry, rot=rot), "#BC8758", line=False))
    elif pid == "kitten":
        c = "#E58C47"
        for k, y in enumerate((74, 120, 166, 210)):
            L = 54 + (k % 2) * 10
            P.append(d.fill(d.blob([(6, y - 11), (L - 8, y - 4), (L, y + 1), (L - 8, y + 6), (6, y + 12)], 0.6), c, line=False))
            R = 50 + ((k + 1) % 2) * 10
            P.append(d.fill(d.blob([(194, y - 9), (200 - R + 8, y - 2), (200 - R, y + 3), (200 - R + 8, y + 8), (194, y + 14)], 0.6), c, line=False))
        for x0, x1 in ((86, 90), (100, 100), (114, 110)):
            P.append(d.fill(d.blob([(x0 - 6, 22), (x0 + 6, 22), (x1 + 2, 56), (x1 - 2, 56)], 0.4), c, line=False))
    elif pid == "bunny":
        for x, y, rot in ((60, 74, -20), (140, 66, 18), (100, 138, -6), (48, 178, 24), (152, 176, -24), (102, 220, 10)):
            P.append(carrot(d, x, y, rot))
        for x, y in ((100, 84), (30, 124), (170, 120), (76, 226), (130, 210), (128, 108), (72, 140)):
            P.append(d.dot(x, y, 3.2, "#FFF7F2", 0.9))
    elif pid == "dino":
        for x, y, r in ((64, 70, 14), (128, 54, 10), (150, 112, 16), (84, 130, 11), (40, 160, 13), (120, 176, 15),
                        (170, 186, 10), (70, 214, 12), (140, 230, 10), (100, 92, 7), (30, 104, 9), (184, 146, 8)):
            P.append(d.fill(d.oval(x, y, r, r * 0.92), light("#B5D29A", 0.3), lw=2.2, edge=dark("#B5D29A", 0.3)))
            P.append(d.dot(x - r * 0.3, y - r * 0.32, r * 0.25, "#FFFFFF", 0.55))
    elif pid == "dolphin":
        P += wave_band(150, 9, 40, "#97BCDF", "#EAF4FB", d)
        P += wave_band(196, 9, 40, "#84ADD6", "#DCEBF7", d)
        for x, y, r in ((60, 76, 8), (76, 56, 5), (138, 84, 6), (150, 64, 3.5)):
            P.append(f'<circle cx="{x}" cy="{y}" r="{r}" fill="#F2F8FC" fill-opacity="0.45" stroke="#F2F8FC" stroke-width="2"/>')
    elif pid == "octopus":
        for x, y, r in ((58, 70, 11), (82, 92, 8), (100, 112, 6), (140, 62, 9), (158, 88, 12), (40, 132, 9), (60, 158, 12),
                        (150, 142, 10), (128, 176, 8), (168, 192, 9), (90, 200, 11), (54, 214, 7), (126, 226, 9), (110, 44, 6)):
            P.append(f'<circle cx="{x}" cy="{y}" r="{r}" fill="#F3DDEA" stroke="{dark("#CDB1DC", 0.28)}" stroke-width="2"/>')
            P.append(f'<circle cx="{x}" cy="{y}" r="{n(r * 0.45)}" fill="#E2BFD8"/>')
    elif pid == "turtle":
        R = 23
        for row in range(-1, 13):
            for col in range(-1, 6):
                cx = col * math.sqrt(3) * R + (row % 2) * math.sqrt(3) / 2 * R + 8
                cy = row * 1.5 * R + 10
                P.append(d.fill(d.poly(hexagon(cx, cy, R - 3.5), r=5, j=0.7, bow=0.8), "#C3E1C8", lw=2.4, edge="#7FAE8E", grad=None))
    return P


EGGS = {"puppy": "#F2DCBD", "kitten": "#F8C892", "bunny": "#F7CACB", "dino": "#B5D29A",
        "dolphin": "#A9C8E4", "octopus": "#CDB1DC", "turtle": "#A8D0B2"}
EGG_PATH = egg_outline()
EGG_TOP, EGG_BOTTOM = egg_halves(EGG_PATH)


def egg_parts(d, pid, part="whole"):
    """An egg in its own 200 x 250 units: whole, or its top or bottom half."""
    base = EGGS[pid]
    area = {"whole": EGG_PATH, "top": EGG_TOP, "bottom": EGG_BOTTOM}[part]
    saved, d.rng = d.rng, random.Random(zlib.crc32(f"egg-{pid}".encode()))   # the same egg everywhere

    def inside():
        return [*egg_pattern(d, pid),
                d.speckle(0, 0, EGG_W, EGG_H, 110, [dark(base, 0.55), "#FFFFFF"], 0.5, 1.4, 0.22),
                d.fill(d.oval(64, 82, 15, 30, rot=24), "#FFFFFF", line=False, grad=None, opacity=0.35)]
    P = [d.fill(area, base, line=False, grad=("at", 76, 92, 200)),
         d.clipped(area, inside),
         d.stroke(area, dark(base, 0.4), EGG_LW)]
    d.rng = saved
    return P


def write_eggs():
    out = ART / "eggs"
    out.mkdir(parents=True, exist_ok=True)
    for pid in PET_IDS:
        for part, suffix in (("whole", ""), ("top", "_top"), ("bottom", "_bottom")):
            d = Doc(f"egg-{pid}")
            (out / f"{pid}{suffix}.svg").write_text(d.svg(egg_parts(d, pid, part), box=(0, 0, EGG_W, EGG_H)))
    info = {"egg": {"viewBox": {"width": EGG_W, "height": EGG_H},
                    "wobble": {"x": EGG_W / 2, "y": EGG_H},
                    "crack": [[round(x, 1), round(y, 1)] for x, y in zigzag()]},
            "ids": PET_IDS}
    (out / "eggs.json").write_text(json.dumps(info, indent=2) + "\n")


# ---------------------------------------------------------------- items (120 x 120)
CORAL, MUSTARD, SAGE, DUSTY, PEACH, LILAC, WOOD = "#EE9A86", "#F2C45C", "#A9C79A", "#93B5D6", "#F6C6A2", "#BFA6D9", "#D6A16D"


def tiny_face(d, x, y, s=1.0, sleepy=False):
    """Two dot eyes, a smile and rosy cheeks (moon, star)."""
    P = []
    for dx in (-9 * s, 9 * s):
        if sleepy:
            P.append(d.stroke(smooth([(x + dx - 4 * s, y - 1 * s), (x + dx, y + 2.5 * s), (x + dx + 4 * s, y - 1 * s)], closed=False), INK, 2.2 * s))
        else:
            P.append(d.dot(x + dx, y, 2.8 * s, INK))
            P.append(d.dot(x + dx - 0.9 * s, y - 1 * s, 0.95 * s, "#FFFFFF"))
    P.append(d.stroke(smooth([(x - 4 * s, y + 5 * s), (x, y + 8 * s), (x + 4 * s, y + 5 * s)], closed=False), MOUTH_LINE, 2 * s))
    P += [d.cheek(x - 14 * s, y + 5 * s, 4.5 * s, 3 * s), d.cheek(x + 14 * s, y + 5 * s, 4.5 * s, 3 * s)]
    return P


def bubble(d, x, y, r):
    d.track([(x, y)], r + 1)
    return (f'<circle cx="{n(x)}" cy="{n(y)}" r="{n(r)}" fill="#E6F3FB" fill-opacity="0.6" stroke="#8DBADB" stroke-width="2"/>'
            + d.dot(x - r * 0.35, y - r * 0.35, r * 0.25, "#FFFFFF", 0.9))


def star_path(d, x, y, R, r, rot=-90, corner=None):
    pts = []
    for k in range(10):
        a = math.radians(rot + 36 * k)
        rr = R if k % 2 == 0 else r
        pts.append((x + rr * math.cos(a), y + rr * math.sin(a)))
    return d.poly(pts, r=corner if corner is not None else R * 0.12, j=R * 0.012, bow=R * 0.02)


def heart_path(d, x, y, s):
    pts = []
    for i in range(36):
        t = 2 * math.pi * i / 36
        hx = 16 * math.sin(t) ** 3
        hy = -(13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t))
        pts.append((x + hx * s, y + hy * s))
    return d.blob(pts, 0.3)


def crescent(cx, cy, R, ox, oy, r, m=48):
    """Points round a crescent: the circle (cx, cy, R) less the circle (ox, oy, r)."""
    start = math.atan2(oy - cy, ox - cx)     # towards the bite, so the outer arc runs horn to horn
    outer = []
    for i in range(m + 1):
        a = start + 2 * math.pi * i / m
        x, y = cx + R * math.cos(a), cy + R * math.sin(a)
        if math.hypot(x - ox, y - oy) > r:
            outer.append((x, y))
    a0 = math.atan2(outer[-1][1] - oy, outer[-1][0] - ox)
    a1 = math.atan2(outer[0][1] - oy, outer[0][0] - ox)
    for way in (1, -1):
        span = ((a1 - a0) * way) % (2 * math.pi)
        inner = [(ox + r * math.cos(a0 + way * span * k / 16), oy + r * math.sin(a0 + way * span * k / 16)) for k in range(1, 16)]
        if all(math.hypot(x - cx, y - cy) < R + 0.5 for x, y in inner):
            return outer + inner
    return outer


def bowl(d):
    kib = "#C88B54"
    P = [d.fill(d.oval(60, 62, 44, 10), dark(CORAL, 0.3))]
    for x, y, rot in ((34, 60, 10), (46, 52, -20), (60, 48, 15), (74, 52, -10), (86, 60, 20), (40, 64, 0), (54, 60, 30),
                      (68, 60, -25), (80, 65, 5), (60, 66, 0), (48, 40, 35), (64, 37, -15), (76, 44, 10)):
        P.append(d.fill(d.oval(x, y, 7.5, 5.5, rot=rot), kib, lw=2))
    front = Path((14, 62)).Q((60, 80), (106, 62)).Q((104, 86), (94, 100)).Q((60, 112), (26, 100)).Q((16, 86), (14, 62))
    front.closed = True
    P.append(d.fill(front, CORAL))
    P.append(d.stroke(smooth([(22, 72), (60, 86), (98, 72)], closed=False), light(CORAL, 0.45), 4))
    P.append(d.fill(d.oval(60, 96, 7, 5.5), light(CORAL, 0.55), line=False, grad=None))   # a paw print
    for dx, dy in ((-8, -6), (-3, -10), (3, -10), (8, -6)):
        P.append(d.dot(60 + dx, 96 + dy, 2.4, light(CORAL, 0.55)))
    return P


def biscuit(d, x, y, r, dough="#E6B26C", letter=False, lw=None):
    """A round biscuit with a crimped edge and a smooth middle (the app prints
    the letter there); [letter] paints an A on it (the feast)."""
    pts = []
    for i in range(32):
        a = 2 * math.pi * i / 32
        rr = r * (1.0 if i % 2 == 0 else 0.94)
        pts.append((x + rr * math.cos(a), y + rr * math.sin(a)))
    P = [d.fill(d.blob(pts, r * 0.006), dough, lw=lw)]
    P.append(d.fill(d.oval(x, y, r * 0.7, r * 0.7), light(dough, 0.22), lw=max(1.4, r * 0.035), edge=dark(dough, 0.22)))
    for k in range(12):
        a = 2 * math.pi * (k + 0.5) / 12
        P.append(d.dot(x + r * 0.83 * math.cos(a), y + r * 0.83 * math.sin(a), r * 0.04, dark(dough, 0.35), 0.8))
    if letter:
        icing = "#FFF3DE"
        P.append(d.tube(Path((x - r * 0.32, y + r * 0.36)).L((x, y - r * 0.4)).L((x + r * 0.32, y + r * 0.36)), r * 0.16, icing, lw=1.4))
        P.append(d.tube(Path((x - r * 0.17, y + r * 0.08)).L((x + r * 0.17, y + r * 0.08)), r * 0.14, icing, lw=1.4))
    return P


def cookie(d):
    return biscuit(d, 60, 60, 50)


def sponge(d):
    yel = "#F6D46A"
    body = d.poly([(16, 50), (102, 42), (106, 92), (20, 100)], r=16, j=0.8, bow=2)
    P = [d.fill(body, yel)]
    for x, y, rx, ry in ((36, 66, 5, 4), (58, 60, 4, 3), (80, 58, 6, 4.5), (46, 84, 4.5, 3.5), (70, 80, 6, 4), (92, 78, 3.5, 3), (28, 86, 3, 2.5)):
        P.append(d.fill(d.oval(x, y, rx, ry), dark(yel, 0.2), line=False, grad=None))
    P += [bubble(d, 26, 34, 10), bubble(d, 46, 20, 7), bubble(d, 96, 26, 12), bubble(d, 74, 30, 5)]
    return P


def shower(d):
    metal, water = "#A9C2D6", "#86BDE5"
    P = [d.tube(d.curve([(108, 8), (104, 26), (86, 34), (70, 38)], 0.4), 9, metal, lw=2.4)]
    P.append(d.fill(d.poly([(56, 28), (78, 40), (66, 66), (30, 46)], r=10, j=0.5, bow=1), metal))
    P.append(d.fill(d.oval(48, 57, 21, 8, rot=28), light(metal, 0.3)))
    for t in (-0.6, -0.2, 0.2, 0.6):
        P.append(d.dot(48 + 16 * t * math.cos(math.radians(28)), 57 + 16 * t * math.sin(math.radians(28)), 1.8, dark(metal, 0.45)))
    for x, y in ((26, 76), (40, 82), (54, 88), (30, 98), (46, 104), (62, 100), (20, 92), (70, 82)):
        drop = Path((x, y - 9)).Q((x + 6, y + 1), (x, y + 5)).Q((x - 6, y + 1), (x, y - 9))
        drop.closed = True
        P.append(d.fill(drop, water, lw=1.8))
    return P


def ball(d):
    body = d.oval(60, 62, 44, 44)
    P = [d.fill(body, CORAL)]
    P.append(d.clipped(body, lambda: [
        d.fill(d.blob([(10, 44), (60, 30), (112, 44), (112, 60), (60, 46), (10, 60)], 0.5), "#FFF3DE", line=False),
        d.fill(d.blob([(10, 80), (60, 94), (112, 80), (112, 94), (60, 108), (10, 94)], 0.5), MUSTARD, line=False)]))
    P.append(d.stroke(body, dark(CORAL), 3.5))
    P.append(d.fill(d.oval(42, 40, 9, 5, rot=-35), "#FFFFFF", line=False, grad=None, opacity=0.55))
    return P


def bubbleBall(d):
    P = ['<circle cx="60" cy="60" r="48" fill="#E3F2FB" fill-opacity="0.55" stroke="#86B6DB" stroke-width="3"/>']
    d.track([(60, 60)], 50)
    P.append(d.stroke(smooth([(26, 86), (42, 100), (64, 104)], closed=False), "#F6B8C8", 5, 0.8))
    P.append(d.stroke(smooth([(92, 34), (100, 50), (102, 66)], closed=False), "#AEE3CC", 5, 0.8))
    P.append(d.stroke(smooth([(80, 96), (94, 84)], closed=False), "#D9C4F0", 4, 0.8))
    P.append(d.fill(d.oval(40, 38, 12, 7, rot=-38), "#FFFFFF", line=False, grad=None, opacity=0.85))
    P.append(d.dot(30, 54, 3, "#FFFFFF", 0.85))
    P += [bubble(d, 98, 100, 7), bubble(d, 106, 14, 5)]
    return P


def moon(d):
    col = "#F5DC8A"
    P = [d.fill(d.blob(crescent(54, 64, 46, 80, 46, 38), 0.3), col)]
    P += tiny_face(d, 32, 74, 0.95, sleepy=True)
    for x, y, r in ((96, 26, 4.5), (104, 50, 2.8), (78, 14, 2.6)):
        P.append(d.fill(star_path(d, x, y, r * 2.2, r), MUSTARD, lw=1.6))
    return P


def star(d):
    P = [d.fill(star_path(d, 60, 64, 52, 26, corner=9), "#F6CF5C")]
    P += tiny_face(d, 60, 66, 1.1)
    return P


def heart(d):
    P = [d.fill(heart_path(d, 60, 58, 3.0), "#EF8A88")]
    P.append(d.fill(d.oval(38, 40, 8, 5, rot=-40), "#FFFFFF", line=False, grad=None, opacity=0.6))
    return P


def gift_box(d, lid=True):
    box, rib = CORAL, MUSTARD
    body = d.poly([(20, 56), (100, 56), (98, 108), (22, 108)], r=7)
    P = []
    if not lid:
        P.append(d.fill(d.poly([(22, 50), (98, 50), (100, 62), (20, 62)], r=4), dark(box, 0.35)))
    P.append(d.fill(body, box))
    P.append(d.clipped(body, lambda: [d.dot(x, y, 3.4, "#FFF3DE", 0.8) for x, y in ((32, 70), (36, 94), (84, 72), (88, 96), (44, 82), (78, 86))]
                       + [d.fill(d.poly([(53, 50), (67, 50), (67, 112), (53, 112)], r=1, j=0.3, bow=0.4), rib, line=False)]))
    P.append(d.stroke(body, dark(box), 3.5))
    if lid:
        P.append(d.fill(d.poly([(14, 40), (106, 40), (106, 58), (14, 58)], r=6), light(box, 0.15)))
        P.append(d.fill(d.poly([(53, 40), (67, 40), (67, 58), (53, 58)], r=1, j=0.3, bow=0.4), rib, lw=2.2))
        for s in (1, -1):
            P.append(d.fill(d.blob([(60, 38), (60 - s * 14, 20), (60 - s * 30, 16), (60 - s * 30, 34), (60 - s * 12, 40)], 0.5), rib))
        P.append(d.fill(d.oval(60, 37, 7, 6), rib))
    return P


def giftClosed(d):
    return gift_box(d, True)


def giftOpen(d):
    P = []
    for x, y, r in ((80, 30, 7), (100, 14, 5), (104, 40, 4)):
        P.append(d.fill(star_path(d, x, y, r * 1.9, r * 0.9), "#F6CF5C", lw=1.8))
    for x, y, c, rot in ((62, 26, LILAC, 20), (90, 46, SAGE, -30), (112, 26, DUSTY, 10), (70, 10, PEACH, -15)):
        P.append(d.fill(d.oval(x, y, 4.5, 2.4, rot=rot), c, lw=1.4))
    P += gift_box(d, False)
    lid = d.poly([(0, 0), (86, 0), (86, 17), (0, 17)], r=6)
    band = d.poly([(36, 0), (50, 0), (50, 17), (36, 17)], r=1, j=0.3, bow=0.4)
    P.append(f'<g transform="translate(6 36) rotate(-20)">{d.fill(lid, light(CORAL, 0.15))}{d.fill(band, MUSTARD, lw=2.2)}</g>')
    d.track([(6, 20), (90, 6), (12, 54)], 2)
    return P


def brush(d):
    P = [d.tube(d.curve([(46, 68), (32, 86), (18, 104)], 0.3), 14, WOOD)]
    head = d.oval(66, 46, 38, 27, rot=-36)
    P.append(d.fill(head, SAGE))
    c, s = math.cos(math.radians(-36)), math.sin(math.radians(-36))
    P.append(d.clipped(head, lambda: [d.dot(66 + i * 9 * c - j * 9 * s, 46 + i * 9 * s + j * 9 * c, 2.3, dark(SAGE, 0.4))
                                      for i in range(-3, 4) for j in range(-2, 3) if i * i / 12 + j * j / 5 <= 1]))
    P.append(d.stroke(head, dark(SAGE), 3.5))
    return P


def blanket(d):
    col = DUSTY
    body = d.blob([(12, 22), (40, 18), (70, 22), (108, 18), (110, 50), (106, 80), (110, 104), (80, 100), (50, 106), (14, 102),
                   (10, 74), (14, 46)], 0.6)
    P = [d.fill(body, col)]
    squares = lambda: ([d.fill(d.poly([(x, y), (x + 18, y), (x + 18, y + 18), (x, y + 18)], r=3, j=0.6, bow=0.8), light(col, 0.3), line=False, grad=None)
                        for x in range(4, 120, 36) for y in range(4, 120, 36)]
                       + [d.fill(d.poly([(x, y), (x + 18, y), (x + 18, y + 18), (x, y + 18)], r=3, j=0.6, bow=0.8), light(col, 0.3), line=False, grad=None)
                          for x in range(22, 120, 36) for y in range(22, 120, 36)]
                       + [d.fill(star_path(d, x, y, 5.5, 2.6), MUSTARD, line=False) for x, y in ((31, 31), (67, 67), (103, 31), (31, 103), (85, 85))])
    P.append(d.clipped(body, squares))
    P.append(d.stroke(body, dark(col), 3.5))
    fold = d.blob([(108, 18), (110, 50), (78, 22)], 0.4)
    P.append(d.fill(d.poly([(110, 20), (110, 54), (76, 22)], r=5, j=0.5, bow=1), light(col, 0.5)))
    return P


def zzz(d):
    col = "#A6B4E4"
    P = []
    for x, y, s in ((14, 66, 36), (60, 38, 25), (92, 16, 17)):
        P.append(d.tube(Path((x, y)).L((x + s, y)).L((x, y + s)).L((x + s, y + s)), s * 0.24, col, lw=2.2))
    return P


def plate(d, y=98):
    P = [d.fill(d.oval(60, y, 56, 14), "#FFF8EE")]
    P.append(d.fill(d.oval(60, y - 2, 42, 8), light("#EE9A86", 0.55), line=False, grad=None))
    return P


def cloche(d, x0=0.0, y0=0.0, rot=0):
    """The round cover of today's feast, with a ribbon bow on top."""
    cover, rib = "#F6D9A8", "#EE8C86"
    dome = Path((10, 96)).C((10, 50), (34, 30), (60, 30)).C((86, 30), (110, 50), (110, 96))
    dome.closed = True
    P = [d.fill(dome, cover)]
    P.append(d.stroke(smooth([(24, 80), (26, 58), (42, 44)], closed=False), "#FFFFFF", 5, 0.6))
    P.append(d.fill(d.poly([(6, 92), (114, 92), (114, 100), (6, 100)], r=4, j=0.5, bow=1), dark(cover, 0.12), lw=3))
    P.append(d.fill(d.oval(60, 27, 9, 7), dark(cover, 0.1), lw=2.6))
    for s_ in (1, -1):
        P.append(d.fill(d.blob([(60, 22), (60 - s_ * 12, 8), (60 - s_ * 26, 6), (60 - s_ * 26, 20), (60 - s_ * 10, 24)], 0.5), rib, lw=2.6))
        P.append(d.fill(d.blob([(60 - s_ * 2, 24), (60 - s_ * 10, 40), (60 - s_ * 16, 44), (60 - s_ * 6, 26)], 0.4), rib, lw=2.4))
    P.append(d.fill(d.oval(60, 21, 6, 5.5), rib, lw=2.4))
    if rot:
        return f'<g transform="translate({n(x0)} {n(y0)}) rotate({rot} 60 64)">{"".join(P)}</g>'
    return "".join(P)


def feast_closed(d):
    return plate(d, 102) + [cloche(d)]


def feast_open(d):
    P = plate(d, 104)
    # a little cake with cream and a strawberry
    P.append(d.fill(d.poly([(18, 98), (18, 72), (54, 72), (54, 98)], r=6, j=0.6, bow=1), "#F8D7C4"))
    P.append(d.fill(d.blob([(16, 74), (24, 66), (36, 64), (48, 66), (56, 74), (50, 80), (44, 76), (36, 82), (28, 76), (22, 80)], 0.4), "#FFF8EE", lw=2.6))
    P.append(d.fill(d.oval(36, 61, 7, 6.5), "#EE7F7F", lw=2.2))
    P.append(d.fill(d.oval(36, 55, 4, 2.4), "#86B86A", lw=1.6))
    # fruit: an orange and grapes
    P.append(d.fill(d.oval(96, 92, 12, 12), "#F6B25C", lw=2.6))
    P.append(d.fill(d.oval(98, 80, 4, 2.4, rot=-20), "#86B86A", lw=1.6))
    for x, y in ((74, 96), (82, 96), (78, 89), (70, 90), (86, 90), (78, 82)):
        P.append(d.fill(d.oval(x, y, 4.6, 4.6), "#B79BD9", lw=1.8))
    P += biscuit(d, 60, 94, 13, letter=True, lw=2.6)
    # the cover, lifted up and away
    P.append(f'<g transform="translate(48 2) scale(0.55) rotate(18 60 64)">{cloche(d)}</g>')
    for x, y, r in ((16, 30, 5), (34, 14, 3.4), (10, 52, 3)):
        P.append(d.fill(star_path(d, x, y, r * 2, r), "#F6CF5C", lw=1.6))
    return P


def sun(d):
    pts = []
    for i in range(28):
        a = 2 * math.pi * i / 28
        rr = 50 if i % 2 == 0 else 42
        pts.append((60 + rr * math.cos(a), 60 + rr * math.sin(a)))
    P = [d.fill(d.blob(pts, 0.5), light("#F7CD62", 0.3)), d.fill(d.oval(60, 60, 34, 34), "#F7CD62")]
    P += tiny_face(d, 60, 58, 1.25)
    return P


ITEMS = {f.__name__: f for f in (bowl, cookie, sponge, shower, ball, bubbleBall, moon, star, heart,
                                 giftClosed, giftOpen, brush, blanket, zzz, feast_closed, feast_open, sun)}


# ---------------------------------------------------------------- growth wear (120 x 120)
# Where the app pins them (also in wear/wear.json): the bib's neck is at
# (60, 24), to go just under the pet's mouth; the cap's band is at (60, 90),
# to sit on the top of the head.
WEAR_ANCHORS = {"bib": {"x": 60, "y": 24, "note": "neck: just below pets.json mouth"},
                "cap": {"x": 60, "y": 90, "note": "band: on the top of pets.json head (cy - r * 0.8)"}}


def bib(d):
    col, trim = "#F4B3A8", "#FFF3DE"
    shape = d.blob([(28, 14), (44, 14), (49, 25), (60, 31), (71, 25), (76, 14), (92, 14), (102, 30), (108, 56), (102, 86),
                    (84, 106), (60, 113), (36, 106), (18, 86), (12, 56), (18, 30)], 0.6)
    P = [d.fill(shape, col)]
    P.append(d.clipped(shape, lambda: [d.dot(x, y, 3, trim, 0.7) for x, y in ((28, 48), (92, 48), (24, 76), (96, 76), (44, 98), (76, 98))]))
    P.append(d.stroke(shape, dark(col), 3.5))
    P.append(d.fill(heart_path(d, 60, 66, 1.35), trim, lw=2))
    P.append(d.stroke(smooth([(46, 16), (50, 26), (60, 32), (70, 26), (74, 16)], closed=False), trim, 5))
    return P


def cap(d):
    crown, brim = DUSTY, MUSTARD
    dome = d.blob([(16, 88), (18, 60), (32, 36), (60, 24), (88, 36), (102, 60), (104, 88), (60, 92)], 0.6)
    P = [d.fill(dome, crown)]
    for x in (34, 86):
        P.append(d.stroke(smooth([(60, 26), (x - (x - 60) * 0.5, 52), (x, 88)], closed=False), dark(crown, 0.3), 2.4))
    P.append(d.fill(star_path(d, 60, 62, 12, 6), "#FFF3DE", lw=2))
    P.append(d.fill(d.blob([(14, 86), (60, 82), (106, 86), (100, 100), (60, 108), (20, 100)], 0.5), brim))
    P.append(d.fill(d.oval(60, 22, 7, 5), brim, lw=2.4))
    return P


WEAR = {"bib": bib, "cap": cap}


def write_items():
    for folder, table in (("items", ITEMS), ("wear", WEAR)):
        out = ART / folder
        out.mkdir(parents=True, exist_ok=True)
        for name, fn in table.items():
            d = Doc(name, lw=3.5)
            (out / f"{name}.svg").write_text(d.svg(fn(d), box=(0, 0, 120, 120)))
    (ART / "wear" / "wear.json").write_text(json.dumps(WEAR_ANCHORS, indent=2) + "\n")


def main():
    write_pets()
    write_eggs()
    write_items()


if __name__ == "__main__":
    main()
