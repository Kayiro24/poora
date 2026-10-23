// Parity tests: same cases and expected values as the mobile app's
// test/features/tasks/occurrence_generator_test.dart.
import { describe, expect, test } from 'vitest';
import { Days, Range } from '../../../core/time/days';
import type { OccurrenceRecord, Task } from './models';
import { OccurrenceGenerator } from './occurrenceGenerator';
import { Rules, type RepeatRule } from './recurrence';
import { splitSeries } from './seriesEdits';

const now = new Date(2026, 9, 19, 9).getTime();

function task(opts: { id?: string; start?: string; rule?: RepeatRule; startMinute?: number | null } = {}): Task {
  const id = opts.id ?? 't1';
  const base: Task = {
    id,
    title: `Task ${id}`,
    notes: null,
    color: 0xffef7867,
    tag: null,
    priority: 0,
    allDay: false,
    startDate: opts.start ?? '2026-10-19',
    startMinute: opts.startMinute === undefined ? 540 : opts.startMinute,
    durationMin: 30,
    repeatKind: 'none',
    rrule: null,
    quotaPerWeek: null,
    quotaPreferredDays: [],
    endsOn: null,
    endsAfterCount: null,
    seriesId: id,
    timeZone: null,
    createdAt: now,
    updatedAt: now,
    deletedAt: null,
    reminders: [],
  };
  return Rules.applyTo(opts.rule ?? Rules.none, base);
}

const rec = (o: Partial<OccurrenceRecord> & { id: string; occurrenceDate: string }): OccurrenceRecord => ({
  taskId: 't1',
  status: 'none',
  completedAt: null,
  overrideDate: null,
  overrideStartMinute: null,
  overrideTitle: null,
  late: false,
  ...o,
});

const gen = new OccurrenceGenerator(true);
const from = '2026-10-19';
const twoYears = '2028-10-18';

describe('fixed rules', () => {
  test('does not repeat', () => {
    expect(gen.datesFor(task(), from, twoYears)).toEqual(['2026-10-19']);
    expect(gen.datesFor(task(), '2026-10-20', twoYears)).toEqual([]);
  });

  test('every day for two years', () => {
    const d = gen.datesFor(task({ rule: Rules.daily() }), from, twoYears);
    expect(d.length).toBe(731);
    expect(d[0]).toBe(from);
    expect(d.at(-1)).toBe(twoYears);
  });

  test('every other day', () => {
    const d = gen.datesFor(task({ rule: Rules.everyOtherDay() }), from, twoYears);
    expect(d.slice(0, 4)).toEqual(['2026-10-19', '2026-10-21', '2026-10-23', '2026-10-25']);
    for (let i = 1; i < d.length; i++) expect(Days.between(d[i - 1], d[i])).toBe(2);
    expect(d.length).toBe(366);
  });

  test('every weekday', () => {
    const d = gen.datesFor(task({ rule: Rules.weekdaysOnly() }), from, twoYears);
    expect(d.every((x) => Days.weekday(x) <= 5)).toBe(true);
    expect(d.length).toBe(523);
  });

  test('weekly on start weekday', () => {
    const d = gen.datesFor(task({ rule: Rules.weeklyOn(from) }), from, twoYears);
    expect(d.every((x) => Days.weekday(x) === 1)).toBe(true);
    expect(d.length).toBe(105);
  });

  test('every 2 weeks on Mon, Wed, Fri', () => {
    const rule: RepeatRule = { ...Rules.daily(), freq: 'weekly', interval: 2, weekdays: [1, 3, 5] };
    expect(gen.datesFor(task({ rule }), from, '2026-11-15')).toEqual([
      '2026-10-19', '2026-10-21', '2026-10-23', '2026-11-02', '2026-11-04', '2026-11-06',
    ]);
  });

  test('monthly on day 31 skips short months', () => {
    const s = '2026-10-31';
    expect(gen.datesFor(task({ start: s, rule: Rules.monthlyOnDay() }), s, '2027-04-01')).toEqual([
      '2026-10-31', '2026-12-31', '2027-01-31', '2027-03-31',
    ]);
  });

  test('monthly on the third Monday', () => {
    const t = task({ rule: { ...Rules.monthlyOnDay(), monthlyMode: 'nthWeekday' } });
    expect(Rules.summary(Rules.fromTask(t), from)).toBe('Monthly on the third Monday');
    const d = gen.datesFor(t, from, twoYears);
    expect(d.length).toBe(25);
    for (const x of d) {
      expect(Days.weekday(x)).toBe(1);
      expect(Rules.nthOfMonth(x)).toBe(3);
    }
  });

  test('monthly on the last Monday', () => {
    const s = '2026-10-26';
    const d = gen.datesFor(task({ start: s, rule: { ...Rules.monthlyOnDay(), monthlyMode: 'lastWeekday' } }), s, twoYears);
    expect(d.slice(0, 3)).toEqual(['2026-10-26', '2026-11-30', '2026-12-28']);
    for (const x of d) expect(Days.month(Days.add(x, 7))).not.toBe(Days.month(x));
  });

  test('yearly incl. Feb 29 only on leap years', () => {
    const s = '2028-02-29';
    expect(gen.datesFor(task({ start: s, rule: Rules.yearly() }), s, '2036-12-31')).toEqual([
      '2028-02-29', '2032-02-29', '2036-02-29',
    ]);
  });

  test('ends on a date / after N', () => {
    const t1 = task({ rule: { ...Rules.daily(), endsOn: '2026-10-23' } });
    expect(gen.datesFor(t1, from, twoYears).length).toBe(5);
    const t2 = task({ rule: { ...Rules.everyOtherDay(), endsAfter: 4 } });
    expect(gen.datesFor(t2, from, twoYears).length).toBe(4);
    expect(gen.datesFor(t2, '2026-10-22', twoYears)).toEqual(['2026-10-23', '2026-10-25']);
  });

  test('dates stay calendar dates across DST', () => {
    const d = gen.datesFor(task({ rule: Rules.daily() }), from, '2027-04-01');
    expect(d.length).toBe(Days.between(from, '2027-04-01') + 1);
    expect(Days.at('2026-10-24', 540).getHours()).toBe(9);
    expect(Days.at('2026-10-26', 540).getHours()).toBe(9);
  });
});

describe('summaries', () => {
  test('human text', () => {
    expect(Rules.summary(Rules.everyOtherDay(), from)).toBe('Every 2 days');
    expect(Rules.summary(Rules.weekdaysOnly(), from)).toBe('Every weekday');
    expect(Rules.summary({ ...Rules.daily(), freq: 'weekly', weekdays: [1, 3, 5] }, from)).toBe('Weekly on Mon, Wed, Fri');
    expect(Rules.summary(Rules.timesPerWeek(3), from)).toBe('3 times a week');
    expect(Rules.summary(Rules.monthlyOnDay(), from)).toBe('Monthly on day 19');
  });

  test('round-trips through a stored task', () => {
    const rule: RepeatRule = { ...Rules.daily(), freq: 'weekly', interval: 2, weekdays: [2, 4], endsAfter: 10 };
    expect(Rules.equal(Rules.fromTask(task({ rule })), rule)).toBe(true);
  });
});

describe('generate()', () => {
  const today = '2026-10-21';

  test('past open occurrences are missed, today pending', () => {
    const occ = gen.generate({ tasks: [task({ rule: Rules.daily() })], records: [] }, Range.of(from, '2026-10-22'), today);
    expect(occ.map((o) => o.status)).toEqual(['missed', 'missed', 'pending', 'pending']);
  });

  test('records: done, skipped, deleted, moved', () => {
    const occ = gen.generate(
      {
        tasks: [task({ rule: Rules.daily() })],
        records: [
          rec({ id: 'a', occurrenceDate: from, status: 'done', completedAt: new Date(2026, 9, 19, 9, 10).getTime() }),
          rec({ id: 'b', occurrenceDate: '2026-10-20', status: 'skipped' }),
          rec({ id: 'c', occurrenceDate: '2026-10-21', status: 'deleted' }),
          rec({ id: 'd', occurrenceDate: '2026-10-25', overrideDate: '2026-10-22', overrideStartMinute: 600 }),
        ],
      },
      Range.of(from, '2026-10-22'),
      today,
    );
    expect(occ.length).toBe(4);
    expect(occ[0].status).toBe('done');
    expect(occ[1].status).toBe('skipped');
    const moved = occ.find((o) => o.originalDate === '2026-10-25')!;
    expect(moved.date).toBe('2026-10-22');
    expect(moved.startMinute).toBe(600);
  });

  test('times-per-week hides for the rest of the week once met', () => {
    const t = task({ rule: Rules.timesPerWeek(2), startMinute: null });
    const week = Range.of(from, '2026-10-25');
    const run = (records: OccurrenceRecord[]) => gen.generate({ tasks: [t], records }, week, today);
    expect(run([]).map((o) => o.date)).toEqual(['2026-10-21', '2026-10-22', '2026-10-23', '2026-10-24', '2026-10-25']);
    const met = run([
      rec({ id: 'a', occurrenceDate: from, status: 'done' }),
      rec({ id: 'b', occurrenceDate: today, status: 'done' }),
    ]);
    expect(met.map((o) => o.date)).toEqual(['2026-10-19', '2026-10-21']);
  });
});

test('this and following split', () => {
  const original = task({ rule: { ...Rules.daily(), endsAfter: 10 } });
  const at = '2026-10-23';
  const edited = Rules.applyTo({ ...Rules.everyOtherDay(), endsAfter: 10 }, { ...original, title: 'Edited' });
  const split = splitSeries({ original, at, edited, newId: 't2', now, generator: gen });
  expect(split.ended.endsOn).toBe('2026-10-22');
  expect(gen.datesFor(split.ended, from, twoYears).length).toBe(4);
  expect(split.following.seriesId).toBe(original.seriesId);
  expect(split.following.endsAfterCount).toBe(6);
  expect(gen.datesFor(split.following, from, twoYears).slice(0, 3)).toEqual(['2026-10-23', '2026-10-25', '2026-10-27']);
});
