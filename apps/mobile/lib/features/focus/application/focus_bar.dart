import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poora/core/platform/focus_bar_service.dart';
import 'package:poora/core/providers.dart';
import 'package:poora/core/time/date_utils.dart';
import 'package:poora/features/focus/application/focus_controller.dart';
import 'package:poora/features/focus/application/focus_draft.dart';
import 'package:poora/features/focus/domain/focus_history.dart';
import 'package:poora/features/focus/domain/focus_session.dart';
import 'package:poora/features/settings/settings_controller.dart';

/// The focus bar's contents: finished focus for the last two weeks plus the
/// live session, recomputed whenever sessions, settings or the timer change.
final focusBarDataProvider = Provider<FocusBarData>((ref) {
  final settings = ref.watch(settingsProvider);
  final sessions = ref.watch(focusSessionsProvider).value ?? const <FocusSessionRecord>[];
  final today = ref.watch(todayProvider);
  final session = ref.watch(focusControllerProvider.select((s) => s.session));
  final range = DateRange(Days.add(today, -13), today);
  final byDay = FocusHistory.minutesByDay(sessions, range);

  var liveMs = 0;
  DateTime? since;
  int? cap;
  DateTime? endsAt;
  if (session != null) {
    final eng = ref.read(focusControllerProvider.notifier).engineFor(session.config);
    final now = DateTime.now();
    final t = session.timer;
    liveMs = eng.focusMsSoFar(t, now);
    if (t.isFocus && t.isRunning) {
      since = now;
      cap = t.focusMsCompleted + t.phaseDurationMs;
      endsAt = eng.phaseEndsAt(t);
    }
  }
  return FocusBarData(
    enabled: settings.focusBar,
    goalMin: settings.dailyFocusGoalMin,
    mondayFirst: settings.mondayFirst,
    streak: FocusHistory.goalStreak(sessions, settings.dailyFocusGoalMin, today),
    minutesByDay: {for (final e in byDay.entries) Days.iso(e.key): e.value},
    liveFocusMs: liveMs,
    liveSince: since,
    liveCapMs: cap,
    liveEndsAt: endsAt,
    strict: session?.strict ?? false,
  );
});
