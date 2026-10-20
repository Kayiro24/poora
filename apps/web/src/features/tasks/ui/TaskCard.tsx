import { useRef, useState } from 'react';
import { useSettings } from '../../../core/hooks';
import { css, T } from '../../../core/theme/tokens';
import { Fmt } from '../../../core/time/format';
import { Icon } from '../../../core/widgets/Icon';
import { ArrowButton, Pill } from '../../../core/widgets/widgets';
import { isRecurring, Occ, type Occurrence } from '../domain/models';
import { Rules } from '../domain/recurrence';
import { openEditor, skipOrDelete, toggleDone } from './tasksUi';

export function timeLabel(o: Occurrence, use24h: boolean) {
  if (!Occ.isTimed(o)) return 'All day';
  return `${Fmt.minute(o.startMinute!, use24h)} – ${Fmt.minute(Occ.endMinute(o)!, use24h)}`;
}

/** Round checkbox that fills on completion. */
export function RoundCheck(p: { checked: boolean; skipped?: boolean; onClick: () => void; color?: string; size?: number }) {
  const size = p.size ?? 28;
  const color = p.color ?? T.mint;
  return (
    <button
      type="button"
      role="checkbox"
      aria-checked={p.checked}
      aria-label={p.checked ? 'Completed. Click to undo' : 'Mark done'}
      onClick={(e) => {
        e.stopPropagation();
        p.onClick();
      }}
      style={{ width: 44, height: 44, display: 'grid', placeItems: 'center', flex: 'none' }}
    >
      <span
        style={{
          width: size, height: size, borderRadius: '50%', display: 'grid', placeItems: 'center',
          background: p.checked ? color : 'transparent', border: `1.6px solid ${p.checked ? color : T.textSecondary}`,
          color: T.textInverse, transition: 'all 280ms var(--ease)',
        }}
      >
        {p.checked ? <Icon name="check" size={size * 0.65} /> : p.skipped ? <Icon name="remove" size={size * 0.6} /> : null}
      </span>
    </button>
  );
}

/** Text with a strike-through that draws left → right. */
export function StrikeText({ text, struck, className, style }: { text: string; struck: boolean; className?: string; style?: React.CSSProperties }) {
  return (
    <span className={`truncate ${className ?? ''}`} style={{ position: 'relative', display: 'inline-block', maxWidth: '100%', ...style }}>
      {text}
      <span
        aria-hidden
        style={{
          position: 'absolute', left: 0, top: '52%', height: 1.6, background: 'currentColor',
          width: struck ? '100%' : 0, transition: 'width 420ms var(--ease)',
        }}
      />
    </span>
  );
}

/**
 * List card (Schedule, Home, day sheet): checkbox, condensed title, tag chip,
 * time · repeat line, ↗. Swipe right = done, left = skip/delete (touch);
 * the same actions are buttons on hover for mouse users.
 */
export function TaskCard({ occurrence: o, swipe = true }: { occurrence: Occurrence; swipe?: boolean }) {
  const { use24h } = useSettings();
  const done = o.status === 'done';
  const skipped = o.status === 'skipped';
  const color = css(o.task.color);
  const [dx, setDx] = useState(0);
  const start = useRef<{ x: number; y: number; locked: boolean | null } | null>(null);

  const onPointerDown = (e: React.PointerEvent) => {
    if (!swipe || e.pointerType === 'mouse') return;
    start.current = { x: e.clientX, y: e.clientY, locked: null };
  };
  const onPointerMove = (e: React.PointerEvent) => {
    const s = start.current;
    if (!s) return;
    const mx = e.clientX - s.x, my = e.clientY - s.y;
    if (s.locked == null && Math.hypot(mx, my) > 8) s.locked = Math.abs(mx) > Math.abs(my);
    if (s.locked) setDx(Math.max(-140, Math.min(140, mx)));
  };
  const onPointerUp = () => {
    const s = start.current;
    start.current = null;
    if (s?.locked) {
      if (dx > 90) toggleDone(o);
      else if (dx < -90) skipOrDelete(o);
    }
    setDx(0);
  };

  const recurring = isRecurring(o.task);
  return (
    <div style={{ position: 'relative', borderRadius: 'var(--r-inner)', overflow: 'hidden' }}>
      {dx !== 0 && (
        <div
          aria-hidden
          style={{
            position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', padding: '0 24px', gap: 8, fontWeight: 500,
            justifyContent: dx > 0 ? 'flex-start' : 'flex-end', color: T.textInverse,
            background: dx > 0 ? T.mint : T.coralSoft,
          }}
        >
          <Icon name={dx > 0 ? (done ? 'undo' : 'check') : recurring ? 'redo' : 'delete'} />
          {dx > 0 ? (done ? 'Undo' : 'Done') : recurring ? (skipped ? 'Restore' : 'Skip') : 'Delete'}
        </div>
      )}
      <div
        className="task-card"
        onPointerDown={onPointerDown}
        onPointerMove={onPointerMove}
        onPointerUp={onPointerUp}
        onPointerCancel={onPointerUp}
        onClick={() => openEditor({ occurrence: o })}
        style={{
          position: 'relative', display: 'flex', alignItems: 'stretch', background: T.surface, cursor: 'pointer',
          opacity: done || skipped ? 0.6 : 1, transform: `translateX(${dx}px)`,
          transition: dx === 0 ? 'transform 280ms var(--ease), opacity 360ms var(--ease)' : undefined,
          touchAction: 'pan-y',
        }}
      >
        <span style={{ width: 4, background: color, flex: 'none' }} />
        <div style={{ paddingTop: 6, paddingLeft: 4 }}>
          <RoundCheck checked={done} skipped={skipped} onClick={() => toggleDone(o)} />
        </div>
        <div style={{ flex: 1, minWidth: 0, padding: '14px 4px' }}>
          <div className="row" style={{ gap: 6 }}>
            {o.task.priority === 2 && <span style={{ width: 8, height: 8, borderRadius: '50%', background: T.sun, flex: 'none' }} aria-label="High priority" />}
            <StrikeText text={o.title} struck={done} className="display d20" />
          </div>
          <div className="row wrap" style={{ marginTop: 6 }}>
            {o.task.tag?.trim() && <Pill label={o.task.tag} dense dot={color} />}
            <span className="mono" style={{ fontSize: 12, color: T.textSecondary }}>{timeLabel(o, use24h)}</span>
            {recurring && (
              <span title={Rules.summary(Rules.fromTask(o.task), o.task.startDate)} style={{ color: T.textSecondary, display: 'inline-flex' }}>
                <Icon name="repeat" size={14} />
              </span>
            )}
            {o.status === 'missed' && <span style={{ fontSize: 12, color: T.coralSoft }}>missed</span>}
          </div>
        </div>
        <div className="card-actions" style={{ display: 'flex', alignItems: 'flex-start', paddingTop: 4, paddingRight: 4 }} onClick={(e) => e.stopPropagation()}>
          {swipe && (
            <button
              type="button"
              className="hover-only text-btn"
              title={recurring ? (skipped ? 'Restore' : 'Skip this time') : 'Delete'}
              aria-label={recurring ? (skipped ? 'Restore' : 'Skip this time') : 'Delete'}
              onClick={() => skipOrDelete(o)}
              style={{ color: T.textSecondary, marginTop: 4 }}
            >
              <Icon name={recurring ? 'redo' : 'delete'} size={18} />
            </button>
          )}
          <ArrowButton label={`Open ${o.title}`} onClick={() => openEditor({ occurrence: o })} />
        </div>
      </div>
    </div>
  );
}

/** Compact card on the rail; `highlight` = next upcoming (full pastel fill). */
export function RailCard({ occurrence: o, highlight }: { occurrence: Occurrence; highlight?: boolean }) {
  const { use24h } = useSettings();
  const color = css(o.task.color);
  const done = o.status === 'done';
  return (
    <button
      type="button"
      onClick={() => openEditor({ occurrence: o })}
      onDoubleClick={() => toggleDone(o)}
      aria-label={`${o.title}, ${timeLabel(o, use24h)}${done ? ', done' : ''}`}
      style={{
        width: '100%', height: '100%', borderRadius: 12, overflow: 'hidden', display: 'flex', textAlign: 'left',
        background: highlight ? color : T.surfaceHigh, color: highlight ? T.textInverse : T.textPrimary,
        opacity: done || o.status === 'skipped' ? 0.6 : 1, containerType: 'size',
      }}
    >
      {!highlight && <span style={{ width: 4, background: color, flex: 'none' }} />}
      <span style={{ flex: 1, minWidth: 0, padding: '4px 6px 2px 8px' }}>
        <StrikeText text={o.title} struck={done} className="display" style={{ fontSize: 15, display: 'block' }} />
        <span className="mono rail-time truncate" style={{ fontSize: 10, opacity: 0.8, display: 'block', marginTop: 2 }}>{timeLabel(o, use24h)}</span>
      </span>
    </button>
  );
}

export function AllDayChip({ occurrence: o }: { occurrence: Occurrence }) {
  const color = css(o.task.color);
  return (
    <button
      type="button"
      onClick={() => openEditor({ occurrence: o })}
      onDoubleClick={() => toggleDone(o)}
      className="truncate"
      style={{
        maxWidth: '100%', background: color, color: T.textInverse, borderRadius: 10, padding: '5px 8px', fontSize: 12, fontWeight: 500,
        opacity: o.status === 'done' || o.status === 'skipped' ? 0.6 : 1, display: 'inline-flex', alignItems: 'center', gap: 4,
      }}
    >
      {o.status === 'done' && <Icon name="check" size={14} />}
      <span className="truncate">{o.title}</span>
    </button>
  );
}
