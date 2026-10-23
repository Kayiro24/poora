import { useDb } from '../db/store';
import { generatorFor, getSettings, getSnapshot } from '../hooks';
import { Days, Range } from '../time/days';
import { Fmt } from '../time/format';
import { isQuota, Occ, Reminders } from '../../features/tasks/domain/models';
import { Feedback } from './feedback';
import { Notify } from './notifications';

/*
 * Web reminder scheduler — the same plan as the app's ReminderPlanner, but
 * delivered with in-page timers (browsers can't schedule while closed).
 * Reminders that come due during a focus session are held and delivered
 * together when it ends (§4.4).
 */

interface Planned {
  id: string;
  fireAt: number;
  title: string;
  body: string;
}

const WINDOW_DAYS = 2;
const timers = new Map<string, number>();
const held: Planned[] = [];
let holdUntil: number | null = null;

function plan(): Planned[] {
  const now = Date.now();
  const today = Days.of(new Date());
  const horizon = now + WINDOW_DAYS * 86_400_000;
  const settings = getSettings();
  const occ = generatorFor(settings.mondayFirst).generate(getSnapshot(), Range.of(Days.add(today, -1), Days.add(today, WINDOW_DAYS)), today);
  const out: Planned[] = [];
  for (const o of occ) {
    if (o.status !== 'pending' || !o.task.reminders.length) continue;
    const t = o.task;
    if (isQuota(t) && t.quotaPreferredDays.length && !t.quotaPreferredDays.includes(Days.weekday(o.date))) continue;
    const body = [Occ.isTimed(o) ? Fmt.minute(o.startMinute!, settings.use24h) : 'All day', t.tag?.trim()].filter(Boolean).join(' · ');
    for (const r of t.reminders) {
      const fire = Reminders.fireAt(r, o.date, o.startMinute)?.getTime();
      if (fire == null || fire <= now || fire > horizon) continue;
      out.push({ id: `${t.id}|${o.originalDate}|${r.id}`, fireAt: fire, title: o.title, body });
    }
  }
  return out;
}

function fire(p: Planned) {
  timers.delete(p.id);
  if (holdUntil != null && p.fireAt <= holdUntil) {
    held.push(p);
    return;
  }
  Feedback.reminderTone();
  void Notify.show(p.title, p.body, p.id);
}

export const ReminderScheduler = {
  reschedule() {
    for (const id of timers.values()) clearTimeout(id);
    timers.clear();
    if (Notify.permission() !== 'granted') return;
    for (const p of plan()) timers.set(p.id, window.setTimeout(() => fire(p), p.fireAt - Date.now()));
  },

  /** Hold everything due before `until` (the projected end of the focus cycle). */
  hold(until: number) {
    holdUntil = until;
  },

  heldCount: () => held.length,

  /** Ends holding and delivers what came due as one grouped notification. */
  async releaseHeld() {
    holdUntil = null;
    const due = held.splice(0, held.length);
    if (due.length) {
      const n = due.length;
      Feedback.reminderTone();
      await Notify.show(`While you focused: ${n} task${n === 1 ? ' was' : 's were'} due`, due.slice(0, 5).map((d) => d.title).join(' · '), 'held');
    }
  },

  cancelAll() {
    for (const id of timers.values()) clearTimeout(id);
    timers.clear();
    held.length = 0;
    holdUntil = null;
  },
};

// Recompute whenever tasks, reminders or records change, and hourly so the
// two-day window keeps rolling.
let pending: number | undefined;
useDb.subscribe((s, prev) => {
  if (s.tasks === prev.tasks && s.taskReminders === prev.taskReminders && s.occurrenceRecords === prev.occurrenceRecords) return;
  clearTimeout(pending);
  pending = window.setTimeout(ReminderScheduler.reschedule, 500);
});
setInterval(ReminderScheduler.reschedule, 3_600_000);
