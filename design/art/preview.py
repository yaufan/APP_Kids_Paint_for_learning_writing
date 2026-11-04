"""A contact sheet of all of 字母寵物's art, to look at, and a check of the pets' crops.

    python3 preview.py out.png

The sheet: the pets with their three eyes (and pets.json's points drawn
over them), the eggs whole and cracked, the homes with their pet standing
at y = 1450 (30% of the width), the items and wear, the story pages and
the app icon. It also prints, for each pet, the space left round it in its
picture (the bottom should be 0: the pet stands on the bottom edge).
Needs Node.js with Playwright (Chromium draws the SVGs) and Pillow.
"""
import json
import pathlib
import re
import subprocess
import sys
import tempfile

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[2]
ART = ROOT / "app" / "assets" / "art"
ICON = ROOT / "app" / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset" / "Icon-App-1024x1024@1x.png"
RENDER = pathlib.Path("/home/user/APP_Kids_Paint/docs/design/v6/render_alpha.js")
if not RENDER.exists():
    RENDER = pathlib.Path(__file__).resolve().parent / "render_alpha.js"

PETS = ["puppy", "kitten", "bunny", "dino", "dolphin", "octopus", "turtle"]
ITEMS = ["bowl", "cookie", "sponge", "shower", "ball", "bubbleBall", "moon", "star", "heart", "giftClosed", "giftOpen",
         "brush", "blanket", "zzz", "feast_closed", "feast_open", "sun"]
WEAR = ["bib", "cap"]
SHEET_W = 2200
BG = "#F3EEE6"


def size_of(svg):
    m = re.search(r'viewBox="0 0 ([\d.]+) ([\d.]+)"', svg.read_text())
    return float(m.group(1)), float(m.group(2))


def render_html(html, out, w, h):
    with tempfile.NamedTemporaryFile("w", suffix=".html", delete=False) as f:
        f.write(html)
    try:
        subprocess.run(["node", str(RENDER), f.name, str(out), str(int(w)), str(int(h))], check=True)
    finally:
        pathlib.Path(f.name).unlink()


class Sheet:
    def __init__(self):
        self.parts = []
        self.y = 20

    def img(self, path, x, y, w, h, extra=""):
        self.parts.append(f'<img src="file://{path}" style="position:absolute;left:{x:.1f}px;top:{y:.1f}px;width:{w:.1f}px;height:{h:.1f}px;{extra}">')

    def text(self, s, x, y, size=26, bold=True):
        self.parts.append(f'<div style="position:absolute;left:{x}px;top:{y}px;font:{"700" if bold else "400"} {size}px sans-serif;color:#6B5547">{s}</div>')

    def raw(self, html):
        self.parts.append(html)

    def title(self, s):
        self.text(s, 24, self.y, 30)
        self.y += 50


def pets_section(sh, info):
    sh.title("Pets: open, happy (^ ^), sleep, and pets.json points (head circle, eyes, mouth +, body box)")
    cell, box = 300, 270
    for row, suffix in enumerate(("", "_happy", "_sleep", "")):
        for col, pid in enumerate(PETS):
            f = ART / "pets" / f"{pid}{suffix}.svg"
            vw, vh = size_of(f)
            s = min(box / vw, box / vh)
            w, h = vw * s, vh * s
            x = 24 + col * cell + (cell - w) / 2
            y = sh.y + row * cell + (box - h)
            sh.raw(f'<div style="position:absolute;left:{x:.1f}px;top:{y + h:.1f}px;width:{w:.1f}px;height:2px;background:#D9B8A0"></div>')
            sh.img(f, x, y, w, h)
            if row == 3:
                p = info[pid]
                eyes = "".join(f'<circle cx="{e["x"]}" cy="{e["y"]}" r="{e["r"]}" fill="none" stroke="#2D7FF9" stroke-width="2"/>' for e in p["eyes"])
                b, hd, m = p["body"], p["head"], p["mouth"]
                sh.raw(f'<svg style="position:absolute;left:{x:.1f}px;top:{y:.1f}px" width="{w:.1f}" height="{h:.1f}" viewBox="0 0 {vw} {vh}">'
                       f'<rect x="{b["x"]}" y="{b["y"]}" width="{b["w"]}" height="{b["h"]}" fill="none" stroke="#F08A24" stroke-width="3" stroke-dasharray="8 6"/>'
                       f'<circle cx="{hd["cx"]}" cy="{hd["cy"]}" r="{hd["r"]}" fill="none" stroke="#E0457B" stroke-width="3" stroke-dasharray="8 6"/>{eyes}'
                       f'<path d="M{m["x"] - 10} {m["y"]}h20M{m["x"]} {m["y"] - 10}v20" stroke="#1E9E5A" stroke-width="4"/></svg>')
        if row == 0:
            for col, pid in enumerate(PETS):
                sh.text(pid + (" (sea)" if info[pid]["sea"] else ""), 24 + col * cell + 10, sh.y - 6, 18, False)
    sh.y += 4 * cell + 10


def eggs_section(sh):
    sh.title("Eggs: whole, and cracked (top lifted to show the zigzag)")
    cell = 300
    w, h = 160, 200
    for col, pid in enumerate(PETS):
        x = 24 + col * cell + (cell - w) / 2
        sh.img(ART / "eggs" / f"{pid}.svg", x - 75, sh.y, w, h)
        sh.img(ART / "eggs" / f"{pid}_bottom.svg", x + 85, sh.y + 20, w * 0.8, h * 0.8)
        sh.img(ART / "eggs" / f"{pid}_top.svg", x + 85, sh.y - 6, w * 0.8, h * 0.8, "transform:rotate(-14deg);transform-origin:20% 50%")
    sh.y += h + 50


def homes_section(sh):
    sh.title("Homes (1080 x 1920) with their pet standing at y = 1450, 30% of the width")
    k = 0.27
    hw, hh = 1080 * k, 1920 * k
    for col, pid in enumerate(PETS):
        x = 24 + col * (hw + 12)
        sh.img(ART / "homes" / f"{pid}.svg", x, sh.y, hw, hh)
        vw, vh = size_of(ART / "pets" / f"{pid}.svg")
        pw = 1080 * 0.30 * k
        ph = vh * pw / vw
        sh.img(ART / "pets" / f"{pid}.svg", x + (hw - pw) / 2, sh.y + 1450 * k - ph, pw, ph)
        for band in (250, 1520):
            sh.raw(f'<div style="position:absolute;left:{x}px;top:{sh.y + band * k:.1f}px;width:{hw:.1f}px;height:0;border-top:1px dashed rgba(120,80,60,.5)"></div>')
    sh.y += hh + 50


def items_section(sh):
    sh.title("Items and growth wear (120 x 120)")
    names = [("items", i) for i in ITEMS] + [("wear", w) for w in WEAR]
    per_row = 10
    cell = 210
    for i, (folder, name) in enumerate(names):
        x = 24 + (i % per_row) * cell
        y = sh.y + (i // per_row) * (cell + 10)
        sh.raw(f'<div style="position:absolute;left:{x}px;top:{y}px;width:{cell - 20}px;height:{cell - 20}px;background:#FFFFFF;border-radius:18px"></div>')
        sh.img(ART / folder / f"{name}.svg", x + 23, y + 10, 144, 144)
        sh.text(name, x + 10, y + 160, 17, False)
    sh.y += ((len(names) + per_row - 1) // per_row) * (cell + 10) + 20


def story_section(sh):
    sh.title("Opening story (1080 x 1080) and the app icon")
    s = 480
    for i in range(3):
        sh.img(ART / "story" / f"story_{i + 1}.svg", 24 + i * (s + 20), sh.y, s, s)
    if ICON.exists():
        sh.img(ICON, 24 + 3 * (s + 20) + 40, sh.y + 80, 300, 300, "border-radius:66px")
    sh.y += s + 40


def check_pets():
    """Render each pet at its own size and measure the empty space round it."""
    with tempfile.TemporaryDirectory() as tmp:
        x, cells = 0, []
        for pid in PETS:
            vw, vh = size_of(ART / "pets" / f"{pid}.svg")
            cells.append((pid, x, vw, vh))
            x += vw + 20
        H = max(c[3] for c in cells)
        html = "".join(f'<img src="file://{ART / "pets" / (pid + ".svg")}" style="position:absolute;left:{x}px;top:0;width:{vw}px;height:{vh}px">'
                       for pid, x, vw, vh in cells)
        out = pathlib.Path(tmp) / "check.png"
        render_html(f'<html><body style="margin:0">{html}</body></html>', out, x, H)
        im = Image.open(out).convert("RGBA")
        print("pet      size       space left: left top right bottom (px)")
        for pid, x, vw, vh in cells:
            a = im.crop((int(x), 0, int(x + vw), int(vh))).getchannel("A").point(lambda v: 255 if v > 8 else 0)
            l, t, r, b = a.getbbox()
            print(f"{pid:8s} {int(vw):3d} x {int(vh):3d}   {l:3d} {t:3d} {int(vw) - r:3d} {int(vh) - b:3d}")


def main():
    out = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "art_preview.png").resolve()
    info = json.loads((ART / "pets" / "pets.json").read_text())
    sh = Sheet()
    pets_section(sh, info)
    eggs_section(sh)
    homes_section(sh)
    items_section(sh)
    story_section(sh)
    html = (f'<html><body style="margin:0;background:{BG};width:{SHEET_W}px;height:{sh.y}px;position:relative">'
            + "".join(sh.parts) + "</body></html>")
    out.parent.mkdir(parents=True, exist_ok=True)
    render_html(html, out, SHEET_W, sh.y)
    print(out)
    check_pets()


if __name__ == "__main__":
    main()
