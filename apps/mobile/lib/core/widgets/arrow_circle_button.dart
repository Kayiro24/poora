import 'package:flutter/material.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/widgets/round_icon_button.dart';

/// 40px white circle with a ↗ arrow; sits at a card's top-right and opens
/// detail.
class ArrowCircleButton extends StatelessWidget {
  const ArrowCircleButton({
    required this.onTap,
    this.semanticLabel = 'Open',
    this.background = Tokens.white,
    super.key,
  });

  final VoidCallback? onTap;
  final String semanticLabel;
  final Color background;

  @override
  Widget build(BuildContext context) => RoundIconButton(
    icon: Icons.north_east_rounded,
    onTap: onTap,
    semanticLabel: semanticLabel,
    background: background,
    foreground: Tokens.textInverse,
  );
}
