// Cross-device sync contract: the shared sample (also used by the mobile
// app's test/features/settings/export_format_test.dart) must import and
// re-export unchanged, and read back as the same tasks.
import { readFileSync } from 'node:fs';
import { beforeEach, describe, expect, test } from 'vitest';
import { db } from '../../core/db/store';
import { generatorFor, selectSettings, selectSnapshot } from '../../core/hooks';
import { Range } from '../../core/time/days';
import { Rules } from '../tasks/domain/recurrence';
import { exportJson, importJson } from './dataTransfer';

const samplePath = new URL('../../../../../shared/export-format/sample-v1.json', import.meta.url);
const sample = JSON.parse(readFileSync(samplePath, 'utf8')) as Record<string, unknown>;
const TABLES = ['tasks', 'taskReminders', 'occurrenceRecords', 'focusSessions', 'presets', 'settings'] as const;

describe('export format v1 (shared with the mobile app)', () => {
  beforeEach(() => db().wipe());

  test('import → export round-trips every table unchanged', () => {
    importJson(JSON.stringify(sample));
    const out = JSON.parse(exportJson()) as Record<string, unknown>;
    expect(out.app).toBe('Poora');
    expect(out.format).toBe(1);
    for (const t of TABLES) expect(out[t], t).toEqual(sample[t]);
    // Exactly the same top-level keys as the app writes.
    expect(Object.keys(out).sort()).toEqual(Object.keys(sample).sort());
  });

  test('imported rows read back as the same tasks, rules and settings', () => {
    importJson(JSON.stringify(sample));
    const snap = selectSnapshot(db());
    expect(snap.tasks.map((t) => t.title)).toEqual(['Morning pages', 'Gym', 'Run', 'File taxes']); // deleted one hidden
    const gym = snap.tasks.find((t) => t.title === 'Gym')!;
    expect(Rules.summary(Rules.fromTask(gym), gym.startDate)).toBe('Every 2 weeks on Mon, Wed, Fri, until Dec 31, 2026');
    const run = snap.tasks.find((t) => t.title === 'Run')!;
    expect(run.quotaPreferredDays).toEqual([2, 4, 6]);
    expect(run.reminders).toEqual([{ id: 'rem-0003', offsetMin: 0, atMinute: 420 }]);
    const s = selectSettings(db());
    expect([s.name, s.chime, s.lastFocus.longEvery, s.onboarded]).toEqual(['Asha', 'softBell', 2, true]);
    expect(s.distractingApps).toEqual(['com.instagram.android', 'com.google.android.youtube']);

    const occ = generatorFor(true).generate(snap, Range.of('2026-10-12', '2026-10-16'), '2026-10-16');
    const gymMoved = occ.find((o) => o.task.title === 'Gym' && o.originalDate === '2026-10-14')!;
    expect([gymMoved.date, gymMoved.startMinute, gymMoved.title]).toEqual(['2026-10-15', 1140, 'Gym (late slot)']);
    expect(occ.some((o) => o.task.title === 'Morning pages' && o.date === '2026-10-14')).toBe(false); // deleted occurrence
  });

  test('older exports without focus-tracking fields still import', () => {
    const old = structuredClone(sample) as { focusSessions: Record<string, unknown>[] };
    for (const r of old.focusSessions) for (const k of ['pausedMs', 'awayMs', 'interruptions', 'distractions']) delete r[k];
    importJson(JSON.stringify(old));
    const f = db().focusSessions[0];
    expect([f.pausedMs, f.awayMs, f.interruptions, f.distractions]).toEqual([0, 0, 0, null]);
  });

  test('tasks on the old palette import with today’s shades', () => {
    const old = structuredClone(sample) as { tasks: { id: string; color: number }[] };
    old.tasks[0].color = 0xfff2705e; // coral before the shade shift
    importJson(JSON.stringify(old));
    expect(db().tasks.find((t) => t.id === old.tasks[0].id)!.color).toBe(0xffef7867);
  });

  test('rejects files that are not exports, changing nothing', () => {
    importJson(JSON.stringify(sample));
    expect(() => importJson('{nope')).toThrow('valid JSON');
    expect(() => importJson(JSON.stringify({ format: 2 }))).toThrow('export');
    expect(db().tasks.length).toBe(5);
  });
});
