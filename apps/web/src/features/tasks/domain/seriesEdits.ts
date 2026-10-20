import { Days, type Day } from '../../../core/time/days';
import type { Task } from './models';
import type { OccurrenceGenerator } from './occurrenceGenerator';

/** Google Calendar edit semantics for recurring tasks. */
export type EditScope = 'thisOne' | 'thisAndFollowing' | 'all';

export interface SeriesSplit {
  ended: Task;
  following: Task;
}

/** "This and following": end the original the day before `at`, start `edited` on `at`. */
export function splitSeries(args: {
  original: Task;
  at: Day;
  edited: Task;
  newId: string;
  now: number;
  generator: OccurrenceGenerator;
}): SeriesSplit {
  const { original, at, edited, newId, now, generator } = args;
  const before = Days.add(at, -1);
  let remaining: number | null = null;
  const count = original.endsAfterCount;
  if (count != null) {
    const used = generator.datesFor(original, original.startDate, before).length;
    remaining = Math.min(Math.max(count - used, 1), count);
  }
  const ended: Task = { ...original, endsOn: before, endsAfterCount: null, updatedAt: now };
  const keepCount = edited.endsAfterCount === original.endsAfterCount;
  const following: Task = {
    ...edited,
    id: newId,
    startDate: at,
    seriesId: original.seriesId,
    endsAfterCount: keepCount ? remaining : edited.endsAfterCount,
    createdAt: now,
    updatedAt: now,
  };
  return { ended, following };
}

/** "This task" on a field a record can't override: a one-off in the same series. */
export function detachOccurrence(edited: Task, date: Day, newId: string, now: number): Task {
  return {
    ...edited,
    id: newId,
    startDate: date,
    repeatKind: 'none',
    rrule: null,
    quotaPerWeek: null,
    quotaPreferredDays: [],
    endsOn: null,
    endsAfterCount: null,
    createdAt: now,
    updatedAt: now,
  };
}
