import { create } from 'zustand';
import { db, type FocusSessionRow } from '../../../core/db/store';
import { getSettings, updateSettings } from '../../../core/hooks';
import { Feedback } from '../../../core/platform/feedback';
import { Notify } from '../../../core/platform/notifications';
import { ReminderScheduler } from '../../../core/platform/reminderScheduler';
import type { Day } from '../../../core/time/days';
import { newId } from '../../tasks/domain/models';
import { emptyTracking, FocusTracker, type FocusTracking } from '../domain/focusTracker';
import { TimerEngine, TimerStates, type FocusConfig, type TickResult, type TimerState } from '../domain/timerEngine';

export interface FocusSession {
  id: string;
  config: FocusConfig;
  timer: TimerState;
  startedAt: number;
  linkedTaskId: string | null;
  linkedDate: Day | null;
  /** Interruptions / time away (tab hidden during focus). */
  tracking: FocusTracking;
  /** Strict mode: a started focus phase can't be paused, skipped or ended. */
  strict: boolean;
}

/** True while strict mode holds: a focus phase has started and isn't over. */
export const isLocked = (s: FocusSession | null | undefined) =>
  !!s && s.strict && s.timer.phase === 'focus' && s.timer.phaseStartedAt != null && !s.timer.cycleComplete;

export interface FocusSummary {
  focusMinutes: number;
  sessionsCompleted: number;
  endedEarly: boolean;
  linkedTaskId: string | null;
  linkedDate: Day | null;
  pausedMs: number;
  awayMs: number;
  interruptions: number;
  appUsageMs: number;
}

export interface FocusRecovery {
  session: FocusSession;
  canResume: boolean;
}

interface FocusUi {
  session: FocusSession | null;
  summary: FocusSummary | null;
  recovery: FocusRecovery | null;
}

/** Port of the app's FocusController. */
export const useFocus = create<FocusUi>(() => ({ session: null, summary: null, recovery: null }));

let phaseTimer: number | undefined;
let heartbeat: number | undefined;
const HEARTBEAT_MS = 30_000;

export function engineFor(config: FocusConfig): TimerEngine {
  const s = getSettings();
  return new TimerEngine(config, s.autoStartBreaks, s.autoStartFocus);
}

const get = () => useFocus.getState();
const nowMs = () => Date.now();

function persist() {
  const s = get().session;
  if (!s) return;
  const t = s.timer;
  const k = s.tracking;
  db().setFocusState({
    id: 1,
    sessionId: s.id,
    phase: t.phase,
    focusIndex: t.focusIndex,
    phaseStartedAt: t.phaseStartedAt,
    phaseDurationMs: t.phaseDurationMs,
    pausedAt: t.pausedAt,
    pausedAccumMs: t.pausedAccumMs,
    focusMsCompleted: t.focusMsCompleted,
    phasesCompleted: t.phasesCompleted,
    pausedTotalMs: t.pausedTotalMs ?? 0,
    interruptions: k.interruptions,
    awayMs: k.awayMs,
    awayStartedAt: k.awayStartedAt,
    awayCapAt: k.awayCapAt,
    lastSeenAt: k.lastSeenAt,
    strict: s.strict,
  });
}

function setTracking(k: FocusTracking) {
  const s = get().session;
  if (!s) return;
  useFocus.setState({ session: { ...s, tracking: k } });
  persist();
}

/** End of the running focus phase, if one is running (breaks aren't interruptions). */
function focusPhaseEnd(s: FocusSession) {
  return TimerStates.isFocus(s.timer) ? engineFor(s.config).phaseEndsAt(s.timer) : null;
}

function startHeartbeat() {
  clearInterval(heartbeat);
  heartbeat = window.setInterval(() => {
    const s = get().session;
    if (s && !document.hidden) setTracking(FocusTracker.heartbeat(s.tracking, nowMs()));
  }, HEARTBEAT_MS);
}

function setTimer(t: TimerState) {
  const s = get().session;
  if (!s) return;
  useFocus.setState({ session: { ...s, timer: t } });
  persist();
}

function row(s: FocusSession, endedAt: number | null, focusMs = 0, endedEarly = false, pausedMs = 0): FocusSessionRow {
  return {
    id: s.id,
    startedAt: s.startedAt,
    endedAt,
    plannedFocusMin: s.config.focusMin,
    shortBreakMin: s.config.shortMin,
    longBreakMin: s.config.longMin,
    longEvery: s.config.longEvery,
    focusMsCompleted: focusMs,
    phasesCompleted: s.timer.phasesCompleted,
    endedEarly,
    linkedTaskId: s.linkedTaskId,
    linkedOccurrenceDate: s.linkedDate,
    pausedMs,
    awayMs: s.tracking.awayMs,
    interruptions: s.tracking.interruptions,
    // Distracting-app detection needs Android usage access.
    distractions: null,
  };
}

function holdReminders() {
  const s = get().session;
  if (!s) return;
  ReminderScheduler.hold(engineFor(s.config).projectedCycleEnd(s.timer, nowMs()));
}

function arm() {
  clearTimeout(phaseTimer);
  const s = get().session;
  if (!s) return;
  const end = engineFor(s.config).phaseEndsAt(s.timer);
  if (end == null) return;
  phaseTimer = window.setTimeout(onTick, Math.max(0, end - nowMs()));
}

function onTick() {
  const s = get().session;
  if (!s) return;
  handleEnded(engineFor(s.config).tick(s.timer, nowMs()));
}

function handleEnded(r: TickResult) {
  const s = get().session;
  if (!s) return;
  if (r.ended.length) {
    Feedback.chime();
    Feedback.success();
    // Tab in the background: the one notification focus allows.
    if (document.hidden) {
      const wasFocus = r.ended.at(-1)!.phase === 'focus';
      const held = ReminderScheduler.heldCount();
      void Notify.show(
        wasFocus ? 'Focus complete' : 'Break is over',
        wasFocus ? (held ? `${held} reminder${held === 1 ? ' was' : 's were'} held` : 'Nice work. Time for a break.') : 'Ready when you are.',
        'focus-end',
      );
    }
  }
  if (r.state.cycleComplete) {
    useFocus.setState({ session: { ...s, timer: r.state } });
    finish(false);
    return;
  }
  setTimer(r.state);
  if (r.ended.length) holdReminders();
  arm();
}

function finish(endedEarly: boolean, showSummary = true) {
  const live = get().session;
  if (!live) return;
  clearTimeout(phaseTimer);
  clearInterval(heartbeat);
  const now = nowMs();
  const s = { ...live, tracking: FocusTracker.finish(live.tracking, now) };
  const e = engineFor(s.config);
  const focusMs = e.focusMsSoFar(s.timer, now);
  const pausedMs = e.pausedMsSoFar(s.timer, now);
  db().upsertSession(row(s, now, focusMs, endedEarly, pausedMs));
  db().setFocusState(null);
  void ReminderScheduler.releaseHeld();
  const t = s.timer;
  const completedFocus = t.phase === 'focus' && !t.cycleComplete ? t.focusIndex - 1 : t.focusIndex;
  useFocus.setState({
    session: null,
    recovery: null,
    summary: showSummary
      ? {
          focusMinutes: Math.round(focusMs / 60000),
          sessionsCompleted: Math.min(Math.max(completedFocus, 0), s.config.longEvery),
          endedEarly,
          linkedTaskId: s.linkedTaskId,
          linkedDate: s.linkedDate,
          pausedMs,
          awayMs: s.tracking.awayMs,
          interruptions: s.tracking.interruptions,
          appUsageMs: FocusTracker.appUsageMs(s.startedAt, now, s.tracking.awayMs),
        }
      : null,
  });
}

export const FocusController = {
  /** On load: surface a session interrupted by closing the tab. */
  checkRecovery() {
    const live = db().focusState;
    if (!live) return;
    const r = db().focusSessions.find((x) => x.id === live.sessionId);
    if (!r) {
      db().setFocusState(null);
      return;
    }
    const config = { focusMin: r.plannedFocusMin, shortMin: r.shortBreakMin, longMin: r.longBreakMin, longEvery: r.longEvery };
    const timer: TimerState = { ...live, pausedTotalMs: live.pausedTotalMs ?? 0, cycleComplete: false };
    const e = engineFor(config);
    const now = nowMs();
    const saved: FocusTracking = {
      interruptions: live.interruptions ?? 0,
      awayMs: live.awayMs ?? 0,
      awayStartedAt: live.awayStartedAt ?? null,
      awayCapAt: live.awayCapAt ?? null,
      lastSeenAt: live.lastSeenAt ?? null,
    };
    // Time since the last heartbeat (tab closed or machine restarted) counts as away.
    const tracking = FocusTracker.recover(saved, now, timer.phase === 'focus' ? e.phaseEndsAt(timer) : null);
    const caught = e.tick(timer, now).state;
    useFocus.setState({
      recovery: {
        session: { id: r.id, config, timer: caught, startedAt: r.startedAt, linkedTaskId: r.linkedTaskId, linkedDate: r.linkedOccurrenceDate, tracking, strict: live.strict ?? false },
        canResume: !caught.cycleComplete,
      },
    });
    // Strict focus survives closing the tab: no "close session" way out.
    if (isLocked(get().recovery?.session)) FocusController.resumeRecovered();
  },

  resumeRecovered() {
    const r = get().recovery;
    if (!r) return;
    useFocus.setState({ session: r.session, recovery: null });
    persist();
    holdReminders();
    arm();
    startHeartbeat();
  },

  closeRecovered() {
    const r = get().recovery;
    if (!r) return;
    useFocus.setState({ session: r.session, recovery: null });
    finish(!r.session.timer.cycleComplete, false);
  },

  start(config: FocusConfig, link?: { taskId: string; date: Day } | null, strict = getSettings().strictMode) {
    if (get().session) return;
    const now = nowMs();
    const session: FocusSession = {
      id: newId(),
      config,
      timer: engineFor(config).start(now),
      startedAt: now,
      linkedTaskId: link?.taskId ?? null,
      linkedDate: link?.date ?? null,
      tracking: { ...emptyTracking, lastSeenAt: now },
      strict,
    };
    useFocus.setState({ session, summary: null });
    db().upsertSession(row(session, null));
    persist();
    updateSettings((s) => ({ ...s, lastFocus: config, lastFocusAt: now }));
    holdReminders();
    arm();
    startHeartbeat();
  },

  /** "Focus on this task": one countdown of `minutes`, no breaks, linked to the task. */
  startForTask(taskId: string, date: Day, minutes: number) {
    FocusController.start({ focusMin: minutes, shortMin: 0, longMin: 0, longEvery: 1 }, { taskId, date });
  },

  pause() {
    const s = get().session;
    if (!s || !TimerStates.isRunning(s.timer) || isLocked(s)) return;
    setTimer(engineFor(s.config).pause(s.timer, nowMs()));
    clearTimeout(phaseTimer);
  },

  resume() {
    const s = get().session;
    if (!s) return;
    const e = engineFor(s.config);
    setTimer(TimerStates.isWaiting(s.timer) ? e.startWaiting(s.timer, nowMs()) : e.resume(s.timer, nowMs()));
    holdReminders();
    arm();
  },

  skip() {
    const s = get().session;
    if (!s || isLocked(s)) return;
    handleEnded(engineFor(s.config).skip(s.timer, nowMs()));
  },

  /** "End session" — recorded as ended early. */
  end() {
    if (isLocked(get().session)) return;
    finish(true);
  },

  dismissSummary() {
    useFocus.setState({ summary: null });
  },

  /** Delete all data: drop the session without recording it. */
  discard() {
    clearTimeout(phaseTimer);
    clearInterval(heartbeat);
    useFocus.setState({ session: null, summary: null, recovery: null });
  },

  /** Tab hidden: start counting time away (only during a running focus phase). */
  onHidden() {
    const s = get().session;
    if (s) setTracking(FocusTracker.leave(s.tracking, nowMs(), focusPhaseEnd(s)));
  },

  /** Tab visible again: close the away interval and catch up after sleep. */
  onVisible() {
    const s = get().session;
    if (s) setTracking(FocusTracker.returnTo(s.tracking, nowMs()));
    onTick();
  },
};

if (typeof document !== 'undefined') {
  document.addEventListener('visibilitychange', () => (document.hidden ? FocusController.onHidden() : FocusController.onVisible()));
}
