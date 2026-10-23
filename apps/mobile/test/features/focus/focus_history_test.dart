import 'package:flutter_test/flutter_test.dart';
import 'package:poora/core/time/date_utils.dart';
import 'package:poora/features/focus/domain/focus_history.dart';
import 'package:poora/features/focus/domain/focus_session.dart';
import 'package:poora/features/focus/domain/timer_engine.dart';

const _min = 60000;

FocusSessionRecord _s(String id, DateTime start, int focusMin, {String? task, int paused = 0, int away = 0, int interruptions = 0, bool early = false, Map<String, int> apps = const {}}) =>
    FocusSessionRecord(
      id: id,
      startedAt: start,
      endedAt: start.add(Duration(minutes: focusMin + paused)),
      config: const FocusConfig(),
      focusMsCompleted: focusMin * _min,
      pausedMs: paused * _min,
      awayMs: away * _min,
      interruptions: interruptions,
      endedEarly: early,
      linkedTaskId: task,
      distractions: apps,
    );

void main() {
  final mon = DateTime(2026, 10, 19, 9);
  final sessions = [
    _s('1', mon, 25, task: 'write', away: 3, interruptions: 2, apps: {'com.social': 2 * _min}),
    _s('2', mon.add(const Duration(days: 1)), 45, task: 'write', paused: 5),
    _s('3', mon.add(const Duration(days: 2)), 15, task: 'email', early: true, interruptions: 1, away: 1),
    _s('4', mon.add(const Duration(days: 2, hours: 3)), 60),
    _s('5', mon.subtract(const Duration(days: 7)), 30, task: 'write'), // last week
  ];
  final week = DateRange.week(Days.of(mon), mondayFirst: true);

  test('totals keep focus, paused, away and app use apart', () {
    final t = FocusHistory.totals(FocusHistory.inRange(sessions, week));
    expect(t.sessions, 4);
    expect(t.completed, 3);
    expect(t.focusMs, (25 + 45 + 15 + 60) * _min);
    expect(t.pausedMs, 5 * _min);
    expect(t.awayMs, 4 * _min);
    expect(t.interruptions, 3);
    // App use = wall time − away: (25 + 50 + 15 + 60) − 4.
    expect(t.appUsageMs, (150 - 4) * _min);
    expect(t.interruptionsPerHour, closeTo(3 / (145 / 60), 1e-9));
  });

  test('grouped by task: biggest first, unlinked last, sessions newest first', () {
    final g = FocusHistory.byTask(sessions);
    expect(g.map((x) => x.taskId), ['write', 'email', null]);
    expect(g.first.totals.focusMs, (25 + 45 + 30) * _min);
    expect(g.first.sessions.map((s) => s.id), ['2', '1', '5']);
  });

  test('daily minutes across the week and distracting apps', () {
    final days = FocusHistory.minutesByDay(sessions, week);
    expect(days[Days.of(mon)], 25);
    expect(days[Days.add(Days.of(mon), 2)], 75);
    expect(days.length, 7);
    expect(FocusHistory.distractingApps(sessions).single, isA<MapEntry<String, int>>());
    expect(FocusHistory.distractingApps(sessions).single.value, 2 * _min);
  });

  test('daily goal: streak ends today (or yesterday until today is met)', () {
    final day = Days.of(mon);
    final runs = [
      _s('a', mon.subtract(const Duration(days: 2)), 60),
      _s('b', mon.subtract(const Duration(days: 1)), 30),
      _s('c', mon.subtract(const Duration(hours: 22)), 40),
      _s('d', mon, 20),
    ];
    // Today 20/60 not met yet: streak counts the two days before.
    expect(FocusHistory.goalStreak(runs, 60, day), 2);
    expect(FocusHistory.goalStreak([...runs, _s('e', mon.add(const Duration(hours: 2)), 45)], 60, day), 3);
    expect(FocusHistory.goalStreak(runs, 61, day), 1); // the day before yesterday had 60
    expect(FocusHistory.goalStreak(runs, 71, day), 0);
    expect(FocusHistory.goalDays(runs, 60, DateRange(Days.add(day, -6), day)), 2);
  });
}
