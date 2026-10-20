import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poora/core/providers.dart';
import 'package:poora/core/time/date_utils.dart';
import 'package:poora/features/focus/application/focus_draft.dart';
import 'package:poora/features/focus/domain/focus_session.dart';
import 'package:poora/features/insights/domain/metrics.dart';
import 'package:poora/features/settings/settings_controller.dart';
import 'package:poora/features/tasks/application/tasks_providers.dart';
import 'package:poora/features/tasks/domain/models.dart';
import 'package:poora/features/tasks/domain/occurrence_generator.dart';

/// Filter for the completion calendar: everything, one tag, or one series.
class CalendarFilter {
  const CalendarFilter.all() : tag = null, seriesId = null;
  const CalendarFilter.tag(String this.tag) : seriesId = null;
  const CalendarFilter.series(String this.seriesId) : tag = null;

  final String? tag;
  final String? seriesId;

  bool get isAll => tag == null && seriesId == null;

  /// Query-string form: `tag:Health` / `task:{seriesId}`.
  String? get encoded => tag != null
      ? 'tag:$tag'
      : seriesId != null
      ? 'task:$seriesId'
      : null;

  static CalendarFilter decode(String? s) {
    if (s == null) return const CalendarFilter.all();
    if (s.startsWith('tag:')) return CalendarFilter.tag(s.substring(4));
    if (s.startsWith('task:')) return CalendarFilter.series(s.substring(5));
    return const CalendarFilter.all();
  }

  bool matches(Occurrence o) =>
      (tag == null || o.task.tag?.trim() == tag) &&
      (seriesId == null || o.task.seriesId == seriesId);

  @override
  bool operator ==(Object other) =>
      other is CalendarFilter && other.tag == tag && other.seriesId == seriesId;

  @override
  int get hashCode => Object.hash(tag, seriesId);
}

/// One recurring series (all "this and following" pieces share a seriesId).
class RecurringSeries {
  const RecurringSeries({required this.seriesId, required this.task});
  final String seriesId;

  /// Latest piece of the series — its title/colour/rule represent it.
  final Task task;
}

/// The only way charts read data (§7). Pure computation over a snapshot;
/// results are cached for the lifetime of this instance, which Riverpod
/// replaces whenever tasks, records, sessions or today change.
class InsightsRepository {
  InsightsRepository({
    required this.snapshot,
    required this.sessions,
    required this.generator,
    required this.today,
    required this.mondayFirst,
  });

  final TaskSnapshot snapshot;
  final List<FocusSessionRecord> sessions;
  final OccurrenceGenerator generator;
  final DateTime today;
  final bool mondayFirst;

  final Map<DateRange, List<Occurrence>> _occCache = {};
  final Map<(DateRange, CalendarFilter), Map<DateTime, DayCompletion>> _dayCache = {};

  /// Earliest task creation day; earlier days are "before first use".
  late final DateTime? firstUse = () {
    DateTime? first;
    for (final t in snapshot.tasks) {
      final d = Days.of(t.createdAt);
      if (first == null || d.isBefore(first)) first = d;
    }
    return first;
  }();

  bool get hasData => snapshot.tasks.isNotEmpty;

  List<Occurrence> occurrences(DateRange r) => _occCache.putIfAbsent(
    r,
    () => generator.generate(snapshot: snapshot, range: r, today: today),
  );

  DateRange week(DateTime d) => DateRange.week(d, mondayFirst: mondayFirst);

  /// Day states for [r]; cached per (range, filter).
  Map<DateTime, DayCompletion> dayCompletion(
    DateRange r, {
    CalendarFilter filter = const CalendarFilter.all(),
  }) => _dayCache.putIfAbsent((r, filter), () {
    final occ = occurrences(r).where(filter.matches).toList();
    final series = filter.seriesId == null ? null : seriesTask(filter.seriesId!);
    if (series != null && series.isQuota) return _habitQuota(r, occ);
    return Metrics.dayCompletions(r, occ, today: today, firstUse: firstUse);
  });

  /// Quota habits are weekly: a day is green when done, otherwise neutral.
  Map<DateTime, DayCompletion> _habitQuota(DateRange r, List<Occurrence> occ) => {
    for (final d in r.days)
      d: () {
        final done = occ.where((o) => o.date == d && o.isDone).length;
        final tier = done > 0
            ? DayTier.perfect
            : d.isAfter(today)
            ? DayTier.future
            : (firstUse != null && d.isBefore(firstUse!))
            ? DayTier.beforeFirstUse
            : DayTier.rest;
        return DayCompletion(day: d, tier: tier, done: done);
      }(),
  };

  // --- Headline -----------------------------------------------------------

  int doneCount(DateRange r) => Metrics.doneCount(occurrences(r));
  double? completionRate(DateRange r) => Metrics.completionRate(occurrences(r));

  int overallStreak() {
    final days = dayCompletion(DateRange(Days.add(today, -400), today));
    return Metrics.overallDayStreak(days, today: today);
  }

  /// Longest run of perfect days in [r] (month summary "best streak").
  int bestPerfectRun(DateRange r, {CalendarFilter filter = const CalendarFilter.all()}) {
    var best = 0, run = 0;
    final days = dayCompletion(r, filter: filter);
    for (final d in r.days) {
      final c = days[d]!;
      if (c.isPerfect) {
        run++;
        if (run > best) best = run;
      } else if (c.tier != DayTier.rest) {
        run = 0;
      }
    }
    return best;
  }

  // --- Recurring ------------------------------------------------------------

  List<RecurringSeries> recurringSeries() {
    final bySeries = <String, Task>{};
    for (final t in snapshot.tasks) {
      if (!t.isRecurring) continue;
      final cur = bySeries[t.seriesId];
      if (cur == null || t.startDate.isAfter(cur.startDate)) bySeries[t.seriesId] = t;
    }
    final out = [
      for (final e in bySeries.entries) RecurringSeries(seriesId: e.key, task: e.value),
    ]..sort((a, b) => a.task.title.toLowerCase().compareTo(b.task.title.toLowerCase()));
    return out;
  }

  Task? seriesTask(String seriesId) {
    Task? best;
    for (final t in snapshot.tasks) {
      if (t.seriesId != seriesId) continue;
      if (best == null || t.startDate.isAfter(best.startDate)) best = t;
    }
    return best;
  }

  DateTime _seriesStart(String seriesId) {
    var start = today;
    for (final t in snapshot.tasks) {
      if (t.seriesId == seriesId && t.startDate.isBefore(start)) start = t.startDate;
    }
    return start;
  }

  List<Occurrence> seriesOccurrences(String seriesId, DateRange r) =>
      occurrences(r).where((o) => o.task.seriesId == seriesId).toList();

  /// Segments for every occurrence of the series in [week] (all pieces of a
  /// split series count).
  WeekProgress weekProgress(String seriesId, DateRange week) {
    final occ = seriesOccurrences(seriesId, week)..sort((a, b) => a.date.compareTo(b.date));
    return WeekProgress([for (final o in occ) o.status]);
  }

  /// Weekly completion % for the last [weeks] weeks, oldest first.
  List<double?> weeklyTrend(String seriesId, {int weeks = 4}) {
    final task = seriesTask(seriesId)!;
    final thisWeek = week(today);
    return [
      for (var i = weeks - 1; i >= 0; i--)
        () {
          final w = DateRange(Days.add(thisWeek.from, -7 * i), Days.add(thisWeek.to, -7 * i));
          if (task.isQuota) {
            final done = quotaDone(seriesId, w.from);
            return (done / (task.quotaPerWeek ?? 1)).clamp(0.0, 1.0);
          }
          return weekProgress(seriesId, w).rate;
        }(),
    ];
  }

  Streak streak(String seriesId) {
    final task = seriesTask(seriesId)!;
    final start = _seriesStart(seriesId);
    if (task.isQuota) {
      final weeks = <DateTime, int>{};
      for (var w = week(start).from; !w.isAfter(today); w = Days.add(w, 7)) {
        weeks[w] = quotaDone(seriesId, w);
      }
      return Metrics.quotaStreak(task, weeks, currentWeekStart: week(today).from);
    }
    return Metrics.taskStreak(seriesOccurrences(seriesId, DateRange(start, today)));
  }

  int quotaDone(String seriesId, DateTime weekStart) {
    final w = week(weekStart);
    return occurrences(w).where((o) => o.task.seriesId == seriesId && o.isDone).length;
  }

  /// % of fully elapsed weeks (plus this week if already met) where the quota was met.
  double? quotaWeeksMet(String seriesId) {
    final task = seriesTask(seriesId)!;
    var met = 0, total = 0;
    final current = week(today).from;
    for (var w = week(_seriesStart(seriesId)).from; !w.isAfter(current); w = Days.add(w, 7)) {
      final ok = Metrics.quotaMet(task, quotaDone(seriesId, w));
      if (w == current && !ok) continue;
      total++;
      if (ok) met++;
    }
    return total == 0 ? null : met / total;
  }

  // --- Timing / categories / focus -------------------------------------

  (int, int) onTime(DateRange r) => Metrics.onTime(occurrences(r));
  List<int> completionsByHour(DateRange r) => Metrics.completionsByHour(occurrences(r));
  List<MapEntry<String, int>> byCategory(DateRange r) => Metrics.byCategory(occurrences(r));

  List<String> tags() {
    final s = <String>{
      for (final t in snapshot.tasks)
        if (t.tag != null && t.tag!.trim().isNotEmpty) t.tag!.trim(),
    };
    return s.toList()..sort();
  }

  List<FocusSessionRecord> sessionsIn(DateRange r) =>
      sessions.where((s) => r.contains(Days.of(s.startedAt))).toList();

  FocusStats focus(DateRange r) => Metrics.focus(sessionsIn(r));

  double focusMinutesOn(DateTime day) =>
      Metrics.focus(sessionsIn(DateRange.day(day))).totalMinutes;

  String taskTitle(String taskId) => snapshot.taskById(taskId)?.title ?? 'Deleted task';
}

final insightsRepositoryProvider = Provider<InsightsRepository>((ref) {
  return InsightsRepository(
    snapshot: ref.watch(taskSnapshotProvider).value ?? TaskSnapshot.empty,
    sessions: ref.watch(focusSessionsProvider).value ?? const [],
    generator: ref.watch(generatorProvider),
    today: ref.watch(todayProvider),
    mondayFirst: ref.watch(settingsProvider.select((s) => s.mondayFirst)),
  );
});
