import 'package:poora/core/time/date_utils.dart';
import 'package:poora/features/tasks/domain/models.dart';
import 'package:rrule/rrule.dart';

/// Generates occurrences on the fly for a visible range (§5 rules) and merges
/// them with stored [OccurrenceRecord]s. Pure Dart; never persists anything.
class OccurrenceGenerator {
  OccurrenceGenerator({required this.mondayFirst});

  final bool mondayFirst;
  final Map<String, RecurrenceRule> _ruleCache = {};

  RecurrenceRule _rule(String body) =>
      _ruleCache.putIfAbsent(body, () => RecurrenceRule.fromString('RRULE:$body'));

  /// Original (un-overridden) occurrence dates of [t] within [from]..[to].
  List<DateTime> datesFor(Task t, DateTime from, DateTime to) {
    if (t.deletedAt != null) return const [];
    final start = Days.of(t.startDate);
    var last = Days.of(to);
    final endsOn = t.endsOn;
    if (endsOn != null && endsOn.isBefore(last)) last = Days.of(endsOn);
    final first = start.isAfter(from) ? start : Days.of(from);
    if (first.isAfter(last)) return const [];

    switch (t.repeatKind) {
      case RepeatKind.none:
        return start.isBefore(from) ? const [] : [start];
      case RepeatKind.quota:
        return Days.range(first, last).toList();
      case RepeatKind.rrule:
        final rule = _rule(t.rrule ?? 'FREQ=DAILY');
        final count = t.endsAfterCount;
        final out = <DateTime>[];
        if (count != null) {
          // COUNT is measured from the series start, so iterate from there.
          var n = 0;
          for (final d in rule.getInstances(start: start)) {
            if (d.isAfter(last) || n >= count) break;
            n++;
            if (!d.isBefore(first)) out.add(d);
          }
          return out;
        }
        for (final d in rule.getInstances(
          start: start,
          after: first,
          includeAfter: true,
        )) {
          if (d.isAfter(last)) break;
          out.add(d);
        }
        return out;
    }
  }

  /// True when [day] is an original occurrence date of [t].
  bool occursOn(Task t, DateTime day) => datesFor(t, day, day).isNotEmpty;

  /// All visible occurrences in [range], sorted by date then time.
  ///
  /// * Past occurrences without a done/skipped record are [OccurrenceStatus.missed];
  ///   [today]'s open ones are pending.
  /// * Quota tasks appear on every day until the week's quota is met; past
  ///   days only show if done (they are never "missed").
  List<Occurrence> generate({
    required TaskSnapshot snapshot,
    required DateRange range,
    required DateTime today,
  }) {
    final byTask = <String, Map<DateTime, OccurrenceRecord>>{};
    for (final r in snapshot.records) {
      (byTask[r.taskId] ??= {})[r.occurrenceDate] = r;
    }
    final out = <Occurrence>[];
    for (final t in snapshot.tasks) {
      if (t.deletedAt != null) continue;
      final recs = byTask[t.id] ?? const {};
      final originals = datesFor(t, range.from, range.to).toSet();
      // Occurrences moved into the range from outside it.
      for (final r in recs.values) {
        final o = r.overrideDate;
        if (o != null &&
            range.contains(o) &&
            !originals.contains(r.occurrenceDate) &&
            occursOn(t, r.occurrenceDate)) {
          originals.add(r.occurrenceDate);
        }
      }
      for (final original in originals) {
        final rec = recs[original];
        if (rec?.status == RecordStatus.deleted) continue;
        final date = rec?.overrideDate ?? original;
        if (!range.contains(date)) continue;
        final occ = _build(t, original, date, rec, today);
        if (t.isQuota && !_quotaVisible(t, occ, recs, today)) continue;
        out.add(occ);
      }
    }
    out.sort(compareOccurrences);
    return out;
  }

  Occurrence _build(
    Task t,
    DateTime original,
    DateTime date,
    OccurrenceRecord? rec,
    DateTime today,
  ) {
    final status = switch (rec?.status) {
      RecordStatus.done => OccurrenceStatus.done,
      RecordStatus.skipped => OccurrenceStatus.skipped,
      _ =>
        !t.isQuota && date.isBefore(today)
            ? OccurrenceStatus.missed
            : OccurrenceStatus.pending,
    };
    return Occurrence(
      task: t,
      originalDate: original,
      date: date,
      title: rec?.overrideTitle ?? t.title,
      startMinute: t.allDay ? null : (rec?.overrideStartMinute ?? t.startMinute),
      status: status,
      completedAt: rec?.completedAt,
      late: rec?.late ?? false,
      record: rec,
    );
  }

  bool _quotaVisible(
    Task t,
    Occurrence occ,
    Map<DateTime, OccurrenceRecord> recs,
    DateTime today,
  ) {
    if (occ.status == OccurrenceStatus.done) return true;
    if (occ.status == OccurrenceStatus.skipped) return !occ.date.isBefore(today);
    if (occ.date.isBefore(today)) return false;
    return quotaDone(t, occ.date, recs.values) < (t.quotaPerWeek ?? 1);
  }

  /// Done count for quota task [t] in the week containing [day].
  int quotaDone(Task t, DateTime day, Iterable<OccurrenceRecord> records) {
    final ws = Days.weekStart(day, mondayFirst: mondayFirst);
    final we = Days.add(ws, 6);
    var n = 0;
    for (final r in records) {
      if (r.taskId != t.id || r.status != RecordStatus.done) continue;
      final d = r.overrideDate ?? r.occurrenceDate;
      if (!d.isBefore(ws) && !d.isAfter(we)) n++;
    }
    return n;
  }
}

int compareOccurrences(Occurrence a, Occurrence b) {
  final d = a.date.compareTo(b.date);
  if (d != 0) return d;
  if (a.isTimed != b.isTimed) return a.isTimed ? 1 : -1; // all-day first
  final m = (a.startMinute ?? 0).compareTo(b.startMinute ?? 0);
  if (m != 0) return m;
  return a.title.toLowerCase().compareTo(b.title.toLowerCase());
}
