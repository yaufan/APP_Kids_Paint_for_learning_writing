import 'package:flutter/material.dart';

/// 字母寵物's picture-book colours (docs/design.md "畫風和故事"): warm and
/// soft like watercolour or gouache, and lines a shade darker than their
/// fill instead of black outlines. Different from 畫畫小鎮 on purpose.
abstract final class Book {
  static const paper = Color(0xFFFBF3E4);
  static const paperDeep = Color(0xFFF2E3C9);
  static const paperGrain = Color(0xFFE3CFAE);

  static const ink = Color(0xFF5B4636);
  static const inkSoft = Color(0xFF8A7462);

  static const peach = Color(0xFFF4B393);
  static const peachLine = Color(0xFFC9805F);
  static const coral = Color(0xFFE98B7A);
  static const coralLine = Color(0xFFB8604F);
  static const sage = Color(0xFFAFC69E);
  static const sageLine = Color(0xFF6F8B5E);
  static const blue = Color(0xFF9CBCD1);
  static const blueLine = Color(0xFF5E86A2);
  static const mustard = Color(0xFFEBC874);
  static const mustardLine = Color(0xFFB8913A);
  static const rose = Color(0xFFF2B5AE);
  static const lilac = Color(0xFFC7B6DA);
  static const lilacLine = Color(0xFF8A73A6);

  /// The start dot and what has been traced.
  static const go = Color(0xFF7FB069);
  static const goLine = Color(0xFF4E7F3E);
  static const road = Color(0xFFE6D9C3);
  static const roadLine = Color(0xFFD2C1A3);
  static const traced = Color(0xFFE98B7A);

  /// The night when the pet sleeps.
  static const night = Color(0xFF2E3A5C);

  /// Parent mode: calm and plain.
  static const parentBg = Color(0xFFF6F2EA);
}

abstract final class BookTheme {
  /// jf open 粉圓 (OFL): a rounded typeface made in Taiwan.
  static const font = 'Huninn';

  static ThemeData light() {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Book.coral, surface: Book.paper),
      scaffoldBackgroundColor: Book.paper,
      fontFamily: font,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(bodyColor: Book.ink, displayColor: Book.ink, fontFamily: font),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : null),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Book.go : null),
      ),
    );
  }
}
