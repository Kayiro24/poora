import 'package:flutter/painting.dart';

/// Colour tokens (spec §2.2). Dark-native; built as plain constants so a
/// light palette can be layered in later behind the same names.
abstract final class Tokens {
  static const bg = Color(0xFF151517);
  static const surface = Color(0xFF212124);
  static const surfaceHigh = Color(0xFF2B2B2F);
  static const outline = Color(0xFF39393F);
  static const textPrimary = Color(0xFFF3F0EA);
  static const textSecondary = Color(0xFFA4A19C);
  static const textInverse = Color(0xFF151517);

  static const sage = Color(0xFFC6DAD2);
  static const sageDeep = Color(0xFF86AD9E);
  static const coral = Color(0xFFEF7867);
  static const coralSoft = Color(0xFFF4AA9E);
  static const periwinkle = Color(0xFF7679F0);
  static const periSoft = Color(0xFFBDBFF8);
  static const ice = Color(0xFFC3E7EF);
  static const sun = Color(0xFFF2CA58);
  static const mint = Color(0xFFA2DDC0);
  static const white = Color(0xFFFFFFFF);

  /// Warm off-white of the focus clock face.
  static const paper = Color(0xFFF7F4EE);

  // Completion calendar scale (§4.11).
  static const dayPerfect = Color(0xFF4ADE80);
  static const dayHigh = Color(0xFFA3E635);
  static const dayMid = Color(0xFFF2CA58);
  static const dayLow = Color(0xFFFB923C);
  static const dayMissed = Color(0xFFF25555);
  static const dayEmpty = Color(0xFF2B2B2F);
}

/// User-selectable task colours (Google Calendar style). The DB stores the
/// ARGB value; this list is only the picker order.
abstract final class TaskColors {
  static const lilac = Color(0xFFC9ABEE);
  static const sand = Color(0xFFE7D6BA);

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

  /// The palette before its shade shift (v1.1) → today's swatch. Applied on
  /// upgrade and import so older tasks and export files keep their colour.
  static const legacy = <int, int>{
    0xFFF2705E: 0xFFEF7867, // coral
    0xFFF6C945: 0xFFF2CA58, // sun
    0xFF9EDFB8: 0xFFA2DDC0, // mint
    0xFFBFEAF2: 0xFFC3E7EF, // ice
    0xFF6E72F6: 0xFF7679F0, // periwinkle
    0xFFC9D9CF: 0xFFC6DAD2, // sage
    0xFFC7A6F2: 0xFFC9ABEE, // lilac
    0xFFE6D3B3: 0xFFE7D6BA, // sand
  };

  static int migrate(int argb) => legacy[argb] ?? argb;

  static String nameOf(Color c) {
    final i = all.indexWhere((x) => x.toARGB32() == c.toARGB32());
    return i < 0 ? 'Custom' : names[i];
  }

  /// Text on a task-colour fill. Dark ink passes WCAG AA on every swatch
  /// (lowest: periwinkle 5.0:1); light ink on periwinkle fails (3.2:1).
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
