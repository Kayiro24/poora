import 'package:flutter/material.dart';
import 'package:poora/core/theme/motion.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';

ThemeData buildDarkTheme() {
  const scheme = ColorScheme.dark(
    primary: Tokens.coral,
    onPrimary: Tokens.textInverse,
    secondary: Tokens.sage,
    onSecondary: Tokens.textInverse,
    tertiary: Tokens.periwinkle,
    onTertiary: Tokens.textInverse,
    surface: Tokens.surface,
    onSurface: Tokens.textPrimary,
    surfaceContainerHighest: Tokens.surfaceHigh,
    outline: Tokens.outline,
    error: Tokens.dayMissed,
  );
  final textTheme = TextTheme(
    displayLarge: AppText.h1,
    displayMedium: AppText.h2,
    displaySmall: AppText.h3,
    headlineSmall: AppText.h4,
    titleLarge: AppText.h4,
    titleMedium: AppText.label,
    bodyLarge: AppText.bodyL,
    bodyMedium: AppText.bodyM,
    bodySmall: AppText.bodyS,
    labelLarge: AppText.label,
  );
  OutlineInputBorder border(Color c) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(Radii.input),
    borderSide: c == Colors.transparent ? BorderSide.none : BorderSide(color: c),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: Tokens.bg,
    canvasColor: Tokens.bg,
    fontFamily: 'Inter',
    textTheme: textTheme,
    dividerTheme: const DividerThemeData(
      color: Tokens.outline,
      thickness: 0.5,
      space: 0.5,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Tokens.surface,
      modalBackgroundColor: Tokens.surface,
      showDragHandle: true,
      dragHandleColor: Tokens.outline,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.card)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      titleTextStyle: AppText.h3,
      contentTextStyle: AppText.bodyM,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Tokens.surfaceHigh,
      hintStyle: AppText.body(16, color: Tokens.textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: border(Colors.transparent),
      enabledBorder: border(Colors.transparent),
      focusedBorder: border(Tokens.outline),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? Tokens.sageDeep
            : Tokens.surfaceHigh,
      ),
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled)
            ? Tokens.outline
            : Tokens.textPrimary,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: const CircleBorder(),
      side: const BorderSide(color: Tokens.textSecondary, width: 1.5),
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Tokens.mint : null,
      ),
      checkColor: const WidgetStatePropertyAll(Tokens.textInverse),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Tokens.surfaceHigh,
      contentTextStyle: AppText.bodyM,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.input),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Tokens.textPrimary,
        textStyle: AppText.label,
      ),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: Tokens.surface,
      headerHeadlineStyle: AppText.h2,
      todayBorder: const BorderSide(color: Tokens.ice),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
      ),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: Tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CalmPageTransitionsBuilder(),
        TargetPlatform.iOS: CalmPageTransitionsBuilder(),
      },
    ),
  );
}

/// Fade + 12px upward slide (§2.6). Under reduce-motion: fade only.
class CalmPageTransitionsBuilder extends PageTransitionsBuilder {
  const CalmPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => CalmTransition(animation: animation, child: child);
}

class CalmTransition extends StatelessWidget {
  const CalmTransition({
    required this.animation,
    required this.child,
    super.key,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: animation, curve: Motion.curve);
    final faded = FadeTransition(opacity: curved, child: child);
    if (Motion.reduced(context)) return faded;
    return AnimatedBuilder(
      animation: curved,
      builder: (context, c) => Transform.translate(
        offset: Offset(0, 12 * (1 - curved.value)),
        child: c,
      ),
      child: faded,
    );
  }
}
