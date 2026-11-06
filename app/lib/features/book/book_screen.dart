import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/glyphs.dart';
import '../../core/providers.dart';
import '../../core/sounds.dart';

/// The sticker book (字母圖鑑): a picture card for each digit and capital.
/// A character written right shows its card; three stars make it shiny.
class BookScreen extends ConsumerStatefulWidget {
  const BookScreen({super.key});

  @override
  ConsumerState<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends ConsumerState<BookScreen> {
  late final Sounds _sounds;
  Glyph? _open;

  @override
  void initState() {
    super.initState();
    _sounds = ref.read(soundsProvider);
    _sounds.hold(this, Music.homeOf(ref.read(gameProvider).species));
    WidgetsBinding.instance.addPostFrameCallback((_) => _say(Strings.bookHint));
  }

  @override
  void dispose() {
    _sounds.release(this);
    super.dispose();
  }

  void _say(String zh, {String? en}) {
    if (mounted && ref.read(gameProvider).settings.voice) ref.read(voiceProvider).say(zh, en: en);
  }

  void _tap(Glyph g, int stars) {
    if (stars == 0) {
      _sounds.play(Sfx.tap);
      _say(Strings.locked(g));
      return;
    }
    _sounds.play(Sfx.pop);
    setState(() => _open = g);
    _say(Strings.sayZh(g), en: Strings.sayEn(g));
  }

  @override
  Widget build(BuildContext context) {
    final book = ref.watch(glyphBookProvider);
    final g = ref.watch(gameProvider);
    final groups = [for (final x in book.groups) if (x.glyphs.first.kind != GlyphKind.warmup) x];
    final got = [for (final x in groups) ...x.glyphs].where((x) => (g.glyphs[x.id]?.best ?? 0) > 0).length;
    final all = [for (final x in groups) ...x.glyphs].length;
    return Scaffold(
      body: Paper(
        child: SafeArea(
          child: Stack(children: [
            Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 16, 4),
                child: Row(children: [
                  CornerButton(label: Strings.home, icon: Icons.home_rounded, onTap: () => context.pop()),
                  const SizedBox(width: 12),
                  const Expanded(child: Text(Strings.book, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Book.ink))),
                  Text('$got／$all', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Book.inkSoft)),
                ]),
              ),
              Expanded(
                child: ListView(padding: const EdgeInsets.fromLTRB(14, 6, 14, 30), children: [
                  for (final group in groups) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
                      child: Text(group.label, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Book.inkSoft)),
                    ),
                    Wrap(spacing: 10, runSpacing: 10, children: [
                      for (final x in group.glyphs)
                        StickerCard(glyph: x, stars: g.glyphs[x.id]?.best ?? 0, size: 104, onTap: () => _tap(x, g.glyphs[x.id]?.best ?? 0)),
                    ]),
                  ],
                ]),
              ),
            ]),
            if (_open case final o?)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _open = null),
                  child: ColoredBox(
                    color: Book.ink.withValues(alpha: 0.35),
                    child: Center(
                      child: StickerCard(glyph: o, stars: g.glyphs[o.id]?.best ?? 0, size: 280, big: true, onTap: () => _tap(o, g.glyphs[o.id]?.best ?? 0)),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

/// One card: the picture with its character and word; a grey card with a
/// question mark until it is written right; a gold rim at three stars.
class StickerCard extends StatelessWidget {
  const StickerCard({super.key, required this.glyph, required this.stars, required this.size, required this.onTap, this.big = false});

  final Glyph glyph;
  final int stars;
  final double size;
  final bool big;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final got = stars > 0;
    final shiny = stars >= 3;
    final word = glyph.zh;
    return Semantics(
      container: true,
      button: true,
      label: got ? Strings.cardOf(glyph) : Strings.locked(glyph),
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        sound: null,
        child: SizedBox(
          width: size,
          height: size * 1.25,
          child: Wash(
            color: got ? (shiny ? const Color(0xFFFFF1C9) : Book.paper) : Book.paperDeep,
            line: shiny ? Book.mustardLine : Book.paperGrain,
            radius: size * 0.16,
            seed: glyph.id.hashCode,
            padding: EdgeInsets.all(size * 0.07),
            child: Column(children: [
              Expanded(
                child: got
                    ? _Picture(glyph: glyph)
                    : Center(child: Text('?', style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.w700, color: Book.paperGrain))),
              ),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(glyph.show, style: TextStyle(fontSize: size * 0.2, fontWeight: FontWeight.w700, color: got ? Book.coralLine : Book.paperGrain)),
                // A digit's Chinese numeral looks like a dash next to it: only words.
                if (got && glyph.kind == GlyphKind.capital) ...[
                  SizedBox(width: size * 0.05),
                  Flexible(child: Text(word, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: size * 0.13, fontWeight: FontWeight.w700, color: Book.ink))),
                ],
              ]),
              if (big && got && glyph.kind == GlyphKind.capital)
                Text(glyph.en, style: TextStyle(fontSize: size * 0.1, color: Book.inkSoft, fontWeight: FontWeight.w600)),
              if (shiny) Text(big ? Strings.shiny : '★★★', style: TextStyle(fontSize: size * (big ? 0.07 : 0.1), color: Book.mustardLine)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// A capital's word picture, or a digit's that many stars (an empty bowl
/// for zero).
class _Picture extends StatelessWidget {
  const _Picture({required this.glyph});

  final Glyph glyph;

  @override
  Widget build(BuildContext context) {
    final picture = glyph.picture;
    if (picture != null) return Art(picture);
    final n = int.tryParse(glyph.id) ?? 0;
    if (n == 0) return const Art('items/bowl');
    return LayoutBuilder(builder: (context, box) {
      final cols = n <= 3 ? n : (n <= 4 ? 2 : (n <= 6 ? 3 : (n <= 9 ? 3 : 4)));
      final rows = (n / cols).ceil();
      final s = math.min(box.maxWidth / cols, box.maxHeight / rows) * 0.9;
      return Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          children: [for (var i = 0; i < n; i++) SizedBox(width: s, height: s, child: const Art('items/star'))],
        ),
      );
    });
  }
}
