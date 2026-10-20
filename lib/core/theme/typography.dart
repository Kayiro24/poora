import 'package:flutter/painting.dart';
import 'package:poora/core/theme/tokens.dart';

/// Typography (§2.3). Fonts are bundled under assets/fonts — no runtime
/// fetching. Inter and JetBrains Mono are variable fonts, so the weight is also
/// passed as a `wght` axis variation.
abstract final class AppText {
  static const _display = 'BarlowCondensed';
  static const _body = 'Inter';
  static const _mono = 'JetBrainsMono';

  /// Condensed display face. Callers pass text already upper-cased.
  static TextStyle display(double size, {Color color = Tokens.textPrimary}) =>
      TextStyle(
        fontFamily: _display,
        fontWeight: FontWeight.w600,
        fontSize: size,
        height: 1,
        letterSpacing: -0.5,
        color: color,
      );

  static TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = Tokens.textPrimary,
    double? height = 1.35,
  }) => TextStyle(
    fontFamily: _body,
    fontWeight: weight,
    fontVariations: [FontVariation('wght', weight.value.toDouble())],
    fontSize: size,
    height: height,
    color: color,
  );

  static TextStyle mono(
    double size, {
    Color color = Tokens.textPrimary,
    FontWeight weight = FontWeight.w500,
  }) => TextStyle(
    fontFamily: _mono,
    fontWeight: weight,
    fontVariations: [FontVariation('wght', weight.value.toDouble())],
    fontFeatures: const [FontFeature.tabularFigures()],
    fontSize: size,
    height: 1,
    color: color,
  );

  static final h1 = display(40);
  static final h2 = display(32);
  static final h3 = display(24);
  static final h4 = display(20);
  static final bodyL = body(16);
  static final bodyM = body(14);
  static final bodyS = body(12, color: Tokens.textSecondary);
  static final label = body(14, weight: FontWeight.w500);
}
