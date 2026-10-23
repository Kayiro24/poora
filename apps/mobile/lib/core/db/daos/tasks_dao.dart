import 'package:drift/drift.dart';
import 'package:poora/core/db/database.dart';
import 'package:poora/core/time/date_utils.dart';
import 'package:poora/features/tasks/domain/models.dart';

/// Row ↔ domain mapping and queries for tasks, reminders and records.
class TasksDao {
  TasksDao(this.db);
  final AppDatabase db;

  Stream<TaskSnapshot> watchSnapshot() async* {
    yield await loadSnapshot();
    await for (final _ in db.tableUpdates(
      TableUpdateQuery.onAllTables([
        db.tasks,
        db.taskReminders,
        db.occurrenceRecords,
      ]),
    )) {
      yield await loadSnapshot();
    }
  }

  Future<TaskSnapshot> loadSnapshot({bool includeDeleted = false}) async {
    final taskQuery = db.select(db.tasks);
    if (!includeDeleted) taskQuery.where((t) => t.deletedAt.isNull());
    final taskRows = await taskQuery.get();
    final reminderRows = await db.select(db.taskReminders).get();
    final recordRows = await db.select(db.occurrenceRecords).get();
    final remindersByTask = <String, List<TaskReminder>>{};
    for (final r in reminderRows) {
      (remindersByTask[r.taskId] ??= []).add(
        TaskReminder(id: r.id, offsetMin: r.offsetMin, atMinute: r.atMinute),
      );
    }
    return TaskSnapshot(
      tasks: [
        for (final r in taskRows)
          taskFromRow(r, remindersByTask[r.id] ?? const []),
      ],
      records: recordRows.map(recordFromRow).toList(),
    );
  }

  Future<void> upsertTask(Task t) => db.transaction(() async {
    await db.into(db.tasks).insertOnConflictUpdate(taskToRow(t));
    await (db.delete(db.taskReminders)..where((r) => r.taskId.equals(t.id))).go();
    for (final r in t.reminders) {
      await db
          .into(db.taskReminders)
          .insert(
            TaskRemindersCompanion.insert(
              id: r.id,
              taskId: t.id,
              offsetMin: r.offsetMin,
              atMinute: Value(r.atMinute),
            ),
          );
    }
  });

  Future<void> softDelete(String taskId, DateTime now) =>
      (db.update(db.tasks)..where((t) => t.id.equals(taskId))).write(
        TasksCompanion(
          deletedAt: Value(now.millisecondsSinceEpoch),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );

  Future<void> restore(String taskId, DateTime now) =>
      (db.update(db.tasks)..where((t) => t.id.equals(taskId))).write(
        TasksCompanion(deletedAt: const Value(null), updatedAt: Value(now.millisecondsSinceEpoch)),
      );

  /// Removes a task with its reminders and records for good.
  Future<void> hardDelete(String taskId) => db.transaction(() async {
    await (db.delete(db.taskReminders)..where((r) => r.taskId.equals(taskId))).go();
    await (db.delete(db.occurrenceRecords)..where((r) => r.taskId.equals(taskId))).go();
    await (db.delete(db.tasks)..where((t) => t.id.equals(taskId))).go();
  });

  /// Permanently removes trashed tasks deleted before [before].
  Future<void> purgeDeleted({required DateTime before}) async {
    final rows = await (db.select(db.tasks)
          ..where((t) => t.deletedAt.isNotNull() & t.deletedAt.isSmallerThanValue(before.millisecondsSinceEpoch)))
        .get();
    for (final r in rows) {
      await hardDelete(r.id);
    }
  }

  /// Trashed tasks, most recently deleted first.
  Stream<List<Task>> watchDeleted() async* {
    Future<List<Task>> load() async {
      final rows = await (db.select(db.tasks)
            ..where((t) => t.deletedAt.isNotNull())
            ..orderBy([(t) => OrderingTerm.desc(t.deletedAt)]))
          .get();
      return [for (final r in rows) taskFromRow(r, const [])];
    }

    yield await load();
    await for (final _ in db.tableUpdates(TableUpdateQuery.onTable(db.tasks))) {
      yield await load();
    }
  }

  Future<OccurrenceRecord?> record(String taskId, DateTime date) async {
    final row =
        await (db.select(db.occurrenceRecords)..where(
              (r) =>
                  r.taskId.equals(taskId) &
                  r.occurrenceDate.equals(Days.iso(date)),
            ))
            .getSingleOrNull();
    return row == null ? null : recordFromRow(row);
  }

  Future<void> upsertRecord(OccurrenceRecord r) => db
      .into(db.occurrenceRecords)
      .insert(
        recordToRow(r),
        onConflict: DoUpdate(
          (_) => recordToRow(r),
          target: [db.occurrenceRecords.taskId, db.occurrenceRecords.occurrenceDate],
        ),
      );

  Future<void> deleteRecord(String taskId, DateTime date) =>
      (db.delete(db.occurrenceRecords)..where(
            (r) =>
                r.taskId.equals(taskId) &
                r.occurrenceDate.equals(Days.iso(date)),
          ))
          .go();

  /// Moves records on/after [from] to another task (series split).
  Future<void> reassignRecords(String fromTask, String toTask, DateTime from) =>
      (db.update(db.occurrenceRecords)..where(
            (r) =>
                r.taskId.equals(fromTask) &
                r.occurrenceDate.isBiggerOrEqualValue(Days.iso(from)),
          ))
          .write(OccurrenceRecordsCompanion(taskId: Value(toTask)));

  Future<List<String>> tags() async {
    final rows =
        await (db.selectOnly(db.tasks, distinct: true)
              ..addColumns([db.tasks.tag])
              ..where(db.tasks.tag.isNotNull() & db.tasks.deletedAt.isNull()))
            .get();
    return rows
        .map((r) => r.read(db.tasks.tag)!.trim())
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  // --- Mapping ------------------------------------------------------------

  static Task taskFromRow(TaskRow r, List<TaskReminder> reminders) => Task(
    id: r.id,
    title: r.title,
    notes: r.notes,
    color: r.color,
    tag: r.tag,
    priority: Priority.values[r.priority.clamp(0, 2)],
    allDay: r.allDay,
    startDate: Days.parse(r.startDate),
    startMinute: r.startMinute,
    durationMin: r.durationMin,
    repeatKind: RepeatKind.values.byName(r.repeatKind),
    rrule: r.rrule,
    quotaPerWeek: r.quotaPerWeek,
    quotaPreferredDays: (r.quotaPreferredDays ?? '')
        .split(',')
        .map(int.tryParse)
        .whereType<int>()
        .toList(),
    endsOn: r.endsOn == null ? null : Days.parse(r.endsOn!),
    endsAfterCount: r.endsAfterCount,
    seriesId: r.seriesId,
    timeZone: r.timeZone,
    createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(r.updatedAt),
    deletedAt: r.deletedAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(r.deletedAt!),
    reminders: reminders,
  );

  static TasksCompanion taskToRow(Task t) => TasksCompanion.insert(
    id: t.id,
    title: t.title,
    notes: Value(t.notes),
    color: t.color,
    tag: Value(t.tag),
    priority: Value(t.priority.index),
    allDay: Value(t.allDay),
    startDate: Days.iso(t.startDate),
    startMinute: Value(t.startMinute),
    durationMin: Value(t.durationMin),
    repeatKind: Value(t.repeatKind.name),
    rrule: Value(t.rrule),
    quotaPerWeek: Value(t.quotaPerWeek),
    quotaPreferredDays: Value(
      t.quotaPreferredDays.isEmpty ? null : t.quotaPreferredDays.join(','),
    ),
    endsOn: Value(t.endsOn == null ? null : Days.iso(t.endsOn!)),
    endsAfterCount: Value(t.endsAfterCount),
    seriesId: t.seriesId,
    timeZone: Value(t.timeZone),
    createdAt: t.createdAt.millisecondsSinceEpoch,
    updatedAt: t.updatedAt.millisecondsSinceEpoch,
    deletedAt: Value(t.deletedAt?.millisecondsSinceEpoch),
  );

  static OccurrenceRecord recordFromRow(OccurrenceRecordRow r) =>
      OccurrenceRecord(
        id: r.id,
        taskId: r.taskId,
        occurrenceDate: Days.parse(r.occurrenceDate),
        status: RecordStatus.values.byName(r.status),
        completedAt: r.completedAt == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(r.completedAt!),
        overrideDate: r.overrideDate == null
            ? null
            : Days.parse(r.overrideDate!),
        overrideStartMinute: r.overrideStartMinute,
        overrideTitle: r.overrideTitle,
        late: r.late,
      );

  static OccurrenceRecordsCompanion recordToRow(OccurrenceRecord r) =>
      OccurrenceRecordsCompanion.insert(
        id: r.id,
        taskId: r.taskId,
        occurrenceDate: Days.iso(r.occurrenceDate),
        status: Value(r.status.name),
        completedAt: Value(r.completedAt?.millisecondsSinceEpoch),
        overrideDate: Value(
          r.overrideDate == null ? null : Days.iso(r.overrideDate!),
        ),
        overrideStartMinute: Value(r.overrideStartMinute),
        overrideTitle: Value(r.overrideTitle),
        late: Value(r.late),
      );
}
