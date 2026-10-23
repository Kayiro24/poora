import { useState } from 'react';
import { useNavigate } from 'react-router';
import { create } from 'zustand';
import { useNow, useOccurrences, useSettings, useToday } from '../../core/hooks';
import { css, T, TaskColors } from '../../core/theme/tokens';
import { Days, Range, type Day } from '../../core/time/days';
import { Fmt, monthLong, weekdayShort } from '../../core/time/format';
import { DayRatePills } from '../../core/widgets/DayRatePills';
import { Icon } from '../../core/widgets/Icon';
import { ArrowButton, CoralFab, EmptyState, IconButton, Mascot, MonoBadge, OptionSheet, Pill } from '../../core/widgets/widgets';
import { useFocus } from '../focus/application/focusController';
import { startFocus } from '../focus/ui/FocusScreen';
import { useInsights } from '../insights/data/insightsRepository';
import { DC } from '../insights/domain/metrics';
import { WeekAreaChart } from '../insights/ui/charts';
import { Occ, type Occurrence } from '../tasks/domain/models';
import { timeLabel } from '../tasks/ui/TaskCard';
import { openEditor, TasksView } from '../tasks/ui/tasksUi';

/** Dashboard day (null = follow today). */
export const useHomeDay = create<{ day: Day | null }>(() => ({ day: null }));
export const resetHomeDay = () => useHomeDay.setState({ day: null });

export function HomeScreen() {
  const navigate = useNavigate();
  const today = useToday();
  const day = useHomeDay((s) => s.day) ?? today;
  const { name } = useSettings();
  const now = useNow(30_000);
  const around = useOccurrences(Range.of(Days.add(today, -1), today));
  const overdue = around.some((o) => o.status === 'missed' || (o.status === 'pending' && Occ.endAt(o) != null && Occ.endAt(o)!.getTime() < now.getTime()));
  const isToday = day === today;

  return (
    <div className="page wide">
      <div className="row">
        <button type="button" aria-label="Settings" onClick={() => navigate('/settings')} style={{ width: 48, height: 48, borderRadius: '50%', background: T.surfaceHigh, display: 'grid', placeItems: 'center', flex: 'none' }}>
          <Mascot mood="happy" size={40} />
        </button>
        <h1 className="display d24 truncate" style={{ flex: 1, marginLeft: 8 }}>{name.trim() ? `Hi, ${name.trim()}` : 'Hi there'}</h1>
        <IconButton icon="search" label="Search tasks" onClick={() => { TasksView.setView('schedule'); navigate('/tasks'); }} />
        <IconButton
          icon="bell"
          label={overdue ? 'Overdue tasks' : 'Notifications'}
          badge={overdue}
          onClick={() => { TasksView.setView('schedule'); TasksView.select(Days.add(today, -1)); navigate('/tasks'); }}
        />
      </div>
      <label className="pill" style={{ marginTop: 16, position: 'relative', cursor: 'pointer' }}>
        {isToday ? 'Today' : weekdayShort[Days.weekday(day) - 1]}, {weekdayShort[Days.weekday(day) - 1]} {Days.date(day)} {monthLong[Days.month(day) - 1].slice(0, 3)}
        <Icon name="expand" size={16} />
        <input
          type="date"
          aria-label="Dashboard day"
          value={day}
          onChange={(e) => e.target.value && useHomeDay.setState({ day: e.target.value === today ? null : e.target.value })}
          style={{ position: 'absolute', inset: 0, opacity: 0, cursor: 'pointer' }}
        />
      </label>
      <div className="home-grid" style={{ marginTop: 16 }}>
        <NextUp day={day} />
        <QuickStart />
        <ThisWeek day={day} />
      </div>
      {/* Add a task on the day shown: opens Tasks on that day with the editor. */}
      <CoralFab
        label="Add task"
        onClick={() => {
          TasksView.setView('day');
          TasksView.select(day);
          navigate('/tasks');
          openEditor({ date: day });
        }}
      />
    </div>
  );
}

function NextUp({ day }: { day: Day }) {
  const today = useToday();
  const occ = useOccurrences(Range.day(day));
  const { use24h } = useSettings();
  const now = useNow(1000);
  const isToday = day === today;
  const open = occ.filter((o) => o.status === 'pending');
  const next: Occurrence | undefined =
    open.find((o) => Occ.isTimed(o) && (!isToday || Occ.endAt(o)!.getTime() > now.getTime())) ?? open.find((o) => !Occ.isTimed(o));

  if (!next) {
    return (
      <div className="card row" style={{ padding: 18, gap: 14 }}>
        <span style={{ width: 48, height: 48, borderRadius: 16, background: T.mint, display: 'grid', placeItems: 'center', color: T.textInverse }}>
          <Icon name="check" />
        </span>
        <div>
          <div className="display d20">{isToday ? 'All clear for today' : 'All clear'}</div>
          <div className="body-s" style={{ marginTop: 2 }}>{occ.length ? 'Everything’s done. Enjoy the quiet.' : 'Nothing scheduled.'}</div>
        </div>
      </div>
    );
  }
  const start = Occ.startAt(next);
  const countdown = isToday && start
    ? start.getTime() > now.getTime()
      ? `starts in ${Fmt.countdown(start.getTime() - now.getTime())}`
      : `ends in ${Fmt.countdown(Occ.endAt(next)!.getTime() - now.getTime())}`
    : null;
  return (
    <div className="card clickable row" style={{ padding: '16px 8px 16px 16px', gap: 14, alignItems: 'flex-start' }} onClick={() => openEditor({ occurrence: next })}>
      <span style={{ width: 48, height: 48, borderRadius: 16, background: T.sun, display: 'grid', placeItems: 'center', color: T.textInverse, flex: 'none' }}>
        <Icon name="sun" />
      </span>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div className="caps-label">Next up</div>
        <div className="display d24" style={{ marginTop: 2 }}>{next.title}</div>
        <div className="body-s" style={{ marginTop: 4 }}>{[timeLabel(next, use24h), next.task.tag].filter(Boolean).join(' · ')}</div>
        {countdown && <div style={{ marginTop: 10 }}><MonoBadge text={countdown} /></div>}
      </div>
      <span onClick={(e) => e.stopPropagation()}>
        <ArrowButton label={`Open ${next.title}`} onClick={() => openEditor({ occurrence: next })} />
      </span>
    </div>
  );
}

function QuickStart() {
  const navigate = useNavigate();
  const { lastFocus } = useSettings();
  const running = useFocus((s) => !!s.session);
  return (
    <div className="panel sage clickable row" onClick={() => (running ? navigate('/focus/run') : startFocus(lastFocus))}>
      <div style={{ flex: 1 }}>
        <div className="display d32 ink">{running ? 'In session' : 'Start focus'}</div>
        <div className="mono" style={{ fontSize: 14, marginTop: 4 }}>{running ? 'Tap to return' : `${lastFocus.focusMin} / ${lastFocus.shortMin} · last used`}</div>
      </div>
      <span style={{ width: 56, height: 56, borderRadius: '50%', background: T.bg, color: T.sage, display: 'grid', placeItems: 'center' }}>
        <Icon name={running ? 'timer' : 'play'} size={30} />
      </span>
    </div>
  );
}

function ThisWeek({ day }: { day: Day }) {
  const navigate = useNavigate();
  const repo = useInsights();
  const today = useToday();
  const [last, setLast] = useState(false);
  const [picker, setPicker] = useState(false);
  const week = repo.week(Days.add(day, last ? -7 : 0));
  const days = repo.dayCompletion(week);
  const list = Range.days(week);
  const firstFuture = list.findIndex((d) => d > today);
  const counts = new Map<number, number>();
  for (const o of repo.occurrences(week)) if (o.status === 'done') counts.set(o.task.color, (counts.get(o.task.color) ?? 0) + 1);
  const top = [...counts.entries()].sort((a, b) => b[1] - a[1]).slice(0, 3);
  const empty = [...days.values()].every((d) => DC.scheduled(d) === 0);
  return (
    <section className="panel peri span-2">
      <div className="row">
        <h2 className="display d24 ink" style={{ flex: 1 }}>{last ? 'Last week' : 'This week'}</h2>
        <Pill label={last ? 'last week' : 'this week'} trailingIcon="expand" filled color={T.white} onClick={() => setPicker(true)} />
      </div>
      <div style={{ marginTop: 16 }}>
        <DayRatePills
          days={list.map((d) => ({ date: d, label: weekdayShort[Days.weekday(d) - 1], percent: d > today ? null : DC.percent(days.get(d)!), isToday: d === today, isFuture: d > today }))}
          onTap={(p) => navigate(`/insights/calendar?day=${p.date}`)}
        />
      </div>
      <div style={{ marginTop: 18 }}>
        {empty ? (
          <EmptyState message="Plan a few tasks and your week will take shape here." mood="thinking" compact color={T.textInverse} />
        ) : (
          <WeekAreaChart
            labels={list.map((d) => weekdayShort[Days.weekday(d) - 1][0])}
            actual={list.map((d) => days.get(d)!.done)}
            planned={firstFuture < 0 ? undefined : list.map((d, i) => (i < firstFuture - 1 ? null : DC.scheduled(days.get(d)!)))}
            lastActual={firstFuture < 0 ? undefined : firstFuture - 1}
            height={120}
          />
        )}
      </div>
      {top.length > 0 && (
        <div className="chip-row" style={{ marginTop: 10 }}>
          {top.map(([c, n]) => <Pill key={c} label={`${TaskColors.nameOf(c)} · ${n}`} dense dot={css(c)} filled color={T.white} />)}
        </div>
      )}
      <OptionSheet<boolean>
        open={picker}
        title="Week"
        options={[{ label: 'This week', value: false, selected: !last }, { label: 'Last week', value: true, selected: last }]}
        onPick={(v) => { setLast(v); setPicker(false); }}
        onClose={() => setPicker(false)}
      />
    </section>
  );
}
