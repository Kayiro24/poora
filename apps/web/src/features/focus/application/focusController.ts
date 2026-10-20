import { create } from 'zustand';
import { db, type FocusSessionRow } from '../../../core/db/store';
import { getSettings, updateSettings } from '../../../core/hooks';
import { Feedback } from '../../../core/platform/feedback';
import { Notify } from '../../../core/platform/notifications';
import { ReminderScheduler } from '../../../core/platform/reminderScheduler';
import type { Day } from '../../../core/time/days';
import { newId } from '../../tasks/domain/models';
import { TimerEngine, TimerStates, type FocusConfig, type TickResult, type TimerState } from '../domain/timerEngine';

export interface FocusSession {
  id: string;
  config: FocusConfig;
  timer: TimerState;
  startedAt: number;
  linkedTaskId: string | null;
  linkedDate: Day | null;
}

export interface FocusSummary {
  focusMinutes: number;
  sessionsCompleted: number;
  endedEarly: boolean;
  linkedTaskId: string | null;
  linkedDate: Day | null;
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
  });
}

function setTimer(t: TimerState) {
  const s = get().session;
  if (!s) return;
  useFocus.setState({ session: { ...s, timer: t } });
  persist();
}

function row(s: FocusSession, endedAt: number | null, focusMs = 0, endedEarly = false): FocusSessionRow {
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
  const s = get().session;
  if (!s) return;
  clearTimeout(phaseTimer);
  const now = nowMs();
  const focusMs = engineFor(s.config).focusMsSoFar(s.timer, now);
  db().upsertSession(row(s, now, focusMs, endedEarly));
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
    const timer: TimerState = { ...live, cycleComplete: false };
    const caught = engineFor(config).tick(timer, nowMs()).state;
    useFocus.setState({
      recovery: {
        session: { id: r.id, config, timer: caught, startedAt: r.startedAt, linkedTaskId: r.linkedTaskId, linkedDate: r.linkedOccurrenceDate },
        canResume: !caught.cycleComplete,
      },
    });
  },

  resumeRecovered() {
    const r = get().recovery;
    if (!r) return;
    useFocus.setState({ session: r.session, recovery: null });
    persist();
    holdReminders();
    arm();
  },

  closeRecovered() {
    const r = get().recovery;
    if (!r) return;
    useFocus.setState({ session: r.session, recovery: null });
    finish(!r.session.timer.cycleComplete, false);
  },

  start(config: FocusConfig, link?: { taskId: string; date: Day } | null) {
    if (get().session) return;
    const now = nowMs();
    const session: FocusSession = {
      id: newId(),
      config,
      timer: engineFor(config).start(now),
      startedAt: now,
      linkedTaskId: link?.taskId ?? null,
      linkedDate: link?.date ?? null,
    };
    useFocus.setState({ session, summary: null });
    db().upsertSession(row(session, null));
    persist();
    updateSettings((s) => ({ ...s, lastFocus: config, lastFocusAt: now }));
    holdReminders();
    arm();
  },

  pause() {
    const s = get().session;
    if (!s || !TimerStates.isRunning(s.timer)) return;
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
    if (!s) return;
    handleEnded(engineFor(s.config).skip(s.timer, nowMs()));
  },

  /** "End session" — recorded as ended early. */
  end() {
    finish(true);
  },

  dismissSummary() {
    useFocus.setState({ summary: null });
  },

  /** Delete all data: drop the session without recording it. */
  discard() {
    clearTimeout(phaseTimer);
    useFocus.setState({ session: null, summary: null, recovery: null });
  },

  /** Catch up after the tab was hidden or the machine slept. */
  catchUp() {
    onTick();
  },
};

document.addEventListener('visibilitychange', () => {
  if (!document.hidden) FocusController.catchUp();
});
