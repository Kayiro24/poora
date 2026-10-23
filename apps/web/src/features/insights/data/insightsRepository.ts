import { useMemo } from 'react';
import { useDb, type FocusSessionRow } from '../../../core/db/store';
import { useGenerator, useSettings, useSnapshot, useToday, useTrashed } from '../../../core/hooks';
import { Days, Range, type DateRange, type Day } from '../../../core/time/days';
import { isQuota, type Occurrence, type Task, type TaskSnapshot } from '../../tasks/domain/models';
import type { OccurrenceGenerator } from '../../tasks/domain/occurrenceGenerator';
import { Metrics, weekProgressOf, type DayCompletion, type FocusSessionRecord, type FocusStats, type Streak, type TaskOutcomes, type WeekProgress } from '../domain/metrics';

/** Completion-calendar filter: everything, one tag, or one recurring series. */
export interface CalendarFilter {
  tag?: string;
  seriesId?: string;
}

export const Filters = {
  all: {} as CalendarFilter,
  encode: (f: CalendarFilter) => (f.tag ? `tag:${f.tag}` : f.seriesId ? `task:${f.seriesId}` : null),
  decode(s: string | null): CalendarFilter {
    if (s?.startsWith('tag:')) return { tag: s.slice(4) };
    if (s?.startsWith('task:')) return { seriesId: s.slice(5) };
    return {};
  },
  key: (f: CalendarFilter) => Filters.encode(f) ?? 'all',
  matches: (f: CalendarFilter, o: Occurrence) =>
    (!f.tag || o.task.tag?.trim() === f.tag) && (!f.seriesId || o.task.seriesId === f.seriesId),
};

export interface RecurringSeries {
  seriesId: string;
  task: Task;
}

export const sessionFromRow = (r: FocusSessionRow): FocusSessionRecord => ({
  id: r.id,
  startedAt: r.startedAt,
  endedAt: r.endedAt,
  config: { focusMin: r.plannedFocusMin, shortMin: r.shortBreakMin, longMin: r.longBreakMin, longEvery: r.longEvery },
  focusMsCompleted: r.focusMsCompleted,
  phasesCompleted: r.phasesCompleted,
  endedEarly: r.endedEarly,
  linkedTaskId: r.linkedTaskId,
  linkedOccurrenceDate: r.linkedOccurrenceDate,
  pausedMs: r.pausedMs ?? 0,
  awayMs: r.awayMs ?? 0,
  interruptions: r.interruptions ?? 0,
  distractions: parseDistractions(r.distractions),
});

function parseDistractions(json: string | null | undefined): Record<string, number> {
  if (!json) return {};
  try {
    const m = JSON.parse(json) as Record<string, unknown>;
    return Object.fromEntries(Object.entries(m).filter((e): e is [string, number] => typeof e[1] === 'number'));
  } catch {
    return {};
  }
}

/** Pure computation over a snapshot; caches live as long as the instance. */
export class InsightsRepository {
  private occCache = new Map<string, Occurrence[]>();
  private dayCache = new Map<string, Map<Day, DayCompletion>>();
  readonly firstUse: Day | null;

  constructor(
    readonly snapshot: TaskSnapshot,
    readonly sessions: FocusSessionRecord[],
    readonly generator: OccurrenceGenerator,
    readonly today: Day,
    readonly mondayFirst: boolean,
    readonly trashed: Task[] = [],
  ) {
    let first: Day | null = null;
    for (const t of snapshot.tasks) {
      const d = Days.of(new Date(t.createdAt));
      if (!first || d < first) first = d;
    }
    this.firstUse = first;
  }

  get hasData() {
    return this.snapshot.tasks.length > 0;
  }

  occurrences(r: DateRange): Occurrence[] {
    const k = Range.key(r);
    let v = this.occCache.get(k);
    if (!v) this.occCache.set(k, (v = this.generator.generate(this.snapshot, r, this.today)));
    return v;
  }

  week = (d: Day) => Range.week(d, this.mondayFirst);

  dayCompletion(r: DateRange, filter: CalendarFilter = Filters.all): Map<Day, DayCompletion> {
    const k = `${Range.key(r)}|${Filters.key(filter)}`;
    let v = this.dayCache.get(k);
    if (v) return v;
    const occ = this.occurrences(r).filter((o) => Filters.matches(filter, o));
    const series = filter.seriesId ? this.seriesTask(filter.seriesId) : null;
    v = series && isQuota(series) ? this.habitQuota(r, occ) : Metrics.dayCompletions(r, occ, this.today, this.firstUse);
    this.dayCache.set(k, v);
    return v;
  }

  /** Quota habits are weekly: green when done that day, otherwise neutral. */
  private habitQuota(r: DateRange, occ: Occurrence[]): Map<Day, DayCompletion> {
    const out = new Map<Day, DayCompletion>();
    for (const d of Range.days(r)) {
      const done = occ.filter((o) => o.date === d && o.status === 'done').length;
      const tier = done > 0 ? 'perfect' : d > this.today ? 'future' : this.firstUse && d < this.firstUse ? 'beforeFirstUse' : 'rest';
      out.set(d, { day: d, tier, done, skipped: 0, missed: 0, pending: 0 });
    }
    return out;
  }

  doneCount = (r: DateRange) => Metrics.doneCount(this.occurrences(r));
  completionRate = (r: DateRange) => Metrics.completionRate(this.occurrences(r));

  overallStreak(): number {
    return Metrics.overallDayStreak(this.dayCompletion(Range.of(Days.add(this.today, -400), this.today)), this.today);
  }

  bestPerfectRun(r: DateRange, filter: CalendarFilter = Filters.all): number {
    const days = this.dayCompletion(r, filter);
    let best = 0, run = 0;
    for (const d of Range.days(r)) {
      const c = days.get(d)!;
      if (c.tier === 'perfect') best = Math.max(best, ++run);
      else if (c.tier !== 'rest') run = 0;
    }
    return best;
  }

  recurringSeries(): RecurringSeries[] {
    const by = new Map<string, Task>();
    for (const t of this.snapshot.tasks) {
      if (t.repeatKind === 'none') continue;
      const cur = by.get(t.seriesId);
      if (!cur || t.startDate > cur.startDate) by.set(t.seriesId, t);
    }
    return [...by.entries()]
      .map(([seriesId, task]) => ({ seriesId, task }))
      .sort((a, b) => a.task.title.toLowerCase().localeCompare(b.task.title.toLowerCase()));
  }

  seriesTask(seriesId: string): Task | null {
    let best: Task | null = null;
    for (const t of this.snapshot.tasks) if (t.seriesId === seriesId && (!best || t.startDate > best.startDate)) best = t;
    return best;
  }

  private seriesStart(seriesId: string): Day {
    let s = this.today;
    for (const t of this.snapshot.tasks) if (t.seriesId === seriesId && t.startDate < s) s = t.startDate;
    return s;
  }

  seriesOccurrences = (seriesId: string, r: DateRange) => this.occurrences(r).filter((o) => o.task.seriesId === seriesId);

  weekProgress(seriesId: string, week: DateRange): WeekProgress {
    const occ = [...this.seriesOccurrences(seriesId, week)].sort((a, b) => (a.date < b.date ? -1 : 1));
    return weekProgressOf(occ.map((o) => o.status));
  }

  quotaDone(seriesId: string, weekStart: Day): number {
    return this.occurrences(this.week(weekStart)).filter((o) => o.task.seriesId === seriesId && o.status === 'done').length;
  }

  weeklyTrend(seriesId: string, weeks = 4): (number | null)[] {
    const task = this.seriesTask(seriesId)!;
    const cur = this.week(this.today);
    const out: (number | null)[] = [];
    for (let i = weeks - 1; i >= 0; i--) {
      const w = Range.of(Days.add(cur.from, -7 * i), Days.add(cur.to, -7 * i));
      out.push(isQuota(task) ? Math.min(this.quotaDone(seriesId, w.from) / (task.quotaPerWeek ?? 1), 1) : this.weekProgress(seriesId, w).rate);
    }
    return out;
  }

  streak(seriesId: string): Streak {
    const task = this.seriesTask(seriesId)!;
    const start = this.seriesStart(seriesId);
    if (isQuota(task)) {
      const weeks = new Map<Day, number>();
      for (let w = this.week(start).from; w <= this.today; w = Days.add(w, 7)) weeks.set(w, this.quotaDone(seriesId, w));
      return Metrics.quotaStreak(task, weeks, this.week(this.today).from);
    }
    return Metrics.taskStreak(this.seriesOccurrences(seriesId, Range.of(start, this.today)));
  }

  quotaWeeksMet(seriesId: string): number | null {
    const task = this.seriesTask(seriesId)!;
    const current = this.week(this.today).from;
    let met = 0, total = 0;
    for (let w = this.week(this.seriesStart(seriesId)).from; w <= current; w = Days.add(w, 7)) {
      const ok = Metrics.quotaMet(task, this.quotaDone(seriesId, w));
      if (w === current && !ok) continue;
      total++;
      if (ok) met++;
    }
    return total === 0 ? null : met / total;
  }

  onTime = (r: DateRange) => Metrics.onTime(this.occurrences(r));
  completionsByHour = (r: DateRange) => Metrics.completionsByHour(this.occurrences(r));
  byCategory = (r: DateRange) => Metrics.byCategory(this.occurrences(r));

  tags(): string[] {
    return [...new Set(this.snapshot.tasks.map((t) => t.tag?.trim()).filter((t): t is string => !!t))].sort();
  }

  sessionsIn = (r: DateRange) => this.sessions.filter((s) => Range.contains(r, Days.of(new Date(s.startedAt))));
  outcomes = (r: DateRange): TaskOutcomes => Metrics.outcomes(r, this.occurrences(r), this.snapshot.records, this.trashed);
  focus = (r: DateRange): FocusStats => Metrics.focus(this.sessionsIn(r));
  focusMinutesOn = (d: Day) => this.focus(Range.day(d)).totalMinutes;
  taskTitle = (taskId: string) => this.snapshot.tasks.find((t) => t.id === taskId)?.title ?? 'Deleted task';
}

/** Recreated whenever tasks, records, sessions, today or week start change. */
export function useInsights(): InsightsRepository {
  const snapshot = useSnapshot();
  const rows = useDb((s) => s.focusSessions);
  const gen = useGenerator();
  const today = useToday();
  const mondayFirst = useSettings().mondayFirst;
  const trashed = useTrashed();
  return useMemo(() => {
    const sessions = rows.filter((r) => r.endedAt != null).map(sessionFromRow);
    return new InsightsRepository(snapshot, sessions, gen, today, mondayFirst, trashed);
  }, [snapshot, rows, gen, today, mondayFirst, trashed]);
}
