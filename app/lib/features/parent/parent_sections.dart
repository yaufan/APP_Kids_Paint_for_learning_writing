import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/game.dart';
import '../../core/glyphs.dart';
import '../../core/providers.dart';
import '../home/meters.dart';

/// Progress for parents: the last seven days, every character's stars, and
/// the characters that are often written the wrong way.
class ProgressDetails extends ConsumerWidget {
  const ProgressDetails({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = ref.watch(gameProvider);
    final now = ref.watch(clockProvider)();
    final book = ref.watch(glyphBookProvider);
    var weekRight = 0, weekDays = 0;
    for (var i = 0; i < 7; i++) {
      final d = g.days[dayOf(now.subtract(Duration(days: i)))];
      if (d == null) continue;
      weekRight += d.right;
      if (d.right > 0) weekDays++;
    }
    final wrong = [for (final x in book.all) if ((g.glyphs[x.id]?.misses ?? 0) > 0) x]
      ..sort((a, b) => g.glyphs[b.id]!.misses.compareTo(g.glyphs[a.id]!.misses));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${Strings.thisWeek}：${Strings.weekLine(weekRight, weekDays)}', style: const TextStyle(fontSize: 17)),
      const SizedBox(height: 4),
      Text(Strings.daysPracticed(g.count(RewardGoal.days)), style: const TextStyle(fontSize: 17)),
      const SizedBox(height: 12),
      Text(Strings.oftenWrong, style: const TextStyle(fontSize: 15, color: Book.inkSoft, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      if (wrong.isEmpty)
        const Text(Strings.noneWrong, style: TextStyle(fontSize: 16, color: Book.inkSoft))
      else
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final x in wrong.take(6))
            Chip(
              key: ValueKey('wrong-${x.id}'),
              label: Text('${Strings.glyphLabel(x)}  ×${g.glyphs[x.id]!.misses}', style: const TextStyle(fontSize: 16)),
              backgroundColor: Book.paper,
            ),
        ]),
      const SizedBox(height: 12),
      Text(Strings.eachLetter, style: const TextStyle(fontSize: 15, color: Book.inkSoft, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final x in book.all)
          if (x.kind != GlyphKind.warmup)
            Container(
              width: 58,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(color: Book.paper, borderRadius: BorderRadius.circular(10)),
              child: Column(children: [
                Text(x.show, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                StarSlots(stars: g.glyphs[x.id]?.best ?? 0, size: 15),
              ]),
            ),
      ]),
      const SizedBox(height: 8),
    ]);
  }
}

/// The parent's rewards: the list in order, and adding one.
class RewardsEditor extends ConsumerWidget {
  const RewardsEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = ref.watch(gameProvider);
    final game = ref.read(gameProvider.notifier);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text(Strings.rewardsNote, style: TextStyle(fontSize: 14, height: 1.5, color: Book.inkSoft)),
      const SizedBox(height: 8),
      for (final r in g.rewards)
        ListTile(
          key: ValueKey('reward-${r.id}'),
          contentPadding: EdgeInsets.zero,
          leading: SizedBox(width: 44, height: 44, child: Art('rewards/${r.icon}')),
          title: Text(r.text, style: TextStyle(fontSize: 17, decoration: r.redeemedAt != null ? TextDecoration.lineThrough : null)),
          subtitle: Text('${Strings.goalShort(r.goal, r.target)}・${Strings.rewardState(r, g.progress(r))}', style: const TextStyle(fontSize: 13, color: Book.inkSoft)),
          trailing: r.redeemedAt != null
              ? null
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  if (r.reachedAt != null)
                    FilledButton(
                      key: ValueKey('redeem-${r.id}'),
                      onPressed: () => game.change((g, now) => g.redeem(r.id, now)),
                      child: const Text(Strings.redeem),
                    ),
                  IconButton(
                    key: ValueKey('remove-${r.id}'),
                    tooltip: Strings.remove,
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () => game.change((g, _) => g.removeReward(r.id)),
                  ),
                ]),
        ),
      const SizedBox(height: 6),
      OutlinedButton.icon(
        key: const ValueKey('add-reward'),
        onPressed: () async {
          final added = await showDialog<Reward>(context: context, builder: (_) => const _NewReward());
          if (added != null) game.change((g, _) => g.addReward(added.goal, added.target, added.text, added.icon));
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text(Strings.addReward),
      ),
      const SizedBox(height: 8),
    ]);
  }
}

class _NewReward extends StatefulWidget {
  const _NewReward();

  @override
  State<_NewReward> createState() => _NewRewardState();
}

class _NewRewardState extends State<_NewReward> {
  var _goal = RewardGoal.right;
  var _target = 30;
  var _icon = 'park';
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text(Strings.addReward),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(Strings.rewardGoal, style: TextStyle(fontSize: 14, color: Book.inkSoft)),
            Wrap(spacing: 6, children: [
              for (final goal in RewardGoal.values)
                ChoiceChip(
                  key: ValueKey('goal-${goal.name}'),
                  label: Text(Strings.goalName(goal)),
                  selected: _goal == goal,
                  onSelected: (_) => setState(() => _goal = goal),
                ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              const Text(Strings.rewardCount, style: TextStyle(fontSize: 14, color: Book.inkSoft)),
              const Spacer(),
              IconButton(key: const ValueKey('target-less'), icon: const Icon(Icons.remove_circle_outline), onPressed: _target > 1 ? () => setState(() => _target -= _target > 10 ? 5 : 1) : null),
              Text('$_target', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              IconButton(key: const ValueKey('target-more'), icon: const Icon(Icons.add_circle_outline), onPressed: () => setState(() => _target += _target >= 10 ? 5 : 1)),
            ]),
            TextField(key: const ValueKey('reward-text'), controller: _text, decoration: const InputDecoration(labelText: Strings.rewardText), maxLength: 20),
            const Text(Strings.rewardIcon, style: TextStyle(fontSize: 14, color: Book.inkSoft)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final id in Reward.icons)
                GestureDetector(
                  key: ValueKey('icon-$id'),
                  onTap: () => setState(() => _icon = id),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _icon == id ? Book.coralLine : Book.paperGrain, width: _icon == id ? 3 : 1),
                    ),
                    child: Column(children: [
                      SizedBox(width: 44, height: 44, child: Art('rewards/$id')),
                      Text(Strings.rewardIconName(id), style: const TextStyle(fontSize: 12)),
                    ]),
                  ),
                ),
            ]),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text(Strings.cancel)),
          FilledButton(
            key: const ValueKey('save-reward'),
            onPressed: () {
              final text = _text.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(context, Reward(id: 0, goal: _goal, target: _target, text: text, icon: _icon));
            },
            child: const Text(Strings.ok),
          ),
        ],
      );
}
