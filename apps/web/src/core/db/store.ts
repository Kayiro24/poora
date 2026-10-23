import { create } from 'zustand';
import { createJSONStorage, persist } from 'zustand/middleware';
import { TaskColors } from '../theme/tokens';
import type { Day } from '../time/days';
import type { FocusPhase } from '../../features/focus/domain/timerEngine';
import type { OccurrenceRecord, Task, TaskReminder } from '../../features/tasks/domain/models';

/*
 * The web app's "database": the same tables and row shapes as the mobile
 * app's Drift schema (apps/mobile/lib/core/db/tables.dart), persisted to
 * localStorage. Export/import uses the app's exact JSON, so data moves
 * between phone and browser.
 */

export interface TaskRow {
  id: string;
  title: string;
  notes: string | null;
  color: number;
  tag: string | null;
  priority: number;
  allDay: boolean;
  startDate: Day;
  startMinute: number | null;
  durationMin: number | null;
  repeatKind: string;
  rrule: string | null;
  quotaPerWeek: number | null;
  quotaPreferredDays: string | null;
  endsOn: Day | null;
  endsAfterCount: number | null;
  seriesId: string;
  timeZone: string | null;
  createdAt: number;
  updatedAt: number;
  deletedAt: number | null;
}

export interface TaskReminderRow extends TaskReminder {
  taskId: string;
}

export interface FocusSessionRow {
  id: string;
  startedAt: number;
  endedAt: number | null;
  plannedFocusMin: number;
  shortBreakMin: number;
  longBreakMin: number;
  longEvery: number;
  focusMsCompleted: number;
  phasesCompleted: number;
  endedEarly: boolean;
  linkedTaskId: string | null;
  linkedOccurrenceDate: Day | null;
  /** Time the user had the timer paused. */
  pausedMs: number;
  /** Time spent outside the app while a focus phase ran. */
  awayMs: number;
  /** Times the user left during focus. */
  interruptions: number;
  /** JSON `{package: ms}` of distracting apps (Android only; null on web). */
  distractions: string | null;
}

/** Older exports and saved sessions lack the focus-tracking fields. */
export const focusSessionDefaults = { pausedMs: 0, awayMs: 0, interruptions: 0, distractions: null } as const;

export interface FocusStateRow {
  id: 1;
  sessionId: string;
  phase: FocusPhase;
  focusIndex: number;
  phaseStartedAt: number | null;
  phaseDurationMs: number;
  pausedAt: number | null;
  pausedAccumMs: number;
  focusMsCompleted: number;
  phasesCompleted: number;
  // Focus tracking (absent in states saved before it existed).
  pausedTotalMs?: number;
  interruptions?: number;
  awayMs?: number;
  awayStartedAt?: number | null;
  awayCapAt?: number | null;
  lastSeenAt?: number | null;
  /** Strict mode: the focus phase can't be paused, skipped or ended. */
  strict?: boolean;
}

export interface PresetRow {
  id: string;
  name: string;
  focusMin: number;
  shortMin: number;
  longMin: number;
  longEvery: number;
  sort: number;
}

export interface Tables {
  tasks: TaskRow[];
  taskReminders: TaskReminderRow[];
  occurrenceRecords: OccurrenceRecord[];
  focusSessions: FocusSessionRow[];
  focusState: FocusStateRow | null;
  presets: PresetRow[];
  settings: Record<string, string>;
}

export const emptyTables: Tables = {
  tasks: [],
  taskReminders: [],
  occurrenceRecords: [],
  focusSessions: [],
  focusState: null,
  presets: [],
  settings: {},
};

interface DbActions {
  upsertTask(t: Task): void;
  softDeleteTask(id: string, now: number): void;
  restoreTask(id: string, now: number): void;
  /** Deletes tasks for good, with their reminders and records. */
  hardDeleteTasks(ids: string[]): void;
  upsertRecord(r: OccurrenceRecord): void;
  deleteRecord(taskId: string, date: Day): void;
  reassignRecords(fromTask: string, toTask: string, fromDate: Day): void;
  upsertSession(s: FocusSessionRow): void;
  setFocusState(s: FocusStateRow | null): void;
  upsertPreset(p: PresetRow): void;
  deletePreset(id: string): void;
  setSettings(entries: Record<string, string>): void;
  replaceAll(t: Tables): void;
  wipe(): void;
}

export type Db = Tables & DbActions;

export function taskToRow(t: Task): TaskRow {
  return {
    id: t.id,
    title: t.title,
    notes: t.notes,
    color: t.color,
    tag: t.tag,
    priority: t.priority,
    allDay: t.allDay,
    startDate: t.startDate,
    startMinute: t.startMinute,
    durationMin: t.durationMin,
    repeatKind: t.repeatKind,
    rrule: t.rrule,
    quotaPerWeek: t.quotaPerWeek,
    quotaPreferredDays: t.quotaPreferredDays.length ? t.quotaPreferredDays.join(',') : null,
    endsOn: t.endsOn,
    endsAfterCount: t.endsAfterCount,
    seriesId: t.seriesId,
    timeZone: t.timeZone,
    createdAt: t.createdAt,
    updatedAt: t.updatedAt,
    deletedAt: t.deletedAt,
  };
}

export function taskFromRow(r: TaskRow, reminders: TaskReminder[]): Task {
  return {
    ...r,
    priority: Math.min(Math.max(r.priority, 0), 2) as Task['priority'],
    repeatKind: r.repeatKind === 'rrule' || r.repeatKind === 'quota' ? r.repeatKind : 'none',
    quotaPreferredDays: (r.quotaPreferredDays ?? '').split(',').map(Number).filter((n) => n >= 1 && n <= 7),
    reminders,
  };
}

const sameRecord = (a: OccurrenceRecord, taskId: string, date: Day) => a.taskId === taskId && a.occurrenceDate === date;

export const useDb = create<Db>()(
  persist(
    (set) => ({
      ...emptyTables,

      upsertTask: (t) =>
        set((s) => {
          const row = taskToRow(t);
          const tasks = s.tasks.some((x) => x.id === t.id) ? s.tasks.map((x) => (x.id === t.id ? row : x)) : [...s.tasks, row];
          const taskReminders = [
            ...s.taskReminders.filter((r) => r.taskId !== t.id),
            ...t.reminders.map((r) => ({ ...r, taskId: t.id })),
          ];
          return { tasks, taskReminders };
        }),

      softDeleteTask: (id, now) =>
        set((s) => ({ tasks: s.tasks.map((t) => (t.id === id ? { ...t, deletedAt: now, updatedAt: now } : t)) })),

      restoreTask: (id, now) =>
        set((s) => ({ tasks: s.tasks.map((t) => (t.id === id ? { ...t, deletedAt: null, updatedAt: now } : t)) })),

      hardDeleteTasks: (ids) =>
        set((s) => {
          const gone = new Set(ids);
          return {
            tasks: s.tasks.filter((t) => !gone.has(t.id)),
            taskReminders: s.taskReminders.filter((r) => !gone.has(r.taskId)),
            occurrenceRecords: s.occurrenceRecords.filter((r) => !gone.has(r.taskId)),
          };
        }),

      upsertRecord: (r) =>
        set((s) => {
          const exists = s.occurrenceRecords.some((x) => sameRecord(x, r.taskId, r.occurrenceDate));
          return {
            occurrenceRecords: exists
              ? s.occurrenceRecords.map((x) => (sameRecord(x, r.taskId, r.occurrenceDate) ? { ...r, id: x.id } : x))
              : [...s.occurrenceRecords, r],
          };
        }),

      deleteRecord: (taskId, date) =>
        set((s) => ({ occurrenceRecords: s.occurrenceRecords.filter((x) => !sameRecord(x, taskId, date)) })),

      reassignRecords: (fromTask, toTask, fromDate) =>
        set((s) => ({
          occurrenceRecords: s.occurrenceRecords.map((x) =>
            x.taskId === fromTask && x.occurrenceDate >= fromDate ? { ...x, taskId: toTask } : x,
          ),
        })),

      upsertSession: (row) =>
        set((s) => ({
          focusSessions: s.focusSessions.some((x) => x.id === row.id)
            ? s.focusSessions.map((x) => (x.id === row.id ? row : x))
            : [...s.focusSessions, row],
        })),

      setFocusState: (focusState) => set({ focusState }),

      upsertPreset: (p) =>
        set((s) => ({
          presets: s.presets.some((x) => x.id === p.id) ? s.presets.map((x) => (x.id === p.id ? p : x)) : [...s.presets, p],
        })),

      deletePreset: (id) => set((s) => ({ presets: s.presets.filter((p) => p.id !== id) })),

      setSettings: (entries) => set((s) => ({ settings: { ...s.settings, ...entries } })),

      replaceAll: (t) => set({ ...emptyTables, ...t }),

      wipe: () => set({ ...emptyTables }),
    }),
    {
      name: 'poora:db',
      version: 3,
      // v2: focus sessions gained tracking fields. v3: palette shade shift.
      migrate: (state) => {
        const s = state as Partial<Tables>;
        return {
          ...s,
          focusSessions: (s.focusSessions ?? []).map((f) => ({ ...focusSessionDefaults, ...f })),
          tasks: (s.tasks ?? []).map((t) => ({ ...t, color: TaskColors.migrate(t.color) })),
        } as Db;
      },
      storage: createJSONStorage(() => localStorage),
      partialize: (s) => ({
        tasks: s.tasks,
        taskReminders: s.taskReminders,
        occurrenceRecords: s.occurrenceRecords,
        focusSessions: s.focusSessions,
        focusState: s.focusState,
        presets: s.presets,
        settings: s.settings,
      }),
    },
  ),
);

/** Non-hook access for repositories and controllers. */
export const db = () => useDb.getState();
