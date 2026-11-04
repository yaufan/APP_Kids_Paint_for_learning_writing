"""Rough screen sketches for the design (docs/design.md): the pet's home,
writing a letter, a reward reached, and the parent's reward settings.

    python3 make_mockups.py        # writes docs/mockups/*.png (needs Node.js and Playwright)

The pet is the puppy of 畫畫小鎮 (same author); the font is jf open-huninn
when the 畫畫小鎮 checkout sits next to this one, else the system's.
"""
import pathlib
import subprocess
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
SIBLING = HERE.parents[2] / "APP_Kids_Paint" / "app" / "assets"
W, H = 390, 844

INK, SOFT, CORAL, SUN, SKY, GRASS, GRAPE, PINK = "#34413A", "#6B7A70", "#FF5E5B", "#FFC94A", "#4DA3FF", "#6BCB77", "#8C6CFF", "#FF8FB1"


def pet(size=200):
    svg = (SIBLING / "art" / "animals" / "dog.svg").read_text()
    return svg.replace('width="64" height="64"', f'width="{size}" height="{size}"', 1)


def heart(color=CORAL, size=20, empty=False):
    fill = "#F1E6E2" if empty else color
    return (f'<svg width="{size}" height="{size}" viewBox="0 0 24 24"><path d="M12 21s-8-5.2-8-11a4.5 4.5 0 0 1 8-2.8A4.5 4.5 0 0 1 20 10c0 5.8-8 11-8 11z" '
            f'fill="{fill}"/></svg>')


def star(size=22, color=SUN):
    return f'<svg width="{size}" height="{size}" viewBox="0 0 24 24"><path d="M12 2.5l2.9 6 6.6.9-4.8 4.6 1.2 6.6L12 17.4l-5.9 3.2 1.2-6.6L2.5 9.4l6.6-.9z" fill="{color}"/></svg>'


def cookie(size=22):
    return (f'<svg width="{size}" height="{size}" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10" fill="#E8B86B"/>'
            '<text x="12" y="16.5" text-anchor="middle" font-size="12" font-weight="900" fill="#8A5A22">A</text></svg>')


def gift(size=64, open_=False):
    lid = '<rect x="6" y="18" width="52" height="12" rx="3" fill="#FF8FB1"/>' if not open_ else '<rect x="8" y="6" width="52" height="12" rx="3" fill="#FF8FB1" transform="rotate(-18 34 12)"/>'
    return (f'<svg width="{size}" height="{size}" viewBox="0 0 64 64"><rect x="10" y="28" width="44" height="32" rx="4" fill="#FF5E5B"/>'
            f'{lid}<rect x="29" y="28" width="6" height="32" fill="#FFD166"/>'
            + ('' if open_ else '<rect x="29" y="18" width="6" height="12" fill="#FFD166"/><path d="M32 18c-6-10-16-6-10 0zM32 18c6-10 16-6 10 0z" fill="#FFD166"/>') + '</svg>')


def tool(label, icon, color):
    return (f'<div class="tool"><div class="tb" style="background:{color}">{icon}</div><div class="tl">{label}</div></div>')


ICONS = {
    "飼料": '<svg width="34" height="34" viewBox="0 0 34 34"><path d="M4 18h26l-3 10H7z" fill="#fff"/><circle cx="12" cy="15" r="3" fill="#C98B4B"/><circle cx="18" cy="13" r="3" fill="#C98B4B"/><circle cx="23" cy="15.5" r="3" fill="#C98B4B"/></svg>',
    "洗澡": '<svg width="34" height="34" viewBox="0 0 34 34"><circle cx="12" cy="20" r="7" fill="#fff"/><circle cx="21" cy="12" r="5" fill="#fff" opacity=".8"/><circle cx="25" cy="22" r="4" fill="#fff" opacity=".7"/></svg>',
    "梳毛": '<svg width="34" height="34" viewBox="0 0 34 34"><rect x="5" y="9" width="24" height="7" rx="3" fill="#fff"/>' + "".join(f'<rect x="{7 + i * 4}" y="15" width="2" height="10" fill="#fff"/>' for i in range(6)) + '</svg>',
    "玩球": '<svg width="34" height="34" viewBox="0 0 34 34"><circle cx="17" cy="17" r="11" fill="#fff"/><path d="M6 17h22M17 6c5 4 5 18 0 22" stroke="#FF8FB1" stroke-width="2.5" fill="none"/></svg>',
    "睡覺": '<svg width="34" height="34" viewBox="0 0 34 34"><path d="M22 6a11 11 0 1 0 7 17A9 9 0 0 1 22 6z" fill="#fff"/></svg>',
}

CSS = f"""
@font-face {{ font-family: Huninn; src: url('file://{SIBLING}/fonts/jf-openhuninn-2.1.ttf'); }}
* {{ box-sizing: border-box; margin: 0; padding: 0; }}
body {{ width: {W}px; height: {H}px; overflow: hidden; font-family: Huninn, 'WenQuanYi Zen Hei', sans-serif; color: {INK}; position: relative; }}
.abs {{ position: absolute; }}
.chip {{ display: flex; align-items: center; gap: 6px; background: #fff; border-radius: 20px; padding: 6px 12px; box-shadow: 0 3px 8px rgba(60,50,40,.12); font-size: 16px; font-weight: 700; }}
.card {{ background: #fff; border-radius: 22px; box-shadow: 0 6px 16px rgba(60,50,40,.12); }}
.tool {{ display: flex; flex-direction: column; align-items: center; gap: 4px; width: 66px; }}
.tb {{ width: 58px; height: 58px; border-radius: 20px; display: flex; align-items: center; justify-content: center; box-shadow: 0 4px 0 rgba(0,0,0,.15); }}
.tl {{ font-size: 13px; color: {SOFT}; font-weight: 700; }}
.bubble {{ background: #fff; border-radius: 18px; padding: 10px 14px; font-size: 16px; font-weight: 700; box-shadow: 0 4px 10px rgba(60,50,40,.14); }}
.big {{ border-radius: 30px; color: #fff; font-size: 26px; font-weight: 900; display: flex; align-items: center; justify-content: center; gap: 10px; }}
.bar {{ height: 10px; border-radius: 5px; background: #F0E8DC; overflow: hidden; }}
.bar i {{ display: block; height: 100%; border-radius: 5px; }}
"""


def page(body, bg):
    return f'<!doctype html><html><head><meta charset="utf-8"><style>{CSS}</style></head><body style="background:{bg}">{body}</body></html>'


def home():
    meters = "".join(
        f'<div class="chip" style="font-size:14px;padding:5px 10px">{name}<span style="display:flex">{"".join(heart(c, 16, i >= n) for i in range(3))}</span></div>'
        for name, n, c in [("肚子", 3, CORAL), ("乾淨", 2, SKY), ("開心", 3, PINK)])
    tools = "".join(tool(n, ICONS[n], c) for n, c in [("飼料", "#F2A65A"), ("洗澡", SKY), ("梳毛", GRAPE), ("玩球", PINK), ("睡覺", "#5B6BC0")])
    body = f"""
<div class="abs" style="left:0;right:0;bottom:0;height:300px;background:#F6DDB8;border-radius:50% 50% 0 0/40px 40px 0 0"></div>
<div class="abs chip" style="left:16px;top:18px">豆豆 · 寶寶
  <div class="bar" style="width:70px"><i style="width:70%;background:{GRASS}"></i></div><span style="font-size:12px;color:{SOFT}">小小孩</span></div>
<div class="abs chip" style="right:16px;top:18px">{star(20)}14 {cookie(20)}2</div>
<div class="abs" style="left:16px;top:70px;display:flex;gap:8px">{meters}</div>
<div class="abs" style="left:95px;top:250px">{pet(200)}</div>
<div class="abs bubble" style="left:30px;top:160px;width:230px;line-height:1.45">今天要寫字嗎？<br>我想吃字母餅乾！</div>
<div class="abs card" style="right:14px;top:130px;width:92px;padding:8px;text-align:center">{gift(54)}<div style="font-size:15px;font-weight:900">12／30</div><div style="font-size:12px;color:{SOFT}">週末去公園</div></div>
<div class="abs" style="left:10px;right:10px;top:520px;display:flex;justify-content:space-between">{tools}</div>
<div class="abs big" style="left:40px;right:40px;top:640px;height:88px;background:{CORAL};box-shadow:0 7px 0 #D9423F">
  <svg width="40" height="40" viewBox="0 0 24 24"><path d="M15 4l5 5-9.5 9.5H5.5v-5z" fill="#fff"/></svg>寫字</div>
<div class="abs" style="left:0;right:0;top:750px;text-align:center;font-size:16px;font-weight:700;color:{SOFT}">今天的目標：寫對 3／5 個　{star(16)}{star(16)}{star(16)}{star(16, '#E8DCCB')}{star(16, '#E8DCCB')}</div>
"""
    return page(body, "linear-gradient(#FFF5E6,#FFE9CC)")


def letter_a():
    road = 'stroke="#E6E0D6" stroke-width="54" stroke-linecap="round" stroke-linejoin="round" fill="none"'
    dash = 'stroke="#fff" stroke-width="4" stroke-dasharray="2 12" stroke-linecap="round" fill="none"'
    strokes = ["M195 70 L80 400", "M195 70 L310 400", "M128 280 L262 280"]
    paths = "".join(f'<path d="{d}" {road}/>' for d in strokes) + "".join(f'<path d="{d}" {dash}/>' for d in strokes)
    done = f'<path d="M195 70 L138 233" stroke="{CORAL}" stroke-width="34" stroke-linecap="round" fill="none"/>'
    # Which way to go next: a chevron on the road ahead, pointing down the first stroke.
    arrow = '<path d="M-12 -10 L0 8 L12 -10" stroke="#3FA052" stroke-width="7" stroke-linecap="round" stroke-linejoin="round" fill="none" transform="translate(112 322) rotate(19)"/>'
    starts = (f'<circle cx="195" cy="70" r="22" fill="{GRASS}"/><text x="195" y="78" text-anchor="middle" font-size="22" font-weight="900" fill="#fff">1</text>'
              '<circle cx="215" cy="110" r="14" fill="#fff" stroke="#BFB6A8" stroke-width="3" stroke-dasharray="4 4"/><text x="215" y="116" text-anchor="middle" font-size="15" fill="#8A8172">2</text>'
              '<circle cx="128" cy="280" r="14" fill="#fff" stroke="#BFB6A8" stroke-width="3" stroke-dasharray="4 4"/><text x="128" y="286" text-anchor="middle" font-size="15" fill="#8A8172">3</text>')
    return f'<svg width="390" height="460" viewBox="0 0 390 460">{paths}{done}{arrow}{starts}</svg>'


def writing():
    steps = "".join(
        f'<div class="chip" style="font-size:15px;{"background:" + CORAL + ";color:#fff" if s == "描" else ("color:" + GRASS if i < 2 else "color:#B8AFA2")}">{"✓ " if i < 2 else ""}{s}</div>'
        for i, s in enumerate(["看", "點", "描", "寫"]))
    body = f"""
<div class="abs chip" style="left:16px;top:18px;width:48px;height:48px;justify-content:center;font-size:22px">←</div>
<div class="abs" style="left:80px;top:24px;display:flex;gap:8px">{steps}</div>
<div class="abs card" style="left:12px;right:12px;top:90px;height:520px;overflow:hidden">
  <div class="abs" style="left:-12px;top:30px">{letter_a()}</div></div>
<div class="abs" style="left:4px;top:600px">{pet(130)}</div>
<div class="abs bubble" style="left:130px;top:630px">從綠點開始，往下畫喔！</div>
<div class="abs" style="left:0;right:0;top:760px;display:flex;justify-content:center;gap:10px">{star(34, '#E8DCCB')}{star(34, '#E8DCCB')}{star(34, '#E8DCCB')}</div>
"""
    return page(body, "#FFF8EC")


def reward():
    confetti = "".join(
        f'<div class="abs" style="left:{(i * 53) % 380}px;top:{(i * 97) % 520}px;width:10px;height:16px;border-radius:3px;background:{[CORAL, SUN, SKY, GRASS, GRAPE, PINK][i % 6]};transform:rotate({i * 37}deg)"></div>'
        for i in range(40))
    park = ('<svg width="120" height="100" viewBox="0 0 120 100"><rect x="0" y="70" width="120" height="30" rx="10" fill="#8CD27D"/>'
            '<rect x="28" y="40" width="10" height="34" fill="#9C6B3E"/><circle cx="33" cy="34" r="24" fill="#5FCB79"/>'
            '<rect x="62" y="58" width="44" height="6" rx="3" fill="#C98B4B"/><rect x="66" y="64" width="5" height="12" fill="#9C6B3E"/><rect x="97" y="64" width="5" height="12" fill="#9C6B3E"/></svg>')
    body = f"""
{confetti}
<div class="abs" style="left:0;right:0;top:70px;text-align:center;font-size:34px;font-weight:900;color:{CORAL}">達成了！</div>
<div class="abs" style="left:0;right:0;top:118px;text-align:center;font-size:18px;color:{SOFT};font-weight:700">寫對 30 個字</div>
<div class="abs card" style="left:40px;right:40px;top:170px;height:300px;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:12px">
  {gift(90, open_=True)}{park}
  <div style="font-size:22px;font-weight:900;text-align:center;line-height:1.4">爸爸媽媽說：<br>週末去公園！</div></div>
<div class="abs" style="left:110px;top:470px;transform:rotate(-8deg)">{pet(170)}</div>
<div class="abs big" style="left:40px;right:40px;top:690px;height:80px;background:{GRASS};box-shadow:0 7px 0 #3FA052;font-size:22px">拿給爸爸媽媽看</div>
"""
    return page(body, "linear-gradient(#FFF1F5,#FFE3D6)")


def parent():
    week = [3, 5, 2, 6, 4, 0, 5]
    bars = "".join(
        f'<div style="display:flex;flex-direction:column;align-items:center;gap:4px"><div style="width:22px;height:{v * 12}px;background:{SKY};border-radius:6px"></div>'
        f'<div style="font-size:12px;color:{SOFT}">{d}</div></div>' for v, d in zip(week, "一二三四五六日"))
    def reward_row(goal, prize, n, of, state, color):
        return (f'<div style="padding:12px 0;border-bottom:1px solid #EFEAE0"><div style="display:flex;justify-content:space-between;font-size:16px;font-weight:700">'
                f'<span>{goal} → {prize}</span><span style="color:{color};font-size:14px">{state}</span></div>'
                f'<div class="bar" style="margin-top:8px"><i style="width:{100 * n / of:.0f}%;background:{color}"></i></div>'
                f'<div style="font-size:13px;color:{SOFT};margin-top:4px">{n}／{of}</div></div>')
    body = f"""
<div class="abs" style="left:16px;top:20px;font-size:24px;font-weight:900">家長模式</div>
<div class="abs card" style="left:12px;right:12px;top:66px;padding:16px">
  <div style="font-size:15px;color:{SOFT};font-weight:700">這週寫對 25 個字</div>
  <div style="display:flex;align-items:flex-end;justify-content:space-between;height:96px;margin-top:10px">{bars}</div>
  <div style="font-size:14px;color:{SOFT};margin-top:10px">常寫反的字：<b style="color:{INK}">b　d　2　S</b>（7 歲以前很正常）</div></div>
<div class="abs card" style="left:12px;right:12px;top:300px;padding:6px 16px 14px">
  <div style="font-size:15px;color:{SOFT};font-weight:700;margin-top:10px">獎勵（依序達成）</div>
  {reward_row("寫對 30 個字", "週末去公園", 12, 30, "進行中", GRASS)}
  {reward_row("學會 10 個字", "吃冰淇淋", 4, 10, "下一個", SUN)}
  {reward_row("練習 7 天", "買一本故事書", 3, 7, "之後", "#B8AFA2")}
  <div style="margin-top:12px;font-size:17px;font-weight:700;color:{SKY}">＋ 新增獎勵</div></div>
<div class="abs card" style="left:12px;right:12px;top:640px;padding:14px 16px">
  <div style="font-size:15px;color:{SOFT};font-weight:700">每天的目標</div>
  <div style="display:flex;gap:8px;margin-top:10px">{"".join(f'<div class="chip" style="font-size:15px;{"background:" + CORAL + ";color:#fff" if n == 5 else ""}">{n} 個</div>' for n in (3, 5, 8, 10))}</div></div>
"""
    return page(body, "#F7F5F0")


SCREENS = {"1_寵物的家": home, "2_寫字_描": writing, "3_獎勵達成": reward, "4_家長模式_獎勵": parent}


def main():
    with tempfile.TemporaryDirectory() as tmp:
        for name, make in SCREENS.items():
            html = pathlib.Path(tmp) / f"{name}.html"
            html.write_text(make())
            subprocess.run(["node", str(HERE / "render.js"), str(html), str(HERE / f"{name}.png"), str(W), str(H)], check=True)
    print("done")


if __name__ == "__main__":
    main()
