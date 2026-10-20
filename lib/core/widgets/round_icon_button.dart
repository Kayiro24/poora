import 'package:flutter/material.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/widgets/arrow_circle_button.dart' show ArrowCircleButton;

/// 40px circular icon button — the base of back buttons, header actions and
/// [ArrowCircleButton].
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.background = Tokens.surfaceHigh,
    this.foreground = Tokens.textPrimary,
    this.size = 40,
    this.badge = false,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String semanticLabel;
  final Color background;
  final Color foreground;
  final double size;

  /// Small coral dot at the top-right (e.g. overdue tasks on the bell).
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: SizedBox.square(
        dimension: 48, // accessible hit area around the 40px visual
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: background,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onTap,
                  child: SizedBox.square(
                    dimension: size,
                    child: Icon(icon, size: size * 0.5, color: foreground),
                  ),
                ),
              ),
              if (badge)
                Positioned(
                  right: 1,
                  top: 1,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Tokens.coral,
                      shape: BoxShape.circle,
                      border: Border.all(color: Tokens.bg, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
