import { Area, AreaChart, Bar, BarChart, CartesianGrid, Cell, Line, LineChart, Pie, PieChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts';
import { categoryPalette, otherColor, T } from '../../../core/theme/tokens';
import { Days, type Day } from '../../../core/time/days';
import { monthLong, weekdayLetters } from '../../../core/time/format';
import type { OccurrenceStatus } from '../../tasks/domain/models';
import { DC, type DayCompletion } from '../domain/metrics';

const tooltipStyle = {
  contentStyle: { background: T.surfaceHigh, border: 'none', borderRadius: 10, fontFamily: 'var(--f-mono)', fontSize: 12, color: T.textPrimary },
  itemStyle: { color: T.textPrimary },
  labelStyle: { color: T.textSecondary },
  cursor: { stroke: T.outline, fill: 'rgba(255,255,255,0.04)' },
};

/**
 * Completions per day (smooth coral area). `planned` is a dashed line;
 * days after `lastActual` only show the dashed line.
 */
export function WeekAreaChart(p: { labels: string[]; actual: number[]; planned?: (number | null)[]; lastActual?: number; ink?: string; height?: number }) {
  const ink = p.ink ?? T.textInverse;
  const last = p.lastActual ?? p.actual.length - 1;
  const data = p.labels.map((l, i) => ({ l, done: i <= last ? p.actual[i] : null, planned: p.planned?.[i] ?? null }));
  return (
    <div style={{ height: p.height ?? 140 }} role="img" aria-label={`Completions per day: ${data.filter((d) => d.done != null).map((d) => `${d.l} ${d.done}`).join(', ')}`}>
      <ResponsiveContainer>
        <AreaChart data={data} margin={{ top: 8, right: 4, bottom: 0, left: 4 }}>
          <defs>
            <linearGradient id="coralFill" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor={T.coral} stopOpacity={0.85} />
              <stop offset="100%" stopColor={T.coral} stopOpacity={0.25} />
            </linearGradient>
          </defs>
          <XAxis dataKey="l" axisLine={false} tickLine={false} tick={{ fill: ink, fontSize: 10 }} interval={0} />
          <YAxis hide domain={[0, (max: number) => Math.max(1, max) * 1.15]} />
          <Tooltip {...tooltipStyle} formatter={(v, n) => [v, n === 'done' ? 'done' : 'scheduled']} />
          <Area type="monotone" dataKey="done" stroke={T.coral} strokeWidth={2} fill="url(#coralFill)" connectNulls={false} isAnimationActive animationDuration={360} />
          {p.planned && <Line type="monotone" dataKey="planned" stroke={ink} strokeOpacity={0.6} strokeWidth={2} strokeDasharray="4 4" dot={false} connectNulls={false} />}
        </AreaChart>
      </ResponsiveContainer>
    </div>
  );
}

/** Thin bars with 4px rounded tops, recessive grid, per-bar tooltips. */
export function BarsChart(p: { values: number[]; labels: string[]; color: string; tooltip: (i: number, v: number) => string; labelEvery?: number; height?: number; ariaLabel: string }) {
  const data = p.values.map((v, i) => ({ i, v, l: i % (p.labelEvery ?? 1) === 0 ? p.labels[i] : '' }));
  return (
    <div style={{ height: p.height ?? 140 }} role="img" aria-label={p.ariaLabel}>
      <ResponsiveContainer>
        <BarChart data={data} margin={{ top: 8, right: 0, bottom: 0, left: 0 }}>
          <CartesianGrid vertical={false} stroke={T.outline} strokeWidth={0.5} />
          <XAxis dataKey="l" axisLine={{ stroke: T.outline, strokeWidth: 0.5 }} tickLine={false} tick={{ fill: T.textSecondary, fontSize: 10 }} interval={0} />
          <YAxis hide />
          <Tooltip {...tooltipStyle} labelFormatter={() => ''} formatter={(v, _n, item) => [p.tooltip((item.payload as { i: number }).i, Number(v)), '']} separator="" />
          <Bar dataKey="v" fill={p.color} radius={[4, 4, 0, 0]} maxBarSize={p.values.length > 12 ? 6 : 14} isAnimationActive animationDuration={360} />
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}

/** 4-week trend sparkline; null weeks are gaps. */
export function Sparkline({ values, color }: { values: (number | null)[]; color: string }) {
  const data = values.map((v, i) => ({ i, v }));
  return (
    <div style={{ width: 72, height: 28 }} role="img" aria-label={`Last ${values.length} weeks: ${values.map((v) => (v == null ? 'none' : `${Math.round(v * 100)}%`)).join(', ')}`}>
      <ResponsiveContainer>
        <LineChart data={data} margin={{ top: 4, right: 4, bottom: 4, left: 4 }}>
          <YAxis hide domain={[0, 1.05]} />
          <Line
            type="monotone" dataKey="v" stroke={color} strokeWidth={2} isAnimationActive={false}
            dot={(props: { cx?: number; cy?: number; index?: number }) =>
              props.index === values.length - 1 && props.cx != null ? (
                <circle key="last" cx={props.cx} cy={props.cy} r={3} fill={color} stroke={T.surface} strokeWidth={2} />
              ) : (
                <g key={props.index} />
              )
            }
          />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
}

/** Donut of completed tasks per tag, direct-labelled legend; 7+ fold to Other. */
export function CategoryDonut({ entries }: { entries: [string, number][] }) {
  const top = entries.slice(0, categoryPalette.length);
  const rest = entries.slice(categoryPalette.length).reduce((a, [, n]) => a + n, 0);
  const slices = [...top.map(([k, v], i) => ({ k, v, c: categoryPalette[i] })), ...(rest ? [{ k: 'Other', v: rest, c: otherColor }] : [])];
  const total = slices.reduce((a, s) => a + s.v, 0);
  return (
    <div className="row" style={{ gap: 20, alignItems: 'center' }}>
      <div style={{ width: 132, height: 132, position: 'relative', flex: 'none' }}>
        <ResponsiveContainer>
          <PieChart>
            <Pie data={slices} dataKey="v" nameKey="k" innerRadius={44} outerRadius={64} paddingAngle={2} startAngle={90} endAngle={-270} stroke="none" isAnimationActive animationDuration={360}>
              {slices.map((s) => <Cell key={s.k} fill={s.c} />)}
            </Pie>
            <Tooltip {...tooltipStyle} />
          </PieChart>
        </ResponsiveContainer>
        <div style={{ position: 'absolute', inset: 0, display: 'grid', placeItems: 'center', pointerEvents: 'none', textAlign: 'center' }}>
          <div>
            <div className="mono" style={{ fontSize: 22 }}>{total}</div>
            <div className="body-s">done</div>
          </div>
        </div>
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        {slices.map((s) => (
          <div key={s.k} className="row" style={{ padding: '4px 0' }}>
            <span style={{ width: 10, height: 10, borderRadius: 3, background: s.c, flex: 'none' }} />
            <span className="truncate" style={{ flex: 1 }}>{s.k}</span>
            <span className="mono muted" style={{ fontSize: 13 }}>{s.v}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

/** 12-week grid of daily completion %, one hue (coral) dim → bright. */
export function ConsistencyHeatmap(p: { days: Map<Day, DayCompletion>; start: Day; today: Day; onTap?: (d: Day) => void }) {
  const color = (c?: DayCompletion) => {
    if (!c || c.tier === 'future' || c.tier === 'beforeFirstUse') return T.surface;
    const r = DC.rate(c);
    if (c.tier === 'rest' || r == null) return T.surfaceHigh;
    if (r <= 0) return `${T.coral}1f`;
    if (r < 0.5) return `${T.coral}59`;
    if (r < 0.8) return `${T.coral}99`;
    if (r < 1) return `${T.coral}cc`;
    return T.coral;
  };
  return (
    <div style={{ display: 'grid', gridTemplateColumns: '20px repeat(12, 1fr)', gap: 4 }}>
      {Array.from({ length: 7 }, (_, row) => (
        <div key={row} style={{ display: 'contents' }}>
          <span style={{ fontSize: 9, color: T.textSecondary, alignSelf: 'center' }}>{row % 2 === 0 ? weekdayLetters[Days.weekday(Days.add(p.start, row)) - 1] : ''}</span>
          {Array.from({ length: 12 }, (_, w) => {
            const d = Days.add(p.start, w * 7 + row);
            const c = p.days.get(d);
            const pct = c ? DC.percent(c) : null;
            return (
              <button
                key={d}
                type="button"
                disabled={!p.onTap || d > p.today}
                onClick={() => p.onTap?.(d)}
                aria-label={`${Days.date(d)} ${monthLong[Days.month(d) - 1].slice(0, 3)}: ${pct == null ? 'no tasks' : `${pct}%`}`}
                title={`${Days.date(d)} ${monthLong[Days.month(d) - 1].slice(0, 3)} · ${pct == null ? '–' : `${pct}%`}`}
                style={{ aspectRatio: '1', maxHeight: 22, borderRadius: 4, background: color(c), border: d === p.today ? `1.5px solid ${T.ice}` : undefined }}
              />
            );
          })}
        </div>
      ))}
    </div>
  );
}

/** One segment per occurrence: mint done, coral missed, outline upcoming, grey skipped. */
export function SegmentedBar({ segments }: { segments: OccurrenceStatus[] }) {
  if (!segments.length) return <div style={{ height: 8, borderRadius: 4, background: T.surfaceHigh }} />;
  return (
    <div className="row" style={{ gap: 3 }}>
      {segments.map((s, i) => (
        <span
          key={i}
          style={{
            flex: 1, height: 8, borderRadius: 4,
            background: s === 'done' ? T.mint : s === 'missed' ? T.coral : s === 'skipped' ? 'rgba(164, 161, 156,0.4)' : 'transparent',
            border: s === 'pending' ? `1px solid ${T.outline}` : undefined,
          }}
        />
      ))}
    </div>
  );
}

export function ChartLegend({ items, ink = T.textSecondary }: { items: [string, string, boolean][]; ink?: string }) {
  return (
    <div className="row wrap" style={{ gap: 14 }}>
      {items.map(([c, label, dashed]) => (
        <span key={label} className="row" style={{ gap: 6, fontSize: 11, color: ink }}>
          {dashed ? <span style={{ width: 16, borderTop: `2px dashed ${c}` }} /> : <span style={{ width: 12, height: 8, borderRadius: 2, background: c }} />}
          {label}
        </span>
      ))}
    </div>
  );
}
