import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/game.dart';
import '../../core/pet_art.dart';
import '../../core/providers.dart';
import '../../core/sounds.dart';
import '../pet/pet_view.dart';

/// A parent's reward reached (docs/design.md "達成時的特殊畫面"): streamers,
/// the pet dancing, the gift box opening on the parent's picture and words,
/// read out ("爸爸媽媽說：週末去公園！"), and "show it to mum and dad".
class RewardOverlay extends ConsumerStatefulWidget {
  const RewardOverlay({super.key, required this.reward, required this.art});

  final Reward reward;
  final PetArt? art;

  @override
  ConsumerState<RewardOverlay> createState() => _RewardOverlayState();
}

class _RewardOverlayState extends ConsumerState<RewardOverlay> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  late final Sounds _sounds;

  @override
  void initState() {
    super.initState();
    _sounds = ref.read(soundsProvider);
    _sounds.play(Sfx.celebrate);
    _sounds.hold(this, Music.play);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(gameProvider).settings.voice) {
        ref.read(voiceProvider).say('${Strings.reached}${Strings.parentsSay(widget.reward.text)}');
      }
    });
  }

  @override
  void dispose() {
    _sounds.release(this);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reward;
    return Material(
      color: Book.paper.withValues(alpha: 0.96),
      child: Stack(children: [
        Positioned.fill(child: IgnorePointer(child: AnimatedBuilder(animation: _c, builder: (_, _) => CustomPaint(painter: _Streamers(_c.value))))),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(children: [
              const SizedBox(height: 12),
              const Text(Strings.reached, style: TextStyle(fontSize: 38, fontWeight: FontWeight.w700, color: Book.coralLine)),
              const SizedBox(height: 4),
              Text(Strings.goalShort(r.goal, r.target), style: const TextStyle(fontSize: 20, color: Book.inkSoft, fontWeight: FontWeight.w600)),
              const Spacer(),
              Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                if (widget.art != null)
                  AnimatedBuilder(
                    animation: _c,
                    builder: (_, child) => Transform.rotate(angle: math.sin(_c.value * math.pi * 8) * 0.12, alignment: Alignment.bottomCenter, child: child),
                    child: PetView(art: widget.art!, width: 130, mood: Mood.happy),
                  ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 170,
                  height: 190,
                  child: Stack(alignment: Alignment.bottomCenter, children: [
                    const Positioned.fill(top: 40, child: Art('items/giftOpen')),
                    Positioned(top: 0, child: Breathing(amount: 0.08, period: const Duration(milliseconds: 900), child: SizedBox(width: 96, height: 96, child: Art('rewards/${r.icon}')))),
                  ]),
                ),
              ]),
              const SizedBox(height: 18),
              Bubble(Strings.parentsSay(r.text), size: 24),
              const Spacer(),
              BookButton(
                label: Strings.showParents,
                icon: const Icon(Icons.favorite_rounded, color: Book.coralLine, size: 40),
                color: Book.mustard,
                line: Book.mustardLine,
                wide: true,
                size: 76,
                onTap: () => ref.read(gameProvider.notifier).change((g, now) => g.sawReward(r.id, now)),
              ),
              const SizedBox(height: 8),
            ]),
          ),
        ),
      ]),
    );
  }
}

/// Paper streamers falling, in the book's colours.
class _Streamers extends CustomPainter {
  _Streamers(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    const colors = [Book.coral, Book.mustard, Book.sage, Book.blue, Book.lilac, Book.peach];
    final r = math.Random(4);
    for (var i = 0; i < 46; i++) {
      final x = r.nextDouble() * size.width;
      final speed = 0.6 + r.nextDouble() * 0.8;
      final y = ((r.nextDouble() + t * speed) % 1.0) * (size.height + 40) - 20;
      canvas.save();
      canvas.translate(x + math.sin(t * 6 + i) * 12, y);
      canvas.rotate(t * 8 * speed + i);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 12, height: 6), const Radius.circular(2)),
          Paint()..color = colors[i % colors.length].withValues(alpha: 0.9));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_Streamers old) => old.t != t;
}
