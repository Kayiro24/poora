import { useEffect, useState, type CSSProperties, type ReactNode } from 'react';
import { createPortal } from 'react-dom';
import { AppInfo } from '../appInfo';
import { T } from '../theme/tokens';
import { Icon, type IconName } from './Icon';

const asset = (p: string) => `${import.meta.env.BASE_URL}assets/${p}`;

// ---------------------------------------------------------------- Buttons

export function IconButton(props: {
  icon: IconName;
  label: string;
  onClick?: () => void;
  white?: boolean;
  small?: boolean;
  badge?: boolean;
  disabled?: boolean;
}) {
  return (
    <button
      type="button"
      className={`icon-btn${props.white ? ' white' : ''}${props.small ? ' small' : ''}`}
      aria-label={props.label}
      title={props.label}
      onClick={props.onClick}
      disabled={props.disabled}
    >
      <span className="circle">
        <Icon name={props.icon} />
      </span>
      {props.badge && <span className="badge" />}
    </button>
  );
}

/** 40px white circle with ↗ — opens detail. */
export const ArrowButton = (p: { label?: string; onClick?: () => void }) => (
  <IconButton icon="northEast" white label={p.label ?? 'Open'} onClick={p.onClick} />
);

export function ScreenHeader(p: { title: string; onBack?: () => void; onPastel?: boolean; size?: number; trailing?: ReactNode }) {
  return (
    <header className="screen-header">
      {p.onBack && <IconButton icon="back" label="Back" white={p.onPastel} onClick={p.onBack} />}
      <h1 className="display truncate" style={{ fontSize: p.size ?? 40, color: p.onPastel ? T.textInverse : T.textPrimary }}>
        {p.title}
      </h1>
      {p.trailing}
    </header>
  );
}

export function Pill(p: {
  label: string;
  onClick?: () => void;
  filled?: boolean;
  color?: string;
  fg?: string;
  dot?: string;
  icon?: IconName;
  trailingIcon?: IconName;
  dense?: boolean;
  title?: string;
}) {
  const style: CSSProperties = p.filled
    ? { background: p.color ?? T.textPrimary, color: p.fg ?? T.textInverse }
    : { borderColor: p.color, color: p.fg };
  const content = (
    <>
      {p.dot && <span className="dot" style={{ background: p.dot }} />}
      {p.icon && <Icon name={p.icon} size={p.dense ? 12 : 16} />}
      <span>{p.label}</span>
      {p.trailingIcon && <Icon name={p.trailingIcon} size={p.dense ? 12 : 16} />}
    </>
  );
  const cls = `pill${p.filled ? ' filled' : ''}${p.dense ? ' dense' : ''}`;
  return p.onClick ? (
    <button type="button" className={cls} style={style} onClick={p.onClick} title={p.title}>
      {content}
    </button>
  ) : (
    <span className={cls} style={style}>
      {content}
    </span>
  );
}

export function StatTile(p: { value: string; label: string; color?: string; labelColor?: string; size?: number; leading?: ReactNode }) {
  const color = p.color ?? T.textPrimary;
  return (
    <span className="stat" aria-label={`${p.value} ${p.label.replace('\n', ' ')}`}>
      {p.leading}
      <span className="mono" style={{ fontSize: p.size ?? 32, color }}>
        {p.value}
      </span>
      <span className="label" style={{ color: p.labelColor ?? color, opacity: p.labelColor ? 1 : 0.8 }} aria-hidden>
        {p.label}
      </span>
    </span>
  );
}

export const CoralFab = (p: { onClick: () => void; label?: string }) => (
  <button type="button" className="fab" aria-label={p.label ?? 'Create task'} title={p.label ?? 'Create task'} onClick={p.onClick}>
    <Icon name="plus" size={30} />
  </button>
);

export const MonoBadge = ({ text }: { text: string }) => <span className="mono mono-badge">{text}</span>;

// ---------------------------------------------------------------- Brand & mascot

export type Mood = 'calm' | 'happy' | 'thinking' | 'sleepy';
const moodFile: Record<Mood, string> = { calm: 'blob_sage', happy: 'blob_coral', thinking: 'blob_peri', sleepy: 'blob_ice' };

export const Mascot = ({ mood = 'calm', size = 48 }: { mood?: Mood; size?: number }) => (
  <img src={asset(`illustrations/${moodFile[mood]}.svg`)} width={size} height={size} alt="" draggable={false} style={{ flex: 'none' }} />
);

/**
 * The Poora mark (same geometry as the app's PooraMark). `progress` 0→1 draws
 * the stem, the sage ring, then the ice closing stroke.
 */
export function PooraMark({ size = 64, progress = 1 }: { size?: number; progress?: number }) {
  const seg = (a: number, b: number) => Math.min(Math.max((progress - a) / (b - a), 0), 1);
  const circ = 2 * Math.PI * 176;
  const sage = seg(0.25, 0.8);
  const ice = seg(0.75, 1);
  const stem = seg(0, 0.35);
  const iceLen = (70 / 360) * circ;
  return (
    <svg viewBox="290 180 538 680" height={size} width={(size * 538) / 680} role="img" aria-label={`${AppInfo.name} logo`}>
      <circle
        cx="566" cy="420" r="176" fill="none" stroke={T.sage} strokeWidth="104" strokeLinecap="round"
        strokeDasharray={`${(300 / 360) * circ * sage} ${circ}`}
        transform="rotate(180 566 420)" opacity={sage > 0 ? 1 : 0}
      />
      <circle
        cx="566" cy="420" r="176" fill="none" stroke={T.ice} strokeWidth="104" strokeLinecap="round"
        strokeDasharray={`${iceLen * ice} ${circ}`}
        transform="rotate(110 566 420)" opacity={ice > 0 ? 1 : 0}
      />
      <rect x="300" y="190" width="120" height={Math.max(660 * stem, 0.01)} rx="60" fill={T.coral} opacity={stem > 0 ? 1 : 0} />
    </svg>
  );
}

export const Wordmark = ({ size = 40, tagline = false }: { size?: number; tagline?: boolean }) => (
  <div>
    <div className="row" style={{ gap: size * 0.3 }}>
      <PooraMark size={size} />
      <span className="display" style={{ fontSize: size * 1.05 }}>
        {AppInfo.name}
      </span>
    </div>
    {tagline && (
      <div className="muted" style={{ fontSize: size * 0.38, marginTop: size * 0.25 }}>
        {AppInfo.tagline}
      </div>
    )}
  </div>
);

// ---------------------------------------------------------------- Ring

/** Arc length = exact fraction, clockwise from 12 o'clock; animates to new values. */
export function CompletionRing(p: {
  value: number;
  color: string;
  size?: number;
  stroke?: number;
  track?: string;
  fill?: string;
  glow?: boolean;
  delayMs?: number;
  children?: ReactNode;
}) {
  const size = p.size ?? 44;
  const stroke = p.stroke ?? 3;
  const r = size / 2 - stroke / 2 - (p.glow ? 2 : 0);
  const c = 2 * Math.PI * r;
  const v = Math.min(Math.max(p.value, 0), 1);
  const [drawn, setDrawn] = useState(0);
  useEffect(() => {
    const id = setTimeout(() => setDrawn(v), (p.delayMs ?? 0) + 16);
    return () => clearTimeout(id);
  }, [v, p.delayMs]);
  return (
    <span style={{ position: 'relative', width: size, height: size, display: 'inline-grid', placeItems: 'center', flex: 'none' }}>
      <svg width={size} height={size} style={{ position: 'absolute', inset: 0, overflow: 'visible' }} aria-hidden>
        {p.fill && <circle cx={size / 2} cy={size / 2} r={r} fill={p.fill} />}
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke={p.track ?? T.surfaceHigh} strokeWidth={stroke} />
        {v > 0 && (
          <circle
            cx={size / 2} cy={size / 2} r={r} fill="none" stroke={p.color} strokeWidth={stroke}
            strokeLinecap={v >= 1 ? 'butt' : 'round'}
            strokeDasharray={`${c * drawn} ${c}`}
            transform={`rotate(-90 ${size / 2} ${size / 2})`}
            style={{
              transition: 'stroke-dasharray 420ms cubic-bezier(0.215,0.61,0.355,1)',
              filter: p.glow ? `drop-shadow(0 0 2px ${p.color}4d)` : undefined,
            }}
          />
        )}
      </svg>
      <span style={{ position: 'relative' }}>{p.children}</span>
    </span>
  );
}

// ---------------------------------------------------------------- Layout bits

export const SectionTitle = ({ children, trailing }: { children: string; trailing?: ReactNode }) => (
  <div className="section-title">
    <h2 className="display d22">{children}</h2>
    {trailing}
  </div>
);

export function EmptyState({ message, mood = 'sleepy', compact, color }: { message: string; mood?: Mood; compact?: boolean; color?: string }) {
  return (
    <div className={`empty${compact ? ' compact' : ''}`} style={{ color }}>
      <Mascot mood={mood} size={compact ? 40 : 64} />
      <span style={{ fontSize: 14 }}>{message}</span>
    </div>
  );
}

export const Group = ({ title, children }: { title: string; children: ReactNode }) => (
  <section>
    <h3 className="group-title">{title}</h3>
    <div className="group">{children}</div>
  </section>
);

export function SRow(p: { title: string; subtitle?: string; trailing?: ReactNode; onClick?: () => void; disabled?: boolean }) {
  const inner = (
    <>
      <span className="t">
        <span className="title">{p.title}</span>
        {p.subtitle && <span className="body-s" style={{ display: 'block', marginTop: 2, whiteSpace: 'pre-line' }}>{p.subtitle}</span>}
      </span>
      {p.trailing}
    </>
  );
  return p.onClick && !p.disabled ? (
    <button type="button" className="srow" onClick={p.onClick}>
      {inner}
    </button>
  ) : (
    <div className={`srow${p.disabled ? ' disabled' : ''}`}>{inner}</div>
  );
}

export function SwitchRow(p: { title: string; subtitle?: string; value: boolean; onChange?: (v: boolean) => void; disabled?: boolean }) {
  const off = p.disabled || !p.onChange;
  return (
    <button
      type="button"
      role="switch"
      aria-checked={p.value}
      className={`srow${p.disabled ? ' disabled' : ''}`}
      onClick={off ? undefined : () => p.onChange!(!p.value)}
      disabled={off}
    >
      <span className="t">
        <span className="title">{p.title}</span>
        {p.subtitle && <span className="body-s" style={{ display: 'block', marginTop: 2 }}>{p.subtitle}</span>}
      </span>
      <span className={`switch${p.value ? ' on' : ''}${p.disabled ? ' off-disabled' : ''}`} aria-hidden />
    </button>
  );
}

// ---------------------------------------------------------------- Sheet

export function Sheet(p: { open: boolean; onClose: () => void; children: ReactNode; tall?: boolean; label?: string }) {
  useEffect(() => {
    if (!p.open) return;
    const onKey = (e: KeyboardEvent) => e.key === 'Escape' && p.onClose();
    window.addEventListener('keydown', onKey);
    const prev = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    return () => {
      window.removeEventListener('keydown', onKey);
      document.body.style.overflow = prev;
    };
  }, [p]);
  if (!p.open) return null;
  return createPortal(
    <div className="scrim" onMouseDown={(e) => e.target === e.currentTarget && p.onClose()}>
      <div className={`sheet${p.tall ? ' tall' : ''}`} role="dialog" aria-modal="true" aria-label={p.label}>
        <div className="handle" />
        <div className="sheet-body">{p.children}</div>
      </div>
    </div>,
    document.body,
  );
}

/** Simple list picker in a sheet. */
export function OptionSheet<V>(p: {
  open: boolean;
  title: string;
  options: { label: string; value: V; selected?: boolean; hint?: string }[];
  onPick: (v: V) => void;
  onClose: () => void;
}) {
  return (
    <Sheet open={p.open} onClose={p.onClose} label={p.title}>
      <h2 className="display d24" style={{ margin: '4px 0 8px' }}>{p.title}</h2>
      {p.options.map((o, i) => (
        <button key={i} type="button" className="list-item body-l" onClick={() => p.onPick(o.value)}>
          <span style={{ flex: 1 }}>{o.label}</span>
          {o.hint && <span className="body-s">{o.hint}</span>}
          {o.selected && <Icon name="check" className="icon" />}
        </button>
      ))}
    </Sheet>
  );
}

/** Numeric picker (the app's wheel picker): a scrollable list of mono values. */
export function NumberSheet(p: {
  open: boolean;
  title: string;
  min: number;
  max: number;
  step?: number;
  value: number;
  unit?: string;
  accent?: string;
  onPick: (v: number) => void;
  onClose: () => void;
}) {
  const values: number[] = [];
  for (let v = p.min; v <= p.max; v += p.step ?? 1) values.push(v);
  return (
    <Sheet open={p.open} onClose={p.onClose} label={p.title}>
      <h2 className="display d24" style={{ margin: '4px 0 12px', textAlign: 'center' }}>{p.title}</h2>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(64px, 1fr))', gap: 8, maxHeight: 320, overflowY: 'auto' }}>
        {values.map((v) => (
          <button
            key={v}
            type="button"
            className="mono"
            onClick={() => p.onPick(v)}
            ref={v === p.value ? (el) => el?.scrollIntoView({ block: 'center' }) : undefined}
            style={{
              height: 48, borderRadius: 14, fontSize: 20,
              background: v === p.value ? p.accent ?? T.sage : T.surfaceHigh,
              color: v === p.value ? T.textInverse : T.textPrimary,
            }}
          >
            {v}
          </button>
        ))}
      </div>
      {p.unit && <p className="body-s" style={{ textAlign: 'center' }}>{p.unit}</p>}
    </Sheet>
  );
}
