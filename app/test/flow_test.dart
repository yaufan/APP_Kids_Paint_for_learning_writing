import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:letter_pets/app/strings.dart';
import 'package:letter_pets/core/game.dart';
import 'package:letter_pets/core/pets.dart';
import 'package:letter_pets/core/sounds.dart';
import 'package:letter_pets/features/write/glyph_painter.dart';

import 'helpers.dart';

/// The whole first visit, on a phone and on a tablet: the story, an egg,
/// the first character written in four steps, the egg hatching, a name,
/// care, a cookie, the feast, growing up and parent mode. Screenshots go
/// to `build/screenshots/<device>/`.
void main() {
  for (final (device, size, ratio, species) in [
    ('phone', const Size(1080, 2340), 2.75, Species.puppy),
    ('tablet', const Size(1600, 2560), 2.0, Species.octopus),
  ]) {
    testWidgets('$device: from the story to a grown-up ${species.name}', (tester) async {
      await tester.runAsync(loadFonts);
      final app = await TestApp.start(tester, size: size, ratio: ratio);
      Future<void> shot(String name) => shoot(tester, device, name);

      // The story opens like a picture book.
      expect(find.text(Strings.storyPages.first), findsOneWidget);
      expect(app.voice.said.first, Strings.storyPages.first);
      await shot('01_story');
      for (var i = 0; i < Strings.storyPages.length; i++) {
        await app.tapLabel(Strings.turnPage, ms: 700);
      }
      expect(find.text(Strings.pickEgg), findsWidgets);
      await app.tapLabel(Strings.eggOf(species));
      await shot('02_eggs');
      await app.tapLabel(Strings.takeHome(species), ms: 800);
      expect(app.game.species, species);
      expect(app.store.saved!['species'], species.name, reason: 'saved straight away');

      // At home the egg waits for the first character.
      expect(find.text(Strings.eggHint), findsOneWidget);
      await shot('03_egg_home');
      await app.tapLabel(Strings.write, ms: 600);
      expect(app.sounds.music, Music.write);
      await shot('04_letters');

      // Writing 1: watch, tap the star, trace the road, write it alone.
      await app.tapLabel('1', ms: 600);
      final page = tester.getRect(find.byKey(const ValueKey('page')));
      final glyph = glyphBook.byId['1']!;
      final fit = GlyphFit(glyph, page.size);
      Offset at(Offset p) => page.topLeft + fit.toScreen(p);
      final stroke = glyph.strokes.single;
      await app.settle(500);
      expect(app.voice.said.last, '一|1');
      await shot('05_watch');
      await app.settle(1200);
      expect(find.bySemanticsLabel(Strings.stepTap), findsOneWidget);
      await shot('06_tap');
      await tester.tapAt(at(stroke.first));
      await app.settle(900);
      expect(app.sounds.played, contains(Sfx.star));

      // Tracing: off the road it waits; back on the road it goes on.
      final finger = await tester.startGesture(at(stroke.first));
      for (var i = 1; i < stroke.length ~/ 2; i++) {
        await finger.moveTo(at(stroke[i]));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await shot('07_trace');
      await finger.moveTo(at(stroke[stroke.length ~/ 2]) + Offset(fit.scale * 60, 0));
      await app.settle(100);
      expect(find.text(Strings.backOnRoad), findsOneWidget);
      for (var i = stroke.length ~/ 2; i < stroke.length; i++) {
        await finger.moveTo(at(stroke[i]));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await finger.up();
      await app.settle(1400);
      expect(app.game.glyphs['1']!.traced, 1);

      // Now alone: from the green dot, down.
      final pen = await tester.startGesture(at(stroke.first) + const Offset(3, 2));
      for (var i = 1; i < stroke.length; i++) {
        await pen.moveTo(at(stroke[i]) + Offset(2.0 * (i % 3), 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await pen.up();
      await app.settle(1400);
      expect(app.game.hatched, isTrue);
      expect(app.game.stars, 1);
      expect(find.text(Strings.eggMoved), findsWidgets);
      await shot('08_written');

      // Home: the egg hatches with three taps, and gets a name.
      await app.tapLabel(Strings.home, ms: 800);
      expect(find.text(Strings.hatching), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const ValueKey('hatch-egg')));
        await app.settle(300);
      }
      expect(app.sounds.played.where((s) => s == Sfx.crack).length, 3);
      await app.settle(1200);
      await shot('09_hatched');
      await app.settle(1600);
      expect(find.text(Strings.nameIt), findsWidgets);
      await app.tapLabel(species.names.first, ms: 800);
      expect(app.game.name, species.names.first);
      expect(app.voice.said.last, Strings.hi(species.names.first));
      await shot('10_home');

      // A tap makes it jump and call; three quick taps make it giggle.
      final pet = tester.getCenter(find.byType(Scaffold).first) + Offset(-size.width / ratio * 0.06, size.height / ratio * 0.12);
      app.sounds.played.clear();
      await tester.tapAt(pet);
      await app.settle(500);
      expect(app.sounds.played, contains(Sfx.callOf(species)));
      for (var i = 0; i < 3; i++) {
        await tester.tapAt(pet);
        await tester.pump(const Duration(milliseconds: 120));
      }
      await app.settle(300);
      expect(app.sounds.played, contains(Sfx.giggle));

      // Food goes to its mouth by itself when the bowl is tapped.
      final growth = app.game.growth;
      await app.tapLabel(Strings.careName('feed'), ms: 900);
      expect(app.sounds.played, contains(Sfx.chew));
      expect(app.game.growth, growth + Growth.care);
      await shot('11_fed');
      expect(app.sounds.music, Music.play);

      // Bath: soap (or bubbles in the sea), then rinse.
      await app.tapLabel(Strings.careName(species.sea ? 'bubbles' : 'bath'), ms: 400);
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      if (!species.sea) {
        expect(find.bySemanticsLabel(Strings.rinse), findsWidgets);
        await shot('12_soap');
        await app.tapLabel(Strings.rinse, ms: 400);
        for (var i = 0; i < 16; i++) {
          await tester.pump(const Duration(milliseconds: 250));
        }
        expect(find.bySemanticsLabel(Strings.rinse), findsNothing);
      } else {
        await shot('12_bubbles');
      }
      expect(app.game.lastCare.keys, contains(Care.bath));

      // A ball to chase.
      await app.tapLabel(Strings.careName(species.sea ? 'bubbleBall' : 'ball'), ms: 900);
      await shot('13_ball');
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(app.game.lastCare.keys, contains(Care.ball));

      // Lights out, and good morning.
      await app.tapLabel(Strings.careName('sleep'), ms: 2500);
      expect(app.sounds.music, Music.sleep);
      await shot('14_sleep');
      await app.tapLabel(Strings.careName('wake'), ms: 600);
      expect(app.sounds.music, Music.play);

      // A letter cookie (three stars) and today's feast.
      app.change((g) => g.copyWith(cookies: ['A', 'B'], days: {dayOf(app.now): const DayLog(right: 5)}));
      await app.settle(600);
      expect(find.bySemanticsLabel(Strings.feast), findsOneWidget);
      await shot('15_cookie_feast');
      final beforeCookie = app.game.growth;
      await app.tapLabel(Strings.cookieWith('A'), ms: 1000);
      expect(app.game.cookies, ['B']);
      expect(app.game.growth, beforeCookie + Growth.cookie);
      await app.tapLabel(Strings.feast, ms: 900);
      expect(app.game.today(app.now).feast, isTrue);
      await shot('16_feast');
      await app.settle(4000);

      // Growing up to toddler.
      app.change((g) => g.copyWith(growth: Stage.toddler.from));
      await app.settle(800);
      expect(find.text(Strings.grewUp(species.names.first, Stage.toddler)), findsOneWidget);
      await shot('17_grew_up');
      await app.tapLabel(Strings.yay, ms: 600);
      expect(app.game.grewUp, isFalse);
      await shot('18_toddler');

      // Parent mode, behind the gate.
      await app.tapLabel(Strings.parent, ms: 600);
      expect(find.text(Strings.parentGateTitle), findsOneWidget);
      await shot('19_gate');
      final question = tester.widget<Text>(find.textContaining('等於多少')).data!;
      const zh = ['零', '一', '二', '三', '四', '五', '六', '七', '八', '九'];
      final parts = RegExp(r'(\S) 加 (\S)').firstMatch(question)!;
      final answer = zh.indexOf(parts.group(1)!) + zh.indexOf(parts.group(2)!);
      for (final d in '$answer'.split('')) {
        await tester.tap(find.byKey(ValueKey('gate-key-$d')));
        await tester.pump();
      }
      await app.settle(800);
      expect(find.text(Strings.parentTitle), findsOneWidget);
      await shot('20_parent');
      await tester.tap(find.byKey(const ValueKey('strictness-strict')));
      await app.settle(300);
      expect(app.game.settings.strictness.name, 'strict');
      await tester.dragUntilVisible(find.byKey(const ValueKey('full')), find.byType(ListView), const Offset(0, -200));
      await app.settle(300);
      await shot('21_parent_more');

      await app.end();
    }, timeout: const Timeout(Duration(minutes: 6)));
  }
}
