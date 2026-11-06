import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart' hide Step;
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/glyphs.dart';
import '../../core/pets.dart';
import '../../core/providers.dart';
import '../../core/sounds.dart';
import '../../core/voice.dart';
import '../../core/writing.dart';
import '../home/meters.dart';
import '../pet/pet_view.dart';
import 'glyph_painter.dart';

/// Writing one character in four steps: watch it written, tap where each
/// stroke starts, trace along the road, then write it alone. The pet sits
/// in the corner and cheers.
class WriteScreen extends ConsumerStatefulWidget {
  const WriteScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<WriteScreen> createState() => _WriteScreenState();
}

class _WriteScreenState extends ConsumerState<WriteScreen> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _clock = ValueNotifier<double>(0);
  double get _t => _clock.value;

  late Glyph _glyph;
  var _step = Step.watch;
  double _watchStart = 0;
  int _tapped = 0;
  List<Tracer> _tracers = [];
  int _current = 0;

  // Step 4, a stroke at a time.
  final _done = <int, List<Offset>>{};
  final _errors = <double>[];
  List<Offset>? _live;
  List<Offset>? _fading;
  double _fadeStart = 0;
  int _strokeMisses = 0, _misses = 0;
  bool _road = false;
  int _guide = 0;
  bool _firstStep = true;
  int? _hint;
  double _hintStart = 0;
  int? _stars;
  bool _hatchedNow = false;
  late final GameNotifier _game;

  Size _canvas = Size.zero;
  int? _pointer;
  Timer? _nextStep;
  double _jumpAt = -10, _happyUntil = 0;
  String? _say;
  double _sayUntil = 0, _lastNudge = -10;

  @override
  void initState() {
    super.initState();
    _sounds = ref.read(soundsProvider);
    _voiceOut = ref.read(voiceProvider);
    _game = ref.read(gameProvider.notifier);
    _glyph = ref.read(glyphBookProvider).byId[widget.id] ?? ref.read(glyphBookProvider).all.first;
    final progress = ref.read(gameProvider).glyphs[_glyph.id];
    _guide = progress?.guide ?? 0;
    // A letter already learned starts at writing; the steps above go back.
    final start = (progress?.right ?? 0) > 0 ? Step.write : Step.watch;
    _ticker = createTicker((e) {
      _clock.value = e.inMicroseconds / 1e6;
      if (_step == Step.watch && _watched >= _glyph.strokes.length && _nextStep == null) {
        _nextStep = Timer(const Duration(milliseconds: 700), () => _go(Step.tap));
      }
      if (_say != null && _t > _sayUntil) setState(() => _say = null);
    })
      ..start();
    _sounds.hold(this, Music.write);
    WidgetsBinding.instance.addPostFrameCallback((_) => _go(start));
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clock.dispose();
    _nextStep?.cancel();
    // Tries that did not end in a letter still tell parents what is hard.
    if (_stars == null && _misses > 0) {
      final game = _game, id = _glyph.id, misses = _misses;
      // After this frame: providers cannot change while widgets are torn down.
      Future.microtask(() => game.change((g, _) => g.missed(id, misses)));
    }
    _sounds.release(this);
    _voiceOut.stop();
    super.dispose();
  }

  late final Sounds _sounds;
  late final Voice _voiceOut;
  bool get _talks => ref.read(gameProvider).hatched && ref.read(gameProvider).stage.index >= Stage.toddler.index;

  double get _watched => (_t - _watchStart) / 0.9;

  void _voice(String zh, {String? en}) {
    if (ref.read(gameProvider).settings.voice) ref.read(voiceProvider).say(zh, en: en);
  }

  /// The pet (once it can talk) or a bubble says [s].
  void _bubble(String s, [double seconds = 2.4]) {
    setState(() {
      _say = s;
      _sayUntil = _t + seconds;
    });
  }

  void _go(Step step) {
    if (!mounted) return;
    _nextStep?.cancel();
    _nextStep = null;
    final first = _firstStep;
    _firstStep = false;
    setState(() {
      _step = step;
      _hint = null;
      _current = 0;
      _stars = null;
      _done.clear();
      _errors.clear();
      _live = null;
      _fading = null;
      _road = false;
      _strokeMisses = 0;
      switch (step) {
        case Step.watch:
          _watchStart = _t;
        case Step.tap:
          _tapped = 0;
        case Step.trace:
          _tracers = [for (final s in _glyph.strokes) Tracer(s)];
        case Step.write:
          _misses = 0;
      }
    });
    switch (step) {
      case Step.watch:
        _voice(Strings.sayZh(_glyph), en: Strings.sayEn(_glyph));
      case Step.tap:
        _voice(Strings.tapStars);
        if (_talks) _bubble(Strings.startAtStar);
      case Step.trace:
        _voice(Strings.traceRoad);
      case Step.write:
        // Straight to writing: say what it is first.
        if (first) {
          _voice('${Strings.sayZh(_glyph)}。${Strings.writeYourself}', en: Strings.sayEn(_glyph));
        } else {
          _voice(Strings.writeYourself);
        }
        if (_talks) _bubble(Strings.cheers[math.Random().nextInt(Strings.cheers.length)]);
    }
  }

  /// The template strokes not written yet, in order.
  List<int> get _open => [for (var i = 0; i < _glyph.strokes.length; i++) if (!_done.containsKey(i)) i];

  // --- The finger on the page --------------------------------------------

  GlyphFit get _fit => GlyphFit(_glyph, _canvas);

  void _down(PointerDownEvent e) {
    if (_pointer != null || _stars != null) return; // one finger; no palms
    _pointer = e.pointer;
    final p = _fit.toGlyph(e.localPosition);
    switch (_step) {
      case Step.watch:
        break;
      case Step.tap:
        final s = _glyph.strokes[_tapped];
        if ((p - s.first).distance < 22) {
          _sounds.play(Sfx.star);
          setState(() => _tapped++);
          if (_tapped == _glyph.strokes.length) {
            _nextStep = Timer(const Duration(milliseconds: 600), () => _go(Step.trace));
          }
        } else {
          _nudge(Strings.startAtStar);
        }
      case Step.trace:
        if (_current >= _tracers.length) return;
        if (!_tracers[_current].down(p)) _nudge(_tracers[_current].progress == 0 ? Strings.startAtDot : Strings.backOnRoad);
        setState(() {});
      case Step.write:
        setState(() {
          _hint = null;
          _live = [p];
        });
    }
  }

  void _move(PointerMoveEvent e) {
    if (e.pointer != _pointer) return;
    final p = _fit.toGlyph(e.localPosition);
    switch (_step) {
      case Step.trace:
        if (_current >= _tracers.length) return;
        final tr = _tracers[_current];
        tr.move(p);
        if (tr.offRoad) _nudge(Strings.backOnRoad);
        if (tr.done) _strokeTraced();
        setState(() {});
      case Step.write:
        final live = _live;
        if (live == null) return;
        if ((p - live.last).distance >= 1.2) live.add(p);
        setState(() {});
      case Step.watch || Step.tap:
        break;
    }
  }

  void _up(PointerEvent e) {
    if (e.pointer != _pointer) return;
    _pointer = null;
    switch (_step) {
      case Step.trace:
        if (_current < _tracers.length) _tracers[_current].up();
      case Step.write:
        final drawn = _live;
        setState(() => _live = null);
        if (drawn != null) _strokeWritten(drawn);
      case Step.watch || Step.tap:
        break;
    }
  }

  void _nudge(String s) {
    if (_t - _lastNudge < 2.5) return;
    _lastNudge = _t;
    _sounds.play(Sfx.oops);
    _bubble(s, 2);
    _voice(s);
  }

  void _strokeTraced() {
    _sounds.play(Sfx.strokeDone);
    _tracers[_current].up();
    _current++;
    if (_current < _tracers.length) return;
    _sounds.play(Sfx.letterDone);
    _jumpAt = _t;
    _happyUntil = _t + 1.2;
    ref.read(gameProvider.notifier).change((g, now) => g.traced(_glyph.id, now));
    _nextStep = Timer(const Duration(milliseconds: 1000), () => _go(Step.write));
  }

  /// A stroke written in step 4, checked the moment the finger lifts.
  void _strokeWritten(List<Offset> drawn) {
    final open = _open;
    if (open.isEmpty || _stars != null) return;
    final strokes = _glyph.strokes;
    // A tap or a tiny dot is not a stroke: nothing happens.
    if (isTap(drawn, strokes[open.first])) return;
    final strictness = ref.read(gameProvider).settings.strictness;
    final match = matchStroke(drawn, strokes, open, strictness);
    if (match != null) {
      setState(() {
        _done[match.index] = drawn;
        _errors.add(match.check.error);
        _strokeMisses = 0;
        _road = false;
        _fading = null;
      });
      if (_open.isEmpty) {
        _letterWritten();
      } else {
        _sounds.play(Sfx.strokeDone);
      }
      return;
    }
    // Not yet: only this stroke fades away; the pet shows it once more.
    final want = strokes[open.first];
    final c = checkStroke(drawn, want, strictness);
    // Written from the far end: the way round, not where to start, is what to say.
    final reversed = (drawn.first - want.last).distance < (drawn.first - want.first).distance && (drawn.last - want.first).distance < strictness.start * 1.5;
    final say = reversed || (c.startOk && !c.directionOk) ? Strings.followArrow : (!c.startOk ? Strings.startAtDot : Strings.oneMore);
    _sounds.play(Sfx.oops);
    setState(() {
      _fading = drawn;
      _fadeStart = _t;
      _strokeMisses++;
      _misses++;
      _hint = open.first;
      _hintStart = _t;
      if (_strokeMisses >= 3) _road = true;
    });
    final line = _road && _strokeMisses == 3 ? Strings.alongRoad : say;
    _bubble(line, 2.5);
    _voice(line);
  }

  void _letterWritten() {
    final g = ref.read(gameProvider);
    final stars = starsFor(_errors, g.settings.strictness, misses: _misses);
    final hatches = !g.hatched;
    _game.change((g, now) => g.wrote(_glyph.id, stars, now, misses: _misses));
    _sounds.play(Sfx.letterDone);
    Timer(const Duration(milliseconds: 350), () => _sounds.play(Sfx.star));
    _jumpAt = _t;
    _happyUntil = _t + 2.5;
    setState(() {
      _stars = stars;
      _hatchedNow = hatches;
    });
    _voice(hatches ? Strings.eggMoved : Strings.great);
  }

  void _clear() {
    setState(() {
      _done.clear();
      _errors.clear();
      _live = null;
      _fading = null;
      _hint = null;
      _road = false;
      _strokeMisses = 0;
    });
  }

  String? get _nextId {
    final all = ref.read(glyphBookProvider).all;
    final i = all.indexWhere((x) => x.id == _glyph.id);
    return i >= 0 && i + 1 < all.length ? all[i + 1].id : null;
  }

  // --- Drawing ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final g = ref.watch(gameProvider);
    final left = g.settings.leftHanded;
    return Scaffold(
      body: Paper(
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(children: [
                CornerButton(label: Strings.back, icon: Icons.arrow_back_rounded, onTap: () => context.pop()),
                const Spacer(),
                for (final s in Step.values) _StepChip(step: s, on: s == _step, onTap: () => _go(s)),
                const Spacer(),
                const SizedBox(width: 56),
              ]),
            ),
            Expanded(
              child: LayoutBuilder(builder: (context, box) {
                _canvas = box.biggest;
                return Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: _down,
                  onPointerMove: _move,
                  onPointerUp: _up,
                  onPointerCancel: _up,
                  child: ValueListenableBuilder<double>(
                    valueListenable: _clock,
                    builder: (context, t, _) => CustomPaint(
                      key: const ValueKey('page'),
                      size: box.biggest,
                      painter: WritePainter(
                        glyph: _glyph,
                        step: _step,
                        t: t,
                        watched: _watched,
                        tapped: _tapped,
                        tracers: _tracers,
                        current: _step == Step.write ? (_open.firstOrNull ?? _glyph.strokes.length) : _current,
                        done: _done,
                        live: _live,
                        fading: _fading,
                        fade: ((t - _fadeStart) / 0.9).clamp(0, 1),
                        guide: _guide,
                        road: _road,
                        arrow: _guide < 2 || _strokeMisses > 0,
                        hint: _hint,
                        hintProgress: ((t - _hintStart) / 1.2).clamp(0, 1),
                        leftHanded: left,
                      ),
                    ),
                  ),
                );
              }),
            ),
            SizedBox(
              height: 140,
              child: Stack(clipBehavior: Clip.none, children: [
                // The pet keeps the child company, on the side away from the hand.
                Positioned(
                  left: left ? null : 12,
                  right: left ? 12 : null,
                  bottom: 8,
                  child: _Buddy(jumpAt: _jumpAt, happyUntil: _happyUntil, clock: _clock),
                ),
                if (_say != null)
                  Positioned(
                    left: left ? 16 : 120,
                    right: left ? 120 : 16,
                    top: 0,
                    child: Bubble(_say!, size: 18),
                  ),
                Positioned(
                  left: left ? 16 : null,
                  right: left ? null : 16,
                  bottom: 16,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (_step == Step.watch) BookButton(label: Strings.watchAgain, icon: const Icon(Icons.replay_rounded, color: Book.ink, size: 36), onTap: () => _go(Step.watch)),
                    if (_step == Step.write && _stars == null) ...[
                      if (_misses >= 3) ...[
                        BookButton(label: Strings.traceAgain, icon: const Icon(Icons.gesture_rounded, color: Book.ink, size: 36), color: Book.sage, line: Book.sageLine, onTap: () => _go(Step.trace)),
                        const SizedBox(width: 12),
                      ],
                      BookButton(label: Strings.clear, icon: const Icon(Icons.refresh_rounded, color: Book.ink, size: 36), color: Book.blue, line: Book.blueLine, onTap: _clear),
                    ],
                  ]),
                ),
              ]),
            ),
          ]),
        ),
      ),
      // How it went.
      bottomSheet: _stars == null ? null : _Result(stars: _stars!, hatched: _hatchedNow, onAgain: () => _go(Step.write), onNext: _nextId == null ? null : () => context.pushReplacement('/write/${Uri.encodeComponent(_nextId!)}'), onHome: () => context.go('/home')),
    );
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip({required this.step, required this.on, required this.onTap});

  final Step step;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = switch (step) {
      Step.watch => Strings.stepWatch,
      Step.tap => Strings.stepTap,
      Step.trace => Strings.stepTrace,
      Step.write => Strings.stepWrite,
    };
    return Semantics(
      container: true,
      button: true,
      selected: on,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: on ? 58 : 46,
          height: on ? 58 : 46,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? Book.mustard : Book.paperDeep,
            border: Border.all(color: on ? Book.mustardLine : Book.paperGrain, width: 2),
          ),
          child: Text(label, style: TextStyle(fontSize: on ? 26 : 20, fontWeight: FontWeight.w700, color: on ? Book.ink : Book.inkSoft)),
        ),
      ),
    );
  }
}

/// The pet in the corner (or its egg, before it hatches).
class _Buddy extends ConsumerWidget {
  const _Buddy({required this.jumpAt, required this.happyUntil, required this.clock});

  final double jumpAt;
  final double happyUntil;
  final ValueNotifier<double> clock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = ref.watch(gameProvider);
    final s = g.species;
    if (s == null) return const SizedBox.shrink();
    return ValueListenableBuilder<double>(
      valueListenable: clock,
      builder: (context, t, _) {
        final j = (t - jumpAt) / 0.45;
        final hop = j >= 0 && j <= 1 ? -math.sin(j * math.pi) * 26 : 0.0;
        if (!g.hatched || g.name == null) {
          return Transform.rotate(angle: math.sin(t * 2) * 0.06, alignment: Alignment.bottomCenter, child: SizedBox(width: 80, height: 100, child: Art('eggs/${s.name}')));
        }
        return Transform.translate(
          offset: Offset(0, hop),
          child: PetView(art: ref.watch(petArtProvider)[s], width: 104, mood: t < happyUntil ? Mood.happy : Mood.open, bib: g.stage == Stage.baby),
        );
      },
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.stars, required this.hatched, required this.onAgain, required this.onNext, required this.onHome});

  final int stars;
  final bool hatched;
  final VoidCallback onAgain;
  final VoidCallback? onNext;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        decoration: const BoxDecoration(
          color: Book.paperDeep,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 16)],
        ),
        child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(hatched ? Strings.eggMoved : Strings.great, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Book.ink)),
            const SizedBox(height: 8),
            Semantics(
              label: '$stars',
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                for (var i = 0; i < 3; i++) SizedBox(width: 56, height: 56, child: CustomPaint(painter: StarPainter(filled: i < stars))),
              ]),
            ),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (hatched)
                BookButton(label: Strings.home, icon: const Icon(Icons.egg_rounded, color: Book.ink, size: 40), color: Book.mustard, line: Book.mustardLine, size: 80, onTap: onHome)
              else ...[
                BookButton(label: Strings.again, icon: const Icon(Icons.replay_rounded, color: Book.ink, size: 36), color: Book.blue, line: Book.blueLine, onTap: onAgain),
                const SizedBox(width: 16),
                if (onNext != null) ...[
                  BookButton(label: Strings.next, icon: const Icon(Icons.arrow_forward_rounded, color: Book.ink, size: 36), color: Book.sage, line: Book.sageLine, onTap: onNext),
                  const SizedBox(width: 16),
                ],
                BookButton(label: Strings.home, icon: const Icon(Icons.home_rounded, color: Book.ink, size: 36), onTap: onHome),
              ],
            ]),
          ]),
        ),
      );
}
