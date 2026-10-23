import 'package:flutter_test/flutter_test.dart';
import 'package:poora/core/time/date_utils.dart';
import 'package:poora/features/tasks/domain/models.dart';
import 'package:poora/features/tasks/domain/occurrence_generator.dart';
import 'package:poora/features/tasks/domain/recurrence.dart';
import 'package:poora/features/tasks/domain/series_edits.dart';

final _now = DateTime(2026, 10, 19, 9);

Task task({
  String id = 't1',
  DateTime? start,
  RepeatRule rule = RepeatRule.none,
  int? startMinute = 9 * 60,
}) {
  final base = Task(
    id: id,
    title: 'Task $id',
    color: 0xFFEF7867,
    startDate: start ?? Days.ymd(2026, 10, 19),
    seriesId: id,
    createdAt: _now,
    updatedAt: _now,
    startMinute: startMinute,
    durationMin: 30,
  );
  return rule.applyTo(base);
}

List<String> isoList(Iterable<DateTime> ds) => ds.map(Days.iso).toList();

void main() {
  final gen = OccurrenceGenerator(mondayFirst: true);
  final from = Days.ymd(2026, 10, 19); // Monday
  final twoYears = Days.ymd(2028, 10, 18);

  group('fixed rules', () {
    test('does not repeat', () {
      final t = task();
      expect(isoList(gen.datesFor(t, from, twoYears)), ['2026-10-19']);
      expect(gen.datesFor(t, Days.ymd(2026, 10, 20), twoYears), isEmpty);
    });

    test('every day for two years', () {
      final d = gen.datesFor(task(rule: RepeatRule.daily()), from, twoYears);
      expect(d.length, 731);
      expect(d.first, from);
      expect(d.last, twoYears);
    });

    test('every other day (alternate days)', () {
      final d = gen.datesFor(task(rule: RepeatRule.everyOtherDay()), from, twoYears);
      expect(isoList(d.take(4)), [
        '2026-10-19',
        '2026-10-21',
        '2026-10-23',
        '2026-10-25',
      ]);
      for (var i = 1; i < d.length; i++) {
        expect(Days.between(d[i - 1], d[i]), 2);
      }
      expect(d.length, 366);
    });

    test('every weekday', () {
      final d = gen.datesFor(task(rule: RepeatRule.weekdaysOnly()), from, twoYears);
      expect(d.every((x) => x.weekday <= 5), isTrue);
      expect(isoList(d.take(6)), [
        '2026-10-19',
        '2026-10-20',
        '2026-10-21',
        '2026-10-22',
        '2026-10-23',
        '2026-10-26',
      ]);
      expect(d.length, 523); // 104 weeks + Mon–Wed
    });

    test('weekly on start weekday', () {
      final d = gen.datesFor(task(rule: RepeatRule.weeklyOn(from)), from, twoYears);
      expect(d.every((x) => x.weekday == DateTime.monday), isTrue);
      expect(d.length, 105);
    });

    test('custom: every 2 weeks on Mon, Wed, Fri', () {
      const rule = RepeatRule(
        kind: RepeatKind.rrule,
        freq: Freq.weekly,
        interval: 2,
        weekdays: {1, 3, 5},
      );
      final d = gen.datesFor(task(rule: rule), from, Days.ymd(2026, 11, 15));
      expect(isoList(d), [
        '2026-10-19',
        '2026-10-21',
        '2026-10-23',
        '2026-11-02',
        '2026-11-04',
        '2026-11-06',
      ]);
    });

    test('monthly on day 31 skips short months', () {
      final s = Days.ymd(2026, 10, 31);
      final d = gen.datesFor(
        task(start: s, rule: RepeatRule.monthlyOnDay()),
        s,
        Days.ymd(2027, 4, 1),
      );
      expect(isoList(d), [
        '2026-10-31',
        '2026-12-31',
        '2027-01-31',
        '2027-03-31',
      ]);
    });

    test('monthly on the third Monday', () {
      final rule = RepeatRule.monthlyOnDay().copyWith(
        monthlyMode: MonthlyMode.nthWeekday,
      );
      final t = task(rule: rule); // 19 Oct 2026 is the 3rd Monday
      expect(RepeatRule.fromTask(t).summary(from), 'Monthly on the third Monday');
      final d = gen.datesFor(t, from, twoYears);
      expect(d.length, 25);
      for (final x in d) {
        expect(x.weekday, DateTime.monday);
        expect(RepeatRule.nthOfMonth(x), 3);
      }
      expect(isoList(d.take(3)), ['2026-10-19', '2026-11-16', '2026-12-21']);
    });

    test('monthly on the last Monday', () {
      final s = Days.ymd(2026, 10, 26);
      final rule = RepeatRule.monthlyOnDay().copyWith(
        monthlyMode: MonthlyMode.lastWeekday,
      );
      final d = gen.datesFor(task(start: s, rule: rule), s, twoYears);
      for (final x in d) {
        expect(x.weekday, DateTime.monday);
        expect(Days.add(x, 7).month, isNot(x.month));
      }
      expect(isoList(d.take(3)), ['2026-10-26', '2026-11-30', '2026-12-28']);
    });

    test('yearly, including Feb 29 only on leap years', () {
      final s = Days.ymd(2028, 2, 29);
      final d = gen.datesFor(
        task(start: s, rule: RepeatRule.yearly()),
        s,
        Days.ymd(2036, 12, 31),
      );
      expect(isoList(d), ['2028-02-29', '2032-02-29', '2036-02-29']);
      final y = gen.datesFor(task(rule: RepeatRule.yearly()), from, twoYears);
      expect(isoList(y), ['2026-10-19', '2027-10-19']);
    });

    test('ends on a date', () {
      final rule = RepeatRule.daily().copyWith(endsOn: Days.ymd(2026, 10, 23));
      final d = gen.datesFor(task(rule: rule), from, twoYears);
      expect(d.length, 5);
      expect(d.last, Days.ymd(2026, 10, 23));
    });

    test('ends after N occurrences, counted from series start', () {
      final rule = RepeatRule.everyOtherDay().copyWith(endsAfter: 4);
      final t = task(rule: rule);
      expect(gen.datesFor(t, from, twoYears).length, 4);
      // Window starting mid-series still respects the count.
      expect(
        isoList(gen.datesFor(t, Days.ymd(2026, 10, 22), twoYears)),
        ['2026-10-23', '2026-10-25'],
      );
    });

    test('window before start yields nothing', () {
      final d = gen.datesFor(
        task(rule: RepeatRule.daily()),
        Days.ymd(2026, 1, 1),
        Days.ymd(2026, 10, 18),
      );
      expect(d, isEmpty);
    });

    test('dates stay calendar dates across DST transitions', () {
      // EU DST ends 25 Oct 2026, US ends 1 Nov 2026; days must stay midnight.
      final d = gen.datesFor(task(rule: RepeatRule.daily()), from, Days.ymd(2027, 4, 1));
      for (final x in d) {
        expect(x.isUtc, isTrue);
        expect([x.hour, x.minute, x.second], [0, 0, 0]);
      }
      expect(d.length, Days.between(from, Days.ymd(2027, 4, 1)) + 1);
      // Wall-clock start keeps its local minute on both sides of DST.
      expect(Days.at(Days.ymd(2026, 10, 24), 540).hour, 9);
      expect(Days.at(Days.ymd(2026, 10, 26), 540).hour, 9);
    });
  });

  group('summaries', () {
    test('human text', () {
      expect(RepeatRule.everyOtherDay().summary(from), 'Every 2 days');
      expect(RepeatRule.weekdaysOnly().summary(from), 'Every weekday');
      expect(
        const RepeatRule(
          kind: RepeatKind.rrule,
          freq: Freq.weekly,
          weekdays: {1, 3, 5},
        ).summary(from),
        'Weekly on Mon, Wed, Fri',
      );
      expect(RepeatRule.timesPerWeek(3).summary(from), '3 times a week');
      expect(RepeatRule.monthlyOnDay().summary(from), 'Monthly on day 19');
    });

    test('round-trips through a stored task', () {
      const rule = RepeatRule(
        kind: RepeatKind.rrule,
        freq: Freq.weekly,
        interval: 2,
        weekdays: {2, 4},
        endsAfter: 10,
      );
      expect(RepeatRule.fromTask(task(rule: rule)), rule);
    });
  });

  group('generate()', () {
    final today = Days.ymd(2026, 10, 21);

    test('past open occurrences are missed, today pending', () {
      final t = task(rule: RepeatRule.daily());
      final occ = gen.generate(
        snapshot: TaskSnapshot(tasks: [t], records: const []),
        range: DateRange(from, Days.ymd(2026, 10, 22)),
        today: today,
      );
      expect(occ.map((o) => o.status).toList(), [
        OccurrenceStatus.missed,
        OccurrenceStatus.missed,
        OccurrenceStatus.pending,
        OccurrenceStatus.pending,
      ]);
    });

    test('records mark done/skipped, deleted hides, override moves', () {
      final t = task(rule: RepeatRule.daily());
      final snapshot = TaskSnapshot(
        tasks: [t],
        records: [
          OccurrenceRecord(
            id: 'a',
            taskId: 't1',
            occurrenceDate: from,
            status: RecordStatus.done,
            completedAt: DateTime(2026, 10, 19, 9, 10),
          ),
          OccurrenceRecord(
            id: 'b',
            taskId: 't1',
            occurrenceDate: Days.ymd(2026, 10, 20),
            status: RecordStatus.skipped,
          ),
          OccurrenceRecord(
            id: 'c',
            taskId: 't1',
            occurrenceDate: Days.ymd(2026, 10, 21),
            status: RecordStatus.deleted,
          ),
          OccurrenceRecord(
            id: 'd',
            taskId: 't1',
            occurrenceDate: Days.ymd(2026, 10, 25),
            overrideDate: Days.ymd(2026, 10, 22),
            overrideStartMinute: 600,
          ),
        ],
      );
      final occ = gen.generate(
        snapshot: snapshot,
        range: DateRange(from, Days.ymd(2026, 10, 22)),
        today: today,
      );
      expect(occ.length, 4);
      expect(occ[0].status, OccurrenceStatus.done);
      expect(occ[0].onTime, isTrue);
      expect(occ[1].status, OccurrenceStatus.skipped);
      final moved = occ.where((o) => o.originalDate == Days.ymd(2026, 10, 25));
      expect(moved.single.date, Days.ymd(2026, 10, 22));
      expect(moved.single.startMinute, 600);
    });

    test('times-per-week task hides for the rest of the week once met', () {
      final t = task(rule: RepeatRule.timesPerWeek(2), startMinute: null);
      final week = DateRange(from, Days.ymd(2026, 10, 25));
      List<Occurrence> run(List<OccurrenceRecord> r) => gen.generate(
        snapshot: TaskSnapshot(tasks: [t], records: r),
        range: week,
        today: today,
      );
      // Nothing done: past days hidden (not missed), today..Sunday shown.
      expect(isoList(run(const []).map((o) => o.date)), [
        '2026-10-21',
        '2026-10-22',
        '2026-10-23',
        '2026-10-24',
        '2026-10-25',
      ]);
      // Done Monday and today → quota met, only the done days remain.
      final met = run([
        OccurrenceRecord(
          id: 'a',
          taskId: 't1',
          occurrenceDate: from,
          status: RecordStatus.done,
        ),
        OccurrenceRecord(
          id: 'b',
          taskId: 't1',
          occurrenceDate: today,
          status: RecordStatus.done,
        ),
      ]);
      expect(isoList(met.map((o) => o.date)), ['2026-10-19', '2026-10-21']);
      expect(met.every((o) => o.isDone), isTrue);
    });
  });

  group('series edits', () {
    test('this and following ends old series and starts a new one', () {
      final original = task(rule: RepeatRule.daily().copyWith(endsAfter: 10));
      final at = Days.ymd(2026, 10, 23);
      final edited = RepeatRule.everyOtherDay()
          .copyWith(endsAfter: 10)
          .applyTo(original.copyWith(title: 'Edited'));
      final split = splitSeries(
        original: original,
        at: at,
        edited: edited,
        newId: 't2',
        now: _now,
        generator: gen,
      );
      expect(split.ended.endsOn, Days.ymd(2026, 10, 22));
      expect(gen.datesFor(split.ended, from, twoYears).length, 4);
      expect(split.following.seriesId, original.seriesId);
      expect(split.following.startDate, at);
      expect(split.following.endsAfterCount, 6);
      expect(isoList(gen.datesFor(split.following, from, twoYears).take(3)), [
        '2026-10-23',
        '2026-10-25',
        '2026-10-27',
      ]);
    });
  });
}
