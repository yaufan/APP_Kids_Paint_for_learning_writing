import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/providers.dart';
import '../core/sounds.dart';
import 'theme.dart';

/// A picture from assets/art/.
class Art extends StatelessWidget {
  const Art(this.path, {super.key, this.width, this.height, this.fit = BoxFit.contain});

  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) =>
      SvgPicture.asset('assets/art/$path.svg', width: width, height: height, fit: fit, excludeFromSemantics: true);
}

/// Shrinks a little while pressed, and clicks.
class Pressable extends ConsumerStatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.sound = Sfx.tap});

  final Widget child;
  final VoidCallback? onTap;
  final Sfx? sound;

  @override
  ConsumerState<Pressable> createState() => _PressableState();
}

class _PressableState extends ConsumerState<Pressable> {
  var _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTap: enabled
          ? () {
              final s = widget.sound;
              if (s != null) ref.read(soundsProvider).play(s);
              widget.onTap!();
            }
          : null,
      child: AnimatedScale(scale: _down ? 0.92 : 1, duration: const Duration(milliseconds: 90), child: widget.child),
    );
  }
}

/// A gentle up-and-down, like breathing.
class Breathing extends StatefulWidget {
  const Breathing({super.key, required this.child, this.amount = 0.04, this.period = const Duration(milliseconds: 2400)});

  final Widget child;
  final double amount;
  final Duration period;

  @override
  State<Breathing> createState() => _BreathingState();
}

class _BreathingState extends State<Breathing> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: widget.period)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, child) => Transform.scale(scale: 1 + widget.amount * math.sin(_c.value * 2 * math.pi), child: child),
        child: widget.child,
      );
}

/// A page of the picture book: warm paper with a faint grain.
class Paper extends StatelessWidget {
  const Paper({super.key, required this.child, this.color = Book.paper});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _GrainPainter(color),
        child: child,
      );
}

class _GrainPainter extends CustomPainter {
  _GrainPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = color);
    final r = math.Random(7);
    final dot = Paint()..color = Book.paperGrain.withValues(alpha: 0.22);
    final n = (size.width * size.height / 900).clamp(0, 4000).toInt();
    for (var i = 0; i < n; i++) {
      canvas.drawCircle(Offset(r.nextDouble() * size.width, r.nextDouble() * size.height), 0.5 + r.nextDouble() * 0.9, dot);
    }
    // A soft darker edge, like an old page.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.transparent, Book.paperGrain.withValues(alpha: 0.28)],
          stops: const [0.62, 1],
          radius: 0.9,
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_GrainPainter old) => old.color != color;
}

/// A hand-painted shape: a soft wash of [color], lighter at the top, with
/// a thin wobbly line in a darker shade of it (no black outlines).
class Wash extends StatelessWidget {
  const Wash({super.key, required this.color, required this.line, this.radius = 26, this.child, this.padding = EdgeInsets.zero, this.seed = 1});

  final Color color;
  final Color line;
  final double radius;
  final Widget? child;
  final EdgeInsets padding;
  final int seed;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _WashPainter(color, line, radius, seed),
        child: Padding(padding: padding, child: child),
      );
}

class _WashPainter extends CustomPainter {
  _WashPainter(this.color, this.line, this.radius, this.seed);

  final Color color;
  final Color line;
  final double radius;
  final int seed;

  /// A rounded rectangle whose edge wanders a little, like a brush.
  Path _shape(Size size, math.Random r, double wobble) {
    final rad = math.min(radius, size.shortestSide / 2);
    final rect = Offset.zero & size;
    final base = Path()..addRRect(RRect.fromRectAndRadius(rect.deflate(1.5), Radius.circular(rad)));
    final metric = base.computeMetrics().first;
    final steps = math.max(24, (metric.length / 14).round());
    final phase = r.nextDouble() * math.pi * 2;
    final out = Path();
    for (var i = 0; i <= steps; i++) {
      final t = metric.getTangentForOffset(metric.length * i / steps)!;
      final n = Offset(-t.vector.dy, t.vector.dx);
      final w = wobble * (math.sin(i * 0.9 + phase) * 0.6 + (r.nextDouble() - 0.5) * 0.8);
      final p = t.position + n * w;
      i == 0 ? out.moveTo(p.dx, p.dy) : out.lineTo(p.dx, p.dy);
    }
    return out..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.Random(seed);
    final shape = _shape(size, r, 1.2);
    canvas.drawShadow(shape, line.withValues(alpha: 0.5), 3, false);
    canvas.drawPath(
      shape,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(color, Colors.white, 0.28)!, color, Color.lerp(color, line, 0.18)!],
          stops: const [0, 0.55, 1],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      _shape(size, r, 1.6),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = line.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(_WashPainter old) => old.color != color || old.line != line || old.radius != radius;
}

/// A big button for small hands: a picture and/or a word on a wash.
class BookButton extends StatelessWidget {
  const BookButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.color = Book.peach,
    this.line = Book.peachLine,
    this.size = 72,
    this.showLabel = true,
    this.wide = false,
  });

  final String label;
  final Widget? icon;
  final VoidCallback? onTap;
  final Color color;
  final Color line;
  final double size;
  final bool showLabel;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final content = Row(mainAxisSize: MainAxisSize.min, children: [
      if (icon != null) SizedBox(width: size * 0.62, height: size * 0.62, child: icon),
      if (icon != null && showLabel && wide) const SizedBox(width: 8),
      if (showLabel && (wide || icon == null))
        Text(label, style: TextStyle(fontSize: size * 0.32, fontWeight: FontWeight.w700, color: Book.ink)),
    ]);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.5 : 1,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              height: size,
              width: wide ? null : size,
              child: Wash(
                color: color,
                line: line,
                radius: size * 0.36,
                seed: label.hashCode,
                padding: EdgeInsets.symmetric(horizontal: wide ? size * 0.3 : 0),
                child: Center(child: content),
              ),
            ),
            if (showLabel && !wide && icon != null) ...[
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Book.ink)),
            ],
          ]),
        ),
      ),
    );
  }
}

/// What the pet (or the story) says, in a soft bubble.
class Bubble extends StatelessWidget {
  const Bubble(this.text, {super.key, this.size = 20, this.tail = true});

  final String text;
  final double size;
  final bool tail;

  @override
  Widget build(BuildContext context) => Wash(
        color: const Color(0xFFFFFBF2),
        line: Book.paperGrain,
        radius: 22,
        seed: text.length,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Text(text, style: TextStyle(fontSize: size, height: 1.35, color: Book.ink, fontWeight: FontWeight.w600)),
      );
}

/// A round back/close button in the corner.
class CornerButton extends StatelessWidget {
  const CornerButton({super.key, required this.label, required this.icon, this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Pressable(
          onTap: onTap,
          child: SizedBox(
            width: 56,
            height: 56,
            child: Wash(color: Book.paperDeep, line: Book.paperGrain, radius: 28, child: Icon(icon, color: Book.inkSoft, size: 28)),
          ),
        ),
      );
}
