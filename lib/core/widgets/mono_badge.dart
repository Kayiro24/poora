import 'package:flutter/material.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';

/// Small dark rounded rectangle with mono text, for countdowns ("2:59:12").
class MonoBadge extends StatelessWidget {
  const MonoBadge(
    this.text, {
    this.background = Tokens.bg,
    this.foreground = Tokens.textPrimary,
    this.size = 13,
    super.key,
  });

  final String text;
  final Color background;
  final Color foreground;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: AppText.mono(size, color: foreground)),
    );
  }
}
