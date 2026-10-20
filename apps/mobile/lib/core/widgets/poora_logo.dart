import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:poora/core/app_info.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';

/// The Poora mark: a P whose bowl is a completion ring that has just closed.
/// Coral stem (the action), sage ring (the day), ice closing stroke.
/// Geometry matches `tool/render_logo.py`, which renders the app icons.
class PooraMark extends StatelessWidget {
  const PooraMark({this.size = 64, this.progress = 1, super.key});

  /// Height of the mark.
  final double size;

  /// 0 → 1 draws the stem, then the ring, then the ice closing stroke.
  final double progress;

  // Bounding box on the 1024 design grid.
  static const _x0 = 300.0, _y0 = 190.0, _x1 = 818.0, _y1 = 850.0;
  static const aspect = (_x1 - _x0) / (_y1 - _y0);

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${AppInfo.name} logo',
    image: true,
    child: CustomPaint(
      size: Size(size * aspect, size),
      painter: _MarkPainter(progress.clamp(0, 1)),
    ),
  );
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.height / (PooraMark._y1 - PooraMark._y0);
    Offset p(double x, double y) => Offset((x - PooraMark._x0) * k, (y - PooraMark._y0) * k);
    double seg(double a, double b) => ((t - a) / (b - a)).clamp(0, 1);

    final ring = Rect.fromCircle(center: p(566, 420), radius: 176 * k);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 104 * k
      ..strokeCap = StrokeCap.round;
    double rad(double deg) => deg * math.pi / 180;

    // Ring (sage): 180° → 480°, then ice closing stroke 470° → 540°.
    final sage = seg(0.25, 0.8);
    if (sage > 0) {
      canvas.drawArc(ring, rad(180), rad(300 * sage), false, stroke..color = Tokens.sage);
    }
    final ice = seg(0.75, 1);
    if (ice > 0) {
      canvas.drawArc(ring, rad(470), rad(70 * ice), false, stroke..color = Tokens.ice);
    }
    // Stem (coral) grows downward and sits on top of the ring's left edge.
    final stem = seg(0, 0.35);
    if (stem > 0) {
      final top = p(300, 190);
      final bottom = p(420, 190 + 660 * stem);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromPoints(top, bottom), Radius.circular(60 * k)),
        Paint()..color = Tokens.coral,
      );
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.t != t;
}

/// Mark + "POORA" wordmark, optionally with the tagline underneath.
class PooraWordmark extends StatelessWidget {
  const PooraWordmark({this.size = 40, this.tagline = false, this.color = Tokens.textPrimary, super.key});

  final double size;
  final bool tagline;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PooraMark(size: size),
            SizedBox(width: size * 0.3),
            Text(AppInfo.name.toUpperCase(), style: AppText.display(size * 1.05, color: color)),
          ],
        ),
        if (tagline) ...[
          SizedBox(height: size * 0.25),
          Text(AppInfo.tagline, style: AppText.body(size * 0.38, color: Tokens.textSecondary)),
        ],
      ],
    );
  }
}
