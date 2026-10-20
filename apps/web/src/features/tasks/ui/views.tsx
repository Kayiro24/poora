import { useEffect, useMemo, useRef } from 'react';
import { useGenerator, useNow, useOccurrences, useSettings, useSnapshot, useToday } from '../../../core/hooks';
import { Feedback } from '../../../core/platform/feedback';
import { css, T } from '../../../core/theme/tokens';
import { Days, Range, type Day } from '../../../core/time/days';
import { monthLong, weekdayLetters, weekdayLong, weekdayShort } from '../../../core/time/format';
import { Icon } from '../../../core/widgets/Icon';
import { TimelineRail } from '../../../core/widgets/TimelineRail';
import { EmptyState } from '../../../core/widgets/widgets';
import { useInsights } from '../../insights/data/insightsRepository';
import { DayCell } from '../../insights/ui/DayCell';
import { Occ, type Occurrence } from '../domain/models';
import { AllDayChip, RailCard, TaskCard } from './TaskCard';
import { openEditor, rescheduleOccurrence, TasksView, useTasksView, views, type TaskView } from './tasksUi';

const dayMonth = (d: Day) => `${Days.date(d)} ${monthLong[Days.month(d) - 1].slice(0, 3)}`;

/** Mon–Sun strip with dots; swipe or arrows to change week, tap to jump. */
export function WeekStrip() {
  const { selected } = useTasksView();
  const { mondayFirst } = useSettings();
  const today = useToday();
  const week = Range.week(selected, mondayFirst);
  const occ = useOccurrences(week);
  const busy = new Set(occ.map((o) => o.date));
  const touch = useRef<number | null>(null);
  return (
    <div
      className="row week-strip"
      onTouchStart={(e) => (touch.current = e.touches[0].clientX)}
      onTouchEnd={(e) => {
        if (touch.current == null) return;
        const dx = e.changedTouches[0].clientX - touch.current;
        if (Math.abs(dx) > 60) TasksView.select(Days.add(selected, dx < 0 ? 7 : -7));
        touch.current = null;
      }}
      style={{ padding: '8px 0', gap: 0, background: T.bg }}
    >
      <button type="button" className="text-btn hide-mobile" aria-label="Previous week" onClick={() => TasksView.select(Days.add(selected, -7))}>
        <Icon name="chevronLeft" />
      </button>
      {Range.days(week).map((d) => {
        const sel = d === selected;
        const isToday = d === today;
        return (
          <button
            key={d}
            type="button"
            aria-pressed={sel}
            aria-label={`${weekdayLong[Days.weekday(d) - 1]} ${Days.date(d)}${busy.has(d) ? ', has tasks' : ''}`}
            onClick={() => {
              Feedback.selection();
              TasksView.select(d);
            }}
            style={{
              flex: 1, margin: '0 3px', padding: '8px 0', borderRadius: 16, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4,
              background: sel ? T.coral : 'transparent', color: sel ? T.textInverse : T.textPrimary,
              border: isToday && !sel ? `1px solid ${T.ice}` : '1px solid transparent', transition: 'background 280ms var(--ease)',
            }}
          >
            <span style={{ fontSize: 11, fontWeight: 500, color: sel ? T.textInverse : T.textSecondary }}>{weekdayShort[Days.weekday(d) - 1][0]}</span>
            <span className="mono" style={{ fontSize: 16 }}>{Days.date(d)}</span>
            <span style={{ width: 5, height: 5, borderRadius: '50%', background: busy.has(d) ? (sel ? T.textInverse : T.coral) : 'transparent' }} />
          </button>
        );
      })}
      <button type="button" className="text-btn hide-mobile" aria-label="Next week" onClick={() => TasksView.select(Days.add(selected, 7))}>
        <Icon name="chevronRight" />
      </button>
    </div>
  );
}

/** Day, 3 Day and Week: all-day strip above a 24h rail with a column per day. */
export function TimelineView({ view }: { view: TaskView }) {
  const { selected } = useTasksView();
  const { mondayFirst, use24h } = useSettings();
  const today = useToday();
  const now = useNow(30_000);
  const columns = views.find((v) => v.id === view)!.columns;
  const first = view === 'week' ? Days.weekStart(selected, mondayFirst) : selected;
  const days = Array.from({ length: columns }, (_, i) => Days.add(first, i));
  const occ = useOccurrences(Range.of(days[0], days[days.length - 1]));
  const todayCol = days.indexOf(today);
  const root = useRef<HTMLDivElement>(null);
  const timed = occ.filter(Occ.isTimed);
  const allDay = occ.filter((o) => !Occ.isTimed(o));
  const next = timed
    .filter((o) => o.status === 'pending' && Occ.startAt(o)!.getTime() > now.getTime())
    .sort((a, b) => Occ.startAt(a)!.getTime() - Occ.startAt(b)!.getTime())[0];

  const rangeKey = `${days[0]}|${columns}`;
  useEffect(() => {
    root.current?.querySelector('[data-rail-anchor]')?.scrollIntoView({ block: 'center', behavior: 'smooth' });
  }, [rangeKey]);

  return (
    <div ref={root}>
      {columns > 1 && (
        <div className="row" style={{ paddingLeft: 52, gap: 0 }}>
          {days.map((d) => (
            <div key={d} style={{ flex: 1, textAlign: 'center' }}>
              <div style={{ fontSize: 11, color: T.textSecondary }}>{columns > 3 ? weekdayLetters[Days.weekday(d) - 1] : weekdayShort[Days.weekday(d) - 1].toUpperCase()}</div>
              <div className="mono" style={{ fontSize: 15, color: d === today ? T.ice : T.textPrimary }}>{Days.date(d)}</div>
            </div>
          ))}
        </div>
      )}
      {allDay.length > 0 && (
        <div className="row" style={{ alignItems: 'flex-start', padding: '4px 0 8px', gap: 0 }}>
          <span className="mono" style={{ width: 52, paddingRight: 8, paddingTop: 6, textAlign: 'right', fontSize: 10, color: T.textSecondary, flex: 'none' }}>all day</span>
          {days.map((d) => (
            <div key={d} className="row wrap" style={{ flex: 1, minWidth: 0, gap: 4, padding: '0 2px' }}>
              {allDay.filter((o) => o.date === d).map((o) => <AllDayChip key={Occ.key(o)} occurrence={o} />)}
            </div>
          ))}
        </div>
      )}
      {columns === 1 && <QuotaMet day={days[0]} />}
      <TimelineRail
        columns={columns}
        use24h={use24h}
        now={todayCol >= 0 ? now : null}
        nowColumn={todayCol >= 0 ? todayCol : null}
        anchorMinute={todayCol >= 0 ? now.getHours() * 60 + now.getMinutes() : 8 * 60}
        items={timed.map((o) => ({
          id: Occ.key(o),
          column: days.indexOf(o.date),
          startMinute: o.startMinute!,
          durationMin: Occ.duration(o),
          content: <RailCard occurrence={o} highlight={o === next} />,
        }))}
        onCreate={(col, start, dur) => openEditor({ date: days[col], startMinute: start, durationMin: dur })}
        onMove={(id, col, start) => {
          const o = timed.find((x) => Occ.key(x) === id);
          if (o) void rescheduleOccurrence(o, days[col], start);
        }}
      />
    </div>
  );
}

/** Collapsed group of times-per-week tasks whose quota is met. */
function QuotaMet({ day }: { day: Day }) {
  const snapshot = useSnapshot();
  const gen = useGenerator();
  const visible = new Set(useOccurrences(Range.day(day)).map((o) => o.task.id));
  const met = snapshot.tasks
    .filter((t) => t.repeatKind === 'quota' && !visible.has(t.id) && gen.occursOn(t, day))
    .map((t) => [t, gen.quotaDone(t, day, snapshot.records)] as const)
    .filter(([t, n]) => n >= (t.quotaPerWeek ?? 1));
  if (!met.length) return null;
  return (
    <div className="chip-row" style={{ padding: '0 0 8px 56px' }}>
      {met.map(([t, n]) => (
        <span key={t.id} className="pill dense muted">{t.title} · {n}/{t.quotaPerWeek} done this week ✓</span>
      ))}
    </div>
  );
}

/** Month grid: up to 3 dots + "+n"; with "Show completion", the calendar day states. */
export function MonthView() {
  const { selected, showCompletion } = useTasksView();
  const { mondayFirst } = useSettings();
  const today = useToday();
  const month = Range.month(selected);
  const gridStart = Days.weekStart(month.from, mondayFirst);
  const weeks = Math.ceil((Days.between(gridStart, month.to) + 1) / 7);
  const grid = Range.of(gridStart, Days.add(gridStart, weeks * 7 - 1));
  const occ = useOccurrences(grid);
  const insights = useInsights();
  const completion = showCompletion ? insights.dayCompletion(grid) : null;
  const byDay = useMemo(() => {
    const m = new Map<Day, number[]>();
    for (const o of occ) m.set(o.date, [...(m.get(o.date) ?? []), o.task.color]);
    return m;
  }, [occ]);
  const names = Array.from({ length: 7 }, (_, i) => weekdayLetters[(i + (mondayFirst ? 0 : 6)) % 7]);
  const open = (d: Day) => {
    TasksView.select(d);
    TasksView.setView('day');
  };
  return (
    <div>
      <div className="row" style={{ justifyContent: 'center', margin: '8px 0' }}>
        <button type="button" className="text-btn" aria-label="Previous month" onClick={() => TasksView.page(-1)}><Icon name="chevronLeft" /></button>
        <h2 className="display d24" style={{ minWidth: 200, textAlign: 'center' }}>{monthLong[Days.month(month.from) - 1]} {Days.year(month.from)}</h2>
        <button type="button" className="text-btn" aria-label="Next month" onClick={() => TasksView.page(1)}><Icon name="chevronRight" /></button>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 2 }}>
        {names.map((n, i) => <div key={i} style={{ textAlign: 'center', fontSize: 12, color: T.textSecondary, paddingBottom: 6 }}>{n}</div>)}
        {Range.days(grid).map((d) => {
          const inMonth = Days.month(d) === Days.month(month.from);
          if (completion) {
            return (
              <div key={d} style={{ opacity: inMonth ? 1 : 0.35, padding: '4px 0' }}>
                <DayCell completion={completion.get(d)!} isToday={d === today} onTap={() => open(d)} />
              </div>
            );
          }
          const colors = byDay.get(d) ?? [];
          return (
            <button
              key={d}
              type="button"
              onClick={() => open(d)}
              aria-label={`${dayMonth(d)}, ${colors.length} tasks`}
              style={{
                height: 72, borderRadius: 14, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 6,
                background: d === selected ? T.surfaceHigh : 'transparent', border: d === today ? `1px solid ${T.ice}` : '1px solid transparent',
                opacity: inMonth ? 1 : 0.35,
              }}
            >
              <span className="mono" style={{ fontSize: 14, color: d === today ? T.ice : T.textPrimary }}>{Days.date(d)}</span>
              <span className="row" style={{ gap: 3, minHeight: 6 }}>
                {colors.slice(0, 3).map((c, i) => <span key={i} style={{ width: 6, height: 6, borderRadius: '50%', background: css(c) }} />)}
              </span>
              {colors.length > 3 && <span className="mono" style={{ fontSize: 9, color: T.textSecondary }}>+{colors.length - 3}</span>}
            </button>
          );
        })}
      </div>
    </div>
  );
}

/** Agenda grouped by day with sticky headers; search across a year. */
export function ScheduleView() {
  const { selected, query } = useTasksView();
  const today = useToday();
  const q = query.trim().toLowerCase();
  const range = q ? Range.of(Days.add(today, -365), Days.add(today, 365)) : Range.of(selected, Days.add(selected, 60));
  let occ = useOccurrences(range);
  if (q) occ = occ.filter((o) => o.title.toLowerCase().includes(q) || o.task.tag?.toLowerCase().includes(q) || o.task.notes?.toLowerCase().includes(q));
  const groups = new Map<Day, Occurrence[]>();
  for (const o of occ) groups.set(o.date, [...(groups.get(o.date) ?? []), o]);
  return (
    <div>
      <div style={{ position: 'relative', marginBottom: 8 }}>
        <span style={{ position: 'absolute', left: 14, top: 14, color: T.textSecondary }}><Icon name="search" /></span>
        <input className="input" style={{ paddingLeft: 44 }} placeholder="Search tasks" value={query} onChange={(e) => TasksView.search(e.target.value)} aria-label="Search tasks" />
      </div>
      {groups.size === 0 && <EmptyState message={q ? `No tasks match “${query}”.` : 'Nothing scheduled in the next two months.'} />}
      {[...groups.entries()].map(([d, list]) => (
        <section key={d}>
          <h3
            className="display d18"
            style={{ position: 'sticky', top: 0, zIndex: 3, background: T.bg, padding: '10px 0', color: d === today ? T.ice : T.textSecondary }}
          >
            {d === today ? `Today · ${dayMonth(d)}` : d === Days.add(today, 1) ? `Tomorrow · ${dayMonth(d)}` : `${weekdayShort[Days.weekday(d) - 1]} ${dayMonth(d)}`}
          </h3>
          <div className="stack" style={{ marginBottom: 16 }}>
            {list.map((o) => <TaskCard key={Occ.key(o)} occurrence={o} />)}
          </div>
        </section>
      ))}
    </div>
  );
}
