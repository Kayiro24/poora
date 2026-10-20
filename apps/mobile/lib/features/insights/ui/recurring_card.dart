import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poora/app_router.dart';
import 'package:poora/core/providers.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';
import 'package:poora/core/widgets/accent_panel.dart';
import 'package:poora/core/widgets/arrow_circle_button.dart';
import 'package:poora/features/insights/data/insights_repository.dart';
import 'package:poora/features/insights/ui/charts.dart';
import 'package:poora/features/tasks/domain/recurrence.dart';

/// Per recurring series: rule, this week's x/y + segmented bar, 4-week
/// sparkline, streaks, quota stats (§4.9.3).
class RecurringCard extends ConsumerWidget {
  const RecurringCard({required this.series, super.key});
  final RecurringSeries series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(insightsRepositoryProvider);
    final today = ref.watch(todayProvider);
    final t = series.task;
    final color = Color(t.color);
    final week = repo.week(today);
    final streak = repo.streak(series.seriesId);
    final trend = repo.weeklyTrend(series.seriesId);
    final String progress;
    Widget bar;
    if (t.isQuota) {
      final q = t.quotaPerWeek ?? 1;
      final done = repo.quotaDone(series.seriesId, week.from);
      final met = done >= q;
      progress = '$done of $q this week${met ? ' ✓' : ''}';
      bar = Row(
        children: [
          for (var i = 0; i < q; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Expanded(
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: i < done ? Tokens.mint : Colors.transparent,
                  border: i < done ? null : Border.all(color: Tokens.outline),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ],
      );
    } else {
      final p = repo.weekProgress(series.seriesId, week);
      progress = '${p.done} / ${p.total} done';
      bar = SegmentedBar(segments: p.segments);
    }
    final weeksMet = t.isQuota ? repo.quotaWeeksMet(series.seriesId) : null;
    final unit = t.isQuota ? 'wk' : '';

    return AppCard(
      onTap: () => context.push(Routes.recurring(series.seriesId)),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 6, right: 8),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.title.toUpperCase(), style: AppText.h4, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(RepeatRule.fromTask(t).summary(t.startDate), style: AppText.bodyS),
                  ],
                ),
              ),
              ArrowCircleButton(
                semanticLabel: 'Open ${t.title} history',
                onTap: () => context.push(Routes.recurring(series.seriesId)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('This week', style: AppText.bodyS),
                    const Spacer(),
                    Text(progress, style: AppText.mono(13)),
                  ],
                ),
                const SizedBox(height: 8),
                bar,
                const SizedBox(height: 14),
                Row(
                  children: [
                    _Mini(label: 'streak', value: '${streak.current}$unit'),
                    const SizedBox(width: 18),
                    _Mini(label: 'best', value: '${streak.best}$unit'),
                    if (weeksMet != null) ...[
                      const SizedBox(width: 18),
                      _Mini(label: 'weeks met', value: '${(weeksMet * 100).round()}%'),
                    ],
                    const Spacer(),
                    Sparkline(values: trend, color: Tokens.periSoft),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: AppText.mono(16)),
      Text(label, style: AppText.body(11, color: Tokens.textSecondary)),
    ],
  );
}
