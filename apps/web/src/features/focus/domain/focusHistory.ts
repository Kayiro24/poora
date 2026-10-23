import { Days, Range, type DateRange, type Day } from '../../../core/time/days';
import type { FocusSessionRecord } from '../../insights/domain/metrics';
import { FocusTracker } from './focusTracker';

/** Totals for a set of focus sessions, keeping the four kinds of time apart. */
export interface FocusTotals {
  sessions: number;
  completed: number;
  focusMs: number;
  pausedMs: number;
  awayMs: number;
  interruptions: number;
  appUsageMs: number;
  distractionMs: number;
}

export interface TaskFocusGroup {
  /** Null = sessions not linked to a task. */
  taskId: string | null;
  totals: FocusTotals;
  /** Newest first. */
  sessions: FocusSessionRecord[];
}

const emptyTotals: FocusTotals = { sessions: 0, completed: 0, focusMs: 0, pausedMs: 0, awayMs: 0, interruptions: 0, appUsageMs: 0, distractionMs: 0 };

export const Sessions = {
  appUsageMs: (s: FocusSessionRecord) => (s.endedAt == null ? 0 : FocusTracker.appUsageMs(s.startedAt, s.endedAt, s.awayMs)),
  distractionMs: (s: FocusSessionRecord) => Object.values(s.distractions).reduce((a, b) => a + b, 0),
};

export const FocusHistory = {
  totals: (sessions: Iterable<FocusSessionRecord>): FocusTotals => {
    const t = { ...emptyTotals };
    for (const s of sessions) {
      t.sessions++;
      if (!s.endedEarly) t.completed++;
      t.focusMs += s.focusMsCompleted;
      t.pausedMs += s.pausedMs;
      t.awayMs += s.awayMs;
      t.interruptions += s.interruptions;
      t.appUsageMs += Sessions.appUsageMs(s);
      t.distractionMs += Sessions.distractionMs(s);
    }
    return t;
  },

  /** Interruptions per hour of focus — lower is better. */
  interruptionsPerHour: (t: FocusTotals) => (t.focusMs === 0 ? null : t.interruptions / (t.focusMs / 3_600_000)),

  inRange: (sessions: Iterable<FocusSessionRecord>, r: DateRange) =>
    [...sessions].filter((s) => Range.contains(r, Days.of(new Date(s.startedAt)))),

  /** Sessions grouped by linked task, biggest focus total first; unlinked last. */
  byTask(sessions: Iterable<FocusSessionRecord>): TaskFocusGroup[] {
    const groups = new Map<string | null, FocusSessionRecord[]>();
    for (const s of sessions) {
      const l = groups.get(s.linkedTaskId) ?? [];
      l.push(s);
      groups.set(s.linkedTaskId, l);
    }
    return [...groups.entries()]
      .map(([taskId, list]) => ({
        taskId,
        totals: FocusHistory.totals(list),
        sessions: [...list].sort((a, b) => b.startedAt - a.startedAt),
      }))
      .sort((a, b) => {
        if ((a.taskId == null) !== (b.taskId == null)) return a.taskId == null ? 1 : -1;
        return b.totals.focusMs - a.totals.focusMs;
      });
  },

  /** Focus minutes per day across `r`. */
  minutesByDay(sessions: Iterable<FocusSessionRecord>, r: DateRange): Map<Day, number> {
    const out = new Map<Day, number>(Range.days(r).map((d) => [d, 0]));
    for (const s of sessions) {
      const d = Days.of(new Date(s.startedAt));
      if (out.has(d)) out.set(d, out.get(d)! + s.focusMsCompleted / 60000);
    }
    return out;
  },

  /**
   * "You versus you": consecutive days, ending today, whose focus reached
   * `goalMin`. Today only counts once it's reached — until then the streak
   * runs to yesterday, so an unfinished today never breaks it.
   */
  goalStreak(sessions: Iterable<FocusSessionRecord>, goalMin: number, today: Day): number {
    if (goalMin <= 0) return 0;
    const byDay = new Map<Day, number>();
    for (const s of sessions) {
      const d = Days.of(new Date(s.startedAt));
      byDay.set(d, (byDay.get(d) ?? 0) + s.focusMsCompleted / 60000);
    }
    const met = (d: Day) => (byDay.get(d) ?? 0) >= goalMin;
    let d = met(today) ? today : Days.add(today, -1);
    let n = 0;
    while (met(d)) {
      n++;
      d = Days.add(d, -1);
    }
    return n;
  },

  /** Days in `r` whose focus reached `goalMin`. */
  goalDays: (sessions: Iterable<FocusSessionRecord>, goalMin: number, r: DateRange) =>
    goalMin <= 0 ? 0 : [...FocusHistory.minutesByDay(sessions, r).values()].filter((m) => m >= goalMin).length,

  /** Total ms per monitored app across sessions, most-used first. */
  distractingApps(sessions: Iterable<FocusSessionRecord>): [string, number][] {
    const m = new Map<string, number>();
    for (const s of sessions) for (const [k, v] of Object.entries(s.distractions)) m.set(k, (m.get(k) ?? 0) + v);
    return [...m.entries()].sort((a, b) => b[1] - a[1]);
  },
};
