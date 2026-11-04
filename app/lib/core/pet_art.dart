import 'dart:convert';

import 'package:flutter/services.dart';

import 'pets.dart';

/// Where things are on a pet's picture (assets/art/pets/pets.json, made by
/// design/art/pets.py), in the picture's own units.
class PetArt {
  PetArt({
    required this.species,
    required this.size,
    required this.mouth,
    required this.head,
    required this.headRadius,
    required this.eyes,
    required this.body,
    required this.open,
    required this.happy,
    required this.sleep,
  });

  final Species species;
  final Size size;
  final Offset mouth;
  final Offset head;
  final double headRadius;

  /// Each eye: its centre and radius. The app draws the eyes itself so they
  /// can look at the finger and blink.
  final List<(Offset, double)> eyes;
  final Rect body;

  /// The picture without its eyes, and the happy and sleeping faces.
  final String open;
  final String happy;
  final String sleep;

  /// Where the finger counts as on the pet (head and body).
  bool hits(Offset p) => (p - head).distance <= headRadius || body.inflate(6).contains(p);
}

class PetArtBook {
  PetArtBook(this.pets);

  final Map<Species, PetArt> pets;

  PetArt operator [](Species s) => pets[s]!;

  static final _eyes = RegExp(r'<g id="eyes">.*?</g>', dotAll: true);

  static String withoutEyes(String svg) => svg.replaceFirst(_eyes, '');

  static Future<PetArtBook> load([AssetBundle? bundle]) async {
    final b = bundle ?? rootBundle;
    final info = jsonDecode(await b.loadString('assets/art/pets/pets.json')) as Map<String, dynamic>;
    final pets = <Species, PetArt>{};
    for (final s in Species.values) {
      final j = info[s.name] as Map<String, dynamic>;
      Offset at(Object? o) => Offset(((o as Map)['x'] as num).toDouble(), (o['y'] as num).toDouble());
      final box = j['viewBox'] as Map;
      final head = j['head'] as Map;
      final body = j['body'] as Map;
      pets[s] = PetArt(
        species: s,
        size: Size((box['width'] as num).toDouble(), (box['height'] as num).toDouble()),
        mouth: at(j['mouth']),
        head: Offset((head['cx'] as num).toDouble(), (head['cy'] as num).toDouble()),
        headRadius: (head['r'] as num).toDouble(),
        eyes: [for (final e in j['eyes'] as List) (at(e), ((e as Map)['r'] as num).toDouble())],
        body: Rect.fromLTWH((body['x'] as num).toDouble(), (body['y'] as num).toDouble(), (body['w'] as num).toDouble(), (body['h'] as num).toDouble()),
        open: withoutEyes(await b.loadString('assets/art/pets/${s.name}.svg')),
        happy: await b.loadString('assets/art/pets/${s.name}_happy.svg'),
        sleep: await b.loadString('assets/art/pets/${s.name}_sleep.svg'),
      );
    }
    return PetArtBook(pets);
  }
}
