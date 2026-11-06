"""Sketches for the easier fourth step (docs/design.md, proposal 2026-11-06).

    python3 make_writing_ideas.py

5_一筆一筆寫.png: the child writes one stroke at a time; each stroke is checked
the moment the finger lifts. 6_提示慢慢變淡.png: the faint letter fades as the
child gets better. Glyph data from app/assets/glyphs.json; the pet from
app/assets/art/pets/; the font is jf open-huninn.
"""
import base64
import json
import pathlib
import subprocess

HERE = pathlib.Path(__file__).resolve().parent
APP = HERE.parent.parent / "app"
GLYPHS = {g["id"]: g for g in json.loads((APP / "assets/glyphs.json").read_text())["glyphs"]}

PAPER, INK, SOFT = "#FBF3E4", "#5B4636", "#8A7462"
ROAD, ROADLINE, GO, GOLINE, CORAL, MUSTARD = "#E6D9C3", "#D2C1A3", "#7FB069", "#4E7F3E", "#E98B7A", "#EBC874"


def pet_img(name, w):
    data = base64.b64encode((APP / f"assets/art/pets/{name}.svg").read_bytes()).decode()
    return f'<img src="data:image/svg+xml;base64,{data}" style="width:{w}px">'


def path(points, ox, oy, k):
    return "M" + " L".join(f"{ox + x * k:.1f} {oy + y * k:.1f}" for x, y in points)


def letter(gid, box, k, *, faint=0.0, dashed=False, done=(), current=None, wrong=None, demo=False, dot_tap=None):
    """One glyph drawn in a box: faint guide, finished strokes, the green dot for
    the current stroke, a wrong stroke fading away, a demonstration."""
    g = GLYPHS[gid]
    w, h = box
    ox, oy = (w - g["width"] * k) / 2, (h - 100 * k) / 2
    out = [f'<svg width="{w}" height="{h}" viewBox="0 0 {w} {h}" xmlns="http://www.w3.org/2000/svg">']
    # Guide lines like an exercise book.
    for y in (oy, oy + 100 * k):
        out.append(f'<line x1="20" x2="{w - 20}" y1="{y}" y2="{y}" stroke="{ROADLINE}" stroke-width="2" stroke-dasharray="8 7"/>')
    for i, s in enumerate(g["strokes"]):
        d = path(s, ox, oy, k)
        if faint:
            out.append(f'<path d="{d}" fill="none" stroke="#C9B89C" stroke-opacity="{faint}" stroke-width="{18 * k}" stroke-linecap="round" stroke-linejoin="round"/>')
        if dashed:
            out.append(f'<path d="{d}" fill="none" stroke="#B9A88C" stroke-width="{3.2 * k}" stroke-dasharray="{3 * k} {7 * k}" stroke-linecap="round"/>')
        if i in done:
            out.append(f'<path d="{d}" fill="none" stroke="{CORAL}" stroke-width="{10 * k}" stroke-linecap="round" stroke-linejoin="round"/>')
    if wrong is not None:
        out.append(f'<path d="{path(wrong, ox, oy, k)}" fill="none" stroke="{CORAL}" stroke-opacity="0.28" stroke-width="{10 * k}" stroke-linecap="round" stroke-linejoin="round"/>')
    if current is not None:
        s = g["strokes"][current]
        if demo:
            half = s[: max(2, len(s) * 2 // 3)]
            out.append(f'<path d="{path(s, ox, oy, k)}" fill="none" stroke="{GO}" stroke-opacity="0.3" stroke-width="{18 * k}" stroke-linecap="round"/>')
            out.append(f'<path d="{path(half, ox, oy, k)}" fill="none" stroke="{GOLINE}" stroke-width="{7 * k}" stroke-linecap="round"/>')
            x, y = half[-1]
            out.append(f'<circle cx="{ox + x * k}" cy="{oy + y * k}" r="{7 * k}" fill="{GOLINE}"/>')
        x0, y0 = s[0]
        x1, y1 = s[min(len(s) - 1, 8)]
        cx, cy = ox + x0 * k, oy + y0 * k
        out.append(f'<circle cx="{cx}" cy="{cy}" r="{13 * k}" fill="{GO}" fill-opacity="0.25"/>')
        out.append(f'<circle cx="{cx}" cy="{cy}" r="{9.5 * k}" fill="{GO}" stroke="{GOLINE}" stroke-width="2"/>')
        # A little arrow showing which way.
        dx, dy = x1 - x0, y1 - y0
        n = max((dx * dx + dy * dy) ** 0.5, 1)
        dx, dy = dx / n, dy / n
        nx, ny = -dy, dx
        if nx > 0:
            nx, ny = -nx, -ny
        ax, ay = cx + nx * 22 * k + dx * 4 * k, cy + ny * 22 * k + dy * 4 * k
        bx, by = ax + dx * 20 * k, ay + dy * 20 * k
        out.append(f'<path d="M{ax} {ay} L{bx} {by} M{bx - dx * 7 * k + nx * 6 * k} {by - dy * 7 * k + ny * 6 * k} L{bx} {by} L{bx - dx * 7 * k - nx * 6 * k} {by - dy * 7 * k - ny * 6 * k}" '
                   f'fill="none" stroke="{GOLINE}" stroke-width="{4 * k}" stroke-linecap="round" stroke-linejoin="round" opacity="0.8"/>')
    if dot_tap is not None:
        x, y = dot_tap
        out.append(f'<circle cx="{ox + x * k}" cy="{oy + y * k}" r="{5 * k}" fill="{CORAL}" fill-opacity="0.35"/>')
        out.append(f'<text x="{ox + x * k}" y="{oy + y * k + 34}" text-anchor="middle" font-size="16" fill="{SOFT}" font-weight="700">點一下</text>')
        out.append(f'<text x="{ox + x * k}" y="{oy + y * k + 54}" text-anchor="middle" font-size="16" fill="{SOFT}" font-weight="700">不算</text>')
    out.append("</svg>")
    return "".join(out)


CSS = f"""
@font-face {{ font-family: Huninn; src: url('file://{APP}/assets/fonts/jf-openhuninn-2.1.ttf'); }}
* {{ box-sizing: border-box; margin: 0; }}
body {{ font-family: Huninn, sans-serif; color: {INK}; background: #EFE6D6; padding: 24px; }}
h1 {{ font-size: 30px; margin: 0 0 6px 8px; }}
.sub {{ font-size: 18px; color: {SOFT}; margin: 0 0 18px 8px; }}
.row {{ display: flex; gap: 20px; }}
.panel {{ width: 300px; background: {PAPER}; border-radius: 26px; padding: 16px; box-shadow: 0 6px 16px rgba(80,60,40,.15); position: relative; }}
.n {{ position: absolute; left: 14px; top: 12px; width: 34px; height: 34px; border-radius: 17px; background: {MUSTARD}; font-weight: 900; font-size: 20px; display: flex; align-items: center; justify-content: center; }}
.cap {{ font-size: 18px; font-weight: 700; line-height: 1.45; margin-top: 10px; min-height: 78px; }}
.bubble {{ position: absolute; background: #fff; border-radius: 16px; padding: 8px 12px; font-size: 16px; font-weight: 700; box-shadow: 0 3px 8px rgba(80,60,40,.15); }}
.pet {{ position: absolute; }}
.ok {{ color: {GOLINE}; }}
"""


def page(body, w, h, name):
    html = HERE / f"_{name}.html"
    html.write_text(f"<!doctype html><meta charset=utf-8><style>{CSS}</style><body>{body}</body>")
    subprocess.run(["node", str(HERE / "render.js"), str(html), str(HERE / f"{name}.png"), str(w), str(h)], check=True)
    html.unlink()


def stroke_by_stroke():
    k = 2.4
    e = GLYPHS["E"]
    s0 = e["strokes"][0]
    wrong = [(x + 30, y) for x, y in reversed(e["strokes"][1])][:]  # across the wrong way, too low
    wrong = [(x, y + 28) for x, y in reversed(e["strokes"][1])]
    panels = [
        ("1", letter("E", (268, 300), k, faint=0.45, current=0),
         "只出現<b>第 1 筆</b>的綠點和小箭頭。<br>寫一筆、手指一放開就檢查這一筆。", ""),
        ("2", letter("E", (268, 300), k, faint=0.45, done=(0,), current=1),
         "<span class=ok>寫對了</span>：這一筆變成彩色、「叮」一聲，<br>下一筆的綠點才出現。", ""),
        ("3", letter("E", (268, 300), k, faint=0.45, done=(0,), current=1, wrong=wrong, demo=True),
         "寫錯了：<b>只有這一筆</b>慢慢消失，<br>寵物示範一次，再寫這一筆。<br>寫好的不用重來。", "從綠點往右喔！"),
        ("4", letter("E", (268, 300), k, faint=0.45, done=(0, 1), current=2, dot_tap=(-16, 36)),
         "不小心點到、小點點不算。<br>同一筆錯 3 次，就出現小路<br>讓他描，不會卡住。", ""),
    ]
    cells = []
    for n, svg, cap, bubble in panels:
        b = f'<div class="bubble" style="right:16px;top:244px">{bubble}</div>' if bubble else ""
        cells.append(f'<div class="panel"><div class="n">{n}</div>{svg}{b}<div class="pet" style="left:8px;top:262px">{pet_img("puppy_happy" if n == "2" else "puppy", 52)}</div><div class="cap">{cap}</div></div>')
    body = f"<h1>建議：第 4 關改成「一筆一筆寫」</h1><div class=sub>不用一次寫完整個字才判斷；每一筆馬上知道對不對，寫錯只重寫那一筆。</div><div class=row>{''.join(cells)}</div>"
    page(body, 1328, 590, "5_一筆一筆寫")


def fading():
    k = 2.6
    levels = [
        ("剛開始", dict(faint=0.55), "淡淡的字在下面，<br>照著寫"),
        ("寫對 2 次後", dict(dashed=True), "只剩虛線"),
        ("寫對 4 次後", dict(), "只剩綠點，<br>真正自己寫"),
    ]
    cells = []
    for i, (title, kw, cap) in enumerate(levels):
        svg = letter("A", (268, 300), k, current=0, **kw)
        cells.append(f'<div class="panel"><div class="n">{i + 1}</div><div style="font-size:20px;font-weight:900;text-align:center;margin-bottom:4px">{title}</div>{svg}<div class="cap" style="text-align:center">{cap}</div></div>')
    body = (f"<h1>建議：提示慢慢變淡</h1><div class=sub>每個字自己記得寫到哪一級；寫錯幾次就自動退回上一級，小朋友不會卡住。</div>"
            f"<div class=row>{''.join(cells)}</div>")
    page(body, 1010, 600, "6_提示慢慢變淡")


if __name__ == "__main__":
    stroke_by_stroke()
    fading()
