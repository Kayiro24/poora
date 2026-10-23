import { T } from '../../../core/theme/tokens';

export function fmtMs(ms: number): string {
  const m = Math.round(ms / 60000);
  if (ms > 0 && m === 0) return '<1 min';
  if (m < 60) return `${m} min`;
  return m % 60 === 0 ? `${Math.floor(m / 60)} h` : `${Math.floor(m / 60)} h ${m % 60} min`;
}

/** The four kinds of time, always shown apart and labelled the same way (as in the app). */
export function FocusBreakdown(p: {
  focusMs: number;
  pausedMs: number;
  awayMs: number;
  interruptions: number;
  appUsageMs: number;
  distractions?: [string, number][];
  dense?: boolean;
}) {
  const rows: [string, string, string, string][] = [
    ['Focus', fmtMs(p.focusMs), 'timer running', T.sage],
    ['Paused', fmtMs(p.pausedMs), 'you paused', T.textSecondary],
    ['Away', `${fmtMs(p.awayMs)} · ${p.interruptions}×`, 'left the tab', T.coralSoft],
    ['App use', fmtMs(p.appUsageMs), 'Poora on screen', T.ice],
  ];
  const apps = p.distractions ?? [];
  return (
    <div className={`breakdown${p.dense ? ' dense' : ''}`}>
      {rows.map(([label, value, hint, color]) => (
        <div key={label} className="line">
          <span className="dot" style={{ background: color }} />
          <span className="name">
            {label}
            {!p.dense && <span className="hint">{hint}</span>}
          </span>
          <span className="mono" style={{ fontSize: p.dense ? 12 : 14 }}>{value}</span>
        </div>
      ))}
      {apps.length > 0 && (
        <>
          <p className="caps-label" style={{ margin: '6px 0 0' }}>Distracting apps (Android)</p>
          {apps.slice(0, p.dense ? 2 : 5).map(([pkg, ms]) => (
            <div key={pkg} className="line">
              <span className="name truncate" style={{ fontWeight: 400 }}>{pkg}</span>
              <span className="mono" style={{ fontSize: 12, color: T.coralSoft }}>{fmtMs(ms)}</span>
            </div>
          ))}
        </>
      )}
    </div>
  );
}
