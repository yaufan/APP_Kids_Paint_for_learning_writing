import 'package:flutter/material.dart' hide Step;
import 'package:flutter_test/flutter_test.dart';
import 'package:letter_pets/app/strings.dart';
import 'package:letter_pets/core/game.dart';
import 'package:letter_pets/core/pets.dart';
import 'package:letter_pets/core/sounds.dart';
import 'package:letter_pets/core/writing.dart';
import 'package:letter_pets/features/write/glyph_painter.dart';

import 'helpers.dart';

/// 0.2: the fourth step checks one stroke at a time, so a wrong stroke, a
/// stray tap or a missing stroke can no longer muddle the whole letter.
void main() {
  final day = DateTime(2026, 11, 6, 10);
  Game pet({Map<String, GlyphProgress> glyphs = const {}, Strictness strictness = Strictness.normal}) => Game(
        storyRead: true,
        species: Species.puppy,
        hatched: true,
        name: '豆豆',
        glyphs: glyphs,
        settings: Settings(strictness: strictness),
      );

  group('the helpers', () {
    final t = glyphBook.byId['T']!;

    test('a tap or a tiny dot is not a stroke', () {
      expect(isTap(const [Offset(5, 5)], t.strokes[0]), isTrue);
      expect(isTap(const [Offset(5, 5), Offset(7, 5), Offset(8, 5)], t.strokes[0]), isTrue);
      expect(isTap(t.strokes[0], t.strokes[0]), isFalse);
    });

    test('in order only the next stroke counts; lenient takes any that fits', () {
      expect(matchStroke(t.strokes[1], t.strokes, [0, 1], Strictness.normal), isNull);
      expect(matchStroke(t.strokes[1], t.strokes, [0, 1], Strictness.lenient)!.index, 1);
      expect(matchStroke(t.strokes[0], t.strokes, [0, 1], Strictness.normal)!.index, 0);
      expect(matchStroke(t.strokes[0].reversed.toList(), t.strokes, [0, 1], Strictness.lenient), isNull, reason: 'the wrong way');
    });

    test('stars come from the neatest and roughest strokes; many tries keep at most two', () {
      expect(starsFor([1, 2], Strictness.normal), 3);
      expect(starsFor([1, 8], Strictness.normal), 2);
      expect(starsFor([1, 12], Strictness.normal), 1);
      expect(starsFor([1, 2], Strictness.normal, misses: 3), 2);
      expect(starsFor(const [], Strictness.normal), 0);
    });

    test('the help fades as a letter is written right, and comes back after trouble', () {
      var g = pet();
      expect(g.glyphs['T'], isNull);
      for (final (n, guide) in [(1, 0), (2, 1), (3, 1), (4, 2)]) {
        g = g.wrote('T', 3, day);
        expect(g.glyphs['T']!.streak, n);
        expect(g.glyphs['T']!.guide, guide, reason: 'after $n');
      }
      g = g.wrote('T', 2, day, misses: 3);
      expect(g.glyphs['T']!.guide, 1, reason: 'back a level');
      expect(g.glyphs['T']!.misses, 3);
      expect(g.missed('T', 2).glyphs['T']!.misses, 5);
      expect(g.glyphs['T']!.lastAt, day);
    });
  });

  group('on the page', () {
    Future<(TestApp, Offset Function(Offset))> open(WidgetTester tester, String id, Game game) async {
      final app = await TestApp.start(tester, game: game);
      app.go('/write/$id');
      await app.settle(600);
      final page = tester.getRect(find.byKey(const ValueKey('page')));
      final fit = GlyphFit(glyphBook.byId[id]!, page.size);
      return (app, (Offset p) => page.topLeft + fit.toScreen(p));
    }

    Future<void> stroke(WidgetTester tester, List<Offset> points) async {
      final g = await tester.startGesture(points.first);
      for (final p in points.skip(1)) {
        await g.moveTo(p);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await tester.pump(const Duration(milliseconds: 100));
    }

    WritePainter painter(WidgetTester tester) => tester.widget<CustomPaint>(find.byKey(const ValueKey('page'))).painter! as WritePainter;

    testWidgets('a learned letter opens at writing, with as much help as it needs', (tester) async {
      final (app, _) = await open(tester, 'T', pet(glyphs: {'T': const GlyphProgress(best: 2, right: 3, streak: 2)}));
      expect(painter(tester).step, Step.write);
      expect(painter(tester).guide, 1);
      expect(app.voice.said.first, '${Strings.sayZh(glyphBook.byId['T']!)}。${Strings.writeYourself}|${Strings.sayEn(glyphBook.byId['T']!)}');
      await app.end();
    });

    testWidgets('a new letter still starts by watching', (tester) async {
      final (app, _) = await open(tester, 'T', pet());
      expect(painter(tester).step, Step.watch);
      await app.end();
    });

    testWidgets('one stroke at a time: a wrong one fades alone, taps do not count, the road comes after three tries', (tester) async {
      final t = glyphBook.byId['T']!;
      final (app, at) = await open(tester, 'T', pet(glyphs: {'T': const GlyphProgress(best: 1, right: 1)}));
      Future<void> write(List<Offset> s) => stroke(tester, [for (final p in s) at(p)]);

      // The top of the T, right: it stays, and the green dot moves on.
      await write(t.strokes[0]);
      expect(painter(tester).done.keys, [0]);
      expect(painter(tester).current, 1);
      expect(app.sounds.played.last, Sfx.strokeDone);

      // A tap somewhere: nothing at all.
      app.sounds.played.clear();
      await tester.tapAt(at(const Offset(10, 80)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(app.sounds.played, isEmpty);
      expect(painter(tester).done.keys, [0]);

      // The stem written upwards: only it fades; the top stays.
      await write(t.strokes[1].reversed.toList());
      expect(painter(tester).done.keys, [0]);
      expect(painter(tester).fading, isNotNull);
      expect(painter(tester).hint, 1, reason: 'the pet shows that stroke again');
      expect(find.text(Strings.followArrow), findsOneWidget);
      expect(painter(tester).road, isFalse);

      // Two more tries the wrong way: the road shows for that stroke.
      await write(t.strokes[1].reversed.toList());
      await write(t.strokes[1].reversed.toList());
      expect(painter(tester).road, isTrue);
      expect(find.bySemanticsLabel(Strings.traceAgain), findsOneWidget);

      // Then right: the letter is done, with the tries remembered.
      await write(t.strokes[1]);
      await app.settle(300);
      expect(find.text(Strings.great), findsOneWidget);
      expect(app.game.glyphs['T']!.right, 2);
      expect(app.game.glyphs['T']!.misses, 3);
      expect(app.game.glyphs['T']!.best, inInclusiveRange(1, 2));
      await app.end();
    });

    testWidgets('lenient lets the strokes come in any order', (tester) async {
      final t = glyphBook.byId['T']!;
      final (app, at) = await open(tester, 'T', pet(glyphs: {'T': const GlyphProgress(best: 1, right: 1)}, strictness: Strictness.lenient));
      await stroke(tester, [for (final p in t.strokes[1]) at(p)]);
      await stroke(tester, [for (final p in t.strokes[0]) at(p)]);
      await app.settle(300);
      expect(find.text(Strings.great), findsOneWidget);
      await app.end();
    });

    testWidgets('leaving after a few tries still tells parents it was hard', (tester) async {
      final t = glyphBook.byId['T']!;
      final (app, at) = await open(tester, 'T', pet(glyphs: {'T': const GlyphProgress(best: 1, right: 1, streak: 2)}));
      await stroke(tester, [for (final p in t.strokes[0].reversed) at(p)]);
      await stroke(tester, [for (final p in t.strokes[0].reversed) at(p)]);
      app.go('/home');
      await app.settle(300);
      expect(app.game.glyphs['T']!.misses, 2);
      expect(app.game.glyphs['T']!.streak, 1);
      await app.end();
    });
  });
}
