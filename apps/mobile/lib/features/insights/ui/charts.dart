import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';
import 'package:poora/core/time/date_utils.dart';
import 'package:poora/features/insights/domain/metrics.dart';
import 'package:poora/features/tasks/domain/models.dart';
import 'package:poora/features/tasks/domain/recurrence.dart';

/// Categorical palette for the category donut — deeper steps of the brand
/// hues, validated on the dark surface (lightness band, chroma, CVD ΔE ≥ 7.8,
/// normal-vision ΔE ≥ 22.6, ≥ 3:1 contrast). Fixed order, never cycled;
/// a 7th+ category folds into "Other".
const categoryPalette = <Color>[
  Color(0xFFE8604E),
  Color(0xFF2E8CB0),
  Color(0xFFB8861A),
  Color(0xFF8A5FD0),
  Color(0xFF2F9C6E),
  Color(0xFF5C66E8),
];
const otherColor = Color(0xFF6B6B66);

LineTouchData _lineTouch(String Function(double) fmt) => LineTouchData(
  touchTooltipData: LineTouchTooltipData(
    getTooltipColor: (_) => Tokens.surfaceHigh,
    tooltipBorderRadius: BorderRadius.circular(10),
    fitInsideHorizontally: true,
    getTooltipItems: (spots) => [
      for (final s in spots)
        if (s.barIndex == 0 || spots.length == 1)
          LineTooltipItem(fmt(s.y), AppText.mono(12))
        else
          LineTooltipItem('${s.y.round()} scheduled', AppText.body(11, color: Tokens.textSecondary)),
    ],
  ),
);

/// Smooth area of completions per day. [planned] (optional) is a dashed line
/// over the whole range; days after [lastActual] only show the dashed line.
class WeekAreaChart extends StatelessWidget {
  const WeekAreaChart({
    required this.labels,
    required this.actual,
    this.planned,
    this.lastActual,
    this.fill = Tokens.coral,
    this.ink = Tokens.textInverse,
    this.height = 140,
    super.key,
  });

  final List<String> labels;
  final List<double> actual;
  final List<double>? planned;

  /// Index of the last day with real data (today). Null = all.
  final int? lastActual;
  final Color fill;

  /// Axis and dashed-line colour (text ink for the panel it sits on).
  final Color ink;
  final double height;

  @override
  Widget build(BuildContext context) {
    final last = lastActual ?? actual.length - 1;
    final maxY = [...actual, ...?planned, 1.0].where((v) => !v.isNaN).reduce(math.max);
    final bars = <LineChartBarData>[
      LineChartBarData(
        spots: [for (var i = 0; i <= last && i < actual.length; i++) FlSpot(i.toDouble(), actual[i])],
        isCurved: true,
        curveSmoothness: 0.3,
        preventCurveOverShooting: true,
        color: fill,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [fill.withValues(alpha: 0.85), fill.withValues(alpha: 0.25)],
          ),
        ),
      ),
      if (planned != null)
        LineChartBarData(
          // NaN = gap (no dashed line on that day).
          spots: [
            for (var i = 0; i < planned!.length; i++)
              if (planned![i].isNaN) FlSpot.nullSpot else FlSpot(i.toDouble(), planned![i]),
          ],
          isCurved: true,
          curveSmoothness: 0.3,
          preventCurveOverShooting: true,
          color: ink.withValues(alpha: 0.6),
          dashArray: const [4, 4],
          dotData: const FlDotData(show: false),
        ),
    ];
    return Semantics(
      label: 'Completions per day: ${[for (var i = 0; i <= last && i < actual.length; i++) '${labels[i]} ${actual[i].round()}'].join(', ')}',
      excludeSemantics: true,
      child: SizedBox(
        height: height,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY * 1.15,
            minX: 0,
            maxX: (labels.length - 1).toDouble(),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            lineTouchData: _lineTouch((v) => '${v.round()} done'),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: const AxisTitles(),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (v, meta) => SideTitleWidget(
                    meta: meta,
                    child: Text(labels[v.toInt()], style: AppText.body(10, color: ink)),
                  ),
                ),
              ),
            ),
            lineBarsData: bars,
          ),
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
        ),
      ),
    );
  }
}

/// Thin rounded bars on a recessive baseline with per-bar tooltips.
class SimpleBarChart extends StatelessWidget {
  const SimpleBarChart({
    required this.values,
    required this.labels,
    required this.color,
    required this.tooltip,
    this.labelEvery = 1,
    this.height = 140,
    this.semanticsLabel = '',
    super.key,
  });

  final List<double> values;
  final List<String> labels;
  final Color color;
  final String Function(int index, double value) tooltip;
  final int labelEvery;
  final double height;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final maxY = values.fold<double>(1, math.max);
    return Semantics(
      label: semanticsLabel,
      excludeSemantics: true,
      child: SizedBox(
        height: height,
        child: BarChart(
          BarChartData(
            maxY: maxY * 1.15,
            alignment: BarChartAlignment.spaceBetween,
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: maxY / 2,
              getDrawingHorizontalLine: (_) => const FlLine(color: Tokens.outline, strokeWidth: 0.5),
            ),
            borderData: FlBorderData(
              show: true,
              border: const Border(bottom: BorderSide(color: Tokens.outline, width: 0.5)),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => Tokens.surfaceHigh,
                tooltipBorderRadius: BorderRadius.circular(10),
                fitInsideHorizontally: true,
                getTooltipItem: (group, gi, rod, ri) =>
                    BarTooltipItem(tooltip(group.x, rod.toY), AppText.mono(12)),
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: const AxisTitles(),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, meta) => SideTitleWidget(
                    meta: meta,
                    child: Text(
                      v.toInt() % labelEvery == 0 ? labels[v.toInt()] : '',
                      style: AppText.body(10, color: Tokens.textSecondary),
                    ),
                  ),
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < values.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: values[i],
                      color: color,
                      width: values.length > 12 ? 6 : 14,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                ),
            ],
          ),
          duration: const Duration(milliseconds: 360),
        ),
      ),
    );
  }
}

/// 4-week trend sparkline (no axes); null weeks are gaps.
class Sparkline extends StatelessWidget {
  const Sparkline({required this.values, required this.color, super.key});
  final List<double?> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final spots = [
      for (var i = 0; i < values.length; i++)
        if (values[i] == null) FlSpot.nullSpot else FlSpot(i.toDouble(), values[i]!),
    ];
    return Semantics(
      label: 'Last ${values.length} weeks: ${values.map((v) => v == null ? 'none' : '${(v * 100).round()}%').join(', ')}',
      excludeSemantics: true,
      child: SizedBox(
        width: 72,
        height: 28,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: 1.05,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: const FlTitlesData(show: false),
            lineTouchData: const LineTouchData(enabled: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                preventCurveOverShooting: true,
                color: color,
                dotData: FlDotData(
                  checkToShowDot: (s, bar) => s.x == values.length - 1,
                  getDotPainter: (s, p, bar, i) =>
                      FlDotCirclePainter(radius: 3, color: color, strokeWidth: 2, strokeColor: Tokens.surface),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Donut of completed tasks per tag with a direct-labelled legend.
class CategoryDonut extends StatelessWidget {
  const CategoryDonut({required this.entries, super.key});
  final List<MapEntry<String, int>> entries;

  @override
  Widget build(BuildContext context) {
    final top = entries.take(categoryPalette.length).toList();
    final rest = entries.skip(categoryPalette.length).fold(0, (a, e) => a + e.value);
    final slices = [
      for (var i = 0; i < top.length; i++) (top[i].key, top[i].value, categoryPalette[i]),
      if (rest > 0) ('Other', rest, otherColor),
    ];
    final total = slices.fold(0, (a, s) => a + s.$2);
    return Row(
      children: [
        SizedBox.square(
          dimension: 132,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 42,
                  startDegreeOffset: -90,
                  sections: [
                    for (final s in slices)
                      PieChartSectionData(value: s.$2.toDouble(), color: s.$3, radius: 20, showTitle: false),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$total', style: AppText.mono(22)),
                  Text('done', style: AppText.bodyS),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final s in slices)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: s.$3, borderRadius: BorderRadius.circular(3)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(s.$1, style: AppText.bodyM, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      Text('${s.$2}', style: AppText.mono(13, color: Tokens.textSecondary)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// GitHub-style 12-week grid of daily completion %, coral scale (one hue,
/// dim → bright). Rest days are neutral.
class ConsistencyHeatmap extends StatelessWidget {
  const ConsistencyHeatmap({
    required this.days,
    required this.start,
    required this.today,
    this.onTap,
    super.key,
  });

  final Map<DateTime, DayCompletion> days;
  final DateTime start;
  final DateTime today;
  final ValueChanged<DateTime>? onTap;

  static Color colorFor(DayCompletion? c) {
    if (c == null) return Tokens.surface;
    final rate = c.rate;
    switch (c.tier) {
      case DayTier.future:
      case DayTier.beforeFirstUse:
        return Tokens.surface;
      case DayTier.rest:
        return Tokens.surfaceHigh;
      case DayTier.perfect:
      case DayTier.high:
      case DayTier.mid:
      case DayTier.low:
      case DayTier.missed:
      case DayTier.today:
        if (rate == null) return Tokens.surfaceHigh;
        if (rate <= 0) return Tokens.coral.withValues(alpha: 0.12);
        if (rate < 0.5) return Tokens.coral.withValues(alpha: 0.35);
        if (rate < 0.8) return Tokens.coral.withValues(alpha: 0.6);
        if (rate < 1) return Tokens.coral.withValues(alpha: 0.8);
        return Tokens.coral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const weeks = 12;
        const gap = 4.0;
        final cell = ((c.maxWidth - 20 - gap * (weeks - 1)) / weeks).clamp(10.0, 22.0);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 20,
              child: Column(
                children: [
                  for (var i = 0; i < 7; i++)
                    SizedBox(
                      height: cell + gap,
                      child: i.isEven
                          ? Text(weekdayLetters[Days.add(start, i).weekday - 1], style: AppText.body(9, color: Tokens.textSecondary))
                          : null,
                    ),
                ],
              ),
            ),
            for (var w = 0; w < weeks; w++)
              Padding(
                padding: EdgeInsets.only(right: w == weeks - 1 ? 0 : gap),
                child: Column(
                  children: [
                    for (var i = 0; i < 7; i++)
                      () {
                        final d = Days.add(start, w * 7 + i);
                        final dc = days[d];
                        return Semantics(
                          label: '${d.day} ${d.monthShort}: ${dc?.percent == null ? 'no tasks' : '${dc!.percent}%'}',
                          excludeSemantics: true,
                          child: GestureDetector(
                            onTap: onTap == null || d.isAfter(today) ? null : () => onTap!(d),
                            child: Container(
                              width: cell,
                              height: cell,
                              margin: const EdgeInsets.only(bottom: gap),
                              decoration: BoxDecoration(
                                color: colorFor(dc),
                                borderRadius: BorderRadius.circular(4),
                                border: Days.same(d, today) ? Border.all(color: Tokens.ice, width: 1.5) : null,
                              ),
                            ),
                          ),
                        );
                      }(),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// One segment per occurrence: mint done, coral missed, outline upcoming,
/// grey skipped.
class SegmentedBar extends StatelessWidget {
  const SegmentedBar({required this.segments, super.key});
  final List<OccurrenceStatus> segments;

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) {
      return Container(height: 8, decoration: BoxDecoration(color: Tokens.surfaceHigh, borderRadius: BorderRadius.circular(4)));
    }
    return Row(
      children: [
        for (var i = 0; i < segments.length; i++) ...[
          if (i > 0) const SizedBox(width: 3),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: switch (segments[i]) {
                  OccurrenceStatus.done => Tokens.mint,
                  OccurrenceStatus.missed => Tokens.coral,
                  OccurrenceStatus.skipped => Tokens.textSecondary.withValues(alpha: 0.4),
                  OccurrenceStatus.pending => Colors.transparent,
                },
                border: segments[i] == OccurrenceStatus.pending ? Border.all(color: Tokens.outline) : null,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Small legend row: swatch + label, for charts with ≥ 2 series.
class ChartLegend extends StatelessWidget {
  const ChartLegend({required this.items, this.ink = Tokens.textSecondary, super.key});
  final List<(Color, String, bool)> items; // colour, label, dashed
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        for (final (c, label, dashed) in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dashed) Row(
                      children: [
                        for (var i = 0; i < 3; i++)
                          Container(width: 4, height: 2, margin: const EdgeInsets.only(right: 2), color: c),
                      ],
                    ) else Container(width: 12, height: 8, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 6),
              Text(label, style: AppText.body(11, color: ink)),
            ],
          ),
      ],
    );
  }
}
