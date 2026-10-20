// Parity with test/features/focus/timer_engine_test.dart.
import { describe, expect, test } from 'vitest';
import { FocusCfg, TimerEngine, TimerStates, type FocusConfig } from './timerEngine';
import { TimerFormat } from './timerFormat';

const cfg: FocusConfig = { focusMin: 25, shortMin: 5, longMin: 15, longEvery: 2 };
const MIN = 60000;
const t0 = new Date(2026, 9, 19, 9).getTime();

describe('TimerEngine', () => {
  test('remaining time comes from the wall clock', () => {
    const e = new TimerEngine(cfg);
    const s = e.start(t0);
    const now = t0 + 10.5 * MIN;
    expect(e.remainingMs(s, now)).toBe(14.5 * MIN);
    expect(e.progress(s, now)).toBeCloseTo(0.42, 3);
  });

  test('pause freezes; resume accumulates', () => {
    const e = new TimerEngine(cfg);
    let s = e.start(t0);
    s = e.pause(s, t0 + 5 * MIN);
    expect(e.remainingMs(s, t0 + 35 * MIN)).toBe(20 * MIN);
    s = e.resume(s, t0 + 35 * MIN);
    expect(s.pausedAccumMs).toBe(30 * MIN);
    expect(e.remainingMs(s, t0 + 36 * MIN)).toBe(19 * MIN);
    expect(e.phaseEndsAt(s)).toBe(t0 + 55 * MIN);
  });

  test('cadence: focus, short, focus, long, complete', () => {
    const e = new TimerEngine(cfg, true, true);
    let s = e.start(t0);
    const seen = [s.phase];
    while (!s.cycleComplete) {
      s = e.tick(s, e.phaseEndsAt(s)!).state;
      if (!s.cycleComplete) seen.push(s.phase);
    }
    expect(seen).toEqual(['focus', 'shortBreak', 'focus', 'longBreak']);
    expect(s.focusMsCompleted).toBe(50 * MIN);
    expect(s.phasesCompleted).toBe(4);
  });

  test('catch-up after a long absence', () => {
    const e = new TimerEngine(cfg, true, true);
    const now = t0 + 40 * MIN;
    const r = e.tick(e.start(t0), now);
    expect(r.ended.map((x) => x.phase)).toEqual(['focus', 'shortBreak']);
    expect(r.state.focusIndex).toBe(2);
    expect(e.remainingMs(r.state, now)).toBe(15 * MIN);
    expect(e.focusMsSoFar(r.state, now)).toBe(35 * MIN);
  });

  test('auto-start focus off: next focus waits', () => {
    const e = new TimerEngine(cfg);
    let s = e.tick(e.start(t0), t0 + 31 * MIN).state;
    expect(s.phase).toBe('focus');
    expect(TimerStates.isWaiting(s)).toBe(true);
    s = e.startWaiting(s, t0 + 3 * 60 * MIN);
    expect(e.remainingMs(s, t0 + 181 * MIN)).toBe(24 * MIN);
  });

  test('skip keeps partial focus time', () => {
    const e = new TimerEngine(cfg);
    const s = e.skip(e.start(t0), t0 + 7 * MIN).state;
    expect(s.phase).toBe('shortBreak');
    expect(s.focusMsCompleted).toBe(7 * MIN);
    expect(s.phasesCompleted).toBe(0);
  });

  test('projected cycle end', () => {
    const e = new TimerEngine(cfg);
    expect(e.projectedCycleEnd(e.start(t0), t0)).toBe(t0 + FocusCfg.cycleMs(cfg));
    expect(FocusCfg.cycleMs(cfg)).toBe(70 * MIN);
  });
});

describe('TimerFormat', () => {
  const ms = (24 * 60 + 59) * 1000 + 870;
  test('seconds off', () => {
    const f = new TimerFormat(false, true);
    expect(f.main(ms)).toBe('25');
    expect(f.unit).toBe('min');
    expect(f.effectiveSubSeconds).toBe(false);
  });
  test('seconds on', () => {
    const f = new TimerFormat(true, false);
    expect(f.main(ms)).toBe('25:00');
    expect(f.main(ms - 1000)).toBe('24:59');
    expect(f.main(0)).toBe('00:00');
  });
  test('centiseconds', () => {
    const f = new TimerFormat(true, true);
    expect(f.main(ms)).toBe('24:59.87');
    expect(f.main(5)).toBe('00:00.01');
  });
});
