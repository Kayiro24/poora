/**
 * Calendar dates without a time of day, as ISO `YYYY-MM-DD` strings.
 *
 * Strings are value-equal and sort chronologically, so they work as Map keys
 * and compare with `<`. Arithmetic goes through UTC midnight, which never
 * crosses a DST transition — the same model as the mobile app's `Days`.
 */
export type Day = string;

const pad = (n: number, w = 2) => String(n).padStart(w, '0');

export const Days = {
  /** Local calendar day of an instant. */
  of(t: Date): Day {
    return `${pad(t.getFullYear(), 4)}-${pad(t.getMonth() + 1)}-${pad(t.getDate())}`;
  },

  ymd(y: number, m: number, d: number): Day {
    return Days.fromUtc(new Date(Date.UTC(y, m - 1, d)));
  },

  /** UTC-midnight Date for a day (for rrule and arithmetic). */
  toUtc(d: Day): Date {
    const [y, m, dd] = d.split('-').map(Number);
    return new Date(Date.UTC(y, m - 1, dd));
  },

  fromUtc(t: Date): Day {
    return `${pad(t.getUTCFullYear(), 4)}-${pad(t.getUTCMonth() + 1)}-${pad(t.getUTCDate())}`;
  },

  add(d: Day, n: number): Day {
    const t = Days.toUtc(d);
    t.setUTCDate(t.getUTCDate() + n);
    return Days.fromUtc(t);
  },

  between(a: Day, b: Day): number {
    return Math.round((Days.toUtc(b).getTime() - Days.toUtc(a).getTime()) / 86_400_000);
  },

  /** ISO weekday: 1 = Monday … 7 = Sunday. */
  weekday(d: Day): number {
    const w = Days.toUtc(d).getUTCDay();
    return w === 0 ? 7 : w;
  },

  year: (d: Day) => Number(d.slice(0, 4)),
  month: (d: Day) => Number(d.slice(5, 7)),
  date: (d: Day) => Number(d.slice(8, 10)),

  /** Local wall-clock instant on `day` at `minute` past midnight. */
  at(d: Day, minute: number): Date {
    return new Date(Days.year(d), Days.month(d) - 1, Days.date(d), 0, minute);
  },

  weekStart(d: Day, mondayFirst: boolean): Day {
    const wd = Days.weekday(d);
    return Days.add(d, -(mondayFirst ? wd - 1 : wd % 7));
  },

  monthStart(d: Day): Day {
    return `${d.slice(0, 7)}-01`;
  },

  daysInMonth(y: number, m: number): number {
    return new Date(Date.UTC(y, m, 0)).getUTCDate();
  },

  /** First day of the month `delta` months from `d`'s month. */
  addMonths(d: Day, delta: number): Day {
    return Days.fromUtc(new Date(Date.UTC(Days.year(d), Days.month(d) - 1 + delta, 1)));
  },

  range(from: Day, to: Day): Day[] {
    const out: Day[] = [];
    for (let d = from; d <= to; d = Days.add(d, 1)) out.push(d);
    return out;
  },
};

/** Inclusive range of days. */
export interface DateRange {
  from: Day;
  to: Day;
}

export const Range = {
  of: (from: Day, to: Day): DateRange => ({ from, to }),
  day: (d: Day): DateRange => ({ from: d, to: d }),
  week(d: Day, mondayFirst: boolean): DateRange {
    const s = Days.weekStart(d, mondayFirst);
    return { from: s, to: Days.add(s, 6) };
  },
  month(d: Day): DateRange {
    const s = Days.monthStart(d);
    return { from: s, to: Days.add(Days.addMonths(s, 1), -1) };
  },
  contains: (r: DateRange, d: Day) => d >= r.from && d <= r.to,
  days: (r: DateRange) => Days.range(r.from, r.to),
  length: (r: DateRange) => Days.between(r.from, r.to) + 1,
  key: (r: DateRange) => `${r.from}..${r.to}`,
};
