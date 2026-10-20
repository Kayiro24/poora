import 'package:poora/core/time/date_utils.dart';
import 'package:poora/features/tasks/domain/models.dart';
import 'package:poora/features/tasks/domain/occurrence_generator.dart';

/// Google Calendar edit semantics for recurring tasks.
enum EditScope { thisOne, thisAndFollowing, all }

class SeriesSplit {
  const SeriesSplit({required this.ended, required this.following});

  /// The original series, now ending the day before the split.
  final Task ended;

  /// The new series starting at the split date (same `seriesId`).
  final Task following;
}

/// "This and following": ends [original] the day before [at] and starts
/// [edited] (already carrying the new fields) as a new task on [at].
///
/// A COUNT limit is carried over as the number of occurrences that remained.
SeriesSplit splitSeries({
  required Task original,
  required DateTime at,
  required Task edited,
  required String newId,
  required DateTime now,
  required OccurrenceGenerator generator,
}) {
  final day = Days.of(at);
  final before = Days.add(day, -1);
  int? remaining;
  final count = original.endsAfterCount;
  if (count != null) {
    final used = generator.datesFor(original, original.startDate, before).length;
    remaining = (count - used).clamp(1, count);
  }
  final ended = original.copyWith(
    endsOn: before,
    endsAfterCount: null,
    updatedAt: now,
  );
  final keepCount = edited.endsAfterCount == original.endsAfterCount;
  final following = edited.copyWith(
    id: newId,
    startDate: day,
    seriesId: original.seriesId,
    endsAfterCount: keepCount ? remaining : edited.endsAfterCount,
    createdAt: now,
    updatedAt: now,
  );
  return SeriesSplit(ended: ended, following: following);
}

/// "This task" on a field the record cannot override: detach the occurrence
/// into a one-off task in the same series.
Task detachOccurrence({
  required Task edited,
  required DateTime date,
  required String newId,
  required DateTime now,
}) => edited.copyWith(
  id: newId,
  startDate: Days.of(date),
  repeatKind: RepeatKind.none,
  rrule: null,
  quotaPerWeek: null,
  quotaPreferredDays: const [],
  endsOn: null,
  endsAfterCount: null,
  createdAt: now,
  updatedAt: now,
);
