import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';
import 'package:poora/core/time/format.dart';
import 'package:poora/features/focus/domain/timer_engine.dart';

/// Paper clock face with minute dots and five-minute bars. The planned focus
/// arc is coral, the break arc sageDeep (after a small gap), both starting at
/// the current minute, which a notch on the rim points to. One turn of
/// the dial is 60 minutes (or more, in hour steps, for long plans).
class FocusDial extends StatelessWidget {
  const FocusDial({required this.config, required this.now, required this.use24h, super.key});

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
                Text('${config.focusMin}', style: AppText.mono(56, color: Tokens.textInverse)),
                const SizedBox(height: 4),
                Text('MIN FOCUS', style: AppText.display(14, color: Tokens.textInverse.withValues(alpha: 0.6))),
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

  static Offset _at(double a) => Offset(math.cos(a), math.sin(a));

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    const ink = Tokens.textInverse;
    // Warm paper face with a fine inner bezel.
    canvas
      ..drawCircle(c, r, Paint()..color = Tokens.paper)
      ..drawCircle(
        c,
        r - 4,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = ink.withValues(alpha: 0.08),
      );

    // Minute dots; every fifth minute a short rounded bar.
    final dot = Paint()..color = ink.withValues(alpha: 0.3);
    final bar = Paint()
      ..color = ink.withValues(alpha: 0.75)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 60; i++) {
      final dir = _at(i / 60 * 2 * math.pi - math.pi / 2);
      if (i % 5 == 0) {
        canvas.drawLine(c + dir * (r - 19), c + dir * (r - 12), bar);
      } else {
        canvas.drawCircle(c + dir * (r - 14), 1.1, dot);
      }
    }

    final planned = config.focusMin + config.shortMin;
    final span = (planned / 60).ceil() * 60.0; // minutes per full turn
    // Quarter numerals (minutes past the hour) when one turn is one hour.
    if (span == 60) {
      for (final m in const [0, 15, 30, 45]) {
        final tp = TextPainter(
          text: TextSpan(text: m.toString().padLeft(2, '0'), style: AppText.mono(10, color: ink.withValues(alpha: 0.45))),
          textDirection: TextDirection.ltr,
        )..layout();
        final pos = c + _at(m / 60 * 2 * math.pi - math.pi / 2) * (r - 30);
        tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
      }
    }

    final startMinute = now.minute + now.second / 60;
    final start = startMinute / 60 * 2 * math.pi - math.pi / 2;
    final focusSweep = config.focusMin / span * 2 * math.pi;
    final breakSweep = config.shortMin / span * 2 * math.pi;
    const gap = 0.06; // a breath between focus and break
    final arcR = r - 46;
    final rect = Rect.fromCircle(center: c, radius: arcR);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(
      c,
      arcR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..color = Tokens.sage.withValues(alpha: 0.3),
    );
    if (breakSweep > gap * 2) {
      canvas.drawArc(rect, start + focusSweep + gap, breakSweep - gap, false, arc..color = Tokens.sageDeep);
    }
    canvas.drawArc(rect, start, focusSweep, false, arc..color = Tokens.coral);

    // "Now" notch: a small pointer on the rim, aimed inward.
    final dir = _at(start);
    final side = Offset(-dir.dy, dir.dx);
    final tip = c + dir * (r - 22);
    final base = c + dir * (r - 6);
    canvas
      ..drawPath(
        Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo((base + side * 6).dx, (base + side * 6).dy)
          ..lineTo((base - side * 6).dx, (base - side * 6).dy)
          ..close(),
        Paint()..color = ink,
      )
      ..drawCircle(c + dir * arcR, 3, Paint()..color = Tokens.paper);
  }

  @override
  bool shouldRepaint(_DialPainter old) => old.config != config || old.now.minute != now.minute;
}
