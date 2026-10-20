import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';

/// Bottom-sheet wheel picker with mono numbers (§4.2 break timings).
Future<int?> showWheelPicker(
  BuildContext context, {
  required String title,
  required int min,
  required int max,
  required int value,
  int step = 1,
  String unit = 'min',
  Color accent = Tokens.sage,
}) {
  final values = [for (var v = min; v <= max; v += step) v];
  var selected = values.indexOf(value).clamp(0, values.length - 1);
  return showModalBottomSheet<int>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title.toUpperCase(), style: AppText.h3),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoPicker(
                      itemExtent: 44,
                      scrollController: FixedExtentScrollController(initialItem: selected),
                      selectionOverlay: Container(
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(Radii.input),
                        ),
                      ),
                      onSelectedItemChanged: (i) {
                        selected = i;
                        HapticFeedback.selectionClick();
                      },
                      children: [
                        for (final v in values)
                          Center(child: Text('$v', style: AppText.mono(26))),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 72,
                    child: Text(unit, style: AppText.body(16, color: Tokens.textSecondary)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Tokens.textInverse,
                  shape: const StadiumBorder(),
                ),
                onPressed: () => Navigator.pop(context, values[selected]),
                child: Text('Done', style: AppText.label.copyWith(color: Tokens.textInverse)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
