import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poora/core/app_info.dart';
import 'package:poora/core/providers.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';
import 'package:poora/core/time/date_utils.dart';
import 'package:poora/core/time/format.dart';
import 'package:poora/core/widgets/accent_panel.dart';
import 'package:poora/core/widgets/common.dart';
import 'package:poora/core/widgets/mascot.dart';
import 'package:poora/core/widgets/screen_header.dart';
import 'package:poora/core/widgets/stat_tile.dart';
import 'package:poora/features/focus/application/focus_draft.dart';
import 'package:poora/features/focus/domain/focus_history.dart';
import 'package:poora/features/focus/domain/focus_session.dart';
import 'package:poora/features/focus/ui/focus_breakdown.dart';
import 'package:poora/features/insights/ui/charts.dart';
import 'package:poora/features/settings/settings_controller.dart';
import 'package:poora/features/tasks/application/tasks_providers.dart';
import 'package:poora/features/tasks/domain/recurrence.dart';

/// Focus history: today / this week, daily bars, and sessions grouped by task.
class FocusHistoryScreen extends ConsumerWidget {
  const FocusHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(focusSessionsProvider).value ?? const <FocusSessionRecord>[];
    final today = ref.watch(todayProvider);
    final mondayFirst = ref.watch(settingsProvider.select((s) => s.mondayFirst));
    final week = DateRange.week(today, mondayFirst: mondayFirst);
    final todayTotals = FocusHistory.totals(FocusHistory.inRange(sessions, DateRange.day(today)));
    final weekSessions = FocusHistory.inRange(sessions, week);
    final weekTotals = FocusHistory.totals(weekSessions);
    final daily = FocusHistory.minutesByDay(sessions, week);
    final groups = FocusHistory.byTask(sessions);
    final goal = ref.watch(settingsProvider.select((s) => s.dailyFocusGoalMin));
    final goalDays = FocusHistory.goalDays(sessions, goal, week);
    final streak = FocusHistory.goalStreak(sessions, goal, today);
    final days = week.days.toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.side, Space.m, Space.side, Space.x4),
          children: [
            ScreenHeader(title: 'Focus history', size: 32, onBack: () => Navigator.pop(context)),
            Text('${AppInfo.motto} No leaderboards — only your own days.', style: AppText.body(14, color: Tokens.textSecondary)),
            const SizedBox(height: Space.l),
            AccentPanel(
              color: Tokens.sage,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: StatTile(value: fmtMs(todayTotals.focusMs), label: 'today', color: Tokens.textInverse, size: 26),
                      ),
                      Expanded(
                        child: StatTile(value: fmtMs(weekTotals.focusMs), label: 'this week', color: Tokens.textInverse, size: 26),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SimpleBarChart(
                    values: [for (final d in days) daily[d] ?? 0],
                    labels: [for (final d in days) d.shortWeekday.substring(0, 1)],
                    color: Tokens.textInverse,
                    height: 110,
                    semanticsLabel: 'Focus minutes per day this week',
                    tooltip: (i, v) => '${days[i].dayMonth} · ${v.round()} min',
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.l),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('THIS WEEK', style: AppText.display(18, color: Tokens.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 20,
                    runSpacing: 10,
                    children: [
                      StatTile(value: '${weekTotals.sessions}', label: 'sessions', size: 22, labelColor: Tokens.textSecondary),
                      StatTile(value: '$goalDays/7', label: 'goal days', size: 22, color: Tokens.mint, labelColor: Tokens.textSecondary),
                      StatTile(value: '$streak', label: 'day streak', size: 22, labelColor: Tokens.textSecondary),
                      StatTile(value: '${weekTotals.interruptions}', label: 'interruptions', size: 22, labelColor: Tokens.textSecondary),
                      if (weekTotals.interruptionsPerHour != null)
                        StatTile(
                          value: weekTotals.interruptionsPerHour!.toStringAsFixed(1),
                          label: 'per focus hour',
                          size: 22,
                          labelColor: Tokens.textSecondary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FocusBreakdown(
                    focusMs: weekTotals.focusMs,
                    pausedMs: weekTotals.pausedMs,
                    awayMs: weekTotals.awayMs,
                    interruptions: weekTotals.interruptions,
                    appUsageMs: weekTotals.appUsageMs,
                    distractions: {for (final e in FocusHistory.distractingApps(weekSessions)) e.key: e.value},
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.xxl),
            const SectionTitle('By task'),
            if (groups.isEmpty)
              const EmptyState(message: 'Start a focus session — from Focus or straight from a task — and it will show up here.', mood: MascotMood.calm)
            else
              for (final g in groups)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _GroupCard(group: g),
                ),
          ],
        ),
      ),
    );
  }
}

class _GroupCard extends ConsumerWidget {
  const _GroupCard({required this.group});
  final TaskFocusGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(taskSnapshotProvider).value;
    final task = group.taskId == null ? null : snapshot?.taskById(group.taskId!);
    final title = group.taskId == null ? 'Without a task' : (task?.title ?? 'Deleted task');
    final use24h = ref.watch(settingsProvider.select((s) => s.use24h));
    return Material(
      color: Tokens.surface,
      borderRadius: BorderRadius.circular(Radii.inner),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: Tokens.textSecondary,
        collapsedIconColor: Tokens.textSecondary,
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: task == null ? Tokens.outline : Color(task.color), shape: BoxShape.circle),
        ),
        title: Text(title.toUpperCase(), style: AppText.h4, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${fmtMs(group.totals.focusMs)} focus · ${group.totals.sessions} session${group.totals.sessions == 1 ? '' : 's'} · '
          '${group.totals.interruptions} interruption${group.totals.interruptions == 1 ? '' : 's'}',
          style: AppText.bodyS,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          for (final s in group.sessions)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Tokens.surfaceHigh, borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${s.startedAt.shortWeekday} ${Days.of(s.startedAt).dayMonth} · ${Fmt.time(s.startedAt, use24h: use24h)}',
                          style: AppText.body(13, weight: FontWeight.w500),
                        ),
                      ),
                      Text(s.endedEarly ? 'ended early' : 'completed', style: AppText.body(12, color: s.endedEarly ? Tokens.coralSoft : Tokens.mint)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  FocusBreakdown(
                    dense: true,
                    focusMs: s.focusMsCompleted,
                    pausedMs: s.pausedMs,
                    awayMs: s.awayMs,
                    interruptions: s.interruptions,
                    appUsageMs: s.appUsageMs,
                    distractions: s.distractions,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
