import { AppInfo } from '../../core/appInfo';
import { db, emptyTables, focusSessionDefaults, type FocusSessionRow, type Tables, type TaskRow } from '../../core/db/store';
import { TaskColors } from '../../core/theme/tokens';

/** Same JSON format as the app's DataTransfer (format 1) — files move between phone and web. */
const FORMAT = 1;

export function exportJson(): string {
  const s = db();
  return JSON.stringify(
    {
      app: AppInfo.name,
      format: FORMAT,
      exportedAt: new Date().toISOString(),
      tasks: s.tasks,
      taskReminders: s.taskReminders,
      occurrenceRecords: s.occurrenceRecords,
      focusSessions: s.focusSessions,
      presets: s.presets,
      settings: Object.entries(s.settings).map(([key, value]) => ({ key, value })),
    },
    null,
    2,
  );
}

export function downloadExport() {
  const blob = new Blob([exportJson()], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `${AppInfo.name.toLowerCase()}-export-${new Date().toISOString().slice(0, 10)}.json`;
  a.click();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}

/** Replaces all data. Throws Error with a user-facing message on bad input; nothing changes then. */
export function importJson(text: string) {
  let data: unknown;
  try {
    data = JSON.parse(text);
  } catch {
    throw new Error('This file isn’t valid JSON.');
  }
  if (typeof data !== 'object' || data == null || (data as { format?: unknown }).format !== FORMAT) {
    throw new Error(`This doesn’t look like a ${AppInfo.name} export.`);
  }
  const d = data as Record<string, unknown>;
  const list = <T,>(k: string) => (Array.isArray(d[k]) ? (d[k] as T[]) : []);
  const settings: Record<string, string> = {};
  for (const e of list<{ key: string; value: string }>('settings')) if (typeof e?.key === 'string') settings[e.key] = String(e.value);
  const tables: Tables = {
    ...emptyTables,
    // Older files may use the palette before its shade shift.
    tasks: list<TaskRow>('tasks').map((t) => ({ ...t, color: TaskColors.migrate(t.color) })),
    taskReminders: list('taskReminders'),
    occurrenceRecords: list('occurrenceRecords'),
    // Focus-tracking fields were added to format 1 later; older files lack them.
    focusSessions: list<FocusSessionRow>('focusSessions').map((f) => ({ ...focusSessionDefaults, ...f })),
    presets: list('presets'),
    settings,
  };
  db().replaceAll(tables);
}
