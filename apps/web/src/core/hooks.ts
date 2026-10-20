import { useEffect, useMemo, useState, useSyncExternalStore } from 'react';
import { create } from 'zustand';
import { db, taskFromRow, useDb, type Db } from './db/store';
import { Days, Range, type DateRange, type Day } from './time/days';
import { settingsFromMap, settingsToMap, type AppSettings } from '../features/settings/appSettings';
import type { TaskReminder, TaskSnapshot } from '../features/tasks/domain/models';
import { OccurrenceGenerator } from '../features/tasks/domain/occurrenceGenerator';

// --- Settings -----------------------------------------------------------------

let settingsCache: { map: Record<string, string>; value: AppSettings } | null = null;
export function selectSettings(s: Pick<Db, 'settings'>): AppSettings {
  if (settingsCache?.map !== s.settings) settingsCache = { map: s.settings, value: settingsFromMap(s.settings) };
  return settingsCache.value;
}
export const useSettings = () => useDb(selectSettings);
export const getSettings = () => selectSettings(db());
export function updateSettings(change: (s: AppSettings) => AppSettings) {
  db().setSettings(settingsToMap(change(getSettings())));
}

// --- Snapshot ---------------------------------------------------------------------

let snapCache: { key: unknown[]; value: TaskSnapshot } | null = null;
export function selectSnapshot(s: Pick<Db, 'tasks' | 'taskReminders' | 'occurrenceRecords'>): TaskSnapshot {
  const key = [s.tasks, s.taskReminders, s.occurrenceRecords];
  if (snapCache && snapCache.key.every((k, i) => k === key[i])) return snapCache.value;
  const byTask = new Map<string, TaskReminder[]>();
  for (const r of s.taskReminders) {
    const l = byTask.get(r.taskId) ?? [];
    l.push({ id: r.id, offsetMin: r.offsetMin, atMinute: r.atMinute });
    byTask.set(r.taskId, l);
  }
  const value: TaskSnapshot = {
    tasks: s.tasks.filter((t) => t.deletedAt == null).map((t) => taskFromRow(t, byTask.get(t.id) ?? [])),
    records: s.occurrenceRecords,
  };
  snapCache = { key, value };
  return value;
}
export const useSnapshot = () => useDb(selectSnapshot);
export const getSnapshot = () => selectSnapshot(db());

let genCache: OccurrenceGenerator | null = null;
export function generatorFor(mondayFirst: boolean) {
  if (genCache?.mondayFirst !== mondayFirst) genCache = new OccurrenceGenerator(mondayFirst);
  return genCache;
}
export const useGenerator = () => generatorFor(useSettings().mondayFirst);

// --- Today / now --------------------------------------------------------------------

const useTodayStore = create<{ today: Day }>(() => ({ today: Days.of(new Date()) }));
function refreshToday() {
  const d = Days.of(new Date());
  if (d !== useTodayStore.getState().today) useTodayStore.setState({ today: d });
}
if (typeof window !== 'undefined') {
  setInterval(refreshToday, 30_000);
  document.addEventListener('visibilitychange', refreshToday);
}
export const useToday = () => useTodayStore((s) => s.today);
export const getToday = () => useTodayStore.getState().today;

/** Current time, refreshed every `ms`. */
export function useNow(ms = 30_000): Date {
  const [now, setNow] = useState(() => new Date());
  useEffect(() => {
    const id = setInterval(() => setNow(new Date()), ms);
    return () => clearInterval(id);
  }, [ms]);
  return now;
}

// --- Occurrences ------------------------------------------------------------------

/** Occurrences for a visible range, regenerated when data, today or week start change. */
export function useOccurrences(range: DateRange) {
  const snapshot = useSnapshot();
  const today = useToday();
  const gen = useGenerator();
  const key = Range.key(range);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  return useMemo(() => gen.generate(snapshot, range, today), [snapshot, today, gen, key]);
}

export const occurrencesNow = (range: DateRange) =>
  generatorFor(getSettings().mondayFirst).generate(getSnapshot(), range, getToday());

// --- Media queries ------------------------------------------------------------------

export function useMediaQuery(query: string): boolean {
  return useSyncExternalStore(
    (cb) => {
      const m = window.matchMedia(query);
      m.addEventListener('change', cb);
      return () => m.removeEventListener('change', cb);
    },
    () => window.matchMedia(query).matches,
  );
}

export const useReducedMotion = () => useMediaQuery('(prefers-reduced-motion: reduce)');
export const useDesktop = () => useMediaQuery('(min-width: 960px)');
