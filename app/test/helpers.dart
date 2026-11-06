import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:letter_pets/app/app.dart';
import 'package:letter_pets/core/game.dart';
import 'package:letter_pets/core/glyphs.dart';
import 'package:letter_pets/core/pet_art.dart';
import 'package:letter_pets/core/providers.dart';
import 'package:letter_pets/core/sounds.dart';
import 'package:letter_pets/core/store.dart';
import 'package:letter_pets/core/voice.dart';

final glyphBook = GlyphBook.fromJson(jsonDecode(File('assets/glyphs.json').readAsStringSync()) as Map<String, dynamic>);

/// Remembers the sounds played and the music asked for.
class RecordingSounds implements Sounds {
  final played = <Sfx>[];
  final holders = MusicHolders();

  Music? get music => holders.current;

  @override
  set music(bool on) {}

  @override
  set effects(bool on) {}

  @override
  void play(Sfx sfx) => played.add(sfx);

  @override
  void hold(Object owner, Music? music) => holders.hold(owner, music);

  @override
  void release(Object owner) => holders.release(owner);
}

final shotKey = GlobalKey();

/// The app on a phone screen, starting from [game].
class TestApp {
  TestApp(this.tester, this.store, this.sounds, this.voice);

  final WidgetTester tester;
  final MemoryStore store;
  final RecordingSounds sounds;
  final RecordingVoice voice;
  DateTime now = DateTime(2026, 11, 4, 10);

  ProviderContainer get container => ProviderScope.containerOf(tester.element(find.byType(LetterPetsApp)));
  Game get game => container.read(gameProvider);
  void change(Game Function(Game g) f) => container.read(gameProvider.notifier).change((g, _) => f(g));

  static PetArtBook? _art;

  static Future<TestApp> start(WidgetTester tester, {Game game = const Game(), Size size = const Size(1080, 2340), double ratio = 2.75, String at = '/home'}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = ratio;
    addTearDown(tester.view.reset);
    final art = _art ??= (await tester.runAsync(PetArtBook.load))!;
    final store = MemoryStore();
    final app = TestApp(tester, store, RecordingSounds(), RecordingVoice());
    await tester.pumpWidget(RepaintBoundary(
      key: shotKey,
      child: ProviderScope(
        overrides: [
          storeProvider.overrideWithValue(store),
          savedGameProvider.overrideWithValue(game),
          glyphBookProvider.overrideWithValue(glyphBook),
          petArtProvider.overrideWithValue(art),
          soundsProvider.overrideWithValue(app.sounds),
          voiceProvider.overrideWithValue(app.voice),
          clockProvider.overrideWithValue(() => app.now),
        ],
        child: const LetterPetsApp(),
      ),
    ));
    if (at != '/home') app.go(at);
    await app.settle();
    return app;
  }

  void go(String location) => app.container.read(routerProvider).go(location);

  String get location => container.read(routerProvider).state.matchedLocation;

  TestApp get app => this;

  /// Lets the pictures load and the screen move on [ms] milliseconds.
  Future<void> settle([int ms = 400]) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(Duration(milliseconds: ms ~/ 6));
    }
  }

  Future<void> tapLabel(String label, {int ms = 400}) async {
    await tester.tap(find.bySemanticsLabel(label).first);
    await settle(ms);
  }

  Future<void> end() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Real fonts for screenshots instead of the test font's boxes.
Future<void> loadFonts() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '/home/user/flutter';
  final fonts = {
    'MaterialIcons': ['$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf'],
    'Huninn': ['assets/fonts/jf-openhuninn-2.1.ttf'],
    'Roboto': ['assets/fonts/jf-openhuninn-2.1.ttf'],
  };
  for (final MapEntry(key: family, value: paths) in fonts.entries) {
    final loader = FontLoader(family);
    for (final path in paths.where((p) => File(p).existsSync())) {
      loader.addFont(File(path).readAsBytes().then(ByteData.sublistView));
    }
    await loader.load();
  }
}

Future<void> shoot(WidgetTester tester, String device, String name) => tester.runAsync(() async {
      final boundary = shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('build/screenshots/$device/$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
