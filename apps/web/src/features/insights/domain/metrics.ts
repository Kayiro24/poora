import { Days, Range, type DateRange, type Day } from '../../../core/time/days';
import type { FocusConfig } from '../../focus/domain/timerEngine';
import { isQuota, Occ, type Occurrence, type OccurrenceRecord, type OccurrenceStatus, type Task } from '../../tasks/domain/models';

/** A finished focus cycle (`focus_sessions`). */
export interface FocusSessionRecord {
  id: string;
  startedAt: number;
  endedAt: number | null;
  config: FocusConfig;
  focusMsCompleted: number;
  phasesCompleted: number;
  endedEarly: boolean;
  linkedTaskId: string | null;
  linkedOccurrenceDate: Day | null;
  pausedMs: number;
  awayMs: number;
  interruptions: number;
  /** Package → ms in apps chosen as distracting (Android only). */
  distractions: Record<string, number>;
}

/** Completed / not completed / deleted for a period (Google Calendar-style deletes). */
export interface TaskOutcomes {
  completed: number;
  /** Past occurrences that weren't done (missed). */
  notCompleted: number;
  /** Single occurrences deleted ("This task") on days in the period. */
  deletedOccurrences: number;
  /** Whole tasks/series moved to Trash during the period. */
  deletedTasks: number;
}

export const Outcomes = {
  deleted: (o: TaskOutcomes) => o.deletedOccurrences + o.deletedTasks,
  total: (o: TaskOutcomes) => o.completed + o.notCompleted + o.deletedOccurrences + o.deletedTasks,
};

/** Tier thresholds (§4.11). Tune here only. */
export const CompletionTiers = {
  perfect: 1,
  high: 0.8,
  mid: 0.5,
  streakThreshold: 0.8,
  tierFor(rate: number): DayTier {
    if (rate >= 1) return 'perfect';
    if (rate >= 0.8) return 'high';
    if (rate >= 0.5) return 'mid';
    if (rate > 0) return 'low';
    return 'missed';
  },
};

export type DayTier = 'perfect' | 'high' | 'mid' | 'low' | 'missed' | 'rest' | 'today' | 'future' | 'beforeFirstUse';

export interface DayCompletion {
  day: Day;
  tier: DayTier;
  done: number;
  skipped: number;
  missed: number;
  pending: number;
}

export const DC = {
  scheduled: (c: DayCompletion) => c.done + c.missed + c.pending,
  rate: (c: DayCompletion) => (DC.scheduled(c) === 0 ? null : c.done / DC.scheduled(c)),
  percent: (c: DayCompletion) => {
    const r = DC.rate(c);
    return r == null ? null : Math.round(r * 100);
  },
};

export interface WeekProgress {
  segments: OccurrenceStatus[];
  done: number;
  total: number;
  rate: number | null;
}

export const weekProgressOf = (segments: OccurrenceStatus[]): WeekProgress => {
  const done = segments.filter((s) => s === 'done').length;
  const total = segments.filter((s) => s !== 'skipped').length;
  return { segments, done, total, rate: total === 0 ? null : done / total };
};

export interface Streak {
  current: number;
  best: number;
}

export interface FocusStats {
  minutesByDay: Map<Day, number>;
  completed: number;
  endedEarly: number;
  averageMinutes: number;
  bestHour: number | null;
  minutesByTask: [string, number][];
  totalMinutes: number;
}

const fixed = (occ: Iterable<Occurrence>) => [...occ].filter((o) => !isQuota(o.task));

/** Pure analytics definitions (§7). Quota tasks count weekly only. */
export const Metrics = {
  dayCompletion(day: Day, occurrences: Iterable<Occurrence>, today: Day, firstUse: Day | null): DayCompletion {
    let done = 0, skipped = 0, missed = 0, pending = 0;
    for (const o of fixed(occurrences)) {
      if (o.date !== day) continue;
      if (o.status === 'done') done++;
      else if (o.status === 'skipped') skipped++;
      else if (o.status === 'missed') missed++;
      else pending++;
    }
    const scheduled = done + missed + pending;
    let tier: DayTier;
    if (firstUse && day < firstUse) tier = 'beforeFirstUse';
    else if (day > today) tier = 'future';
    else if (scheduled === 0) tier = 'rest';
    else if (day === today) tier = done === scheduled ? 'perfect' : 'today';
    else tier = CompletionTiers.tierFor(done / scheduled);
    return { day, tier, done, skipped, missed, pending };
  },

  dayCompletions(range: DateRange, occurrences: Occurrence[], today: Day, firstUse: Day | null): Map<Day, DayCompletion> {
    const byDay = new Map<Day, Occurrence[]>();
    for (const o of occurrences) {
      const l = byDay.get(o.date);
      if (l) l.push(o);
      else byDay.set(o.date, [o]);
    }
    const out = new Map<Day, DayCompletion>();
    for (const d of Range.days(range)) out.set(d, Metrics.dayCompletion(d, byDay.get(d) ?? [], today, firstUse));
    return out;
  },

  completionRate(occ: Iterable<Occurrence>): number | null {
    let done = 0, missed = 0;
    for (const o of fixed(occ)) {
      if (o.status === 'done') done++;
      if (o.status === 'missed') missed++;
    }
    return done + missed === 0 ? null : done / (done + missed);
  },

  doneCount: (occ: Iterable<Occurrence>) => [...occ].filter(Occ.isDone).length,

  weekProgress(task: Task, occ: Iterable<Occurrence>, week: DateRange): WeekProgress {
    const list = [...occ].filter((o) => o.task.id === task.id && Range.contains(week, o.date)).sort((a, b) => (a.date < b.date ? -1 : 1));
    return weekProgressOf(list.map((o) => o.status));
  },

  quotaMet: (task: Task, doneInWeek: number) => doneInWeek >= (task.quotaPerWeek ?? 1),

  /** Consecutive completions back from the latest past one; skips don't break it. */
  taskStreak(occ: Iterable<Occurrence>): Streak {
    const list = [...occ].filter((o) => o.status !== 'pending').sort((a, b) => (a.date < b.date ? -1 : a.date > b.date ? 1 : 0));
    let best = 0, run = 0;
    for (const o of list) {
      if (o.status === 'done') {
        run++;
        best = Math.max(best, run);
      } else if (o.status === 'missed') run = 0;
    }
    return { current: run, best };
  },

  quotaStreak(task: Task, doneByWeekStart: Map<Day, number>, currentWeekStart: Day): Streak {
    const weeks = [...doneByWeekStart.keys()].sort();
    let best = 0, run = 0;
    for (const w of weeks) {
      if (Metrics.quotaMet(task, doneByWeekStart.get(w)!)) {
        run++;
        best = Math.max(best, run);
      } else if (w !== currentWeekStart) run = 0;
    }
    return { current: run, best };
  },

  overallDayStreak(days: Map<Day, DayCompletion>, today: Day): number {
    let streak = 0;
    for (let d = today; days.has(d); d = Days.add(d, -1)) {
      const c = days.get(d)!;
      const rate = DC.rate(c);
      if (c.tier === 'beforeFirstUse') break;
      if (rate == null) continue;
      if (d === today && rate < CompletionTiers.streakThreshold) continue;
      if (rate < CompletionTiers.streakThreshold) break;
      streak++;
    }
    return streak;
  },

  onTime(occ: Iterable<Occurrence>): [number, number] {
    let on = 0, late = 0;
    for (const o of fixed(occ)) {
      if (o.status !== 'done') continue;
      if (Occ.onTime(o)) on++;
      else late++;
    }
    return [on, late];
  },

  completionsByHour(occ: Iterable<Occurrence>): number[] {
    const h = new Array<number>(24).fill(0);
    for (const o of occ) if (o.status === 'done' && o.completedAt != null) h[new Date(o.completedAt).getHours()]++;
    return h;
  },

  bestWindow(byHour: number[]): number | null {
    let best = -1, at = -1;
    for (let i = 0; i < 24; i++) {
      const v = byHour[i] + (i < 23 ? byHour[i + 1] : 0);
      if (v > best) [best, at] = [v, i];
    }
    return best <= 0 ? null : at;
  },

  byCategory(occ: Iterable<Occurrence>): [string, number][] {
    const m = new Map<string, number>();
    for (const o of occ) {
      if (o.status !== 'done') continue;
      const tag = o.task.tag?.trim() || 'Untagged';
      m.set(tag, (m.get(tag) ?? 0) + 1);
    }
    return [...m.entries()].sort((a, b) => b[1] - a[1]);
  },

  outcomes(range: DateRange, occ: Iterable<Occurrence>, records: Iterable<OccurrenceRecord>, trashed: Iterable<Task>): TaskOutcomes {
    let completed = 0, notCompleted = 0, deletedOccurrences = 0, deletedTasks = 0;
    for (const o of occ) {
      if (!Range.contains(range, o.date)) continue;
      if (o.status === 'done') completed++;
      if (o.status === 'missed') notCompleted++;
    }
    for (const r of records) if (r.status === 'deleted' && Range.contains(range, r.overrideDate ?? r.occurrenceDate)) deletedOccurrences++;
    for (const t of trashed) if (t.deletedAt != null && Range.contains(range, Days.of(new Date(t.deletedAt)))) deletedTasks++;
    return { completed, notCompleted, deletedOccurrences, deletedTasks };
  },

  focus(sessions: Iterable<FocusSessionRecord>): FocusStats {
    const byDay = new Map<Day, number>();
    const byHour = new Array<number>(24).fill(0);
    const byTask = new Map<string, number>();
    let completed = 0, early = 0, total = 0, count = 0;
    for (const s of sessions) {
      const mins = s.focusMsCompleted / 60000;
      const started = new Date(s.startedAt);
      const day = Days.of(started);
      byDay.set(day, (byDay.get(day) ?? 0) + mins);
      byHour[started.getHours()] += mins;
      if (s.linkedTaskId) byTask.set(s.linkedTaskId, (byTask.get(s.linkedTaskId) ?? 0) + mins);
      if (s.endedEarly) early++;
      else completed++;
      total += mins;
      count++;
    }
    let bestHour: number | null = null, bestVal = 0;
    for (let i = 0; i < 24; i++) if (byHour[i] > bestVal) [bestVal, bestHour] = [byHour[i], i];
    return {
      minutesByDay: byDay,
      completed,
      endedEarly: early,
      averageMinutes: count === 0 ? 0 : total / count,
      bestHour,
      minutesByTask: [...byTask.entries()].sort((a, b) => b[1] - a[1]),
      totalMinutes: total,
    };
  },
};
