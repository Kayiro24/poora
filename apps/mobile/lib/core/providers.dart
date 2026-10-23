import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poora/core/db/daos/focus_dao.dart';
import 'package:poora/core/db/daos/settings_dao.dart';
import 'package:poora/core/db/daos/tasks_dao.dart';
import 'package:poora/core/db/database.dart';
import 'package:poora/core/notifications/notification_service.dart';
import 'package:poora/core/notifications/reminder_scheduler.dart';
import 'package:poora/core/platform/dnd_service.dart';
import 'package:poora/core/platform/feedback.dart';
import 'package:poora/core/platform/guard_service.dart';
import 'package:poora/core/platform/usage_service.dart';
import 'package:poora/core/time/clock.dart';
import 'package:poora/core/time/date_utils.dart';
import 'package:poora/core/time/format.dart';
import 'package:poora/features/settings/settings_controller.dart';

/// Overridden in `main` with the opened database.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider must be overridden'),
);

/// Database file path (passed to notification payloads for background writes).
final dbPathProvider = Provider<String>((ref) => '');

final clockProvider = Provider<Clock>((ref) => const SystemClock());

final tasksDaoProvider = Provider((ref) => TasksDao(ref.watch(databaseProvider)));
final focusDaoProvider = Provider((ref) => FocusDao(ref.watch(databaseProvider)));
final settingsDaoProvider = Provider(
  (ref) => SettingsDao(ref.watch(databaseProvider)),
);

final notificationServiceProvider = Provider((ref) => NotificationService());
final dndServiceProvider = Provider((ref) => DndService());
final usageServiceProvider = Provider((ref) => UsageService());
final guardServiceProvider = Provider((ref) => GuardService());
final feedbackProvider = Provider(
  (ref) => AppFeedback(() => ref.read(settingsProvider)),
);

final reminderSchedulerProvider = Provider((ref) {
  return ReminderScheduler(
    service: ref.watch(notificationServiceProvider),
    tasksDao: ref.watch(tasksDaoProvider),
    settingsDao: ref.watch(settingsDaoProvider),
    clock: ref.watch(clockProvider),
    dbPath: ref.watch(dbPathProvider),
    mondayFirst: () => ref.read(settingsProvider).mondayFirst,
    timeLabel: (m) => Fmt.minute(m, use24h: ref.read(settingsProvider).use24h),
  );
});

/// Today's date; ticks over at local midnight and on app resume.
final todayProvider = NotifierProvider<TodayNotifier, DateTime>(
  TodayNotifier.new,
);

class TodayNotifier extends Notifier<DateTime> {
  Timer? _timer;

  @override
  DateTime build() {
    ref.onDispose(() => _timer?.cancel());
    final now = ref.read(clockProvider).now();
    _arm(now);
    return Days.of(now);
  }

  void _arm(DateTime now) {
    _timer?.cancel();
    final next = DateTime(now.year, now.month, now.day + 1, 0, 0, 1);
    _timer = Timer(next.difference(now), refresh);
  }

  void refresh() {
    final now = ref.read(clockProvider).now();
    final d = Days.of(now);
    if (d != state) state = d;
    _arm(now);
  }
}

/// Ticks every second — for countdowns ("starts in 0:42:10") and "now" lines.
final secondTickerProvider = StreamProvider<DateTime>((ref) {
  final clock = ref.watch(clockProvider);
  return Stream.periodic(const Duration(seconds: 1), (_) => clock.now());
});

/// Current time, refreshed every 30 s — cheap enough for "now" markers.
final nowProvider = StreamProvider<DateTime>((ref) async* {
  final clock = ref.watch(clockProvider);
  yield clock.now();
  yield* Stream.periodic(const Duration(seconds: 30), (_) => clock.now());
});
