/**
 * Wall-clock Pomodoro engine — a port of the mobile app's TimerEngine.
 * State is phaseStartedAt + durations + paused time; remaining time always
 * comes from the clock, so a closed tab or sleeping laptop can't desync it.
 * All instants are epoch milliseconds.
 */
export type FocusPhase = 'focus' | 'shortBreak' | 'longBreak';

export interface FocusConfig {
  focusMin: number;
  shortMin: number;
  longMin: number;
  /** Focus sessions per cycle; the long break follows the last one. */
  longEvery: number;
}

export const defaultFocus: FocusConfig = { focusMin: 25, shortMin: 5, longMin: 15, longEvery: 4 };

export const FocusCfg = {
  durationMs: (c: FocusConfig, p: FocusPhase) =>
    (p === 'focus' ? c.focusMin : p === 'shortBreak' ? c.shortMin : c.longMin) * 60000,
  cycleMs: (c: FocusConfig) => (c.focusMin * c.longEvery + c.shortMin * (c.longEvery - 1) + c.longMin) * 60000,
  label: (c: FocusConfig) => `${c.focusMin} / ${c.shortMin}`,
  equal: (a: FocusConfig, b: FocusConfig) =>
    a.focusMin === b.focusMin && a.shortMin === b.shortMin && a.longMin === b.longMin && a.longEvery === b.longEvery,
};

export interface TimerState {
  phase: FocusPhase;
  /** 1-based index of the current (or just finished) focus phase. */
  focusIndex: number;
  /** Null while waiting for the user to start the phase. */
  phaseStartedAt: number | null;
  phaseDurationMs: number;
  pausedAt: number | null;
  pausedAccumMs: number;
  focusMsCompleted: number;
  phasesCompleted: number;
  cycleComplete: boolean;
}

export const TimerStates = {
  isPaused: (s: TimerState) => s.pausedAt != null,
  isWaiting: (s: TimerState) => s.phaseStartedAt == null && !s.cycleComplete,
  isRunning: (s: TimerState) => s.phaseStartedAt != null && s.pausedAt == null && !s.cycleComplete,
  isFocus: (s: TimerState) => s.phase === 'focus',
};

export interface PhaseEnded {
  phase: FocusPhase;
  endedAt: number;
}

export interface TickResult {
  state: TimerState;
  ended: PhaseEnded[];
}

export class TimerEngine {
  constructor(
    readonly config: FocusConfig,
    readonly autoStartBreaks = true,
    readonly autoStartFocus = false,
  ) {}

  start(now: number): TimerState {
    return {
      phase: 'focus',
      focusIndex: 1,
      phaseStartedAt: now,
      phaseDurationMs: FocusCfg.durationMs(this.config, 'focus'),
      pausedAt: null,
      pausedAccumMs: 0,
      focusMsCompleted: 0,
      phasesCompleted: 0,
      cycleComplete: false,
    };
  }

  elapsedMs(s: TimerState, now: number): number {
    if (s.phaseStartedAt == null || s.cycleComplete) return 0;
    const until = s.pausedAt ?? now;
    const e = until - s.phaseStartedAt - s.pausedAccumMs;
    return Math.min(Math.max(e, 0), s.phaseDurationMs);
  }

  remainingMs = (s: TimerState, now: number) => s.phaseDurationMs - this.elapsedMs(s, now);

  progress = (s: TimerState, now: number) => (s.phaseDurationMs === 0 ? 1 : this.elapsedMs(s, now) / s.phaseDurationMs);

  phaseEndsAt(s: TimerState): number | null {
    if (s.phaseStartedAt == null || s.pausedAt != null || s.cycleComplete) return null;
    return s.phaseStartedAt + s.phaseDurationMs + s.pausedAccumMs;
  }

  projectedCycleEnd(s: TimerState, now: number): number {
    let ms = this.remainingMs(s, now);
    let phase = s.phase;
    let index = s.focusIndex;
    for (;;) {
      const next = this.next(phase, index);
      if (!next) break;
      [phase, index] = next;
      ms += FocusCfg.durationMs(this.config, phase);
    }
    return now + ms;
  }

  focusMsSoFar = (s: TimerState, now: number) =>
    s.focusMsCompleted + (s.phase === 'focus' ? this.elapsedMs(s, now) : 0);

  pause = (s: TimerState, now: number): TimerState => (TimerStates.isRunning(s) ? { ...s, pausedAt: now } : s);

  resume(s: TimerState, now: number): TimerState {
    if (s.pausedAt == null) return s;
    return { ...s, pausedAt: null, pausedAccumMs: s.pausedAccumMs + (now - s.pausedAt) };
  }

  startWaiting = (s: TimerState, now: number): TimerState =>
    TimerStates.isWaiting(s) ? { ...s, phaseStartedAt: now, pausedAccumMs: 0 } : s;

  /** Advances through every phase that has ended by `now`. */
  tick(s: TimerState, now: number): TickResult {
    const ended: PhaseEnded[] = [];
    let state = s;
    while (TimerStates.isRunning(state)) {
      const end = this.phaseEndsAt(state)!;
      if (now < end) break;
      ended.push({ phase: state.phase, endedAt: end });
      state = this.advance(state, end, state.phaseDurationMs, false);
    }
    return { state, ended };
  }

  skip(s: TimerState, now: number): TickResult {
    if (s.cycleComplete) return { state: s, ended: [] };
    const done = this.elapsedMs(s, now);
    const next = this.advance(this.resume(s, now), now, done, true);
    return { state: next, ended: [{ phase: s.phase, endedAt: now }] };
  }

  private advance(s: TimerState, endedAt: number, completedMs: number, skipped: boolean): TimerState {
    const focusMs = s.phase === 'focus' ? s.focusMsCompleted + completedMs : s.focusMsCompleted;
    const phases = s.phasesCompleted + (skipped ? 0 : 1);
    const next = this.next(s.phase, s.focusIndex);
    if (!next) {
      return { ...s, focusMsCompleted: focusMs, phasesCompleted: phases, cycleComplete: true, phaseStartedAt: null, pausedAt: null };
    }
    const [phase, index] = next;
    const auto = phase === 'focus' ? this.autoStartFocus : this.autoStartBreaks;
    return {
      phase,
      focusIndex: index,
      phaseStartedAt: auto ? endedAt : null,
      phaseDurationMs: FocusCfg.durationMs(this.config, phase),
      pausedAt: null,
      pausedAccumMs: 0,
      focusMsCompleted: focusMs,
      phasesCompleted: phases,
      cycleComplete: false,
    };
  }

  private next(phase: FocusPhase, index: number): [FocusPhase, number] | null {
    if (phase === 'focus') return index >= this.config.longEvery ? ['longBreak', index] : ['shortBreak', index];
    if (phase === 'shortBreak') return ['focus', index + 1];
    return null;
  }
}
