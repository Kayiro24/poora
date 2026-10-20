import 'dart:async';

import 'package:poora/core/db/daos/settings_dao.dart';
import 'package:poora/core/db/daos/tasks_dao.dart';
import 'package:poora/core/db/database.dart';
import 'package:poora/core/notifications/notification_service.dart';
import 'package:poora/core/time/clock.dart';
import 'package:poora/core/time/date_utils.dart';
import 'package:poora/features/tasks/domain/models.dart';
import 'package:poora/features/tasks/domain/occurrence_generator.dart';

class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.fireAt,
    required this.payload,
  });
  final int id;
  final DateTime fireAt;
  final ReminderPayload payload;
}

/// Pure planning of the rolling reminder window (§6).
abstract final class ReminderPlanner {
  static const windowDays = 14;

  /// iOS caps pending notifications at 64; leave room for focus/summary.
  static const maxPending = 60;

  static List<PlannedReminder> plan({
    required TaskSnapshot snapshot,
    required OccurrenceGenerator generator,
    required DateTime now,
    required String dbPath,
    required String Function(int minute) timeLabel,
  }) {
    final today = Days.of(now);
    final horizon = now.add(const Duration(days: windowDays));
    final occurrences = generator.generate(
      snapshot: snapshot,
      range: DateRange(Days.add(today, -1), Days.add(today, windowDays)),
      today: today,
    );
    final out = <PlannedReminder>[];
    for (final o in occurrences) {
      if (o.status != OccurrenceStatus.pending || o.task.reminders.isEmpty) {
        continue;
      }
      final t = o.task;
      // Quota tasks: daily reminder only on preferred days (if any) while the
      // week's quota is unmet — the generator already hides met weeks.
      if (t.isQuota &&
          t.quotaPreferredDays.isNotEmpty &&
          !t.quotaPreferredDays.contains(o.date.weekday)) {
        continue;
      }
      final body = [
        if (o.isTimed) timeLabel(o.startMinute!) else 'All day',
        if (t.tag != null && t.tag!.trim().isNotEmpty) t.tag!.trim(),
      ].join(' · ');
      final ids = [
        for (final r in t.reminders) reminderId(t.id, o.originalDate, r.id),
      ];
      for (var i = 0; i < t.reminders.length; i++) {
        final fire = t.reminders[i].fireAt(o.date, o.startMinute);
        if (fire == null || !fire.isAfter(now) || fire.isAfter(horizon)) {
          continue;
        }
        out.add(
          PlannedReminder(
            id: ids[i],
            fireAt: fire,
            payload: ReminderPayload(
              taskId: t.id,
              date: o.originalDate,
              title: o.title,
              body: body,
              dbPath: dbPath,
              siblings: [for (final x in ids) if (x != ids[i]) x],
            ),
          ),
        );
      }
    }
    out.sort((a, b) => a.fireAt.compareTo(b.fireAt));
    return out.length > maxPending ? out.sublist(0, maxPending) : out;
  }
}

/// Applies the plan to the OS, holding reminders during focus (§4.4).
class ReminderScheduler {
  ReminderScheduler({
    required this.service,
    required this.tasksDao,
    required this.settingsDao,
    required this.clock,
    required this.dbPath,
    required this.mondayFirst,
    required this.timeLabel,
  });

  final NotificationService service;
  final TasksDao tasksDao;
  final SettingsDao settingsDao;
  final Clock clock;
  final String dbPath;
  bool Function() mondayFirst;
  String Function(int minute) timeLabel;

  /// While set, reminders firing before this instant are held, not scheduled.
  DateTime? holdUntil;

  /// Whether the last pass had to fall back to inexact alarms.
  bool exactDenied = false;

  Future<void> _queue = Future.value();

  /// Serialised so overlapping triggers never interleave.
  Future<void> reschedule() => _queue = _queue.then((_) => _run()).catchError((_) {});

  Future<void> _run() async {
    final now = clock.now();
    final snapshot = await tasksDao.loadSnapshot();
    final plan = ReminderPlanner.plan(
      snapshot: snapshot,
      generator: OccurrenceGenerator(mondayFirst: mondayFirst()),
      now: now,
      dbPath: dbPath,
      timeLabel: timeLabel,
    );
    final exact = await service.canScheduleExact();
    exactDenied = !exact;
    final hold = holdUntil;
    final desired = <int>{};
    for (final p in plan) {
      if (hold != null && !p.fireAt.isAfter(hold)) {
        await settingsDao.hold(
          HeldReminderRow(
            notificationId: p.id,
            taskId: p.payload.taskId,
            occurrenceDate: Days.iso(p.payload.date),
            originalFireAt: p.fireAt.millisecondsSinceEpoch,
            title: p.payload.title,
          ),
        );
        continue;
      }
      desired.add(p.id);
      await service.scheduleReminder(
        id: p.id,
        at: p.fireAt,
        payload: p.payload,
        exact: exact,
      );
    }
    for (final pending in await service.pending()) {
      final payload = ReminderPayload.decode(pending.payload);
      if (payload == null || desired.contains(pending.id)) continue;
      // Keep user snoozes, except while focus holds every reminder.
      final snoozeId = reminderId(payload.taskId, payload.date, 'snooze');
      if (pending.id == snoozeId && hold == null) continue;
      await service.cancel(pending.id);
    }
  }

  /// Count of reminders currently held.
  Future<int> heldCount() async => (await settingsDao.heldReminders()).length;

  /// Ends holding: delivers anything that came due as one grouped
  /// notification and reschedules the rest (§4.4 step 4).
  Future<void> releaseHeld() async {
    holdUntil = null;
    final now = clock.now().millisecondsSinceEpoch;
    final held = await settingsDao.heldReminders();
    final due = held.where((h) => h.originalFireAt <= now).toList();
    final uniqueTasks = {for (final h in due) '${h.taskId}|${h.occurrenceDate}': h};
    if (uniqueTasks.isNotEmpty) {
      final n = uniqueTasks.length;
      await service.showHeldSummary(
        'While you focused: $n task${n == 1 ? ' was' : 's were'} due',
        uniqueTasks.values.map((h) => h.title).take(5).join(' · '),
      );
    }
    await settingsDao.clearHeld();
    await reschedule();
  }
}
