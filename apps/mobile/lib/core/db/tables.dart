import 'package:drift/drift.dart';

// Schema (§5). Calendar dates are ISO `yyyy-MM-dd` text; instants are epoch
// milliseconds (drift's default DateTime storage drops milliseconds, which
// the focus timer needs).

@DataClassName('TaskRow')
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get notes => text().nullable()();
  IntColumn get color => integer()();
  TextColumn get tag => text().nullable()();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  BoolColumn get allDay => boolean().withDefault(const Constant(false))();
  TextColumn get startDate => text()();
  IntColumn get startMinute => integer().nullable()();
  IntColumn get durationMin => integer().nullable()();
  TextColumn get repeatKind => text().withDefault(const Constant('none'))();
  TextColumn get rrule => text().nullable()();
  IntColumn get quotaPerWeek => integer().nullable()();
  TextColumn get quotaPreferredDays => text().nullable()();
  TextColumn get endsOn => text().nullable()();
  IntColumn get endsAfterCount => integer().nullable()();
  TextColumn get seriesId => text()();
  TextColumn get timeZone => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TaskReminderRow')
class TaskReminders extends Table {
  TextColumn get id => text()();
  TextColumn get taskId =>
      text().references(Tasks, #id, onDelete: KeyAction.cascade)();
  IntColumn get offsetMin => integer()();
  IntColumn get atMinute => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('OccurrenceRecordRow')
class OccurrenceRecords extends Table {
  TextColumn get id => text()();
  TextColumn get taskId =>
      text().references(Tasks, #id, onDelete: KeyAction.cascade)();
  TextColumn get occurrenceDate => text()();

  /// none | done | skipped | deleted. "missed" is derived, never stored.
  TextColumn get status => text().withDefault(const Constant('none'))();
  IntColumn get completedAt => integer().nullable()();
  TextColumn get overrideDate => text().nullable()();
  IntColumn get overrideStartMinute => integer().nullable()();
  TextColumn get overrideTitle => text().nullable()();

  /// Back-filled completion (§4.11 day sheet) — keeps on-time stats honest.
  BoolColumn get late => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {taskId, occurrenceDate},
  ];
}

@DataClassName('FocusSessionRow')
class FocusSessions extends Table {
  TextColumn get id => text()();
  IntColumn get startedAt => integer()();
  IntColumn get endedAt => integer().nullable()();
  IntColumn get plannedFocusMin => integer()();
  IntColumn get shortBreakMin => integer()();
  IntColumn get longBreakMin => integer()();
  IntColumn get longEvery => integer()();
  IntColumn get focusMsCompleted => integer().withDefault(const Constant(0))();
  IntColumn get phasesCompleted => integer().withDefault(const Constant(0))();
  BoolColumn get endedEarly => boolean().withDefault(const Constant(false))();
  TextColumn get linkedTaskId => text().nullable()();
  TextColumn get linkedOccurrenceDate => text().nullable()();

  // Focus tracking (schema v2).
  IntColumn get pausedMs => integer().withDefault(const Constant(0))();
  IntColumn get awayMs => integer().withDefault(const Constant(0))();
  IntColumn get interruptions => integer().withDefault(const Constant(0))();

  /// JSON object: Android package name → ms in that app during the session.
  TextColumn get distractions => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Single row: the live session, for kill-recovery.
@DataClassName('FocusStateRow')
class FocusStates extends Table {
  @override
  String get tableName => 'focus_state';

  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get sessionId => text()();
  TextColumn get phase => text()();
  IntColumn get focusIndex => integer()();
  IntColumn get phaseStartedAt => integer().nullable()();
  IntColumn get phaseDurationMs => integer()();
  IntColumn get pausedAt => integer().nullable()();
  IntColumn get pausedAccumMs => integer().withDefault(const Constant(0))();
  IntColumn get focusMsCompleted => integer().withDefault(const Constant(0))();
  IntColumn get phasesCompleted => integer().withDefault(const Constant(0))();

  // Focus tracking (schema v2).
  IntColumn get pausedTotalMs => integer().withDefault(const Constant(0))();
  IntColumn get interruptions => integer().withDefault(const Constant(0))();
  IntColumn get awayMs => integer().withDefault(const Constant(0))();
  IntColumn get awayStartedAt => integer().nullable()();
  IntColumn get awayCapAt => integer().nullable()();
  IntColumn get lastSeenAt => integer().nullable()();

  // Strict mode (schema v3): the focus phase can't be paused, skipped or ended.
  BoolColumn get strict => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PresetRow')
class Presets extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get focusMin => integer()();
  IntColumn get shortMin => integer()();
  IntColumn get longMin => integer()();
  IntColumn get longEvery => integer()();
  IntColumn get sort => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('HeldReminderRow')
class HeldReminders extends Table {
  IntColumn get notificationId => integer()();
  TextColumn get taskId => text()();
  TextColumn get occurrenceDate => text()();
  IntColumn get originalFireAt => integer()();
  TextColumn get title => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {notificationId};
}

@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
