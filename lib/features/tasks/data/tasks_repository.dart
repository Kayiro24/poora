import 'package:poora/core/db/daos/tasks_dao.dart';
import 'package:poora/core/time/clock.dart';
import 'package:poora/core/time/date_utils.dart';
import 'package:poora/features/tasks/domain/models.dart';
import 'package:poora/features/tasks/domain/occurrence_generator.dart';
import 'package:poora/features/tasks/domain/series_edits.dart';
import 'package:uuid/uuid.dart';

/// All task mutations, with Google Calendar scope semantics.
class TasksRepository {
  TasksRepository({
    required this.dao,
    required this.clock,
    required this.generator,
  });

  final TasksDao dao;
  final Clock clock;
  final OccurrenceGenerator Function() generator;
  static const _uuid = Uuid();

  String newId() => _uuid.v4();

  Future<List<String>> tags() => dao.tags();

  Future<void> create(Task t) => dao.upsertTask(t);

  // --- Status -------------------------------------------------------------

  Future<OccurrenceRecord> _recordFor(Occurrence o) async =>
      o.record ??
      await dao.record(o.task.id, o.originalDate) ??
      OccurrenceRecord(
        id: newId(),
        taskId: o.task.id,
        occurrenceDate: o.originalDate,
      );

  /// Marks done (or undoes). Completing after the day is over counts as a
  /// late back-fill so on-time stats stay honest.
  Future<void> setDone(Occurrence o, {required bool done}) async {
    final now = clock.now();
    final rec = await _recordFor(o);
    if (!done) return _clearStatus(rec);
    await dao.upsertRecord(
      rec.copyWith(
        status: RecordStatus.done,
        completedAt: now,
        late: o.date.isBefore(Days.of(now)),
      ),
    );
  }

  Future<void> setSkipped(Occurrence o, {required bool skipped}) async {
    final rec = await _recordFor(o);
    if (!skipped) return _clearStatus(rec);
    await dao.upsertRecord(
      rec.copyWith(status: RecordStatus.skipped, completedAt: null, late: false),
    );
  }

  Future<void> _clearStatus(OccurrenceRecord rec) async {
    final hasOverride =
        rec.overrideDate != null ||
        rec.overrideStartMinute != null ||
        rec.overrideTitle != null;
    if (hasOverride) {
      await dao.upsertRecord(
        rec.copyWith(status: RecordStatus.none, completedAt: null, late: false),
      );
    } else {
      await dao.deleteRecord(rec.taskId, rec.occurrenceDate);
    }
  }

  // --- Edit ---------------------------------------------------------------

  /// Saves [edited] (the editor's result, whose `startDate` is the date the
  /// user picked for [occ]) with the given [scope].
  Future<void> save(Task edited, {Occurrence? occ, EditScope scope = EditScope.all}) async {
    final now = clock.now();
    final original = occ?.task;
    if (original == null || !original.isRecurring) {
      return dao.upsertTask(edited.copyWith(updatedAt: now));
    }
    switch (scope) {
      case EditScope.all:
        final shift = Days.between(occ!.originalDate, edited.startDate);
        await dao.upsertTask(
          edited.copyWith(
            id: original.id,
            startDate: Days.add(original.startDate, shift),
            updatedAt: now,
          ),
        );
      case EditScope.thisOne:
        await _saveThisOne(edited, occ!, now);
      case EditScope.thisAndFollowing:
        if (Days.same(occ!.originalDate, original.startDate)) {
          return save(edited, occ: occ);
        }
        final split = splitSeries(
          original: original,
          at: occ.originalDate,
          edited: edited,
          newId: newId(),
          now: now,
          generator: generator(),
        );
        // A different date picked in the editor moves the new series start.
        final following = split.following.copyWith(
          startDate: edited.startDate,
          reminders: [
            for (final r in edited.reminders)
              TaskReminder(id: newId(), offsetMin: r.offsetMin, atMinute: r.atMinute),
          ],
        );
        await dao.upsertTask(split.ended);
        await dao.upsertTask(following);
        await dao.reassignRecords(original.id, following.id, occ.originalDate);
    }
  }

  Future<void> _saveThisOne(Task edited, Occurrence occ, DateTime now) async {
    final t = occ.task;
    final onlyOverridable =
        edited.color == t.color &&
        edited.tag == t.tag &&
        edited.notes == t.notes &&
        edited.priority == t.priority &&
        edited.allDay == t.allDay &&
        edited.durationMin == t.durationMin &&
        _sameReminders(edited.reminders, t.reminders) &&
        edited.repeatKind == t.repeatKind &&
        edited.rrule == t.rrule;
    final rec = await _recordFor(occ);
    if (onlyOverridable) {
      await dao.upsertRecord(
        rec.copyWith(
          overrideTitle: edited.title == t.title ? null : edited.title,
          overrideDate: Days.same(edited.startDate, occ.originalDate)
              ? null
              : edited.startDate,
          overrideStartMinute: edited.startMinute == t.startMinute
              ? null
              : edited.startMinute,
        ),
      );
      return;
    }
    // Detach into a one-off exception, carrying over its status.
    final detached = detachOccurrence(
      edited: edited.copyWith(
        reminders: [
          for (final r in edited.reminders)
            TaskReminder(id: newId(), offsetMin: r.offsetMin, atMinute: r.atMinute),
        ],
      ),
      date: edited.startDate,
      newId: newId(),
      now: now,
    );
    await dao.upsertTask(detached);
    if (rec.status == RecordStatus.done || rec.status == RecordStatus.skipped) {
      await dao.upsertRecord(
        OccurrenceRecord(
          id: newId(),
          taskId: detached.id,
          occurrenceDate: detached.startDate,
          status: rec.status,
          completedAt: rec.completedAt,
          late: rec.late,
        ),
      );
    }
    await dao.upsertRecord(
      rec.copyWith(status: RecordStatus.deleted, completedAt: null),
    );
  }

  static bool _sameReminders(List<TaskReminder> a, List<TaskReminder> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // --- Reschedule (drag on the rail) -----------------------------------------

  Future<void> reschedule(
    Occurrence occ, {
    required DateTime date,
    required int? startMinute,
    int? durationMin,
    EditScope scope = EditScope.thisOne,
  }) async {
    final t = occ.task;
    final edited = t.copyWith(
      startDate: date,
      startMinute: startMinute,
      durationMin: durationMin ?? t.durationMin,
      allDay: startMinute == null && t.allDay,
    );
    if (!t.isRecurring) {
      return dao.upsertTask(edited.copyWith(updatedAt: clock.now()));
    }
    if (scope == EditScope.thisOne && durationMin == null) {
      final rec = await _recordFor(occ);
      await dao.upsertRecord(
        rec.copyWith(
          overrideDate: Days.same(date, occ.originalDate) ? null : date,
          overrideStartMinute: startMinute == t.startMinute ? null : startMinute,
        ),
      );
      return;
    }
    await save(edited, occ: occ, scope: scope);
  }

  // --- Delete -------------------------------------------------------------

  Future<void> delete(Occurrence occ, {EditScope scope = EditScope.all}) async {
    final t = occ.task;
    final now = clock.now();
    if (!t.isRecurring || scope == EditScope.all) {
      return dao.softDelete(t.id, now);
    }
    if (scope == EditScope.thisOne) {
      final rec = await _recordFor(occ);
      return dao.upsertRecord(
        rec.copyWith(status: RecordStatus.deleted, completedAt: null),
      );
    }
    if (Days.same(occ.originalDate, t.startDate)) {
      return dao.softDelete(t.id, now);
    }
    await dao.upsertTask(
      t.copyWith(
        endsOn: Days.add(occ.originalDate, -1),
        endsAfterCount: null,
        updatedAt: now,
      ),
    );
  }
}
