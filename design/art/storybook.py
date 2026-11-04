"""字母寵物's picture-book drawing kit (shared by pets.py and homes.py).

The look: like gouache in a storybook, not like 畫畫小鎮's coloring pages.
- No black outlines. An outline, where there is one, is a darker shade of
  its own fill, thin to medium, and a little wobbly (hand-drawn).
- Soft fills: each shape is lighter towards the top left and a little
  darker at its edge (a radial gradient), like paint that pooled.
- Paper grain: small faint speckle dots (homes and eggs). No SVG filters,
  because flutter_svg does not draw them.

Everything is deterministic: the wobble comes from a random generator
seeded with the drawing's name, so the same script always writes the
same files.
"""
import math
import random
import zlib

INK = "#3A2A25"      # eyes: the darkest thing in a picture
DEEP = "#5A392B"     # outlines are their fill mixed towards this
CREAM = "#FFF6E6"
BLUSH = "#F39A8F"
WHITE = "#FFFDF8"


# ---------------------------------------------------------------- colors
def rgb(c):
    c = c.lstrip("#")
    return tuple(int(c[i:i + 2], 16) for i in (0, 2, 4))


def mix(a, b, t):
    """[a] moved [t] of the way towards [b]."""
    a, b = rgb(a), rgb(b)
    return "#%02X%02X%02X" % tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def dark(c, t=0.42):
    return mix(c, DEEP, t)


def light(c, t=0.35):
    return mix(c, WHITE, t)


def n(v):
    """A number, short."""
    s = f"{v:.1f}"
    if s.endswith(".0"):
        s = s[:-2]
    return "0" if s in ("-0", "-0.0") else s


# ---------------------------------------------------------------- paths
class Path:
    """A path kept as segments, so it can be written and also measured."""

    def __init__(self, start):
        self.start = start
        self.segs = []          # ("L", p) or ("C", c1, c2, p)
        self.closed = False

    @property
    def end(self):
        return self.segs[-1][-1] if self.segs else self.start

    def L(self, p):
        self.segs.append(("L", p))
        return self

    def C(self, c1, c2, p):
        self.segs.append(("C", c1, c2, p))
        return self

    def Q(self, c, p):
        p0 = self.end
        c1 = (p0[0] + 2 / 3 * (c[0] - p0[0]), p0[1] + 2 / 3 * (c[1] - p0[1]))
        c2 = (p[0] + 2 / 3 * (c[0] - p[0]), p[1] + 2 / 3 * (c[1] - p[1]))
        return self.C(c1, c2, p)

    def d(self):
        out = [f"M{n(self.start[0])} {n(self.start[1])}"]
        for s in self.segs:
            if s[0] == "L":
                out.append(f"L{n(s[1][0])} {n(s[1][1])}")
            else:
                out.append("C" + " ".join(f"{n(p[0])} {n(p[1])}" for p in s[1:]))
        return "".join(out) + ("Z" if self.closed else "")

    def points(self, steps=8):
        """Points along the path (to measure it)."""
        pts = [self.start]
        p0 = self.start
        for s in self.segs:
            if s[0] == "L":
                pts.append(s[1])
            else:
                c1, c2, p = s[1:]
                for i in range(1, steps + 1):
                    t = i / steps
                    u = 1 - t
                    pts.append((u ** 3 * p0[0] + 3 * u * u * t * c1[0] + 3 * u * t * t * c2[0] + t ** 3 * p[0],
                                u ** 3 * p0[1] + 3 * u * u * t * c1[1] + 3 * u * t * t * c2[1] + t ** 3 * p[1]))
            p0 = s[-1]
        return pts

    def moved(self, dx, dy, sx=1, sy=1):
        f = lambda p: (p[0] * sx + dx, p[1] * sy + dy)
        out = Path(f(self.start))
        out.segs = [(s[0], *map(f, s[1:])) for s in self.segs]
        out.closed = self.closed
        return out


def smooth(pts, closed=True, k=1 / 6):
    """A smooth curve through [pts] (Catmull-Rom)."""
    m = len(pts)
    path = Path(pts[0])
    for i in range(m if closed else m - 1):
        p0 = pts[i - 1] if (closed or i > 0) else pts[i]
        p1, p2 = pts[i], pts[(i + 1) % m]
        p3 = pts[(i + 2) % m] if (closed or i + 2 < m) else p2
        path.C((p1[0] + (p2[0] - p0[0]) * k, p1[1] + (p2[1] - p0[1]) * k),
               (p2[0] - (p3[0] - p1[0]) * k, p2[1] - (p3[1] - p1[1]) * k), p2)
    path.closed = closed
    return path


def _toward(a, b, r):
    dx, dy = b[0] - a[0], b[1] - a[1]
    L = math.hypot(dx, dy) or 1
    t = min(r / L, 0.45)
    return (a[0] + dx * t, a[1] + dy * t)


def rounded(pts, r, bows=None):
    """A polygon with round corners of radius [r]; [bows] bend each edge a little."""
    m = len(pts)
    A = [_toward(pts[i], pts[i - 1], r) for i in range(m)]
    B = [_toward(pts[i], pts[(i + 1) % m], r) for i in range(m)]
    path = Path(B[-1])
    for i in range(m):
        a, b = B[i - 1], A[i]
        bow = bows[i] if bows else 0
        if bow:
            dx, dy = b[0] - a[0], b[1] - a[1]
            L = math.hypot(dx, dy) or 1
            path.Q(((a[0] + b[0]) / 2 - dy / L * bow, (a[1] + b[1]) / 2 + dx / L * bow), b)
        else:
            path.L(b)
        path.Q(pts[i], B[i])
    path.closed = True
    return path


def mirror_pts(pts, axis):
    return [(2 * axis - x, y) for x, y in pts]


# ---------------------------------------------------------------- a drawing
class Doc:
    """One SVG drawing: its parts, its gradients and clips, and its size.

    [name] seeds the wobble and prefixes the ids, so a drawing is the same
    every time and its ids never clash with another drawing's.
    """

    def __init__(self, name, lw=3.5):
        self.name = name
        self.rng = random.Random(zlib.crc32(name.encode()))
        self.lw = lw
        self.defs = []
        self._grads = {}
        self._count = 0
        self.box = [math.inf, math.inf, -math.inf, -math.inf]
        self.meta = {}

    # -- bookkeeping
    def uid(self, kind):
        self._count += 1
        return f"{self.name}-{kind}{self._count}"

    def track(self, pts, pad=0.0):
        b = self.box
        for x, y in pts:
            b[0], b[1] = min(b[0], x - pad), min(b[1], y - pad)
            b[2], b[3] = max(b[2], x + pad), max(b[3], y + pad)

    def grad(self, color, style="soft"):
        """A soft paint fill: lighter top left, a little darker at the edge."""
        key = (color, style)
        if key not in self._grads:
            gid = self.uid("g")
            if style == "soft":
                self.defs.append(
                    f'<radialGradient id="{gid}" cx="0.36" cy="0.3" r="0.78">'
                    f'<stop offset="0" stop-color="{light(color, 0.26)}"/>'
                    f'<stop offset="0.55" stop-color="{color}"/>'
                    f'<stop offset="1" stop-color="{dark(color, 0.1)}"/></radialGradient>')
            elif style == "flat":   # very gentle, for big background areas
                self.defs.append(
                    f'<radialGradient id="{gid}" cx="0.4" cy="0.3" r="0.9">'
                    f'<stop offset="0" stop-color="{light(color, 0.16)}"/>'
                    f'<stop offset="1" stop-color="{dark(color, 0.05)}"/></radialGradient>')
            elif style[0] == "at":  # ("at", cx, cy, r): soft, placed in the drawing's own units
                _, cx, cy, r = style
                self.defs.append(
                    f'<radialGradient id="{gid}" gradientUnits="userSpaceOnUse" cx="{n(cx)}" cy="{n(cy)}" r="{n(r)}">'
                    f'<stop offset="0" stop-color="{light(color, 0.3)}"/>'
                    f'<stop offset="0.55" stop-color="{color}"/>'
                    f'<stop offset="1" stop-color="{dark(color, 0.1)}"/></radialGradient>')
            else:                   # ("down", top color): a vertical wash
                top = style[1]
                self.defs.append(
                    f'<linearGradient id="{gid}" x1="0" y1="0" x2="0" y2="1">'
                    f'<stop offset="0" stop-color="{top}"/><stop offset="1" stop-color="{color}"/></linearGradient>')
            self._grads[key] = gid
        return f"url(#{self._grads[key]})"

    def clip(self, path):
        cid = self.uid("c")
        self.defs.append(f'<clipPath id="{cid}"><path d="{path.d()}"/></clipPath>')
        return cid

    # -- wobbly shapes
    def oval(self, cx, cy, rx, ry, rot=0, wob=1.0, m=None):
        """A hand-drawn ellipse: never quite round."""
        m = m or max(14, min(40, int((rx + ry) / 5)))
        R = self.rng
        waves = [(k, R.uniform(0, 2 * math.pi), a) for k, a in ((2, 0.014), (3, 0.012), (5, 0.007), (7, 0.005))]
        cr, sr = math.cos(math.radians(rot)), math.sin(math.radians(rot))
        pts = []
        for i in range(m):
            a = 2 * math.pi * i / m
            f = 1 + wob * sum(amp * math.sin(k * a + ph) for k, ph, amp in waves)
            x, y = rx * math.cos(a) * f, ry * math.sin(a) * f
            pts.append((cx + x * cr - y * sr, cy + x * sr + y * cr))
        return smooth(pts)

    def jit(self, pts, j=1.0):
        R = self.rng
        return [(x + R.uniform(-j, j), y + R.uniform(-j, j)) for x, y in pts]

    def blob(self, pts, j=1.0):
        """A smooth closed shape through (slightly moved) points."""
        return smooth(self.jit(pts, j))

    def poly(self, pts, r=6, j=0.8, bow=1.2):
        """A soft-cornered shape with slightly bowed hand-drawn edges."""
        R = self.rng
        return rounded(self.jit(pts, j), r, [R.uniform(-bow, bow) for _ in pts])

    def curve(self, pts, j=0.6):
        return smooth(self.jit(pts, j), closed=False)

    # -- paint
    def fill(self, path, color, line=True, lw=None, grad="soft", opacity=None, edge=None):
        """[path] painted [color]; outlined in a darker shade of it."""
        lw = self.lw if lw is None else lw
        paint = self.grad(color, grad) if grad else color
        attrs = f'fill="{paint}"'
        if line and lw > 0:
            attrs += f' stroke="{edge or dark(color)}" stroke-width="{n(lw)}" stroke-linejoin="round"'
        if opacity is not None:
            attrs += f' opacity="{opacity:.2f}"'
        self.track(path.points(), lw / 2 if line else 0)
        return f'<path d="{path.d()}" {attrs}/>'

    def stroke(self, path, color, w, opacity=None):
        """An open line (a smile, a fold, a whisker)."""
        o = f' opacity="{opacity:.2f}"' if opacity is not None else ""
        self.track(path.points(), w / 2)
        return (f'<path d="{path.d()}" fill="none" stroke="{color}" stroke-width="{n(w)}" '
                f'stroke-linecap="round" stroke-linejoin="round"{o}/>')

    def tube(self, path, w, color, lw=None):
        """A thick round band along [path] (a tail, an arm), outlined."""
        lw = self.lw if lw is None else lw
        self.track(path.points(), w / 2 + lw)
        d = path.d()
        return (f'<path d="{d}" fill="none" stroke="{dark(color)}" stroke-width="{n(w + 2 * lw)}" stroke-linecap="round" stroke-linejoin="round"/>'
                f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{n(w)}" stroke-linecap="round" stroke-linejoin="round"/>')

    def dot(self, x, y, r, color, opacity=None):
        o = f' opacity="{opacity:.2f}"' if opacity is not None else ""
        self.track([(x, y)], r)
        return f'<circle cx="{n(x)}" cy="{n(y)}" r="{n(r)}" fill="{color}"{o}/>'

    def clipped(self, area, make):
        """What [make]() draws, only inside [area] (a Path). It does not count
        towards the drawing's size, since the area already does."""
        box = self.box[:]
        parts = make()
        self.box = box
        return f'<g clip-path="url(#{self.clip(area)})">{"".join(parts)}</g>'

    def speckle(self, x0, y0, x1, y1, count, colors, rmin=0.6, rmax=1.6, opacity=0.12):
        """Paper grain: faint little dots scattered over a box."""
        R = self.rng
        groups = {c: [] for c in colors}
        for _ in range(count):
            c = colors[R.randrange(len(colors))]
            groups[c].append(f'<circle cx="{n(R.uniform(x0, x1))}" cy="{n(R.uniform(y0, y1))}" r="{n(R.uniform(rmin, rmax))}"/>')
        return "".join(f'<g fill="{c}" opacity="{opacity:.2f}">{"".join(v)}</g>' for c, v in groups.items() if v)

    # -- faces
    eye_mode = "open"   # "open", "happy" (^ ^) or "sleep" (closed, curving down)

    def eye(self, x, y, r=12):
        """A shiny dot eye (or, for the variants, a happy or a sleeping one)."""
        self.meta.setdefault("eyes", []).append({"x": x, "y": y, "r": r})
        self.track([(x, y)], r * 1.3)
        if self.eye_mode == "happy":
            w = max(3.0, r * 0.42)
            return (f'<path d="M{n(x - r * 1.0)} {n(y + r * 0.42)}Q{n(x)} {n(y - r * 1.05)} {n(x + r * 1.0)} {n(y + r * 0.42)}" '
                    f'fill="none" stroke="{INK}" stroke-width="{n(w)}" stroke-linecap="round"/>')
        if self.eye_mode == "sleep":
            w = max(3.0, r * 0.38)
            return (f'<path d="M{n(x - r * 1.0)} {n(y - r * 0.05)}Q{n(x)} {n(y + r * 1.0)} {n(x + r * 1.0)} {n(y - r * 0.05)}" '
                    f'fill="none" stroke="{INK}" stroke-width="{n(w)}" stroke-linecap="round"/>')
        return (f'<circle cx="{n(x)}" cy="{n(y)}" r="{n(r)}" fill="{INK}"/>'
                f'<circle cx="{n(x - r * 0.3)}" cy="{n(y - r * 0.36)}" r="{n(r * 0.34)}" fill="#FFFFFF"/>')

    def eyes(self, *spots):
        """All the eyes in one <g id="eyes">, so the app can hide them and
        draw its own pupils that follow a finger; spots are (x, y, r)."""
        return '<g id="eyes">' + "".join(self.eye(*s) for s in spots) + "</g>"

    def cheek(self, x, y, rx=15, ry=9.5):
        return (f'<ellipse cx="{n(x)}" cy="{n(y)}" rx="{n(rx)}" ry="{n(ry)}" fill="{BLUSH}" opacity="0.55"/>')

    # -- writing it out
    def svg(self, parts, box=None, bottom_flush=True, margin=5, background=None):
        """The SVG, cropped to what was drawn (or to [box] = x0, y0, x1, y1)."""
        x0, y0, x1, y1 = box or self.box
        if not box:
            x0, y0, x1 = x0 - margin, y0 - margin, x1 + margin
            if not bottom_flush:
                y1 += margin
        w, h = math.ceil(x1 - x0), math.ceil(y1 - y0)
        # keep it centred after rounding the width up; the bottom stays exactly at the lowest point
        dx = -x0 + (w - (x1 - x0)) / 2
        dy = -y0 + (h - (y1 - y0))
        self.offset = (dx, dy)
        self.size = (w, h)
        defs = f'<defs>{"".join(self.defs)}</defs>' if self.defs else ""
        bg = f'<rect width="{w}" height="{h}" fill="{background}"/>' if background else ""
        body = "".join(parts)
        if abs(dx) > 1e-6 or abs(dy) > 1e-6:
            body = f'<g transform="translate({n(dx)} {n(dy)})">{body}</g>'
        return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">'
                f'{defs}{bg}{body}</svg>\n')
