"""The strokes of every character the child writes (0.1: warm-up lines,
0-9, A-Z), in the order and direction they are written, as
app/assets/glyphs.json.

A character sits in a box 100 high (the cap height), as wide as it needs.
y grows downwards. Each stroke is a list of points about 2.5 apart, from
where the pen starts to where it lifts. The shapes are a simple
"ball and stick" print, close to what Taiwan's schoolbooks use; the order
and directions are written down in docs/letters.md.

    python3 glyphs.py          # writes app/assets/glyphs.json and prints a summary
    python3 glyphs.py preview out.png   # every character drawn, the start of each stroke marked
"""
import json
import math
import pathlib
import sys

OUT = pathlib.Path(__file__).resolve().parents[2] / "app" / "assets" / "glyphs.json"
STEP = 2.5


def line(*pts):
    """A straight polyline through [pts]."""
    out = [pts[0]]
    for a, b in zip(pts, pts[1:]):
        n = max(1, math.ceil(math.dist(a, b) / STEP))
        out += [(a[0] + (b[0] - a[0]) * i / n, a[1] + (b[1] - a[1]) * i / n) for i in range(1, n + 1)]
    return out


def arc(cx, cy, rx, ry, start, end):
    """An elliptical arc from angle [start] to [end] (degrees; 0 is to the
    right, 90 is down since y grows downwards). Going from a larger to a
    smaller angle turns the way a clock's hands do not: counterclockwise
    on the screen."""
    length = abs(end - start) / 360 * 2 * math.pi * (rx + ry) / 2
    n = max(2, math.ceil(length / STEP))
    return [(cx + rx * math.cos(math.radians(start + (end - start) * i / n)),
             cy + ry * math.sin(math.radians(start + (end - start) * i / n))) for i in range(n + 1)]


def join(*parts):
    """One stroke made of pieces that follow on from each other."""
    out = list(parts[0])
    for p in parts[1:]:
        out += p[1:] if math.dist(out[-1], p[0]) < 1e-6 else line(out[-1], p[0])[1:] + p[1:]
    return out


# ---------------------------------------------------------------- the characters

def warmups():
    return {
        "line_v": ("直線", 40, [line((20, 0), (20, 100))]),
        "line_h": ("橫線", 100, [line((0, 50), (100, 50))]),
        "circle": ("圓圈", 100, [arc(50, 50, 48, 48, -90, -450)]),
        "cross": ("十字", 100, [line((50, 0), (50, 100)), line((0, 50), (100, 50))]),
        "slash": ("斜線", 80, [line((80, 0), (0, 100))]),
        "x": ("叉叉", 90, [line((0, 0), (90, 100)), line((90, 0), (0, 100))]),
    }


def digits():
    return {
        "1": ("一", 30, [line((15, 0), (15, 100))]),
        "0": ("零", 64, [arc(32, 50, 30, 48, -90, -450)]),
        "7": ("七", 64, [line((2, 2), (62, 2), (22, 100))]),
        "4": ("四", 70, [line((46, 0), (2, 66), (68, 66)), line((46, 0), (46, 100))]),
        "6": ("六", 64, [join(arc(34, 62, 30, 36, -70, -180), arc(32, 72, 28, 26, 180, -180))]),
        "9": ("九", 64, [join(arc(32, 28, 28, 26, 0, -360), line((60, 28), (60, 100)))]),
        "2": ("二", 64, [join(arc(32, 28, 28, 26, 190, 380), line((58, 38), (2, 100), (62, 100)))]),
        "3": ("三", 62, [join(arc(30, 25, 26, 23, 200, 450), arc(30, 73, 29, 25, 270, 520))]),
        "5": ("五", 62, [join(line((10, 2), (8, 46)), arc(30, 68, 28, 30, 225, 495)), line((10, 2), (58, 2))]),
        "8": ("八", 64, [join(arc(32, 25, 24, 23, -90, -270), arc(32, 74, 29, 26, -90, 270), arc(32, 25, 24, 23, 90, -90))]),
    }


def capitals():
    return {
        # Straight lines only.
        "L": (56, [line((8, 0), (8, 100), (56, 100))]),
        "T": (64, [line((2, 2), (62, 2)), line((32, 2), (32, 100))]),
        "F": (56, [line((8, 0), (8, 100)), line((8, 2), (54, 2)), line((8, 50), (44, 50))]),
        "E": (56, [line((8, 0), (8, 100)), line((8, 2), (54, 2)), line((8, 50), (46, 50)), line((8, 98), (54, 98))]),
        "H": (64, [line((8, 0), (8, 100)), line((56, 0), (56, 100)), line((8, 50), (56, 50))]),
        "I": (44, [line((22, 0), (22, 100)), line((4, 2), (40, 2)), line((4, 98), (40, 98))]),
        # With curves.
        "O": (84, [arc(42, 50, 40, 48, -90, -450)]),
        "C": (72, [arc(42, 50, 40, 48, -40, -320)]),
        "G": (76, [join(arc(42, 50, 40, 48, -40, -360), line((82, 50), (82, 80))), line((50, 52), (80, 52))]),
        "D": (66, [line((8, 0), (8, 100)), join(line((8, 2), (24, 2)), arc(24, 50, 40, 48, -90, 90), line((24, 98), (8, 98)))]),
        "P": (60, [line((8, 0), (8, 100)), join(line((8, 2), (28, 2)), arc(28, 27, 28, 25, -90, 90), line((28, 52), (8, 52)))]),
        "B": (62, [line((8, 0), (8, 100)),
                   join(line((8, 2), (28, 2)), arc(28, 25, 24, 23, -90, 90), line((28, 48), (8, 48))),
                   join(line((8, 48), (30, 48)), arc(30, 73, 28, 25, -90, 90), line((30, 98), (8, 98)))]),
        "R": (62, [line((8, 0), (8, 100)), join(line((8, 2), (28, 2)), arc(28, 27, 28, 25, -90, 90), line((28, 52), (8, 52))), line((26, 52), (60, 100))]),
        "U": (64, [join(line((6, 0), (6, 68)), arc(32, 68, 26, 30, 180, 0), line((58, 68), (58, 0)))]),
        "J": (52, [join(line((44, 0), (44, 74)), arc(24, 74, 20, 24, 0, 160))]),
        "S": (62, [join(arc(32, 25, 26, 23, -20, -270), arc(32, 73, 28, 25, -90, 140))]),
        "Q": (84, [arc(42, 50, 40, 48, -90, -450), line((50, 70), (82, 100))]),
        # With slanted lines.
        "V": (70, [line((2, 0), (35, 100), (68, 0))]),
        "W": (92, [line((2, 0), (24, 100), (46, 28), (68, 100), (90, 0))]),
        "X": (66, [line((4, 0), (62, 100)), line((62, 0), (4, 100))]),
        "Y": (66, [line((4, 0), (33, 48)), line((62, 0), (33, 48), (33, 100))]),
        "Z": (64, [line((4, 2), (60, 2), (4, 98), (60, 98))]),
        "K": (62, [line((8, 0), (8, 100)), line((58, 0), (8, 58)), line((24, 42), (60, 100))]),
        "M": (80, [line((6, 0), (6, 100)), line((6, 0), (40, 70), (74, 0)), line((74, 0), (74, 100))]),
        "N": (64, [line((6, 0), (6, 100)), line((6, 0), (58, 100)), line((58, 0), (58, 100))]),
        "A": (74, [line((37, 0), (2, 100)), line((37, 0), (72, 100)), line((18, 64), (56, 64))]),
    }


# What the voice says with a capital: an English word and its Mandarin.
WORDS = {
    "A": ("apple", "蘋果"), "B": ("ball", "球"), "C": ("cat", "貓"), "D": ("dog", "狗"), "E": ("egg", "蛋"),
    "F": ("fish", "魚"), "G": ("grapes", "葡萄"), "H": ("hat", "帽子"), "I": ("ice cream", "冰淇淋"), "J": ("juice", "果汁"),
    "K": ("kite", "風箏"), "L": ("lion", "獅子"), "M": ("moon", "月亮"), "N": ("nose", "鼻子"), "O": ("orange", "柳橙"),
    "P": ("pig", "豬"), "Q": ("queen", "皇后"), "R": ("rabbit", "兔子"), "S": ("sun", "太陽"), "T": ("tree", "樹"),
    "U": ("umbrella", "雨傘"), "V": ("violin", "小提琴"), "W": ("watermelon", "西瓜"), "X": ("xylophone", "木琴"),
    "Y": ("yo-yo", "溜溜球"), "Z": ("zebra", "斑馬"),
}

GROUPS = [
    ("warmup", "暖身線條", list(warmups())),
    ("digits", "數字", list(digits())),
    ("straight", "大寫：直直的線", ["L", "T", "F", "E", "H", "I"]),
    ("curves", "大寫：彎彎的線", ["O", "C", "G", "D", "P", "B", "R", "U", "J", "S", "Q"]),
    ("slants", "大寫：斜斜的線", ["V", "W", "X", "Y", "Z", "K", "M", "N", "A"]),
]


def build():
    glyphs = []
    for gid, label, (w, strokes) in [(k, v[0], (v[1], v[2])) for k, v in warmups().items()]:
        glyphs.append({"id": gid, "kind": "warmup", "show": "", "zh": label, "en": "", "width": w, "strokes": strokes})
    for gid, (zh, w, strokes) in digits().items():
        glyphs.append({"id": gid, "kind": "digit", "show": gid, "zh": zh, "en": gid, "width": w, "strokes": strokes})
    for gid, (w, strokes) in capitals().items():
        en, zh = WORDS[gid]
        glyphs.append({"id": gid, "kind": "capital", "show": gid, "zh": zh, "en": en, "width": w, "strokes": strokes})
    for g in glyphs:
        g["strokes"] = [[[round(x, 1), round(y, 1)] for x, y in s] for s in g["strokes"]]
        xs = [p[0] for s in g["strokes"] for p in s]
        ys = [p[1] for s in g["strokes"] for p in s]
        assert min(xs) >= -1, (g["id"], min(xs))
        g["width"] = max(g["width"], math.ceil(max(xs)) + 2)
        assert min(ys) >= -1 and max(ys) <= 101, (g["id"], min(ys), max(ys))
    order = {gid: i for i, gid in enumerate(g["id"] for g in glyphs)}
    groups = [{"id": gid, "label": label, "glyphs": ids} for gid, label, ids in GROUPS]
    assert sorted(order) == sorted(i for g in groups for i in g["glyphs"])
    return {"version": 1, "height": 100, "groups": groups, "glyphs": glyphs}


def preview(out):
    """Every character on a grid: grey strokes, a green dot where each starts, its number."""
    data = build()
    cell, pad = 150, 25
    cols = 9
    rows = math.ceil(len(data["glyphs"]) / cols)
    parts = []
    for i, g in enumerate(data["glyphs"]):
        ox, oy = (i % cols) * cell + pad, (i // cols) * cell + pad
        for n, s in enumerate(g["strokes"]):
            d = "M" + " L".join(f"{ox + x:.1f} {oy + y:.1f}" for x, y in s)
            parts.append(f'<path d="{d}" fill="none" stroke="#C9BBA8" stroke-width="9" stroke-linecap="round" stroke-linejoin="round"/>')
            x, y = s[0]
            parts.append(f'<circle cx="{ox + x}" cy="{oy + y}" r="7" fill="#4CAF50"/><text x="{ox + x + 9}" y="{oy + y - 6}" font-size="13" fill="#2E7D32">{n + 1}</text>')
            x2, y2 = s[min(len(s) - 1, 3)]
            parts.append(f'<line x1="{ox + x}" y1="{oy + y}" x2="{ox + x2}" y2="{oy + y2}" stroke="#E53935" stroke-width="3"/>')
        parts.append(f'<text x="{ox}" y="{oy + 122}" font-size="14" fill="#555">{g["id"]}</text>')
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{cols * cell}" height="{rows * cell}">'
           f'<rect width="100%" height="100%" fill="#fff"/>{"".join(parts)}</svg>')
    tmp = pathlib.Path(out).with_suffix(".svg")
    tmp.write_text(svg)
    import subprocess
    subprocess.run(["node", "/home/user/APP_Kids_Paint/docs/design/v6/render_alpha.js", str(tmp), str(out), str(cols * cell), str(rows * cell)], check=True)


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "preview":
        preview(sys.argv[2])
    else:
        data = build()
        OUT.write_text(json.dumps(data, ensure_ascii=False, separators=(",", ":")))
        print(len(data["glyphs"]), "characters,", OUT.stat().st_size // 1024, "KB")
