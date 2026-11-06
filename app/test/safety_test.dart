import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:letter_pets/features/parent/parent_gate.dart';
import 'package:letter_pets/core/game.dart';
import 'package:letter_pets/core/pets.dart';

import 'helpers.dart';

/// Privacy and the parent gate: no network, no pages opened by other apps,
/// parent mode only through the gate.
void main() {
  test('the app asks for no network and takes no links from other apps', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, isNot(contains('android.permission.INTERNET')));
    expect(manifest, contains('android:name="flutter_deeplinking_enabled" android:value="false"'));
    expect(File('ios/Runner/Info.plist').readAsStringSync(), contains('<key>FlutterDeepLinkingEnabled</key>\n\t<false/>'));
  });

  testWidgets('parent mode cannot be opened without the gate', (tester) async {
    final app = await TestApp.start(tester, game: const Game(storyRead: true, species: Species.bunny, hatched: true, name: '棉花'));
    app.go('/parent');
    await app.settle();
    expect(app.location, '/home', reason: 'no pass from the gate');
    ParentPass.grant();
    app.go('/parent');
    await app.settle();
    expect(app.location, '/parent', reason: 'right after the gate');
    app.go('/home');
    await app.settle();
    app.go('/parent');
    await app.settle();
    expect(app.location, '/home', reason: 'the pass is used up');
    await app.end();
  });
}
