import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/glyphs.dart';
import '../../core/providers.dart';
import '../../core/sounds.dart';
import '../home/meters.dart';
import '../write/glyph_painter.dart';

/// Picking what to write: cards in rows from easy to hard; the ones learned
/// show their stars, and the next one to learn bounces.
class LettersScreen extends ConsumerStatefulWidget {
  const LettersScreen({super.key});

  @override
  ConsumerState<LettersScreen> createState() => _LettersScreenState();
}

class _LettersScreenState extends ConsumerState<LettersScreen> {
  final _next = GlobalKey();

  @override
  void initState() {
    super.initState();
    ref.read(soundsProvider).hold(this, Music.write);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(gameProvider).settings.voice) ref.read(voiceProvider).say(Strings.pickLetter);
      final c = _next.currentContext;
      if (c != null) Scrollable.ensureVisible(c, alignment: 0.4, duration: const Duration(milliseconds: 400));
    });
  }

  @override
  void dispose() {
    ref.read(soundsProvider).release(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final book = ref.watch(glyphBookProvider);
    final g = ref.watch(gameProvider);
    final next = g.suggest([for (final x in book.all) x.id]);
    return Scaffold(
      body: Paper(
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(children: [
                CornerButton(label: Strings.home, icon: Icons.home_rounded, onTap: () => context.pop()),
                const SizedBox(width: 12),
                const Expanded(child: Text(Strings.pickLetter, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Book.ink))),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  for (final group in book.groups) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
                      child: Text(Strings.groupLabel(group), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Book.inkSoft)),
                    ),
                    Wrap(spacing: 12, runSpacing: 12, children: [
                      for (final glyph in group.glyphs)
                        _Card(
                          key: glyph.id == next ? _next : null,
                          glyph: glyph,
                          stars: g.glyphs[glyph.id]?.best ?? 0,
                          next: glyph.id == next,
                          onTap: () => context.push('/write/${Uri.encodeComponent(glyph.id)}'),
                        ),
                    ]),
                  ],
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({super.key, required this.glyph, required this.stars, required this.next, required this.onTap});

  final Glyph glyph;
  final int stars;
  final bool next;
  final VoidCallback onTap;

  static const _colors = [
    (Book.peach, Book.peachLine),
    (Book.sage, Book.sageLine),
    (Book.blue, Book.blueLine),
    (Book.mustard, Book.mustardLine),
    (Book.lilac, Book.lilacLine),
    (Book.rose, Book.coralLine),
  ];

  @override
  Widget build(BuildContext context) {
    final (color, line) = _colors[glyph.id.codeUnitAt(0) % _colors.length];
    final card = Semantics(
      button: true,
      label: Strings.glyphLabel(glyph),
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: SizedBox(
          width: 98,
          height: 118,
          child: Wash(
            color: stars > 0 ? color : Color.lerp(color, Colors.white, 0.55)!,
            line: line,
            radius: 22,
            seed: glyph.id.hashCode,
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
            child: Column(children: [
              Expanded(child: CustomPaint(size: Size.infinite, painter: GlyphPainter(glyph, color: Book.ink, width: 9))),
              const SizedBox(height: 4),
              StarSlots(stars: stars, size: 20),
            ]),
          ),
        ),
      ),
    );
    return next ? Breathing(amount: 0.06, period: const Duration(milliseconds: 1000), child: card) : card;
  }
}
