import { useState } from 'react';
import { T } from '../../../core/theme/tokens';
import { Days, type Day } from '../../../core/time/days';
import { monthLong, weekdayLetters, weekdayLong } from '../../../core/time/format';
import { Icon } from '../../../core/widgets/Icon';
import { Sheet } from '../../../core/widgets/widgets';
import { Rules, type Freq, type MonthlyMode, type RepeatRule } from '../domain/recurrence';

const ORD = ['first', 'second', 'third', 'fourth', 'fifth'];

/** Quick repeat options, "Times per week…" and "Custom…" (§4.8). */
export function RepeatPicker(p: { open: boolean; start: Day; current: RepeatRule; onPick: (r: RepeatRule) => void; onClose: () => void }) {
  const [mode, setMode] = useState<'list' | 'custom' | 'quota'>('list');
  const close = () => {
    setMode('list');
    p.onClose();
  };
  const pick = (r: RepeatRule) => {
    p.onPick(r);
    close();
  };
  const wd = Days.weekday(p.start);
  const quick: [string, RepeatRule][] = [
    ['Does not repeat', Rules.none],
    ['Every day', Rules.daily()],
    ['Every weekday (Mon–Fri)', Rules.weekdaysOnly()],
    [`Every week on ${weekdayLong[wd - 1]}`, Rules.weeklyOn(p.start)],
    [`Every month on day ${Days.date(p.start)}`, Rules.monthlyOnDay()],
    [`Every year on ${monthLong[Days.month(p.start) - 1]} ${Days.date(p.start)}`, Rules.yearly()],
    ['Every other day', Rules.everyOtherDay()],
  ];
  const sameBase = (a: RepeatRule, b: RepeatRule) => Rules.equal({ ...a, endsOn: null, endsAfter: null }, { ...b, endsOn: null, endsAfter: null });

  return (
    <Sheet open={p.open} onClose={close} label="Repeat" tall={mode !== 'list'}>
      {mode === 'list' && (
        <>
          <h2 className="display d24" style={{ margin: '4px 0 8px' }}>Repeat</h2>
          {quick.map(([label, rule]) => (
            <button
              key={label}
              type="button"
              className="list-item body-l"
              onClick={() => pick(rule.kind === 'none' ? rule : { ...rule, endsOn: p.current.endsOn, endsAfter: p.current.endsAfter })}
            >
              <span style={{ flex: 1 }}>{label}</span>
              {sameBase(rule, p.current) && <Icon name="check" className="icon" />}
            </button>
          ))}
          <button type="button" className="list-item body-l" onClick={() => setMode('quota')}>
            <span style={{ flex: 1 }}>Times per week…</span>
            <Icon name={p.current.kind === 'quota' ? 'check' : 'chevronRight'} />
          </button>
          <button type="button" className="list-item body-l" onClick={() => setMode('custom')}>
            <span style={{ flex: 1 }}>Custom…</span>
            <Icon name="chevronRight" />
          </button>
        </>
      )}
      {mode === 'custom' && (
        <CustomRepeat start={p.start} initial={p.current.kind === 'rrule' ? p.current : Rules.daily()} onDone={pick} onBack={() => setMode('list')} />
      )}
      {mode === 'quota' && (
        <QuotaRepeat start={p.start} initial={p.current.kind === 'quota' ? p.current : Rules.timesPerWeek(3)} onDone={pick} onBack={() => setMode('list')} />
      )}
    </Sheet>
  );
}

function Header({ title, summary, onBack, onDone }: { title: string; summary: string; onBack: () => void; onDone: () => void }) {
  return (
    <>
      <div className="row" style={{ marginBottom: 12 }}>
        <button type="button" className="text-btn" onClick={onBack} aria-label="Back">
          <Icon name="back" />
        </button>
        <h2 className="display d22" style={{ flex: 1 }}>{title}</h2>
        <button type="button" className="text-btn coral" onClick={onDone}>Done</button>
      </div>
      <div style={{ padding: 16, borderRadius: 'var(--r-inner)', background: `${T.coral}24`, color: T.coralSoft, marginBottom: 24 }}>{summary}</div>
    </>
  );
}

function Stepper({ value, min, max, onChange }: { value: number; min: number; max: number; onChange: (v: number) => void }) {
  return (
    <div className="row" style={{ background: T.surfaceHigh, borderRadius: 999, gap: 0, flex: 'none' }}>
      <button type="button" className="text-btn" aria-label="Decrease" disabled={value <= min} onClick={() => onChange(value - 1)}>
        <Icon name="remove" />
      </button>
      <span className="mono" style={{ width: 36, textAlign: 'center', fontSize: 20 }} aria-live="polite">{value}</span>
      <button type="button" className="text-btn" aria-label="Increase" disabled={value >= max} onClick={() => onChange(value + 1)}>
        <Icon name="plus" />
      </button>
    </div>
  );
}

function DayToggles({ selected, onToggle }: { selected: number[]; onToggle: (d: number) => void }) {
  return (
    <div className="row" style={{ justifyContent: 'space-between' }}>
      {weekdayLetters.map((l, i) => {
        const d = i + 1;
        const on = selected.includes(d);
        return (
          <button
            key={d}
            type="button"
            aria-pressed={on}
            aria-label={weekdayLong[i]}
            onClick={() => onToggle(d)}
            style={{ width: 40, height: 40, borderRadius: '50%', fontWeight: 600, background: on ? T.coral : T.surfaceHigh, color: on ? T.textInverse : T.textPrimary }}
          >
            {l}
          </button>
        );
      })}
    </div>
  );
}

function Ends({ rule, start, allowCount, onChange }: { rule: RepeatRule; start: Day; allowCount: boolean; onChange: (r: RepeatRule) => void }) {
  const mode = rule.endsOn ? 'on' : rule.endsAfter != null ? 'after' : 'never';
  const radio = (v: string, label: React.ReactNode, on: () => void) => (
    <label className="list-item body-l" style={{ cursor: 'pointer' }}>
      <input type="radio" name="ends" checked={mode === v} onChange={on} style={{ accentColor: 'var(--coral)', width: 18, height: 18 }} />
      {label}
    </label>
  );
  return (
    <>
      <p className="caps-label" style={{ marginTop: 24 }}>Ends</p>
      {radio('never', 'Never', () => onChange({ ...rule, endsOn: null, endsAfter: null }))}
      {radio(
        'on',
        <>
          On
          <input
            type="date"
            className="input"
            style={{ width: 'auto', padding: '8px 12px' }}
            min={start}
            value={rule.endsOn ?? ''}
            onChange={(e) => e.target.value && onChange({ ...rule, endsOn: e.target.value, endsAfter: null })}
          />
        </>,
        () => onChange({ ...rule, endsOn: rule.endsOn ?? Days.add(start, 30), endsAfter: null }),
      )}
      {allowCount &&
        radio(
          'after',
          <>
            After
            <input
              type="number"
              className="input mono"
              min={1}
              style={{ width: 80, padding: '8px 12px', textAlign: 'center' }}
              value={rule.endsAfter ?? 10}
              onChange={(e) => Number(e.target.value) > 0 && onChange({ ...rule, endsOn: null, endsAfter: Number(e.target.value) })}
            />
            occurrences
          </>,
          () => onChange({ ...rule, endsOn: null, endsAfter: rule.endsAfter ?? 10 }),
        )}
    </>
  );
}

function CustomRepeat({ start, initial, onDone, onBack }: { start: Day; initial: RepeatRule; onDone: (r: RepeatRule) => void; onBack: () => void }) {
  const [r, setR] = useState<RepeatRule>({ ...initial, kind: 'rrule' });
  const wd = Days.weekday(start);
  const nth = Rules.nthOfMonth(start);
  const unit = { daily: 'day', weekly: 'week', monthly: 'month', yearly: 'year' }[r.freq] + (r.interval === 1 ? '' : 's');
  const monthly: [MonthlyMode, string][] = [
    ['dayOfMonth', `On day ${Days.date(start)}`],
    ...(nth <= 4 ? [['nthWeekday', `On the ${ORD[nth - 1]} ${weekdayLong[wd - 1]}`] as [MonthlyMode, string]] : []),
    ...(Days.month(Days.add(start, 7)) !== Days.month(start) ? [['lastWeekday', `On the last ${weekdayLong[wd - 1]}`] as [MonthlyMode, string]] : []),
  ];
  return (
    <>
      <Header title="Custom repeat" summary={Rules.summary(r, start)} onBack={onBack} onDone={() => onDone(r)} />
      <p className="caps-label">Repeat every</p>
      <div className="row">
        <Stepper value={r.interval} min={1} max={99} onChange={(interval) => setR({ ...r, interval })} />
        <select
          className="input"
          value={r.freq}
          aria-label="Frequency"
          onChange={(e) => {
            const freq = e.target.value as Freq;
            setR({ ...r, freq, weekdays: freq === 'weekly' && !r.weekdays.length ? [wd] : r.weekdays });
          }}
        >
          {(['daily', 'weekly', 'monthly', 'yearly'] as Freq[]).map((f) => (
            <option key={f} value={f}>{{ daily: 'day', weekly: 'week', monthly: 'month', yearly: 'year' }[f]}</option>
          ))}
        </select>
      </div>
      <p className="body-s">{unit}</p>
      {r.freq === 'weekly' && (
        <>
          <p className="caps-label" style={{ marginTop: 24 }}>On</p>
          <DayToggles
            selected={r.weekdays}
            onToggle={(d) => {
              const next = r.weekdays.includes(d) ? r.weekdays.filter((x) => x !== d) : [...r.weekdays, d];
              if (next.length) setR({ ...r, weekdays: next });
            }}
          />
        </>
      )}
      {r.freq === 'monthly' && (
        <div style={{ marginTop: 16 }}>
          {monthly.map(([m, label]) => (
            <label key={m} className="list-item body-l" style={{ cursor: 'pointer' }}>
              <input type="radio" name="monthly" checked={r.monthlyMode === m} onChange={() => setR({ ...r, monthlyMode: m })} style={{ accentColor: 'var(--coral)', width: 18, height: 18 }} />
              {label}
            </label>
          ))}
        </div>
      )}
      <Ends rule={r} start={start} allowCount onChange={setR} />
    </>
  );
}

function QuotaRepeat({ start, initial, onDone, onBack }: { start: Day; initial: RepeatRule; onDone: (r: RepeatRule) => void; onBack: () => void }) {
  const [r, setR] = useState<RepeatRule>(initial);
  return (
    <>
      <Header title="Times per week" summary={Rules.summary(r, start)} onBack={onBack} onDone={() => onDone(r)} />
      <p className="caps-label">Do this</p>
      <div className="row">
        <Stepper value={r.quota} min={1} max={7} onChange={(quota) => setR({ ...r, quota })} />
        <span className="body-l">times per week</span>
      </div>
      <p className="body-s" style={{ marginTop: 12 }}>
        Shows on every day until you’ve done it {r.quota} {r.quota === 1 ? 'time' : 'times'}, then hides for the rest of the week.
      </p>
      <p className="caps-label" style={{ marginTop: 24 }}>Preferred days (optional)</p>
      <p className="body-s">Reminders only fire on these days.</p>
      <DayToggles
        selected={r.preferredDays}
        onToggle={(d) => setR({ ...r, preferredDays: r.preferredDays.includes(d) ? r.preferredDays.filter((x) => x !== d) : [...r.preferredDays, d] })}
      />
      <p className="body-s" style={{ marginTop: 12 }}>Set a daily reminder time with “Add reminder” on the task.</p>
      <Ends rule={r} start={start} allowCount={false} onChange={setR} />
    </>
  );
}
