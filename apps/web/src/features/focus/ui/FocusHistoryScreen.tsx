import { useMemo, useState } from 'react';
import { useNavigate } from 'react-router';
import { AppInfo } from '../../../core/appInfo';
import { useDb } from '../../../core/db/store';
import { useSettings, useSnapshot, useToday } from '../../../core/hooks';
import { css, T } from '../../../core/theme/tokens';
import { Days, Range } from '../../../core/time/days';
import { Fmt, monthLong, weekdayShort } from '../../../core/time/format';
import { Icon } from '../../../core/widgets/Icon';
import { EmptyState, ScreenHeader, SectionTitle, StatTile } from '../../../core/widgets/widgets';
import { sessionFromRow } from '../../insights/data/insightsRepository';
import { BarsChart } from '../../insights/ui/charts';
import { FocusHistory, Sessions, type TaskFocusGroup } from '../domain/focusHistory';
import { FocusBreakdown, fmtMs } from './FocusBreakdown';

/** Focus history: today / this week, daily bars, and sessions grouped by task. */
export function FocusHistoryScreen() {
  const navigate = useNavigate();
  const rows = useDb((s) => s.focusSessions);
  const today = useToday();
  const { mondayFirst, dailyFocusGoalMin: goal } = useSettings();
  const sessions = useMemo(() => rows.filter((r) => r.endedAt != null).map(sessionFromRow), [rows]);
  const week = Range.week(today, mondayFirst);
  const todayTotals = FocusHistory.totals(FocusHistory.inRange(sessions, Range.day(today)));
  const weekSessions = FocusHistory.inRange(sessions, week);
  const weekTotals = FocusHistory.totals(weekSessions);
  const perHour = FocusHistory.interruptionsPerHour(weekTotals);
  const daily = FocusHistory.minutesByDay(sessions, week);
  const days = Range.days(week);
  const groups = FocusHistory.byTask(sessions);
  const goalDays = FocusHistory.goalDays(sessions, goal, week);
  const streak = FocusHistory.goalStreak(sessions, goal, today);

  return (
    <div className="page">
      <ScreenHeader title="Focus history" size={32} onBack={() => navigate(-1)} />
      <p className="muted" style={{ margin: '4px 0 0' }}>{AppInfo.motto} No leaderboards — only your own days.</p>
      <div className="stack-l" style={{ marginTop: 24 }}>
        <section className="panel sage">
          <div className="row" style={{ gap: 16 }}>
            <div style={{ flex: 1 }}><StatTile value={fmtMs(todayTotals.focusMs)} label="today" color={T.textInverse} size={26} /></div>
            <div style={{ flex: 1 }}><StatTile value={fmtMs(weekTotals.focusMs)} label="this week" color={T.textInverse} size={26} /></div>
          </div>
          <div style={{ marginTop: 14 }}>
            <BarsChart
              values={days.map((d) => daily.get(d) ?? 0)}
              labels={days.map((d) => weekdayShort[Days.weekday(d) - 1][0])}
              color={T.textInverse}
              height={110}
              ariaLabel="Focus minutes per day this week"
              tooltip={(i, v) => `${Days.date(days[i])} ${monthLong[Days.month(days[i]) - 1].slice(0, 3)} · ${Math.round(v)} min`}
            />
          </div>
        </section>

        <section className="card">
          <h2 className="display d18 muted" style={{ margin: '0 0 8px' }}>This week</h2>
          <div className="row wrap" style={{ gap: 20, marginBottom: 12 }}>
            <StatTile value={String(weekTotals.sessions)} label="sessions" size={22} labelColor={T.textSecondary} />
            <StatTile value={`${goalDays}/7`} label="goal days" size={22} color={T.mint} labelColor={T.textSecondary} />
            <StatTile value={String(streak)} label="day streak" size={22} labelColor={T.textSecondary} />
            <StatTile value={String(weekTotals.interruptions)} label="interruptions" size={22} labelColor={T.textSecondary} />
            {perHour != null && <StatTile value={perHour.toFixed(1)} label="per focus hour" size={22} labelColor={T.textSecondary} />}
          </div>
          <FocusBreakdown
            focusMs={weekTotals.focusMs}
            pausedMs={weekTotals.pausedMs}
            awayMs={weekTotals.awayMs}
            interruptions={weekTotals.interruptions}
            appUsageMs={weekTotals.appUsageMs}
            distractions={FocusHistory.distractingApps(weekSessions)}
          />
        </section>

        <section>
          <SectionTitle>By task</SectionTitle>
          {groups.length === 0 ? (
            <EmptyState message="Start a focus session — from Focus or straight from a task — and it will show up here." mood="calm" />
          ) : (
            <div className="stack">
              {groups.map((g) => <GroupCard key={g.taskId ?? '-'} group={g} />)}
            </div>
          )}
        </section>
      </div>
    </div>
  );
}

function GroupCard({ group }: { group: TaskFocusGroup }) {
  const [open, setOpen] = useState(false);
  const { tasks } = useSnapshot();
  const { use24h } = useSettings();
  const task = group.taskId == null ? null : tasks.find((t) => t.id === group.taskId);
  const title = group.taskId == null ? 'Without a task' : (task?.title ?? 'Deleted task');
  const t = group.totals;
  const plural = (n: number, w: string) => `${n} ${w}${n === 1 ? '' : 's'}`;
  return (
    <div className="card" style={{ padding: 0 }}>
      <button type="button" className="row" aria-expanded={open} onClick={() => setOpen(!open)} style={{ width: '100%', padding: 16, gap: 12, textAlign: 'left' }}>
        <span style={{ width: 12, height: 12, borderRadius: '50%', flex: 'none', background: task ? css(task.color) : T.outline }} />
        <span style={{ flex: 1, minWidth: 0 }}>
          <span className="display d18 truncate" style={{ display: 'block' }}>{title}</span>
          <span className="body-s">
            {fmtMs(t.focusMs)} focus · {plural(t.sessions, 'session')} · {plural(t.interruptions, 'interruption')}
          </span>
        </span>
        <Icon name={open ? 'collapse' : 'expand'} />
      </button>
      {open && (
        <div className="stack" style={{ padding: '0 16px 16px' }}>
          {group.sessions.map((s) => {
            const d = new Date(s.startedAt);
            const day = Days.of(d);
            return (
              <div key={s.id} style={{ background: T.surfaceHigh, borderRadius: 14, padding: 12 }}>
                <div className="row" style={{ marginBottom: 6 }}>
                  <span style={{ flex: 1, fontSize: 13, fontWeight: 500 }}>
                    {weekdayShort[Days.weekday(day) - 1]} {Days.date(day)} {monthLong[Days.month(day) - 1].slice(0, 3)} · {Fmt.time(d, use24h)}
                  </span>
                  <span style={{ fontSize: 12, color: s.endedEarly ? T.coralSoft : T.mint }}>{s.endedEarly ? 'ended early' : 'completed'}</span>
                </div>
                <FocusBreakdown
                  dense
                  focusMs={s.focusMsCompleted}
                  pausedMs={s.pausedMs}
                  awayMs={s.awayMs}
                  interruptions={s.interruptions}
                  appUsageMs={Sessions.appUsageMs(s)}
                  distractions={Object.entries(s.distractions).sort((a, b) => b[1] - a[1])}
                />
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
