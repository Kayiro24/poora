import { useEffect, useRef, useState } from 'react';
import { Navigate, useNavigate } from 'react-router';
import { useOccurrences, useReducedMotion, useSettings } from '../../../core/hooks';
import { Feedback } from '../../../core/platform/feedback';
import { WakeLock } from '../../../core/platform/wakeLock';
import { css, T } from '../../../core/theme/tokens';
import { Range } from '../../../core/time/days';
import { Icon, type IconName } from '../../../core/widgets/Icon';
import { Sheet } from '../../../core/widgets/widgets';
import { TasksRepository } from '../../tasks/data/tasksRepository';
import { AppInfo } from '../../../core/appInfo';
import { Fmt } from '../../../core/time/format';
import { engineFor, FocusController, isLocked, useFocus, type FocusSummary } from '../application/focusController';

const RING_R = 46;
import { TimerStates } from '../domain/timerEngine';
import { TimerFormat } from '../domain/timerFormat';
import { FocusBreakdown } from './FocusBreakdown';

/**
 * Full-screen, distraction-free session (§4.3): phase label, timer and ring.
 * Fullscreen + wake lock where the browser allows; controls on tap for 4 s.
 */
export function FocusRunScreen() {
  const navigate = useNavigate();
  const { session, summary } = useFocus();
  const settings = useSettings();
  const reduced = useReducedMotion();
  const [controls, setControls] = useState(false);
  const hide = useRef<number | undefined>(undefined);
  const digits = useRef<HTMLSpanElement>(null);
  const ring = useRef<SVGCircleElement>(null);
  const head = useRef<SVGGElement>(null);

  // Immersive: fullscreen + keep awake while the room is open.
  useEffect(() => {
    if (settings.keepAwake) void WakeLock.enable();
    document.documentElement.requestFullscreen?.().catch(() => {});
    return () => {
      void WakeLock.disable();
      if (document.fullscreenElement) void document.exitFullscreen().catch(() => {});
    };
  }, [settings.keepAwake]);

  // Per-frame ring and digits without re-rendering React.
  useEffect(() => {
    if (!session) return;
    const engine = engineFor(session.config);
    const fmt = new TimerFormat(settings.showSeconds, settings.showSubSeconds);
    const C = 2 * Math.PI * RING_R;
    let raf = 0;
    let last = '';
    const frame = () => {
      const now = Date.now();
      const text = fmt.main(engine.remainingMs(session.timer, now));
      if (text !== last && digits.current) digits.current.textContent = last = text;
      const p = engine.progress(session.timer, now);
      ring.current?.setAttribute('stroke-dasharray', `${C * p} ${C}`);
      // The moving head: a bead with a soft halo at the end of the arc.
      const a = p * 2 * Math.PI - Math.PI / 2;
      head.current?.setAttribute('transform', `translate(${50 + Math.cos(a) * RING_R} ${50 + Math.sin(a) * RING_R})`);
      head.current?.setAttribute('opacity', p > 0 ? '1' : '0');
      raf = requestAnimationFrame(frame);
    };
    raf = requestAnimationFrame(frame);
    return () => cancelAnimationFrame(raf);
  }, [session, settings.showSeconds, settings.showSubSeconds]);

  const reveal = () => {
    setControls(true);
    clearTimeout(hide.current);
    hide.current = window.setTimeout(() => setControls(false), 4000);
  };

  if (!session) {
    if (summary) return <Summary summary={summary} onDone={() => { FocusController.dismissSummary(); navigate('/focus', { replace: true }); }} />;
    return <Navigate to="/focus" replace />;
  }

  const t = session.timer;
  const accent = t.phase === 'focus' ? T.sage : T.ice;
  const label = t.phase === 'focus' ? `Focus · ${t.focusIndex} of ${session.config.longEvery}` : t.phase === 'shortBreak' ? 'Short break' : 'Long break';
  const fmt = new TimerFormat(settings.showSeconds, settings.showSubSeconds);
  const paused = TimerStates.isPaused(t);
  const locked = isLocked(session);
  const endsAt = engineFor(session.config).phaseEndsAt(t);
  const waiting = TimerStates.isWaiting(t);

  return (
    <div
      className={reduced ? undefined : 'breathe'}
      onClick={reveal}
      style={{ position: 'fixed', inset: 0, background: T.bg, display: 'grid', placeItems: 'center', cursor: controls ? 'default' : 'none', userSelect: 'none' }}
    >
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
        <h1 className="display" style={{ fontSize: 18, color: 'rgba(243, 240, 234,0.4)' }}>{label}</h1>
        {/* The ring is a size container: the digits scale with it, never past it. */}
        <div style={{ position: 'relative', width: 'min(340px, calc(100vw - 48px), 70vh)', aspectRatio: '1', marginTop: 28, containerType: 'size' }}>
          <svg viewBox="0 0 100 100" style={{ position: 'absolute', inset: 0 }} aria-hidden>
            {/* Sixty minute dots just outside the track; every fifth a touch larger. */}
            {Array.from({ length: 60 }, (_, i) => {
              const a = (i / 60) * 2 * Math.PI - Math.PI / 2;
              return <circle key={i} cx={50 + Math.cos(a) * 49} cy={50 + Math.sin(a) * 49} r={i % 5 === 0 ? 0.5 : 0.25} fill={T.textSecondary} fillOpacity={0.4} />;
            })}
            <circle cx="50" cy="50" r={RING_R} fill="none" stroke={T.outline} strokeWidth="0.6" />
            <circle ref={ring} cx="50" cy="50" r={RING_R} fill="none" stroke={accent} strokeWidth="1.2" strokeLinecap="round" strokeDasharray="0 400" transform="rotate(-90 50 50)" />
            <g ref={head} opacity="0">
              <circle r="2.6" fill={accent} fillOpacity={0.18} />
              <circle r="1.4" fill={accent} />
            </g>
          </svg>
          <div style={{ position: 'absolute', inset: '12%', display: 'grid', placeItems: 'center' }} aria-live="off">
            <span className="row" style={{ alignItems: 'baseline', gap: 8 }}>
              {/* Mono digits are 0.6em wide: "25" / "44:47" / "44:47.87" fill ~70% of the ring. */}
              <span
                ref={digits}
                className="mono"
                style={{ fontSize: !fmt.showSeconds ? '34cqw' : fmt.effectiveSubSeconds ? '14cqw' : '22cqw', fontWeight: 400, whiteSpace: 'nowrap' }}
              />
              {fmt.unit && <span style={{ fontSize: '7cqw', color: T.textSecondary }}>{fmt.unit}</span>}
            </span>
          </div>
        </div>
        <div style={{ height: 56, marginTop: 28 }}>
          {waiting && <ControlPill label={t.phase === 'focus' ? 'Start focus' : 'Start break'} icon="play" color={accent} onClick={() => FocusController.resume()} />}
        </div>
      </div>

      <div
        onClick={(e) => e.stopPropagation()}
        style={{ position: 'fixed', left: 24, right: 24, bottom: 32, textAlign: 'center', opacity: controls ? 1 : 0, pointerEvents: controls ? 'auto' : 'none', transition: 'opacity 360ms var(--ease)' }}
      >
        {locked ? (
          <div>
            <div className="row display d18" style={{ justifyContent: 'center', gap: 8, color: T.sage }}>
              <Icon name="lock" size={18} />
              Strict focus{endsAt != null ? ` · ends ${Fmt.time(new Date(endsAt), settings.use24h)}` : ''}
            </div>
            <p className="body-s" style={{ marginTop: 6 }}>No pausing, no ending early. {AppInfo.motto}</p>
          </div>
        ) : (
        <>
        <div className="row" style={{ justifyContent: 'center', gap: 10, flexWrap: 'wrap' }}>
          {!waiting && (
            <ControlPill label={paused ? 'Resume' : 'Pause'} icon={paused ? 'play' : 'pause'} onClick={() => { reveal(); if (paused) FocusController.resume(); else FocusController.pause(); }} />
          )}
          <ControlPill label="Skip" icon="skip" onClick={() => { reveal(); FocusController.skip(); }} />
          <EndPill longPress={settings.longPressToEnd} />
        </div>
        {settings.longPressToEnd && <p className="body-s" style={{ marginTop: 10 }}>Hold END to finish early</p>}
        </>
        )}
      </div>
    </div>
  );
}

function ControlPill({ label, icon, onClick, color = T.textPrimary }: { label: string; icon: IconName; onClick: () => void; color?: string }) {
  return (
    <button type="button" onClick={onClick} className="row" style={{ background: T.surface, border: `1px solid ${color}66`, borderRadius: 999, padding: '14px 18px', color }}>
      <Icon name={icon} />
      <span className="display d18">{label}</span>
    </button>
  );
}

/** End requires a long press (when the setting is on), so it's never accidental. */
function EndPill({ longPress }: { longPress: boolean }) {
  const timer = useRef<number | undefined>(undefined);
  const [holding, setHolding] = useState(false);
  const end = () => {
    Feedback.success();
    FocusController.end();
  };
  const down = () => {
    if (!longPress) return;
    setHolding(true);
    timer.current = window.setTimeout(end, 700);
  };
  const up = () => {
    clearTimeout(timer.current);
    setHolding(false);
  };
  return (
    <button
      type="button"
      aria-label={longPress ? 'End, hold to activate' : 'End'}
      onClick={longPress ? undefined : end}
      onPointerDown={down}
      onPointerUp={up}
      onPointerLeave={up}
      onKeyDown={(e) => e.key === 'Enter' && longPress && end()}
      className="row"
      style={{
        background: holding ? `${T.coralSoft}33` : T.surface, border: `1px solid ${T.coralSoft}66`, borderRadius: 999,
        padding: '14px 18px', color: T.coralSoft, transition: 'background 700ms linear',
      }}
    >
      <Icon name="stop" />
      <span className="display d18">End</span>
    </button>
  );
}

function Summary({ summary, onDone }: { summary: FocusSummary; onDone: () => void }) {
  const date = summary.linkedDate;
  const occ = useOccurrences(Range.day(date ?? '1970-01-01'));
  const linked = summary.linkedTaskId && date ? occ.find((o) => o.task.id === summary.linkedTaskId && o.originalDate === date) : undefined;
  return (
    <div style={{ position: 'fixed', inset: 0, background: T.bg }}>
      <Sheet open onClose={onDone} label="Session summary">
        <h2 className="display d32">{summary.endedEarly ? 'Session ended early' : 'Cycle complete'}</h2>
        <div className="row" style={{ marginTop: 20 }}>
          <div style={{ flex: 1 }}>
            <div className="mono" style={{ fontSize: 44, color: T.sage }}>{summary.focusMinutes}</div>
            <div className="body-s" style={{ marginTop: 4 }}>focus minutes</div>
          </div>
          <div style={{ flex: 1 }}>
            <div className="mono" style={{ fontSize: 44, color: T.sage }}>{summary.sessionsCompleted}</div>
            <div className="body-s" style={{ marginTop: 4 }}>sessions completed</div>
          </div>
        </div>
        <div style={{ marginTop: 16 }}>
          <FocusBreakdown
            focusMs={summary.focusMinutes * 60000}
            pausedMs={summary.pausedMs}
            awayMs={summary.awayMs}
            interruptions={summary.interruptions}
            appUsageMs={summary.appUsageMs}
          />
        </div>
        {linked && (
          <div className="row" style={{ marginTop: 20, padding: 16, background: T.surfaceHigh, borderRadius: 'var(--r-inner)' }}>
            <span style={{ width: 4, height: 32, background: css(linked.task.color) }} />
            <span className="display d20" style={{ flex: 1 }}>{linked.title}</span>
            {linked.status === 'done' ? (
              <span style={{ color: T.mint }}><Icon name="check" /></span>
            ) : (
              <button type="button" className="text-btn coral" onClick={() => { Feedback.success(); TasksRepository.setDone(linked, true); }}>
                Mark task done
              </button>
            )}
          </div>
        )}
        <button type="button" className="btn sage block" style={{ marginTop: 24, height: 56 }} onClick={onDone}>Done</button>
      </Sheet>
    </div>
  );
}
