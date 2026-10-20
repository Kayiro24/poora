import 'package:flutter/material.dart';
import 'package:poora/core/theme/tokens.dart';

/// Full-width rounded pastel panel that holds each screen's hero.
class AccentPanel extends StatelessWidget {
  const AccentPanel({
    required this.color,
    required this.child,
    this.padding = const EdgeInsets.all(Space.xl),
    this.onTap,
    this.radius = Radii.card,
    super.key,
  });

  final Color color;
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Dark rounded card on the app background (bg → surface).
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(Space.l),
    this.color = Tokens.surface,
    this.radius = Radii.card,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final double radius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
