import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:letter_pets/core/glyphs.dart';
import 'package:letter_pets/core/writing.dart';

/// The writing engine: is a character written right, and tracing its road.
void main() {
  final book = GlyphBook.fromJson(jsonDecode(File('assets/glyphs.json').readAsStringSync()) as Map<String, dynamic>);

  /// A child's hand: the template, a little wobbly and shifted.
  List<Offset> wobbly(List<Offset> s, {double amount = 2.5, Offset shift = const Offset(1.5, -1), int seed = 1}) {
    final r = math.Random(seed);
    return [for (final p in s) p + shift + Offset((r.nextDouble() - 0.5) * amount, (r.nextDouble() - 0.5) * amount)];
  }

  group('the glyph book', () {
    test('has the warm-ups, the ten digits and A to Z, each written in order', () {
      expect(book.groups.map((g) => g.id), ['warmup', 'digits', 'straight', 'curves', 'slants']);
      expect(book.all.where((g) => g.kind == GlyphKind.digit).map((g) => g.id).toSet(), {for (var i = 0; i < 10; i++) '$i'});
      expect(book.all.where((g) => g.kind == GlyphKind.capital).map((g) => g.id).toSet(),
          {for (var c = 65; c <= 90; c++) String.fromCharCode(c)});
      for (final g in book.all) {
        expect(g.strokes, isNotEmpty, reason: g.id);
        for (final s in g.strokes) {
          expect(s.length, greaterThan(1), reason: g.id);
          for (final p in s) {
            expect(p.dx >= -1 && p.dx <= g.width + 1 && p.dy >= -1 && p.dy <= Glyph.height + 1, isTrue, reason: '${g.id} $p');
          }
        }
      }
    });

    test('lines go down and to the right; a circle goes round the other way to the clock', () {
      for (final g in book.all) {
        for (final s in g.strokes) {
          final d = s.last - s.first;
          // A stroke that only goes up would be the wrong way for a beginner.
          if (d.distance > 10 && d.dx.abs() < 2) expect(d.dy, greaterThan(0), reason: '${g.id}: vertical lines start at the top');
          if (d.distance > 10 && d.dy.abs() < 2) expect(d.dx, greaterThan(0), reason: '${g.id}: across lines start on the left');
        }
      }
      final o = book.byId['O']!.strokes.single;
      var area = 0.0;
      for (var i = 0; i < o.length; i++) {
        final p = o[i], q = o[(i + 1) % o.length];
        area += p.dx * q.dy - q.dx * p.dy;
      }
      expect(area, lessThan(0), reason: 'counterclockwise on a screen that grows down');
    });
  });

  group('judging a written character', () {
    test('every character written along its lines gets stars, at every strictness', () {
      for (final s in Strictness.values) {
        for (final g in book.all) {
          final v = judge([for (final (i, st) in g.strokes.indexed) wobbly(st, seed: i + 1)], g.strokes, s);
          expect(v.passed, isTrue, reason: '${g.id} at ${s.name}');
        }
      }
    });

    test('neat is three stars; a shaky hand fewer, but still right', () {
      final one = book.byId['1']!;
      expect(judge([one.strokes.single], one.strokes, Strictness.normal).stars, 3);
      final off = [for (final p in one.strokes.single) p + const Offset(8, 0)];
      final v = judge([off], one.strokes, Strictness.normal);
      expect(v.stars, inInclusiveRange(1, 2));
    });

    test('a stroke the wrong way round, or from the wrong end, is not yet', () {
      final one = book.byId['1']!;
      final up = one.strokes.single.reversed.toList();
      final v = judge([up], one.strokes, Strictness.normal);
      expect(v.passed, isFalse);
      expect(v.hint, 0);

      final o = book.byId['O']!;
      final clockwise = o.strokes.single.reversed.toList();
      expect(judge([clockwise], o.strokes, Strictness.normal).passed, isFalse);
    });

    test('a scribble somewhere else is not yet', () {
      final t = book.byId['T']!;
      final scribble = [for (var i = 0; i < 30; i++) Offset(10 + i * 1.0, 90 - (i % 5) * 2.0)];
      expect(judge([scribble, scribble], t.strokes, Strictness.lenient).passed, isFalse);
    });

    test('only half of the line is not yet', () {
      final t = book.byId['T']!;
      final half = t.strokes[1].sublist(0, t.strokes[1].length ~/ 2);
      expect(judge([t.strokes[0], half], t.strokes, Strictness.normal).passed, isFalse);
    });

    test('lenient lets the strokes come in any order; normal wants the right order', () {
      final t = book.byId['T']!;
      final swapped = [t.strokes[1], t.strokes[0]];
      expect(judge(swapped, t.strokes, Strictness.lenient).passed, isTrue);
      final normal = judge(swapped, t.strokes, Strictness.normal);
      expect(normal.passed, isFalse);
      expect(normal.hint, 0, reason: 'show the first stroke again');
    });

    test('lenient joins a stroke the finger lifted in the middle of', () {
      final one = book.byId['1']!;
      final s = one.strokes.single;
      final cut = s.length ~/ 2;
      final parts = [s.sublist(0, cut), s.sublist(cut + 1)];
      expect(judge(parts, one.strokes, Strictness.lenient).passed, isTrue);
      expect(judge(parts, one.strokes, Strictness.strict).passed, isFalse);
    });

    test('a missing stroke is not yet, and the hint points at it', () {
      final e = book.byId['E']!;
      final v = judge(e.strokes.sublist(0, 2), e.strokes, Strictness.normal);
      expect(v.passed, isFalse);
      expect(v.hint, 2);
    });

    test('nothing written is not yet', () {
      final a = book.byId['A']!;
      expect(judge(const [], a.strokes, Strictness.lenient).passed, isFalse);
      expect(judge(const [[]], a.strokes, Strictness.lenient).passed, isFalse);
    });

    test('strict wants the lines closer than lenient does', () {
      final h = book.byId['H']!;
      final loose = [for (final (i, s) in h.strokes.indexed) wobbly(s, amount: 3, shift: const Offset(11, 0), seed: i)];
      expect(judge(loose, h.strokes, Strictness.lenient).passed, isTrue);
      expect(judge(loose, h.strokes, Strictness.strict).passed, isFalse);
    });
  });

  group('tracing the road', () {
    final line = [for (var y = 0.0; y <= 100; y += 2.5) Offset(20, y)];

    test('starts only at the start dot, and follows the finger forwards', () {
      final t = Tracer(line);
      expect(t.down(const Offset(20, 60)), isFalse, reason: 'not in the middle');
      expect(t.down(const Offset(22, 3)), isTrue);
      for (var y = 5.0; y <= 50; y += 5) {
        t.move(Offset(21, y));
      }
      expect(t.progress, closeTo(0.5, 0.05));
      t.move(const Offset(20, 30));
      expect(t.progress, closeTo(0.5, 0.05), reason: 'never backwards');
    });

    test('off the road it waits, and goes on when the finger comes back', () {
      final t = Tracer(line)..down(const Offset(20, 0));
      for (var y = 5.0; y <= 40; y += 5) {
        t.move(Offset(20, y));
      }
      final at = t.progress;
      t.move(const Offset(70, 45));
      expect(t.offRoad, isTrue);
      expect(t.progress, at);
      t.up();
      expect(t.down(const Offset(80, 90)), isFalse, reason: 'not somewhere else');
      expect(t.down(const Offset(21, 41)), isTrue, reason: 'back where it stopped');
      for (var y = 45.0; y <= 100; y += 5) {
        t.move(Offset(20, y));
      }
      expect(t.done, isTrue);
      expect(t.offRoad, isFalse);
    });

    test('cannot jump ahead past a gap', () {
      final t = Tracer(line)..down(const Offset(20, 0));
      t.move(const Offset(20, 95));
      expect(t.progress, lessThan(0.6));
    });

    test('what has been traced runs from the start to the finger', () {
      final t = Tracer(line)..down(const Offset(20, 0));
      for (var y = 5.0; y <= 30; y += 5) {
        t.move(Offset(20, y));
      }
      expect(t.traced.first, line.first);
      expect(t.traced.last.dy, closeTo(30, 1.5));
    });

    test('every stroke of every character can be traced to the end', () {
      for (final g in book.all) {
        for (final s in g.strokes) {
          final t = Tracer(s);
          expect(t.down(s.first), isTrue);
          for (final p in s) {
            t.move(p);
          }
          expect(t.done, isTrue, reason: g.id);
        }
      }
    });
  });

  test('resampling spreads the points evenly', () {
    final r = resample(const [Offset(0, 0), Offset(10, 0), Offset(10, 10)], 5);
    expect(r.length, 5);
    expect(r.first, const Offset(0, 0));
    expect(r.last, const Offset(10, 10));
    for (var i = 1; i < r.length; i++) {
      expect((r[i] - r[i - 1]).distance, closeTo(5, 1.5));
    }
  });
}
