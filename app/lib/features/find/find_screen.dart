import 'dart:async';
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
import '../pet/pet_view.dart';

/// Which characters to play with: the ones written right so far (digits and
/// capitals), topped up from the start of the order so there are always a
/// few to choose between.
List<Glyph> findPool(GlyphBook book, Map<String, int> best, {int least = 6}) {
  final all = [for (final g in book.all) if (g.kind != GlyphKind.warmup) g];
  final pool = [for (final g in all) if ((best[g.id] ?? 0) > 0) g];
  for (final g in all) {
    if (pool.length >= least) break;
    if (!pool.contains(g)) pool.add(g);
  }
  return pool;
}

/// One round: the character to find among [blocks].
class FindRound {
  FindRound(this.target, this.blocks);

  final Glyph target;
  final List<Glyph> blocks;

  /// [rounds] rounds from [pool]: different targets where it can, each
  /// among three or four others.
  static List<FindRound> deal(List<Glyph> pool, math.Random r, {int rounds = 5, int blocks = 4}) {
    final targets = [...pool]..shuffle(r);
    return [
      for (var i = 0; i < rounds; i++)
        () {
          final t = targets[i % targets.length];
          final others = [for (final g in pool) if (g.id != t.id) g]..shuffle(r);
          return FindRound(t, [t, ...others.take(blocks - 1)]..shuffle(r));
        }(),
    ];
  }
}

/// Finding letters (找字母): the pet hid letter blocks around its home and
/// asks for one at a time. A wrong block just says what it is; five found
/// and the pet is very happy. Reading practice next to the writing.
class FindScreen extends ConsumerStatefulWidget {
  const FindScreen({super.key, this.random});

  final math.Random? random;

  @override
  ConsumerState<FindScreen> createState() => _FindScreenState();
}

class _FindScreenState extends ConsumerState<FindScreen> with TickerProviderStateMixin {
  late final Sounds _sounds;
  late final _random = widget.random ?? math.Random();
  late List<FindRound> _rounds;
  var _round = 0;
  String? _found;
  String? _wobble;
  var _finished = false;
  var _happy = false;
  late final _wobbleCtl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  Timer? _next;

  @override
  void initState() {
    super.initState();
    _sounds = ref.read(soundsProvider);
    _sounds.hold(this, Music.play);
    _deal();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ask());
  }

  @override
  void dispose() {
    _next?.cancel();
    _wobbleCtl.dispose();
    _sounds.release(this);
    super.dispose();
  }

  void _deal() {
    final g = ref.read(gameProvider);
    final pool = findPool(ref.read(glyphBookProvider), {for (final e in g.glyphs.entries) e.key: e.value.best});
    _rounds = FindRound.deal(pool, _random);
    _round = 0;
    _finished = false;
    _found = null;
  }

  FindRound get _now => _rounds[_round];

  void _say(String zh, {String? en}) {
    if (mounted && ref.read(gameProvider).settings.voice) ref.read(voiceProvider).say(zh, en: en);
  }

  void _ask() {
    final t = _now.target;
    if (t.kind == GlyphKind.digit) {
      _say('${Strings.findAsk}${t.zh}');
    } else {
      _say(Strings.findAsk, en: t.show);
    }
  }

  void _tap(Glyph g) {
    if (_found != null || _finished) return;
    if (g.id != _now.target.id) {
      _sounds.play(Sfx.oops);
      setState(() => _wobble = g.id);
      _wobbleCtl.forward(from: 0);
      if (g.kind == GlyphKind.digit) {
        _say(Strings.thisIs(g).replaceFirst(g.show, g.zh));
      } else {
        _say('這是', en: g.show);
      }
      return;
    }
    _sounds.play(Sfx.star);
    setState(() {
      _found = g.id;
      _happy = true;
    });
    _say(Strings.findRight);
    _next = Timer(const Duration(milliseconds: 1300), () {
      if (!mounted) return;
      if (_round + 1 >= _rounds.length) {
        _sounds.play(Sfx.celebrate);
        ref.read(gameProvider.notifier).change((g, now) => g.cuddled(now, 0.3));
        setState(() => _finished = true);
        _say(Strings.allFound);
        return;
      }
      setState(() {
        _round++;
        _found = null;
        _happy = false;
      });
      _ask();
    });
  }

  @override
  Widget build(BuildContext context) {
    final g = ref.watch(gameProvider);
    final species = g.species;
    final art = species == null ? null : ref.watch(petArtProvider)[species];
    final round = _now;
    return Scaffold(
      body: Stack(children: [
        if (species != null) Positioned.fill(child: Art('homes/${species.name}', fit: BoxFit.cover)),
        SafeArea(
          child: LayoutBuilder(builder: (context, box) {
            final w = box.maxWidth, h = box.maxHeight;
            final block = math.min(w * 0.3, 128.0);
            // Four places spread over the upper part, a little crooked.
            final spots = [
              Offset(w * 0.27, h * 0.27),
              Offset(w * 0.73, h * 0.23),
              Offset(w * 0.3, h * 0.5),
              Offset(w * 0.72, h * 0.48),
            ];
            return Stack(children: [
              Positioned(
                left: 12,
                top: 8,
                child: CornerButton(label: Strings.home, icon: Icons.home_rounded, onTap: () => context.pop()),
              ),
              Positioned(
                left: 80,
                right: 16,
                top: 12,
                child: Row(children: [
                  Expanded(child: Bubble(_finished ? Strings.allFound : Strings.findAskShown(round.target), size: 22)),
                  const SizedBox(width: 10),
                  Text('${math.min(_round + (_found != null || _finished ? 1 : 0), _rounds.length)}／${_rounds.length}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Book.ink)),
                ]),
              ),
              if (!_finished)
                for (final (i, b) in round.blocks.indexed)
                  AnimatedPositioned(
                    key: ValueKey('block-${round.target.id}-${b.id}'),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeInBack,
                    left: (_found == b.id ? w / 2 : spots[i].dx) - block / 2,
                    top: (_found == b.id ? h * 0.78 : spots[i].dy) - block / 2,
                    width: block,
                    height: block,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 600),
                      opacity: _found == b.id ? 0.0 : 1.0,
                      child: AnimatedBuilder(
                        animation: _wobbleCtl,
                        builder: (_, child) => Transform.rotate(
                          angle: (_wobble == b.id ? math.sin(_wobbleCtl.value * math.pi * 5) * 0.2 * (1 - _wobbleCtl.value) : 0) + (i.isEven ? -0.06 : 0.07),
                          child: child,
                        ),
                        child: _Block(glyph: b, onTap: () => _tap(b)),
                      ),
                    ),
                  ),
              if (art != null)
                Positioned(
                  left: w / 2 - math.min(w * 0.42, 190) / 2,
                  bottom: _finished ? 140 : 20,
                  child: PetView(art: art, width: math.min(w * 0.42, 190), mood: _happy || _finished ? Mood.happy : Mood.open),
                ),
              if (_finished)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 30,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    BookButton(
                      label: Strings.playAgain,
                      icon: const Icon(Icons.replay_rounded, color: Book.ink, size: 36),
                      color: Book.blue,
                      line: Book.blueLine,
                      onTap: () {
                        setState(_deal);
                        _ask();
                      },
                    ),
                    const SizedBox(width: 20),
                    BookButton(label: Strings.home, icon: const Icon(Icons.home_rounded, color: Book.ink, size: 36), onTap: () => context.pop()),
                  ]),
                ),
            ]);
          }),
        ),
      ]),
    );
  }
}

/// A wooden letter block with its character on it.
class _Block extends StatelessWidget {
  const _Block({required this.glyph, required this.onTap});

  final Glyph glyph;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        button: true,
        label: glyph.show,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          child: LayoutBuilder(
            builder: (context, box) => Stack(alignment: Alignment.center, children: [
              const Positioned.fill(child: Art('items/block')),
              Padding(
                padding: EdgeInsets.only(top: box.maxHeight * 0.06),
                child: Text(glyph.show, style: TextStyle(fontSize: box.maxHeight * 0.48, fontWeight: FontWeight.w700, color: Book.coralLine)),
              ),
            ]),
          ),
        ),
      );
}
