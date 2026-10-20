import 'package:flutter/widgets.dart';

/// Motion defaults (§2.6): soothing, never bouncy.
abstract final class Motion {
  static const curve = Curves.easeOutCubic;
  static const fast = Duration(milliseconds: 280);
  static const medium = Duration(milliseconds: 360);
  static const slow = Duration(milliseconds: 420);

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Returns [d], or zero when the OS asks for reduced motion.
  static Duration of(BuildContext context, [Duration d = medium]) =>
      reduced(context) ? Duration.zero : d;
}
