import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/pet_art.dart';

/// The pet's face right now.
enum Mood { open, happy, sleep }

/// The pet drawn [width] wide. With its eyes open it looks at [lookAt]
/// (in this widget's own coordinates) and blinks now and then.
class PetView extends StatefulWidget {
  const PetView({super.key, required this.art, required this.width, this.mood = Mood.open, this.lookAt, this.bib = false});

  final PetArt art;
  final double width;
  final Mood mood;
  final Offset? lookAt;

  /// A baby wears a bib (assets/art/wear/bib.svg: 120 square, the neck at
  /// 60, 24).
  final bool bib;

  double get height => width * art.size.height / art.size.width;

  @override
  State<PetView> createState() => _PetViewState();
}

class _PetViewState extends State<PetView> with SingleTickerProviderStateMixin {
  late final _blink = AnimationController(vsync: this, duration: const Duration(milliseconds: 160));
  final _random = math.Random();
  Timer? _next;

  @override
  void initState() {
    super.initState();
    _blink.addStatusListener((s) {
      if (s == AnimationStatus.completed) _blink.reverse();
      if (s == AnimationStatus.dismissed) _scheduleBlink();
    });
    _scheduleBlink();
  }

  void _scheduleBlink() {
    _next?.cancel();
    _next = Timer(Duration(milliseconds: 2500 + _random.nextInt(3000)), () {
      if (mounted) _blink.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _next?.cancel();
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final art = widget.art;
    final svg = switch (widget.mood) {
      Mood.open => art.open,
      Mood.happy => art.happy,
      Mood.sleep => art.sleep,
    };
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(fit: StackFit.expand, children: [
        SvgPicture.string(svg, fit: BoxFit.contain, excludeFromSemantics: true),
        if (widget.mood == Mood.open)
          AnimatedBuilder(
            animation: _blink,
            builder: (_, _) => CustomPaint(painter: EyesPainter(art, lookAt: widget.lookAt, closed: _blink.value)),
          ),
        if (widget.bib) _bib(),
      ]),
    );
  }
}

extension on _PetViewState {
  Widget _bib() {
    final art = widget.art;
    final k = widget.width / art.size.width;
    final w = art.body.width * 0.7 * k;
    final neck = Offset(art.mouth.dx, art.mouth.dy + art.headRadius * 0.34) * k;
    return Positioned(
      left: neck.dx - w / 2,
      top: neck.dy - w * 0.2,
      width: w,
      height: w,
      child: SvgPicture.asset('assets/art/wear/bib.svg', excludeFromSemantics: true),
    );
  }
}

/// The pet's eyes: dark round dots with a shine, turned towards [lookAt];
/// [closed] (0..1) shuts them for a blink.
class EyesPainter extends CustomPainter {
  EyesPainter(this.art, {this.lookAt, this.closed = 0});

  final PetArt art;
  final Offset? lookAt;
  final double closed;

  static const _dark = Color(0xFF3A2A25);

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / art.size.width;
    canvas.save();
    canvas.scale(k);
    final target = lookAt == null ? null : lookAt! / k;
    for (final (c, r) in art.eyes) {
      var gaze = Offset.zero;
      if (target != null) {
        final d = target - c;
        final len = d.distance;
        if (len > 1) gaze = d / len * math.min(r * 0.32, len * 0.08);
      }
      final at = c + gaze;
      final h = 1 - closed;
      if (h < 0.25) {
        // Shut: a little curved line.
        final p = Path()
          ..moveTo(at.dx - r, at.dy)
          ..quadraticBezierTo(at.dx, at.dy + r * 0.55, at.dx + r, at.dy);
        canvas.drawPath(
          p,
          Paint()
            ..color = _dark
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.32
            ..strokeCap = StrokeCap.round,
        );
        continue;
      }
      canvas.drawOval(Rect.fromCenter(center: at, width: r * 2, height: r * 2 * h), Paint()..color = _dark);
      canvas.drawCircle(at + Offset(-r * 0.3, -r * 0.36 * h) + gaze * 0.25, r * 0.34, Paint()..color = Colors.white);
      canvas.drawCircle(at + Offset(r * 0.32, r * 0.3 * h), r * 0.13, Paint()..color = Colors.white.withValues(alpha: 0.8));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(EyesPainter old) => old.lookAt != lookAt || old.closed != closed || old.art != art;
}
