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
  });

  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final FocusConfig config;
  final int focusMsCompleted;
  final int phasesCompleted;
  final bool endedEarly;
  final String? linkedTaskId;
  final DateTime? linkedOccurrenceDate;

  double get focusMinutes => focusMsCompleted / 60000;
}
