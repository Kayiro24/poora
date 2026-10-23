/// Interruption tracking for focus sessions (Regain-style). Pure Dart.
///
/// Distinguishes, per session:
/// * **focus time**: completed focus-phase time (from the timer engine);
/// * **paused time**: time the user explicitly paused (timer engine);
/// * **away time / interruptions**: time spent outside the app while a focus
///   phase was running, and how many times that happened;
/// * **app usage time**: session wall time minus away time.
library;

class FocusTracking {
  const FocusTracking({
    this.interruptions = 0,
    this.awayMs = 0,
    this.awayStartedAt,
    this.awayCapAt,
    this.lastSeenAt,
  });

  static const empty = FocusTracking();

  final int interruptions;
  final int awayMs;

  /// Set while the user is outside the app during a running focus phase.
  final DateTime? awayStartedAt;

  /// Away time can't extend past the end of the focus phase that was running
  /// when the user left (breaks aren't interruptions).
  final DateTime? awayCapAt;

  /// Heartbeat while visible — bounds the gap if the process dies on screen.
  final DateTime? lastSeenAt;

  bool get isAway => awayStartedAt != null;

  FocusTracking copyWith({
    int? interruptions,
    int? awayMs,
    Object? awayStartedAt = _keep,
    Object? awayCapAt = _keep,
    Object? lastSeenAt = _keep,
  }) => FocusTracking(
    interruptions: interruptions ?? this.interruptions,
    awayMs: awayMs ?? this.awayMs,
    awayStartedAt: identical(awayStartedAt, _keep) ? this.awayStartedAt : awayStartedAt as DateTime?,
    awayCapAt: identical(awayCapAt, _keep) ? this.awayCapAt : awayCapAt as DateTime?,
    lastSeenAt: identical(lastSeenAt, _keep) ? this.lastSeenAt : lastSeenAt as DateTime?,
  );
}

const Object _keep = Object();

abstract final class FocusTracker {
  /// Shorter trips (pulling down the notification shade) don't count.
  static const minAway = Duration(seconds: 2);

  /// Without a heartbeat for this long, a recovered session counts the gap
  /// as time away (the app was killed or the phone restarted while visible).
  static const heartbeatGap = Duration(seconds: 90);

  /// The app left the foreground. Only counts while a focus phase runs;
  /// [focusPhaseEndsAt] is that phase's wall-clock end.
  static FocusTracking leave(FocusTracking t, DateTime now, {required DateTime? focusPhaseEndsAt}) {
    if (t.isAway || focusPhaseEndsAt == null || !now.isBefore(focusPhaseEndsAt)) return t;
    return t.copyWith(awayStartedAt: now, awayCapAt: focusPhaseEndsAt);
  }

  /// The app is back in the foreground.
  static FocusTracking returnTo(FocusTracking t, DateTime now) {
    final start = t.awayStartedAt;
    if (start == null) return t.copyWith(lastSeenAt: now);
    final cap = t.awayCapAt;
    final end = cap != null && cap.isBefore(now) ? cap : now;
    final away = end.difference(start);
    if (away < minAway) {
      return t.copyWith(awayStartedAt: null, awayCapAt: null, lastSeenAt: now);
    }
    return t.copyWith(
      interruptions: t.interruptions + 1,
      awayMs: t.awayMs + away.inMilliseconds,
      awayStartedAt: null,
      awayCapAt: null,
      lastSeenAt: now,
    );
  }

  static FocusTracking heartbeat(FocusTracking t, DateTime now) =>
      t.isAway ? t : t.copyWith(lastSeenAt: now);

  /// Session restored after the process died (or the phone restarted).
  /// [focusPhaseEndsAt] is the end of the focus phase that was running at
  /// the last heartbeat, if any.
  static FocusTracking recover(FocusTracking t, DateTime now, {required DateTime? focusPhaseEndsAt}) {
    if (t.isAway) return returnTo(t, now);
    final seen = t.lastSeenAt;
    if (seen == null || now.difference(seen) < heartbeatGap || focusPhaseEndsAt == null) {
      return t.copyWith(lastSeenAt: now);
    }
    final gap = leave(t, seen, focusPhaseEndsAt: focusPhaseEndsAt);
    return returnTo(gap, now);
  }

  /// Closes an open away interval when the session ends.
  static FocusTracking finish(FocusTracking t, DateTime now) => t.isAway ? returnTo(t, now) : t;

  /// Time the app was in use during the session (wall time minus away time).
  static int appUsageMs({required DateTime startedAt, required DateTime endedAt, required int awayMs}) {
    final wall = endedAt.difference(startedAt).inMilliseconds;
    return (wall - awayMs).clamp(0, wall);
  }
}
