import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/game.dart';
import '../../core/pet_art.dart';
import '../../core/pets.dart';
import '../../core/providers.dart';
import '../../core/sounds.dart';
import '../parent/parent_gate.dart';
import '../pet/pet_view.dart';
import 'hatch.dart';
import 'meters.dart';
import 'particles.dart';
import 'reward_overlay.dart';
import 'side_cards.dart';

/// Things the child carries to the pet with a finger (or taps, and the
/// thing goes by itself).
enum Carry {
  food('items/bowl'),
  sponge('items/sponge'),
  shower('items/shower'),
  bubbles('items/bubbleBall'),
  brush('items/brush'),
  cookie('items/cookie');

  const Carry(this.art);

  final String art;
}

/// The pet's home (docs/design.md "寵物的家"): the pet in the middle, its
/// three hearts at the top, the care tools along the bottom and the big
/// 寫字 button. Before it hatches, the egg waits here.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _clock = ValueNotifier<double>(0);
  final _particles = Particles();
  double get _t => _clock.value;

  Size _screen = Size.zero;
  Rect _petRect = Rect.zero;
  final _tools = <Carry, Offset>{};
  Offset _growthAt = Offset.zero;

  // The finger.
  Offset? _finger;
  int? _pointer;
  Offset _downAt = Offset.zero;
  double _downTime = 0, _moved = 0, _rubbed = 0;
  bool _onPet = false, _cuddled = false;
  final _taps = <double>[];

  // What is being carried, or going by itself.
  Carry? _carry;
  Offset? _carryAt;
  double _carryStep = 0;
  ({Carry what, double start, Offset from})? _auto;
  int _autoSteps = 0;
  bool _soapy = false;
  int _brushed = 0;

  // The pet's moments.
  double _jumpAt = -10, _rollAt = -10, _happyUntil = 0, _chewUntil = 0, _wobbleAt = -10, _lastZ = 0;
  double? _ballAt;
  bool _sleeping = false;
  double? _feastOpenedAt;
  String? _say;
  double _sayUntil = 0;
  double _playUntil = 0;
  Music? _music;

  PetArt? get _art {
    final s = ref.read(gameProvider).species;
    return s == null ? null : ref.read(petArtProvider)[s];
  }

  @override
  void initState() {
    super.initState();
    _sounds = ref.read(soundsProvider);
    _ticker = createTicker(_tick)..start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Today's tasks are picked the first time the home opens each day.
      final order = [for (final x in ref.read(glyphBookProvider).all) x.id];
      _game.change((g, now) => g.withTasks(now, order));
      final g = ref.read(gameProvider);
      if (!g.hatched) _speak(Strings.eggHint, 4);
      if (g.feastReady(_now)) {
        _speak(Strings.feastReady, 3.5);
      } else if (g.today(_now).tasksBonus && g.cookies.contains(Game.bonusCookie)) {
        _speak(Strings.tasksDone, 3.5);
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clock.dispose();
    _sounds.release(this);
    super.dispose();
  }

  DateTime get _now => ref.read(clockProvider)();
  GameNotifier get _game => ref.read(gameProvider.notifier);
  late final Sounds _sounds;

  void _tick(Duration elapsed) {
    final t = elapsed.inMicroseconds / 1e6;
    _clock.value = t;
    _particles.step(t);
    if (_sleeping && t - _lastZ > 1.3) {
      _lastZ = t;
      final art = _art;
      if (art != null) _particles.zzz(_petRect.topLeft + art.head.scale(_k, _k) + Offset(art.headRadius * _k * 0.5, -art.headRadius * _k * 0.6), t);
    }
    final auto = _auto;
    if (auto != null) _runAuto(auto, t);
    final ball = _ballAt;
    if (ball != null && t - ball > 2.6) {
      _ballAt = null;
      _careDone(Care.ball);
    }
    _updateMusic();
    if (_say != null && t > _sayUntil) setState(() => _say = null);
  }

  double get _k {
    final art = _art;
    return art == null ? 1 : _petRect.width / art.size.width;
  }

  void _updateMusic() {
    final g = ref.read(gameProvider);
    final want = _sleeping ? Music.sleep : (_t < _playUntil ? Music.play : Music.homeOf(g.species));
    if (want == _music) return;
    _music = want;
    _sounds.hold(this, want);
  }

  void _speak(String text, [double seconds = 2.6]) {
    setState(() {
      _say = text;
      _sayUntil = _t + seconds;
    });
    if (ref.read(gameProvider).settings.voice) ref.read(voiceProvider).say(text);
  }

  // --- Where things are ---------------------------------------------------

  Offset _petLocal(Offset p) => (p - _petRect.topLeft) / _k;

  bool _hitsPet(Offset p) {
    final art = _art;
    if (art == null || !ref.read(gameProvider).hatched) return false;
    return art.hits(_petLocal(p));
  }

  Offset get _mouth {
    final art = _art!;
    return _petRect.topLeft + art.mouth * _k;
  }

  /// The pet's offset and turn right now: hopping, rolling, chasing.
  ({Offset shift, double turn, double scale}) _pose(double t) {
    var shift = Offset.zero;
    var turn = 0.0, scale = 1.0;
    final j = (t - _jumpAt) / 0.45;
    if (j >= 0 && j <= 1) shift += Offset(0, -math.sin(j * math.pi) * _petRect.height * 0.14);
    final r = (t - _rollAt) / 0.9;
    if (r >= 0 && r <= 1) {
      turn = math.sin(r * math.pi * 3) * 0.28;
      shift += Offset(0, -math.sin(r * math.pi) * 14);
    }
    if (t < _chewUntil) scale = 1 + 0.03 * math.sin(t * 22);
    final ball = _ballAt;
    if (ball != null) {
      final x = _ballX(t - ball);
      final want = ((x - _petRect.center.dx) * 0.7).clamp(-_screen.width * 0.28, _screen.width * 0.28);
      final ease = math.min(1.0, (t - ball) * 2) * math.min(1.0, (2.6 - (t - ball)) * 2.5).clamp(0, 1);
      shift += Offset(want * ease, -math.max(0, math.sin((t - ball) * 9)) * 10 * ease);
    }
    if (!_sleeping && _finger != null && _carry == null) {
      // Leans a little towards the finger.
      turn += ((_finger!.dx - _petRect.center.dx) / _screen.width).clamp(-0.5, 0.5) * 0.06;
    }
    return (shift: shift, turn: turn, scale: scale);
  }

  double _ballX(double age) => _screen.width + 40 - (_screen.width + 80) * (age / 2.4).clamp(0, 1);

  double _ballY(double age, bool sea) {
    final floor = _petRect.bottom - 30;
    if (sea) return floor - 120 - math.sin(age * 3) * 40;
    return floor - (math.sin(age * 7).abs() * 90 * math.max(0, 1 - age / 2.6));
  }

  // --- The finger ---------------------------------------------------------

  void _down(PointerDownEvent e) {
    if (_pointer != null) return; // a second finger or a palm
    _pointer = e.pointer;
    _finger = e.localPosition;
    _downAt = e.localPosition;
    _downTime = _t;
    _moved = 0;
    _rubbed = 0;
    _cuddled = false;
    _onPet = _carry == null && !_sleeping && _hitsPet(e.localPosition);
    if (_carry != null) _carryAt = e.localPosition + const Offset(0, -44);
    setState(() {});
  }

  void _move(PointerMoveEvent e) {
    if (e.pointer != _pointer) return;
    final step = (e.localPosition - (_finger ?? e.localPosition)).distance;
    _finger = e.localPosition;
    _moved += step;
    final carry = _carry;
    if (carry != null) {
      _carryAt = e.localPosition + const Offset(0, -44);
      _carryStep += step;
      if (_hitsPet(_carryAt!)) _useOnPet(carry, _carryAt!);
    } else if (_onPet) {
      _rubbed += step;
      if (_rubbed > 34) {
        _rubbed = 0;
        _particles.hearts(e.localPosition, _t, n: 1);
        _happyUntil = _t + 0.6;
        if (!_cuddled && _moved > 180) {
          _cuddled = true;
          _sounds.play(Sfx.happy);
          _game.change((g, now) => g.cuddled(now, 0.1));
        }
      }
    }
    setState(() {});
  }

  void _up(PointerEvent e) {
    if (e.pointer != _pointer) return;
    _pointer = null;
    final carry = _carry;
    final at = _carryAt;
    _carry = null;
    _carryAt = null;
    if (carry != null) {
      if (_moved < 14) {
        _startAuto(carry);
      } else if ((carry == Carry.food || carry == Carry.cookie) && at != null && _nearMouth(at)) {
        _eat(carry);
      } else if (!_hitsPetAny(at)) {
        _speak(carry == Carry.food || carry == Carry.cookie ? Strings.feedHint : Strings.dragHint);
      }
    } else if (_onPet && _moved < 16 && _t - _downTime < 0.4) {
      _tapPet();
    } else if (!ref.read(gameProvider).hatched && _eggRect.contains(_downAt) && _moved < 16) {
      _wobbleAt = _t;
      _sounds.play(Sfx.tap);
      _speak(Strings.eggHint, 3);
    }
    _finger = null;
    setState(() {});
  }

  bool _hitsPetAny(Offset? p) => p != null && _hitsPet(p);

  bool _nearMouth(Offset p) => (p - _mouth).distance < _art!.headRadius * _k * 0.9;

  Rect get _eggRect => Rect.fromCenter(center: _petRect.center + Offset(0, _petRect.height * 0.2), width: _petRect.width * 0.7, height: _petRect.height * 0.6);

  void _tapPet() {
    final g = ref.read(gameProvider);
    _taps.add(_t);
    _taps.removeWhere((x) => _t - x > 1.1);
    if (_taps.length >= 3) {
      _taps.clear();
      _rollAt = _t;
      _happyUntil = _t + 1.4;
      _sounds.play(Sfx.giggle);
      _particles.hearts(_petRect.center, _t, n: 4);
      _game.change((g, now) => g.cuddled(now, 0.1));
      return;
    }
    _jumpAt = _t;
    _happyUntil = _t + 0.8;
    _sounds.play(Sfx.callOf(g.species!));
    if (g.stage.index >= Stage.toddler.index && math.Random().nextInt(3) == 0) {
      _speak(math.Random().nextBool() ? Strings.hi(g.name ?? g.species!.zh) : Strings.cheers.first);
    }
  }

  // --- Care ---------------------------------------------------------------

  void _startCarry(Carry c, PointerDownEvent e) {
    if (_auto != null || _sleeping || _pointer != null) return;
    if (c == Carry.shower && !_soapy) return;
    _carry = c;
    _carryStep = 0;
    _brushed = 0;
  }

  void _useOnPet(Carry c, Offset at) {
    final k = _petRect;
    final local = Offset((at.dx - k.left) / k.width, (at.dy - k.top) / k.height);
    switch (c) {
      case Carry.sponge:
        if (_carryStep > 16) {
          _carryStep = 0;
          if (_particles.foamCount < 24) {
            _particles.foam(local, _t);
            if (_particles.foamCount % 4 == 0) _sounds.play(Sfx.bubbles);
          }
          if (_particles.foamCount >= 18 && !_soapy) {
            setState(() => _soapy = true);
            _speak(Strings.rinse, 2);
          }
        }
      case Carry.shower:
        if (_carryStep > 12) {
          _carryStep = 0;
          _particles.drops(at + const Offset(0, 20), 50, _t);
          _rinseNear(local);
        }
      case Carry.brush:
        if (_carryStep > 22) {
          _carryStep = 0;
          _particles.sparkles(at, _t, n: 2, spread: 40);
          _happyUntil = _t + 0.5;
          if (++_brushed == 10) _careDone(Care.brush);
        }
      case Carry.bubbles:
        if (_carryStep > 18) {
          _carryStep = 0;
          _particles.bubbles(at, _t, n: 2, spread: 30);
          if (++_brushed % 3 == 0) _sounds.play(Sfx.bubbles);
          if (_brushed == 12) _careDone(Care.bath);
        }
      case Carry.food || Carry.cookie:
        break;
    }
  }

  void _rinseNear(Offset local) {
    final foam = _particles.all.where((p) => p.kind == Bit.foam).toList();
    if (foam.isEmpty) return;
    foam.sort((a, b) => (a.at - local).distance.compareTo((b.at - local).distance));
    _particles.all.remove(foam.first);
    if (foam.length > 1) _particles.all.remove(foam[1]);
    _sounds.play(Sfx.rinse);
    if (_particles.foamCount == 0) {
      setState(() => _soapy = false);
      _careDone(Care.bath);
    }
  }

  void _startAuto(Carry c) {
    if (c == Carry.shower && !_soapy) return;
    _auto = (what: c, start: _t, from: _tools[c] ?? _petRect.center);
    _autoSteps = 0;
    _carryStep = 0;
    _brushed = 0;
  }

  /// A tool that was tapped does its job by itself.
  void _runAuto(({Carry what, double start, Offset from}) a, double t) {
    final age = t - a.start;
    final body = _petRect.center + Offset(0, _petRect.height * 0.12);
    switch (a.what) {
      case Carry.food || Carry.cookie:
        final p = (age / 0.6).clamp(0.0, 1.0);
        _carryAt = Offset.lerp(a.from, _mouth + const Offset(0, 10), Curves.easeInOut.transform(p))! + Offset(0, -math.sin(p * math.pi) * 60);
        if (p >= 1) {
          _endAuto();
          _eat(a.what);
        }
      case Carry.sponge || Carry.brush || Carry.bubbles || Carry.shower:
        final lift = (age / 0.35).clamp(0.0, 1.0);
        final scrub = body + Offset(math.sin(age * 9) * _petRect.width * 0.25, math.cos(age * 4) * _petRect.height * 0.15);
        final at = Offset.lerp(a.from, a.what == Carry.shower ? _petRect.topCenter + const Offset(0, -10) : scrub, Curves.easeOut.transform(lift))!;
        _carryAt = at;
        if (lift >= 1) {
          // A step of the job every so often, however fast the frames come.
          final want = ((age - 0.35) / (a.what == Carry.shower ? 0.12 : 0.08)).floor();
          while (_autoSteps < want && _auto != null) {
            _autoSteps++;
            if (a.what == Carry.shower) {
              _particles.drops(at + Offset(math.sin(_autoSteps * 1.7) * 30, 30), 70, t);
              final foam = _particles.all.where((p) => p.kind == Bit.foam).toList();
              if (foam.isNotEmpty) _rinseNear(foam.first.at);
            } else {
              _carryStep = 100;
              final jitter = Offset(math.sin(_autoSteps * 2.3), math.cos(_autoSteps * 1.3)) * _petRect.width * 0.18;
              _useOnPet(a.what, at + jitter);
            }
          }
        }
        final done = switch (a.what) {
          Carry.sponge => _soapy,
          Carry.shower => !_soapy,
          Carry.brush => _brushed >= 10,
          _ => _brushed >= 12,
        };
        if (done || age > 6) _endAuto();
    }
    setState(() {});
  }

  void _endAuto() {
    _auto = null;
    _carryAt = null;
  }

  void _eat(Carry c) {
    final g = ref.read(gameProvider);
    if (!g.hatched) return;
    _chewUntil = _t + 1.6;
    _happyUntil = _t + 1.8;
    _particles.crumbs(_mouth, _t);
    if (c == Carry.cookie) {
      _sounds.play(Sfx.cookie);
      _particles.sparkles(_mouth, _t, n: 8);
      final before = g.growth;
      _game.change((g, now) => g.ateCookie(now));
      if (ref.read(gameProvider).growth > before) _particles.sparkles(_growthAt, _t, n: 6, spread: 50);
    } else {
      _sounds.play(Sfx.chew);
      _careDone(Care.feed);
    }
    _playUntil = _t + 20;
  }

  void _careDone(Care c) {
    final before = ref.read(gameProvider).growth;
    _game.change((g, now) => g.care(c, now));
    _happyUntil = _t + 1.2;
    if (c != Care.sleep) _particles.sparkles(_petRect.center, _t, n: 6, spread: _petRect.width * 0.6);
    if (c != Care.feed) _sounds.play(Sfx.happy);
    if (ref.read(gameProvider).growth > before) _particles.sparkles(_growthAt, _t, n: 6, spread: 50);
    _playUntil = _t + 20;
  }

  void _throwBall() {
    if (_ballAt != null || _sleeping) return;
    _sounds.play(Sfx.ball);
    setState(() => _ballAt = _t);
  }

  void _sleep() {
    _sounds.play(Sfx.lightsOut);
    setState(() => _sleeping = true);
    _careDone(Care.sleep);
    _speak(Strings.goodNight, 2.5);
  }

  void _wake() {
    _sounds.play(Sfx.happy);
    setState(() => _sleeping = false);
    _jumpAt = _t;
    _speak(Strings.wakeUp, 2);
  }

  void _feast() {
    if (_feastOpenedAt != null) return;
    _sounds.play(Sfx.celebrate);
    _particles.confetti(_screen, _t);
    _chewUntil = _t + 2.6;
    _happyUntil = _t + 3;
    _jumpAt = _t + 0.3;
    setState(() => _feastOpenedAt = _t);
    _game.change((g, now) => g.hadFeast(now));
  }

  Future<void> _openParent() async {
    if (await showParentGate(context) && mounted) await context.push('/parent');
  }

  // --- Drawing ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final g = ref.watch(gameProvider);
    final species = g.species;
    if (species == null) return const Scaffold(body: SizedBox());
    final art = ref.watch(petArtProvider)[species];
    final now = _now;
    return Scaffold(
      body: LayoutBuilder(builder: (context, box) {
        _screen = box.biggest;
        final pad = MediaQuery.paddingOf(context);
        final w = box.maxWidth, h = box.maxHeight;
        final floor = h - pad.bottom - 128;
        final petW = math.min(w * 0.56, h * 0.31) * (g.stage == Stage.baby ? 0.84 : 1.0);
        final petH = petW * art.size.height / art.size.width;
        final petX = w * (w > 700 ? 0.5 : 0.44);
        _petRect = Rect.fromLTWH(petX - petW / 2, floor - petH, petW, petH);
        _growthAt = Offset(w - 70, pad.top + 30);
        final toolsY = h - pad.bottom - 58;
        final tools = species.sea ? [Carry.food, Carry.bubbles, Carry.brush] : [Carry.food, Carry.sponge, Carry.brush];
        final buttons = 5;
        for (var i = 0; i < tools.length; i++) {
          _tools[tools[i]] = Offset(w * (i + 0.5) / buttons, toolsY);
        }
        _tools[Carry.shower] = Offset(w * 0.5 / buttons + 6, toolsY - 96);
        final rightX = w - 16 - 96;
        final feast = g.feastReady(now) || (_feastOpenedAt != null && _t - _feastOpenedAt! < 4);

        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _down,
          onPointerMove: _move,
          onPointerUp: _up,
          onPointerCancel: _up,
          child: Stack(children: [
            Positioned.fill(child: Art('homes/${species.name}', fit: BoxFit.cover)),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedContainer(duration: const Duration(milliseconds: 700), color: _sleeping ? Book.night.withValues(alpha: 0.62) : Colors.transparent),
              ),
            ),
            // The pet (or its egg), its particles and what is carried.
            Positioned.fill(
              child: IgnorePointer(
                child: ValueListenableBuilder<double>(
                  valueListenable: _clock,
                  builder: (context, t, _) => _scene(g, art, t, species),
                ),
              ),
            ),
            if (feast)
              Positioned(
                left: _petRect.left - 70,
                top: floor - 96,
                width: 120,
                height: 100,
                child: Semantics(
                  container: true,
                  button: true,
                  label: Strings.feast,
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: _feast,
                    child: _feastOpenedAt == null
                        ? const Breathing(amount: 0.05, period: Duration(milliseconds: 1200), child: Art('items/feast_closed'))
                        : const Art('items/feast_open'),
                  ),
                ),
              ),
            // Top: the parent's corner, the hearts, how big it is growing.
            Positioned(
              left: 12,
              right: 12,
              top: pad.top + 8,
              child: Row(children: [
                Semantics(
                  container: true,
                  button: true,
                  label: Strings.parent,
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: _openParent,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: Book.paper.withValues(alpha: 0.8), shape: BoxShape.circle, border: Border.all(color: Book.paperGrain)),
                      child: const Icon(Icons.lock_outline_rounded, color: Book.inkSoft, size: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (g.hatched)
                  for (final heart in Heart.values) ...[
                    HeartMeter(heart: heart, level: g.heart(heart, now)),
                    const SizedBox(width: 4),
                  ],
                const Spacer(),
                if (g.hatched) GrowthBar(value: g.toNextStage),
              ]),
            ),
            // Left: today's tasks, the gift box, the sticker book and finding letters.
            if (g.hatched && g.name != null && !_sleeping)
              Positioned(
                left: 12,
                top: pad.top + 64,
                width: 84,
                child: Column(children: [
                  if (g.tasks.isNotEmpty)
                    TaskCard(
                      tasks: [for (final id in g.tasks) ?ref.read(glyphBookProvider).byId[id]],
                      done: g.tasksDone(now),
                      onTap: (x) => context.push('/write/${Uri.encodeComponent(x.id)}'),
                    ),
                  if (g.currentReward case final r?) ...[
                    const SizedBox(height: 10),
                    GiftCard(reward: r, progress: g.progress(r)),
                  ],
                  const SizedBox(height: 10),
                  SmallArtButton(label: Strings.book, art: 'items/book', onTap: () => context.push('/book')),
                  const SizedBox(height: 8),
                  SmallArtButton(label: Strings.find, art: 'items/magnifier', onTap: () => context.push('/find')),
                ]),
              ),
            // Right: write, the stars, the cookies.
            Positioned(
              left: rightX,
              top: pad.top + 76,
              width: 96,
              child: Column(children: [
                Wash(
                  color: Book.paper,
                  line: Book.paperGrain,
                  radius: 24,
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                  child: Column(children: [
                    _WriteButton(pulse: !g.hatched || g.today(now).right == 0, onTap: () => context.push('/letters')),
                    const SizedBox(height: 6),
                    StarSlots(stars: g.stars, size: 26),
                  ]),
                ),
                const SizedBox(height: 10),
                if (g.cookies.isNotEmpty && g.hatched)
                  Listener(
                    onPointerDown: (e) => _startCarry(Carry.cookie, e),
                    child: Semantics(
                      container: true,
                      button: true,
                      label: Strings.cookieWith(g.cookies.first),
                      excludeSemantics: true,
                      child: Builder(builder: (context) {
                        _tools[Carry.cookie] = Offset(rightX + 48, pad.top + 76 + 96 + 10 + 34 + 10 + 36);
                        return Opacity(
                          opacity: _carry == Carry.cookie || _auto?.what == Carry.cookie ? 0.3 : 1,
                          child: Column(children: [
                            Breathing(child: _Cookie(letter: g.cookies.first, size: 72)),
                            if (g.cookies.length > 1)
                              Text('× ${g.cookies.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Book.ink)),
                          ]),
                        );
                      }),
                    ),
                  ),
              ]),
            ),
            // Bottom: the care tools.
            if (g.hatched)
              Positioned(
                left: 0,
                right: 0,
                bottom: pad.bottom + 8,
                height: 104,
                child: Row(children: [
                  if (_sleeping) ...[
                    const Spacer(flex: 2),
                    Expanded(
                      child: Center(
                        child: BookButton(label: Strings.careName('wake'), icon: const Art('items/sun'), color: Book.mustard, line: Book.mustardLine, onTap: _wake),
                      ),
                    ),
                    const Spacer(flex: 2),
                  ] else ...[
                    for (final c in tools)
                      Expanded(
                        child: Center(
                          child: _CarryButton(
                            what: c,
                            label: Strings.careName(switch (c) {
                              Carry.food => 'feed',
                              Carry.sponge => 'bath',
                              Carry.bubbles => 'bubbles',
                              _ => 'brush',
                            }),
                            onDown: (e) => _startCarry(c, e),
                            away: _carry == c || _auto?.what == c,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Center(
                        child: BookButton(
                          label: Strings.careName(species.sea ? 'bubbleBall' : 'ball'),
                          icon: Art(species.sea ? 'items/bubbleBall' : 'items/ball'),
                          color: Book.blue,
                          line: Book.blueLine,
                          onTap: _ballAt == null ? _throwBall : null,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: BookButton(label: Strings.careName('sleep'), icon: const Art('items/moon'), color: Book.lilac, line: Book.lilacLine, onTap: _sleep),
                      ),
                    ),
                  ],
                ]),
              ),
            if (_soapy && !_sleeping)
              Positioned(
                left: _tools[Carry.shower]!.dx - 40,
                top: _tools[Carry.shower]!.dy - 40,
                child: _CarryButton(what: Carry.shower, label: Strings.rinse, onDown: (e) => _startCarry(Carry.shower, e), away: _carry == Carry.shower || _auto?.what == Carry.shower),
              ),
            if (_say != null)
              Positioned(
                left: 24,
                right: 120,
                top: math.max(pad.top + 70, _petRect.top - 90),
                child: IgnorePointer(child: Center(child: Bubble(_say!))),
              ),
            if (g.hatched && g.name == null) Positioned.fill(child: HatchOverlay(species: species)),
            if (g.grewUp && g.name != null) Positioned.fill(child: GrowUpOverlay(name: g.name!, stage: g.stage, art: art)),
            if (!g.grewUp && g.name != null && g.rewardToShow != null)
              Positioned.fill(child: RewardOverlay(reward: g.rewardToShow!, art: art)),
          ]),
        );
      }),
    );
  }

  Widget _scene(Game g, PetArt art, double t, Species species) {
    final children = <Widget>[];
    if (!g.hatched) {
      final wob = (t - _wobbleAt) < 0.7 ? math.sin((t - _wobbleAt) * 30) * 0.12 * (1 - (t - _wobbleAt) / 0.7) : math.sin(t * 1.4) * 0.025;
      final r = _eggRect;
      children.add(Positioned.fromRect(
        rect: r,
        child: Transform.rotate(angle: wob, alignment: Alignment.bottomCenter, child: Art('eggs/${species.name}')),
      ));
    } else if (g.name != null) {
      final pose = _pose(t);
      final mood = _sleeping ? Mood.sleep : (t < _happyUntil ? Mood.happy : Mood.open);
      final breathe = 1 + 0.012 * math.sin(t * 2.4);
      final look = _finger == null ? null : _finger! - (_petRect.topLeft + pose.shift);
      children.add(Positioned(
        left: _petRect.left + pose.shift.dx,
        top: _petRect.top + pose.shift.dy,
        width: _petRect.width,
        height: _petRect.height,
        child: Transform.rotate(
          angle: pose.turn,
          alignment: Alignment.bottomCenter,
          child: Transform.scale(
            scaleY: breathe * pose.scale,
            scaleX: pose.scale,
            alignment: Alignment.bottomCenter,
            child: PetView(art: art, width: _petRect.width, mood: mood, lookAt: look, bib: g.stage == Stage.baby),
          ),
        ),
      ));
      if (_sleeping) {
        children.add(Positioned(
          left: _petRect.left - _petRect.width * 0.08,
          top: _petRect.top + _petRect.height * 0.55,
          width: _petRect.width * 1.16,
          height: _petRect.height * 0.5,
          child: const Art('items/blanket', fit: BoxFit.fill),
        ));
      }
    }
    // A thrown ball.
    final ball = _ballAt;
    if (ball != null) {
      final age = t - ball;
      final x = _ballX(age), y = _ballY(age, species.sea);
      children.add(Positioned(
        left: x - 32,
        top: y - 32,
        width: 64,
        height: 64,
        child: Transform.rotate(angle: -age * 8, child: Art(species.sea ? 'items/bubbleBall' : 'items/ball')),
      ));
    }
    children.add(Positioned.fill(child: CustomPaint(painter: ParticlePainter(_particles, t, _petRect))));
    final carryAt = _carryAt;
    final what = _carry ?? _auto?.what;
    if (carryAt != null && what != null) {
      children.add(Positioned(
        left: carryAt.dx - 42,
        top: carryAt.dy - 42,
        width: 84,
        height: 84,
        child: what == Carry.cookie ? _Cookie(letter: g.cookies.firstOrNull ?? '', size: 84) : Art(what.art),
      ));
    }
    return Stack(children: children);
  }
}

class _WriteButton extends StatelessWidget {
  const _WriteButton({required this.pulse, required this.onTap});

  final bool pulse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final b = BookButton(
      label: Strings.write,
      icon: const Icon(Icons.edit_rounded, color: Book.ink, size: 46),
      color: Book.coral,
      line: Book.coralLine,
      size: 96,
      onTap: onTap,
    );
    return pulse ? Breathing(amount: 0.06, period: const Duration(milliseconds: 1100), child: b) : b;
  }
}

/// A care tool that is pressed and carried to the pet (or tapped).
class _CarryButton extends StatelessWidget {
  const _CarryButton({required this.what, required this.label, required this.onDown, required this.away});

  final Carry what;
  final String label;
  final void Function(PointerDownEvent e) onDown;
  final bool away;

  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: onDown,
        child: Opacity(
          opacity: away ? 0.35 : 1,
          child: BookButton(label: label, icon: Art(what.art), color: Book.peach, line: Book.peachLine, onTap: () {}),
        ),
      );
}

/// A letter cookie: a round biscuit with its character on it.
class _Cookie extends StatelessWidget {
  const _Cookie({required this.letter, required this.size});

  final String letter;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Stack(alignment: Alignment.center, children: [
          const Positioned.fill(child: Art('items/cookie')),
          Text(letter, style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.w700, color: const Color(0xFF8A5A33))),
        ]),
      );
}
