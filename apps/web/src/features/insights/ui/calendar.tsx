import { useEffect, useRef, useState } from 'react';
import { create } from 'zustand';
import { useOccurrences, useReducedMotion, useSettings, useToday } from '../../../core/hooks';
import { Feedback } from '../../../core/platform/feedback';
import { css, T } from '../../../core/theme/tokens';
import { Days, Range, type Day } from '../../../core/time/days';
import { monthLong, weekdayLetters, weekdayLong } from '../../../core/time/format';
import { Icon } from '../../../core/widgets/Icon';
import { CompletionRing, Pill, Sheet } from '../../../core/widgets/widgets';
import { TasksRepository } from '../../tasks/data/tasksRepository';
import { Occ, type Occurrence } from '../../tasks/domain/models';
import { TaskCard, timeLabel } from '../../tasks/ui/TaskCard';
import { Filters, useInsights, type CalendarFilter } from '../data/insightsRepository';
import { DC } from '../domain/metrics';
import { DayCell, tierColor } from './DayCell';

let pulsedDay: Day | null = null;

/** Month grid with consecutive perfect days joined by a soft green pill; 7+ streak gets 🔥. */
export function CompletionMonthGrid({ month, filter = Filters.all, onDayTap }: { month: Day; filter?: CalendarFilter; onDayTap?: (d: Day) => void }) {
  const repo = useInsights();
  const { mondayFirst } = useSettings();
  const today = useToday();
  const reduced = useReducedMotion();
  const m = Range.month(month);
  const gridStart = Days.weekStart(m.from, mondayFirst);
  const weeks = Math.ceil((Days.between(gridStart, m.to) + 1) / 7);
  const grid = Range.of(gridStart, Days.add(gridStart, weeks * 7 - 1));
  const days = repo.dayCompletion(grid, filter);
  const quotaTask = filter.seriesId ? repo.seriesTask(filter.seriesId) : null;
  const isQuota = quotaTask?.repeatKind === 'quota';
  // Rings draw in with a 20 ms stagger on mount only (parents key this by month).
  const [settled, setSettled] = useState(false);
  useEffect(() => {
    const id = setTimeout(() => setSettled(true), 900);
    return () => clearTimeout(id);
  }, []);

  // Run length of perfect days (continues across rows; rest days don't break it).
  const runAt = new Map<Day, number>();
  let run = 0;
  for (const d of Range.days(grid)) {
    const c = days.get(d)!;
    if (c.tier === 'perfect') run++;
    else if (c.tier !== 'rest' || run === 0) run = 0;
    runAt.set(d, c.tier === 'perfect' ? run : 0);
  }

  // Today's ring just closed → one soft pulse + haptic, once per day.
  const pulseToday = days.get(today)?.tier === 'perfect' && pulsedDay !== today && Range.contains(grid, today);
  useEffect(() => {
    if (pulseToday) {
      pulsedDay = today;
      Feedback.success();
    }
  }, [pulseToday, today]);

  const names = Array.from({ length: 7 }, (_, i) => weekdayLetters[(i + (mondayFirst ? 0 : 6)) % 7]);
  let index = 0;
  const cols = isQuota ? '1fr 44px' : '1fr';
  return (
    <div>
      <div style={{ display: 'grid', gridTemplateColumns: cols }}>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)' }}>
          {names.map((n, i) => <span key={i} style={{ textAlign: 'center', fontSize: 11, color: T.textSecondary }}>{n}</span>)}
        </div>
      </div>
      {Array.from({ length: weeks }, (_, w) => {
        const rowDays = Array.from({ length: 7 }, (_, i) => Days.add(gridStart, w * 7 + i));
        const perfect = rowDays.map((d) => days.get(d)!.tier === 'perfect' && Days.month(d) === Days.month(m.from));
        return (
          <div key={w} style={{ display: 'grid', gridTemplateColumns: cols, alignItems: 'center', marginTop: 4 }}>
            <div style={{ position: 'relative', display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)' }}>
              {/* Streak pills */}
              {perfect.map((p, i) => {
                if (!p || (i > 0 && perfect[i - 1])) return null;
                let j = i;
                while (j + 1 < 7 && perfect[j + 1]) j++;
                if (j === i) return null;
                return (
                  <span
                    key={`s${i}`}
                    aria-hidden
                    style={{
                      position: 'absolute', top: 2, bottom: 2, borderRadius: 999, background: `${T.dayPerfect}29`,
                      left: `calc(${(i / 7) * 100}% + 2px)`, width: `calc(${((j - i + 1) / 7) * 100}% - 4px)`,
                    }}
                  />
                );
              })}
              {rowDays.map((d) => {
                const c = days.get(d)!;
                const inMonth = Days.month(d) === Days.month(m.from);
                const endsStreak = (runAt.get(d) ?? 0) >= 7 && days.get(Days.add(d, 1))?.tier !== 'perfect';
                const delay = !settled && !reduced ? 20 * index++ : 0;
                return (
                  <div key={d} style={{ position: 'relative', visibility: inMonth ? 'visible' : 'hidden' }}>
                    <DayCell
                      completion={c}
                      isToday={d === today}
                      delayMs={delay}
                      pulse={pulseToday && d === today}
                      onTap={onDayTap && d <= today && c.tier !== 'beforeFirstUse' ? () => onDayTap(d) : undefined}
                    />
                    {endsStreak && <span aria-hidden style={{ position: 'absolute', top: -2, right: '18%', fontSize: 12 }}>🔥</span>}
                  </div>
                );
              })}
            </div>
            {isQuota && (() => {
              const done = repo.quotaDone(filter.seriesId!, rowDays[0]);
              const q = quotaTask!.quotaPerWeek ?? 1;
              return (
                <span className="mono" style={{ fontSize: 11, textAlign: 'right', color: done >= q ? T.dayPerfect : T.textSecondary }}>
                  {done}/{q}{done >= q ? ' ✓' : ''}
                </span>
              );
            })()}
          </div>
        );
      })}
    </div>
  );
}

/** GitHub-style 53×7 year grid, auto-scrolled to today. */
export function CompletionYearGrid({ filter, onDayTap }: { filter: CalendarFilter; onDayTap: (d: Day) => void }) {
  const repo = useInsights();
  const { mondayFirst } = useSettings();
  const today = useToday();
  const scroller = useRef<HTMLDivElement>(null);
  const end = Days.add(Days.weekStart(today, mondayFirst), 6);
  const start = Days.add(end, -53 * 7 + 1);
  const days = repo.dayCompletion(Range.of(start, end), filter);
  useEffect(() => {
    scroller.current?.scrollTo({ left: scroller.current.scrollWidth });
  }, []);
  const cell = 14, gap = 3;
  return (
    <div ref={scroller} style={{ overflowX: 'auto', paddingBottom: 8 }}>
      <div style={{ display: 'flex', gap, height: 16, marginBottom: 4 }}>
        {Array.from({ length: 53 }, (_, w) => {
          const d = Days.add(start, w * 7);
          return (
            <span key={w} style={{ width: cell, flex: 'none', fontSize: 10, color: T.textSecondary, whiteSpace: 'nowrap', overflow: 'visible' }}>
              {Days.date(d) <= 7 ? monthLong[Days.month(d) - 1].slice(0, 3) : ''}
            </span>
          );
        })}
      </div>
      <div style={{ display: 'flex', gap }}>
        {Array.from({ length: 53 }, (_, w) => (
          <div key={w} style={{ display: 'flex', flexDirection: 'column', gap }}>
            {Array.from({ length: 7 }, (_, i) => {
              const d = Days.add(start, w * 7 + i);
              const c = days.get(d)!;
              const color = c.tier === 'future' || c.tier === 'beforeFirstUse' ? T.surface : c.tier === 'rest' ? T.dayEmpty : c.tier === 'today' ? `${T.ice}80` : tierColor(c.tier);
              return (
                <button
                  key={d}
                  type="button"
                  aria-label={`${Days.date(d)} ${monthLong[Days.month(d) - 1].slice(0, 3)} ${Days.year(d)}: ${c.tier}`}
                  disabled={d > today}
                  onClick={() => onDayTap(d)}
                  style={{ width: cell, height: cell, borderRadius: 4, background: color, border: d === today ? `1px solid ${T.ice}` : undefined }}
                />
              );
            })}
          </div>
        ))}
      </div>
    </div>
  );
}

export function TierLegend() {
  const [open, setOpen] = useState(false);
  const items = [
    ['perfect', '100%', 'check'],
    ['high', '80–99%', null],
    ['mid', '50–79%', null],
    ['low', '1–49%', null],
    ['missed', '0%', 'close'],
  ] as const;
  return (
    <div>
      <button type="button" className="row body-s" style={{ padding: '6px 0' }} onClick={() => setOpen(!open)} aria-expanded={open}>
        Legend <Icon name={open ? 'collapse' : 'expand'} size={18} />
      </button>
      {open && (
        <div className="row wrap" style={{ gap: 12 }}>
          {items.map(([tier, label, icon]) => (
            <span key={tier} className="row" style={{ gap: 6 }}>
              <span style={{ width: 18, height: 18, borderRadius: '50%', background: `${tierColor(tier)}4d`, border: `2px solid ${tierColor(tier)}`, display: 'grid', placeItems: 'center' }}>
                {icon && <Icon name={icon} size={10} />}
              </span>
              <span className="body-s">{label}</span>
            </span>
          ))}
          <span className="row" style={{ gap: 6 }}>
            <span style={{ width: 6, height: 6, borderRadius: '50%', background: T.outline }} />
            <span className="body-s">Rest day</span>
          </span>
        </div>
      )}
    </div>
  );
}

// ---------------------------------------------------------------- Day detail sheet

const useDaySheet = create<{ day: Day | null }>(() => ({ day: null }));
export const openDaySheet = (day: Day) => useDaySheet.setState({ day });

export function DaySheetHost() {
  const day = useDaySheet((s) => s.day);
  return (
    <Sheet open={!!day} onClose={() => useDaySheet.setState({ day: null })} tall label="Day detail">
      {day && <DaySheet day={day} />}
    </Sheet>
  );
}

function DaySheet({ day }: { day: Day }) {
  const repo = useInsights();
  const { use24h } = useSettings();
  const c = repo.dayCompletion(Range.day(day)).get(day)!;
  const occ = useOccurrences(Range.day(day));
  const focus = repo.focusMinutesOn(day);
  const groups: [string, Occurrence[]][] = [
    ['Done', occ.filter((o) => o.status === 'done')],
    ['Missed', occ.filter((o) => o.status === 'missed')],
    ['Still open', occ.filter((o) => o.status === 'pending')],
    ['Skipped', occ.filter((o) => o.status === 'skipped')],
  ];
  const ringColor = c.tier === 'today' ? T.ice : c.tier === 'rest' ? T.outline : tierColor(c.tier);
  const pct = DC.percent(c);
  return (
    <div>
      <div className="row" style={{ gap: 16 }}>
        <CompletionRing value={c.tier === 'missed' ? 1 : (DC.rate(c) ?? 0)} color={ringColor} size={72} stroke={6}>
          <span className="mono" style={{ fontSize: 15 }}>{pct == null ? '–' : `${pct}%`}</span>
        </CompletionRing>
        <div>
          <h2 className="display d32">{weekdayLong[Days.weekday(day) - 1]} {Days.date(day)} {monthLong[Days.month(day) - 1].slice(0, 3)}</h2>
          <p className="muted" style={{ margin: '4px 0 0', fontSize: 15 }}>{DC.scheduled(c) === 0 ? 'Rest day' : `${c.done} of ${DC.scheduled(c)} done`}</p>
        </div>
      </div>
      {focus > 0 && (
        <div style={{ marginTop: 12 }}>
          <Pill label={`${Math.round(focus)} min focus`} icon="timer" filled color={T.sage} />
        </div>
      )}
      {groups.map(([title, list]) =>
        list.length ? (
          <section key={title} style={{ marginTop: 20 }}>
            <h3 className="display d16 muted" style={{ marginBottom: 8 }}>{title}</h3>
            <div className="stack">
              {list.map((o) =>
                o.status === 'missed' ? (
                  <div key={Occ.key(o)} className="row" style={{ background: T.surfaceHigh, borderRadius: 'var(--r-inner)', overflow: 'hidden', gap: 0 }}>
                    <span style={{ width: 4, alignSelf: 'stretch', background: css(o.task.color) }} />
                    <div style={{ flex: 1, minWidth: 0, padding: '10px 12px' }}>
                      <div className="display d18 truncate">{o.title}</div>
                      <div className="mono body-s" style={{ marginTop: 2 }}>{[timeLabel(o, use24h), o.task.tag].filter(Boolean).join(' · ')}</div>
                    </div>
                    <button type="button" className="text-btn mint" onClick={() => { Feedback.success(); TasksRepository.setDone(o, true); }}>
                      Mark done
                    </button>
                    <button type="button" className="text-btn" style={{ color: T.textSecondary }} onClick={() => TasksRepository.setSkipped(o, true)}>
                      Skip
                    </button>
                  </div>
                ) : (
                  <TaskCard key={Occ.key(o)} occurrence={o} swipe={false} />
                ),
              )}
            </div>
          </section>
        ) : null,
      )}
      {occ.length === 0 && <p style={{ marginTop: 24 }}>Nothing was scheduled. Rest is part of the rhythm.</p>}
    </div>
  );
}
