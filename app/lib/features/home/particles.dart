import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';

enum Bit { heart, bubble, sparkle, zzz, crumb, foam, drop, confetti, note }

/// Little things that float up, fall or pop round the pet.
class Particle {
  Particle(this.kind, this.at, {this.velocity = Offset.zero, required this.born, this.life = 1.2, this.size = 18, this.spin = 0, this.color, this.gravity = 0});

  final Bit kind;
  Offset at;
  Offset velocity;
  final double born;
  final double life;
  final double size;
  final double spin;
  final Color? color;
  final double gravity;

  double age(double t) => t - born;
  bool alive(double t) => life <= 0 || age(t) < life;
}

class Particles {
  final _all = <Particle>[];
  final _random = math.Random(3);
  double _last = 0;

  List<Particle> get all => _all;
  bool get isEmpty => _all.isEmpty;

  void add(Particle p) => _all.add(p);

  void step(double t) {
    final dt = (t - _last).clamp(0.0, 0.05);
    _last = t;
    for (final p in _all) {
      p.velocity += Offset(0, p.gravity * dt);
      p.at += p.velocity * dt;
    }
    _all.removeWhere((p) => !p.alive(t));
  }

  double r() => _random.nextDouble();

  void hearts(Offset at, double t, {int n = 3}) {
    for (var i = 0; i < n; i++) {
      add(Particle(Bit.heart, at + Offset((r() - 0.5) * 40, (r() - 0.5) * 20),
          velocity: Offset((r() - 0.5) * 40, -60 - r() * 50), born: t, life: 1.3, size: 16 + r() * 10));
    }
  }

  void bubbles(Offset at, double t, {int n = 4, double spread = 60}) {
    for (var i = 0; i < n; i++) {
      add(Particle(Bit.bubble, at + Offset((r() - 0.5) * spread, (r() - 0.5) * spread * 0.5),
          velocity: Offset((r() - 0.5) * 30, -50 - r() * 60), born: t, life: 1.8 + r(), size: 10 + r() * 16));
    }
  }

  void sparkles(Offset at, double t, {int n = 5, double spread = 70}) {
    for (var i = 0; i < n; i++) {
      add(Particle(Bit.sparkle, at + Offset((r() - 0.5) * spread, (r() - 0.5) * spread),
          velocity: Offset((r() - 0.5) * 30, -20 - r() * 30), born: t, life: 0.9, size: 12 + r() * 12, spin: r() * 3));
    }
  }

  void crumbs(Offset at, double t) {
    for (var i = 0; i < 6; i++) {
      add(Particle(Bit.crumb, at, velocity: Offset((r() - 0.5) * 120, -40 - r() * 60), born: t, life: 0.9, size: 4 + r() * 4, gravity: 420));
    }
  }

  /// Soap that stays on the pet (in its own coordinates, 0..1) until rinsed.
  void foam(Offset at, double t) =>
      add(Particle(Bit.foam, at, born: t, life: 0, size: 14 + r() * 14));

  int get foamCount => _all.where((p) => p.kind == Bit.foam).length;

  void rinse(double t) {
    _all.removeWhere((p) => p.kind == Bit.foam);
  }

  void drops(Offset from, double width, double t) {
    for (var i = 0; i < 14; i++) {
      add(Particle(Bit.drop, from + Offset((r() - 0.5) * width, r() * 20),
          velocity: Offset(0, 260 + r() * 120), born: t + r() * 0.4, life: 0.9, size: 8 + r() * 4));
    }
  }

  void zzz(Offset at, double t) =>
      add(Particle(Bit.zzz, at, velocity: Offset(14 + r() * 10, -26), born: t, life: 2.4, size: 22 + r() * 10));

  void confetti(Size screen, double t) {
    const colors = [Book.coral, Book.mustard, Book.sage, Book.blue, Book.lilac, Book.peach];
    for (var i = 0; i < 60; i++) {
      add(Particle(Bit.confetti, Offset(r() * screen.width, -20 - r() * 120),
          velocity: Offset((r() - 0.5) * 60, 120 + r() * 140), born: t, life: 3.2, size: 8 + r() * 6, spin: r() * 6, color: colors[i % colors.length]));
    }
  }

  void notes(Offset at, double t) {
    for (var i = 0; i < 2; i++) {
      add(Particle(Bit.note, at + Offset((r() - 0.5) * 60, 0), velocity: Offset((r() - 0.5) * 30, -50), born: t, life: 1.6, size: 22));
    }
  }
}

/// Paints the particles; foam is drawn on [petRect] (it moves with the pet).
class ParticlePainter extends CustomPainter {
  ParticlePainter(this.particles, this.t, this.petRect);

  final Particles particles;
  final double t;
  final Rect petRect;

  static Path heart(Offset c, double s) {
    final w = s, h = s * 0.9;
    return Path()
      ..moveTo(c.dx, c.dy + h * 0.45)
      ..cubicTo(c.dx - w * 0.9, c.dy - h * 0.1, c.dx - w * 0.45, c.dy - h * 0.75, c.dx, c.dy - h * 0.25)
      ..cubicTo(c.dx + w * 0.45, c.dy - h * 0.75, c.dx + w * 0.9, c.dy - h * 0.1, c.dx, c.dy + h * 0.45)
      ..close();
  }

  static Path star(Offset c, double r, {int points = 4, double inner = 0.38, double turn = 0}) {
    final p = Path();
    for (var i = 0; i < points * 2; i++) {
      final a = turn - math.pi / 2 + i * math.pi / points;
      final rr = i.isEven ? r : r * inner;
      final q = c + Offset(math.cos(a), math.sin(a)) * rr;
      i == 0 ? p.moveTo(q.dx, q.dy) : p.lineTo(q.dx, q.dy);
    }
    return p..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles.all) {
      final age = p.age(t);
      if (age < 0) continue;
      final fade = p.life <= 0 ? 1.0 : (1 - age / p.life).clamp(0.0, 1.0);
      switch (p.kind) {
        case Bit.heart:
          canvas.drawPath(heart(p.at, p.size), Paint()..color = const Color(0xFFEF8E9A).withValues(alpha: fade));
          canvas.drawPath(
              heart(p.at, p.size),
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.5
                ..color = const Color(0xFFC25E6C).withValues(alpha: fade * 0.8));
        case Bit.bubble || Bit.foam:
          final at = p.kind == Bit.foam ? Offset(petRect.left + p.at.dx * petRect.width, petRect.top + p.at.dy * petRect.height) : p.at;
          final r = p.size / 2 * (p.kind == Bit.foam ? 1 : (0.7 + 0.3 * math.min(1, age * 3)));
          canvas.drawCircle(at, r, Paint()..color = Colors.white.withValues(alpha: (p.kind == Bit.foam ? 0.85 : 0.35) * fade));
          canvas.drawCircle(
              at,
              r,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.6
                ..color = Book.blueLine.withValues(alpha: 0.55 * fade));
          canvas.drawCircle(at + Offset(-r * 0.35, -r * 0.35), r * 0.22, Paint()..color = Colors.white.withValues(alpha: 0.9 * fade));
        case Bit.sparkle:
          canvas.drawPath(star(p.at, p.size / 2, turn: p.spin + age * 2), Paint()..color = Book.mustard.withValues(alpha: fade));
        case Bit.zzz:
          final tp = TextPainter(
            text: TextSpan(text: 'Z', style: TextStyle(fontSize: p.size, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: fade * 0.9), fontFamily: 'Huninn')),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, p.at);
        case Bit.crumb:
          canvas.drawCircle(p.at, p.size / 2, Paint()..color = const Color(0xFFB98A5A).withValues(alpha: fade));
        case Bit.drop:
          final path = Path()
            ..moveTo(p.at.dx, p.at.dy - p.size)
            ..quadraticBezierTo(p.at.dx + p.size * 0.6, p.at.dy, p.at.dx, p.at.dy + p.size * 0.4)
            ..quadraticBezierTo(p.at.dx - p.size * 0.6, p.at.dy, p.at.dx, p.at.dy - p.size);
          canvas.drawPath(path, Paint()..color = Book.blue.withValues(alpha: 0.85 * fade));
        case Bit.confetti:
          canvas.save();
          canvas.translate(p.at.dx, p.at.dy);
          canvas.rotate(p.spin + age * 4);
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.55), const Radius.circular(2)),
              Paint()..color = p.color!.withValues(alpha: fade));
          canvas.restore();
        case Bit.note:
          final tp = TextPainter(
            text: TextSpan(text: '♪', style: TextStyle(fontSize: p.size, color: Book.lilacLine.withValues(alpha: fade))),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, p.at);
      }
    }
  }

  @override
  bool shouldRepaint(ParticlePainter old) => true;
}
