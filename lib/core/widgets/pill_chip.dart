import 'package:flutter/material.dart';
import 'package:poora/core/theme/motion.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';

/// Filled or outlined pill with an optional leading dot or icon.
class PillChip extends StatelessWidget {
  const PillChip({
    required this.label,
    this.onTap,
    this.filled = false,
    this.color,
    this.foreground,
    this.dot,
    this.icon,
    this.trailingIcon,
    this.dense = false,
    this.semanticLabel,
    super.key,
  });

  final String label;
  final VoidCallback? onTap;
  final bool filled;

  /// Fill (when [filled]) or outline colour.
  final Color? color;
  final Color? foreground;
  final Color? dot;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool dense;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = color ?? (filled ? Tokens.textPrimary : Tokens.outline);
    final fg =
        foreground ??
        (filled
            ? (c.computeLuminance() > 0.3 ? Tokens.textInverse : Tokens.textPrimary)
            : Tokens.textPrimary);
    final pad = dense
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
        : const EdgeInsets.symmetric(horizontal: 14, vertical: 8);
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.pill),
          onTap: onTap,
          child: AnimatedContainer(
            duration: Motion.of(context, Motion.fast),
            curve: Motion.curve,
            padding: pad,
            constraints: BoxConstraints(minHeight: dense ? 24 : 36),
            decoration: BoxDecoration(
              color: filled ? c : Colors.transparent,
              borderRadius: BorderRadius.circular(Radii.pill),
              border: filled ? null : Border.all(color: c),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dot != null) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                ],
                if (icon != null) ...[
                  Icon(icon, size: dense ? 12 : 16, color: fg),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: AppText.body(
                    dense ? 11 : 13,
                    weight: FontWeight.w500,
                    color: fg,
                    height: 1.1,
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 4),
                  Icon(trailingIcon, size: dense ? 12 : 16, color: fg),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
