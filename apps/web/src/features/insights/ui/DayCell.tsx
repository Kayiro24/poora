import { T } from '../../../core/theme/tokens';
import { Days } from '../../../core/time/days';
import { monthLong } from '../../../core/time/format';
import { Icon } from '../../../core/widgets/Icon';
import { CompletionRing } from '../../../core/widgets/widgets';
import { CompletionTiers, DC, type DayCompletion, type DayTier } from '../domain/metrics';

export const tierColor = (t: DayTier): string =>
  ({ perfect: T.dayPerfect, high: T.dayHigh, mid: T.dayMid, low: T.dayLow, missed: T.dayMissed, today: T.ice } as Partial<Record<DayTier, string>>)[t] ??
  T.dayEmpty;

export const tierLabel = (t: DayTier) =>
  ({
    perfect: 'all done', high: 'mostly done', mid: 'about half done', low: 'a little done', missed: 'missed',
    rest: 'rest day', today: 'in progress', future: 'upcoming', beforeFirstUse: 'before you started',
  })[t];

/** One calendar day: ring arc = exact %, tinted fill, mono date and ✓ ◐ ✕ (never colour alone). */
export function DayCell(p: { completion: DayCompletion; isToday: boolean; onTap?: () => void; size?: number; delayMs?: number; pulse?: boolean }) {
  const c = p.completion;
  const size = p.size ?? 44;
  const tier = c.tier;
  const dim = tier === 'future' || tier === 'beforeFirstUse';
  const sched = DC.scheduled(c);
  const label = `${Days.date(c.day)} ${monthLong[Days.month(c.day) - 1].slice(0, 3)}: ${tierLabel(tier)}${sched > 0 && !dim ? `, ${c.done} of ${sched} done` : ''}`;
  const icon = tier === 'perfect' ? 'check' : tier === 'missed' ? 'close' : tier === 'high' || tier === 'mid' || tier === 'low' ? 'half' : null;

  const inner = (
    <span style={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
      <span className="mono" style={{ fontSize: 13, color: tier === 'beforeFirstUse' ? 'rgba(163,160,154,0.35)' : dim ? T.textSecondary : T.textPrimary }}>
        {Days.date(c.day)}
      </span>
      {icon === 'half' ? (
        <span aria-hidden style={{ width: 9, height: 9, borderRadius: '50%', border: `1.5px solid ${T.textPrimary}`, background: `linear-gradient(90deg, ${T.textPrimary} 50%, transparent 50%)`, marginTop: 2, opacity: 0.8 }} />
      ) : icon ? (
        <span style={{ opacity: 0.8, marginTop: 1, display: 'flex' }}><Icon name={icon} size={10} /></span>
      ) : tier === 'future' && c.pending > 0 ? (
        <span className="row" style={{ gap: 2, marginTop: 3 }}>
          {Array.from({ length: Math.min(c.pending, 3) }, (_, i) => <span key={i} style={{ width: 3, height: 3, borderRadius: '50%', background: T.textSecondary }} />)}
        </span>
      ) : tier === 'rest' ? (
        <span style={{ width: 4, height: 4, borderRadius: '50%', background: T.outline, marginTop: 3 }} />
      ) : null}
    </span>
  );

  let body = inner;
  if (tier !== 'rest' && tier !== 'future' && tier !== 'beforeFirstUse') {
    const rate = DC.rate(c) ?? 0;
    const progressTier = CompletionTiers.tierFor(rate);
    const color = tier === 'today' ? (progressTier === 'missed' ? T.ice : tierColor(progressTier)) : tierColor(tier);
    body = (
      <CompletionRing
        value={tier === 'missed' ? 1 : rate}
        color={color}
        size={size}
        stroke={tier === 'missed' ? 1.5 : 3}
        fill={tier === 'today' ? undefined : `${color}${tier === 'perfect' ? '59' : '33'}`}
        glow={tier === 'perfect'}
        delayMs={p.delayMs}
      >
        {inner}
      </CompletionRing>
    );
  }

  return (
    <button
      type="button"
      aria-label={label}
      onClick={p.onTap}
      disabled={!p.onTap}
      className={p.pulse ? 'pulse-once' : undefined}
      style={{ width: '100%', height: size + 4, display: 'grid', placeItems: 'center', cursor: p.onTap ? 'pointer' : 'default' }}
    >
      <span
        className={p.isToday ? 'today-ring' : undefined}
        style={{ width: size + (p.isToday ? 6 : 0), height: size + (p.isToday ? 6 : 0), borderRadius: '50%', display: 'grid', placeItems: 'center' }}
      >
        {body}
      </span>
    </button>
  );
}
