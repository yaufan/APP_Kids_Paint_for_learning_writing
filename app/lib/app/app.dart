import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../features/home/home_screen.dart';
import '../features/letters/letters_screen.dart';
import '../features/parent/parent_screen.dart';
import '../features/story/story_screen.dart';
import '../features/write/write_screen.dart';
import 'strings.dart';
import 'theme.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final g = ref.read(gameProvider);
      final atStory = state.matchedLocation == '/story';
      if (g.species == null && !atStory) return '/story';
      if (g.species != null && atStory) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/story', builder: (_, _) => const StoryScreen()),
      GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/letters', builder: (_, _) => const LettersScreen()),
      GoRoute(path: '/write/:id', builder: (_, s) => WriteScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/parent', builder: (_, _) => const ParentScreen()),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class LetterPetsApp extends ConsumerWidget {
  const LetterPetsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The parent's sound choices go to the speakers.
    final settings = ref.watch(gameProvider.select((g) => g.settings));
    ref.read(soundsProvider)
      ..music = settings.music
      ..effects = settings.sounds;
    return MaterialApp.router(
      title: Strings.appName,
      debugShowCheckedModeBanner: false,
      theme: BookTheme.light(),
      locale: const Locale('zh', 'TW'),
      supportedLocales: const [Locale('zh', 'TW')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
