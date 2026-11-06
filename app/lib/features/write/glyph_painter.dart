import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/glyphs.dart';
import '../../core/writing.dart';
import '../home/particles.dart';

/// Where a glyph sits in a box: glyph units (100 high) to the screen.
class GlyphFit {
  GlyphFit(Glyph glyph, Size box, {double fill = 0.78})
      : scale = math.min(box.height * fill / Glyph.height, box.width * 0.86 / math.max(glyph.width, 40)),
        size = box {
    origin = Offset((box.width - glyph.width * scale) / 2, (box.height - Glyph.height * scale) / 2);
  }

  final double scale;
  final Size size;
  late final Offset origin;

  Offset toScreen(Offset p) => origin + p * scale;
  Offset toGlyph(Offset p) => (p - origin) / scale;
}

Path strokePath(List<Offset> points, Offset Function(Offset) map) {
  final p = Path();
  if (points.isEmpty) return p;
  final first = map(points.first);
  p.moveTo(first.dx, first.dy);
  for (final q in points.skip(1)) {
    final s = map(q);
    p.lineTo(s.dx, s.dy);
  }
  return p;
}

/// The first part of [points], [t] (0..1) of the way along.
List<Offset> partOf(List<Offset> points, double t) {
  if (t >= 1) return points;
  if (t <= 0) return [points.first];
  final total = pathLength(points);
  var left = total * t;
  final out = <Offset>[points.first];
  for (var i = 1; i < points.length; i++) {
    final seg = (points[i] - points[i - 1]).distance;
    if (left <= seg) {
      out.add(Offset.lerp(points[i - 1], points[i], seg == 0 ? 0 : left / seg)!);
      return out;
    }
    left -= seg;
    out.add(points[i]);
  }
  return out;
}

/// A glyph drawn whole, for its card.
class GlyphPainter extends CustomPainter {
  GlyphPainter(this.glyph, {this.color = Book.ink, this.width = 10});

  final Glyph glyph;
  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final fit = GlyphFit(glyph, size, fill: 0.86);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width * fit.scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    for (final s in glyph.strokes) {
      canvas.drawPath(strokePath(s, fit.toScreen), paint);
    }
  }

  @override
  bool shouldRepaint(GlyphPainter old) => old.glyph != glyph || old.color != color;
}

/// The four steps (docs/design.md "四個小關卡").
enum Step { watch, tap, trace, write }

/// What the writing page shows for [step].
class WritePainter extends CustomPainter {
  WritePainter({
    required this.glyph,
    required this.step,
    required this.t,
    this.watched = 0,
    this.tapped = 0,
    this.tracers = const [],
    this.current = 0,
    this.done = const {},
    this.live,
    this.fading,
    this.fade = 0,
    this.guide = 0,
    this.road = false,
    this.arrow = true,
    this.hint,
    this.hintProgress = 0,
    this.leftHanded = false,
    this.inkColor = Book.coral,
  });

  final Glyph glyph;
  final Step step;

  /// Seconds, for the bouncing dot.
  final double t;

  /// How much of the glyph has been shown in step 1 (strokes; 1.5 is half
  /// of the second).
  final double watched;

  /// Start stars tapped (step 2).
  final int tapped;
  final List<Tracer> tracers;

  /// The stroke being traced or written.
  final int current;
  /// Step 4: the strokes written right so far (by template stroke), the one
  /// being written, and a wrong one fading away ([fade] 0..1, gone at 1).
  final Map<int, List<Offset>> done;
  final List<Offset>? live;
  final List<Offset>? fading;
  final double fade;

  /// How much help to show under the writing: 0 the faint letter, 1 a
  /// dotted line, 2 nothing but the green dot.
  final int guide;

  /// After three tries at a stroke, its road shows again.
  final bool road;

  /// The little arrow beside the green dot.
  final bool arrow;
  final int? hint;
  final double hintProgress;
  final bool leftHanded;
  final Color inkColor;

  static const roadWidth = 20.0, inkWidth = 9.0;

  @override
  void paint(Canvas canvas, Size size) {
    final fit = GlyphFit(glyph, size);
    Paint line(Color c, double w) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * fit.scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = c;

    // A faint guide box, like a page in an exercise book.
    final box = Rect.fromLTWH(fit.origin.dx - 14 * fit.scale, fit.origin.dy - 8 * fit.scale, (glyph.width + 28) * fit.scale, 116 * fit.scale);
    final dash = Paint()
      ..color = Book.paperGrain.withValues(alpha: 0.6)
      ..strokeWidth = 1.5;
    for (final y in [fit.origin.dy, fit.origin.dy + 100 * fit.scale]) {
      for (var x = box.left; x < box.right; x += 14) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + 7, box.right), y), dash);
      }
    }

    final strokes = glyph.strokes;
    switch (step) {
      case Step.watch:
        for (final s in strokes) {
          canvas.drawPath(strokePath(s, fit.toScreen), line(Book.road, roadWidth * 0.7));
        }
        for (var i = 0; i < strokes.length; i++) {
          final p = (watched - i).clamp(0.0, 1.0);
          if (p <= 0) break;
          final part = partOf(strokes[i], p);
          canvas.drawPath(strokePath(part, fit.toScreen), line(inkColor, inkWidth));
          if (p < 1) _pencil(canvas, fit.toScreen(part.last), fit.scale);
        }
      case Step.tap:
        for (var i = 0; i < strokes.length; i++) {
          canvas.drawPath(strokePath(strokes[i], fit.toScreen), line(i < tapped ? inkColor : Book.road, i < tapped ? inkWidth : roadWidth * 0.7));
        }
        if (tapped < strokes.length) _star(canvas, fit.toScreen(strokes[tapped].first), fit.scale, tapped + 1);
      case Step.trace:
        for (var i = 0; i < strokes.length; i++) {
          final path = strokePath(strokes[i], fit.toScreen);
          canvas.drawPath(path, line(Book.roadLine, roadWidth + 2));
          canvas.drawPath(path, line(Book.road, roadWidth));
        }
        for (var i = 0; i < tracers.length && i <= current; i++) {
          canvas.drawPath(strokePath(i < current ? strokes[i] : tracers[i].traced, fit.toScreen), line(inkColor, inkWidth * 1.3));
        }
        if (current < strokes.length) {
          final tr = tracers[current];
          final at = tr.pointAt(tr.progress * pathLength(strokes[current]));
          _arrow(canvas, fit, strokes[current], tr.progress);
          _dot(canvas, fit.toScreen(at), fit.scale);
        }
      case Step.write:
        // The help under the writing.
        for (final st in strokes) {
          final path = strokePath(st, fit.toScreen);
          if (guide == 0) canvas.drawPath(path, line(Book.road.withValues(alpha: 0.75), roadWidth * 0.85));
          if (guide == 1) _dotted(canvas, st, fit);
        }
        if (road && current < strokes.length) {
          final path = strokePath(strokes[current], fit.toScreen);
          canvas.drawPath(path, line(Book.roadLine, roadWidth + 2));
          canvas.drawPath(path, line(Book.road, roadWidth));
        }
        void ink(List<Offset> s, Color c) {
          if (s.length == 1) {
            canvas.drawCircle(fit.toScreen(s.first), inkWidth * fit.scale / 2, Paint()..color = c);
          } else {
            canvas.drawPath(strokePath(s, fit.toScreen), line(c, inkWidth));
          }
        }
        for (final s in done.values) {
          ink(s, inkColor);
        }
        final f = fading;
        if (f != null && fade < 1) ink(f, inkColor.withValues(alpha: 0.6 * (1 - fade)));
        final h = hint;
        if (h != null && h < strokes.length) {
          canvas.drawPath(strokePath(strokes[h], fit.toScreen), line(Book.go.withValues(alpha: 0.35), roadWidth));
          final part = partOf(strokes[h], hintProgress);
          canvas.drawPath(strokePath(part, fit.toScreen), line(Book.goLine, inkWidth * 0.8));
        }
        if (current < strokes.length) {
          if (arrow || h != null) _arrow(canvas, fit, strokes[current], 0);
          _dot(canvas, fit.toScreen(strokes[current].first), fit.scale);
        }
        final l = live;
        if (l != null) ink(l, inkColor);
    }
  }

  /// A dotted line along [stroke] (the middle level of help).
  void _dotted(Canvas canvas, List<Offset> stroke, GlyphFit fit) {
    final len = pathLength(stroke);
    final dot = Paint()..color = Book.roadLine;
    final along = Tracer(stroke);
    for (var d = 0.0; d <= len; d += 7) {
      canvas.drawCircle(fit.toScreen(along.pointAt(d)), 1.9 * fit.scale, dot);
    }
  }

  /// The green start dot, bouncing a little.
  void _dot(Canvas canvas, Offset at, double scale) {
    final r = (9 + 1.6 * math.sin(t * 6)) * scale;
    canvas.drawCircle(at, r + 3 * scale, Paint()..color = Book.go.withValues(alpha: 0.25));
    canvas.drawCircle(at, r, Paint()..color = Book.go);
    canvas.drawCircle(
        at,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Book.goLine);
    canvas.drawCircle(at + Offset(-r * 0.3, -r * 0.3), r * 0.25, Paint()..color = Colors.white.withValues(alpha: 0.8));
  }

  void _star(Canvas canvas, Offset at, double scale, int n) {
    final r = (12 + 1.5 * math.sin(t * 6)) * scale;
    canvas.drawCircle(at, r * 1.3, Paint()..color = Book.mustard.withValues(alpha: 0.3));
    final s = ParticlePainter.star(at, r, points: 5, inner: 0.5);
    canvas.drawPath(s, Paint()..color = Book.mustard);
    canvas.drawPath(
        s,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round
          ..color = Book.mustardLine);
    final tp = TextPainter(
      text: TextSpan(text: '$n', style: TextStyle(fontSize: r * 0.9, fontWeight: FontWeight.w700, color: Book.ink, fontFamily: 'Huninn')),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
  }

  void _pencil(Canvas canvas, Offset at, double scale) {
    canvas.drawCircle(at, 7 * scale, Paint()..color = Book.coralLine);
    canvas.drawCircle(at, 4 * scale, Paint()..color = Colors.white.withValues(alpha: 0.7));
  }

  /// Which way to go: a soft arrow beside the road, on the side the hand
  /// does not cover.
  void _arrow(Canvas canvas, GlyphFit fit, List<Offset> stroke, double from) {
    final len = pathLength(stroke);
    if (len < 8) return;
    final s0 = from * len;
    final a = _at(stroke, s0 + 4), b = _at(stroke, math.min(len, s0 + 22));
    final d = b - a;
    if (d.distance < 1) return;
    final dir = d / d.distance;
    var normal = Offset(-dir.dy, dir.dx);
    // Right-handed: put it on the left of the road (and the other way round).
    if ((normal.dx > 0) != leftHanded) normal = -normal;
    final off = normal * 20;
    final p0 = fit.toScreen(a + off), p1 = fit.toScreen(b + off);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5 * fit.scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Book.goLine.withValues(alpha: 0.75);
    canvas.drawLine(p0, p1, paint);
    final back = -dir * 7 * fit.scale;
    final side = Offset(-dir.dy, dir.dx) * 6 * fit.scale;
    canvas.drawPath(Path()
      ..moveTo(p1.dx + back.dx + side.dx, p1.dy + back.dy + side.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p1.dx + back.dx - side.dx, p1.dy + back.dy - side.dy), paint);
  }

  Offset _at(List<Offset> s, double d) => Tracer(s).pointAt(d);

  @override
  bool shouldRepaint(WritePainter old) => true;
}
