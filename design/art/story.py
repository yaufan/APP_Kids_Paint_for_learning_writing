"""字母寵物's opening story: three picture-book pages, 1080 x 1080, opaque.

    python3 story.py            # writes app/assets/art/story/story_{1,2,3}.svg

1. The edge of the letter forest at dusk: a small cosy pet house with a
   round door and a warm window.
2. The same doorstep with the seven eggs, softly glowing (the same eggs
   as app/assets/art/eggs/).
3. An open picture book on a table, the eggs peeking out of it: the
   "pick one" page.
No words in the pictures: the app prints the story text.
"""
import math
import pathlib

from homes import CLOUD, bush, face, flower, glow, round_tree, tuft
from pets import EGG_H, EGG_W, PET_IDS, egg_parts
from storybook import Doc, Path, dark, light, mirror_pts, n, smooth

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "app" / "assets" / "art" / "story"
S = 1080

# Little glowing letters drift among the trees of the letter forest
# (shapes, not words). Set to False for plain fireflies.
LETTER_FIREFLIES = True

DUSK_TOP, DUSK_LOW = "#A596C9", "#F6C39C"
WALL, DOOR, WOOD = "#F6DDBE", "#D98C6E", "#C99A6E"
WARM = "#FFE7A6"


def sky(d, top, low, y1):
    return f'<rect width="{S}" height="{S}" fill="{low}"/><rect width="{S}" height="{y1}" fill="{d.grad(low, ("down", top))}"/>'


def hills(d, y, amp, wl, color, phase, line=True):
    pts = [(-60 + (S + 120) * i / 24, y + amp * math.sin(2 * math.pi * (-60 + (S + 120) * i / 24) / wl + phase)) for i in range(25)]
    top = smooth(d.jit(pts, 1.5), closed=False)
    top.L((S + 60, S + 60)).L((-60, S + 60))
    top.closed = True
    return d.fill(top, color, line=line, lw=3, grad="flat")


def sparkle(d, x, y, r, color="#FFF6DA", opacity=0.9):
    p = Path((x, y - r)).Q((x, y), (x + r, y)).Q((x, y), (x, y + r)).Q((x, y), (x - r, y)).Q((x, y), (x, y - r))
    p.closed = True
    d.track([(x, y)], r)
    return f'<path d="{p.d()}" fill="{color}" opacity="{opacity:.2f}"/>'


def moon(d, x, y, r):
    """A sleepy crescent moon."""
    from pets import crescent
    P = [glow(d, x, y, r * 2.6, "#FFF4D0", 0.45),
         d.fill(d.blob(crescent(x, y, r, x + r * 0.55, y - r * 0.4, r * 0.85), 0.8), "#FBE7A8", lw=3)]
    P += face(d, x - r * 0.42, y + r * 0.2, r / 70, sleepy=True)
    return P


def letter_glow(d, x, y, s, which):
    """A tiny glowing letter, like a firefly."""
    shapes = {"A": [[(-8, 10), (0, -10), (8, 10)], [(-4.5, 3), (4.5, 3)]],
              "b": [[(-6, -12), (-6, 10)], [(-6, 2), (0, -3), (6, 2), (6, 6), (0, 11), (-6, 7)]],
              "3": [[(-6, -9), (0, -12), (6, -8), (0, -1), (6, 5), (0, 11), (-6, 8)]],
              "C": [[(7, -8), (0, -12), (-7, -5), (-7, 5), (0, 12), (7, 8)]]}
    P = [glow(d, x, y, 34 * s, "#FFF1B0", 0.6)]
    for pts in shapes[which]:
        P.append(d.stroke(smooth([(x + px * s, y + py * s) for px, py in pts], closed=False) if len(pts) > 3
                          else Path((x + pts[0][0] * s, y + pts[0][1] * s)).L((x + pts[1][0] * s, y + pts[1][1] * s)) if len(pts) == 2
                          else Path((x + pts[0][0] * s, y + pts[0][1] * s)).L((x + pts[1][0] * s, y + pts[1][1] * s)).L((x + pts[2][0] * s, y + pts[2][1] * s)),
                          "#FFF3C4", 3.2 * s))
    return P


def firefly(d, x, y, r=5):
    return [glow(d, x, y, r * 5, "#FFF1B0", 0.55), d.dot(x, y, r, "#FFF3C4")]


def tall_tree(d, x, y, s, leaf):
    """A rounded storybook fir: three soft tiers."""
    P = [d.fill(d.poly([(x - 10 * s, y), (x - 8 * s, y - 60 * s), (x + 8 * s, y - 60 * s), (x + 10 * s, y)], r=4 * s), "#9C7A66", lw=3)]
    for k, (w, top, bot) in enumerate(((70, -150, -40), (58, -215, -110), (44, -270, -175))):
        P.append(d.fill(d.blob([(x - w * s, y + bot * s), (x - w * 0.5 * s, y + (bot + top) * 0.5 * s - 6 * s), (x, y + top * s),
                                (x + w * 0.5 * s, y + (bot + top) * 0.5 * s - 6 * s), (x + w * s, y + bot * s), (x, y + (bot + 14) * s)], 1.2 * s),
                         light(leaf, 0.04 * k), lw=3))
    return P


def egg(d, pid, x, bottom, scale, part="whole"):
    """One of the seven eggs, its bottom centre at (x, bottom)."""
    tx, ty = x - EGG_W / 2 * scale, bottom - EGG_H * scale
    d.track([(tx, ty), (tx + EGG_W * scale, bottom)])
    return f'<g transform="translate({n(tx)} {n(ty)}) scale({scale})">{"".join(egg_parts(d, pid, part))}</g>'


def pet_house(d, x, base, s=1.0, door_open=False):
    """A small cosy house for a pet: a round door, a round warm window, a soft roof."""
    P = []
    wall = d.blob([(x - 150 * s, base), (x - 160 * s, base - 120 * s), (x - 130 * s, base - 200 * s), (x, base - 236 * s),
                   (x + 130 * s, base - 200 * s), (x + 160 * s, base - 120 * s), (x + 150 * s, base)], 1.5 * s)
    P.append(d.fill(d.poly([(x + 70 * s, base - 250 * s), (x + 70 * s, base - 330 * s), (x + 112 * s, base - 330 * s), (x + 112 * s, base - 230 * s)],
                           r=8 * s), "#C9876F", lw=3))
    for k, (dx, dy, r) in enumerate(((96, -360, 16), (112, -398, 21), (94, -440, 26))):
        P.append(f'<circle cx="{n(x + dx * s)}" cy="{n(base + dy * s)}" r="{n(r * s)}" fill="{CLOUD}" opacity="{0.75 - k * 0.15:.2f}"/>')
    P.append(d.fill(wall, WALL))
    roof = d.blob([(x - 196 * s, base - 150 * s), (x - 160 * s, base - 240 * s), (x - 70 * s, base - 300 * s), (x, base - 314 * s),
                   (x + 70 * s, base - 300 * s), (x + 160 * s, base - 240 * s), (x + 196 * s, base - 150 * s), (x + 150 * s, base - 168 * s),
                   (x + 100 * s, base - 150 * s), (x + 50 * s, base - 168 * s), (x, base - 150 * s), (x - 50 * s, base - 168 * s),
                   (x - 100 * s, base - 150 * s), (x - 150 * s, base - 168 * s)], 1.5 * s)
    P.append(d.fill(roof, "#8FA9CC"))
    for dx in (-120, -40, 40, 120):
        P.append(d.dot(x + dx * s, base - 220 * s - abs(dx) * 0.2 * s, 7 * s, light("#8FA9CC", 0.35), 0.9))
    # the round warm window
    P.append(glow(d, x - 82 * s, base - 100 * s, 120 * s, WARM, 0.55))
    P.append(d.fill(d.oval(x - 82 * s, base - 100 * s, 38 * s, 38 * s), "#E2B489", lw=3))
    P.append(d.fill(d.oval(x - 82 * s, base - 100 * s, 28 * s, 28 * s), "#FFE08A", lw=2.4, grad=("at", x - 90 * s, base - 108 * s, 34 * s)))
    P.append(d.stroke(Path((x - 82 * s, base - 128 * s)).L((x - 82 * s, base - 72 * s)), "#E2B489", 5 * s))
    P.append(d.stroke(Path((x - 110 * s, base - 100 * s)).L((x - 54 * s, base - 100 * s)), "#E2B489", 5 * s))
    # the round door
    P.append(d.fill(d.oval(x + 40 * s, base - 70 * s, 64 * s, 74 * s), dark(WOOD, 0.1)))
    door = Path((x - 10 * s, base)).L((x - 10 * s, base - 70 * s)).C((x - 10 * s, base - 140 * s), (x + 90 * s, base - 140 * s), (x + 90 * s, base - 70 * s)).L((x + 90 * s, base))
    door.closed = True
    if door_open:
        P.append(glow(d, x + 40 * s, base - 60 * s, 150 * s, WARM, 0.7))
        P.append(d.fill(door, "#FFE29A", grad=("at", x + 40 * s, base - 50 * s, 90 * s)))
    else:
        P.append(d.fill(door, DOOR))
        for dx in (14, 40, 66):
            P.append(d.stroke(d.curve([(x + dx * s, base - 6 * s), (x + dx * s, base - 112 * s + abs(dx - 40) * 0.9 * s)], 0.6), dark(DOOR, 0.2), 2.6 * s))
        P.append(d.dot(x + 72 * s, base - 62 * s, 5.5 * s, "#F6CF6A"))
    P.append(d.fill(d.poly([(x - 30 * s, base - 4 * s), (x + 110 * s, base - 4 * s), (x + 118 * s, base + 14 * s), (x - 38 * s, base + 14 * s)], r=6 * s), "#CFC6BE", lw=3))
    return P


# ---------------------------------------------------------------- the pages
def story_1(d):
    """The edge of the letter forest at dusk, and a small cosy house."""
    P = [sky(d, DUSK_TOP, DUSK_LOW, 760)]
    for x, y, r in ((160, 110, 7), (300, 70, 5), (470, 140, 6), (650, 60, 8), (820, 120, 5), (980, 80, 7), (90, 240, 4), (560, 230, 4),
                    (900, 260, 5), (760, 200, 3.5)):
        P.append(sparkle(d, x, y, r * 1.6))
    P += moon(d, 860, 190, 62)
    P.append(hills(d, 600, 22, 700, "#B3A3C9", 0.4))
    P.append(hills(d, 660, 16, 900, "#A4B3CB", 1.8))
    # the forest: rounded trees on both sides, the house in a clearing
    for x, y, s, c in ((60, 760, 1.15, "#7E9E98"), (190, 740, 0.95, "#8BA996"), (300, 760, 0.8, "#7E9E98"), (870, 740, 0.85, "#8BA996"),
                       (990, 760, 1.2, "#7E9E98")):
        P += tall_tree(d, x, y, s, c)
    P.append(hills(d, 760, 14, 1100, "#9FB88F", 0.9))
    for x, y, s, c in ((40, 900, 1.0, "#88A982"), (230, 880, 0.7, "#97B48A"), (1010, 900, 1.05, "#88A982"), (840, 880, 0.65, "#97B48A")):
        P += round_tree(d, x, y, s, c)
    P += pet_house(d, 560, 840, 1.0)
    # stepping stones to the door
    for x, y, rx in ((612, 880, 30), (580, 930, 34), (618, 990, 38), (570, 1050, 42)):
        P.append(d.fill(d.oval(x, y, rx, rx * 0.42), "#D6CCC2", lw=2.6))
    P += bush(d, 360, 860, 0.8, "#8FAE84") + bush(d, 760, 866, 0.7, "#8FAE84")
    for fx, fy, c in ((410, 900, "#F4A7A1"), (450, 920, "#FFFFFF"), (720, 900, "#F6CF6A")):
        P += flower(d, fx, fy, 0.9, c)
    for tx, ty in ((140, 980), (300, 1030), (880, 1000), (980, 1050)):
        P += tuft(d, tx, ty, 1.0, "#9FB88F")
    # fireflies and little glowing letters among the trees
    for x, y in ((140, 560), (330, 640), (930, 600), (760, 520), (250, 470)):
        P += firefly(d, x, y, 4.5)
    if LETTER_FIREFLIES:
        for x, y, s, ch in ((110, 420, 1.3, "A"), (950, 470, 1.2, "b"), (300, 560, 1.1, "3")):
            P += letter_glow(d, x, y, s, ch)
    return P


def story_2(d):
    """The doorstep: seven eggs glowing softly in front of the round door."""
    P = [sky(d, DUSK_TOP, DUSK_LOW, 700)]
    for x, y, r in ((80, 90, 6), (220, 50, 4), (900, 70, 7), (1010, 160, 4)):
        P.append(sparkle(d, x, y, r * 1.6))
    P.append(hills(d, 620, 14, 800, "#A4B3CB", 0.6))
    P += pet_house(d, 520, 770, 1.75, door_open=True)
    P.append(hills(d, 740, 8, 1300, "#9FB88F", 1.2))
    P += bush(d, 60, 780, 1.1, "#8FAE84") + bush(d, 1030, 780, 1.1, "#8FAE84")
    # the seven eggs in a soft arc on the grass
    spots = [(130, 930, 0.52), (270, 966, 0.56), (410, 990, 0.6), (550, 1000, 0.62), (690, 990, 0.6), (830, 966, 0.56), (965, 930, 0.52)]
    order = [3, 2, 4, 1, 5, 0, 6]
    for (x, y, sc), pid in zip(spots, PET_IDS):
        P.append(glow(d, x, y - EGG_H * sc * 0.5, EGG_H * sc * 0.95, "#FFF1B8", 0.75))
    for i in sorted(range(7), key=lambda k: spots[k][1]):
        x, y, sc = spots[i]
        P.append(f'<ellipse cx="{n(x)}" cy="{n(y - 2)}" rx="{n(EGG_W * sc * 0.42)}" ry="{n(10 * sc)}" fill="#6E7E5E" opacity="0.18"/>')
        P.append(egg(d, PET_IDS[i], x, y, sc))
    for x, y in ((210, 820), (480, 860), (760, 840), (900, 800), (350, 790)):
        P.append(sparkle(d, x, y, 10, "#FFF6DA", 0.95))
    return P


def story_3(d):
    """An open picture book on a table, the eggs peeking out: pick one!"""
    wall, table = "#F4DDC4", "#D9AE82"
    P = [f'<rect width="{S}" height="{S}" fill="{wall}"/>']
    for x in range(40, S, 120):
        for y in range(240, 560, 110):
            P.append(d.dot(x + (y // 110 % 2) * 60, y, 5, light(wall, 0.45), 0.8))
    P.append(glow(d, 540, 520, 560, "#FFF0C8", 0.6))
    # a little garland of paper flags
    string = smooth([(-20, 70), (270, 130), (540, 150), (810, 130), (1100, 70)], closed=False)
    P.append(d.stroke(string, "#B98A64", 3))
    pts = string.points(20)
    colors = ["#EE9A86", "#F2C45C", "#A9C79A", "#93B5D6", "#BFA6D9"]
    for k, i in enumerate(range(6, len(pts) - 4, 7)):
        x, y = pts[i]
        P.append(d.fill(d.poly([(x - 26, y), (x + 26, y), (x, y + 54)], r=5, j=0.6, bow=1), colors[k % 5], lw=2.6))
    P.append(d.fill(d.poly([(-20, 560), (S + 20, 560), (S + 20, S + 20), (-20, S + 20)], r=4, j=1.5, bow=3), table))
    for y in (1000, 1050):
        P.append(d.stroke(d.curve([(-10, y), (540, y + 4), (S + 10, y)], 1.2), dark(table, 0.14), 3))
    # the book: a coral cover under two cream pages
    cover = d.blob([(36, 620), (160, 566), (320, 552), (460, 570), (540, 612), (620, 570), (760, 552), (920, 566), (1044, 620), (1062, 962),
                    (790, 926), (540, 988), (290, 926), (18, 962)], 1.5)
    P.append(d.fill(cover, "#E8907C"))
    for k, off in enumerate((16, 8, 0)):
        left = d.blob([(66, 600 + off), (170, 552 + off), (320, 538 + off), (450, 554 + off), (536, 600 + off), (536, 942 + off),
                       (420, 912 + off), (240, 900 + off), (58, 930 + off)], 1.0)
        right = d.blob(mirror_pts([(66, 600 + off), (170, 552 + off), (320, 538 + off), (450, 554 + off), (536, 600 + off), (536, 942 + off),
                                   (420, 912 + off), (240, 900 + off), (58, 930 + off)], 540), 1.0)
        shade = dark("#FFF8EC", 0.05 * (2 - k))
        P += [d.fill(left, shade, lw=2.6), d.fill(right, shade, lw=2.6)]
    P.append(d.stroke(d.curve([(540, 590), (540, 940)], 0.5), dark("#FFF8EC", 0.25), 3))
    P += [d.fill(d.oval(170, 630, 26, 26), "#F7CD62", lw=2.4)]
    P.append(f'<g fill="{CLOUD}" stroke="{dark(CLOUD, 0.3)}" stroke-width="2"><ellipse cx="900" cy="640" rx="40" ry="16"/></g>')
    # the eggs peeking out, behind little pop-up paper hills
    back = [(300, 724, 0.62), (540, 716, 0.64), (780, 724, 0.62)]
    front = [(180, 884, 0.62), (420, 892, 0.64), (660, 892, 0.64), (900, 884, 0.62)]
    for (x, y, sc), pid in zip(back, ("dino", "puppy", "dolphin")):
        P.append(glow(d, x, y - 80, 110, "#FFF1B8", 0.65))
        P.append(egg(d, pid, x, y, sc))
    P.append(d.fill(d.blob([(100, 730), (220, 692), (300, 700), (420, 682), (540, 694), (660, 682), (780, 700), (860, 692), (980, 730),
                            (950, 768), (540, 780), (130, 768)], 1.2), "#A9C79A", lw=2.6))
    for (x, y, sc), pid in zip(front, ("kitten", "bunny", "octopus", "turtle")):
        P.append(glow(d, x, y - 80, 110, "#FFF1B8", 0.65))
        P.append(egg(d, pid, x, y, sc))
    P.append(d.fill(d.blob([(62, 886), (180, 848), (300, 864), (420, 842), (540, 860), (660, 842), (780, 864), (900, 848), (1018, 886),
                            (1012, 934), (780, 908), (540, 952), (300, 908), (68, 934)], 1.2), "#BCD7A6", lw=2.6))
    for x, y, c in ((300, 892, "#F4A7A1"), (540, 900, "#F6CF6A"), (780, 892, "#FFFFFF"), (130, 900, "#F6CF6A"), (950, 900, "#F4A7A1")):
        P.append(d.fill(d.oval(x, y, 9, 9), c, lw=2))
        P.append(d.dot(x, y, 3.4, "#F6C65C"))
    for x, y, r in ((130, 480, 13), (950, 470, 15), (420, 520, 9), (680, 500, 11), (540, 420, 8)):
        P.append(sparkle(d, x, y, r, "#FFFFFF", 0.95))
    return P


PAGES = {"story_1": story_1, "story_2": story_2, "story_3": story_3}


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for name, fn in PAGES.items():
        d = Doc(name, lw=3)
        parts = fn(d) + [grain_square(d)]
        (OUT / f"{name}.svg").write_text(d.svg(parts, box=(0, 0, S, S)))


def grain_square(d, count=520):
    return (d.speckle(0, 0, S, S, count, ["#6E5240"], 0.8, 2.2, 0.07)
            + d.speckle(0, 0, S, S, count // 2, ["#FFFFFF"], 0.8, 2.0, 0.22))


if __name__ == "__main__":
    main()
