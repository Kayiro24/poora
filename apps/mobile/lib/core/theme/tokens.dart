import 'package:flutter/painting.dart';

/// Colour tokens (spec §2.2). Dark-native; built as plain constants so a
/// light palette can be layered in later behind the same names.
abstract final class Tokens {
  static const bg = Color(0xFF161616);
  static const surface = Color(0xFF222222);
  static const surfaceHigh = Color(0xFF2C2C2C);
  static const outline = Color(0xFF3A3A3A);
  static const textPrimary = Color(0xFFF4F1EA);
  static const textSecondary = Color(0xFFA3A09A);
  static const textInverse = Color(0xFF161616);

  static const sage = Color(0xFFC9D9CF);
  static const sageDeep = Color(0xFF8FAF9C);
  static const coral = Color(0xFFF2705E);
  static const coralSoft = Color(0xFFF7A497);
  static const periwinkle = Color(0xFF6E72F6);
  static const periSoft = Color(0xFFB9BBFB);
  static const ice = Color(0xFFBFEAF2);
  static const sun = Color(0xFFF6C945);
  static const mint = Color(0xFF9EDFB8);
  static const white = Color(0xFFFFFFFF);

  // Completion calendar scale (§4.11).
  static const dayPerfect = Color(0xFF4ADE80);
  static const dayHigh = Color(0xFFA3E635);
  static const dayMid = Color(0xFFF6C945);
  static const dayLow = Color(0xFFFB923C);
  static const dayMissed = Color(0xFFF25555);
  static const dayEmpty = Color(0xFF2C2C2C);
}

/// User-selectable task colours (Google Calendar style). The DB stores the
/// ARGB value; this list is only the picker order.
abstract final class TaskColors {
  static const lilac = Color(0xFFC7A6F2);
  static const sand = Color(0xFFE6D3B3);

  static const all = <Color>[
    Tokens.coral,
    Tokens.sun,
    Tokens.mint,
    Tokens.ice,
    Tokens.periwinkle,
    Tokens.sage,
    lilac,
    sand,
  ];

  static const names = <String>[
    'Coral',
    'Sun',
    'Mint',
    'Ice',
    'Periwinkle',
    'Sage',
    'Lilac',
    'Sand',
  ];

  static String nameOf(Color c) {
    final i = all.indexWhere((x) => x.toARGB32() == c.toARGB32());
    return i < 0 ? 'Custom' : names[i];
  }

  /// Text on a task-colour fill. Dark ink passes WCAG AA on every swatch
  /// (lowest: periwinkle 4.65:1); light ink on periwinkle fails (3.45:1).
  /// Never dim it — reduced-opacity ink drops below AA on periwinkle.
  static Color onColor(Color c) => Tokens.textInverse;
}

/// Spacing scale (§2.4).
abstract final class Space {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const x3 = 32.0;
  static const x4 = 48.0;
  static const side = 20.0;
}

/// Radius scale (§2.4).
abstract final class Radii {
  static const card = 28.0;
  static const inner = 20.0;
  static const pill = 999.0;
  static const input = 16.0;
}
