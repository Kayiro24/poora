import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poora/app_router.dart';
import 'package:poora/core/app_info.dart';
import 'package:poora/core/notifications/notification_service.dart';
import 'package:poora/core/providers.dart';
import 'package:poora/core/theme/theme.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/time/date_utils.dart';
import 'package:poora/features/focus/application/focus_bar.dart';
import 'package:poora/features/focus/application/focus_controller.dart';
import 'package:poora/features/focus/ui/recovery_dialog.dart';
import 'package:poora/features/settings/permissions_list.dart';
import 'package:poora/features/tasks/application/tasks_providers.dart';

class PooraApp extends ConsumerStatefulWidget {
  const PooraApp({super.key});

  @override
  ConsumerState<PooraApp> createState() => _PooraAppState();
}

class _PooraAppState extends ConsumerState<PooraApp>
    with WidgetsBindingObserver {
  Timer? _rescheduleDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    ref.read(notificationServiceProvider).onAction = _onNotificationAction;
    // Android focus bar: today's focus and the week, kept in the notification shade.
    ref.listenManual(
      focusBarDataProvider,
      (_, d) => unawaited(ref.read(focusBarServiceProvider).update(d)),
      fireImmediately: true,
    );
    // Interrupted focus sessions are checked when the splash finishes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(reminderSchedulerProvider).reschedule());
      // Trash keeps deleted tasks for 30 days (like Google Calendar).
      unawaited(ref.read(tasksRepositoryProvider).purgeOldTrash());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _rescheduleDebounce?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final focus = ref.read(focusControllerProvider.notifier);
    switch (state) {
      case AppLifecycleState.resumed:
        ref.read(todayProvider.notifier).refresh();
        ref.invalidate(specialPermissionsProvider);
        unawaited(focus.onForeground());
        unawaited(ref.read(reminderSchedulerProvider).reschedule());
      case AppLifecycleState.paused:
        unawaited(focus.onBackground());
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  /// Foreground notification actions go through the repository so every
  /// stream updates immediately.
  Future<void> _onNotificationAction(String action, ReminderPayload p) async {
    final notif = ref.read(notificationServiceProvider);
    if (action != 'done') return handleReminderAction(action, p, notif);
    final occ = ref
        .read(occurrencesProvider(DateRange.day(p.date)))
        .where((o) => o.task.id == p.taskId && o.originalDate == p.date);
    if (occ.isEmpty) return handleReminderAction(action, p, notif);
    await ref.read(tasksRepositoryProvider).setDone(occ.first, done: true);
    for (final id in p.siblings) {
      await notif.cancel(id);
    }
  }

  void _scheduleReschedule() {
    _rescheduleDebounce?.cancel();
    _rescheduleDebounce = Timer(
      const Duration(milliseconds: 600),
      () => ref.read(reminderSchedulerProvider).reschedule(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Any task/record change recomputes the rolling reminder window.
    ref
      ..listen(taskSnapshotProvider, (_, _) => _scheduleReschedule())
      ..listen(focusControllerProvider.select((s) => s.recovery), (_, next) {
        final ctx = rootNavigatorKey.currentContext;
        if (next != null && ctx != null) showRecoveryDialog(ctx, ref);
      })
      ..listen(focusControllerProvider.select((s) => s.session?.id), (prev, next) {
        if (prev == null && next != null) appRouter.push(Routes.focusRun);
      });

    return MaterialApp.router(
      title: AppInfo.name,
      debugShowCheckedModeBanner: false,
      theme: buildDarkTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.dark,
      routerConfig: appRouter,
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Tokens.bg,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: child!,
      ),
    );
  }
}
