// Parity with test/features/tasks/delete_trash_test.dart — Google Calendar
// delete scopes, undo, and the 30-day Trash.
import { beforeEach, describe, expect, test } from 'vitest';
import { db } from '../../../core/db/store';
import { generatorFor, selectSnapshot, selectTrashed } from '../../../core/hooks';
import { Days, Range } from '../../../core/time/days';
import type { Task } from '../domain/models';
import { Rules, type RepeatRule } from '../domain/recurrence';
import { TasksRepository } from './tasksRepository';

const start = '2026-10-19';
const today = '2026-10-21';
const created = new Date(2026, 9, 19).getTime();

const task = (id: string, rule: RepeatRule): Task =>
  Rules.applyTo(rule, {
    id, title: id, notes: null, color: 0xffef7867, tag: null, priority: 0, allDay: false, startDate: start,
    startMinute: 540, durationMin: 30, repeatKind: 'none', rrule: null, quotaPerWeek: null, quotaPreferredDays: [],
    endsOn: null, endsAfterCount: null, seriesId: id, timeZone: null, createdAt: created, updatedAt: created, deletedAt: null, reminders: [],
  });

const occ = () => generatorFor(true).generate(selectSnapshot(db()), Range.of(start, Days.add(start, 6)), today);
const at = (id: string, d: string) => occ().find((o) => o.task.id === id && o.originalDate === d)!;

describe('delete and Trash', () => {
  beforeEach(() => db().wipe());

  test('one-off: delete moves to Trash; undo restores', () => {
    TasksRepository.create(task('a', Rules.none));
    const undo = TasksRepository.delete(at('a', start));
    expect(occ()).toEqual([]);
    expect(selectTrashed(db()).map((t) => t.id)).toEqual(['a']);
    undo();
    expect(occ().map((o) => o.task.id)).toEqual(['a']);
    expect(selectTrashed(db())).toEqual([]);
  });

  test('recurring "This task" removes one occurrence; undo brings it back', () => {
    TasksRepository.create(task('d', Rules.daily()));
    const undo = TasksRepository.delete(at('d', Days.add(start, 2)), 'thisOne');
    expect(occ().map((o) => o.date)).not.toContain(Days.add(start, 2));
    expect(occ().length).toBe(6);
    undo();
    expect(occ().length).toBe(7);
  });

  test('"This task" undo keeps a completion that existed before', () => {
    TasksRepository.create(task('d', Rules.daily()));
    TasksRepository.setDone(at('d', start), true);
    const undo = TasksRepository.delete(at('d', start), 'thisOne');
    undo();
    expect(at('d', start).status).toBe('done');
  });

  test('"This and following" ends the series; undo restores it', () => {
    TasksRepository.create(task('d', Rules.daily()));
    const undo = TasksRepository.delete(at('d', Days.add(start, 3)), 'thisAndFollowing');
    expect(occ().length).toBe(3);
    undo();
    expect(occ().length).toBe(7);
  });

  test('"All tasks" trashes the whole series', () => {
    TasksRepository.create(task('d', Rules.daily()));
    TasksRepository.delete(at('d', Days.add(start, 3)), 'all');
    expect(occ()).toEqual([]);
  });

  test('Trash: restore, delete forever and 30-day purge', () => {
    TasksRepository.create(task('a', Rules.none));
    TasksRepository.create(task('b', Rules.none));
    TasksRepository.delete(at('a', start));
    TasksRepository.delete(at('b', start));
    TasksRepository.restore('a');
    expect(occ().map((o) => o.task.id)).toEqual(['a']);
    TasksRepository.deleteForever('b');
    expect(selectTrashed(db())).toEqual([]);
    expect(db().tasks.map((t) => t.id)).toEqual(['a']);

    TasksRepository.delete(at('a', start));
    const deletedAt = db().tasks[0].deletedAt!;
    TasksRepository.purgeOldTrash(deletedAt + 29 * 86_400_000);
    expect(selectTrashed(db()).length).toBe(1);
    TasksRepository.purgeOldTrash(deletedAt + 31 * 86_400_000);
    expect(selectTrashed(db())).toEqual([]);
  });
});
