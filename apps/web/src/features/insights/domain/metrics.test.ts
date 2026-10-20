// Parity with test/features/insights/metrics_test.dart — same seeded 4-week
// dataset, same hand-computed answers.
import { describe, expect, test } from 'vitest';
import { Days, Range } from '../../../core/time/days';
import { defaultFocus } from '../../focus/domain/timerEngine';
import type { OccurrenceRecord, Task } from '../../tasks/domain/models';
import { OccurrenceGenerator } from '../../tasks/domain/occurrenceGenerator';
import { Rules, type RepeatRule } from '../../tasks/domain/recurrence';
import { DC, Metrics } from './metrics';

const start = '2026-09-28';
const end = '2026-10-25';
const today = '2026-10-26';
const created = new Date(2026, 8, 27).getTime();

function mk(id: string, title: string, rule: RepeatRule, o: { at?: number; dur?: number; tag?: string; start?: string } = {}): Task {
  return Rules.applyTo(rule, {
    id, title, notes: null, color: 0xfff2705e, tag: o.tag ?? null, priority: 0,
    allDay: o.at == null, startDate: o.start ?? start, startMinute: o.at ?? null, durationMin: o.dur ?? null,
    repeatKind: 'none', rrule: null, quotaPerWeek: null, quotaPreferredDays: [], endsOn: null,
    endsAfterCount: null, seriesId: id, timeZone: null, createdAt: created, updatedAt: created, deletedAt: null, reminders: [],
  });
}
const r = (taskId: string, day: string, status: OccurrenceRecord['status'], at?: Date, late = false): OccurrenceRecord => ({
  id: `${taskId}-${day}`, taskId, occurrenceDate: day, status, completedAt: at?.getTime() ?? null,
  overrideDate: null, overrideStartMinute: null, overrideTitle: null, late,
});

const tasks = [
  mk('A', 'Read', Rules.daily(), { at: 480, dur: 30, tag: 'Mind' }),
  mk('B', 'Gym', { ...Rules.daily(), freq: 'weekly', weekdays: [1, 3, 5] }, { at: 1080, dur: 60, tag: 'Health' }),
  mk('C', 'Taxes', Rules.none, { start: '2026-10-07' }),
  mk('D', 'Run', Rules.timesPerWeek(3), { tag: 'Health' }),
];
const records: OccurrenceRecord[] = [];
for (const day of Days.range(start, end)) {
  if (day === '2026-10-15') records.push(r('A', day, 'skipped'));
  else if (day !== '2026-10-02' && day !== '2026-10-10') records.push(r('A', day, 'done', Days.at(day, 495)));
  if ([1, 3, 5].includes(Days.weekday(day)) && day !== '2026-10-09' && day !== '2026-10-21') {
    records.push(r('B', day, 'done', Days.at(day, 1125)));
  }
}
records.push(r('C', '2026-10-07', 'done', new Date(2026, 9, 8, 10), true));
for (const s of ['2026-09-29', '2026-09-30', '2026-10-01', '2026-10-06', '2026-10-13', '2026-10-15', '2026-10-17', '2026-10-20', '2026-10-22']) {
  records.push(r('D', s, 'done', Days.at(s, 420)));
}

const gen = new OccurrenceGenerator(true);
const snapshot = { tasks, records };
const range = Range.of(start, today);
const occ = gen.generate(snapshot, range, today);
const past = occ.filter((o) => o.date <= end);
const days = Metrics.dayCompletions(range, occ, today, start);

describe('metrics on the seeded dataset', () => {
  test('completion rate', () => {
    expect(Metrics.completionRate(occ)).toBeCloseTo(0.9, 9);
  });

  test('daily % and tiers', () => {
    expect(DC.percent(days.get('2026-10-02')!)).toBe(50);
    expect(days.get('2026-10-02')!.tier).toBe('mid');
    expect(days.get('2026-10-10')!.tier).toBe('missed');
    expect(days.get('2026-10-15')!.tier).toBe('rest');
    expect(days.get('2026-10-07')!.tier).toBe('perfect');
    expect(DC.scheduled(days.get('2026-10-07')!)).toBe(3);
    expect(days.get('2026-10-26')!.tier).toBe('today');
    expect(Metrics.dayCompletion('2026-09-01', [], today, start).tier).toBe('beforeFirstUse');
  });

  test('streaks', () => {
    expect(Metrics.overallDayStreak(days, today)).toBe(4);
    expect(Metrics.taskStreak(occ.filter((o) => o.task.id === 'A'))).toEqual({ current: 14, best: 14 });
    expect(Metrics.taskStreak(occ.filter((o) => o.task.id === 'B'))).toEqual({ current: 1, best: 5 });
  });

  test('week progress', () => {
    const p = Metrics.weekProgress(tasks[1], occ, Range.week('2026-10-19', true));
    expect([p.done, p.total]).toEqual([2, 3]);
    expect(p.segments).toEqual(['done', 'missed', 'done']);
  });

  test('quota', () => {
    const weeks = new Map<string, number>();
    for (let w = start; w <= today; w = Days.add(w, 7)) weeks.set(w, gen.quotaDone(tasks[3], w, records));
    expect([...weeks.values()]).toEqual([3, 1, 3, 2, 0]);
    expect(Metrics.quotaStreak(tasks[3], weeks, today)).toEqual({ current: 0, best: 1 });
  });

  test('timing and categories', () => {
    expect(Metrics.onTime(occ)).toEqual([35, 1]);
    const hours = Metrics.completionsByHour(past);
    expect([hours[8], hours[18], hours[10], hours[7]]).toEqual([25, 10, 1, 9]);
    expect(Metrics.bestWindow(hours)).toBe(7);
    expect(Metrics.byCategory(past)).toEqual([['Mind', 25], ['Health', 19], ['Untagged', 1]]);
  });

  test('focus stats', () => {
    const f = Metrics.focus([
      { id: 's1', startedAt: new Date(2026, 9, 19, 9).getTime(), endedAt: null, config: defaultFocus, focusMsCompleted: 100 * 60000, phasesCompleted: 8, endedEarly: false, linkedTaskId: null, linkedOccurrenceDate: null },
      { id: 's2', startedAt: new Date(2026, 9, 20, 14).getTime(), endedAt: null, config: defaultFocus, focusMsCompleted: 12 * 60000, phasesCompleted: 1, endedEarly: true, linkedTaskId: 'A', linkedOccurrenceDate: null },
    ]);
    expect(f.minutesByDay.get('2026-10-19')).toBe(100);
    expect([f.completed, f.endedEarly, f.averageMinutes, f.bestHour, f.totalMinutes]).toEqual([1, 1, 56, 9, 112]);
    expect(f.minutesByTask[0][0]).toBe('A');
  });
});
