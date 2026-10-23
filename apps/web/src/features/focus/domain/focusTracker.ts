/**
 * Interruption tracking for focus sessions (Regain-style) — port of the app's
 * FocusTracker. All instants are epoch milliseconds.
 *
 * Distinguishes, per session:
 * - focus time: completed focus-phase time (from the timer engine);
 * - paused time: time the user explicitly paused (timer engine);
 * - away time / interruptions: time spent outside the tab while a focus
 *   phase was running, and how many times that happened;
 * - app usage time: session wall time minus away time.
 */
export interface FocusTracking {
  interruptions: number;
  awayMs: number;
  /** Set while the user is away during a running focus phase. */
  awayStartedAt: number | null;
  /** Away time can't extend past the end of the focus phase that was running when the user left. */
  awayCapAt: number | null;
  /** Heartbeat while visible — bounds the gap if the tab dies on screen. */
  lastSeenAt: number | null;
}

export const emptyTracking: FocusTracking = { interruptions: 0, awayMs: 0, awayStartedAt: null, awayCapAt: null, lastSeenAt: null };

export const FocusTracker = {
  /** Shorter trips (a quick tab switch) don't count. */
  minAwayMs: 2000,
  /** Without a heartbeat for this long, a recovered session counts the gap as time away. */
  heartbeatGapMs: 90_000,

  isAway: (t: FocusTracking) => t.awayStartedAt != null,

  /** The tab was hidden. Only counts while a focus phase runs. */
  leave(t: FocusTracking, now: number, focusPhaseEndsAt: number | null): FocusTracking {
    if (t.awayStartedAt != null || focusPhaseEndsAt == null || now >= focusPhaseEndsAt) return t;
    return { ...t, awayStartedAt: now, awayCapAt: focusPhaseEndsAt };
  },

  /** The tab is visible again. */
  returnTo(t: FocusTracking, now: number): FocusTracking {
    const start = t.awayStartedAt;
    if (start == null) return { ...t, lastSeenAt: now };
    const end = t.awayCapAt != null && t.awayCapAt < now ? t.awayCapAt : now;
    const away = end - start;
    const closed = { ...t, awayStartedAt: null, awayCapAt: null, lastSeenAt: now };
    if (away < FocusTracker.minAwayMs) return closed;
    return { ...closed, interruptions: t.interruptions + 1, awayMs: t.awayMs + away };
  },

  heartbeat: (t: FocusTracking, now: number): FocusTracking => (t.awayStartedAt != null ? t : { ...t, lastSeenAt: now }),

  /** Session restored after the tab was closed or the machine restarted. */
  recover(t: FocusTracking, now: number, focusPhaseEndsAt: number | null): FocusTracking {
    if (t.awayStartedAt != null) return FocusTracker.returnTo(t, now);
    const seen = t.lastSeenAt;
    if (seen == null || now - seen < FocusTracker.heartbeatGapMs || focusPhaseEndsAt == null) return { ...t, lastSeenAt: now };
    return FocusTracker.returnTo(FocusTracker.leave(t, seen, focusPhaseEndsAt), now);
  },

  /** Closes an open away interval when the session ends. */
  finish: (t: FocusTracking, now: number) => (t.awayStartedAt != null ? FocusTracker.returnTo(t, now) : t),

  /** Time the app was in use during the session (wall time minus away time). */
  appUsageMs(startedAt: number, endedAt: number, awayMs: number) {
    const wall = endedAt - startedAt;
    return Math.min(Math.max(wall - awayMs, 0), Math.max(wall, 0));
  },
};
