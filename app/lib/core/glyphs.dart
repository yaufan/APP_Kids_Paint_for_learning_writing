import 'dart:convert';

import 'package:flutter/services.dart';

/// What a character is: a warm-up line, a digit or a capital (0.1).
enum GlyphKind { warmup, digit, capital }

/// One character the child learns to write, as in assets/glyphs.json
/// (design/glyphs/glyphs.py): its strokes in writing order, each from where
/// the pen starts to where it lifts, in a box [height] (100) high.
class Glyph {
  const Glyph({required this.id, required this.kind, required this.show, required this.zh, required this.en, required this.width, required this.strokes});

  final String id;
  final GlyphKind kind;

  /// What is printed on its card ('' for the warm-up lines).
  final String show;

  /// Its Mandarin name (and for a capital, the word that goes with it).
  final String zh;

  /// Its English word ('' for the warm-ups; the digit itself for a digit).
  final String en;
  final double width;
  final List<List<Offset>> strokes;

  static const height = 100.0;

  /// Its picture in the sticker book (a capital's word; digits are drawn
  /// as that many stars).
  String? get picture => kind == GlyphKind.capital ? 'words/${en.replaceAll(' ', '_').replaceAll('-', '_')}' : null;

  Size get size => Size(width, height);

  factory Glyph.fromJson(Map<String, dynamic> j) => Glyph(
        id: j['id'] as String,
        kind: GlyphKind.values.byName(j['kind'] as String),
        show: j['show'] as String,
        zh: j['zh'] as String,
        en: j['en'] as String,
        width: (j['width'] as num).toDouble(),
        strokes: [
          for (final s in j['strokes'] as List)
            [for (final p in s as List) Offset(((p as List)[0] as num).toDouble(), (p[1] as num).toDouble())],
        ],
      );
}

/// A row of the picker: characters that are about as hard to write.
class GlyphGroup {
  const GlyphGroup(this.id, this.label, this.glyphs);

  final String id;
  final String label;
  final List<Glyph> glyphs;
}

class GlyphBook {
  GlyphBook(this.groups) : byId = {for (final g in groups) for (final glyph in g.glyphs) glyph.id: glyph};

  final List<GlyphGroup> groups;
  final Map<String, Glyph> byId;

  /// Every character in learning order.
  List<Glyph> get all => [for (final g in groups) ...g.glyphs];

  factory GlyphBook.fromJson(Map<String, dynamic> j) {
    final glyphs = {for (final g in j['glyphs'] as List) (g as Map<String, dynamic>)['id'] as String: Glyph.fromJson(g)};
    return GlyphBook([
      for (final g in j['groups'] as List)
        GlyphGroup((g as Map<String, dynamic>)['id'] as String, g['label'] as String, [for (final id in g['glyphs'] as List) glyphs[id]!]),
    ]);
  }

  static Future<GlyphBook> load([AssetBundle? bundle]) async =>
      GlyphBook.fromJson(jsonDecode(await (bundle ?? rootBundle).loadString('assets/glyphs.json')) as Map<String, dynamic>);
}
