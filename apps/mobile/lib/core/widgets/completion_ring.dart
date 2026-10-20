import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:poora/core/theme/tokens.dart';

/// Ring whose arc length is an exact fraction, drawn clockwise from 12
/// o'clock. Animates to new values ("the ring animates to its new value").
class CompletionRing extends StatelessWidget {
  const CompletionRing({
    required this.value,
    required this.color,
    this.size = 44,
    this.stroke = 3,
    this.track = Tokens.surfaceHigh,
    this.fill,
    this.glow = false,
    this.duration = const Duration(milliseconds: 420),
    this.delay = Duration.zero,
    this.child,
    super.key,
  });

  final double value;
  final Color color;
  final double size;
  final double stroke;
  final Color track;
  final Color? fill;
  final bool glow;
  final Duration duration;
  final Duration delay;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0, 1)),
      duration: duration + delay,
      curve: Interval(
        (duration + delay).inMicroseconds == 0
            ? 0
            : delay.inMicroseconds / (duration + delay).inMicroseconds,
        1,
        curve: Curves.easeOutCubic,
      ),
      builder: (context, v, c) => CustomPaint(
        size: Size.square(size),
        painter: RingPainter(
          value: v,
          color: color,
          stroke: stroke,
          track: track,
          fill: fill,
          glow: glow,
        ),
        child: SizedBox.square(dimension: size, child: Center(child: c)),
      ),
      child: child,
    );
  }
}

class RingPainter extends CustomPainter {
  RingPainter({
    required this.value,
    required this.color,
    required this.stroke,
    required this.track,
    this.fill,
    this.glow = false,
  });

  final double value;
  final Color color;
  final double stroke;
  final Color track;
  final Color? fill;
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - stroke / 2 - (glow ? 2 : 0);
    if (fill != null) {
      canvas.drawCircle(center, radius, Paint()..color = fill!);
    }
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (value <= 0) return;
    final rect = Rect.fromCircle(center: center, radius: radius);
    if (glow) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * value,
        false,
        Paint()
          ..color = color.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke + 2
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * value,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = value >= 1 ? StrokeCap.butt : StrokeCap.round
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(RingPainter old) =>
      old.value != value ||
      old.color != color ||
      old.fill != fill ||
      old.track != track ||
      old.glow != glow;
}
