import 'package:poora/core/time/date_utils.dart';
import 'package:poora/features/focus/domain/focus_session.dart';
import 'package:poora/features/tasks/domain/models.dart';

/// Tier thresholds for the completion calendar (§4.11). Tune here only.
abstract final class CompletionTiers {
  static const perfect = 1.0;
  static const high = 0.8;
  static const mid = 0.5;

  /// Daily % needed for a day to count toward the overall day streak (§7).
  static const streakThreshold = 0.8;

  static DayTier tierFor(double rate) {
    if (rate >= perfect) return DayTier.perfect;
    if (rate >= high) return DayTier.high;
    if (rate >= mid) return DayTier.mid;
    if (rate > 0) return DayTier.low;
    return DayTier.missed;
  }
}

enum DayTier {
  perfect,
  high,
  mid,
  low,
  missed,

  /// No tasks scheduled, or all skipped. Neutral, not failure.
  rest,

  /// In progress — never shown as missed.
  today,
  future,

  /// Before the user's first task; fully dimmed, never missed.
  beforeFirstUse,
}

class DayCompletion {
  const DayCompletion({
    required this.day,
    required this.tier,
    this.done = 0,
    this.skipped = 0,
    this.missed = 0,
    this.pending = 0,
  });

  final DateTime day;
  final DayTier tier;
  final int done;
  final int skipped;
  final int missed;
  final int pending;

  /// Scheduled(d): generated occurrences excluding skipped (§7).
  int get scheduled => done + missed + pending;

  /// done / scheduled, or null when nothing was scheduled.
  double? get rate => scheduled == 0 ? null : done / scheduled;

  /// Daily % for `DayRatePills`; null renders as "–".
  int? get percent => rate == null ? null : (rate! * 100).round();

  bool get isPerfect => tier == DayTier.perfect;
}

/// Weekly x/y for a recurring task, with one segment per occurrence.
class WeekProgress {
  const WeekProgress(this.segments);
  final List<OccurrenceStatus> segments;
  int get done => segments.where((s) => s == OccurrenceStatus.done).length;

  /// Generated occurrences in the week, excluding skipped.
  int get total => segments.where((s) => s != OccurrenceStatus.skipped).length;
  double? get rate => total == 0 ? null : done / total;
}

/// Completed / not completed / deleted for a period (Google-Calendar-style outcomes).
class TaskOutcomes {
  const TaskOutcomes({required this.completed, required this.notCompleted, required this.deletedOccurrences, required this.deletedTasks});
  final int completed;

  /// Past occurrences that weren't done (missed).
  final int notCompleted;

  /// Single occurrences deleted ("This task") on days in the period.
  final int deletedOccurrences;

  /// Whole tasks/series moved to Trash during the period.
  final int deletedTasks;

  int get deleted => deletedOccurrences + deletedTasks;
  int get total => completed + notCompleted + deleted;
}

class Streak {
  const Streak(this.current, this.best);
  final int current;
  final int best;
}

class FocusStats {
  const FocusStats({
    required this.minutesByDay,
    required this.completed,
    required this.endedEarly,
    required this.averageMinutes,
    required this.bestHour,
    required this.minutesByTask,
  });

  final Map<DateTime, double> minutesByDay;
  final int completed;
  final int endedEarly;
  final double averageMinutes;
  final int? bestHour;

  /// Task id → attributed minutes, sorted descending.
  final List<MapEntry<String, double>> minutesByTask;

  double get totalMinutes => minutesByDay.values.fold(0, (a, b) => a + b);
}

/// Pure analytics definitions (§7). Quota tasks are excluded from all daily
/// figures and counted weekly only.
abstract final class Metrics {
  static Iterable<Occurrence> _fixed(Iterable<Occurrence> occ) =>
      occ.where((o) => !o.task.isQuota);

  /// Day state for [day] from that day's occurrences.
  static DayCompletion dayCompletion(
    DateTime day,
    Iterable<Occurrence> occurrences, {
    required DateTime today,
    DateTime? firstUse,
  }) {
    var done = 0, skipped = 0, missed = 0, pending = 0;
    for (final o in _fixed(occurrences)) {
      if (!Days.same(o.date, day)) continue;
      switch (o.status) {
        case OccurrenceStatus.done:
          done++;
        case OccurrenceStatus.skipped:
          skipped++;
        case OccurrenceStatus.missed:
          missed++;
        case OccurrenceStatus.pending:
          pending++;
      }
    }
    final scheduled = done + missed + pending;
    final DayTier tier;
    if (firstUse != null && day.isBefore(firstUse)) {
      tier = DayTier.beforeFirstUse;
    } else if (day.isAfter(today)) {
      tier = DayTier.future;
    } else if (scheduled == 0) {
      tier = DayTier.rest;
    } else if (Days.same(day, today)) {
      tier = done == scheduled ? DayTier.perfect : DayTier.today;
    } else {
      tier = CompletionTiers.tierFor(done / scheduled);
    }
    return DayCompletion(
      day: day,
      tier: tier,
      done: done,
      skipped: skipped,
      missed: missed,
      pending: pending,
    );
  }

  static Map<DateTime, DayCompletion> dayCompletions(
    DateRange range,
    List<Occurrence> occurrences, {
    required DateTime today,
    DateTime? firstUse,
  }) {
    final byDay = <DateTime, List<Occurrence>>{};
    for (final o in occurrences) {
      (byDay[o.date] ??= []).add(o);
    }
    return {
      for (final d in range.days)
        d: dayCompletion(d, byDay[d] ?? const [], today: today, firstUse: firstUse),
    };
  }

  /// done / (done + missed) for fixed-rule and one-off tasks; pending excluded.
  static double? completionRate(Iterable<Occurrence> occurrences) {
    var done = 0, missed = 0;
    for (final o in _fixed(occurrences)) {
      if (o.status == OccurrenceStatus.done) done++;
      if (o.status == OccurrenceStatus.missed) missed++;
    }
    final n = done + missed;
    return n == 0 ? null : done / n;
  }

  static int doneCount(Iterable<Occurrence> occurrences) =>
      occurrences.where((o) => o.isDone).length;

  /// Segments for [task]'s occurrences inside [week].
  static WeekProgress weekProgress(
    Task task,
    Iterable<Occurrence> occurrences,
    DateRange week,
  ) {
    final list =
        occurrences
            .where((o) => o.task.id == task.id && week.contains(o.date))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    return WeekProgress([for (final o in list) o.status]);
  }

  static bool quotaMet(Task task, int doneInWeek) =>
      doneInWeek >= (task.quotaPerWeek ?? 1);

  /// Consecutive completed occurrences counting back from the most recent
  /// past one. Skips don't break it; misses do. Today's still-open occurrence
  /// is ignored.
  static Streak taskStreak(Iterable<Occurrence> taskOccurrences) {
    final list =
        taskOccurrences
            .where((o) => o.status != OccurrenceStatus.pending)
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    var best = 0, run = 0;
    for (final o in list) {
      if (o.status == OccurrenceStatus.done) {
        run++;
        if (run > best) best = run;
      } else if (o.status == OccurrenceStatus.missed) {
        run = 0;
      }
    }
    return Streak(run, best);
  }

  /// Quota streak: consecutive weeks where the quota was met. The current
  /// week counts once met; an unmet current week doesn't break the streak yet.
  static Streak quotaStreak(
    Task task,
    Map<DateTime, int> doneByWeekStart, {
    required DateTime currentWeekStart,
  }) {
    final weeks = doneByWeekStart.keys.toList()..sort();
    var best = 0, run = 0;
    for (final w in weeks) {
      final met = quotaMet(task, doneByWeekStart[w]!);
      if (met) {
        run++;
        if (run > best) best = run;
      } else if (w != currentWeekStart) {
        run = 0;
      }
    }
    return Streak(run, best);
  }

  /// Consecutive days with daily % ≥ threshold, counting back from today
  /// (today only counts once it qualifies). Rest days are neutral.
  static int overallDayStreak(
    Map<DateTime, DayCompletion> days, {
    required DateTime today,
  }) {
    var streak = 0;
    for (var d = today; days.containsKey(d); d = Days.add(d, -1)) {
      final c = days[d]!;
      final rate = c.rate;
      if (c.tier == DayTier.beforeFirstUse) break;
      if (rate == null) continue; // rest day
      if (Days.same(d, today) && rate < CompletionTiers.streakThreshold) {
        continue; // today still in progress
      }
      if (rate < CompletionTiers.streakThreshold) break;
      streak++;
    }
    return streak;
  }

  /// (on time, late) among completed fixed/one-off occurrences.
  static (int, int) onTime(Iterable<Occurrence> occurrences) {
    var on = 0, late = 0;
    for (final o in _fixed(occurrences)) {
      if (!o.isDone) continue;
      o.onTime ? on++ : late++;
    }
    return (on, late);
  }

  /// Completions per local hour of day, 24 buckets.
  static List<int> completionsByHour(Iterable<Occurrence> occurrences) {
    final h = List.filled(24, 0);
    for (final o in occurrences) {
      final c = o.completedAt;
      if (o.isDone && c != null) h[c.hour]++;
    }
    return h;
  }

  /// Start hour of the best two-hour window, e.g. 10 for "10–12".
  static int? bestWindow(List<int> byHour) {
    var best = -1, at = -1;
    for (var i = 0; i < 24; i++) {
      final v = byHour[i] + (i < 23 ? byHour[i + 1] : 0);
      if (v > best) (best, at) = (v, i);
    }
    return best <= 0 ? null : at;
  }

  /// Completed occurrences per tag ("Untagged" for none), descending.
  static List<MapEntry<String, int>> byCategory(Iterable<Occurrence> occ) {
    final m = <String, int>{};
    for (final o in occ) {
      if (!o.isDone) continue;
      final tag = (o.task.tag?.trim().isNotEmpty ?? false) ? o.task.tag!.trim() : 'Untagged';
      m[tag] = (m[tag] ?? 0) + 1;
    }
    return m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  /// Outcomes for [range]: done vs missed occurrences, plus deletions —
  /// occurrence records marked deleted on days in the range, and trashed
  /// tasks whose deletion time falls in it.
  static TaskOutcomes outcomes(
    DateRange range,
    Iterable<Occurrence> occurrences,
    Iterable<OccurrenceRecord> records,
    Iterable<Task> trashed,
  ) {
    var done = 0, missed = 0;
    for (final o in occurrences) {
      if (!range.contains(o.date)) continue;
      if (o.status == OccurrenceStatus.done) done++;
      if (o.status == OccurrenceStatus.missed) missed++;
    }
    final deletedOcc = records
        .where((r) => r.status == RecordStatus.deleted && range.contains(r.overrideDate ?? r.occurrenceDate))
        .length;
    final deletedTasks = trashed.where((t) => t.deletedAt != null && range.contains(Days.of(t.deletedAt!))).length;
    return TaskOutcomes(completed: done, notCompleted: missed, deletedOccurrences: deletedOcc, deletedTasks: deletedTasks);
  }

  /// Focus minutes = completed focus-phase time, breaks excluded (§7).
  static FocusStats focus(Iterable<FocusSessionRecord> sessions) {
    final byDay = <DateTime, double>{};
    final byHour = List<double>.filled(24, 0);
    final byTask = <String, double>{};
    var completed = 0, early = 0;
    var total = 0.0;
    var count = 0;
    for (final s in sessions) {
      final mins = s.focusMinutes;
      final day = Days.of(s.startedAt);
      byDay[day] = (byDay[day] ?? 0) + mins;
      byHour[s.startedAt.hour] += mins;
      if (s.linkedTaskId != null) {
        byTask[s.linkedTaskId!] = (byTask[s.linkedTaskId!] ?? 0) + mins;
      }
      s.endedEarly ? early++ : completed++;
      total += mins;
      count++;
    }
    int? bestHour;
    var bestVal = 0.0;
    for (var i = 0; i < 24; i++) {
      if (byHour[i] > bestVal) (bestVal, bestHour) = (byHour[i], i);
    }
    return FocusStats(
      minutesByDay: byDay,
      completed: completed,
      endedEarly: early,
      averageMinutes: count == 0 ? 0 : total / count,
      bestHour: bestHour,
      minutesByTask: byTask.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)),
    );
  }
}
