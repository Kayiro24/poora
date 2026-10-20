import 'package:flutter/material.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';
import 'package:poora/core/widgets/round_icon_button.dart';

/// Round back button + big uppercase title, optional trailing widgets
/// (filter pill, gear…).
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    required this.title,
    this.onBack,
    this.trailing = const [],
    this.onPastel = false,
    this.size = 40,
    super.key,
  });

  final String title;
  final VoidCallback? onBack;
  final List<Widget> trailing;

  /// On a pastel panel: white back button, dark title.
  final bool onPastel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fg = onPastel ? Tokens.textInverse : Tokens.textPrimary;
    return Row(
      children: [
        if (onBack != null) ...[
          RoundIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: onBack,
            semanticLabel: 'Back',
            background: onPastel ? Tokens.white : Tokens.surfaceHigh,
            foreground: onPastel ? Tokens.textInverse : Tokens.textPrimary,
          ),
          const SizedBox(width: Space.xs),
        ],
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title.toUpperCase(),
              style: AppText.display(size, color: fg),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        ...trailing,
      ],
    );
  }
}
