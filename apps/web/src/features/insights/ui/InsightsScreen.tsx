import { useState } from 'react';
import { useNavigate } from 'react-router';
import { useSettings, useToday } from '../../../core/hooks';
import { css, T } from '../../../core/theme/tokens';
import { Days, Range, type DateRange, type Day } from '../../../core/time/days';
import { Fmt, monthLong, weekdayShort } from '../../../core/time/format';
import { DayRatePills } from '../../../core/widgets/DayRatePills';
import { ArrowButton, EmptyState, IconButton, OptionSheet, Pill, ScreenHeader, SectionTitle, StatTile } from '../../../core/widgets/widgets';
import { Rules } from '../../tasks/domain/recurrence';
import { useInsights, type InsightsRepository, type RecurringSeries } from '../data/insightsRepository';
import { DC, Metrics } from '../domain/metrics';
import { CompletionMonthGrid, openDaySheet, TierLegend } from './calendar';
import { BarsChart, CategoryDonut, ChartLegend, ConsistencyHeatmap, SegmentedBar, Sparkline, WeekAreaChart } from './charts';

type RangeKind = 'today' | 'week' | 'month' | 'last30' | 'all';
const rangeLabels: Record<RangeKind, string> = { today: 'Today', week: 'This week', month: 'This month', last30: 'Last 30 days', all: 'All time' };
const EMPTY = 'Complete a few tasks and your week will show up here';
const dm = (d: Day) => `${Days.date(d)} ${monthLong[Days.month(d) - 1].slice(0, 3)}`;

function resolve(kind: RangeKind, offset: number, repo: InsightsRepository, today: Day): DateRange {
  switch (kind) {
    case 'today':
      return Range.day(Days.add(today, offset));
    case 'week': {
      const w = repo.week(today);
      return Range.of(Days.add(w.from, 7 * offset), Days.add(w.to, 7 * offset));
    }
    case 'month':
      return Range.month(Days.addMonths(today, offset));
    case 'last30': {
      const end = Days.add(today, 30 * offset);
      return Range.of(Days.add(end, -29), end);
    }
    case 'all':
      return Range.of(repo.firstUse ?? today, today);
  }
}

export function InsightsScreen() {
  const repo = useInsights();
  const today = useToday();
  const [kind, setKind] = useState<RangeKind>('week');
  const [offset, setOffset] = useState(0);
  const [picker, setPicker] = useState(false);
  const range = resolve(kind, offset, repo, today);
  const anchor = range.to > today ? today : range.to;
  const title = offset === 0 ? rangeLabels[kind] : Range.length(range) === 1 ? dm(range.from) : `${dm(range.from)} – ${dm(range.to)}`;

  return (
    <div className="page wide insights-head">
      <ScreenHeader
        title="Insights"
        trailing={
          <div className="row insights-controls">
            {kind !== 'all' && (
              <>
                <IconButton icon="back" small label="Previous period" onClick={() => setOffset(offset - 1)} />
                <IconButton icon="forward" small label="Next period" disabled={offset >= 0} onClick={() => setOffset(offset + 1)} />
              </>
            )}
            <Pill label={title} trailingIcon="expand" onClick={() => setPicker(true)} title="Change range" />
          </div>
        }
      />
      <div className="stack-l" style={{ marginTop: 12 }}>
        <Headline range={range} />
        <div className="grid-2">
          <CalendarSection month={anchor} />
          <WeekCapacity day={anchor} />
          <Recurring />
          <Heatmap />
          <Timing range={range} />
          <FocusSection range={range} />
          <Category range={range} />
        </div>
      </div>
      <OptionSheet<RangeKind>
        open={picker}
        title="Range"
        options={(Object.keys(rangeLabels) as RangeKind[]).map((k) => ({ label: rangeLabels[k], value: k, selected: k === kind }))}
        onPick={(k) => { setKind(k); setOffset(0); setPicker(false); }}
        onClose={() => setPicker(false)}
      />
    </div>
  );
}

function Headline({ range }: { range: DateRange }) {
  const repo = useInsights();
  const rate = repo.completionRate(range);
  const focus = repo.focus(range);
  const tile = (child: React.ReactNode) => <div className="card inner" style={{ padding: '18px 16px', overflow: 'hidden' }}>{child}</div>;
  return (
    <div className="headline-grid">
      {tile(<StatTile value={String(repo.doneCount(range))} label={'tasks\ncompleted'} labelColor={T.textSecondary} />)}
      {tile(<StatTile value={rate == null ? '–' : `${Math.round(rate * 100)}%`} label={'completion\nrate'} labelColor={T.textSecondary} />)}
      {tile(<StatTile value={Fmt.hours(focus.totalMinutes)} label={'focus\nhours'} color={T.sage} labelColor={T.textSecondary} />)}
      {tile(<StatTile value={String(repo.overallStreak())} label={'day\nstreak'} color={T.sun} labelColor={T.textSecondary} leading={<span style={{ fontSize: 20 }} aria-hidden>🔥</span>} />)}
    </div>
  );
}

function CalendarSection({ month }: { month: Day }) {
  const navigate = useNavigate();
  return (
    <section className="card" style={{ padding: '14px 10px 16px 14px' }}>
      <div className="row">
        <h2 className="display d24" style={{ flex: 1, paddingLeft: 6 }}>{monthLong[Days.month(month) - 1]} {Days.year(month)}</h2>
        <ArrowButton label="Open completion calendar" onClick={() => navigate('/insights/calendar')} />
      </div>
      <div style={{ marginTop: 10 }}>
        <CompletionMonthGrid key={month} month={month} onDayTap={openDaySheet} />
      </div>
      <div style={{ paddingLeft: 6 }}>
        <TierLegend />
      </div>
    </section>
  );
}

function WeekCapacity({ day }: { day: Day }) {
  const repo = useInsights();
  const today = useToday();
  const week = repo.week(day);
  const days = repo.dayCompletion(week);
  const list = Range.days(week);
  const firstFuture = list.findIndex((d) => d > today);
  const any = [...days.values()].some((d) => DC.scheduled(d) > 0);
  return (
    <section className="panel peri">
      <h2 className="display d24 ink">Week capacity</h2>
      <p style={{ margin: '4px 0 16px', fontSize: 13, color: T.textInverse }}>{dm(week.from)} – {dm(week.to)}</p>
      <DayRatePills
        days={list.map((d) => ({ date: d, label: weekdayShort[Days.weekday(d) - 1], percent: d > today ? null : DC.percent(days.get(d)!), isToday: d === today, isFuture: d > today }))}
        onTap={(p) => !p.isFuture && openDaySheet(p.date)}
      />
      <div style={{ marginTop: 16 }}>
        {!any ? (
          <EmptyState message={EMPTY} mood="thinking" compact color={T.textInverse} />
        ) : (
          <>
            <WeekAreaChart
              labels={list.map((d) => weekdayShort[Days.weekday(d) - 1][0])}
              actual={list.map((d) => days.get(d)!.done)}
              planned={list.map((d) => DC.scheduled(days.get(d)!))}
              lastActual={firstFuture < 0 ? undefined : firstFuture - 1}
            />
            <div style={{ marginTop: 8 }}>
              <ChartLegend ink={T.textInverse} items={[[T.coral, 'Completed', false], [T.textInverse, 'Scheduled', true]]} />
            </div>
          </>
        )}
      </div>
    </section>
  );
}

export function RecurringCard({ series }: { series: RecurringSeries }) {
  const repo = useInsights();
  const navigate = useNavigate();
  const today = useToday();
  const t = series.task;
  const week = repo.week(today);
  const streak = repo.streak(series.seriesId);
  const trend = repo.weeklyTrend(series.seriesId);
  const quota = t.repeatKind === 'quota';
  const unit = quota ? 'wk' : '';
  let progress: string;
  let bar: React.ReactNode;
  if (quota) {
    const q = t.quotaPerWeek ?? 1;
    const done = repo.quotaDone(series.seriesId, week.from);
    progress = `${done} of ${q} this week${done >= q ? ' ✓' : ''}`;
    bar = <SegmentedBar segments={Array.from({ length: q }, (_, i) => (i < done ? 'done' : 'pending'))} />;
  } else {
    const p = repo.weekProgress(series.seriesId, week);
    progress = `${p.done} / ${p.total} done`;
    bar = <SegmentedBar segments={p.segments} />;
  }
  const met = quota ? repo.quotaWeeksMet(series.seriesId) : null;
  const open = () => navigate(`/insights/task/${encodeURIComponent(series.seriesId)}`);
  return (
    <div className="card clickable" onClick={open} style={{ padding: '14px 8px 16px 16px' }}>
      <div className="row" style={{ alignItems: 'flex-start' }}>
        <span style={{ width: 10, height: 10, borderRadius: '50%', background: css(t.color), marginTop: 8, flex: 'none' }} />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div className="display d20 truncate">{t.title}</div>
          <div className="body-s" style={{ marginTop: 2 }}>{Rules.summary(Rules.fromTask(t), t.startDate)}</div>
        </div>
        <span onClick={(e) => e.stopPropagation()}>
          <ArrowButton label={`Open ${t.title} history`} onClick={open} />
        </span>
      </div>
      <div style={{ paddingRight: 8, marginTop: 14 }}>
        <div className="row"><span className="body-s">This week</span><span className="spacer" /><span className="mono" style={{ fontSize: 13 }}>{progress}</span></div>
        <div style={{ marginTop: 8 }}>{bar}</div>
        <div className="row" style={{ marginTop: 14, gap: 18 }}>
          <Mini label="streak" value={`${streak.current}${unit}`} />
          <Mini label="best" value={`${streak.best}${unit}`} />
          {met != null && <Mini label="weeks met" value={`${Math.round(met * 100)}%`} />}
          <span className="spacer" />
          <Sparkline values={trend} color={T.periSoft} />
        </div>
      </div>
    </div>
  );
}

const Mini = ({ label, value }: { label: string; value: string }) => (
  <div>
    <div className="mono" style={{ fontSize: 16 }}>{value}</div>
    <div style={{ fontSize: 11, color: T.textSecondary, marginTop: 3 }}>{label}</div>
  </div>
);

function Recurring() {
  const series = useInsights().recurringSeries();
  return (
    <section>
      <SectionTitle>Recurring tasks</SectionTitle>
      {series.length === 0 ? (
        <EmptyState message="Repeat a task and its rhythm will show up here." mood="thinking" compact />
      ) : (
        <div className="stack">{series.map((s) => <RecurringCard key={s.seriesId} series={s} />)}</div>
      )}
    </section>
  );
}

function Heatmap() {
  const repo = useInsights();
  const today = useToday();
  const { mondayFirst } = useSettings();
  const start = Days.add(Days.weekStart(today, mondayFirst), -77);
  const days = repo.dayCompletion(Range.of(start, Days.add(start, 83)));
  return (
    <section>
      <SectionTitle>Consistency</SectionTitle>
      <div className="card">
        {repo.hasData ? (
          <>
            <ConsistencyHeatmap days={days} start={start} today={today} onTap={openDaySheet} />
            <div className="row" style={{ marginTop: 10, gap: 4, fontSize: 11, color: T.textSecondary }}>
              Less
              {['1f', '59', '99', 'cc', 'ff'].map((a) => <span key={a} style={{ width: 12, height: 12, borderRadius: 3, background: `${T.coral}${a}` }} />)}
              More
            </div>
          </>
        ) : (
          <EmptyState message={EMPTY} compact />
        )}
      </div>
    </section>
  );
}

function Timing({ range }: { range: DateRange }) {
  const repo = useInsights();
  const { use24h } = useSettings();
  const [on, late] = repo.onTime(range);
  const byHour = repo.completionsByHour(range);
  const total = byHour.reduce((a, b) => a + b, 0);
  const best = Metrics.bestWindow(byHour);
  return (
    <section>
      <SectionTitle>Timing</SectionTitle>
      <div className="card">
        {total === 0 ? (
          <EmptyState message={EMPTY} compact />
        ) : (
          <>
            <div className="row" style={{ gap: 24 }}>
              <StatTile value={String(on)} label="on time" color={T.mint} labelColor={T.textSecondary} size={26} />
              <StatTile value={String(late)} label="late" labelColor={T.textSecondary} size={26} />
            </div>
            {on + late > 0 && (
              <div className="row" style={{ gap: 2, marginTop: 10, borderRadius: 4, overflow: 'hidden' }}>
                {on > 0 && <span style={{ flex: on, height: 8, background: T.mint }} />}
                {late > 0 && <span style={{ flex: late, height: 8, background: T.textSecondary }} />}
              </div>
            )}
            {best != null && (
              <p className="body-l" style={{ margin: '20px 0 12px' }}>
                You get most done {Fmt.hour(best, use24h)}–{Fmt.hour((best + 2) % 24, use24h)}
              </p>
            )}
            <BarsChart
              values={byHour}
              labels={byHour.map((_, h) => Fmt.hour(h, use24h))}
              labelEvery={6}
              color={T.coral}
              height={120}
              ariaLabel="Completions by hour of day"
              tooltip={(i, v) => `${Fmt.hour(i, use24h)} · ${v}`}
            />
          </>
        )}
      </div>
    </section>
  );
}

function FocusSection({ range }: { range: DateRange }) {
  const repo = useInsights();
  const today = useToday();
  const { use24h } = useSettings();
  const end = range.to > today ? today : range.to;
  const start = Range.length(range) > 31 ? Days.add(end, -30) : range.from;
  const list = Days.range(start, end);
  const stats = repo.focus(range);
  const daily = repo.focus(Range.of(start, end)).minutesByDay;
  return (
    <section>
      <SectionTitle>Focus</SectionTitle>
      <div className="card">
        {stats.completed + stats.endedEarly === 0 ? (
          <EmptyState message="Start a focus session and your minutes will gather here." mood="calm" compact />
        ) : (
          <>
            <BarsChart
              values={list.map((d) => daily.get(d) ?? 0)}
              labels={list.map((d) => (list.length <= 7 ? weekdayShort[Days.weekday(d) - 1][0] : String(Days.date(d))))}
              labelEvery={list.length <= 7 ? 1 : 5}
              color={T.sage}
              ariaLabel="Focus minutes per day"
              tooltip={(i, v) => `${dm(list[i])} · ${Math.round(v)} min`}
            />
            <div className="row wrap" style={{ gap: 22, marginTop: 16 }}>
              <StatTile value={String(stats.completed)} label="completed" color={T.sage} labelColor={T.textSecondary} size={24} />
              <StatTile value={String(stats.endedEarly)} label="ended early" labelColor={T.textSecondary} size={24} />
              <StatTile value={String(Math.round(stats.averageMinutes))} label="avg min" labelColor={T.textSecondary} size={24} />
              {stats.bestHour != null && <StatTile value={Fmt.hour(stats.bestHour, use24h)} label="best hour" labelColor={T.textSecondary} size={24} />}
            </div>
            {stats.minutesByTask.length > 0 && (
              <>
                <p className="caps-label" style={{ marginTop: 20 }}>Minutes by linked task</p>
                {stats.minutesByTask.slice(0, 5).map(([id, m]) => (
                  <div key={id} className="row" style={{ padding: '4px 0' }}>
                    <span className="truncate" style={{ flex: 1 }}>{repo.taskTitle(id)}</span>
                    <span className="mono" style={{ fontSize: 13, color: T.sage }}>{Math.round(m)} min</span>
                  </div>
                ))}
              </>
            )}
          </>
        )}
      </div>
    </section>
  );
}

function Category({ range }: { range: DateRange }) {
  const entries = useInsights().byCategory(range);
  return (
    <section>
      <SectionTitle>By category</SectionTitle>
      <div className="card">{entries.length ? <CategoryDonut entries={entries} /> : <EmptyState message={EMPTY} compact />}</div>
    </section>
  );
}
