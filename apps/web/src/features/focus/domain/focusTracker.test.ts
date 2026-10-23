// Parity with test/features/focus/focus_tracker_test.dart.
import { describe, expect, test } from 'vitest';
import { emptyTracking, FocusTracker } from './focusTracker';
import { TimerEngine } from './timerEngine';

const MIN = 60000;
const t0 = new Date(2026, 9, 21, 9).getTime();
const at = (min: number, sec = 0) => t0 + min * MIN + sec * 1000;
const focusEnd = at(25);

describe('interruptions', () => {
  test('leaving and returning counts one interruption with its duration', () => {
    let t = FocusTracker.leave(emptyTracking, at(5), focusEnd);
    expect(FocusTracker.isAway(t)).toBe(true);
    t = FocusTracker.returnTo(t, at(8));
    expect([t.interruptions, t.awayMs, FocusTracker.isAway(t)]).toEqual([1, 3 * MIN, false]);
  });

  test('glances under 2 s are ignored', () => {
    const t = FocusTracker.returnTo(FocusTracker.leave(emptyTracking, at(5), focusEnd), at(5, 1));
    expect([t.interruptions, t.awayMs]).toEqual([0, 0]);
  });

  test('leaving during a break or after the focus phase is not an interruption', () => {
    expect(FocusTracker.isAway(FocusTracker.leave(emptyTracking, at(5), null))).toBe(false);
    expect(FocusTracker.isAway(FocusTracker.leave(emptyTracking, at(26), focusEnd))).toBe(false);
  });

  test('away time is clipped at the end of the focus phase', () => {
    const t = FocusTracker.returnTo(FocusTracker.leave(emptyTracking, at(20), focusEnd), at(40));
    expect(t.awayMs).toBe(5 * MIN);
  });

  test('several trips accumulate; a second leave while away is ignored', () => {
    let t = FocusTracker.leave(emptyTracking, at(1), focusEnd);
    t = FocusTracker.leave(t, at(2), focusEnd);
    t = FocusTracker.returnTo(t, at(3));
    t = FocusTracker.leave(t, at(10), focusEnd);
    t = FocusTracker.returnTo(t, at(10, 30));
    expect([t.interruptions, t.awayMs]).toEqual([2, 2 * MIN + 30000]);
  });
});

describe('recovery', () => {
  test('closed while away: away interval closes at recovery', () => {
    const r = FocusTracker.recover(FocusTracker.leave(emptyTracking, at(5), focusEnd), at(15), focusEnd);
    expect([r.interruptions, r.awayMs]).toEqual([1, 10 * MIN]);
  });

  test('died on screen (restart): gap since last heartbeat counts as away', () => {
    const r = FocusTracker.recover(FocusTracker.heartbeat(emptyTracking, at(4)), at(12), focusEnd);
    expect([r.interruptions, r.awayMs]).toEqual([1, 8 * MIN]);
  });

  test('a short heartbeat gap is not an interruption', () => {
    expect(FocusTracker.recover(FocusTracker.heartbeat(emptyTracking, at(4)), at(4, 30), focusEnd).interruptions).toBe(0);
  });

  test('finish closes an open away interval', () => {
    expect(FocusTracker.finish(FocusTracker.leave(emptyTracking, at(5), focusEnd), at(7)).awayMs).toBe(2 * MIN);
  });
});

describe('time categories', () => {
  test('focus, paused, away and app-usage time stay distinct', () => {
    const e = new TimerEngine({ focusMin: 25, shortMin: 5, longMin: 5, longEvery: 1 });
    let s = e.start(t0);
    s = e.pause(s, at(10));
    s = e.resume(s, at(14)); // 4 min paused
    let tr = FocusTracker.leave(emptyTracking, at(16), e.phaseEndsAt(s));
    tr = FocusTracker.returnTo(tr, at(19)); // 3 min away (timer keeps running)
    const end = at(29);
    s = e.tick(s, end).state;
    expect(e.focusMsSoFar(s, end)).toBe(25 * MIN);
    expect(e.pausedMsSoFar(s, end)).toBe(4 * MIN);
    expect(tr.awayMs).toBe(3 * MIN);
    expect(FocusTracker.appUsageMs(t0, end, tr.awayMs)).toBe(26 * MIN);
  });

  test('paused total survives phase changes and counts an open pause', () => {
    const e = new TimerEngine({ focusMin: 25, shortMin: 5, longMin: 15, longEvery: 2 }, true, true);
    let s = e.start(t0);
    s = e.resume(e.pause(s, at(5)), at(7)); // 2 min
    s = e.tick(s, at(32)).state; // focus done (ends at 27) → break
    expect(s.pausedTotalMs).toBe(2 * MIN);
    s = e.pause(s, at(30));
    expect(e.pausedMsSoFar(s, at(33))).toBe(5 * MIN);
  });

  test('focus from a task: one countdown, no break', () => {
    const e = new TimerEngine({ focusMin: 45, shortMin: 0, longMin: 0, longEvery: 1 });
    const r = e.tick(e.start(t0), at(45));
    expect(r.state.cycleComplete).toBe(true);
    expect(r.state.focusMsCompleted).toBe(45 * MIN);
    expect(r.ended.map((x) => x.phase)).toEqual(['focus']);
  });
});
