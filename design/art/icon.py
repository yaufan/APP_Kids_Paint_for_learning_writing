"""字母寵物's app icon: the baby puppy (pets.py) hugging a wooden letter
block with a big A, on a soft warm background with a little paper grain.

    python3 icon.py preview out.png   # a sheet: round / squircle / square masks at 48, 96 and 192 px
    python3 icon.py export            # writes the Android and iOS icons into app/

export writes
- Android, full square art: app/android/app/src/main/res/mipmap-{mdpi..xxxhdpi}/ic_launcher.png (48..192 px).
- Android adaptive icon (API 26+): mipmap-anydpi-v26/ic_launcher.xml, with
  drawable-{mdpi..xxxhdpi}/ic_launcher_foreground.png and ic_launcher_background.png
  (108 dp canvas; the puppy and block stay inside the central 66 dp circle).
- iOS: every PNG listed in app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json,
  at its size, opaque (no alpha).
Needs Node.js with Playwright (the SVGs are drawn by Chromium) and Pillow.
"""
import json
import math
import pathlib
import subprocess
import sys
import tempfile

from PIL import Image, ImageDraw

import pets
from storybook import Doc, Path, dark, light

ROOT = pathlib.Path(__file__).resolve().parents[2]
APP = ROOT / "app"
RES = APP / "android" / "app" / "src" / "main" / "res"
IOS = APP / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
RENDER = pathlib.Path("/home/user/APP_Kids_Paint/docs/design/v6/render_alpha.js")
if not RENDER.exists():   # the sibling checkout of 畫畫小鎮, or a copy next to this file
    RENDER = pathlib.Path(__file__).resolve().parent / "render_alpha.js"

C = 1024                      # the master canvas
DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
WOOD, LETTER = "#EFC58C", "#E8806E"


# ---------------------------------------------------------------- the drawing
def hug_block(d):
    """A wooden letter block in the puppy's lap, its feet in front and its paws round it."""
    fur = pets.PUPPY_FUR
    P = [d.fill(d.poly([(140, 296), (156, 280), (278, 280), (262, 296)], r=6, j=0.6, bow=1), light(WOOD, 0.3)),
         d.fill(d.poly([(262, 296), (278, 280), (278, 402), (262, 418)], r=6, j=0.6, bow=1), dark(WOOD, 0.16))]
    front = d.poly([(140, 296), (262, 296), (262, 418), (140, 418)], r=10, j=0.8, bow=1.2)
    P.append(d.fill(front, WOOD))
    P.append(d.stroke(d.poly([(152, 308), (250, 308), (250, 406), (152, 406)], r=8, j=0.6, bow=1), dark(WOOD, 0.22), 3))
    P.append(d.tube(Path((168, 394)).L((201, 318)).L((234, 394)), 15, LETTER, lw=2.6))
    P.append(d.tube(Path((183, 366)).L((219, 366)), 13, LETTER, lw=2.6))
    for x in (154, 248):
        P.append(d.fill(d.oval(x, 414, 31, 19), fur))
        P += pets.toes(d, x, 420, fur, 31)
    P.append(d.fill(d.oval(142, 336, 18, 24, rot=12), fur))
    P.append(d.fill(d.oval(272, 334, 17, 23, rot=-12), fur))
    return P


def foreground_parts():
    d = Doc("icon-puppy")
    parts = pets.puppy(d, hug=hug_block)
    return d, parts


def foreground_svg(px, radius):
    """The puppy and block, see-through around them, centred, scaled so the
    drawing reaches [radius] (in 1024ths of the canvas) from the centre."""
    d, parts = foreground_parts()
    x0, y0, x1, y1 = d.box
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    s = radius / math.hypot((x1 - x0) / 2, (y1 - y0) / 2)
    s *= FIT.get(radius, 1.0)
    defs = f'<defs>{"".join(d.defs)}</defs>'
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {C} {C}" width="{px}" height="{px}">{defs}'
            f'<g transform="translate({C / 2} {C / 2 + 6}) scale({s:.4f}) translate({-cx:.1f} {-cy:.1f})">{"".join(parts)}</g></svg>')


def background_svg(px):
    """A soft warm page with a glow behind the puppy and a little grain."""
    d = Doc("icon-bg")
    gid = d.uid("bg")
    d.defs.append(f'<radialGradient id="{gid}" cx="0.5" cy="0.44" r="0.72"><stop offset="0" stop-color="#FFF0C9"/>'
                  f'<stop offset="0.55" stop-color="#FAD58F"/><stop offset="1" stop-color="#F3B47C"/></radialGradient>')
    P = [f'<rect width="{C}" height="{C}" fill="url(#{gid})"/>']
    pts = []
    for i in range(36):
        a = 2 * math.pi * i / 36
        rr = 360 * (1.0 if i % 2 == 0 else 0.96)
        pts.append((C / 2 + rr * math.cos(a), C / 2 + rr * math.sin(a)))
    P.append(d.fill(d.blob(pts, 2), "#FFF6DE", line=False, grad="flat", opacity=0.5))
    for x, y, r in ((190, 230, 16), (842, 260, 12), (820, 790, 15), (205, 800, 11)):
        p = Path((x, y - r)).Q((x, y), (x + r, y)).Q((x, y), (x, y + r)).Q((x, y), (x - r, y)).Q((x, y), (x, y - r))
        p.closed = True
        P.append(f'<path d="{p.d()}" fill="#FFFFFF" opacity="0.9"/>')
    P.append(d.speckle(0, 0, C, C, 700, ["#7A5640"], 1.0, 2.6, 0.07))
    P.append(d.speckle(0, 0, C, C, 350, ["#FFFFFF"], 1.0, 2.4, 0.3))
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {C} {C}" width="{px}" height="{px}">'
            f'<defs>{"".join(d.defs)}</defs>{"".join(P)}</svg>')


# How far the drawing may reach from the centre, in 1024ths of the canvas.
FULL_R = 0.43 * C                 # full square art (legacy Android, iOS)
SAFE_R = 33 / 108 * C * 0.97      # adaptive foreground: the central 66 dp circle of 108 dp
FIT = {}                          # filled in by fit(): corrects the box estimate to the real drawing


# ---------------------------------------------------------------- rendering
def render(svg_text, px):
    with tempfile.TemporaryDirectory() as tmp:
        src, out = pathlib.Path(tmp) / "in.svg", pathlib.Path(tmp) / "out.png"
        src.write_text(svg_text)
        subprocess.run(["node", str(RENDER), str(src), str(out), str(px), str(px)], check=True)
        return Image.open(out).convert("RGBA").copy()


def reach(img):
    """How far the drawing's pixels reach from the centre (in pixels)."""
    a = img.getchannel("A")
    w, h = img.size
    px = a.load()
    best = 0.0
    for y in range(0, h, 2):
        for x in range(0, w, 2):
            if px[x, y] > 24:
                best = max(best, math.hypot(x + 0.5 - w / 2, y + 0.5 - h / 2))
    return best


def fit():
    """Scale the foreground so its real outline (not its box) just reaches each target."""
    for radius in (FULL_R, SAFE_R):
        FIT[radius] = 1.0
        got = reach(render(foreground_svg(512, radius), 512)) * C / 512
        FIT[radius] = radius / got


def full_art():
    """The full square icon (opaque), 1024 px."""
    bg = render(background_svg(C), C)
    fg = render(foreground_svg(C, FULL_R), C)
    return Image.alpha_composite(bg, fg).convert("RGB")


def adaptive_layers():
    """The adaptive icon's two 108 dp layers, 1024 px masters."""
    return render(background_svg(C), C).convert("RGB"), render(foreground_svg(C, SAFE_R), C)


def resized(img, px):
    return img.resize((px, px), Image.LANCZOS)


# ---------------------------------------------------------------- masks and preview
def mask(kind, px):
    m = Image.new("L", (px * 4, px * 4), 0)
    dr = ImageDraw.Draw(m)
    s = px * 4
    if kind == "round":
        dr.ellipse((0, 0, s - 1, s - 1), fill=255)
    elif kind == "squircle":
        pts = []
        for i in range(720):
            t = 2 * math.pi * i / 720
            c, si = math.cos(t), math.sin(t)
            pts.append((s / 2 + s / 2 * math.copysign(abs(c) ** (2 / 5), c), s / 2 + s / 2 * math.copysign(abs(si) ** (2 / 5), si)))
        dr.polygon(pts, fill=255)
    else:
        dr.rounded_rectangle((0, 0, s - 1, s - 1), radius=s * 0.08, fill=255)
    return m.resize((px, px), Image.LANCZOS)


def preview(out):
    fit()
    full = full_art()
    bg, fg = adaptive_layers()
    adaptive = Image.alpha_composite(bg.convert("RGBA"), fg).convert("RGB")
    # a launcher shows the middle 72 dp of the 108 dp adaptive canvas
    k = C * 18 / 108
    adaptive_view = adaptive.crop((round(k), round(k), round(C - k), round(C - k)))
    sizes = (48, 96, 192)
    rows = [("round", adaptive_view), ("squircle", adaptive_view), ("square", full)]
    pad = 24
    W = pad + sum(s + pad for s in sizes) + 420 + pad
    H = pad + len(rows) * (192 + pad) + 120
    sheet = Image.new("RGB", (W, H), "#E9E4DE")
    dark_band = Image.new("RGB", (W, 120), "#2F2B33")
    sheet.paste(dark_band, (0, H - 120))
    for r, (kind, art) in enumerate(rows):
        x = pad
        y = pad + r * (192 + pad)
        for s in sizes:
            icon = resized(art, s)
            sheet.paste(icon, (x, y + 192 - s), mask(kind, s))
            x += s + pad
    big = resized(full, 420)
    sheet.paste(big, (W - pad - 420, pad), mask("squircle", 420))
    x = pad
    for kind, art in rows:
        sheet.paste(resized(art, 72), (x, H - 96), mask(kind, 72))
        x += 72 + pad
    sheet.save(out)
    print(out)


# ---------------------------------------------------------------- export
ADAPTIVE_XML = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
</adaptive-icon>
"""


def export():
    fit()
    full = full_art()
    bg, fg = adaptive_layers()
    written = []
    for name, k in DENSITIES.items():
        mip = RES / f"mipmap-{name}"
        mip.mkdir(parents=True, exist_ok=True)
        resized(full, round(48 * k)).save(mip / "ic_launcher.png")
        draw = RES / f"drawable-{name}"
        draw.mkdir(parents=True, exist_ok=True)
        resized(fg, round(108 * k)).save(draw / "ic_launcher_foreground.png")
        resized(bg, round(108 * k)).save(draw / "ic_launcher_background.png")
        written += [mip / "ic_launcher.png", draw / "ic_launcher_foreground.png", draw / "ic_launcher_background.png"]
    anydpi = RES / "mipmap-anydpi-v26"
    anydpi.mkdir(parents=True, exist_ok=True)
    (anydpi / "ic_launcher.xml").write_text(ADAPTIVE_XML)
    written.append(anydpi / "ic_launcher.xml")
    contents = json.loads((IOS / "Contents.json").read_text())
    for image in contents["images"]:
        if not image.get("filename"):
            continue
        size = float(image["size"].split("x")[0]) * float(image["scale"].rstrip("x"))
        resized(full, round(size)).convert("RGB").save(IOS / image["filename"])
        written.append(IOS / image["filename"])
    manifest = (APP / "android" / "app" / "src" / "main" / "AndroidManifest.xml").read_text()
    if 'android:icon="@mipmap/ic_launcher"' not in manifest:
        print("note: AndroidManifest.xml's android:icon is not @mipmap/ic_launcher")
    for p in written:
        print(p.relative_to(ROOT))


if __name__ == "__main__":
    if len(sys.argv) >= 2 and sys.argv[1] == "export":
        export()
    elif len(sys.argv) >= 3 and sys.argv[1] == "preview":
        preview(sys.argv[2])
    else:
        print(__doc__)
