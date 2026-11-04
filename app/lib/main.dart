import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'core/game.dart';
import 'core/glyphs.dart';
import 'core/pet_art.dart';
import 'core/providers.dart';
import 'core/sounds.dart';
import 'core/store.dart';
import 'core/voice.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final store = FileStore(await getApplicationSupportDirectory());
  final saved = Game.fromJson(await store.read(), DateTime.now());
  final glyphs = await GlyphBook.load();
  final pets = await PetArtBook.load();
  runApp(ProviderScope(
    overrides: [
      storeProvider.overrideWithValue(store),
      savedGameProvider.overrideWithValue(saved),
      glyphBookProvider.overrideWithValue(glyphs),
      petArtProvider.overrideWithValue(pets),
      soundsProvider.overrideWithValue(SystemSounds()),
      voiceProvider.overrideWithValue(SystemVoice()),
    ],
    child: const LetterPetsApp(),
  ));
}
