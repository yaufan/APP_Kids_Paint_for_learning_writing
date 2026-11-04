import 'package:flutter_test/flutter_test.dart';
import 'package:letter_pets/core/game.dart';
import 'package:letter_pets/core/pets.dart';
import 'package:letter_pets/core/store.dart';
import 'package:letter_pets/core/writing.dart';

/// The pet's rules: hatching, stars and cookies, the feast, the hearts,
/// growing up, and keeping it all in the saved file.
void main() {
  final monday = DateTime(2026, 11, 2, 9);

  Game hatched() => const Game().pickEgg(Species.bunny).wrote('1', 3, monday).named('棉花');

  test('the first character written right hatches the egg', () {
    final egg = const Game().pickEgg(Species.dolphin);
    expect(egg.species, Species.dolphin);
    expect(egg.storyRead, isTrue);
    expect(egg.hatched, isFalse);
    expect(egg.pickEgg(Species.puppy).species, Species.dolphin, reason: 'one egg');
    final g = egg.wrote('L', 2, monday);
    expect(g.hatched, isTrue);
    expect(g.name, isNull, reason: 'named next');
    expect(g.named('  浪浪  ').name, '浪浪');
    expect(g.named('   ').name, isNull);
    expect(g.named('一二三四五六七八九十').name!.length, 8);
  });

  test('three stars make a cookie with the letter that finished it, and a cookie grows the pet a lot', () {
    var g = hatched();
    expect(g.stars, 1);
    g = g.wrote('T', 1, monday).wrote('F', 2, monday);
    expect(g.stars, 0);
    expect(g.cookies, ['F']);
    final before = g.growth;
    g = g.ateCookie(monday);
    expect(g.cookies, isEmpty);
    expect(g.growth - before, Growth.cookie);
    expect(Growth.cookie, greaterThanOrEqualTo(Growth.care * 10));
    expect(g.ateCookie(monday).growth, g.growth, reason: 'no cookie left');
  });

  test('each character remembers its best stars and how often it was right', () {
    final g = hatched().wrote('A', 1, monday).wrote('A', 3, monday).wrote('A', 2, monday).traced('A', monday);
    expect(g.glyphs['A']!.best, 3);
    expect(g.glyphs['A']!.right, 3);
    expect(g.glyphs['A']!.traced, 1);
    expect(g.suggest(['1', 'A', 'B', 'C']), 'B');
  });

  test('today\'s feast once the daily goal is reached, once a day', () {
    var g = hatched().copyWith(settings: const Settings(dailyGoal: 3));
    expect(g.feastReady(monday), isFalse);
    g = g.wrote('T', 1, monday).wrote('F', 1, monday);
    expect(g.today(monday).right, 3);
    expect(g.feastReady(monday), isTrue);
    final before = g.growth;
    g = g.hadFeast(monday);
    expect(g.growth - before, Growth.feast);
    expect(g.feastReady(monday), isFalse);
    expect(g.hadFeast(monday).growth, g.growth);
    final tuesday = monday.add(const Duration(days: 1));
    expect(g.feastReady(tuesday), isFalse, reason: 'a new day starts again');
    expect(g.today(tuesday).right, 0);
  });

  test('care grows the pet once an hour per tool, and fills its hearts', () {
    var g = hatched();
    final base = g.growth;
    g = g.care(Care.feed, monday).care(Care.feed, monday.add(const Duration(minutes: 10)));
    expect(g.growth - base, Growth.care, reason: 'feeding again soon is fine, but does not count twice');
    g = g.care(Care.ball, monday.add(const Duration(minutes: 11)));
    expect(g.growth - base, Growth.care * 2, reason: 'another tool counts');
    g = g.care(Care.feed, monday.add(const Duration(hours: 1, minutes: 1)));
    expect(g.growth - base, Growth.care * 3);

    // An egg does not grow from care.
    final egg = const Game().pickEgg(Species.puppy).care(Care.feed, monday);
    expect(egg.growth, 0);
  });

  test('the hearts run down slowly, never to nothing, and care brings them back', () {
    var g = hatched().care(Care.bath, monday).care(Care.feed, monday).care(Care.ball, monday);
    expect(g.heart(Heart.clean, monday), 1);
    final later = monday.add(const Duration(hours: 4));
    expect(g.heart(Heart.belly, later), inExclusiveRange(0.4, 0.9));
    final away = monday.add(const Duration(days: 9));
    for (final h in Heart.values) {
      expect(g.heart(h, away), closeTo(Heart.low, 1e-9), reason: 'it misses you, it is not ill');
    }
    g = g.care(Care.feed, away);
    expect(g.heart(Heart.belly, away), closeTo(Heart.low + 0.5, 1e-9));
  });

  test('it grows up stage by stage, as far as 0.1 goes', () {
    expect(Stage.of(0), Stage.baby);
    expect(Stage.of(99), Stage.baby);
    expect(Stage.of(100), Stage.toddler);
    expect(Stage.of(5000), Stage.last);
    var g = hatched();
    expect(g.grewUp, isFalse);
    g = g.copyWith(growth: 120);
    expect(g.stage, Stage.toddler);
    expect(g.grewUp, isTrue);
    expect(g.sawStage().grewUp, isFalse);
    expect(g.toNextStage, 1);
    expect(hatched().copyWith(growth: 50).toNextStage, closeTo(0.5, 1e-9));
  });

  test('about five right a day reaches toddler in about two days', () {
    var g = hatched();
    var day = monday;
    var days = 0;
    while (g.stage == Stage.baby && days < 10) {
      for (var i = 0; i < 5; i++) {
        g = g.wrote('A', 2, day);
      }
      while (g.cookies.isNotEmpty) {
        g = g.ateCookie(day);
      }
      g = g.hadFeast(day);
      for (final c in Care.values) {
        g = g.care(c, day);
      }
      days++;
      day = day.add(const Duration(days: 1));
    }
    expect(days, inInclusiveRange(2, 3));
  });

  test('everything comes back from the saved file; broken parts start fresh', () async {
    final g = hatched()
        .care(Care.feed, monday)
        .wrote('T', 3, monday)
        .wrote('F', 1, monday)
        .copyWith(settings: const Settings(strictness: Strictness.strict, leftHanded: true, music: false, dailyGoal: 7, full: false));
    final store = MemoryStore();
    store.write(g.toJson());
    final back = Game.fromJson(await store.read(), monday);
    expect(back.toJson(), g.toJson());
    expect(back.species, Species.bunny);
    expect(back.name, '棉花');
    expect(back.cookies, ['F']);
    expect(back.settings.strictness, Strictness.strict);
    expect(back.settings.leftHanded, isTrue);
    expect(back.lastCare[Care.feed], monday);

    final broken = Game.fromJson({'species': 'unicorn', 'growth': 'lots', 'glyphs': 3, 'settings': {'dailyGoal': 999}}..remove('growth'), monday);
    expect(broken.species, isNull);
    expect(broken.settings.dailyGoal, 20);
    expect(Game.fromJson(null, monday).storyRead, isFalse);
  });
}
