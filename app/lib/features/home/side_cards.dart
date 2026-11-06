import 'package:flutter/material.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/game.dart';
import '../../core/glyphs.dart';
import '../write/glyph_painter.dart';

/// Today's tasks on the pet's home: the characters the pet asks for, each
/// ticked when written right today. Tapping one goes to write it.
class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.tasks, required this.done, required this.onTap});

  final List<Glyph> tasks;
  final Set<String> done;
  final void Function(Glyph g) onTap;

  @override
  Widget build(BuildContext context) => Wash(
        color: Book.paper,
        line: Book.paperGrain,
        radius: 20,
        seed: 3,
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(width: 30, height: 30, child: Art('items/task')),
          for (final g in tasks) ...[
            const SizedBox(height: 6),
            Semantics(
              container: true,
              button: true,
              label: Strings.task(g),
              excludeSemantics: true,
              child: Pressable(
                onTap: () => onTap(g),
                child: SizedBox(
                  width: 60,
                  height: 56,
                  child: Stack(children: [
                    Positioned.fill(
                      child: Wash(
                        color: done.contains(g.id) ? Book.sage : Book.paperDeep,
                        line: done.contains(g.id) ? Book.sageLine : Book.paperGrain,
                        radius: 14,
                        seed: g.id.hashCode,
                        padding: const EdgeInsets.all(7),
                        child: CustomPaint(size: Size.infinite, painter: GlyphPainter(g, color: Book.ink, width: 11)),
                      ),
                    ),
                    if (done.contains(g.id))
                      const Positioned(right: -2, top: -2, child: Icon(Icons.check_circle_rounded, color: Book.goLine, size: 22)),
                  ]),
                ),
              ),
            ),
          ],
        ]),
      );
}

/// The gift box with how far the current reward is.
class GiftCard extends StatelessWidget {
  const GiftCard({super.key, required this.reward, required this.progress});

  final Reward reward;
  final int progress;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: '${Strings.gift} ${Strings.giftProgress(progress, reward.target)}',
        excludeSemantics: true,
        child: Wash(
          color: Book.paper,
          line: Book.paperGrain,
          radius: 20,
          seed: 5,
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Breathing(amount: 0.04, child: SizedBox(width: 52, height: 52, child: Art(reward.reachedAt != null ? 'items/giftOpen' : 'items/giftClosed'))),
            Text(Strings.giftProgress(progress.clamp(0, reward.target), reward.target),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Book.ink)),
          ]),
        ),
      );
}

/// A small round button with a picture (the sticker book, finding letters).
class SmallArtButton extends StatelessWidget {
  const SmallArtButton({super.key, required this.label, required this.art, required this.onTap, this.color = Book.paper, this.line = Book.paperGrain});

  final String label;
  final String art;
  final VoidCallback onTap;
  final Color color;
  final Color line;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        button: true,
        label: label,
        excludeSemantics: true,
        onTap: onTap,
        child: Pressable(
          onTap: onTap,
          child: SizedBox(
            width: 58,
            height: 58,
            child: Wash(color: color, line: line, radius: 29, seed: label.hashCode, padding: const EdgeInsets.all(9), child: Art(art)),
          ),
        ),
      );
}
