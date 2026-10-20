import type { Day } from '../time/days';
import { T } from '../theme/tokens';

export interface DayPill {
  date: Day;
  label: string;
  /** Null renders "–". */
  percent: number | null;
  isToday: boolean;
  isFuture: boolean;
}

/** Circular day bubbles with % inside; today dark, future hatched. Sits on a pastel panel. */
export function DayRatePills({ days, onTap }: { days: DayPill[]; onTap?: (d: DayPill) => void }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', gap: 4 }}>
      {days.map((d) => {
        const text = d.percent == null ? '–' : `${d.percent}%`;
        const bg = d.isToday ? T.bg : d.isFuture ? 'rgba(255,255,255,0.35)' : T.white;
        const fg = d.isToday ? T.textPrimary : d.isFuture ? 'rgba(22,22,22,0.75)' : T.textInverse;
        return (
          <button
            key={d.date}
            type="button"
            onClick={onTap ? () => onTap(d) : undefined}
            disabled={!onTap}
            aria-label={`${d.label}, ${d.percent == null ? 'no tasks' : `${text} done`}`}
            style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6, flex: 1, minWidth: 0, cursor: onTap ? 'pointer' : 'default' }}
          >
            <span
              className="mono"
              style={{
                width: '100%', maxWidth: 46, aspectRatio: '1', borderRadius: '50%', display: 'grid', placeItems: 'center',
                background: bg, color: fg, fontSize: 11,
                backgroundImage: d.isFuture ? 'repeating-linear-gradient(-45deg, rgba(22,22,22,0.12) 0 1.2px, transparent 1.2px 6px)' : undefined,
              }}
            >
              {text}
            </span>
            <span style={{ fontSize: 11, fontWeight: 500, color: T.textInverse }}>{d.label}</span>
          </button>
        );
      })}
    </div>
  );
}
