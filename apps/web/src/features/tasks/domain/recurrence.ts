import { Days, type Day } from '../../../core/time/days';
import { monthLong, weekdayLong, weekdayShort } from '../../../core/time/format';
import type { RepeatKind, Task } from './models';

export type Freq = 'daily' | 'weekly' | 'monthly' | 'yearly';
export type MonthlyMode = 'dayOfMonth' | 'nthWeekday' | 'lastWeekday';

const RR_DAYS = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
const ORDINALS = ['first', 'second', 'third', 'fourth', 'fifth'];

/** Editable repeat rule (§4.8). Fixed rules serialise to RRULE bodies. */
export interface RepeatRule {
  kind: RepeatKind;
  freq: Freq;
  interval: number;
  /** ISO weekdays for weekly rules. */
  weekdays: number[];
  monthlyMode: MonthlyMode;
  quota: number;
  preferredDays: number[];
  endsOn: Day | null;
  endsAfter: number | null;
}

const base: RepeatRule = {
  kind: 'none',
  freq: 'daily',
  interval: 1,
  weekdays: [],
  monthlyMode: 'dayOfMonth',
  quota: 3,
  preferredDays: [],
  endsOn: null,
  endsAfter: null,
};

export const Rules = {
  none: base,
  daily: (): RepeatRule => ({ ...base, kind: 'rrule' }),
  everyOtherDay: (): RepeatRule => ({ ...base, kind: 'rrule', interval: 2 }),
  weekdaysOnly: (): RepeatRule => ({ ...base, kind: 'rrule', freq: 'weekly', weekdays: [1, 2, 3, 4, 5] }),
  weeklyOn: (start: Day): RepeatRule => ({ ...base, kind: 'rrule', freq: 'weekly', weekdays: [Days.weekday(start)] }),
  monthlyOnDay: (): RepeatRule => ({ ...base, kind: 'rrule', freq: 'monthly' }),
  yearly: (): RepeatRule => ({ ...base, kind: 'rrule', freq: 'yearly' }),
  timesPerWeek: (n: number): RepeatRule => ({ ...base, kind: 'quota', quota: n }),

  /** 1-based week-of-month of the day's weekday (third Monday → 3). */
  nthOfMonth: (d: Day) => Math.floor((Days.date(d) - 1) / 7) + 1,

  toRRule(r: RepeatRule, start: Day): string | null {
    if (r.kind !== 'rrule') return null;
    const parts = [`FREQ=${r.freq.toUpperCase()}`];
    if (r.interval > 1) parts.push(`INTERVAL=${r.interval}`);
    const wd = Days.weekday(start);
    switch (r.freq) {
      case 'daily':
        break;
      case 'weekly': {
        const days = [...(r.weekdays.length ? r.weekdays : [wd])].sort((a, b) => a - b);
        parts.push(`BYDAY=${days.map((d) => RR_DAYS[d - 1]).join(',')}`);
        break;
      }
      case 'monthly':
        if (r.monthlyMode === 'dayOfMonth') parts.push(`BYMONTHDAY=${Days.date(start)}`);
        else if (r.monthlyMode === 'nthWeekday') parts.push(`BYDAY=${Rules.nthOfMonth(start)}${RR_DAYS[wd - 1]}`);
        else parts.push(`BYDAY=-1${RR_DAYS[wd - 1]}`);
        break;
      case 'yearly':
        parts.push(`BYMONTH=${Days.month(start)}`, `BYMONTHDAY=${Days.date(start)}`);
        break;
    }
    return parts.join(';');
  },

  parse(body: string): Record<string, string> {
    const map: Record<string, string> = {};
    for (const part of body.replace('RRULE:', '').split(';')) {
      const i = part.indexOf('=');
      if (i > 0) map[part.slice(0, i).toUpperCase()] = part.slice(i + 1);
    }
    return map;
  },

  fromTask(t: Task): RepeatRule {
    if (t.repeatKind === 'none') return base;
    if (t.repeatKind === 'quota') {
      return { ...base, kind: 'quota', quota: t.quotaPerWeek ?? 3, preferredDays: [...t.quotaPreferredDays], endsOn: t.endsOn };
    }
    const map = Rules.parse(t.rrule ?? 'FREQ=DAILY');
    const freq = (['daily', 'weekly', 'monthly', 'yearly'] as Freq[]).find((f) => f.toUpperCase() === map.FREQ) ?? 'daily';
    let weekdays: number[] = [];
    let monthlyMode: MonthlyMode = 'dayOfMonth';
    const byDay = map.BYDAY;
    if (byDay) {
      if (freq === 'monthly') monthlyMode = byDay.startsWith('-1') ? 'lastWeekday' : 'nthWeekday';
      else weekdays = byDay.split(',').map((d) => RR_DAYS.indexOf(d.replace(/[-0-9]/g, '')) + 1).filter((d) => d > 0);
    }
    return {
      ...base,
      kind: 'rrule',
      freq,
      interval: Number(map.INTERVAL ?? '1') || 1,
      weekdays,
      monthlyMode,
      endsOn: t.endsOn,
      endsAfter: t.endsAfterCount,
    };
  },

  summary(r: RepeatRule, start: Day): string {
    const b = Rules.baseSummary(r, start);
    if (r.kind === 'none') return b;
    if (r.endsOn) return `${b}, until ${monthLong[Days.month(r.endsOn) - 1].slice(0, 3)} ${Days.date(r.endsOn)}, ${Days.year(r.endsOn)}`;
    if (r.endsAfter != null) return `${b}, ${r.endsAfter} times`;
    return b;
  },

  baseSummary(r: RepeatRule, start: Day): string {
    if (r.kind === 'none') return 'Does not repeat';
    if (r.kind === 'quota') return r.quota === 1 ? 'Once a week' : `${r.quota} times a week`;
    const n = r.interval;
    const wd = Days.weekday(start);
    switch (r.freq) {
      case 'daily':
        return n === 1 ? 'Every day' : `Every ${n} days`;
      case 'weekly': {
        const days = [...(r.weekdays.length ? r.weekdays : [wd])].sort((a, b) => a - b);
        if (n === 1 && days.length === 5 && days.every((d) => d <= 5)) return 'Every weekday';
        if (n === 1 && days.length === 7) return 'Every day';
        const names = days.map((d) => weekdayShort[d - 1]).join(', ');
        return n === 1 ? `Weekly on ${names}` : `Every ${n} weeks on ${names}`;
      }
      case 'monthly': {
        const prefix = n === 1 ? 'Monthly' : `Every ${n} months`;
        if (r.monthlyMode === 'dayOfMonth') return `${prefix} on day ${Days.date(start)}`;
        if (r.monthlyMode === 'nthWeekday') return `${prefix} on the ${ORDINALS[Rules.nthOfMonth(start) - 1]} ${weekdayLong[wd - 1]}`;
        return `${prefix} on the last ${weekdayLong[wd - 1]}`;
      }
      case 'yearly': {
        const date = `${monthLong[Days.month(start) - 1]} ${Days.date(start)}`;
        return n === 1 ? `Annually on ${date}` : `Every ${n} years on ${date}`;
      }
    }
  },

  /** Writes the rule's fields onto a task (for its start date). */
  applyTo(r: RepeatRule, t: Task): Task {
    return {
      ...t,
      repeatKind: r.kind,
      rrule: Rules.toRRule(r, t.startDate),
      quotaPerWeek: r.kind === 'quota' ? r.quota : null,
      quotaPreferredDays: r.kind === 'quota' ? [...r.preferredDays].sort((a, b) => a - b) : [],
      endsOn: r.kind === 'none' ? null : r.endsOn,
      endsAfterCount: r.kind === 'rrule' ? r.endsAfter : null,
    };
  },

  equal(a: RepeatRule, b: RepeatRule): boolean {
    const set = (x: number[]) => [...x].sort().join(',');
    return (
      a.kind === b.kind && a.freq === b.freq && a.interval === b.interval &&
      set(a.weekdays) === set(b.weekdays) && a.monthlyMode === b.monthlyMode &&
      a.quota === b.quota && set(a.preferredDays) === set(b.preferredDays) &&
      a.endsOn === b.endsOn && a.endsAfter === b.endsAfter
    );
  },
};
