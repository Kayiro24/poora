import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';
import 'package:poora/core/time/format.dart';
import 'package:poora/features/focus/domain/timer_engine.dart';

/// White clock face with fine radial ticks. The planned focus arc is coral,
/// the break arc sageDeep, both starting at the current minute. One turn of
/// the dial is 60 minutes (or more, in hour steps, for long plans).
class FocusDial extends StatelessWidget {
  const FocusDial({
    required this.config,
    required this.now,
    required this.use24h,
    super.key,
  });

  final FocusConfig config;
  final DateTime now;
  final bool use24h;

  @override
  Widget build(BuildContext context) {
    final end = now.add(Duration(minutes: config.focusMin));
    return Semantics(
      label:
          'Plan: ${config.focusMin} minutes focus, ${config.shortMin} minutes break, '
          'ending at ${Fmt.time(end, use24h: use24h)}',
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: 1,
        child: CustomPaint(
          painter: _DialPainter(config: config, now: now),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${config.focusMin}',
                  style: AppText.mono(56, color: Tokens.textInverse),
                ),
                const SizedBox(height: 4),
                Text(
                  'MIN FOCUS',
                  style: AppText.display(14, color: Tokens.textInverse.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 8),
                Text(
                  '→ ${Fmt.time(end, use24h: use24h)}',
                  style: AppText.mono(13, color: Tokens.textInverse.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({required this.config, required this.now});

  final FocusConfig config;
  final DateTime now;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.drawCircle(c, r, Paint()..color = Tokens.white);

    // Fine radial ticks: 120 marks, every 10th long.
    final tick = Paint()
      ..color = Tokens.textInverse.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    final strong = Paint()
      ..color = Tokens.textInverse.withValues(alpha: 0.8)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 120; i++) {
      final a = i / 120 * 2 * math.pi - math.pi / 2;
      final long = i % 10 == 0;
      final outer = r - 8;
      final inner = outer - (long ? 12 : 6);
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + dir * inner, c + dir * outer, long ? strong : tick);
    }

    final planned = config.focusMin + config.shortMin;
    final span = (planned / 60).ceil() * 60.0; // minutes per full turn
    final startMinute = now.minute + now.second / 60;
    final start = startMinute / 60 * 2 * math.pi - math.pi / 2;
    final focusSweep = config.focusMin / span * 2 * math.pi;
    final breakSweep = config.shortMin / span * 2 * math.pi;
    final arcR = r - 34;
    final rect = Rect.fromCircle(center: c, radius: arcR);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawCircle(
        c,
        arcR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..color = Tokens.sage.withValues(alpha: 0.35),
      )
      ..drawArc(rect, start + focusSweep, breakSweep, false, arc..color = Tokens.sageDeep)
      ..drawArc(rect, start, focusSweep, false, arc..color = Tokens.coral);

    // "Now" hand.
    final dir = Offset(math.cos(start), math.sin(start));
    canvas
      ..drawLine(
        c + dir * (arcR - 18),
        c + dir * (r - 6),
        Paint()
          ..color = Tokens.textInverse
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      )
      ..drawCircle(c + dir * (r - 6), 4, Paint()..color = Tokens.textInverse);
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.config != config || old.now.minute != now.minute;
}
