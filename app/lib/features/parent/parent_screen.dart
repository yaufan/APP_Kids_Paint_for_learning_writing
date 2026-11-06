import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/version.dart';
import '../../core/providers.dart';
import '../../core/writing.dart';
import 'parent_sections.dart';

/// Parent mode (after the gate): how it is going, and the settings.
/// Rewards and the fuller progress pages come in 0.2.
class ParentScreen extends ConsumerWidget {
  const ParentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = ref.watch(gameProvider);
    final now = ref.watch(clockProvider)();
    final book = ref.watch(glyphBookProvider);
    final s = g.settings;
    final game = ref.read(gameProvider.notifier);
    final learned = book.all.where((x) => (g.glyphs[x.id]?.best ?? 0) > 0).length;

    Widget section(String title, List<Widget> children) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 15, color: Book.inkSoft, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                ...children,
              ]),
            ),
          ),
        );

    Widget toggle(String label, bool value, void Function(bool) set, {String? note, Key? key}) => SwitchListTile(
          key: key,
          contentPadding: EdgeInsets.zero,
          title: Text(label, style: const TextStyle(fontSize: 17)),
          subtitle: note == null ? null : Text(note, style: const TextStyle(fontSize: 13, color: Book.inkSoft)),
          value: value,
          onChanged: set,
        );

    return Scaffold(
      backgroundColor: Book.parentBg,
      appBar: AppBar(
        backgroundColor: Book.parentBg,
        title: const Text(Strings.parentTitle),
        leading: IconButton(icon: const Icon(Icons.close_rounded), tooltip: Strings.back, onPressed: () => context.pop()),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
        section(Strings.progress, [
          Text(g.species == null ? Strings.noPet : Strings.petLine(g.name ?? g.species!.zh, g.species!, g.stage), style: const TextStyle(fontSize: 17)),
          const SizedBox(height: 4),
          Text(Strings.todayRight(g.today(now).right, s.dailyGoal), style: const TextStyle(fontSize: 17)),
          const SizedBox(height: 4),
          Text(Strings.learned(learned, book.all.length), style: const TextStyle(fontSize: 17)),
          const SizedBox(height: 4),
          Text(Strings.allRight(g.totalRight), style: const TextStyle(fontSize: 17)),
          const SizedBox(height: 8),
          const ProgressDetails(),
        ]),
        section(Strings.rewards, const [RewardsEditor()]),
        section(Strings.writing, [
          const Text(Strings.strictness, style: TextStyle(fontSize: 17)),
          RadioGroup<Strictness>(
            groupValue: s.strictness,
            onChanged: (v) => game.settings((x) => x.copyWith(strictness: v)),
            child: Column(children: [
              for (final level in Strictness.values)
                RadioListTile<Strictness>(
                  key: ValueKey('strictness-${level.name}'),
                  contentPadding: EdgeInsets.zero,
                  value: level,
                  title: Text(Strings.strictnessName(level), style: const TextStyle(fontSize: 16)),
                ),
            ]),
          ),
          toggle(Strings.leftHanded, s.leftHanded, (v) => game.settings((x) => x.copyWith(leftHanded: v)), note: Strings.leftHandedNote, key: const ValueKey('left-handed')),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(Strings.dailyGoal, style: TextStyle(fontSize: 17)),
            subtitle: Text(Strings.goalCount(s.dailyGoal), style: const TextStyle(fontSize: 13, color: Book.inkSoft)),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                key: const ValueKey('goal-less'),
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: s.dailyGoal > 1 ? () => game.settings((x) => x.copyWith(dailyGoal: x.dailyGoal - 1)) : null,
              ),
              Text('${s.dailyGoal}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              IconButton(
                key: const ValueKey('goal-more'),
                icon: const Icon(Icons.add_circle_outline),
                onPressed: s.dailyGoal < 20 ? () => game.settings((x) => x.copyWith(dailyGoal: x.dailyGoal + 1)) : null,
              ),
            ]),
          ),
        ]),
        section(Strings.dailyTasks, [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(Strings.dailyTasks, style: TextStyle(fontSize: 17)),
            subtitle: Text(Strings.tasksCount(s.dailyTasks), style: const TextStyle(fontSize: 13, color: Book.inkSoft)),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                key: const ValueKey('tasks-less'),
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: s.dailyTasks > 1 ? () => game.settings((x) => x.copyWith(dailyTasks: x.dailyTasks - 1)) : null,
              ),
              Text('${s.dailyTasks}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              IconButton(
                key: const ValueKey('tasks-more'),
                icon: const Icon(Icons.add_circle_outline),
                onPressed: s.dailyTasks < 5 ? () => game.settings((x) => x.copyWith(dailyTasks: x.dailyTasks + 1)) : null,
              ),
            ]),
          ),
        ]),
        section(Strings.sound, [
          toggle(Strings.music, s.music, (v) => game.settings((x) => x.copyWith(music: v)), key: const ValueKey('music')),
          toggle(Strings.effects, s.sounds, (v) => game.settings((x) => x.copyWith(sounds: v)), key: const ValueKey('effects')),
          toggle(Strings.voice, s.voice, (v) => game.settings((x) => x.copyWith(voice: v)), key: const ValueKey('voice')),
        ]),
        section(Strings.edition, [
          const Text(Strings.fullNote, style: TextStyle(fontSize: 14, height: 1.5, color: Book.inkSoft)),
          toggle(Strings.fullTest, s.full, (v) => game.settings((x) => x.copyWith(full: v)), key: const ValueKey('full')),
        ]),
        section(Strings.about, [
          Text(Strings.version(appVersion), style: const TextStyle(fontSize: 17)),
          const SizedBox(height: 4),
          const Text(Strings.privacy, style: TextStyle(fontSize: 14, height: 1.5, color: Book.inkSoft)),
          const SizedBox(height: 8),
        ]),
      ]),
    );
  }
}
