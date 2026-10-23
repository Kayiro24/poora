import 'package:poora/features/focus/domain/focus_tracker.dart';
import 'package:poora/features/focus/domain/timer_engine.dart';

/// A finished (or ended-early) focus cycle, as stored in `focus_sessions`.
class FocusSessionRecord {
  const FocusSessionRecord({
    required this.id,
    required this.startedAt,
    required this.config,
    this.endedAt,
    this.focusMsCompleted = 0,
    this.phasesCompleted = 0,
    this.endedEarly = false,
    this.linkedTaskId,
    this.linkedOccurrenceDate,
    this.pausedMs = 0,
    this.awayMs = 0,
    this.interruptions = 0,
    this.distractions = const {},
  });

  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final FocusConfig config;

  /// Focus-phase time actually completed (breaks and pauses excluded).
  final int focusMsCompleted;
  final int phasesCompleted;
  final bool endedEarly;
  final String? linkedTaskId;
  final DateTime? linkedOccurrenceDate;

  /// Time explicitly paused.
  final int pausedMs;

  /// Time spent outside the app while a focus phase was running.
  final int awayMs;

  /// How many times the user left the app during focus.
  final int interruptions;

  /// Android package → ms spent in that (monitored) app during the session.
  final Map<String, int> distractions;

  double get focusMinutes => focusMsCompleted / 60000;

  /// Session wall time minus time away.
  int get appUsageMs => endedAt == null
      ? 0
      : FocusTracker.appUsageMs(startedAt: startedAt, endedAt: endedAt!, awayMs: awayMs);

  int get distractionMs => distractions.values.fold(0, (a, b) => a + b);
}
