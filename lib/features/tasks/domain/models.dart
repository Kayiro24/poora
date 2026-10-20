import 'package:poora/core/time/date_utils.dart';

enum RepeatKind { none, rrule, quota }

enum Priority { none, low, high }

/// Sentinel for nullable `copyWith` parameters.
const Object _keep = Object();

/// A reminder attached to a task.
///
/// * [atMinute] null: fires at the occurrence start + [offsetMin]
///   (negative = before). Timed tasks only.
/// * [atMinute] set: fires on (occurrence day + [offsetMin] / 1440 days) at
///   [atMinute] past midnight — e.g. all-day "day before at 9:00" is
///   `offsetMin: -1440, atMinute: 540`.
class TaskReminder {
  const TaskReminder({required this.id, required this.offsetMin, this.atMinute});

  final String id;
  final int offsetMin;
  final int? atMinute;

  /// Fire instant (local) for an occurrence on [day] starting at [startMinute].
  DateTime? fireAt(DateTime day, int? startMinute) {
    if (atMinute != null) {
      return Days.at(Days.add(day, (offsetMin / 1440).floor()), atMinute!);
    }
    if (startMinute == null) return null;
    return Days.at(day, startMinute).add(Duration(minutes: offsetMin));
  }

  String label({bool allDay = false, String Function(int minute)? time}) {
    final t = time ?? _hhmm;
    if (atMinute != null) {
      final daysBefore = -(offsetMin / 1440).floor();
      if (daysBefore == 0) return 'On the day at ${t(atMinute!)}';
      if (daysBefore == 1) return 'Day before at ${t(atMinute!)}';
      return '$daysBefore days before at ${t(atMinute!)}';
    }
    final m = -offsetMin;
    if (m == 0) return 'At start time';
    if (m < 0) return '${-m} min after';
    if (m % 1440 == 0) return '${m ~/ 1440} day${m == 1440 ? '' : 's'} before';
    if (m % 60 == 0) return '${m ~/ 60} hour${m == 60 ? '' : 's'} before';
    return '$m min before';
  }

  static String _hhmm(int minute) =>
      '${(minute ~/ 60).toString().padLeft(2, '0')}:'
      '${(minute % 60).toString().padLeft(2, '0')}';

  Map<String, Object?> toJson() => {
    'id': id,
    'offsetMin': offsetMin,
    'atMinute': atMinute,
  };

  factory TaskReminder.fromJson(Map<String, Object?> j) => TaskReminder(
    id: j['id']! as String,
    offsetMin: j['offsetMin']! as int,
    atMinute: j['atMinute'] as int?,
  );

  @override
  bool operator ==(Object other) =>
      other is TaskReminder &&
      other.offsetMin == offsetMin &&
      other.atMinute == atMinute;

  @override
  int get hashCode => Object.hash(offsetMin, atMinute);
}

class Task {
  const Task({
    required this.id,
    required this.title,
    required this.color,
    required this.startDate,
    required this.seriesId,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.tag,
    this.priority = Priority.none,
    this.allDay = false,
    this.startMinute,
    this.durationMin,
    this.repeatKind = RepeatKind.none,
    this.rrule,
    this.quotaPerWeek,
    this.quotaPreferredDays = const [],
    this.endsOn,
    this.endsAfterCount,
    this.timeZone,
    this.deletedAt,
    this.reminders = const [],
  });

  final String id;
  final String title;
  final String? notes;

  /// ARGB colour value.
  final int color;
  final String? tag;
  final Priority priority;
  final bool allDay;

  /// First occurrence date (UTC-midnight day, see [Days]).
  final DateTime startDate;

  /// Minutes from midnight; null when [allDay].
  final int? startMinute;
  final int? durationMin;
  final RepeatKind repeatKind;

  /// RFC 5545 RRULE body without DTSTART/UNTIL/COUNT, e.g. `FREQ=DAILY;INTERVAL=2`.
  final String? rrule;
  final int? quotaPerWeek;

  /// ISO weekdays 1 (Mon) … 7 (Sun).
  final List<int> quotaPreferredDays;
  final DateTime? endsOn;
  final int? endsAfterCount;

  /// Groups the pieces of a series split by "this and following" edits.
  final String seriesId;
  final String? timeZone;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final List<TaskReminder> reminders;

  bool get isRecurring => repeatKind != RepeatKind.none;
  bool get isQuota => repeatKind == RepeatKind.quota;
  bool get isTimed => !allDay && startMinute != null;

  Task copyWith({
    String? id,
    String? title,
    Object? notes = _keep,
    int? color,
    Object? tag = _keep,
    Priority? priority,
    bool? allDay,
    DateTime? startDate,
    Object? startMinute = _keep,
    Object? durationMin = _keep,
    RepeatKind? repeatKind,
    Object? rrule = _keep,
    Object? quotaPerWeek = _keep,
    List<int>? quotaPreferredDays,
    Object? endsOn = _keep,
    Object? endsAfterCount = _keep,
    String? seriesId,
    Object? timeZone = _keep,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? deletedAt = _keep,
    List<TaskReminder>? reminders,
  }) => Task(
    id: id ?? this.id,
    title: title ?? this.title,
    notes: identical(notes, _keep) ? this.notes : notes as String?,
    color: color ?? this.color,
    tag: identical(tag, _keep) ? this.tag : tag as String?,
    priority: priority ?? this.priority,
    allDay: allDay ?? this.allDay,
    startDate: startDate ?? this.startDate,
    startMinute: identical(startMinute, _keep)
        ? this.startMinute
        : startMinute as int?,
    durationMin: identical(durationMin, _keep)
        ? this.durationMin
        : durationMin as int?,
    repeatKind: repeatKind ?? this.repeatKind,
    rrule: identical(rrule, _keep) ? this.rrule : rrule as String?,
    quotaPerWeek: identical(quotaPerWeek, _keep)
        ? this.quotaPerWeek
        : quotaPerWeek as int?,
    quotaPreferredDays: quotaPreferredDays ?? this.quotaPreferredDays,
    endsOn: identical(endsOn, _keep) ? this.endsOn : endsOn as DateTime?,
    endsAfterCount: identical(endsAfterCount, _keep)
        ? this.endsAfterCount
        : endsAfterCount as int?,
    seriesId: seriesId ?? this.seriesId,
    timeZone: identical(timeZone, _keep) ? this.timeZone : timeZone as String?,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: identical(deletedAt, _keep)
        ? this.deletedAt
        : deletedAt as DateTime?,
    reminders: reminders ?? this.reminders,
  );
}

/// Stored per-occurrence state. Only occurrences that differ from the
/// generated default have a record.
enum RecordStatus { none, done, skipped, deleted }

class OccurrenceRecord {
  const OccurrenceRecord({
    required this.id,
    required this.taskId,
    required this.occurrenceDate,
    this.status = RecordStatus.none,
    this.completedAt,
    this.overrideDate,
    this.overrideStartMinute,
    this.overrideTitle,
    this.late = false,
  });

  final String id;
  final String taskId;

  /// The original generated date — the record's key.
  final DateTime occurrenceDate;
  final RecordStatus status;
  final DateTime? completedAt;
  final DateTime? overrideDate;
  final int? overrideStartMinute;
  final String? overrideTitle;

  /// Back-filled completion (marked done after the day was over).
  final bool late;

  OccurrenceRecord copyWith({
    String? taskId,
    RecordStatus? status,
    Object? completedAt = _keep,
    Object? overrideDate = _keep,
    Object? overrideStartMinute = _keep,
    Object? overrideTitle = _keep,
    bool? late,
  }) => OccurrenceRecord(
    id: id,
    taskId: taskId ?? this.taskId,
    occurrenceDate: occurrenceDate,
    status: status ?? this.status,
    completedAt: identical(completedAt, _keep)
        ? this.completedAt
        : completedAt as DateTime?,
    overrideDate: identical(overrideDate, _keep)
        ? this.overrideDate
        : overrideDate as DateTime?,
    overrideStartMinute: identical(overrideStartMinute, _keep)
        ? this.overrideStartMinute
        : overrideStartMinute as int?,
    overrideTitle: identical(overrideTitle, _keep)
        ? this.overrideTitle
        : overrideTitle as String?,
    late: late ?? this.late,
  );
}

enum OccurrenceStatus { pending, done, skipped, missed }

/// One generated instance of a task on a day, merged with its record.
class Occurrence {
  const Occurrence({
    required this.task,
    required this.originalDate,
    required this.date,
    required this.title,
    required this.status,
    this.startMinute,
    this.completedAt,
    this.late = false,
    this.record,
  });

  final Task task;
  final DateTime originalDate;

  /// Display date (override or original).
  final DateTime date;
  final int? startMinute;
  final String title;
  final OccurrenceStatus status;
  final DateTime? completedAt;
  final bool late;
  final OccurrenceRecord? record;

  String get key => '${task.id}|${Days.iso(originalDate)}';
  bool get isDone => status == OccurrenceStatus.done;
  bool get isTimed => !task.allDay && startMinute != null;
  int get durationMin => task.durationMin ?? 30;
  int? get endMinute => isTimed ? startMinute! + durationMin : null;
  DateTime? get startAt => isTimed ? Days.at(date, startMinute!) : null;
  DateTime? get endAt => isTimed ? Days.at(date, endMinute!) : null;

  /// §7 on-time: completed on the occurrence day and, for timed tasks,
  /// before start + duration. Back-fills are never on time.
  bool get onTime {
    final c = completedAt;
    if (!isDone || c == null || late) return false;
    if (!Days.same(c, date)) return false;
    final end = endAt;
    return end == null || !c.isAfter(end);
  }
}

/// Tasks plus all occurrence records — the input to every derived view.
class TaskSnapshot {
  const TaskSnapshot({required this.tasks, required this.records});
  static const empty = TaskSnapshot(tasks: [], records: []);

  final List<Task> tasks;
  final List<OccurrenceRecord> records;

  Task? taskById(String id) {
    for (final t in tasks) {
      if (t.id == id) return t;
    }
    return null;
  }
}
