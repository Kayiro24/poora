import { useState } from 'react';
import { useNavigate } from 'react-router';
import { create } from 'zustand';
import { db, useDb } from '../../../core/db/store';
import { getSettings, useNow, useOccurrences, useSettings, useToday } from '../../../core/hooks';
import { Feedback } from '../../../core/platform/feedback';
import { css, T } from '../../../core/theme/tokens';
import { Range, type Day } from '../../../core/time/days';
import { Fmt } from '../../../core/time/format';
import { Icon } from '../../../core/widgets/Icon';
import { confirm, prompt } from '../../../core/widgets/overlays';
import { ArrowButton, EmptyState, Group, IconButton, NumberSheet, Pill, ScreenHeader, SectionTitle, Sheet, SRow } from '../../../core/widgets/widgets';
import { newId, Occ } from '../../tasks/domain/models';
import { focusDurations } from '../../tasks/ui/tasksUi';
import { FocusController, useFocus } from '../application/focusController';
import { FocusCfg, type FocusConfig } from '../domain/timerEngine';
import { DailyGoalCard, FocusRules } from './FocusRules';

export const builtInPresets: [string, FocusConfig][] = [
  ['25 / 5', { focusMin: 25, shortMin: 5, longMin: 15, longEvery: 4 }],
  ['50 / 10', { focusMin: 50, shortMin: 10, longMin: 30, longEvery: 3 }],
  ['90 / 20', { focusMin: 90, shortMin: 20, longMin: 30, longEvery: 2 }],
];
const MAX_SAVED = 6;

/** The pre-start screen's editable config (opens with last used) and linked task. */
export const useFocusDraft = create<{ config: FocusConfig | null; link: { taskId: string; date: Day } | null }>(() => ({ config: null, link: null }));
export const resetFocusDraft = () => useFocusDraft.setState({ config: null, link: null });

export function startFocus(config: FocusConfig) {
  Feedback.light();
  FocusController.start(config, useFocusDraft.getState().link);
  useFocusDraft.setState({ link: null });
}

export function FocusScreen() {
  const navigate = useNavigate();
  const settings = useSettings();
  const draft = useFocusDraft((s) => s.config) ?? settings.lastFocus;
  const set = (c: FocusConfig) => useFocusDraft.setState({ config: c });
  const now = useNow(15_000);
  const running = useFocus((s) => !!s.session);
  const [picker, setPicker] = useState<keyof FocusConfig | 'custom' | null>(null);

  const rows: [keyof FocusConfig, string, number, number, number, string][] = [
    ['focusMin', 'Focus length', 5, 180, 5, 'min'],
    ['shortMin', 'Short break', 1, 60, 1, 'min'],
    ['longMin', 'Long break', 5, 60, 1, 'min'],
    ['longEvery', 'Long break after every', 2, 8, 1, 'sessions'],
  ];
  const active = rows.find((r) => r[0] === picker) ?? (picker === 'custom' ? rows[0] : null);

  return (
    <div className="page wide">
      <div className="focus-layout">
        <section className="panel sage">
          <ScreenHeader
            title="Focus"
            onPastel
            trailing={
              <div className="row" style={{ gap: 8 }}>
                <IconButton icon="history" white label="Focus history" onClick={() => navigate('/focus/history')} />
                <IconButton icon="tune" white label="Focus settings" onClick={() => navigate('/focus/settings')} />
              </div>
            }
          />
          <div style={{ maxWidth: 300, margin: '16px auto 0' }}>
            <FocusDial config={draft} now={now} use24h={settings.use24h} />
          </div>
          <div className="row mono" style={{ fontSize: 12, color: 'rgba(21, 21, 23,0.7)', marginTop: 12 }}>
            <span>{Fmt.utcOffset(now)}</span>
            <span className="spacer" />
            <span>{Fmt.time(now, settings.use24h)}</span>
          </div>
          <button
            type="button"
            className="btn dark block"
            style={{ height: 64, fontSize: 26, marginTop: 16 }}
            onClick={() => (running ? navigate('/focus/run') : startFocus(draft))}
          >
            <Icon name="play" size={28} />
            {running ? 'Return to session' : 'Start focus'}
          </button>
        </section>

        <div className="stack-l">
          {/* One-tap focus lengths (15 / 25 / 45 / 60 min). */}
          <div className="quick-durations" role="group" aria-label="Focus length">
            {focusDurations.map((m) => (
              <button key={m} type="button" aria-pressed={draft.focusMin === m} onClick={() => set({ ...draft, focusMin: m })}>
                {m} min
              </button>
            ))}
          </div>
          <DailyGoalCard />
          <FocusRules />
          {settings.lastFocusAt != null && (
            <div className="card row" style={{ padding: '16px 12px 16px 20px' }}>
              <div style={{ flex: 1 }}>
                <div className="display d16 muted">Last used</div>
                <div style={{ marginTop: 6 }}>
                  {settings.lastFocus.focusMin} min focus · {settings.lastFocus.shortMin} min break · {Fmt.ago(new Date(settings.lastFocusAt), now)}
                </div>
              </div>
              <ArrowButton label="Start with last used settings" onClick={running ? undefined : () => startFocus(getSettings().lastFocus)} />
            </div>
          )}

          <section>
            <SectionTitle>Break timings</SectionTitle>
            <Group title="Per cycle">
              {rows.map(([key, label, , , , unit]) => (
                <SRow
                  key={key}
                  title={label}
                  onClick={() => setPicker(key)}
                  trailing={
                    <span className="row" style={{ gap: 4 }}>
                      <span className="mono" style={{ fontSize: 18, color: T.sage }}>{draft[key]}</span>
                      <span className="body-s">{unit}</span>
                      <Icon name="chevronRight" className="icon muted" />
                    </span>
                  }
                />
              ))}
            </Group>
          </section>

          <section>
            <SectionTitle>Presets</SectionTitle>
            <Presets draft={draft} onSelect={set} onCustom={() => setPicker('custom')} />
          </section>

          <LinkTask />
        </div>
      </div>

      {active && (
        <NumberSheet
          open
          title={active[1]}
          min={active[2]}
          max={active[3]}
          step={active[4]}
          value={draft[active[0]]}
          unit={active[5]}
          onPick={(v) => {
            set({ ...draft, [active[0]]: v });
            setPicker(null);
          }}
          onClose={() => setPicker(null)}
        />
      )}
    </div>
  );
}

function Presets({ draft, onSelect, onCustom }: { draft: FocusConfig; onSelect: (c: FocusConfig) => void; onCustom: () => void }) {
  const saved = useDb((s) => s.presets);
  const all: [string, FocusConfig, string | null][] = [
    ...builtInPresets.map(([n, c]) => [n, c, null] as [string, FocusConfig, null]),
    ...[...saved].sort((a, b) => a.sort - b.sort).map((p) => [p.name, { focusMin: p.focusMin, shortMin: p.shortMin, longMin: p.longMin, longEvery: p.longEvery }, p.id] as [string, FocusConfig, string]),
  ];
  const matched = all.some(([, c]) => FocusCfg.equal(c, draft));
  const save = async () => {
    const name = await prompt({ title: 'Save preset', action: 'Save', input: { placeholder: 'Name', initial: FocusCfg.label(draft), maxLength: 16 } });
    if (!name) return;
    db().upsertPreset({ id: newId(), name, ...draft, sort: saved.length });
  };
  const remove = async (id: string, name: string) => {
    if (await confirm({ title: 'Delete preset?', body: `“${name}” will be removed.`, action: 'Delete', cancel: 'Keep', danger: true })) db().deletePreset(id);
  };
  return (
    <div className="chip-row">
      {all.map(([name, c, id]) => {
        const sel = FocusCfg.equal(c, draft);
        return (
          <span key={id ?? name} className="row" style={{ gap: 0 }}>
            <Pill label={name} filled={sel} color={sel ? T.sage : undefined} onClick={() => { Feedback.selection(); onSelect(c); }} />
            {id && (
              <button type="button" className="text-btn" aria-label={`Delete preset ${name}`} title="Delete preset" onClick={() => remove(id, name)} style={{ padding: 6, color: T.textSecondary }}>
                <Icon name="close" size={14} />
              </button>
            )}
          </span>
        );
      })}
      <Pill label="Custom" filled={!matched} color={!matched ? T.sage : undefined} onClick={onCustom} />
      {!matched && saved.length < MAX_SAVED && <Pill label="Save preset" icon="plus" onClick={save} />}
    </div>
  );
}

function LinkTask() {
  const link = useFocusDraft((s) => s.link);
  const today = useToday();
  const occ = useOccurrences(Range.day(today));
  const [open, setOpen] = useState(false);
  const linked = link ? occ.find((o) => o.task.id === link.taskId && o.originalDate === link.date) : undefined;
  const pending = occ.filter((o) => o.status === 'pending');
  return (
    <div className="row">
      <Pill label={linked ? linked.title : 'Link a task'} icon="link" filled={!!linked} color={linked ? css(linked.task.color) : undefined} onClick={() => setOpen(true)} />
      {linked && <IconButton icon="close" small label="Unlink task" onClick={() => useFocusDraft.setState({ link: null })} />}
      <Sheet open={open} onClose={() => setOpen(false)} label="Link a task">
        <h2 className="display d24" style={{ margin: '4px 0 12px' }}>Link a task</h2>
        {pending.length === 0 ? (
          <EmptyState message="No open tasks today." compact />
        ) : (
          pending.map((o) => (
            <button
              key={Occ.key(o)}
              type="button"
              className="list-item body-l"
              onClick={() => {
                useFocusDraft.setState({ link: { taskId: o.task.id, date: o.originalDate } });
                setOpen(false);
              }}
            >
              <span style={{ width: 12, height: 12, borderRadius: '50%', background: css(o.task.color) }} />
              {o.title}
            </button>
          ))
        )}
      </Sheet>
    </div>
  );
}

/** White clock face, fine ticks; focus arc coral, break arc sageDeep, from now. */
/** Paper clock face: minute dots, five-minute bars, quarter numerals, focus then break arc (after a small gap), and a notch at "now". */
export function FocusDial({ config, now, use24h }: { config: FocusConfig; now: Date; use24h: boolean }) {
  const end = new Date(now.getTime() + config.focusMin * 60000);
  const span = Math.ceil((config.focusMin + config.shortMin) / 60) * 60;
  const startAngle = ((now.getMinutes() + now.getSeconds() / 60) / 60) * 360;
  const R = 100, AR = 62, C = 2 * Math.PI * AR, GAP = 0.06 * AR;
  const focusLen = (config.focusMin / span) * C;
  const breakLen = (config.shortMin / span) * C;
  const rad = ((startAngle - 90) * Math.PI) / 180;
  const at = (a: number, r: number) => [100 + Math.cos(a) * r, 100 + Math.sin(a) * r] as const;
  const [tx, ty] = at(rad, R - 11);
  const side = [-Math.sin(rad), Math.cos(rad)];
  const [bx, by] = at(rad, R - 3);
  const [hx, hy] = at(rad, AR);
  return (
    <div role="img" aria-label={`Plan: ${config.focusMin} minutes focus, ${config.shortMin} minutes break, ending at ${Fmt.time(end, use24h)}`} style={{ position: 'relative' }}>
      <svg viewBox="0 0 200 200" style={{ width: '100%', display: 'block' }}>
        <circle cx="100" cy="100" r={R} fill={T.paper} />
        <circle cx="100" cy="100" r={R - 2} fill="none" stroke={T.textInverse} strokeOpacity={0.08} strokeWidth="0.5" />
        {Array.from({ length: 60 }, (_, i) => {
          const a = (i / 60) * 2 * Math.PI - Math.PI / 2;
          if (i % 5 !== 0) {
            const [x, y] = at(a, R - 7);
            return <circle key={i} cx={x} cy={y} r="0.55" fill={T.textInverse} fillOpacity={0.3} />;
          }
          const [x1, y1] = at(a, R - 9.5);
          const [x2, y2] = at(a, R - 6);
          return <line key={i} x1={x1} y1={y1} x2={x2} y2={y2} stroke={T.textInverse} strokeOpacity={0.75} strokeWidth="1.2" strokeLinecap="round" />;
        })}
        {span === 60 &&
          [0, 15, 30, 45].map((m) => {
            const [x, y] = at((m / 60) * 2 * Math.PI - Math.PI / 2, R - 15);
            return (
              <text key={m} x={x} y={y} textAnchor="middle" dominantBaseline="central" className="mono" fontSize="5" fill={T.textInverse} fillOpacity={0.45}>
                {String(m).padStart(2, '0')}
              </text>
            );
          })}
        <circle cx="100" cy="100" r={AR} fill="none" stroke={T.sage} strokeOpacity={0.3} strokeWidth="6" />
        <g transform={`rotate(${startAngle - 90} 100 100)`}>
          {breakLen > GAP * 2 && (
            <circle cx="100" cy="100" r={AR} fill="none" stroke={T.sageDeep} strokeWidth="6" strokeLinecap="round" strokeDasharray={`0 ${focusLen + GAP} ${breakLen - GAP} ${C}`} />
          )}
          <circle cx="100" cy="100" r={AR} fill="none" stroke={T.coral} strokeWidth="6" strokeLinecap="round" strokeDasharray={`${focusLen} ${C}`} />
        </g>
        <path d={`M${tx} ${ty} L${bx + side[0] * 3} ${by + side[1] * 3} L${bx - side[0] * 3} ${by - side[1] * 3} Z`} fill={T.textInverse} />
        <circle cx={hx} cy={hy} r="1.5" fill={T.paper} />
      </svg>
      <div style={{ position: 'absolute', inset: 0, display: 'grid', placeItems: 'center', color: T.textInverse, textAlign: 'center' }}>
        <div>
          <div className="mono" style={{ fontSize: 'clamp(40px, 12vw, 56px)' }}>{config.focusMin}</div>
          <div className="display" style={{ fontSize: 14, opacity: 0.6, marginTop: 4 }}>Min focus</div>
          <div className="mono" style={{ fontSize: 13, opacity: 0.7, marginTop: 8 }}>→ {Fmt.time(end, use24h)}</div>
        </div>
      </div>
    </div>
  );
}
