import 'package:flutter/material.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';

/// Big mono number with a small label to its right ("64 employees" style).
class StatTile extends StatelessWidget {
  const StatTile({
    required this.value,
    required this.label,
    this.color = Tokens.textPrimary,
    this.labelColor,
    this.size = 32,
    this.leading,
    super.key,
  });

  final String value;
  final String label;
  final Color color;
  final Color? labelColor;
  final double size;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$value $label',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 4)],
          Text(value, style: AppText.mono(size, color: color)),
          const SizedBox(width: 6),
          Flexible(
            child: Padding(
              padding: EdgeInsets.only(bottom: size * 0.08),
              child: Text(
                label,
                style: AppText.body(
                  12,
                  color: labelColor ?? color.withValues(alpha: 0.75),
                  height: 1.1,
                ),
                maxLines: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
