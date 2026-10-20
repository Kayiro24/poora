import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Color, DartPluginRegistrant;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    hide Priority;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:poora/core/db/daos/tasks_dao.dart';
import 'package:poora/core/db/database.dart';
import 'package:poora/core/time/date_utils.dart';
import 'package:poora/features/tasks/domain/models.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';

/// Fixed notification ids; reminder ids are hashes (see [reminderId]).
abstract final class NotificationIds {
  static const focusEnd = 1;
  static const heldSummary = 2;
}

abstract final class Channels {
  static const reminders = 'task_reminders';
  static const focusEnd = 'focus_end';
}

const _actionDone = 'done';
const _actionSnooze = 'snooze';
const _categoryReminder = 'task_reminder';

/// Payload carried by every task reminder so actions work with the app closed.
class ReminderPayload {
  const ReminderPayload({
    required this.taskId,
    required this.date,
    required this.title,
    required this.body,
    required this.dbPath,
    this.siblings = const [],
  });

  final String taskId;
  final DateTime date;
  final String title;
  final String body;
  final String dbPath;

  /// Other reminder ids of the same occurrence — cancelled on "Done".
  final List<int> siblings;

  String encode() => jsonEncode({
    'type': 'reminder',
    'taskId': taskId,
    'date': Days.iso(date),
    'title': title,
    'body': body,
    'db': dbPath,
    'siblings': siblings,
  });

  static ReminderPayload? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final j = jsonDecode(raw) as Map<String, Object?>;
      if (j['type'] != 'reminder') return null;
      return ReminderPayload(
        taskId: j['taskId']! as String,
        date: Days.parse(j['date']! as String),
        title: j['title']! as String,
        body: j['body']! as String,
        dbPath: j['db']! as String,
        siblings: (j['siblings'] as List?)?.cast<int>() ?? const [],
      );
    } on Object {
      return null;
    }
  }
}

/// Deterministic, idempotent id for (task, occurrence date, reminder):
/// FNV-1a 32-bit, kept positive and clear of the fixed ids.
int reminderId(String taskId, DateTime date, String reminderKey) {
  var h = 0x811c9dc5;
  for (final c in '$taskId|${Days.iso(date)}|$reminderKey'.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0xffffffff;
  }
  final id = h & 0x7fffffff;
  return id < 100 ? id + 100 : id;
}

NotificationDetails _reminderDetails() => const NotificationDetails(
  android: AndroidNotificationDetails(
    Channels.reminders,
    'Task reminders',
    channelDescription: 'Reminders for scheduled tasks',
    color: Color(0xFFF2705E),
    actions: [
      AndroidNotificationAction(_actionDone, 'Done'),
      AndroidNotificationAction(_actionSnooze, 'Snooze 10 min'),
    ],
  ),
  iOS: DarwinNotificationDetails(categoryIdentifier: _categoryReminder),
);

NotificationDetails _summaryDetails() => const NotificationDetails(
  android: AndroidNotificationDetails(
    Channels.reminders,
    'Task reminders',
    channelDescription: 'Reminders for scheduled tasks',
    color: Color(0xFFF2705E),
  ),
  iOS: DarwinNotificationDetails(),
);

NotificationDetails _focusDetails() => const NotificationDetails(
  android: AndroidNotificationDetails(
    Channels.focusEnd,
    'Focus complete',
    channelDescription: 'Fires once when a focus phase ends',
    importance: Importance.high,
    color: Color(0xFF8FAF9C),
    sound: RawResourceAndroidNotificationSound('focus_chime'),
  ),
  iOS: DarwinNotificationDetails(),
);

/// Thin wrapper around flutter_local_notifications.
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  /// Foreground action handler; set by the app so writes go through the
  /// repository and UI streams update.
  Future<void> Function(String actionId, ReminderPayload p)? onAction;

  bool get _supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  Future<void> init() async {
    if (!_supported || _ready) return;
    await initTimeZones();
    await _plugin.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings('@drawable/ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          notificationCategories: [
            DarwinNotificationCategory(
              _categoryReminder,
              actions: [
                DarwinNotificationAction.plain(_actionDone, 'Done'),
                DarwinNotificationAction.plain(_actionSnooze, 'Snooze 10 min'),
              ],
            ),
          ],
        ),
      ),
      onDidReceiveNotificationResponse: _onResponse,
      onDidReceiveBackgroundNotificationResponse: notificationBackgroundHandler,
    );
    await _android?.createNotificationChannel(
      const AndroidNotificationChannel(
        Channels.reminders,
        'Task reminders',
        description: 'Reminders for scheduled tasks',
      ),
    );
    await _android?.createNotificationChannel(
      const AndroidNotificationChannel(
        Channels.focusEnd,
        'Focus complete',
        description: 'Fires once when a focus phase ends',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('focus_chime'),
      ),
    );
    _ready = true;
  }

  static Future<void> initTimeZones() async {
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } on Object {
      tz.setLocalLocation(tz.UTC);
    }
  }

  static String get localZoneName => tz.local.name;

  Future<void> _onResponse(NotificationResponse r) async {
    final p = ReminderPayload.decode(r.payload);
    final action = r.actionId;
    if (p == null || action == null) return;
    final handler = onAction;
    if (handler != null) {
      await handler(action, p);
    } else {
      await handleReminderAction(action, p, this);
    }
  }

  // --- Permissions --------------------------------------------------------

  Future<bool> notificationsEnabled() async {
    if (!_supported) return false;
    if (Platform.isAndroid) return await _android?.areNotificationsEnabled() ?? false;
    final p = await _ios?.checkPermissions();
    return p?.isEnabled ?? false;
  }

  Future<bool> requestNotifications() async {
    if (!_supported) return false;
    if (Platform.isAndroid) {
      return await _android?.requestNotificationsPermission() ?? false;
    }
    return await _ios?.requestPermissions(alert: true, sound: true, badge: true) ??
        false;
  }

  /// Android 12+: exact alarms. Always true elsewhere.
  Future<bool> canScheduleExact() async {
    if (!_supported || !Platform.isAndroid) return true;
    return await _android?.canScheduleExactNotifications() ?? true;
  }

  Future<bool> requestExact() async {
    if (!_supported || !Platform.isAndroid) return true;
    await _android?.requestExactAlarmsPermission();
    return canScheduleExact();
  }

  // --- Scheduling ---------------------------------------------------------

  Future<List<PendingNotificationRequest>> pending() async =>
      _supported ? _plugin.pendingNotificationRequests() : const [];

  Future<void> scheduleReminder({
    required int id,
    required DateTime at,
    required ReminderPayload payload,
    required bool exact,
  }) async {
    if (!_supported) return;
    await _plugin.zonedSchedule(
      id: id,
      title: payload.title,
      body: payload.body,
      scheduledDate: tz.TZDateTime.from(at, tz.local),
      notificationDetails: _reminderDetails(),
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload.encode(),
    );
  }

  Future<void> cancel(int id) async {
    if (_supported) await _plugin.cancel(id: id);
  }

  /// The one notification allowed around focus: fires at phase end.
  Future<void> scheduleFocusEnd({
    required DateTime at,
    required String title,
    required String body,
    required bool exact,
  }) async {
    if (!_supported) return;
    await _plugin.zonedSchedule(
      id: NotificationIds.focusEnd,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(at, tz.local),
      notificationDetails: _focusDetails(),
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelFocusEnd() => cancel(NotificationIds.focusEnd);

  /// Cancels every pending and shown notification (Delete all data).
  Future<void> cancelAll() async {
    if (_supported) await _plugin.cancelAll();
  }

  Future<void> showHeldSummary(String title, String body) async {
    if (!_supported) return;
    await _plugin.show(
      id: NotificationIds.heldSummary,
      title: title,
      body: body,
      notificationDetails: _summaryDetails(),
    );
  }

  Future<void> snooze(ReminderPayload p) async {
    if (!_supported) return;
    await _plugin.zonedSchedule(
      id: reminderId(p.taskId, p.date, 'snooze'),
      title: p.title,
      body: p.body,
      scheduledDate: tz.TZDateTime.now(tz.UTC).add(const Duration(minutes: 10)),
      notificationDetails: _reminderDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: p.encode(),
    );
  }
}

/// Done/Snooze handling shared by the foreground and background paths.
/// "Done" writes the occurrence record straight into the database file.
Future<void> handleReminderAction(
  String action,
  ReminderPayload p,
  NotificationService service,
) async {
  if (action == _actionSnooze) {
    await service.snooze(p);
    return;
  }
  if (action != _actionDone) return;
  final db = AppDatabase.atPath(p.dbPath);
  try {
    final dao = TasksDao(db);
    final existing = await dao.record(p.taskId, p.date);
    final now = DateTime.now();
    await dao.upsertRecord(
      (existing ??
              OccurrenceRecord(
                id: const Uuid().v4(),
                taskId: p.taskId,
                occurrenceDate: p.date,
              ))
          .copyWith(status: RecordStatus.done, completedAt: now),
    );
  } finally {
    await db.close();
  }
  for (final id in p.siblings) {
    await service.cancel(id);
  }
}

/// Runs in a background isolate when an action is tapped with the app closed.
@pragma('vm:entry-point')
Future<void> notificationBackgroundHandler(NotificationResponse r) async {
  DartPluginRegistrant.ensureInitialized();
  final p = ReminderPayload.decode(r.payload);
  final action = r.actionId;
  if (p == null || action == null) return;
  tzdata.initializeTimeZones();
  await handleReminderAction(action, p, NotificationService());
}
