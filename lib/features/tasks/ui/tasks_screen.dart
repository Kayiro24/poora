import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poora/core/providers.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';
import 'package:poora/core/time/date_utils.dart';
import 'package:poora/core/widgets/accent_panel.dart';
import 'package:poora/core/widgets/coral_fab.dart';
import 'package:poora/core/widgets/floating_nav_bar.dart';
import 'package:poora/core/widgets/mascot.dart';
import 'package:poora/core/widgets/pill_chip.dart';
import 'package:poora/core/widgets/screen_header.dart';
import 'package:poora/core/widgets/stat_tile.dart';
import 'package:poora/features/tasks/application/tasks_providers.dart';
import 'package:poora/features/tasks/application/tasks_view.dart';
import 'package:poora/features/tasks/domain/models.dart';
import 'package:poora/features/tasks/ui/month_view.dart';
import 'package:poora/features/tasks/ui/schedule_view.dart';
import 'package:poora/features/tasks/ui/task_actions.dart';
import 'package:poora/features/tasks/ui/task_editor.dart';
import 'package:poora/features/tasks/ui/timeline_view.dart';
import 'package:poora/features/tasks/ui/week_strip.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tasksViewProvider);
    final ctrl = ref.read(tasksViewProvider.notifier);
    final view = state.view;
    final bottom = FloatingNavBar.reservedHeight(context);

    return Scaffold(
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: bottom - 16),
        child: CoralFab(onPressed: () => openEditor(context, date: state.selected)),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.side, Space.m, Space.side - 4, Space.s),
              child: ScreenHeader(
                title: 'Tasks',
                trailing: [
                  PopupMenuButton<TaskView>(
                    tooltip: 'Change view',
                    color: Tokens.surfaceHigh,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.input)),
                    onSelected: ctrl.setView,
                    itemBuilder: (_) => [
                      for (final v in TaskView.values)
                        PopupMenuItem(value: v, child: Text(v.label, style: AppText.bodyL)),
                      if (view == TaskView.month)
                        PopupMenuItem(
                          onTap: ctrl.toggleCompletion,
                          child: Row(
                            children: [
                              Icon(
                                state.showCompletion ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                color: Tokens.coral,
                              ),
                              const SizedBox(width: 8),
                              Text('Show completion', style: AppText.bodyL),
                            ],
                          ),
                        ),
                    ],
                    child: IgnorePointer(
                      child: PillChip(label: view.label, trailingIcon: Icons.expand_more_rounded),
                    ),
                  ),
                  const SizedBox(width: 6),
                  PillChip(label: 'Today', onTap: ctrl.today),
                ],
              ),
            ),
            Expanded(
              child: CustomScrollView(
                key: PageStorageKey('tasks-${view.name}'),
                slivers: [
                  const SliverToBoxAdapter(child: _ExactAlarmBanner()),
                  const SliverToBoxAdapter(child: _StatsPanel()),
                  if (view != TaskView.month)
                    SliverPersistentHeader(pinned: true, delegate: _PinnedStrip()),
                  if (view == TaskView.schedule) ...[
                    const SliverToBoxAdapter(child: ScheduleSearch()),
                    const ScheduleSlivers(),
                  ] else if (view == TaskView.month)
                    const SliverToBoxAdapter(child: MonthView())
                  else
                    SliverToBoxAdapter(child: TimelineView(view: view)),
                  SliverToBoxAdapter(child: SizedBox(height: bottom + 64)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinnedStrip extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => 84;
  @override
  double get maxExtent => 84;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => const WeekStrip();

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}

/// Compact coral panel: mascot + "6 due today" / "4 done". Scrolls away.
class _StatsPanel extends ConsumerWidget {
  const _StatsPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(tasksViewProvider.select((s) => s.selected));
    final today = ref.watch(todayProvider);
    final occ = ref
        .watch(occurrencesProvider(DateRange.day(selected)))
        .where((o) => o.status != OccurrenceStatus.skipped)
        .toList();
    final done = occ.where((o) => o.isDone).length;
    final isToday = Days.same(selected, today);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.side, Space.xs, Space.side, Space.xs),
      child: AccentPanel(
        color: Tokens.coral,
        padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
        child: Row(
          children: [
            StatTile(
              value: '${occ.length}',
              label: isToday ? 'due\ntoday' : 'due\nthat day',
              color: Tokens.textInverse,
            ),
            const SizedBox(width: Space.xxl),
            StatTile(value: '$done', label: 'done', color: Tokens.textInverse),
            const Spacer(),
            Mascot(mood: done == occ.length && occ.isNotEmpty ? MascotMood.happy : MascotMood.calm, size: 56),
          ],
        ),
      ),
    );
  }
}

/// Exact alarms denied (Android 12+): reminders fall back to inexact.
class _ExactAlarmBanner extends ConsumerWidget {
  const _ExactAlarmBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exact = ref.watch(exactAlarmProvider).value ?? true;
    final hasReminders = (ref.watch(taskSnapshotProvider).value?.tasks ?? const <Task>[])
        .any((t) => t.reminders.isNotEmpty);
    if (exact || !hasReminders) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.side, 0, Space.side, Space.s),
      child: Material(
        color: Tokens.sun.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(Radii.input),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.input),
          onTap: () async {
            await ref.read(notificationServiceProvider).requestExact();
            ref.invalidate(exactAlarmProvider);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.alarm_off_rounded, color: Tokens.sun),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Reminders may arrive a few minutes late. Tap to allow exact alarms.',
                    style: AppText.body(13, color: Tokens.sun),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
