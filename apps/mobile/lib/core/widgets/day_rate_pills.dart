import 'package:flutter/material.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';

class DayPill {
  const DayPill({
    required this.date,
    required this.label,
    this.percent,
    this.isToday = false,
    this.isFuture = false,
  });

  final DateTime date;
  final String label;

  /// Null renders "–" (no tasks that day).
  final int? percent;
  final bool isToday;
  final bool isFuture;
}

/// Row of circular day bubbles with a percentage inside. Today is filled
/// dark; future days are hatched and dimmed.
class DayRatePills extends StatelessWidget {
  const DayRatePills({required this.days, this.onTap, super.key});

  final List<DayPill> days;
  final ValueChanged<DayPill>? onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final size = ((c.maxWidth - 6 * 6) / 7).clamp(32.0, 46.0);
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [for (final d in days) _bubble(d, size)],
        );
      },
    );
  }

  Widget _bubble(DayPill d, double size) {
    final text = d.percent == null ? '–' : '${d.percent}%';
    final Color bg;
    final Color fg;
    if (d.isToday) {
      bg = Tokens.bg;
      fg = Tokens.textPrimary;
    } else if (d.isFuture) {
      bg = Tokens.white.withValues(alpha: 0.35);
      fg = Tokens.textInverse.withValues(alpha: 0.75);
    } else {
      bg = Tokens.white;
      fg = Tokens.textInverse;
    }
    return Semantics(
      button: onTap != null,
      label: '${d.label}, ${d.percent == null ? 'no tasks' : '$text done'}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap == null ? null : () => onTap!(d),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: CustomPaint(
                painter: d.isFuture ? _HatchPainter() : null,
                child: Center(
                  child: Text(
                    text,
                    style: AppText.mono(size < 40 ? 10 : 11, color: fg),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              d.label,
              style: AppText.body(
                11,
                weight: FontWeight.w500,
                color: Tokens.textInverse,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HatchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipPath(Path()..addOval(Offset.zero & size));
    final p = Paint()
      ..color = Tokens.textInverse.withValues(alpha: 0.12)
      ..strokeWidth = 1.2;
    for (var x = -size.height; x < size.width; x += 6) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
