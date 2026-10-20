import { Days, type Day } from '../../../core/time/days';

export type RepeatKind = 'none' | 'rrule' | 'quota';

/** 0 none, 1 low, 2 high. */
export type Priority = 0 | 1 | 2;

/**
 * A reminder on a task.
 * - `atMinute` null: fires at occurrence start + `offsetMin` (negative = before).
 * - `atMinute` set: fires on (day + offsetMin/1440 days) at `atMinute`.
 */
export interface TaskReminder {
  id: string;
  offsetMin: number;
  atMinute: number | null;
}

export interface Task {
  id: string;
  title: string;
  notes: string | null;
  /** ARGB colour value (same as the app). */
  color: number;
  tag: string | null;
  priority: Priority;
  allDay: boolean;
  startDate: Day;
  startMinute: number | null;
  durationMin: number | null;
  repeatKind: RepeatKind;
  /** RFC 5545 body without DTSTART/UNTIL/COUNT. */
  rrule: string | null;
  quotaPerWeek: number | null;
  /** ISO weekdays 1..7. */
  quotaPreferredDays: number[];
  endsOn: Day | null;
  endsAfterCount: number | null;
  seriesId: string;
  timeZone: string | null;
  /** Epoch milliseconds. */
  createdAt: number;
  updatedAt: number;
  deletedAt: number | null;
  reminders: TaskReminder[];
}

export type RecordStatus = 'none' | 'done' | 'skipped' | 'deleted';

/** Stored per-occurrence state; only occurrences that differ have one. */
export interface OccurrenceRecord {
  id: string;
  taskId: string;
  /** Original generated date — the key. */
  occurrenceDate: Day;
  status: RecordStatus;
  completedAt: number | null;
  overrideDate: Day | null;
  overrideStartMinute: number | null;
  overrideTitle: string | null;
  /** Back-filled completion. */
  late: boolean;
}

export type OccurrenceStatus = 'pending' | 'done' | 'skipped' | 'missed';

export interface Occurrence {
  task: Task;
  originalDate: Day;
  /** Display date (override or original). */
  date: Day;
  title: string;
  status: OccurrenceStatus;
  startMinute: number | null;
  completedAt: number | null;
  late: boolean;
  record: OccurrenceRecord | null;
}

export interface TaskSnapshot {
  tasks: Task[];
  records: OccurrenceRecord[];
}

export const emptySnapshot: TaskSnapshot = { tasks: [], records: [] };

export const isRecurring = (t: Task) => t.repeatKind !== 'none';
export const isQuota = (t: Task) => t.repeatKind === 'quota';

export const Occ = {
  key: (o: Occurrence) => `${o.task.id}|${o.originalDate}`,
  isDone: (o: Occurrence) => o.status === 'done',
  isTimed: (o: Occurrence) => !o.task.allDay && o.startMinute != null,
  duration: (o: Occurrence) => o.task.durationMin ?? 30,
  endMinute: (o: Occurrence) => (Occ.isTimed(o) ? o.startMinute! + Occ.duration(o) : null),
  startAt: (o: Occurrence) => (Occ.isTimed(o) ? Days.at(o.date, o.startMinute!) : null),
  endAt: (o: Occurrence) => (Occ.isTimed(o) ? Days.at(o.date, Occ.endMinute(o)!) : null),
  /** Completed on its day and, for timed tasks, before start + duration. */
  onTime(o: Occurrence): boolean {
    if (o.status !== 'done' || o.completedAt == null || o.late) return false;
    const c = new Date(o.completedAt);
    if (Days.of(c) !== o.date) return false;
    const end = Occ.endAt(o);
    return end == null || c.getTime() <= end.getTime();
  },
};

export const Reminders = {
  fireAt(r: TaskReminder, day: Day, startMinute: number | null): Date | null {
    if (r.atMinute != null) return Days.at(Days.add(day, Math.floor(r.offsetMin / 1440)), r.atMinute);
    if (startMinute == null) return null;
    return new Date(Days.at(day, startMinute).getTime() + r.offsetMin * 60000);
  },

  label(r: TaskReminder, time: (minute: number) => string): string {
    if (r.atMinute != null) {
      const before = -Math.floor(r.offsetMin / 1440);
      if (before === 0) return `On the day at ${time(r.atMinute)}`;
      if (before === 1) return `Day before at ${time(r.atMinute)}`;
      return `${before} days before at ${time(r.atMinute)}`;
    }
    const m = -r.offsetMin;
    if (m === 0) return 'At start time';
    if (m < 0) return `${-m} min after`;
    if (m % 1440 === 0) return `${m / 1440} day${m === 1440 ? '' : 's'} before`;
    if (m % 60 === 0) return `${m / 60} hour${m === 60 ? '' : 's'} before`;
    return `${m} min before`;
  },

  same: (a: TaskReminder, b: TaskReminder) => a.offsetMin === b.offsetMin && a.atMinute === b.atMinute,
};

export const newId = () => crypto.randomUUID();
