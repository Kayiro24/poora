import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poora/app_router.dart';
import 'package:poora/core/providers.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';
import 'package:poora/core/time/date_utils.dart';
import 'package:poora/core/time/format.dart';
import 'package:poora/core/widgets/accent_panel.dart';
import 'package:poora/core/widgets/common.dart';
import 'package:poora/core/widgets/pill_chip.dart';
import 'package:poora/core/widgets/screen_header.dart';
import 'package:poora/core/widgets/stat_tile.dart';
import 'package:poora/features/insights/data/insights_repository.dart';
import 'package:poora/features/insights/ui/charts.dart';
import 'package:poora/features/insights/ui/completion_calendar.dart';
import 'package:poora/features/settings/settings_controller.dart';
import 'package:poora/features/tasks/domain/models.dart';
import 'package:poora/features/tasks/domain/recurrence.dart';

/// Recurring task detail: 12-week heatmap and full history.
class RecurringDetailScreen extends ConsumerWidget {
  const RecurringDetailScreen({required this.taskId, super.key});

  /// Series id (route param keeps the historical name).
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(insightsRepositoryProvider);
    final today = ref.watch(todayProvider);
    final mondayFirst = ref.watch(settingsProvider.select((s) => s.mondayFirst));
    final task = repo.seriesTask(taskId);
    if (task == null) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Space.side),
            child: Column(
              children: [
                ScreenHeader(title: 'Task', onBack: () => Navigator.pop(context)),
                const EmptyState(message: 'This task no longer exists.'),
              ],
            ),
          ),
        ),
      );
    }
    final start = Days.add(Days.weekStart(today, mondayFirst: mondayFirst), -77);
    final range = DateRange(start, Days.add(start, 83));
    final filter = CalendarFilter.series(taskId);
    final days = repo.dayCompletion(range, filter: filter);
    final streak = repo.streak(taskId);
    final history = repo
        .seriesOccurrences(taskId, DateRange(Days.add(today, -365), today))
        .where((o) => o.status != OccurrenceStatus.pending || Days.same(o.date, today))
        .toList()
        .reversed
        .toList();
    final unit = task.isQuota ? ' wk' : '';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.side, Space.m, Space.side, Space.x4),
          children: [
            ScreenHeader(title: task.title, size: 32, onBack: () => Navigator.pop(context)),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 52),
              child: Text(RepeatRule.fromTask(task).summary(task.startDate), style: AppText.bodyS),
            ),
            const SizedBox(height: Space.xl),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                StatTile(value: '${streak.current}$unit', label: 'current\nstreak', color: Tokens.sun, labelColor: Tokens.textSecondary),
                StatTile(value: '${streak.best}$unit', label: 'best\nstreak', labelColor: Tokens.textSecondary),
                if (task.isQuota)
                  StatTile(
                    value: () {
                      final m = repo.quotaWeeksMet(taskId);
                      return m == null ? '–' : '${(m * 100).round()}%';
                    }(),
                    label: 'weeks\nquota met',
                    labelColor: Tokens.textSecondary,
                  ),
              ],
            ),
            const SizedBox(height: Space.xxl),
            SectionTitle(
              'Last 12 weeks',
              trailing: PillChip(
                label: 'Calendar',
                icon: Icons.calendar_month_rounded,
                dense: true,
                onTap: () => context.push(Routes.calendar(filter: filter.encoded)),
              ),
            ),
            AppCard(
              child: ConsistencyHeatmap(
                days: days,
                start: start,
                today: today,
                onTap: (d) => showDayDetailSheet(context, d),
              ),
            ),
            const SizedBox(height: Space.xxl),
            const SectionTitle('History'),
            if (history.isEmpty)
              const EmptyState(message: 'No history yet — the first one is the hardest.', compact: true)
            else
              for (final o in history.take(120))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _HistoryRow(occurrence: o),
                ),
          ],
        ),
      ),
    );
  }
}

class _HistoryRow extends ConsumerWidget {
  const _HistoryRow({required this.occurrence});
  final Occurrence occurrence;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final o = occurrence;
    final use24h = ref.watch(settingsProvider.select((s) => s.use24h));
    final (icon, color, label) = switch (o.status) {
      OccurrenceStatus.done => (Icons.check_circle_rounded, Tokens.mint, o.late ? 'Done late' : o.onTime ? 'Done on time' : 'Done'),
      OccurrenceStatus.missed => (Icons.cancel_rounded, Tokens.coral, 'Missed'),
      OccurrenceStatus.skipped => (Icons.remove_circle_rounded, Tokens.textSecondary, 'Skipped'),
      OccurrenceStatus.pending => (Icons.radio_button_unchecked_rounded, Tokens.ice, 'Today'),
    };
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      radius: Radii.inner,
      onTap: () => showDayDetailSheet(context, o.date),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text('${o.date.shortWeekday} ${o.date.dayMonth} ${o.date.year}', style: AppText.bodyM),
          ),
          Text(label, style: AppText.body(12, color: Tokens.textSecondary)),
          const SizedBox(width: 10),
          Text(
            o.completedAt == null ? '' : Fmt.time(o.completedAt!, use24h: use24h),
            style: AppText.mono(11, color: Tokens.textSecondary),
          ),
        ],
      ),
    );
  }
}
