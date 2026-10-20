import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poora/core/providers.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';
import 'package:poora/core/time/date_utils.dart';
import 'package:poora/core/widgets/timeline_rail.dart';
import 'package:poora/features/settings/settings_controller.dart';
import 'package:poora/features/tasks/application/tasks_providers.dart';
import 'package:poora/features/tasks/application/tasks_view.dart';
import 'package:poora/features/tasks/domain/models.dart';
import 'package:poora/features/tasks/domain/recurrence.dart';
import 'package:poora/features/tasks/ui/task_actions.dart';
import 'package:poora/features/tasks/ui/task_card.dart';

/// Day, 3 Day and Week views: all-day strip above a 24h rail with a column
/// per day.
class TimelineView extends ConsumerStatefulWidget {
  const TimelineView({required this.view, super.key});
  final TaskView view;

  @override
  ConsumerState<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends ConsumerState<TimelineView> {
  final _anchor = GlobalKey();
  DateRange? _scrolledFor;

  List<DateTime> _days(DateTime selected, bool mondayFirst) {
    final start = widget.view == TaskView.week
        ? Days.weekStart(selected, mondayFirst: mondayFirst)
        : selected;
    return [for (var i = 0; i < widget.view.columns; i++) Days.add(start, i)];
  }

  void _autoScroll(DateRange range) {
    if (_scrolledFor == range) return;
    _scrolledFor = range;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _anchor.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, alignment: 0.25, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tasksViewProvider);
    final settings = ref.watch(settingsProvider);
    final today = ref.watch(todayProvider);
    final now = ref.watch(nowProvider).value ?? DateTime.now();
    final days = _days(state.selected, settings.mondayFirst);
    final range = DateRange(days.first, days.last);
    final occ = ref.watch(occurrencesProvider(range));
    final todayCol = days.indexWhere((d) => Days.same(d, today));
    _autoScroll(range);

    final timed = occ.where((o) => o.isTimed).toList();
    final allDay = occ.where((o) => !o.isTimed).toList();
    final next = timed
        .where((o) => o.status == OccurrenceStatus.pending && o.startAt!.isAfter(now))
        .fold<Occurrence?>(null, (a, o) => a == null || o.startAt!.isBefore(a.startAt!) ? o : a);
    final multi = days.length > 1;
    final anchorMinute = todayCol >= 0 ? now.hour * 60 + now.minute : 8 * 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (multi) _DayHeaders(days: days, today: today),
        _AllDayStrip(days: days, occurrences: allDay),
        _QuotaMet(day: days.length == 1 ? days.first : null),
        Padding(
          padding: const EdgeInsets.only(right: Space.side - 8, left: 4),
          child: Stack(
            children: [
              TimelineRail(
                columns: days.length,
                use24h: settings.use24h,
                now: todayCol >= 0 ? now : null,
                nowColumn: todayCol >= 0 ? todayCol : null,
                items: [
                  for (final o in timed)
                    TimelineItem(
                      id: o.key,
                      column: days.indexWhere((d) => Days.same(d, o.date)),
                      startMinute: o.startMinute!,
                      durationMin: o.durationMin,
                      child: RailCard(occurrence: o, highlight: o == next),
                    ),
                ],
                onCreate: (col, start, dur) => openEditor(
                  context,
                  date: days[col],
                  startMinute: start,
                  durationMin: dur,
                ),
                onMove: (item, col, start) {
                  final o = timed.firstWhere((x) => x.key == item.id);
                  rescheduleOccurrence(context, ref, o, date: days[col], startMinute: start);
                },
              ),
              Positioned(
                top: (anchorMinute / 60) * 64,
                left: 0,
                child: SizedBox(key: _anchor, width: 1, height: 1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayHeaders extends StatelessWidget {
  const _DayHeaders({required this.days, required this.today});
  final List<DateTime> days;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(TimelineRail.labelWidth + 4, 4, Space.side - 8, 4),
      child: Row(
        children: [
          for (final d in days)
            Expanded(
              child: Column(
                children: [
                  Text(
                    days.length > 3 ? d.shortWeekday.substring(0, 1) : d.shortWeekday.toUpperCase(),
                    style: AppText.body(11, color: Tokens.textSecondary),
                  ),
                  Text(
                    '${d.day}',
                    style: AppText.mono(15, color: Days.same(d, today) ? Tokens.ice : Tokens.textPrimary),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AllDayStrip extends StatelessWidget {
  const _AllDayStrip({required this.days, required this.occurrences});
  final List<DateTime> days;
  final List<Occurrence> occurrences;

  @override
  Widget build(BuildContext context) {
    if (occurrences.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, Space.side - 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: TimelineRail.labelWidth,
            child: Padding(
              padding: const EdgeInsets.only(top: 6, right: 8),
              child: Text('all day', textAlign: TextAlign.right, style: AppText.mono(10, color: Tokens.textSecondary)),
            ),
          ),
          for (final d in days)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (final o in occurrences.where((o) => Days.same(o.date, d)))
                      AllDayChip(occurrence: o),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Collapsed group of times-per-week tasks whose quota is met (§4.8).
class _QuotaMet extends ConsumerWidget {
  const _QuotaMet({required this.day});
  final DateTime? day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = day;
    if (d == null) return const SizedBox.shrink();
    final snapshot = ref.watch(taskSnapshotProvider).value;
    if (snapshot == null) return const SizedBox.shrink();
    final gen = ref.watch(generatorProvider);
    final visible = ref.watch(occurrencesProvider(DateRange.day(d))).map((o) => o.task.id).toSet();
    final met = [
      for (final t in snapshot.tasks)
        if (t.isQuota && t.deletedAt == null && !visible.contains(t.id) && gen.occursOn(t, d))
          (t, gen.quotaDone(t, d, snapshot.records)),
    ].where((e) => e.$2 >= (e.$1.quotaPerWeek ?? 1)).toList();
    if (met.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(TimelineRail.labelWidth + 4, 0, Space.side - 8, 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final (t, n) in met)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(color: Tokens.outline),
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
              child: Text(
                '${t.title} · $n/${t.quotaPerWeek} done this week ✓',
                style: AppText.body(12, color: Tokens.textSecondary),
              ),
            ),
        ],
      ),
    );
  }
}
