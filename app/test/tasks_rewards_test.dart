import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:letter_pets/core/game.dart';
import 'package:letter_pets/core/pets.dart';
import 'package:letter_pets/core/store.dart';
import 'package:letter_pets/features/find/find_screen.dart';

import 'helpers.dart';

/// 0.2: today's tasks (one new, the rest to review), parents' rewards, and
/// dealing the find-the-letter rounds.
void main() {
  final monday = DateTime(2026, 11, 9, 9);
  final order = [for (final g in glyphBook.all) g.id];
  const pet = Game(storyRead: true, species: Species.bunny, hatched: true, name: '棉花');

  group('today\'s tasks', () {
    test('at first: the first new characters', () {
      final g = pet.withTasks(monday, order);
      expect(g.taskDay, dayOf(monday));
      expect(g.tasks, order.take(3).toList());
    });

    test('one new, then the learned ones with the fewest stars and the longest ago', () {
      var g = pet;
      g = g.wrote('line_v', 3, monday.subtract(const Duration(days: 3)));
      g = g.wrote('line_h', 1, monday.subtract(const Duration(days: 1)));
      g = g.wrote('circle', 1, monday.subtract(const Duration(days: 2)));
      g = g.withTasks(monday, order);
      expect(g.tasks, ['cross', 'circle', 'line_h']);
    });

    test('they stay the same all day, and change the next', () {
      var g = pet.withTasks(monday, order);
      final first = g.tasks;
      g = g.wrote(first.first, 3, monday);
      expect(g.withTasks(monday.add(const Duration(hours: 5)), order).tasks, first);
      expect(g.withTasks(monday.add(const Duration(days: 1)), order).tasks, isNot(first));
    });

    test('doing them all gives a star cookie, once', () {
      var g = pet.withTasks(monday, order);
      expect(g.tasksDone(monday), isEmpty);
      for (final id in g.tasks) {
        g = g.wrote(id, 2, monday);
      }
      expect(g.tasksDone(monday), g.tasks.toSet());
      expect(g.cookies.where((c) => c == Game.bonusCookie).length, 1);
      g = g.wrote(g.tasks.first, 2, monday);
      expect(g.cookies.where((c) => c == Game.bonusCookie).length, 1);
      expect(g.today(monday).tasksBonus, isTrue);
    });

    test('the number is the parent\'s', () {
      final g = pet.copyWith(settings: const Settings(dailyTasks: 5)).withTasks(monday, order);
      expect(g.tasks.length, 5);
    });
  });

  group('rewards', () {
    test('count from when they start, are reached, seen, given, and the next starts', () {
      var g = pet.wrote('1', 3, monday).wrote('0', 3, monday);
      g = g.addReward(RewardGoal.right, 3, '週末去公園', 'park').addReward(RewardGoal.days, 2, '吃冰淇淋', 'ice_cream');
      final park = g.currentReward!;
      expect(park.text, '週末去公園');
      expect(g.progress(park), 0, reason: 'what was written before does not count');
      expect(g.rewards[1].from, isNull, reason: 'the second waits its turn');

      for (var i = 0; i < 3; i++) {
        g = g.wrote('7', 2, monday);
      }
      expect(g.currentReward!.reachedAt, monday);
      expect(g.rewardToShow!.id, park.id);
      g = g.sawReward(park.id, monday);
      expect(g.rewardToShow, isNull);
      expect(g.currentReward!.id, park.id, reason: 'until the parent gives it');

      g = g.redeem(park.id, monday);
      final cream = g.currentReward!;
      expect(cream.text, '吃冰淇淋');
      expect(cream.from, 1, reason: 'one day practised so far');
      g = g.wrote('4', 1, monday.add(const Duration(days: 1)));
      expect(g.progress(g.currentReward!), 1);
      g = g.wrote('4', 1, monday.add(const Duration(days: 2)));
      expect(g.rewardToShow!.text, '吃冰淇淋');
    });

    test('learned means three stars', () {
      var g = pet.addReward(RewardGoal.learned, 2, '故事書', 'book');
      g = g.wrote('L', 2, monday).wrote('T', 3, monday);
      expect(g.progress(g.currentReward!), 1);
      g = g.wrote('L', 3, monday);
      expect(g.currentReward!.reachedAt, isNotNull);
    });

    test('removing the current one starts the next', () {
      var g = pet.addReward(RewardGoal.right, 5, 'A', 'toy').addReward(RewardGoal.right, 5, 'B', 'hug');
      g = g.removeReward(g.rewards.first.id);
      expect(g.currentReward!.text, 'B');
      expect(g.currentReward!.from, 0);
    });

    test('they are saved', () async {
      final g = pet.addReward(RewardGoal.days, 7, '去動物園', 'park').withTasks(monday, order).wrote('1', 3, monday);
      final store = MemoryStore()..write(g.toJson());
      final back = Game.fromJson(await store.read(), monday);
      expect(back.toJson(), g.toJson());
      expect(back.rewards.single.text, '去動物園');
      expect(back.tasks, g.tasks);
      expect(back.today(monday).glyphs, ['1']);
    });
  });

  group('finding letters', () {
    test('plays with the characters learned, topped up to six', () {
      expect(findPool(glyphBook, const {}).map((g) => g.id), ['1', '0', '7', '4', '6', '9']);
      final pool = findPool(glyphBook, const {'A': 2, 'B': 1, 'C': 3, 'D': 1, 'E': 1, 'F': 1, 'G': 1});
      expect(pool.map((g) => g.id).toSet(), {'A', 'B', 'C', 'D', 'E', 'F', 'G'});
    });

    test('five rounds, each target among three others', () {
      final rounds = FindRound.deal(findPool(glyphBook, const {}), math.Random(1));
      expect(rounds.length, 5);
      for (final r in rounds) {
        expect(r.blocks.length, 4);
        expect(r.blocks.where((b) => b.id == r.target.id).length, 1);
        expect(r.blocks.map((b) => b.id).toSet().length, 4);
      }
      expect(rounds.map((r) => r.target.id).toSet().length, 5, reason: 'different targets');
    });
  });
}
