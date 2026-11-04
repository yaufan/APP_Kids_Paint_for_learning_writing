import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'game.dart';
import 'glyphs.dart';
import 'pet_art.dart';
import 'sounds.dart';
import 'store.dart';
import 'voice.dart';

/// What time it is (tests and screenshots set it).
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// These are read before the app starts (main.dart) and given here.
final storeProvider = Provider<GameStore>((ref) => MemoryStore());
final savedGameProvider = Provider<Game>((ref) => const Game());
final glyphBookProvider = Provider<GlyphBook>((ref) => throw UnimplementedError('loaded in main'));
final petArtProvider = Provider<PetArtBook>((ref) => throw UnimplementedError('loaded in main'));

final soundsProvider = Provider<Sounds>((ref) => const SilentSounds());
final voiceProvider = Provider<Voice>((ref) => const SilentVoice());

/// The game; every change is saved straight away.
final gameProvider = NotifierProvider<GameNotifier, Game>(GameNotifier.new);

class GameNotifier extends Notifier<Game> {
  @override
  Game build() => ref.read(savedGameProvider);

  DateTime get now => ref.read(clockProvider)();

  void change(Game Function(Game g, DateTime now) f) {
    final next = f(state, now);
    if (identical(next, state)) return;
    state = next;
    ref.read(storeProvider).write(next.toJson());
  }

  void settings(Settings Function(Settings s) f) => change((g, _) => g.copyWith(settings: f(g.settings)));
}
