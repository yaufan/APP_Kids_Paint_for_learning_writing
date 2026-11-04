import 'dart:math' as math;
import 'dart:ui';

/// How exact the writing has to be (a parent's choice): lenient for 3 and
/// 4 year olds (strokes in any order), normal (in order), strict (5 and up).
enum Strictness {
  lenient(start: 24, path: 17),
  normal(start: 18, path: 13),
  strict(start: 13, path: 9);

  const Strictness({required this.start, required this.path});

  /// How far (in glyph units; a character is 100 high) a stroke may begin
  /// from its start dot, and stray from its line on average.
  final double start;
  final double path;
}

/// [points] spread evenly along their length, [n] of them.
List<Offset> resample(List<Offset> points, int n) {
  if (points.isEmpty) return const [];
  if (points.length == 1) return List.filled(n, points.first);
  final total = pathLength(points);
  if (total == 0) return List.filled(n, points.first);
  final step = total / (n - 1);
  final out = <Offset>[points.first];
  var travelled = 0.0, i = 1;
  var prev = points.first;
  while (out.length < n - 1 && i < points.length) {
    final seg = (points[i] - prev).distance;
    if (travelled + seg >= step) {
      final t = (step - travelled) / seg;
      prev = Offset.lerp(prev, points[i], t)!;
      out.add(prev);
      travelled = 0;
    } else {
      travelled += seg;
      prev = points[i];
      i++;
    }
  }
  while (out.length < n) {
    out.add(points.last);
  }
  return out;
}

double pathLength(List<Offset> points) {
  var total = 0.0;
  for (var i = 1; i < points.length; i++) {
    total += (points[i] - points[i - 1]).distance;
  }
  return total;
}

/// The shortest distance from [p] to the polyline [line].
double distanceToLine(Offset p, List<Offset> line) {
  if (line.length == 1) return (p - line.first).distance;
  var best = double.infinity;
  for (var i = 1; i < line.length; i++) {
    best = math.min(best, _toSegment(p, line[i - 1], line[i]));
  }
  return best;
}

double _toSegment(Offset p, Offset a, Offset b) {
  final ab = b - a;
  final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
  if (len2 == 0) return (p - a).distance;
  final t = (((p.dx - a.dx) * ab.dx + (p.dy - a.dy) * ab.dy) / len2).clamp(0.0, 1.0);
  return (p - (a + ab * t)).distance;
}

/// Twice the area a closed-ish stroke goes round: its sign says which way
/// round (negative is counterclockwise on the screen, y growing down).
double _turning(List<Offset> s) {
  var a = 0.0;
  for (var i = 0; i < s.length; i++) {
    final p = s[i], q = s[(i + 1) % s.length];
    a += p.dx * q.dy - q.dx * p.dy;
  }
  return a;
}

bool _closed(List<Offset> s) => s.length > 2 && (s.first - s.last).distance < 0.2 * pathLength(s);

/// How one stroke compares with its template: started at the right dot,
/// went the right way, stayed near the line ([error], the average distance).
class StrokeCheck {
  const StrokeCheck({required this.startOk, required this.directionOk, required this.error, required this.covered});

  final bool startOk;
  final bool directionOk;
  final double error;

  /// How much of the template the stroke reached (0..1).
  final double covered;

  bool ok(Strictness s) => startOk && directionOk && error <= s.path && covered >= 0.75;
}

StrokeCheck checkStroke(List<Offset> drawn, List<Offset> template, Strictness strictness) {
  const n = 32;
  final d = resample(drawn, n), t = resample(template, n);
  final startOk = (d.first - t.first).distance <= strictness.start;
  var error = 0.0;
  for (final p in d) {
    error += distanceToLine(p, template);
  }
  error /= n;
  // How much of the template has a drawn point near it.
  var near = 0;
  for (final p in t) {
    if (distanceToLine(p, drawn.length > 1 ? drawn : [drawn.first, drawn.first]) <= strictness.path * 1.4) near++;
  }
  final covered = near / n;
  bool directionOk;
  if (_closed(template)) {
    directionOk = _turning(d).sign == _turning(t).sign;
  } else {
    directionOk = (d.last - t.last).distance < (d.last - t.first).distance;
  }
  return StrokeCheck(startOk: startOk, directionOk: directionOk, error: error, covered: covered);
}

/// The verdict on a character written by hand: 0 stars is not yet, 1 to 3
/// how neat. [hint] is the first stroke to show again when it is not yet.
class Verdict {
  const Verdict(this.stars, this.checks, {this.hint});

  final int stars;
  final List<StrokeCheck?> checks;
  final int? hint;

  bool get passed => stars > 0;
}

/// Judges [drawn] (the child's strokes, glyph units) against [template].
/// Lenient lets strokes come in any order, and joins two strokes the
/// finger lifted between.
Verdict judge(List<List<Offset>> drawn, List<List<Offset>> template, Strictness strictness) {
  final strokes = [for (final s in drawn) if (s.isNotEmpty) s];
  if (strokes.isEmpty) return Verdict(0, List.filled(template.length, null), hint: 0);
  var candidates = [strokes];
  if (strictness == Strictness.lenient && strokes.length > template.length) {
    candidates.add(_joinGaps(strokes));
  }
  Verdict? best;
  for (final c in candidates) {
    final v = _judge(c, template, strictness);
    if (best == null || v.stars > best.stars) best = v;
  }
  return best!;
}

List<List<Offset>> _joinGaps(List<List<Offset>> strokes) {
  final out = <List<Offset>>[List.of(strokes.first)];
  for (final s in strokes.skip(1)) {
    if ((out.last.last - s.first).distance < 14) {
      out.last.addAll(s);
    } else {
      out.add(List.of(s));
    }
  }
  return out;
}

Verdict _judge(List<List<Offset>> strokes, List<List<Offset>> template, Strictness strictness) {
  if (strokes.length != template.length) {
    final checks = <StrokeCheck?>[
      for (var i = 0; i < template.length; i++) i < strokes.length ? checkStroke(strokes[i], template[i], strictness) : null,
    ];
    return Verdict(0, checks, hint: checks.indexWhere((c) => c == null || !c.ok(strictness)).clamp(0, template.length - 1));
  }
  final checks = List<StrokeCheck?>.filled(template.length, null);
  if (strictness == Strictness.lenient) {
    // Each drawn stroke goes to the template stroke it fits best.
    final free = {for (var i = 0; i < template.length; i++) i};
    for (final s in strokes) {
      int? pick;
      StrokeCheck? pickCheck;
      for (final i in free) {
        final c = checkStroke(s, template[i], strictness);
        if (pickCheck == null || _score(c) < _score(pickCheck)) {
          pick = i;
          pickCheck = c;
        }
      }
      free.remove(pick);
      checks[pick!] = pickCheck;
    }
  } else {
    for (var i = 0; i < template.length; i++) {
      checks[i] = checkStroke(strokes[i], template[i], strictness);
    }
  }
  final bad = checks.indexWhere((c) => !c!.ok(strictness));
  if (bad >= 0) return Verdict(0, checks, hint: bad);
  final worst = checks.map((c) => c!.error).reduce(math.max);
  final stars = worst <= strictness.path * 0.45 ? 3 : (worst <= strictness.path * 0.7 ? 2 : 1);
  return Verdict(stars, checks);
}

double _score(StrokeCheck c) => c.error + (c.startOk ? 0 : 40) + (c.directionOk ? 0 : 40) + (1 - c.covered) * 30;

/// Tracing one stroke along its road (the third step): how far along the
/// finger has come. The finger has to start at the start dot; if it leaves
/// the road the tracing waits where it was until the finger comes back.
class Tracer {
  Tracer(this.stroke, {this.width = 16}) : _length = pathLength(stroke);

  final List<Offset> stroke;

  /// How far from the line (glyph units) still counts as on the road.
  final double width;
  final double _length;
  double _along = 0;
  bool _active = false;
  bool offRoad = false;

  /// How far along the stroke (0..1).
  double get progress => _length == 0 ? 1 : (_along / _length).clamp(0, 1);

  bool get done => progress >= 0.96;

  /// The finger comes down at [p]: it has to be at the start, or (after it
  /// left the road) back where the tracing stopped.
  bool down(Offset p) {
    final at = pointAt(_along);
    _active = (p - at).distance <= width * 1.5;
    offRoad = !_active;
    return _active;
  }

  /// The finger moved to [p]: the tracing follows it forwards along the
  /// road, never backwards, and never jumps ahead past a gap.
  void move(Offset p) {
    if (!_active || done) return;
    var best = _along, bestD = double.infinity;
    // Look a little way ahead of where the tracing is.
    final ahead = math.min(_length, _along + width * 3);
    for (var s = _along; s <= ahead; s += 1) {
      final d = (pointAt(s) - p).distance;
      if (d < bestD) {
        bestD = d;
        best = s;
      }
    }
    if (bestD > width) {
      offRoad = true;
      return;
    }
    offRoad = false;
    _along = math.max(_along, best);
  }

  void up() => _active = false;

  /// The point [s] along the stroke.
  Offset pointAt(double s) {
    var left = s;
    for (var i = 1; i < stroke.length; i++) {
      final seg = (stroke[i] - stroke[i - 1]).distance;
      if (left <= seg) return Offset.lerp(stroke[i - 1], stroke[i], seg == 0 ? 0 : left / seg)!;
      left -= seg;
    }
    return stroke.last;
  }

  /// The part of the stroke traced so far.
  List<Offset> get traced {
    final out = <Offset>[stroke.first];
    var walked = 0.0;
    for (var i = 1; i < stroke.length; i++) {
      final seg = (stroke[i] - stroke[i - 1]).distance;
      if (walked + seg >= _along) {
        out.add(pointAt(_along));
        return out;
      }
      walked += seg;
      out.add(stroke[i]);
    }
    return out;
  }
}
