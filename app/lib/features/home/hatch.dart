import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/pet_art.dart';
import '../../core/pets.dart';
import '../../core/providers.dart';
import '../../core/sounds.dart';
import '../pet/pet_view.dart';

/// The egg hatches (after the first character written right): the child
/// taps it three times, it cracks open, and the pet is given a name.
class HatchOverlay extends ConsumerStatefulWidget {
  const HatchOverlay({super.key, required this.species});

  final Species species;

  @override
  ConsumerState<HatchOverlay> createState() => _HatchOverlayState();
}

class _HatchOverlayState extends ConsumerState<HatchOverlay> with TickerProviderStateMixin {
  late final _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  late final _open = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  var _cracks = 0;
  var _naming = false;
  late final Sounds _sounds;

  @override
  void initState() {
    super.initState();
    _sounds = ref.read(soundsProvider);
    _sounds.hold(this, Music.play);
    WidgetsBinding.instance.addPostFrameCallback((_) => _say(Strings.hatching));
  }

  @override
  void dispose() {
    _sounds.release(this);
    _shake.dispose();
    _open.dispose();
    super.dispose();
  }

  void _say(String s) {
    if (mounted && ref.read(gameProvider).settings.voice) ref.read(voiceProvider).say(s);
  }

  Future<void> _tap() async {
    if (_cracks >= 3) return;
    final sounds = ref.read(soundsProvider);
    setState(() => _cracks++);
    sounds.play(Sfx.crack);
    _shake.forward(from: 0);
    if (_cracks < 3) return;
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    sounds.play(Sfx.celebrate);
    await _open.forward();
    if (!mounted) return;
    _say(Strings.hello(widget.species));
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (mounted) setState(() => _naming = true);
    _say(Strings.nameIt);
  }

  void _name(String name) {
    ref.read(gameProvider.notifier).change((g, _) => g.named(name));
    ref.read(soundsProvider).play(Sfx.happy);
    _say(Strings.hi(name.trim()));
  }

  Future<void> _type() async {
    final c = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Book.paper,
        title: const Text(Strings.nameField),
        content: TextField(controller: c, autofocus: true, maxLength: 8, style: const TextStyle(fontSize: 24)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text(Strings.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, c.text), child: const Text(Strings.ok)),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) _name(name);
  }

  @override
  Widget build(BuildContext context) {
    final art = ref.watch(petArtProvider)[widget.species];
    return Material(
      color: Book.paper.withValues(alpha: 0.94),
      child: SafeArea(
        child: LayoutBuilder(builder: (context, box) {
          final size = math.min(box.maxWidth * 0.62, box.maxHeight * 0.36);
          return Column(children: [
            const SizedBox(height: 28),
            Text(
              _naming ? Strings.nameIt : (_open.value > 0 ? Strings.hello(widget.species) : Strings.hatching),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Book.ink),
              textAlign: TextAlign.center,
            ),
            Expanded(
              child: Center(
                child: Semantics(
                  key: const ValueKey('hatch-egg'),
                  container: true,
                  button: true,
                  label: Strings.hatching,
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: _tap,
                    child: SizedBox(
                      width: size,
                      height: size * 1.25,
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_shake, _open]),
                        builder: (context, _) => _egg(art, size),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_naming)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                child: Column(children: [
                  Wrap(spacing: 14, runSpacing: 14, alignment: WrapAlignment.center, children: [
                    for (final n in widget.species.names)
                      BookButton(label: n, color: Book.mustard, line: Book.mustardLine, size: 72, wide: true, onTap: () => _name(n)),
                  ]),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _type,
                    icon: const Icon(Icons.keyboard_rounded, color: Book.inkSoft),
                    label: const Text(Strings.typeName, style: TextStyle(fontSize: 18, color: Book.inkSoft)),
                  ),
                ]),
              )
            else
              const SizedBox(height: 120),
          ]);
        }),
      ),
    );
  }

  Widget _egg(PetArt art, double size) {
    final shake = math.sin(_shake.value * math.pi * 6) * 0.12 * (1 - _shake.value);
    final open = Curves.easeOut.transform(_open.value);
    final petW = size * 0.92;
    return Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
      if (open > 0)
        Positioned(
          bottom: size * 0.05,
          child: Opacity(
            opacity: open,
            child: Transform.scale(scale: 0.5 + 0.5 * open, alignment: Alignment.bottomCenter, child: PetView(art: art, width: petW, mood: Mood.happy)),
          ),
        ),
      if (open < 1) ...[
        // The bottom half drops away, the top flies up.
        Positioned.fill(
          child: Transform.translate(
            offset: Offset(0, open * size * 0.6),
            child: Opacity(
              opacity: 1 - open,
              child: Transform.rotate(angle: shake, alignment: Alignment.bottomCenter, child: Art(_cracks > 0 || open > 0 ? 'eggs/${widget.species.name}_bottom' : 'eggs/${widget.species.name}')),
            ),
          ),
        ),
        if (_cracks > 0)
          Positioned.fill(
            child: Transform.translate(
              offset: Offset(open * size * 0.3, -open * size * 0.9),
              child: Transform.rotate(
                angle: shake + open * 0.8,
                child: Opacity(opacity: 1 - open, child: Art('eggs/${widget.species.name}_top')),
              ),
            ),
          ),
      ],
    ]);
  }
}

/// The pet reached a new stage: a page of the story book with what it can
/// do now.
class GrowUpOverlay extends ConsumerStatefulWidget {
  const GrowUpOverlay({super.key, required this.name, required this.stage, required this.art});

  final String name;
  final Stage stage;
  final PetArt art;

  @override
  ConsumerState<GrowUpOverlay> createState() => _GrowUpOverlayState();
}

class _GrowUpOverlayState extends ConsumerState<GrowUpOverlay> {
  @override
  void initState() {
    super.initState();
    ref.read(soundsProvider).play(Sfx.celebrate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(gameProvider).settings.voice) {
        ref.read(voiceProvider).say('${Strings.grewUp(widget.name, widget.stage)}。${Strings.newPower(widget.stage)}');
      }
    });
  }

  @override
  Widget build(BuildContext context) => Material(
        color: Book.paper.withValues(alpha: 0.95),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              const Spacer(),
              Text(Strings.grewUp(widget.name, widget.stage),
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: Book.ink)),
              const SizedBox(height: 20),
              Breathing(child: PetView(art: widget.art, width: 220, mood: Mood.happy)),
              const SizedBox(height: 20),
              Bubble(Strings.newPower(widget.stage), size: 20),
              const Spacer(),
              BookButton(
                label: Strings.yay,
                icon: const Icon(Icons.favorite_rounded, color: Book.coralLine, size: 40),
                color: Book.mustard,
                line: Book.mustardLine,
                wide: true,
                size: 76,
                onTap: () => ref.read(gameProvider.notifier).change((g, _) => g.sawStage()),
              ),
              const SizedBox(height: 12),
            ]),
          ),
        ),
      );
}
