import 'package:poora/core/time/date_utils.dart';
import 'package:poora/features/focus/domain/focus_session.dart';

/// Totals for a set of focus sessions, keeping the four kinds of time apart.
class FocusTotals {
  const FocusTotals({
    this.sessions = 0,
    this.completed = 0,
    this.focusMs = 0,
    this.pausedMs = 0,
    this.awayMs = 0,
    this.interruptions = 0,
    this.appUsageMs = 0,
    this.distractionMs = 0,
  });

  final int sessions;
  final int completed;
  final int focusMs;
  final int pausedMs;
  final int awayMs;
  final int interruptions;
  final int appUsageMs;
  final int distractionMs;

  double get focusMinutes => focusMs / 60000;

  /// Interruptions per hour of focus — lower is better.
  double? get interruptionsPerHour => focusMs == 0 ? null : interruptions / (focusMs / 3600000);

  FocusTotals operator +(FocusSessionRecord s) => FocusTotals(
    sessions: sessions + 1,
    completed: completed + (s.endedEarly ? 0 : 1),
    focusMs: focusMs + s.focusMsCompleted,
    pausedMs: pausedMs + s.pausedMs,
    awayMs: awayMs + s.awayMs,
    interruptions: interruptions + s.interruptions,
    appUsageMs: appUsageMs + s.appUsageMs,
    distractionMs: distractionMs + s.distractionMs,
  );
}

class TaskFocusGroup {
  const TaskFocusGroup({required this.taskId, required this.totals, required this.sessions});

  /// Null = sessions not linked to a task.
  final String? taskId;
  final FocusTotals totals;

  /// Newest first.
  final List<FocusSessionRecord> sessions;
}

abstract final class FocusHistory {
  static FocusTotals totals(Iterable<FocusSessionRecord> sessions) =>
      sessions.fold(const FocusTotals(), (t, s) => t + s);

  static List<FocusSessionRecord> inRange(Iterable<FocusSessionRecord> sessions, DateRange r) =>
      [for (final s in sessions) if (r.contains(Days.of(s.startedAt))) s];

  /// Sessions grouped by linked task, biggest focus total first; unlinked last.
  static List<TaskFocusGroup> byTask(Iterable<FocusSessionRecord> sessions) {
    final groups = <String?, List<FocusSessionRecord>>{};
    for (final s in sessions) {
      (groups[s.linkedTaskId] ??= []).add(s);
    }
    final out = [
      for (final e in groups.entries)
        TaskFocusGroup(
          taskId: e.key,
          totals: totals(e.value),
          sessions: [...e.value]..sort((a, b) => b.startedAt.compareTo(a.startedAt)),
        ),
    ]..sort((a, b) {
        if ((a.taskId == null) != (b.taskId == null)) return a.taskId == null ? 1 : -1;
        return b.totals.focusMs.compareTo(a.totals.focusMs);
      });
    return out;
  }

  /// Focus minutes per day across [r].
  static Map<DateTime, double> minutesByDay(Iterable<FocusSessionRecord> sessions, DateRange r) {
    final out = {for (final d in r.days) d: 0.0};
    for (final s in sessions) {
      final d = Days.of(s.startedAt);
      if (out.containsKey(d)) out[d] = out[d]! + s.focusMinutes;
    }
    return out;
  }

  /// "You versus you": consecutive days, ending today, whose focus reached
  /// [goalMin]. Today only counts once it's reached — until then the streak
  /// runs to yesterday, so an unfinished today never breaks it.
  static int goalStreak(Iterable<FocusSessionRecord> sessions, int goalMin, DateTime today) {
    if (goalMin <= 0) return 0;
    final byDay = <DateTime, double>{};
    for (final s in sessions) {
      final d = Days.of(s.startedAt);
      byDay[d] = (byDay[d] ?? 0) + s.focusMinutes;
    }
    bool met(DateTime d) => (byDay[d] ?? 0) >= goalMin;
    var d = met(today) ? today : Days.add(today, -1);
    var n = 0;
    while (met(d)) {
      n++;
      d = Days.add(d, -1);
    }
    return n;
  }

  /// Days in [r] whose focus reached [goalMin].
  static int goalDays(Iterable<FocusSessionRecord> sessions, int goalMin, DateRange r) =>
      goalMin <= 0 ? 0 : minutesByDay(sessions, r).values.where((m) => m >= goalMin).length;

  /// Total ms per monitored app across sessions, most-used first.
  static List<MapEntry<String, int>> distractingApps(Iterable<FocusSessionRecord> sessions) {
    final m = <String, int>{};
    for (final s in sessions) {
      s.distractions.forEach((k, v) => m[k] = (m[k] ?? 0) + v);
    }
    return m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }
}
