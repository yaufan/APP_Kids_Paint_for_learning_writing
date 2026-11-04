import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/pets.dart';
import '../../core/providers.dart';
import '../../core/sounds.dart';

/// The opening story: the picture book opens on the pet house at the edge
/// of the letter forest, eggs appear at its door, and the child takes one
/// home (docs/design.md "故事").
class StoryScreen extends ConsumerStatefulWidget {
  const StoryScreen({super.key});

  @override
  ConsumerState<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends ConsumerState<StoryScreen> {
  var _page = 0;
  Species? _picked;

  bool get _picking => _page >= Strings.storyPages.length;

  @override
  void initState() {
    super.initState();
    ref.read(soundsProvider).hold(this, Music.homeLand);
    WidgetsBinding.instance.addPostFrameCallback((_) => _read());
  }

  @override
  void dispose() {
    ref.read(soundsProvider).release(this);
    ref.read(voiceProvider).stop();
    super.dispose();
  }

  void _read() {
    if (!mounted || !ref.read(gameProvider).settings.voice) return;
    ref.read(voiceProvider).say(_picking ? Strings.pickEgg : Strings.storyPages[_page]);
  }

  void _turn() {
    setState(() => _page++);
    _read();
  }

  void _pick(Species s) {
    ref.read(soundsProvider).play(Sfx.pop);
    setState(() => _picked = s);
    if (ref.read(gameProvider).settings.voice) ref.read(voiceProvider).say(Strings.eggOf(s));
  }

  void _takeHome() {
    final s = _picked;
    if (s == null) return;
    ref.read(gameProvider.notifier).change((g, _) => g.pickEgg(s));
    ref.read(soundsProvider).play(Sfx.happy);
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Paper(
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(position: Tween(begin: const Offset(0.12, 0), end: Offset.zero).animate(a), child: child),
            ),
            child: _picking ? _eggs(context) : _storyPage(context),
          ),
        ),
      ),
    );
  }

  Widget _storyPage(BuildContext context) {
    return GestureDetector(
      key: ValueKey('page-$_page'),
      behavior: HitTestBehavior.opaque,
      onTap: _turn,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Art('story/story_${_page + 1}', fit: BoxFit.cover),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            Strings.storyPages[_page],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, height: 1.5, fontWeight: FontWeight.w600, color: Book.ink),
          ),
          const SizedBox(height: 22),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < Strings.storyPages.length; i++)
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(shape: BoxShape.circle, color: i == _page ? Book.coral : Book.paperGrain),
              ),
          ]),
          const SizedBox(height: 16),
          BookButton(label: Strings.turnPage, icon: const Icon(Icons.arrow_forward_rounded, color: Book.ink, size: 40), onTap: _turn, wide: true),
        ]),
      ),
    );
  }

  Widget _eggs(BuildContext context) {
    final picked = _picked;
    final full = ref.watch(gameProvider.select((g) => g.settings.full));
    return LayoutBuilder(
      key: const ValueKey('eggs'),
      builder: (context, box) {
        final egg = math.min(box.maxWidth / 3.6, box.maxHeight / 5.6);
        return Column(children: [
          const SizedBox(height: 20),
          const Text(Strings.pickEgg, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: Book.ink)),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 6,
                children: [
                  for (final s in Species.values)
                    _Egg(
                      species: s,
                      size: egg,
                      picked: picked == s,
                      // The free version has one pet; it can be any of them.
                      locked: false,
                      onTap: () => _pick(s),
                    ),
                ],
              ),
            ),
          ),
          if (!full) const SizedBox.shrink(),
          Padding(
            padding: const EdgeInsets.only(bottom: 24, top: 8),
            child: AnimatedOpacity(
              opacity: picked == null ? 0 : 1,
              duration: const Duration(milliseconds: 250),
              child: BookButton(
                label: picked == null ? Strings.pickEgg : Strings.takeHome(picked),
                icon: const Icon(Icons.home_rounded, color: Book.ink, size: 40),
                color: Book.sage,
                line: Book.sageLine,
                wide: true,
                size: 76,
                onTap: picked == null ? null : _takeHome,
              ),
            ),
          ),
        ]);
      },
    );
  }
}

class _Egg extends StatelessWidget {
  const _Egg({required this.species, required this.size, required this.picked, required this.locked, required this.onTap});

  final Species species;
  final double size;
  final bool picked;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final egg = SizedBox(width: size, height: size * 1.2, child: Art('eggs/${species.name}'));
    return Semantics(
      button: true,
      selected: picked,
      label: Strings.eggOf(species),
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        sound: null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: picked ? [BoxShadow(color: Book.mustard.withValues(alpha: 0.7), blurRadius: 30, spreadRadius: 4)] : const [],
          ),
          child: picked ? Breathing(amount: 0.06, period: const Duration(milliseconds: 900), child: egg) : egg,
        ),
      ),
    );
  }
}
