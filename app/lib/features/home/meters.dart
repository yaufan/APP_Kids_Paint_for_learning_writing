import 'package:flutter/material.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../core/game.dart';
import 'particles.dart';

/// One of the three hearts, filled from the bottom as full as it is, with
/// a little picture of what it is for.
class HeartMeter extends StatelessWidget {
  const HeartMeter({super.key, required this.heart, required this.level, this.size = 44});

  final Heart heart;
  final double level;
  final double size;

  @override
  Widget build(BuildContext context) {
    final label = switch (heart) {
      Heart.belly => Strings.belly,
      Heart.clean => Strings.clean,
      Heart.happy => Strings.happy,
    };
    return Semantics(
      label: '$label ${(level * 100).round()}%',
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _HeartPainter(heart, level)),
      ),
    );
  }
}

class _HeartPainter extends CustomPainter {
  _HeartPainter(this.heart, this.level);

  final Heart heart;
  final double level;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.52);
    final shape = ParticlePainter.heart(c, size.width * 0.92);
    canvas.drawPath(shape, Paint()..color = const Color(0xFFFFF6EC));
    canvas.save();
    canvas.clipPath(shape);
    final top = size.height * (0.92 - 0.84 * level.clamp(0, 1));
    canvas.drawRect(Rect.fromLTRB(0, top, size.width, size.height), Paint()..color = const Color(0xFFEF8E9A));
    canvas.restore();
    canvas.drawPath(
        shape,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFFC25E6C));
    // What it is for: a bowl, a bubble, a smile.
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = Book.ink.withValues(alpha: 0.75);
    final s = size.width;
    switch (heart) {
      case Heart.belly:
        canvas.drawArc(Rect.fromCenter(center: c + Offset(0, -s * 0.02), width: s * 0.36, height: s * 0.28), 0, 3.14, false, ink);
        canvas.drawLine(c + Offset(-s * 0.2, -s * 0.02), c + Offset(s * 0.2, -s * 0.02), ink);
      case Heart.clean:
        canvas.drawCircle(c + Offset(-s * 0.05, -s * 0.02), s * 0.11, ink);
        canvas.drawCircle(c + Offset(s * 0.12, -s * 0.1), s * 0.06, ink);
      case Heart.happy:
        canvas.drawArc(Rect.fromCenter(center: c + Offset(0, -s * 0.06), width: s * 0.3, height: s * 0.24), 0.3, 2.5, false, ink);
    }
  }

  @override
  bool shouldRepaint(_HeartPainter old) => old.level != level;
}

/// Stars towards the next cookie: three slots.
class StarSlots extends StatelessWidget {
  const StarSlots({super.key, required this.stars, this.size = 26});

  final int stars;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
        label: Strings.stars(stars),
        excludeSemantics: true,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < 3; i++) SizedBox(width: size, height: size, child: CustomPaint(painter: StarPainter(filled: i < stars))),
        ]),
      );
}

class StarPainter extends CustomPainter {
  StarPainter({required this.filled, this.color = Book.mustard, this.line = Book.mustardLine});

  final bool filled;
  final Color color;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final s = ParticlePainter.star(size.center(Offset.zero), size.width * 0.46, points: 5, inner: 0.48);
    canvas.drawPath(s, Paint()..color = filled ? color : const Color(0xFFFFF6EC));
    canvas.drawPath(
        s,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeJoin = StrokeJoin.round
          ..color = filled ? line : Book.paperGrain);
  }

  @override
  bool shouldRepaint(StarPainter old) => old.filled != filled;
}

/// How far to the next stage: a sprout and a little bar.
class GrowthBar extends StatelessWidget {
  const GrowthBar({super.key, required this.value, this.width = 96});

  final double value;
  final double width;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '${Strings.growth} ${(value * 100).round()}%',
        excludeSemantics: true,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.spa_rounded, color: Book.sageLine, size: 22),
          const SizedBox(width: 4),
          Container(
            width: width,
            height: 12,
            decoration: BoxDecoration(color: const Color(0xFFFFF6EC), borderRadius: BorderRadius.circular(6), border: Border.all(color: Book.sageLine, width: 1.5)),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 600),
                widthFactor: value.clamp(0.04, 1),
                child: Container(decoration: BoxDecoration(color: Book.sage, borderRadius: BorderRadius.circular(6))),
              ),
            ),
          ),
        ]),
      );
}
