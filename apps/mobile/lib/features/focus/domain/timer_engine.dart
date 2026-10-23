/// Wall-clock Pomodoro engine (§1, §4.3). Pure Dart.
///
/// State is `phaseStartedAt + phaseDurationMs + pausedAccumMs`; remaining
/// time is always derived from the clock, so backgrounding or a process kill
/// never desynchronises the timer. [TimerEngine.tick] replays any phases that
/// ended while the app was away.
library;

enum FocusPhase { focus, shortBreak, longBreak }

class FocusConfig {
  const FocusConfig({
    this.focusMin = 25,
    this.shortMin = 5,
    this.longMin = 15,
    this.longEvery = 4,
  });

  final int focusMin;
  final int shortMin;
  final int longMin;

  /// Focus sessions per cycle; the long break follows the last one.
  final int longEvery;

  int durationMs(FocusPhase p) =>
      switch (p) {
        FocusPhase.focus => focusMin,
        FocusPhase.shortBreak => shortMin,
        FocusPhase.longBreak => longMin,
      } *
      60000;

  /// Planned length of a full cycle (all focus phases and breaks).
  Duration get cycleDuration => Duration(
    minutes: focusMin * longEvery + shortMin * (longEvery - 1) + longMin,
  );

  String get label => '$focusMin / $shortMin';

  FocusConfig copyWith({
    int? focusMin,
    int? shortMin,
    int? longMin,
    int? longEvery,
  }) => FocusConfig(
    focusMin: focusMin ?? this.focusMin,
    shortMin: shortMin ?? this.shortMin,
    longMin: longMin ?? this.longMin,
    longEvery: longEvery ?? this.longEvery,
  );

  Map<String, int> toJson() => {
    'focusMin': focusMin,
    'shortMin': shortMin,
    'longMin': longMin,
    'longEvery': longEvery,
  };

  factory FocusConfig.fromJson(Map<String, Object?> j) => FocusConfig(
    focusMin: (j['focusMin'] as int?) ?? 25,
    shortMin: (j['shortMin'] as int?) ?? 5,
    longMin: (j['longMin'] as int?) ?? 15,
    longEvery: (j['longEvery'] as int?) ?? 4,
  );

  @override
  bool operator ==(Object other) =>
      other is FocusConfig &&
      other.focusMin == focusMin &&
      other.shortMin == shortMin &&
      other.longMin == longMin &&
      other.longEvery == longEvery;

  @override
  int get hashCode => Object.hash(focusMin, shortMin, longMin, longEvery);
}

/// Immutable timer state; exactly what is persisted for kill-recovery.
class TimerState {
  const TimerState({
    required this.phase,
    required this.focusIndex,
    required this.phaseDurationMs,
    this.phaseStartedAt,
    this.pausedAt,
    this.pausedAccumMs = 0,
    this.pausedTotalMs = 0,
    this.focusMsCompleted = 0,
    this.phasesCompleted = 0,
    this.cycleComplete = false,
  });

  final FocusPhase phase;

  /// 1-based index of the current (or just finished) focus phase.
  final int focusIndex;

  /// Null while waiting for the user to start the phase (auto-start off).
  final DateTime? phaseStartedAt;
  final int phaseDurationMs;
  final DateTime? pausedAt;
  final int pausedAccumMs;

  /// Paused time across the whole session (excluding a pause still open).
  final int pausedTotalMs;

  /// Focus time from fully or partially completed earlier focus phases.
  final int focusMsCompleted;
  final int phasesCompleted;
  final bool cycleComplete;

  bool get isPaused => pausedAt != null;
  bool get isWaiting => phaseStartedAt == null && !cycleComplete;
  bool get isRunning => phaseStartedAt != null && !isPaused && !cycleComplete;
  bool get isFocus => phase == FocusPhase.focus;

  TimerState copyWith({
    FocusPhase? phase,
    int? focusIndex,
    Object? phaseStartedAt = _keep,
    int? phaseDurationMs,
    Object? pausedAt = _keep,
    int? pausedAccumMs,
    int? pausedTotalMs,
    int? focusMsCompleted,
    int? phasesCompleted,
    bool? cycleComplete,
  }) => TimerState(
    phase: phase ?? this.phase,
    focusIndex: focusIndex ?? this.focusIndex,
    phaseStartedAt: identical(phaseStartedAt, _keep)
        ? this.phaseStartedAt
        : phaseStartedAt as DateTime?,
    phaseDurationMs: phaseDurationMs ?? this.phaseDurationMs,
    pausedAt: identical(pausedAt, _keep) ? this.pausedAt : pausedAt as DateTime?,
    pausedAccumMs: pausedAccumMs ?? this.pausedAccumMs,
    pausedTotalMs: pausedTotalMs ?? this.pausedTotalMs,
    focusMsCompleted: focusMsCompleted ?? this.focusMsCompleted,
    phasesCompleted: phasesCompleted ?? this.phasesCompleted,
    cycleComplete: cycleComplete ?? this.cycleComplete,
  );
}

const Object _keep = Object();

/// A phase that finished during a [TimerEngine.tick].
class PhaseEnded {
  const PhaseEnded(this.phase, this.endedAt);
  final FocusPhase phase;
  final DateTime endedAt;
}

class TickResult {
  const TickResult(this.state, this.ended);
  final TimerState state;
  final List<PhaseEnded> ended;
}

class TimerEngine {
  const TimerEngine(
    this.config, {
    this.autoStartBreaks = true,
    this.autoStartFocus = false,
  });

  final FocusConfig config;
  final bool autoStartBreaks;
  final bool autoStartFocus;

  TimerState start(DateTime now) => TimerState(
    phase: FocusPhase.focus,
    focusIndex: 1,
    phaseStartedAt: now,
    phaseDurationMs: config.durationMs(FocusPhase.focus),
  );

  int elapsedMs(TimerState s, DateTime now) {
    final started = s.phaseStartedAt;
    if (started == null || s.cycleComplete) return 0;
    final until = s.pausedAt ?? now;
    final e = until.difference(started).inMilliseconds - s.pausedAccumMs;
    return e.clamp(0, s.phaseDurationMs);
  }

  int remainingMs(TimerState s, DateTime now) =>
      s.phaseDurationMs - elapsedMs(s, now);

  double progress(TimerState s, DateTime now) =>
      s.phaseDurationMs == 0 ? 1 : elapsedMs(s, now) / s.phaseDurationMs;

  /// Wall-clock end of the current phase, or null if not running.
  DateTime? phaseEndsAt(TimerState s) {
    final started = s.phaseStartedAt;
    if (started == null || s.isPaused || s.cycleComplete) return null;
    return started.add(
      Duration(milliseconds: s.phaseDurationMs + s.pausedAccumMs),
    );
  }

  /// Projected end of the whole cycle assuming phases auto-advance.
  DateTime projectedCycleEnd(TimerState s, DateTime now) {
    var ms = remainingMs(s, now);
    var phase = s.phase;
    var index = s.focusIndex;
    while (true) {
      final next = _next(phase, index);
      if (next == null) break;
      (phase, index) = next;
      ms += config.durationMs(phase);
    }
    return now.add(Duration(milliseconds: ms));
  }

  /// Total focus time so far, including the running focus phase.
  int focusMsSoFar(TimerState s, DateTime now) =>
      s.focusMsCompleted + (s.isFocus ? elapsedMs(s, now) : 0);

  /// Total paused time so far, including a pause that is still open.
  int pausedMsSoFar(TimerState s, DateTime now) =>
      s.pausedTotalMs + (s.pausedAt == null ? 0 : now.difference(s.pausedAt!).inMilliseconds);

  TimerState pause(TimerState s, DateTime now) =>
      s.isRunning ? s.copyWith(pausedAt: now) : s;

  TimerState resume(TimerState s, DateTime now) {
    final p = s.pausedAt;
    if (p == null) return s;
    final paused = now.difference(p).inMilliseconds;
    return s.copyWith(
      pausedAt: null,
      pausedAccumMs: s.pausedAccumMs + paused,
      pausedTotalMs: s.pausedTotalMs + paused,
    );
  }

  /// Starts a phase that is waiting for the user.
  TimerState startWaiting(TimerState s, DateTime now) =>
      s.isWaiting ? s.copyWith(phaseStartedAt: now, pausedAccumMs: 0) : s;

  /// Advances through every phase that has ended by [now].
  TickResult tick(TimerState s, DateTime now) {
    final ended = <PhaseEnded>[];
    var state = s;
    while (state.isRunning) {
      final end = phaseEndsAt(state)!;
      if (now.isBefore(end)) break;
      ended.add(PhaseEnded(state.phase, end));
      state = _advance(state, end, completedMs: state.phaseDurationMs);
    }
    return TickResult(state, ended);
  }

  /// Ends the current phase now and moves on (the "Skip phase" control).
  TickResult skip(TimerState s, DateTime now) {
    if (s.cycleComplete) return TickResult(s, const []);
    final done = elapsedMs(s, now);
    final resumed = resume(s, now);
    final next = _advance(resumed, now, completedMs: done, skipped: true);
    return TickResult(next, [PhaseEnded(s.phase, now)]);
  }

  TimerState _advance(
    TimerState s,
    DateTime endedAt, {
    required int completedMs,
    bool skipped = false,
  }) {
    final focusMs = s.isFocus ? s.focusMsCompleted + completedMs : s.focusMsCompleted;
    final phases = s.phasesCompleted + (skipped ? 0 : 1);
    final next = _next(s.phase, s.focusIndex);
    if (next == null) {
      return s.copyWith(
        focusMsCompleted: focusMs,
        phasesCompleted: phases,
        cycleComplete: true,
        phaseStartedAt: null,
        pausedAt: null,
      );
    }
    final (phase, index) = next;
    final auto = phase == FocusPhase.focus ? autoStartFocus : autoStartBreaks;
    return TimerState(
      phase: phase,
      focusIndex: index,
      phaseStartedAt: auto ? endedAt : null,
      phaseDurationMs: config.durationMs(phase),
      pausedTotalMs: s.pausedTotalMs,
      focusMsCompleted: focusMs,
      phasesCompleted: phases,
    );
  }

  (FocusPhase, int)? _next(FocusPhase phase, int index) => switch (phase) {
    // A zero-length long break means "no break": the cycle ends after focus
    // (used by focus-from-task).
    FocusPhase.focus when index >= config.longEvery && config.longMin == 0 => null,
    FocusPhase.focus when index >= config.longEvery => (FocusPhase.longBreak, index),
    FocusPhase.focus => (FocusPhase.shortBreak, index),
    FocusPhase.shortBreak => (FocusPhase.focus, index + 1),
    FocusPhase.longBreak => null,
  };
}
