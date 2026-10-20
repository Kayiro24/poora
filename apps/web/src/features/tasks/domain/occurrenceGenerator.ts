import { RRule } from 'rrule';
import { Days, Range, type DateRange, type Day } from '../../../core/time/days';
import { isQuota, Occ, type Occurrence, type OccurrenceRecord, type OccurrenceStatus, type Task, type TaskSnapshot } from './models';

/**
 * Generates occurrences on the fly for a visible range and merges stored
 * records. Pure; mirrors the mobile app's OccurrenceGenerator exactly.
 */
export class OccurrenceGenerator {
  private readonly cache = new Map<string, ReturnType<typeof RRule.parseString>>();

  constructor(readonly mondayFirst: boolean) {}

  private rule(body: string, start: Day): RRule {
    let opts = this.cache.get(body);
    if (!opts) {
      opts = RRule.parseString(body);
      this.cache.set(body, opts);
    }
    return new RRule({ ...opts, dtstart: Days.toUtc(start) });
  }

  /** Original (un-overridden) occurrence dates of `t` within from..to. */
  datesFor(t: Task, from: Day, to: Day): Day[] {
    if (t.deletedAt != null) return [];
    const start = t.startDate;
    let last = to;
    if (t.endsOn && t.endsOn < last) last = t.endsOn;
    const first = start > from ? start : from;
    if (first > last) return [];

    switch (t.repeatKind) {
      case 'none':
        return start < from ? [] : [start];
      case 'quota':
        return Days.range(first, last);
      case 'rrule': {
        const rule = this.rule(t.rrule ?? 'FREQ=DAILY', start);
        const lastUtc = Days.toUtc(last);
        const count = t.endsAfterCount;
        if (count != null) {
          // COUNT is measured from the series start.
          const out: Day[] = [];
          rule.all((d, i) => {
            if (i >= count || d > lastUtc) return false;
            const day = Days.fromUtc(d);
            if (day >= first) out.push(day);
            return true;
          });
          return out;
        }
        return rule.between(Days.toUtc(first), lastUtc, true).map(Days.fromUtc);
      }
    }
  }

  occursOn(t: Task, day: Day): boolean {
    return this.datesFor(t, day, day).length > 0;
  }

  generate(snapshot: TaskSnapshot, range: DateRange, today: Day): Occurrence[] {
    const byTask = new Map<string, Map<Day, OccurrenceRecord>>();
    for (const r of snapshot.records) {
      let m = byTask.get(r.taskId);
      if (!m) byTask.set(r.taskId, (m = new Map()));
      m.set(r.occurrenceDate, r);
    }
    const out: Occurrence[] = [];
    for (const t of snapshot.tasks) {
      if (t.deletedAt != null) continue;
      const recs = byTask.get(t.id) ?? new Map<Day, OccurrenceRecord>();
      const originals = new Set(this.datesFor(t, range.from, range.to));
      // Occurrences moved into the range from outside it.
      for (const r of recs.values()) {
        const o = r.overrideDate;
        if (o && Range.contains(range, o) && !originals.has(r.occurrenceDate) && this.occursOn(t, r.occurrenceDate)) {
          originals.add(r.occurrenceDate);
        }
      }
      for (const original of originals) {
        const rec = recs.get(original) ?? null;
        if (rec?.status === 'deleted') continue;
        const date = rec?.overrideDate ?? original;
        if (!Range.contains(range, date)) continue;
        const occ = this.build(t, original, date, rec, today);
        if (isQuota(t) && !this.quotaVisible(t, occ, recs, today)) continue;
        out.push(occ);
      }
    }
    return out.sort(compareOccurrences);
  }

  private build(t: Task, original: Day, date: Day, rec: OccurrenceRecord | null, today: Day): Occurrence {
    let status: OccurrenceStatus;
    if (rec?.status === 'done') status = 'done';
    else if (rec?.status === 'skipped') status = 'skipped';
    else status = !isQuota(t) && date < today ? 'missed' : 'pending';
    return {
      task: t,
      originalDate: original,
      date,
      title: rec?.overrideTitle ?? t.title,
      startMinute: t.allDay ? null : (rec?.overrideStartMinute ?? t.startMinute),
      status,
      completedAt: rec?.completedAt ?? null,
      late: rec?.late ?? false,
      record: rec,
    };
  }

  private quotaVisible(t: Task, o: Occurrence, recs: Map<Day, OccurrenceRecord>, today: Day): boolean {
    if (o.status === 'done') return true;
    if (o.status === 'skipped') return o.date >= today;
    if (o.date < today) return false;
    return this.quotaDone(t, o.date, recs.values()) < (t.quotaPerWeek ?? 1);
  }

  /** Done count for quota task `t` in the week containing `day`. */
  quotaDone(t: Task, day: Day, records: Iterable<OccurrenceRecord>): number {
    const ws = Days.weekStart(day, this.mondayFirst);
    const we = Days.add(ws, 6);
    let n = 0;
    for (const r of records) {
      if (r.taskId !== t.id || r.status !== 'done') continue;
      const d = r.overrideDate ?? r.occurrenceDate;
      if (d >= ws && d <= we) n++;
    }
    return n;
  }
}

export function compareOccurrences(a: Occurrence, b: Occurrence): number {
  if (a.date !== b.date) return a.date < b.date ? -1 : 1;
  const at = Occ.isTimed(a), bt = Occ.isTimed(b);
  if (at !== bt) return at ? 1 : -1; // all-day first
  const m = (a.startMinute ?? 0) - (b.startMinute ?? 0);
  if (m !== 0) return m;
  return a.title.toLowerCase().localeCompare(b.title.toLowerCase());
}
