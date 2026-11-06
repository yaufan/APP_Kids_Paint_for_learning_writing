"""字母寵物's word pictures (the sticker book), the parents' reward icons
and four more button pictures, in the picture-book style of storybook.py.

    python3 words.py      # writes app/assets/art/words/, rewards/ and four items/

- words/<id>.svg: 240 x 240, one picture for the word of each capital
  letter (A apple ... Z zebra; the id is the English word, spaces and
  hyphens as _). See-through round the subject.
- rewards/<id>.svg: 240 x 240, the rewards parents set: ice_cream, park,
  toy, book, hug, star (star is for "something else").
  Both kinds are drawn freely and then centred and scaled so the subject
  fills the square less a 12-unit margin; the script prints each scale
  (near 1, so lines keep the same weight everywhere).
- items/block.svg, magnifier.svg, book.svg, task.svg: 120 x 120 like
  pets.py's items. block.svg's front face is plain, centred on (60, 64)
  (BLOCK_FACE), so the app can print a letter there.
"""
import math
import pathlib

from pets import CORAL, DUSTY, LILAC, MOUTH_LINE, MUSTARD, SAGE, WOOD, crescent, heart_path, star_path, tiny_face
from storybook import DEEP, INK, Doc, Path, dark, light, mirror_pts, n, smooth

ROOT = pathlib.Path(__file__).resolve().parents[2]
ART = ROOT / "app" / "assets" / "art"

S = 240          # the square pictures
MARGIN = 12      # left round the subject
LW = 5.5         # outline width in a 240 picture (a 120 item uses 3.5)

CREAMY = "#FFF3DE"
LEAF = "#94C07A"
BARK = "#A97750"
GOLD = "#F6CF5C"
PINK = "#F4A9B4"
WATER = "#86BDE5"
STRIPE = "#56474A"     # zebra stripes: the darkest paint after the eyes

WORDS = ["apple", "ball", "cat", "dog", "egg", "fish", "grapes", "hat", "ice_cream", "juice", "kite", "lion", "moon",
         "nose", "orange", "pig", "queen", "rabbit", "sun", "tree", "umbrella", "violin", "watermelon", "xylophone",
         "yo_yo", "zebra"]
REWARDS = ["ice_cream", "park", "toy", "book", "hug", "star"]
NEW_ITEMS = ["block", "magnifier", "book", "task"]
BLOCK_FACE = {"x": 21, "y": 25, "w": 78, "h": 78}   # the block's plain front face, in its 120 x 120 units


# ---------------------------------------------------------------- little helpers
def place(pts, x, y, ang=0.0, s=1.0):
    """[pts] turned [ang] degrees round (0, 0), scaled [s] and moved to (x, y)."""
    c, si = math.cos(math.radians(ang)), math.sin(math.radians(ang))
    return [(x + s * (px * c - py * si), y + s * (px * si + py * c)) for px, py in pts]


def line(d, pts, color, w, opacity=None, j=0.4):
    return d.stroke(d.curve(pts, j), color, w, opacity)


def shine(d, x, y, rx, ry, rot=-30, op=0.55):
    """A soft white gleam."""
    return d.fill(d.oval(x, y, rx, ry, rot=rot), "#FFFFFF", line=False, grad=None, opacity=op)


def smile(d, x, y, w=11, h=7, lw=3.8, color=MOUTH_LINE):
    return d.stroke(smooth([(x - w, y - h * 0.4), (x, y + h * 0.6), (x + w, y - h * 0.4)], closed=False), color, lw)


def w_mouth(d, x, y, w=10, drop=6, lw=3.6):
    """A little 'w' mouth hanging from the nose."""
    return [d.stroke(d.curve([(x, y - drop), (x, y)], 0.2), MOUTH_LINE, lw),
            d.stroke(smooth([(x - w, y - 3), (x - w * 0.5, y + 4), (x, y)], closed=False), MOUTH_LINE, lw),
            d.stroke(smooth([(x, y), (x + w * 0.5, y + 4), (x + w, y - 3)], closed=False), MOUTH_LINE, lw)]


def eyes_cheeks(d, x, y, dx, r=9.5, cdx=None, cdy=20, crx=12, cry=7.5):
    """Two shiny dot eyes [dx] either side of x, and rosy cheeks below them."""
    cdx = cdx if cdx is not None else dx + 18
    return [d.eye(x - dx, y, r), d.eye(x + dx, y, r), d.cheek(x - cdx, y + cdy, crx, cry), d.cheek(x + cdx, y + cdy, crx, cry)]


def happy_eyes(d, x, y, dx, r=8):
    saved, d.eye_mode = d.eye_mode, "happy"
    out = [d.eye(x - dx, y, r), d.eye(x + dx, y, r)]
    d.eye_mode = saved
    return out


def bumpy(cx, cy, rx, ry, bumps, depth=0.13, rot=0.0, steps=6):
    """Points round a cloud-like shape with [bumps] round lobes (a tree's
    leaves, a lion's mane)."""
    pts = []
    m = bumps * steps
    for i in range(m):
        a = 2 * math.pi * i / m + math.radians(rot)
        u = (i % steps) / steps
        f = 1 - depth + depth * math.sin(math.pi * u) ** 0.6
        pts.append((cx + rx * f * math.cos(a), cy + ry * f * math.sin(a)))
    return pts


def teardrop(x, y, s, ang=0.0):
    """Points round a drop [s] tall, pointing up (turned [ang])."""
    pts = []
    for i in range(20):
        t = 2 * math.pi * i / 20
        pts.append((0.62 * math.sin(t) * math.sin(t / 2), -math.cos(t) * 0.5))
    return place(pts, x, y, ang, s)


def drop(d, x, y, s=16, color=WATER, ang=0.0):
    return d.fill(d.blob(teardrop(x, y, s, ang), 0.15), color, lw=3)


def shade(d, path, top=0.32, edge=0.16):
    """A see-through light-and-shadow wash over a shape made of flat parts
    (a beach ball, an umbrella): the same soft look as one painted shape."""
    gid = d.uid("s")
    d.defs.append(f'<radialGradient id="{gid}" cx="0.36" cy="0.3" r="0.78">'
                  f'<stop offset="0" stop-color="#FFFFFF" stop-opacity="{top}"/>'
                  f'<stop offset="0.55" stop-color="#FFFFFF" stop-opacity="0"/>'
                  f'<stop offset="1" stop-color="{DEEP}" stop-opacity="{edge}"/></radialGradient>')
    return f'<path d="{path.d()}" fill="url(#{gid})"/>'


def heart_pts(x, y, s, ang=0.0):
    pts = []
    for i in range(36):
        t = 2 * math.pi * i / 36
        hx = 16 * math.sin(t) ** 3
        hy = -(13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t))
        pts.append((hx, hy))
    return place(pts, x, y, ang, s)


def twinkle(d, x, y, r, color=GOLD, lw=2.6):
    """A four-pointed sparkle."""
    p = Path((x, y - r)).Q((x + r * 0.16, y - r * 0.16), (x + r, y)).Q((x + r * 0.16, y + r * 0.16), (x, y + r))
    p.Q((x - r * 0.16, y + r * 0.16), (x - r, y)).Q((x - r * 0.16, y - r * 0.16), (x, y - r))
    p.closed = True
    return d.fill(p, color, lw=lw)


# ---------------------------------------------------------------- words, A to M
def apple(d):
    red = "#E8705F"
    P = [d.tube(d.curve([(120, 74), (121, 50), (130, 26)], 0.3), 9, BARK, lw=3.5)]
    body = d.blob([(120, 66), (140, 54), (166, 50), (192, 62), (209, 88), (213, 122), (205, 160), (187, 192), (165, 209),
                   (142, 207), (120, 200), (98, 207), (75, 209), (53, 192), (35, 160), (27, 122), (31, 88), (48, 62),
                   (74, 50), (100, 54)], 0.8)
    P.append(d.fill(body, red))
    P.append(line(d, [(106, 68), (120, 76), (134, 68)], dark(red, 0.25), 4, 0.7))
    P.append(d.fill(d.blob([(128, 48), (142, 31), (164, 21), (192, 22), (180, 38), (156, 50)], 0.5), LEAF))
    P.append(line(d, [(134, 44), (158, 33), (182, 26)], dark(LEAF, 0.3), 3))
    P.append(shine(d, 66, 104, 13, 26, 22))
    P.append(d.dot(76, 146, 6, "#FFFFFF", 0.5))
    return P


def ball(d):
    """A beach ball."""
    body = d.oval(120, 120, 100, 100, wob=0.5)
    pole = (96, 82)
    cols = [CORAL, CREAMY, MUSTARD, CREAMY, DUSTY, CREAMY]

    def far(a):
        return (pole[0] + 280 * math.cos(a), pole[1] + 280 * math.sin(a))

    def bend(a):
        return (pole[0] + 80 * math.cos(a + 0.4), pole[1] + 80 * math.sin(a + 0.4))

    def wedges():
        out = []
        for k in range(6):
            a0 = math.radians(-110 + 60 * k)
            a1 = a0 + math.radians(60)
            p = Path(pole).Q(bend(a0), far(a0)).L(far((a0 + a1) / 2)).L(far(a1)).Q(bend(a1), pole)
            p.closed = True
            out.append(d.fill(p, cols[k], line=False, grad=None))
        return out

    def seams():
        return [d.stroke(Path(pole).Q(bend(math.radians(-110 + 60 * k)), far(math.radians(-110 + 60 * k))), dark(CREAMY, 0.3), 2.4, 0.7)
                for k in range(6)]

    P = [d.fill(body, CREAMY, line=False, grad=None), d.clipped(body, wedges), d.clipped(body, seams), shade(d, body, 0.4, 0.2)]
    P.append(d.stroke(body, dark(CORAL, 0.38), LW))
    P.append(d.fill(d.oval(pole[0], pole[1], 13, 11, rot=-20), CREAMY, lw=3.5, edge=dark(CREAMY, 0.4)))
    P.append(shine(d, 62, 70, 15, 9, -40, 0.6))
    return P


def cat(d):
    fur, cream, pink = "#BDB2AC", "#FBF3EA", "#F3B4AE"
    stripe = dark(fur, 0.3)
    P = [d.tube(d.curve([(150, 214), (190, 212), (214, 186), (214, 154), (198, 136)], 0.4), 18, fur)]
    ear = [(48, 80), (54, 26), (64, 16), (76, 18), (108, 46)]
    inner = [(60, 70), (63, 34), (68, 30), (94, 50)]
    for pts in (ear, mirror_pts(ear, 120)):
        P.append(d.fill(d.poly(pts, r=12), fur))
    for pts in (inner, mirror_pts(inner, 120)):
        P.append(d.fill(d.poly(pts, r=8), pink, line=False))
    P.append(d.fill(d.oval(120, 184, 54, 46), fur))
    P.append(d.fill(d.oval(120, 198, 32, 27), cream, line=False))
    for x in (94, 146):
        P.append(d.fill(d.oval(x, 226, 23, 13), fur))
    for x, r in ((100, 14), (140, -14)):
        P.append(d.fill(d.oval(x, 200, 14, 12, rot=r), fur))
    P.append(d.fill(d.oval(120, 100, 82, 66), fur))
    for x, y0, y1 in ((120, 38, 58), (105, 42, 55), (135, 42, 55)):
        P.append(line(d, [(x, y0), (x + (x - 120) * 0.1, y1)], stripe, 5.5, j=0.2))
    for s in (1, -1):
        for y in (88, 104):
            P.append(line(d, [(120 - s * 81, y), (120 - s * 66, y + 2)], stripe, 5, j=0.2))
    P += [d.fill(d.oval(109, 130, 15, 11), cream, line=False), d.fill(d.oval(131, 130, 15, 11), cream, line=False)]
    P += eyes_cheeks(d, 120, 104, 31, 9.5, cdx=50, cdy=22)
    whisk = dark(fur, 0.5)
    for s in (1, -1):
        P.append(line(d, [(120 - s * 30, 124), (120 - s * 64, 116)], whisk, 2.4))
        P.append(line(d, [(120 - s * 30, 134), (120 - s * 62, 140)], whisk, 2.4))
    P += w_mouth(d, 120, 132, 9, 6)
    P.append(d.fill(d.poly([(112, 117), (128, 117), (120, 126)], r=3, j=0.3, bow=0.5), "#E8847F", line=False))
    return P


def dog(d):
    fur, ear, patch, nose = "#F7ECDD", "#B07D57", "#DDAA78", "#4E362E"
    edge = dark(fur, 0.5)
    P = [d.tube(d.curve([(156, 208), (186, 198), (204, 172)], 0.4), 16, fur, lw=LW)]
    P[0] = P[0].replace(f'stroke="{dark(fur)}"', f'stroke="{edge}"')
    P.append(d.fill(d.oval(120, 188, 52, 44), fur, edge=edge))
    for x in (96, 144):
        P.append(d.fill(d.oval(x, 226, 22, 13), fur, edge=edge))
        P += [line(d, [(x + dx, 222), (x + dx, 231)], edge, 2.4, j=0.2) for dx in (-6, 6)]
    for x, r in ((100, 14), (140, -14)):
        P.append(d.fill(d.oval(x, 204, 13, 11, rot=r), fur, edge=edge))
    P.append(d.tube(d.curve([(80, 156), (120, 170), (160, 156)], 0.3), 12, CORAL, lw=3.5))
    P.append(d.fill(d.oval(120, 181, 9, 9), MUSTARD, lw=3))
    P.append(d.fill(d.oval(120, 94, 82, 66), fur, edge=edge))
    P.append(d.fill(d.oval(152, 92, 23, 21, rot=-10), patch, line=False))
    ear_pts = [(66, 38), (46, 44), (30, 70), (24, 106), (30, 134), (44, 146), (58, 136), (64, 104), (72, 66), (82, 42)]
    for pts in (ear_pts, mirror_pts(ear_pts, 120)):
        P.append(d.fill(d.blob(pts, 0.6), ear))
    P.append(d.fill(d.oval(120, 124, 36, 24), "#FFFDF8", line=False))
    P += eyes_cheeks(d, 120, 98, 31, 9.5, cdx=52, cdy=24)
    tongue = Path((113, 131)).Q((120, 148), (127, 131))
    tongue.closed = True
    P.append(d.fill(tongue, "#EE8F8C", lw=2.4))
    P += w_mouth(d, 120, 131, 10, 9)
    P.append(d.fill(d.oval(120, 115, 13, 9), nose, line=False))
    P.append(d.dot(115, 112, 3.2, "#FFFFFF", 0.6))
    return P


def egg(d):
    """An egg in a little nest."""
    shell, nest = "#F2D8B4", "#C99A62"
    pts = []
    for i in range(32):
        t = 2 * math.pi * i / 32
        f = 1 - 0.12 * math.cos(t)
        pts.append((120 + 60 * math.sin(t) * f, 100 - 80 * math.cos(t)))
    P = [d.fill(d.blob(pts, 0.4), shell)]
    P.append(shine(d, 96, 62, 11, 22, 20, 0.6))
    rim = [(22, 150), (52, 138), (86, 144), (120, 140), (154, 144), (188, 138), (218, 150)]
    body = d.blob(rim + [(212, 182), (188, 208), (150, 224), (90, 224), (52, 208), (28, 182)], 0.6)
    for a, b in (((34, 148), (12, 134)), ((206, 148), (228, 136)), ((72, 142), (58, 124)), ((170, 142), (186, 126))):
        P.append(line(d, [a, b], dark(nest, 0.25), 4.5))
    P.append(d.fill(body, nest))
    twigs = [[(20, 164), (70, 172), (120, 166), (170, 174), (222, 162)],
             [(24, 188), (80, 194), (130, 186), (180, 196), (220, 184)],
             [(40, 210), (100, 214), (160, 208), (210, 202)],
             [(40, 150), (78, 186), (100, 226)], [(200, 150), (162, 188), (140, 226)], [(120, 150), (110, 186), (128, 226)],
             [(70, 150), (44, 196)], [(176, 152), (198, 200)]]
    P.append(d.clipped(body, lambda: [line(d, t, dark(nest, 0.3) if k % 2 else light(nest, 0.3), 4) for k, t in enumerate(twigs)]))
    P.append(d.stroke(d.curve(rim, 0.3), light(nest, 0.35), 6))
    return P


def fish(d):
    body_c, fin, belly = "#F3A766", "#EE8C76", "#FCE3C6"
    P = [d.fill(d.blob([(84, 76), (98, 42), (132, 38), (154, 60), (146, 76)], 0.6), fin),
         d.fill(d.blob([(100, 168), (108, 194), (134, 194), (134, 168)], 0.5), fin),
         d.fill(d.blob([(56, 122), (22, 74), (8, 84), (16, 122), (8, 160), (22, 170)], 0.6), fin)]
    body = d.oval(112, 122, 78, 58)
    P.append(d.fill(body, body_c))

    def inside():
        out = [d.fill(d.oval(120, 176, 80, 30), belly, line=False)]
        for x, y in ((66, 104), (90, 92), (90, 118), (114, 104), (66, 130), (114, 130), (90, 144)):
            out.append(line(d, [(x - 9, y - 4), (x, y + 6), (x + 9, y - 4)], light(body_c, 0.4), 3.5, j=0.2))
        return out

    P.append(d.clipped(body, inside))
    P.append(d.stroke(body, dark(body_c), LW))
    P.append(line(d, [(148, 88), (138, 122), (148, 156)], dark(body_c, 0.25), 4))
    P.append(d.fill(d.blob([(108, 128), (84, 146), (88, 158), (114, 144)], 0.4), fin, lw=4))
    P.append(d.eye(164, 108, 10.5))
    P.append(d.cheek(164, 134, 11, 7))
    P.append(d.stroke(smooth([(176, 130), (184, 135), (191, 128)], closed=False), MOUTH_LINE, 3.8))
    for x, y, r in ((210, 72, 12), (224, 42, 8), (202, 26, 5.5)):
        d.track([(x, y)], r + 2)
        P.append(f'<circle cx="{x}" cy="{y}" r="{r}" fill="#E6F3FB" fill-opacity="0.6" stroke="#8DBADB" stroke-width="3"/>'
                 + d.dot(x - r * 0.35, y - r * 0.35, r * 0.28, "#FFFFFF", 0.9))
    return P


def grapes(d):
    grape = "#A585CC"
    P = [d.tube(d.curve([(120, 74), (122, 52), (130, 30)], 0.3), 8, BARK, lw=3.5)]
    leaf = d.blob(bumpy(170, 46, 42, 30, 5, 0.22, rot=-20), 0.6)
    P.append(d.fill(leaf, LEAF))
    for tip in ((210, 40), (188, 16), (150, 18), (134, 52)):
        P.append(line(d, [(148, 60), tip], dark(LEAF, 0.3), 3, j=0.3))
    P.append(line(d, [(116, 58), (96, 50), (86, 32), (98, 22), (106, 32)], dark(LEAF, 0.15), 3.5))
    rows = [(92, (60, 100, 140, 180)), (128, (80, 120, 160)), (162, (100, 140)), (195, (120,))]
    k = 0
    for y, xs in rows:
        for x in xs:
            col = grape if k % 3 else dark(grape, 0.12)
            k += 1
            P.append(d.fill(d.oval(x, y, 23, 23), col, lw=4.5))
            P.append(shine(d, x - 8, y - 9, 6, 3.6, -40, 0.65))
    return P


def hat(d):
    """A straw sun hat with a ribbon and a flower."""
    straw = "#EBC67E"
    P = [d.fill(d.oval(120, 150, 108, 42), straw)]
    P.append(line(d, [(28, 160), (120, 184), (212, 160)], dark(straw, 0.22), 2.6, 0.6))
    P.append(line(d, [(44, 140), (120, 124), (196, 140)], dark(straw, 0.3), 2.6, 0.4))
    crown = Path((64, 148)).C((62, 88), (88, 56), (120, 56)).C((152, 56), (178, 88), (176, 148)).Q((120, 168), (64, 148))
    crown.closed = True
    P.append(d.fill(crown, light(straw, 0.08)))
    band = Path((50, 114)).Q((120, 132), (190, 114)).L((190, 146)).Q((120, 168), (50, 146))
    band.closed = True
    P.append(d.clipped(crown, lambda: [d.fill(band, CORAL, line=False),
                                       line(d, [(84, 84), (120, 76), (156, 84)], dark(straw, 0.2), 2.6, 0.5)]))
    P.append(d.stroke(crown, dark(straw), LW))
    for x1, y1 in ((190, 176), (172, 184)):
        P.append(d.fill(d.poly([(162, 136), (170, 134), (x1 + 6, y1), (x1 - 4, y1 - 2)], r=4, j=0.4, bow=1), CORAL, lw=3.5))
    for k in range(5):
        a = math.radians(-90 + 72 * k)
        P.append(d.fill(d.oval(86 + 10 * math.cos(a), 136 + 10 * math.sin(a), 8, 8), CREAMY, lw=2.6))
    P.append(d.fill(d.oval(86, 136, 6, 6), MUSTARD, lw=2.4))
    return P


def cone(d, top, half, tip, col="#E6B06E"):
    shape = d.poly([(120 - half, top), (120 + half, top), (120, tip)], r=10, j=0.5, bow=1)
    P = [d.fill(shape, col)]

    def hatch():
        out = []
        for k in range(-7, 8):
            x = 120 + k * 17
            out.append(d.stroke(Path((x, top - 20)).L((x + 130, top + 110)), dark(col, 0.28), 3, 0.8))
            out.append(d.stroke(Path((x, top - 20)).L((x - 130, top + 110)), dark(col, 0.28), 3, 0.8))
        return out

    P.append(d.clipped(shape, hatch))
    P.append(d.stroke(shape, dark(col), LW))
    return P


def scoop(d, cx, cy, rx, ry, col, drip=0.42):
    """A scoop: a round top and a wavy, dripping bottom edge."""
    pts = [(cx + rx * math.cos(a), cy + ry * math.sin(a)) for a in [math.pi + math.pi * i / 12 for i in range(13)]]
    waves = 7
    for i in range(1, waves * 2):
        x = cx + rx - i * 2 * rx / (waves * 2)
        pts.append((x, cy + ry * (drip if i % 2 else 0.16)))
    return [d.fill(d.blob(pts, 0.5), col), shine(d, cx - rx * 0.45, cy - ry * 0.45, rx * 0.2, ry * 0.12, -30, 0.55)]


def sprinkles(d, spots):
    cols = [MUSTARD, DUSTY, "#FFFFFF", SAGE, LILAC]
    P = []
    for k, (x, y, a) in enumerate(spots):
        c, s = math.cos(math.radians(a)), math.sin(math.radians(a))
        P.append(d.stroke(Path((x - 5 * c, y - 5 * s)).L((x + 5 * c, y + 5 * s)), cols[k % len(cols)], 4.5))
    return P


def cherry(d, x, y, r=14):
    return [line(d, [(x + 2, y - r + 2), (x + 8, y - r - 12), (x + 20, y - r - 18)], "#7FA35E", 3.5),
            d.fill(d.oval(x, y, r, r * 0.95), "#E2675E", lw=4), shine(d, x - r * 0.35, y - r * 0.35, r * 0.25, r * 0.16, -40, 0.7)]


def ice_cream(d):
    P = cone(d, 124, 46, 230)
    P += scoop(d, 120, 118, 58, 38, "#A9D8BE")
    P += scoop(d, 120, 78, 48, 36, PINK)
    P += sprinkles(d, [(100, 64, 30), (140, 60, -20), (118, 84, 10), (150, 82, 60), (92, 88, -40), (126, 56, 80)])
    P += cherry(d, 122, 38)
    return P


def juice(d):
    orange = "#F7AE4E"
    glass = d.poly([(60, 56), (180, 56), (166, 224), (74, 224)], r=12, j=0.5, bow=0.8)
    P = [d.fill(glass, "#E8F2F7", line=False, grad=None, opacity=0.85)]
    straw = Path((112, 176)).L((124, 46)).L((150, 20))
    P.append(d.tube(straw, 11, "#FFF8F0", lw=2.6))
    pts = straw.points()
    for k in range(1, 12):
        t = k / 12
        L = len(pts) - 1
        i = min(int(t * L), L - 1)
        (x0, y0), (x1, y1) = pts[i], pts[i + 1]
        ux, uy = x1 - x0, y1 - y0
        m = math.hypot(ux, uy) or 1
        ux, uy = ux / m, uy / m
        x, y = x0 + (x1 - x0) * (t * L - i), y0 + (y1 - y0) * (t * L - i)
        if k % 2:
            P.append(d.stroke(Path((x - uy * 4.5 - ux * 3, y + ux * 4.5 - uy * 3)).L((x + uy * 4.5 + ux * 3, y - ux * 4.5 + uy * 3)), CORAL, 4.5))
    P.append(d.fill(d.poly([(66, 92), (174, 92), (164, 216), (76, 216)], r=10, j=0.4, bow=0.6), orange, line=False))
    P.append(d.fill(d.oval(120, 92, 54, 7), light(orange, 0.4), line=False, grad=None))
    P.append(d.stroke(glass, "#9DBDCC", LW))
    P.append(d.stroke(d.curve([(78, 70), (86, 196)], 0.3), "#FFFFFF", 7, 0.6))
    rind, flesh = "#F4A24C", "#F9C46E"
    P.append(d.fill(d.oval(176, 60, 30, 30), rind, lw=4))
    P.append(d.fill(d.oval(176, 60, 23, 23), flesh, line=False))
    for k in range(8):
        a = math.radians(22.5 * k)
        P.append(d.stroke(Path((176 + 4 * math.cos(a), 60 + 4 * math.sin(a))).L((176 + 21 * math.cos(a), 60 + 21 * math.sin(a))), CREAMY, 2.6))
    return P


def kite(d):
    T, B = (150, 14), (118, 166)
    ux, uy = (B[0] - T[0]) / math.dist(T, B), (B[1] - T[1]) / math.dist(T, B)
    C = (T[0] + (B[0] - T[0]) * 0.34, T[1] + (B[1] - T[1]) * 0.34)
    px, py = -uy, ux
    L, R = (C[0] - 68 * px, C[1] - 68 * py), (C[0] + 68 * px, C[1] + 68 * py)
    # the tail first, so the kite sits on top of it
    tail = d.curve([B, (100, 184), (110, 200), (88, 212), (66, 210), (44, 226)], 0.3)
    P = [d.stroke(tail, "#9A6B55", 3.2)]
    tp = tail.points(10)
    for (i, col) in ((12, CORAL), (26, MUSTARD), (42, DUSTY)):
        (x0, y0), (x1, y1) = tp[i - 1], tp[i + 1]
        a = math.degrees(math.atan2(y1 - y0, x1 - x0)) + 90
        x, y = tp[i]
        for side in (1, -1):
            P.append(d.fill(d.poly(place([(0, 0), (side * 14, -8), (side * 14, 8)], x, y, a), r=3, j=0.3, bow=0.5), col, lw=3))
        P.append(d.dot(x, y, 4, dark(col, 0.3)))
    shape = d.poly([T, R, B, L], r=8, j=0.5, bow=1.5)
    quads = [([T, R, C], CORAL), ([R, B, C], MUSTARD), ([B, L, C], SAGE), ([L, T, C], DUSTY)]

    def parts():
        out = []
        for pts, col in quads:
            far = [(C[0] + (x - C[0]) * 1.4, C[1] + (y - C[1]) * 1.4) for x, y in pts[:2]]
            out.append(d.fill(d.poly(far + [C], r=0.1, j=0, bow=0), col, line=False, grad=None))
        return out

    P += [d.clipped(shape, parts), shade(d, shape, 0.3, 0.12)]
    P.append(d.stroke(d.curve([T, B], 0.2), dark(WOOD, 0.3), 4))
    P.append(d.stroke(d.curve([L, R], 0.2), dark(WOOD, 0.3), 4))
    P.append(d.stroke(shape, "#9A6B55", LW))
    return P


def lion(d):
    mane, face = "#DE945A", "#F4C976"
    P = [d.fill(d.blob(bumpy(120, 116, 104, 100, 13, 0.16), 0.8), mane)]
    P.append(d.fill(d.blob(bumpy(120, 120, 84, 80, 13, 0.14, rot=14), 0.6), light(mane, 0.2), line=False))
    for x in (68, 172):
        P.append(d.fill(d.oval(x, 62, 19, 18), face))
        P.append(d.fill(d.oval(x, 64, 9.5, 9), dark(face, 0.25), line=False))
    P.append(d.fill(d.oval(120, 124, 68, 60), face))
    P.append(d.fill(d.oval(107, 150, 20, 15), "#FCEBD2", line=False))
    P.append(d.fill(d.oval(133, 150, 20, 15), "#FCEBD2", line=False))
    P += eyes_cheeks(d, 120, 114, 27, 10, cdx=46, cdy=28)
    P += [d.dot(x, y, 2.2, dark(face, 0.5)) for x, y in ((100, 150), (106, 158), (140, 150), (134, 158))]
    P += w_mouth(d, 120, 158, 9, 10)
    P.append(d.fill(d.poly([(108, 138), (132, 138), (120, 150)], r=5, j=0.3, bow=0.5), "#8A5A48", line=False))
    return P


def moon(d):
    col = "#F5DC8A"
    P = [d.fill(d.blob(crescent(110, 120, 96, 160, 84, 82), 0.4), col)]
    P += tiny_face(d, 60, 152, 2.1, sleepy=True)
    for x, y, r in ((176, 62, 11), (210, 128, 7), (134, 30, 6)):
        P.append(d.fill(star_path(d, x, y, r * 2.1, r), MUSTARD, lw=3.5))
    return P


# ---------------------------------------------------------------- words, N to Z
def nose(d):
    """A bear cub's face; its big round nose is the point."""
    fur, inner, snout, nose_c = "#C8956C", "#E9B791", "#F6E0C4", "#5E3B30"
    P = []
    for x in (52, 188):
        P.append(d.fill(d.oval(x, 56, 32, 31), fur))
        P.append(d.fill(d.oval(x + (120 - x) * 0.05, 58, 17, 16), inner, line=False))
    P.append(d.fill(d.oval(120, 132, 100, 90), fur))
    P.append(d.fill(d.oval(120, 170, 62, 46), snout, line=False))
    P += eyes_cheeks(d, 120, 108, 44, 9, cdx=66, cdy=46, crx=14, cry=9)
    P += w_mouth(d, 120, 190, 14, 14)
    P.append(d.fill(d.oval(120, 152, 38, 28), nose_c, lw=3.5))
    P.append(shine(d, 104, 141, 12, 7, -20, 0.75))
    P.append(d.dot(136, 143, 3.6, "#FFFFFF", 0.5))
    return P


def orange(d):
    col, flesh, pith = "#F4A24C", "#F8BA5A", "#FFF0D6"
    body = d.oval(98, 128, 78, 74)
    P = [d.fill(body, col)]
    R = d.rng
    dots = [(R.uniform(26, 172), R.uniform(58, 200)) for _ in range(40)]
    P.append(d.clipped(body, lambda: [d.dot(x, y, 1.8, dark(col, 0.25), 0.5) for x, y in dots]))
    P.append(d.fill(d.oval(98, 58, 7, 5), "#7FA35E", lw=2.4))
    P.append(d.fill(d.blob([(100, 56), (114, 36), (140, 26), (162, 30), (148, 48), (120, 58)], 0.5), LEAF))
    P.append(line(d, [(108, 50), (132, 36), (156, 31)], dark(LEAF, 0.3), 3))
    P.append(shine(d, 62, 92, 12, 20, 30, 0.45))
    cx, cy = 174, 176
    P.append(d.fill(d.oval(cx, cy, 46, 46), col))
    P.append(d.fill(d.oval(cx, cy, 39, 39), pith, line=False, grad=None))
    for k in range(8):
        a0, a1 = math.radians(45 * k + 5), math.radians(45 * k + 40)
        pts = [(cx + 5 * math.cos((a0 + a1) / 2), cy + 5 * math.sin((a0 + a1) / 2)),
               (cx + 34 * math.cos(a0), cy + 34 * math.sin(a0)), (cx + 35 * math.cos((a0 + a1) / 2), cy + 35 * math.sin((a0 + a1) / 2)),
               (cx + 34 * math.cos(a1), cy + 34 * math.sin(a1))]
        P.append(d.fill(d.poly(pts, r=4, j=0.3, bow=0.4), flesh, line=False))
    P.append(d.dot(cx, cy, 4, pith))
    return P


def pig(d):
    pink, snout = "#F5B4AE", "#EF9C98"
    P = [d.stroke(smooth([(166, 196), (190, 192), (198, 176), (186, 168), (180, 180), (192, 186)], closed=False), dark(pink, 0.3), 5)]
    for pts in ([(52, 62), (46, 16), (58, 12), (100, 42)], mirror_pts([(52, 62), (46, 16), (58, 12), (100, 42)], 120)):
        P.append(d.fill(d.poly(pts, r=10), pink))
    P.append(d.fill(d.oval(120, 188, 56, 46), pink))
    for x in (96, 144):
        P.append(d.fill(d.oval(x, 226, 21, 12), pink))
        P.append(line(d, [(x, 220), (x, 232)], dark(pink, 0.4), 2.6, j=0.2))
    for x, r in ((100, 14), (140, -14)):
        P.append(d.fill(d.oval(x, 204, 13, 11, rot=r), pink))
    P.append(d.fill(d.oval(120, 102, 84, 68), pink))
    P += eyes_cheeks(d, 120, 94, 34, 9.5, cdx=52, cdy=30)
    P.append(d.fill(d.oval(120, 126, 29, 20), snout))
    P += [d.fill(d.oval(x, 126, 4.6, 7), dark(snout, 0.5), line=False, grad=None) for x in (110, 130)]
    P.append(smile(d, 120, 154, 10, 6))
    return P


def queen(d):
    """A little cartoon queen with a crown and a star wand."""
    skin, hair, gown, gold = "#F8D9C0", "#A86F4C", LILAC, "#F2C45C"
    P = [d.fill(d.blob([(64, 84), (70, 50), (120, 36), (170, 50), (176, 84), (184, 130), (170, 156), (70, 156), (56, 130)], 0.6), hair)]
    P.append(d.tube(d.curve([(170, 210), (184, 160), (194, 118)], 0.3), 7, gold, lw=3))
    P.append(d.fill(star_path(d, 196, 104, 22, 10.5, corner=4), GOLD, lw=4))
    body = d.blob([(94, 150), (120, 146), (146, 150), (170, 186), (198, 226), (120, 234), (42, 226), (70, 186)], 0.6)
    P.append(d.fill(body, gown))
    P.append(d.clipped(body, lambda: [d.fill(d.blob([(30, 216), (120, 210), (210, 216), (210, 240), (30, 240)], 0.4), gold, line=False)]))
    P.append(d.stroke(body, dark(gown), LW))
    P += [d.dot(120, y, 4.5, CREAMY) for y in (172, 190)]
    P.append(d.fill(d.oval(120, 152, 34, 11), CREAMY, lw=3.5))
    P.append(d.fill(d.oval(80, 196, 12, 11), skin))
    P.append(d.fill(d.oval(168, 194, 12, 11), skin))
    P.append(d.fill(d.oval(120, 106, 50, 47), skin))
    P.append(d.fill(d.blob([(72, 102), (78, 70), (120, 56), (162, 70), (168, 102), (152, 88), (134, 94), (120, 82), (104, 94), (86, 88)], 0.5), hair))
    crown = d.poly([(84, 66), (80, 24), (102, 44), (120, 14), (138, 44), (160, 24), (156, 66)], r=5, j=0.5, bow=1)
    P.append(d.fill(crown, gold))
    for x, y, r, c in ((80, 22, 6.5, CORAL), (120, 12, 7, CORAL), (160, 22, 6.5, CORAL), (102, 56, 5, DUSTY), (120, 54, 6, CORAL), (138, 56, 5, SAGE)):
        P.append(d.fill(d.oval(x, y, r, r), c, lw=2.6))
    P += eyes_cheeks(d, 120, 114, 20, 7.5, cdx=33, cdy=16, crx=10, cry=6.5)
    P.append(smile(d, 120, 132, 8, 6, 3.4))
    return P


def rabbit(d):
    fur, inner, belly = "#CFA986", "#F3B4AE", "#FBEBD8"
    P = []
    for cx, rot in ((98, -10), (142, 10)):
        P.append(d.fill(d.oval(cx, 54, 18, 46, rot=rot), fur))
        P.append(d.fill(d.oval(cx + rot * 0.12, 60, 8.5, 33, rot=rot), inner, line=False))
    P.append(d.fill(d.oval(120, 190, 52, 42), fur))
    P.append(d.fill(d.oval(120, 198, 31, 26), belly, line=False))
    for x in (96, 144):
        P.append(d.fill(d.oval(x, 228, 24, 12), fur))
        P.append(d.fill(d.oval(x, 230, 9, 5.5), inner, line=False))
    P.append(d.fill(d.oval(120, 124, 66, 56), fur))
    P += eyes_cheeks(d, 120, 124, 25, 9.5, cdx=44, cdy=22)
    P += w_mouth(d, 120, 150, 9, 7)
    P.append(d.fill(d.poly([(112, 136), (128, 136), (120, 144)], r=3, j=0.3, bow=0.5), "#EE9C9C", line=False))
    # a carrot held in both paws
    for a in (-35, 0, 35):
        P.append(d.fill(d.oval(*place([(0, -17)], 180, 176, a + 50)[0], 7, 17, rot=a + 50), LEAF, lw=3))
    car = d.poly([(168, 166), (184, 188), (70, 222)], r=8, j=0.4, bow=1)
    P.append(d.fill(car, "#F2994A"))
    for t in (0.25, 0.45, 0.65):
        x, y = 176 + (70 - 176) * t, 177 + (222 - 177) * t
        P.append(line(d, [(x - 4, y - 8), (x + 3, y + 6)], dark("#F2994A", 0.3), 2.8, j=0.2))
    for x, y, r in ((102, 206, 14), (150, 190, -14)):
        P.append(d.fill(d.oval(x, y, 13, 11, rot=r), fur))
    return P


def sun(d):
    P = []
    for k in range(12):
        a = math.radians(30 * k - 90)
        pts = [(120 + 70 * math.cos(a - 0.2), 120 + 70 * math.sin(a - 0.2)), (120 + 112 * math.cos(a), 120 + 112 * math.sin(a)),
               (120 + 70 * math.cos(a + 0.2), 120 + 70 * math.sin(a + 0.2))]
        P.append(d.fill(d.poly(pts, r=7, j=0.5, bow=1), "#F6B85C" if k % 2 else light("#F7CD62", 0.15), lw=4.5))
    P.append(d.fill(d.oval(120, 120, 72, 72), "#F7CD62"))
    P += tiny_face(d, 120, 116, 2.5)
    return P


def tree_crown(d, cx, cy, rx, ry, green=LEAF, bumps=10):
    crown = d.blob(bumpy(cx, cy, rx, ry, bumps, 0.14), 0.8)

    def inside():
        # leaf clumps: a shadow along the bottom, light ones catching the sun on top
        return [d.fill(d.blob(bumpy(cx + rx * 0.05, cy + ry * 0.62, rx * 0.95, ry * 0.42, 7, 0.2), 0.5), dark(green, 0.12), line=False, grad=None),
                d.fill(d.blob(bumpy(cx - rx * 0.32, cy - ry * 0.3, rx * 0.38, ry * 0.32, 5, 0.18), 0.5), light(green, 0.3), line=False),
                d.fill(d.blob(bumpy(cx + rx * 0.32, cy - ry * 0.2, rx * 0.3, ry * 0.28, 4, 0.18), 0.5), light(green, 0.25), line=False),
                d.fill(d.blob(bumpy(cx - rx * 0.02, cy + ry * 0.18, rx * 0.3, ry * 0.24, 4, 0.18), 0.5), light(green, 0.18), line=False)]

    return [d.fill(crown, green), d.clipped(crown, inside), d.stroke(crown, dark(green), LW)]


def tree(d):
    P = [d.fill(d.poly([(94, 232), (106, 212), (108, 140), (132, 140), (134, 212), (146, 232)], r=8, j=0.6, bow=1.5), BARK)]
    P.append(line(d, [(122, 196), (124, 172)], dark(BARK, 0.3), 3))
    P += tree_crown(d, 120, 92, 102, 80)
    P.append(d.fill(d.oval(120, 230, 60, 9), SAGE))
    return P


def umbrella(d):
    xs = [14, 67, 120, 173, 226]
    canopy = Path((14, 128)).C((14, 64), (64, 24), (120, 24)).C((176, 24), (226, 64), (226, 128))
    for i in range(4, 0, -1):
        canopy.Q(((xs[i] + xs[i - 1]) / 2, 108), (xs[i - 1], 128))
    canopy.closed = True

    def rib(xb):
        return Path((120, 24)).Q((120 + (xb - 120) * 0.75, 44), (xb, 128))

    def panels():
        cols = [CORAL, MUSTARD, SAGE, DUSTY]
        out = []
        edges = [-60, 67, 120, 173, 300]
        for k in range(4):
            a, b = edges[k], edges[k + 1]
            p = Path((120, 24)).Q((120 + (a - 120) * 0.75, 44), (a, 128)).L((a, 170)).L((b, 170)).L((b, 128)).Q((120 + (b - 120) * 0.75, 44), (120, 24))
            p.closed = True
            out.append(d.fill(p, cols[k], line=False, grad=None))
        return out

    P = [d.tube(Path((120, 110)).L((120, 206)).Q((120, 228), (104, 226)).Q((90, 224), (92, 208)), 9, BARK, lw=3.2)]
    P.append(d.tube(Path((120, 28)).L((120, 8)), 6, BARK, lw=2.6))
    P += [d.clipped(canopy, panels), shade(d, canopy, 0.3, 0.12)]
    for xb in (67, 120, 173):
        P.append(d.stroke(rib(xb), "#A0705F", 3, 0.6))
    P.append(d.stroke(canopy, "#A0705F", LW))
    P += [drop(d, 26, 40), drop(d, 214, 40), drop(d, 44, 182, 14), drop(d, 196, 186, 14)]
    return P


def violin(d):
    wood, board = "#CF8550", "#5E4034"
    X, Y, A = 128, 112, 35
    T = lambda pts: place(pts, X, Y, A)
    right = [(0, -80), (20, -80), (38, -72), (46, -58), (45, -42), (36, -30), (30, -18), (30, -2), (38, 10), (50, 26),
             (54, 46), (48, 66), (30, 80), (0, 86)]
    outline = right + [(-x, y) for x, y in reversed(right[1:-1])]
    P = [d.fill(d.poly(T([(-7, -82), (7, -82), (7, -120), (-7, -120)]), r=3, j=0.2, bow=0.3), dark(wood, 0.1), lw=3.5)]
    sx, sy = T([(0, -130)])[0]
    P.append(d.fill(d.oval(sx, sy, 12, 13, rot=A), dark(wood, 0.1), lw=3.5))
    P.append(d.stroke(smooth(T([(4, -130), (0, -134), (-5, -130), (0, -124), (8, -130)]), closed=False), dark(wood, 0.45), 2.6))
    for y in (-114, -102):
        for s in (1, -1):
            px, py = T([(s * 13, y)])[0]
            P.append(d.fill(d.oval(px, py, 5, 3.5, rot=A), board, lw=2))
    body = d.blob(T(outline), 0.4)
    P.append(d.fill(body, wood))
    P.append(d.stroke(d.blob(T([(x * 0.88, y * 0.9 + 1) for x, y in outline]), 0.3), dark(wood, 0.3), 2.2, 0.6))
    P.append(d.fill(d.poly(T([(-8, -118), (8, -118), (11, 14), (-11, 14)]), r=4, j=0.2, bow=0.3), board, lw=2.6))
    for s in (1, -1):
        P.append(d.stroke(smooth(T([(s * 22, 2), (s * 17, 14), (s * 23, 28), (s * 18, 40)]), closed=False), dark(wood, 0.55), 3.2))
    P.append(d.fill(d.poly(T([(-10, 50), (10, 50), (7, 78), (-7, 78)]), r=3, j=0.2, bow=0.3), board, lw=2.4))
    for x in (-3.5, 3.5):
        P.append(d.stroke(Path(T([(x, -116)])[0]).L(T([(x * 1.4, 54)])[0]), "#F3E6CF", 1.8))
    P.append(d.fill(d.poly(T([(-16, 32), (16, 32), (13, 40), (-13, 40)]), r=2, j=0.2, bow=0.3), "#F3DDB8", lw=2.2))
    # the bow, across the strings
    a, b = (24, 96), (204, 200)
    P.append(d.stroke(Path((a[0] + 4, a[1] + 8)).L((b[0] - 10, b[1] + 2)), "#F3E6CF", 3.4))
    P.append(d.tube(Path(a).L(b), 5, "#8A5A3C", lw=2.2))
    P.append(d.fill(d.poly([(b[0] - 26, b[1] - 10), (b[0] - 12, b[1] - 2), (b[0] - 18, b[1] + 10), (b[0] - 32, b[1] + 2)], r=3, j=0.3, bow=0.4), board, lw=2.2))
    return P


def watermelon(d):
    def wedge(tip, half, side, ctrl):
        pts = [(120, tip)]
        pts += [(120 + half * t, tip + (side - tip) * t) for t in (0.33, 0.66)]
        for k in range(13):
            t = k / 12
            x = (1 - t) ** 2 * (120 + half) + 2 * (1 - t) * t * 120 + t * t * (120 - half)
            y = (1 - t) ** 2 * side + 2 * (1 - t) * t * ctrl + t * t * side
            pts.append((x, y))
        pts += [(120 - half * t, tip + (side - tip) * t) for t in (0.66, 0.33)]
        return pts

    rind, band, flesh = "#8DBF72", "#E3F0CC", "#F07C7C"
    P = [d.fill(d.poly(wedge(12, 104, 166, 262), r=10, j=0.5, bow=0.8), rind)]
    P.append(d.fill(d.poly(wedge(30, 90, 158, 242), r=8, j=0.4, bow=0.6), band, line=False))
    P.append(d.fill(d.poly(wedge(38, 82, 154, 228), r=8, j=0.4, bow=0.6), flesh, lw=3, edge=dark(flesh, 0.25)))
    for x, y in ((120, 76), (100, 110), (140, 110), (80, 144), (120, 144), (160, 144), (100, 176), (140, 176)):
        P.append(d.fill(d.blob(teardrop(x, y, 15, (x - 120) * 0.25), 0.1), "#4E3A34", line=False, grad=None))
        P.append(d.dot(x - 1.5, y - 1, 1.6, "#FFFFFF", 0.6))
    return P


def xylophone(d):
    cols = [CORAL, "#F4A95C", MUSTARD, SAGE, "#8EC4B8", DUSTY, LILAC]
    P = [d.tube(d.curve([(22, 66), (218, 104)], 0.2), 12, WOOD, lw=3.5),
         d.tube(d.curve([(22, 184), (218, 140)], 0.2), 12, WOOD, lw=3.5)]
    for i, c in enumerate(cols):
        x = 36 + i * 28
        top, bot = 50 + i * 6, 198 - i * 7.5
        P.append(d.fill(d.poly([(x - 11, top), (x + 11, top), (x + 11, bot), (x - 11, bot)], r=7, j=0.4, bow=0.6), c, lw=4))
        P.append(d.stroke(d.curve([(x - 4, top + 10), (x - 4, bot - 10)], 0.2), "#FFFFFF", 3.5, 0.45))
        for y in (66 + (104 - 66) * (x - 22) / 196, 184 + (140 - 184) * (x - 22) / 196):
            P.append(d.dot(x, y, 3, dark(c, 0.45)))
    for (x0, y0), (x1, y1), c in (((40, 230), (104, 194), CORAL), ((212, 230), (150, 190), DUSTY)):
        P.append(d.tube(Path((x0, y0)).L((x1, y1)), 7, WOOD, lw=3))
        P.append(d.fill(d.oval(x1 + (x1 - x0) * 0.1, y1 + (y1 - y0) * 0.1, 14, 14), c, lw=4))
    return P


def yo_yo(d):
    col = "#EE8C7E"
    P = [d.stroke(d.curve([(130, 78), (136, 52), (146, 32), (150, 18)], 0.3), "#8A6A5A", 3.6)]
    d.track([(152, 10)], 10)
    P.append(f'<circle cx="152" cy="10" r="8" fill="none" stroke="#8A6A5A" stroke-width="3.6"/>')
    P.append(d.fill(d.oval(134, 140, 76, 76), dark(col, 0.18)))
    P.append(d.fill(d.oval(118, 150, 76, 76), col))
    P.append(d.fill(d.oval(118, 150, 50, 50), MUSTARD, lw=3.5))
    P.append(d.fill(d.oval(118, 150, 28, 28), CREAMY, lw=3))
    P.append(d.fill(star_path(d, 118, 151, 17, 8, corner=3), col, lw=2.6))
    P.append(shine(d, 74, 110, 14, 8, -50, 0.55))
    for k, (x, r) in enumerate(((22, 46), (12, 30))):
        P.append(line(d, [(x + 10, 150 - r), (x, 150), (x + 10, 150 + r)], dark(col, 0.1), 5, 0.7))
    return P


def zebra(d):
    white, muzzle, ear_in = "#FAF6EF", "#B3A49D", "#E8C2BC"
    edge = dark(white, 0.55)

    def striped(path, stripes):
        return [d.fill(path, white, edge=edge), d.clipped(path, stripes), d.stroke(path, edge, LW)]

    body = d.oval(120, 196, 56, 38)
    P = striped(body, lambda: [d.fill(d.poly([(120 - s * 64, y - 8), (120 - s * 26, y + 6), (120 - s * 64, y + 10)], r=3, j=0.4, bow=0.6),
                                      STRIPE, line=False, grad=None) for y in (172, 194, 216) for s in (1, -1)])
    for x in (98, 142):
        P.append(d.fill(d.oval(x, 230, 21, 11), "#7A6A66"))
    for x, rot in ((76, -34), (164, 34)):
        P.append(d.fill(d.oval(x, 40, 14, 27, rot=rot), white, edge=edge))
        P.append(d.fill(d.oval(x, 42, 6.5, 16, rot=rot), ear_in, line=False))
    P.append(d.fill(d.poly([(96, 44), (100, 14), (110, 30), (118, 6), (126, 30), (136, 12), (144, 44)], r=4, j=0.5, bow=0.8), STRIPE))
    head = d.blob([(120, 30), (156, 36), (176, 62), (178, 100), (168, 132), (162, 160), (150, 184), (120, 192), (90, 184),
                   (78, 160), (72, 132), (62, 100), (64, 62), (84, 36)], 0.6)

    def head_stripes():
        out = []
        for y in (60, 84, 108, 132):
            for s in (1, -1):
                pts = [(120 - s * 70, y - 9), (120 - s * 32, y + 1), (120 - s * 70, y + 10)]
                out.append(d.fill(d.poly(pts, r=3, j=0.4, bow=0.6), STRIPE, line=False, grad=None))
        for x in (108, 132):
            out.append(d.fill(d.poly([(x - 6, 20), (x, 64), (x + 6, 20)], r=3, j=0.4, bow=0.6), STRIPE, line=False, grad=None))
        return out

    P += striped(head, head_stripes)
    P.append(d.fill(d.oval(120, 166, 42, 26), muzzle))
    P += [d.fill(d.oval(x, 162, 5, 6.5), dark(muzzle, 0.6), line=False, grad=None) for x in (105, 135)]
    P += eyes_cheeks(d, 120, 108, 30, 9.5, cdx=40, cdy=26)
    P.append(smile(d, 120, 178, 9, 6, 3.6, INK))
    return P


WORD_DRAW = {f.__name__: f for f in (apple, ball, cat, dog, egg, fish, grapes, hat, ice_cream, juice, kite, lion, moon,
                                     nose, orange, pig, queen, rabbit, sun, tree, umbrella, violin, watermelon, xylophone,
                                     yo_yo, zebra)}


# ---------------------------------------------------------------- rewards
def r_ice_cream(d):
    P = cone(d, 128, 44, 230)
    P += scoop(d, 120, 108, 62, 56, PINK, 0.4)
    P += sprinkles(d, [(96, 82, 30), (140, 74, -20), (118, 102, 10), (156, 98, 60), (84, 108, -40), (122, 66, 80),
                       (104, 64, -60), (146, 118, 20), (98, 124, 70)])
    P += cherry(d, 128, 56)
    return P


def r_park(d):
    """A tree with a swing."""
    P = [d.fill(d.poly([(48, 232), (62, 212), (66, 120), (92, 120), (96, 212), (110, 232)], r=8, j=0.6, bow=1.5), BARK)]
    P.append(d.tube(d.curve([(84, 156), (150, 146), (218, 140)], 0.4), 12, BARK, lw=3.5))
    P += tree_crown(d, 108, 76, 98, 64, bumps=10)
    for x0, x1 in ((152, 148), (200, 198)):
        P.append(line(d, [(x0, 146), (x1, 196)], "#C9A27A", 4, j=0.2))
    P.append(d.fill(d.poly([(136, 192), (212, 192), (210, 206), (138, 206)], r=4, j=0.4, bow=0.6), CORAL, lw=4))
    P.append(d.fill(d.oval(120, 230, 110, 9), SAGE))
    return P


def r_toy(d):
    """A wind-up toy car."""
    body_c, glass = CORAL, "#CFE6F2"
    key = "#E9B949"
    P = [d.tube(Path((128, 84)).L((128, 50)), 7, key, lw=3)]
    for x in (110, 146):
        P.append(d.fill(d.oval(x, 38, 17, 12), key, lw=3.5))
    P.append(d.fill(d.oval(128, 38, 7, 7), dark(key, 0.15), lw=2.6))
    body = d.poly([(20, 178), (20, 140), (34, 126), (66, 120), (88, 82), (166, 82), (190, 120), (214, 128), (222, 146), (222, 178)], r=16, j=0.6, bow=1)
    P.append(d.fill(body, body_c))
    P.append(d.fill(d.poly([(96, 92), (124, 92), (124, 120), (80, 120)], r=6, j=0.4, bow=0.6), glass, lw=3.5, edge=dark(body_c, 0.3)))
    P.append(d.fill(d.poly([(134, 92), (160, 92), (178, 120), (134, 120)], r=6, j=0.4, bow=0.6), glass, lw=3.5, edge=dark(body_c, 0.3)))
    P.append(line(d, [(129, 126), (129, 168)], dark(body_c, 0.3), 3))
    P.append(d.fill(star_path(d, 162, 148, 12, 5.5, corner=2), CREAMY, lw=2.4))
    P.append(d.fill(d.oval(214, 146, 7, 9), MUSTARD, lw=2.6))
    P.append(shine(d, 70, 136, 22, 5, -6, 0.45))
    for x in (68, 176):
        P.append(d.fill(d.oval(x, 182, 28, 28), "#6E5E58"))
        P.append(d.fill(d.oval(x, 182, 11, 11), "#F3E6D0", lw=2.6))
    return P


def r_book(d):
    """An open storybook."""
    cover, page = DUSTY, "#FFF8EE"
    P = [d.fill(d.poly([(10, 74), (120, 92), (230, 74), (230, 208), (120, 220), (10, 208)], r=10, j=0.5, bow=1), cover)]

    def page_path(s, dy=0):
        p = Path((120 - s * 98, 62 + dy)).Q((120 - s * 52, 48 + dy), (120, 78 + dy)).L((120, 206 + dy)).Q((120 - s * 52, 182 + dy), (120 - s * 98, 194 + dy))
        p.closed = True
        return p

    for s in (1, -1):
        P.append(d.fill(page_path(s, 6), dark(page, 0.12), lw=3))
        P.append(d.fill(page_path(s), page, lw=3.5))
    P.append(d.fill(d.oval(52, 100, 11, 11), MUSTARD, lw=3))
    P.append(d.fill(d.blob([(32, 168), (52, 136), (76, 128), (100, 146), (112, 176), (112, 186), (32, 182)], 0.5), SAGE, lw=3))
    for k, y in enumerate((104, 124, 144, 164)):
        x1 = 206 if k < 3 else 186
        P.append(line(d, [(134, y - 4), (x1, y - 4 - (x1 - 134) * 0.12)], "#D9C6B0", 5, j=0.3))
    P.append(line(d, [(120, 80), (120, 204)], dark(page, 0.3), 3, j=0.2))
    P.append(d.fill(d.poly([(114, 204), (126, 204), (126, 234), (120, 226), (114, 234)], r=2, j=0.3, bow=0.3), CORAL, lw=3))
    P += [d.fill(star_path(d, x, y, r * 2, r), GOLD, lw=3) for x, y, r in ((60, 26, 8), (184, 22, 7), (120, 30, 5))]
    return P


def r_hug(d):
    """Two hearts hugging."""
    a_col, b_col = "#EF8A88", "#F6B6A2"
    P = [d.fill(d.oval(26, 140, 12, 11, rot=-20), b_col, lw=4)]        # b's hand, round a's back
    P += [d.fill(d.blob(heart_pts(84, 132, 3.7, 14), 0.4), a_col), d.fill(d.blob(heart_pts(160, 128, 3.7, -14), 0.4), b_col)]
    for (x, y, col) in ((80, 124, a_col), (164, 120, b_col)):
        P += happy_eyes(d, x, y, 16, 7.5)
        P += [d.cheek(x - 26, y + 14, 10, 6.5), d.cheek(x + 26, y + 14, 10, 6.5)]
        P.append(smile(d, x, y + 14, 8, 6, 3.4))
    P.append(d.tube(d.curve([(112, 160), (150, 168), (196, 150)], 0.3), 12, a_col, lw=4))   # a's arm round b
    P.append(d.fill(d.oval(206, 144, 12, 11, rot=20), a_col, lw=4))
    P += [d.fill(heart_path(d, x, y, s), "#EF8A88", lw=3) for x, y, s in ((122, 34, 1.15), (156, 20, 0.7), (90, 22, 0.6))]
    return P


def r_star(d):
    P = [d.fill(star_path(d, 120, 126, 108, 54, corner=16), GOLD)]
    P += tiny_face(d, 120, 130, 2.3)
    P += [twinkle(d, 30, 36, 15), twinkle(d, 210, 34, 12), twinkle(d, 120, 226, 10)]
    return P


REWARD_DRAW = {"ice_cream": r_ice_cream, "park": r_park, "toy": r_toy, "book": r_book, "hug": r_hug, "star": r_star}


# ---------------------------------------------------------------- items (120 x 120)
def block(d):
    """A plain wooden letter block; its front face is BLOCK_FACE (the app prints the letter there)."""
    wood = "#EFC58C"
    f = BLOCK_FACE
    x0, y0, x1, y1 = f["x"], f["y"], f["x"] + f["w"], f["y"] + f["h"]
    dx, dy = 12, -13
    P = [d.fill(d.poly([(x0, y0), (x0 + dx, y0 + dy), (x1 + dx, y0 + dy), (x1, y0)], r=5, j=0.4, bow=0.6), light(wood, 0.3)),
         d.fill(d.poly([(x1, y0), (x1 + dx, y0 + dy), (x1 + dx, y1 + dy), (x1, y1)], r=5, j=0.4, bow=0.6), dark(wood, 0.16))]
    P.append(line(d, [(x1 + 6, y0 + 10), (x1 + 6, y1 - 14)], dark(wood, 0.3), 1.8, 0.5))
    P.append(d.fill(d.poly([(x0, y0), (x1, y0), (x1, y1), (x0, y1)], r=8, j=0.6, bow=1), wood))
    P.append(d.stroke(d.poly([(x0 + 7, y0 + 7), (x1 - 7, y0 + 7), (x1 - 7, y1 - 7), (x0 + 7, y1 - 7)], r=6, j=0.4, bow=0.6), dark(wood, 0.2), 2.2))
    return P


def magnifier(d):
    rim, handle = CORAL, WOOD
    P = [d.tube(Path((74, 74)).L((106, 106)), 15, handle)]
    P.append(d.tube(Path((70, 70)).L((79, 79)), 17, dark(rim, 0.1), lw=3))
    P.append(d.fill(d.oval(48, 48, 33, 33), "#DDEFF8", line=False, grad=None, opacity=0.9))
    P.append(d.stroke(smooth([(28, 50), (30, 36), (42, 28)], closed=False), "#FFFFFF", 5, 0.9))
    P.append(d.dot(56, 62, 3, "#FFFFFF", 0.8))
    P.append(d.tube(d.oval(48, 48, 33, 33), 7, rim, lw=2.6))
    return P


def book(d):
    """A closed picture book with a star on the cover."""
    cover, page = DUSTY, "#FFF8EE"
    P = [d.fill(d.poly([(28, 20), (104, 20), (104, 110), (28, 110)], r=8, j=0.4, bow=0.6), page)]
    for k in (1, 2):
        P.append(line(d, [(98 + 2 * k, 30), (98 + 2 * k, 104)], dark(page, 0.25), 1.4, j=0.2))
        P.append(line(d, [(36, 104 + 2 * k), (98, 104 + 2 * k)], dark(page, 0.25), 1.4, j=0.2))
    front = d.poly([(16, 10), (96, 10), (96, 102), (16, 102)], r=9, j=0.5, bow=0.8)
    P.append(d.fill(front, cover))
    P.append(d.clipped(front, lambda: [d.fill(d.poly([(10, 4), (28, 4), (28, 110), (10, 110)], r=1, j=0.3, bow=0.4), dark(cover, 0.18), line=False, grad=None)]))
    P.append(d.stroke(front, dark(cover), 3.5))
    P.append(d.fill(star_path(d, 62, 50, 21, 10, corner=3), GOLD, lw=2.6))
    P.append(line(d, [(46, 84), (78, 84)], light(cover, 0.5), 4.5, j=0.2))
    return P


def task(d):
    """Today's tasks: a little clipboard with two ticks."""
    paper, metal, tick = "#FFFDF8", "#AFC3D2", "#6FA65A"
    P = [d.fill(d.poly([(16, 16), (104, 16), (104, 114), (16, 114)], r=11, j=0.5, bow=0.8), WOOD)]
    P.append(d.fill(d.poly([(27, 28), (93, 28), (93, 104), (27, 104)], r=5, j=0.4, bow=0.6), paper, lw=2.6))
    P.append(d.fill(d.poly([(40, 6), (80, 6), (82, 28), (38, 28)], r=6, j=0.4, bow=0.6), metal, lw=3))
    P.append(d.fill(d.oval(60, 14, 6, 3.5), "#FFFFFF", line=False, grad=None))
    for k, y in enumerate((50, 70, 90)):
        P.append(d.fill(d.poly([(34, y - 7.5), (49, y - 7.5), (49, y + 7.5), (34, y + 7.5)], r=3, j=0.3, bow=0.4), "#FFF6E6", lw=2.4, edge="#C3A88E"))
        P.append(line(d, [(56, y), (85, y)], "#D9C6B0", 5, j=0.2))
        if k < 2:
            P.append(d.stroke(smooth([(35, y - 1), (41, y + 6), (53, y - 10)], closed=False), tick, 5))
    return P


ITEM_DRAW = {"block": block, "magnifier": magnifier, "book": book, "task": task}


# ---------------------------------------------------------------- writing
def square_svg(name, fn):
    """[fn]'s drawing centred in the 240 square, scaled so it fills it less MARGIN."""
    d = Doc(name, lw=LW)
    parts = fn(d)
    x0, y0, x1, y1 = d.box
    s = (S - 2 * MARGIN) / max(x1 - x0, y1 - y0)
    tx, ty = S / 2 - s * (x0 + x1) / 2, S / 2 - s * (y0 + y1) / 2
    body = f'<g transform="translate({n(tx)} {n(ty)}) scale({s:.3f})">{"".join(parts)}</g>'
    return d.svg([body], box=(0, 0, S, S)), s


def main():
    for folder, table, prefix in (("words", WORD_DRAW, "w"), ("rewards", REWARD_DRAW, "r")):
        out = ART / folder
        out.mkdir(parents=True, exist_ok=True)
        for name, fn in table.items():
            svg, s = square_svg(f"{prefix}-{name}", fn)
            (out / f"{name}.svg").write_text(svg)
            print(f"{folder}/{name}.svg  scale {s:.2f}  {len(svg) / 1024:.1f} KB")
    out = ART / "items"
    for name, fn in ITEM_DRAW.items():
        d = Doc(name, lw=3.5)
        svg = d.svg(fn(d), box=(0, 0, 120, 120))
        (out / f"{name}.svg").write_text(svg)
        print(f"items/{name}.svg  {len(svg) / 1024:.1f} KB")


if __name__ == "__main__":
    main()
