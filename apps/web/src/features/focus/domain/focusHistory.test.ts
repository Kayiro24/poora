// Parity with test/features/focus/focus_history_test.dart.
import { describe, expect, test } from 'vitest';
import { Days, Range } from '../../../core/time/days';
import type { FocusSessionRecord } from '../../insights/domain/metrics';
import { FocusHistory } from './focusHistory';
import { defaultFocus } from './timerEngine';

const MIN = 60000;
const DAY = 86_400_000;

interface Opts {
  task?: string;
  paused?: number;
  away?: number;
  interruptions?: number;
  early?: boolean;
  apps?: Record<string, number>;
}

function s(id: string, start: number, focusMin: number, o: Opts = {}): FocusSessionRecord {
  return {
    id,
    startedAt: start,
    endedAt: start + (focusMin + (o.paused ?? 0)) * MIN,
    config: defaultFocus,
    focusMsCompleted: focusMin * MIN,
    phasesCompleted: 1,
    endedEarly: o.early ?? false,
    linkedTaskId: o.task ?? null,
    linkedOccurrenceDate: null,
    pausedMs: (o.paused ?? 0) * MIN,
    awayMs: (o.away ?? 0) * MIN,
    interruptions: o.interruptions ?? 0,
    distractions: o.apps ?? {},
  };
}

const mon = new Date(2026, 9, 19, 9).getTime();
const sessions = [
  s('1', mon, 25, { task: 'write', away: 3, interruptions: 2, apps: { 'com.social': 2 * MIN } }),
  s('2', mon + DAY, 45, { task: 'write', paused: 5 }),
  s('3', mon + 2 * DAY, 15, { task: 'email', early: true, interruptions: 1, away: 1 }),
  s('4', mon + 2 * DAY + 3 * 3_600_000, 60),
  s('5', mon - 7 * DAY, 30, { task: 'write' }), // last week
];
const week = Range.week(Days.of(new Date(mon)), true);

describe('FocusHistory', () => {
  test('totals keep focus, paused, away and app use apart', () => {
    const t = FocusHistory.totals(FocusHistory.inRange(sessions, week));
    expect([t.sessions, t.completed, t.focusMs, t.pausedMs, t.awayMs, t.interruptions]).toEqual([4, 3, 145 * MIN, 5 * MIN, 4 * MIN, 3]);
    // App use = wall time − away: (25 + 50 + 15 + 60) − 4.
    expect(t.appUsageMs).toBe((150 - 4) * MIN);
    expect(FocusHistory.interruptionsPerHour(t)).toBeCloseTo(3 / (145 / 60), 9);
  });

  test('grouped by task: biggest first, unlinked last, sessions newest first', () => {
    const g = FocusHistory.byTask(sessions);
    expect(g.map((x) => x.taskId)).toEqual(['write', 'email', null]);
    expect(g[0].totals.focusMs).toBe((25 + 45 + 30) * MIN);
    expect(g[0].sessions.map((x) => x.id)).toEqual(['2', '1', '5']);
  });

  test('daily minutes across the week and distracting apps', () => {
    const days = FocusHistory.minutesByDay(sessions, week);
    const monDay = Days.of(new Date(mon));
    expect(days.get(monDay)).toBe(25);
    expect(days.get(Days.add(monDay, 2))).toBe(75);
    expect(days.size).toBe(7);
    expect(FocusHistory.distractingApps(sessions)).toEqual([['com.social', 2 * MIN]]);
  });

  test('daily goal: streak ends today (or yesterday until today is met)', () => {
    const day = Days.of(new Date(mon));
    const runs = [s('a', mon - 2 * DAY, 60), s('b', mon - DAY, 30), s('c', mon - 22 * 3_600_000, 40), s('d', mon, 20)];
    // Today 20/60 not met yet: streak counts the two days before.
    expect(FocusHistory.goalStreak(runs, 60, day)).toBe(2);
    expect(FocusHistory.goalStreak([...runs, s('e', mon + 2 * 3_600_000, 45)], 60, day)).toBe(3);
    expect(FocusHistory.goalStreak(runs, 61, day)).toBe(1); // the day before yesterday had 60
    expect(FocusHistory.goalStreak(runs, 71, day)).toBe(0);
    expect(FocusHistory.goalDays(runs, 60, Range.of(Days.add(day, -6), day))).toBe(2);
  });
});
