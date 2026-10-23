import { db } from '../../../core/db/store';
import { generatorFor, getSettings, getSnapshot } from '../../../core/hooks';
import { Days, type Day } from '../../../core/time/days';
import { isRecurring, newId, Reminders, type Occurrence, type OccurrenceRecord, type Task } from '../domain/models';
import { detachOccurrence, splitSeries, type EditScope } from '../domain/seriesEdits';

/** All task mutations, with Google Calendar scope semantics (port of the app's TasksRepository). */

const now = () => Date.now();
const gen = () => generatorFor(getSettings().mondayFirst);

function recordFor(o: Occurrence): OccurrenceRecord {
  return (
    o.record ??
    db().occurrenceRecords.find((r) => r.taskId === o.task.id && r.occurrenceDate === o.originalDate) ?? {
      id: newId(),
      taskId: o.task.id,
      occurrenceDate: o.originalDate,
      status: 'none',
      completedAt: null,
      overrideDate: null,
      overrideStartMinute: null,
      overrideTitle: null,
      late: false,
    }
  );
}

function clearStatus(rec: OccurrenceRecord) {
  const hasOverride = rec.overrideDate != null || rec.overrideStartMinute != null || rec.overrideTitle != null;
  if (hasOverride) db().upsertRecord({ ...rec, status: 'none', completedAt: null, late: false });
  else db().deleteRecord(rec.taskId, rec.occurrenceDate);
}

const freshReminders = (t: Task) => t.reminders.map((r) => ({ ...r, id: newId() }));

export const TasksRepository = {
  create(t: Task) {
    db().upsertTask(t);
  },

  tags(): string[] {
    const s = new Set<string>();
    for (const t of getSnapshot().tasks) if (t.tag?.trim()) s.add(t.tag.trim());
    return [...s].sort();
  },

  /** Done/undo. Completing after the day counts as a late back-fill. */
  setDone(o: Occurrence, done: boolean) {
    const rec = recordFor(o);
    if (!done) return clearStatus(rec);
    db().upsertRecord({ ...rec, status: 'done', completedAt: now(), late: o.date < Days.of(new Date()) });
  },

  setSkipped(o: Occurrence, skipped: boolean) {
    const rec = recordFor(o);
    if (!skipped) return clearStatus(rec);
    db().upsertRecord({ ...rec, status: 'skipped', completedAt: null, late: false });
  },

  /** Saves the editor result; `edited.startDate` is the date picked for `occ`. */
  save(edited: Task, occ?: Occurrence, scope: EditScope = 'all'): void {
    const t = now();
    const original = occ?.task;
    if (!original || !isRecurring(original)) return db().upsertTask({ ...edited, updatedAt: t });
    if (scope === 'all') {
      const shift = Days.between(occ!.originalDate, edited.startDate);
      return db().upsertTask({ ...edited, id: original.id, startDate: Days.add(original.startDate, shift), updatedAt: t });
    }
    if (scope === 'thisOne') return saveThisOne(edited, occ!, t);
    if (occ!.originalDate === original.startDate) return TasksRepository.save(edited, occ, 'all');
    const split = splitSeries({ original, at: occ!.originalDate, edited, newId: newId(), now: t, generator: gen() });
    const following = { ...split.following, startDate: edited.startDate, reminders: freshReminders(edited) };
    db().upsertTask(split.ended);
    db().upsertTask(following);
    db().reassignRecords(original.id, following.id, occ!.originalDate);
  },

  /** Drag on the rail. */
  reschedule(o: Occurrence, date: Day, startMinute: number | null, scope: EditScope = 'thisOne') {
    const t = o.task;
    const edited: Task = { ...t, startDate: date, startMinute };
    if (!isRecurring(t)) return db().upsertTask({ ...edited, updatedAt: now() });
    if (scope === 'thisOne') {
      const rec = recordFor(o);
      return db().upsertRecord({
        ...rec,
        overrideDate: date === o.originalDate ? null : date,
        overrideStartMinute: startMinute === t.startMinute ? null : startMinute,
      });
    }
    TasksRepository.save(edited, o, scope);
  },

  /**
   * Google Calendar delete: a one-off or "All tasks" goes to Trash; "This task"
   * removes one occurrence; "This and following" ends the series the day
   * before. Returns an undo for the snackbar.
   */
  delete(o: Occurrence, scope: EditScope = 'all'): () => void {
    const t = o.task;
    if (!isRecurring(t) || scope === 'all' || (scope === 'thisAndFollowing' && o.originalDate === t.startDate)) {
      db().softDeleteTask(t.id, now());
      return () => db().restoreTask(t.id, now());
    }
    if (scope === 'thisOne') {
      const previous = o.record ?? db().occurrenceRecords.find((r) => r.taskId === t.id && r.occurrenceDate === o.originalDate) ?? null;
      db().upsertRecord({ ...recordFor(o), status: 'deleted', completedAt: null });
      return () => (previous ? db().upsertRecord(previous) : db().deleteRecord(t.id, o.originalDate));
    }
    db().upsertTask({ ...t, endsOn: Days.add(o.originalDate, -1), endsAfterCount: null, updatedAt: now() });
    return () => db().upsertTask({ ...t, updatedAt: now() });
  },

  // --- Trash (Google Calendar keeps deleted events for 30 days) ---------------

  trashDays: 30,

  restore: (taskId: string) => db().restoreTask(taskId, now()),

  deleteForever: (taskId: string) => db().hardDeleteTasks([taskId]),

  emptyTrash: () => db().hardDeleteTasks(db().tasks.filter((t) => t.deletedAt != null).map((t) => t.id)),

  /** Drops trash older than `trashDays`; run at launch. */
  purgeOldTrash(at = now()) {
    const before = at - TasksRepository.trashDays * 86_400_000;
    const old = db().tasks.filter((t) => t.deletedAt != null && t.deletedAt < before).map((t) => t.id);
    if (old.length) db().hardDeleteTasks(old);
  },
};

function saveThisOne(edited: Task, occ: Occurrence, t: number) {
  const o = occ.task;
  const sameReminders =
    edited.reminders.length === o.reminders.length && edited.reminders.every((r, i) => Reminders.same(r, o.reminders[i]));
  const onlyOverridable =
    edited.color === o.color && edited.tag === o.tag && edited.notes === o.notes && edited.priority === o.priority &&
    edited.allDay === o.allDay && edited.durationMin === o.durationMin && sameReminders &&
    edited.repeatKind === o.repeatKind && edited.rrule === o.rrule;
  const rec = recordFor(occ);
  if (onlyOverridable) {
    db().upsertRecord({
      ...rec,
      overrideTitle: edited.title === o.title ? null : edited.title,
      overrideDate: edited.startDate === occ.originalDate ? null : edited.startDate,
      overrideStartMinute: edited.startMinute === o.startMinute ? null : edited.startMinute,
    });
    return;
  }
  const detached = detachOccurrence({ ...edited, reminders: freshReminders(edited) }, edited.startDate, newId(), t);
  db().upsertTask(detached);
  if (rec.status === 'done' || rec.status === 'skipped') {
    db().upsertRecord({ ...rec, id: newId(), taskId: detached.id, occurrenceDate: detached.startDate, overrideDate: null, overrideStartMinute: null, overrideTitle: null });
  }
  db().upsertRecord({ ...rec, status: 'deleted', completedAt: null });
}
