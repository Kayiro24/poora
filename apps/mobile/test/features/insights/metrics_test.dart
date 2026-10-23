import 'package:flutter_test/flutter_test.dart';
import 'package:poora/core/time/date_utils.dart';
import 'package:poora/features/focus/domain/focus_session.dart';
import 'package:poora/features/focus/domain/timer_engine.dart';
import 'package:poora/features/insights/domain/metrics.dart';
import 'package:poora/features/tasks/domain/models.dart';
import 'package:poora/features/tasks/domain/occurrence_generator.dart';
import 'package:poora/features/tasks/domain/recurrence.dart';

/// Seeded 4-week dataset, Mon 28 Sep – Sun 25 Oct 2026; "today" = Mon 26 Oct.
///
/// A  "Read"  daily 08:00 (30m), tag Mind. Done 08:15 every day except
///            missed 2 Oct + 10 Oct, skipped 15 Oct.  → 25 done, 2 missed.
/// B  "Gym"   Mon/Wed/Fri 18:00 (60m), tag Health. Done 18:45 except missed
///            9 Oct + 21 Oct.                          → 10 done, 2 missed.
/// C  "Taxes" one-off all-day 7 Oct, done late on 8 Oct 10:00, no tag.
/// D  "Run"   3× per week, tag Health. Done: wk1 29,30 Sep + 1 Oct (met),
///            wk2 6 Oct (1), wk3 13,15,17 Oct (met), wk4 20,22 Oct (2).
final _start = Days.ymd(2026, 9, 28);
final _end = Days.ymd(2026, 10, 25);
final _today = Days.ymd(2026, 10, 26);
final _created = DateTime(2026, 9, 27);

Task _task(String id, String title, RepeatRule rule, {int? at, int? dur, String? tag, DateTime? start}) =>
    rule.applyTo(
      Task(
        id: id,
        title: title,
        color: 0xFFEF7867,
        startDate: start ?? _start,
        seriesId: id,
        createdAt: _created,
        updatedAt: _created,
        allDay: at == null,
        startMinute: at,
        durationMin: dur,
        tag: tag,
      ),
    );

OccurrenceRecord _rec(String task, DateTime day, RecordStatus s, {DateTime? at, bool late = false}) =>
    OccurrenceRecord(
      id: '$task-${Days.iso(day)}',
      taskId: task,
      occurrenceDate: day,
      status: s,
      completedAt: at,
      late: late,
    );

TaskSnapshot seed() {
  final a = _task('A', 'Read', RepeatRule.daily(), at: 480, dur: 30, tag: 'Mind');
  final b = _task(
    'B',
    'Gym',
    const RepeatRule(kind: RepeatKind.rrule, freq: Freq.weekly, weekdays: {1, 3, 5}),
    at: 1080,
    dur: 60,
    tag: 'Health',
  );
  final c = _task('C', 'Taxes', RepeatRule.none, start: Days.ymd(2026, 10, 7));
  final d = _task('D', 'Run', RepeatRule.timesPerWeek(3), tag: 'Health');
  final records = <OccurrenceRecord>[];
  for (final day in Days.range(_start, _end)) {
    final iso = Days.iso(day);
    if (iso == '2026-10-15') {
      records.add(_rec('A', day, RecordStatus.skipped));
    } else if (iso != '2026-10-02' && iso != '2026-10-10') {
      records.add(_rec('A', day, RecordStatus.done, at: Days.at(day, 495)));
    }
    if ({1, 3, 5}.contains(day.weekday) && iso != '2026-10-09' && iso != '2026-10-21') {
      records.add(_rec('B', day, RecordStatus.done, at: Days.at(day, 1125)));
    }
  }
  records.add(
    _rec('C', Days.ymd(2026, 10, 7), RecordStatus.done, at: DateTime(2026, 10, 8, 10), late: true),
  );
  for (final s in ['2026-09-29', '2026-09-30', '2026-10-01', '2026-10-06', '2026-10-13', '2026-10-15', '2026-10-17', '2026-10-20', '2026-10-22']) {
    records.add(_rec('D', Days.parse(s), RecordStatus.done, at: Days.at(Days.parse(s), 420)));
  }
  return TaskSnapshot(tasks: [a, b, c, d], records: records);
}

void main() {
  final gen = OccurrenceGenerator(mondayFirst: true);
  final snapshot = seed();
  final range = DateRange(_start, _today);
  final occ = gen.generate(snapshot: snapshot, range: range, today: _today);
  final past = occ.where((o) => !o.date.isAfter(_end)).toList();
  final days = Metrics.dayCompletions(range, occ, today: _today, firstUse: _start);

  test('completion rate = done / (done + missed), quota excluded', () {
    // (25 + 10 + 1) / (36 + 4) = 0.9
    expect(Metrics.completionRate(occ), closeTo(0.9, 1e-9));
    expect(Metrics.doneCount(past.where((o) => !o.task.isQuota)), 36);
  });

  test('daily % and tiers', () {
    DayCompletion at(String iso) => days[Days.parse(iso)]!;
    expect(at('2026-10-02').percent, 50); // A missed, B done
    expect(at('2026-10-02').tier, DayTier.mid);
    expect(at('2026-10-10').tier, DayTier.missed); // A missed, nothing else
    expect(at('2026-10-15').tier, DayTier.rest); // only A, skipped
    expect(at('2026-10-15').percent, isNull);
    expect(at('2026-10-07').tier, DayTier.perfect); // A, B, C all done
    expect(at('2026-10-07').scheduled, 3);
    expect(at('2026-10-21').percent, 50);
    // Today: A + B pending — in progress, never missed.
    expect(at('2026-10-26').tier, DayTier.today);
    expect(at('2026-10-26').pending, 2);
    final before = Metrics.dayCompletion(
      Days.ymd(2026, 9, 1),
      const [],
      today: _today,
      firstUse: _start,
    );
    expect(before.tier, DayTier.beforeFirstUse);
  });

  test('overall day streak counts back over ≥80% days', () {
    // 22–25 Oct are 100%; 21 Oct is 50%. Today (pending) is skipped over.
    expect(Metrics.overallDayStreak(days, today: _today), 4);
  });

  test('task streaks: skips do not break, misses do', () {
    final a = Metrics.taskStreak(occ.where((o) => o.task.id == 'A'));
    expect(a.current, 14); // 11–14 + 16–25 Oct, skip on 15th
    expect(a.best, 14);
    final b = Metrics.taskStreak(occ.where((o) => o.task.id == 'B'));
    expect(b.current, 1); // 23 Oct after the 21 Oct miss
    expect(b.best, 5); // 28 Sep – 7 Oct
  });

  test('recurring weekly progress and segmented bar', () {
    final b = snapshot.taskById('B')!;
    final wk4 = DateRange.week(Days.ymd(2026, 10, 19), mondayFirst: true);
    final p = Metrics.weekProgress(b, occ, wk4);
    expect('${p.done} / ${p.total}', '2 / 3');
    expect(p.segments, [
      OccurrenceStatus.done,
      OccurrenceStatus.missed,
      OccurrenceStatus.done,
    ]);
    final a = snapshot.taskById('A')!;
    final wk3 = DateRange.week(Days.ymd(2026, 10, 12), mondayFirst: true);
    final pa = Metrics.weekProgress(a, occ, wk3);
    expect(pa.done, 6);
    expect(pa.total, 6); // skip excluded
    expect(pa.segments.where((s) => s == OccurrenceStatus.skipped).length, 1);
  });

  test('quota met and quota streak', () {
    final d = snapshot.taskById('D')!;
    final weeks = <DateTime, int>{};
    for (var w = _start; !w.isAfter(_today); w = Days.add(w, 7)) {
      weeks[w] = gen.quotaDone(d, w, snapshot.records);
    }
    expect(weeks.values.toList(), [3, 1, 3, 2, 0]);
    expect(weeks.values.where((n) => Metrics.quotaMet(d, n)).length, 2);
    final s = Metrics.quotaStreak(d, weeks, currentWeekStart: _today);
    expect(s.current, 0); // week 4 unmet
    expect(s.best, 1);
  });

  test('on-time vs late, completions by hour, categories', () {
    expect(Metrics.onTime(occ), (35, 1)); // C back-filled late
    final hours = Metrics.completionsByHour(past);
    expect(hours[8], 25);
    expect(hours[18], 10);
    expect(hours[10], 1);
    expect(hours[7], 9); // quota runs
    expect(Metrics.bestWindow(hours), 7); // 07–09: 9 + 25
    final cats = Metrics.byCategory(past);
    expect(cats.map((e) => '${e.key}:${e.value}'), [
      'Mind:25',
      'Health:19',
      'Untagged:1',
    ]);
  });

  test('outcomes: completed, not completed and deleted', () {
    final deletedRecord = OccurrenceRecord(
      id: 'del',
      taskId: 'A',
      occurrenceDate: Days.ymd(2026, 10, 3),
      status: RecordStatus.deleted,
    );
    final trashed = [
      snapshot.tasks.first.copyWith(id: 'gone', deletedAt: DateTime(2026, 10, 20, 9)),
      snapshot.tasks.first.copyWith(id: 'old', deletedAt: DateTime(2026, 9)),
    ];
    final o = Metrics.outcomes(DateRange(_start, _end), occ, [...snapshot.records, deletedRecord], trashed);
    expect(o.completed, 36 + 9); // fixed + quota completions
    expect(o.notCompleted, 4);
    expect(o.deletedOccurrences, 1);
    expect(o.deletedTasks, 1); // only the one deleted inside the range
    expect(o.total, 36 + 9 + 4 + 2);
  });

  test('focus stats', () {
    const cfg = FocusConfig();
    final sessions = [
      FocusSessionRecord(
        id: 's1',
        startedAt: DateTime(2026, 10, 19, 9),
        config: cfg,
        focusMsCompleted: 100 * 60000,
        phasesCompleted: 8,
      ),
      FocusSessionRecord(
        id: 's2',
        startedAt: DateTime(2026, 10, 20, 14),
        config: cfg,
        focusMsCompleted: 12 * 60000,
        endedEarly: true,
        linkedTaskId: 'A',
      ),
    ];
    final f = Metrics.focus(sessions);
    expect(f.minutesByDay[Days.ymd(2026, 10, 19)], 100);
    expect(f.minutesByDay[Days.ymd(2026, 10, 20)], 12);
    expect((f.completed, f.endedEarly), (1, 1));
    expect(f.averageMinutes, 56);
    expect(f.bestHour, 9);
    expect(f.minutesByTask.single.key, 'A');
    expect(f.totalMinutes, 112);
  });
}
