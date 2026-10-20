import { useNavigate, useParams } from 'react-router';
import { useSettings, useToday } from '../../../core/hooks';
import { T } from '../../../core/theme/tokens';
import { Days, Range } from '../../../core/time/days';
import { Fmt, monthLong, weekdayShort } from '../../../core/time/format';
import { Icon } from '../../../core/widgets/Icon';
import { EmptyState, Pill, ScreenHeader, SectionTitle, StatTile } from '../../../core/widgets/widgets';
import { Occ } from '../../tasks/domain/models';
import { Rules } from '../../tasks/domain/recurrence';
import { Filters, useInsights } from '../data/insightsRepository';
import { openDaySheet } from './calendar';
import { ConsistencyHeatmap } from './charts';

/** Recurring task detail: streaks, 12-week heatmap, full history. */
export function RecurringDetailScreen() {
  const { id = '' } = useParams();
  const seriesId = decodeURIComponent(id);
  const navigate = useNavigate();
  const repo = useInsights();
  const today = useToday();
  const { mondayFirst, use24h } = useSettings();
  const task = repo.seriesTask(seriesId);
  if (!task) {
    return (
      <div className="page">
        <ScreenHeader title="Task" onBack={() => navigate(-1)} />
        <EmptyState message="This task no longer exists." />
      </div>
    );
  }
  const quota = task.repeatKind === 'quota';
  const unit = quota ? ' wk' : '';
  const start = Days.add(Days.weekStart(today, mondayFirst), -77);
  const filter = { seriesId };
  const days = repo.dayCompletion(Range.of(start, Days.add(start, 83)), filter);
  const streak = repo.streak(seriesId);
  const met = quota ? repo.quotaWeeksMet(seriesId) : null;
  const history = repo
    .seriesOccurrences(seriesId, Range.of(Days.add(today, -365), today))
    .filter((o) => o.status !== 'pending' || o.date === today)
    .reverse()
    .slice(0, 120);

  return (
    <div className="page">
      <ScreenHeader title={task.title} size={32} onBack={() => navigate(-1)} />
      <p className="body-s" style={{ margin: '4px 0 0 52px' }}>{Rules.summary(Rules.fromTask(task), task.startDate)}</p>
      <div className="row wrap" style={{ gap: 24, margin: '20px 0 24px' }}>
        <StatTile value={`${streak.current}${unit}`} label={'current\nstreak'} color={T.sun} labelColor={T.textSecondary} />
        <StatTile value={`${streak.best}${unit}`} label={'best\nstreak'} labelColor={T.textSecondary} />
        {met != null && <StatTile value={`${Math.round(met * 100)}%`} label={'weeks\nquota met'} labelColor={T.textSecondary} />}
      </div>
      <SectionTitle trailing={<Pill label="Calendar" icon="calendar" dense onClick={() => navigate(`/insights/calendar?filter=${encodeURIComponent(Filters.encode(filter)!)}`)} />}>
        Last 12 weeks
      </SectionTitle>
      <div className="card">
        <ConsistencyHeatmap days={days} start={start} today={today} onTap={openDaySheet} />
      </div>
      <div style={{ marginTop: 24 }}>
        <SectionTitle>History</SectionTitle>
        {history.length === 0 ? (
          <EmptyState message="No history yet — the first one is the hardest." compact />
        ) : (
          <div className="stack">
            {history.map((o) => {
              const [icon, color, label] =
                o.status === 'done'
                  ? (['check', T.mint, o.late ? 'Done late' : Occ.onTime(o) ? 'Done on time' : 'Done'] as const)
                  : o.status === 'missed'
                    ? (['close', T.coral, 'Missed'] as const)
                    : o.status === 'skipped'
                      ? (['remove', T.textSecondary, 'Skipped'] as const)
                      : (['schedule', T.ice, 'Today'] as const);
              return (
                <button key={Occ.key(o)} type="button" className="card inner row" style={{ width: '100%', padding: '12px 16px', textAlign: 'left' }} onClick={() => openDaySheet(o.date)}>
                  <span style={{ color }}><Icon name={icon} /></span>
                  <span style={{ flex: 1 }}>{weekdayShort[Days.weekday(o.date) - 1]} {Days.date(o.date)} {monthLong[Days.month(o.date) - 1].slice(0, 3)} {Days.year(o.date)}</span>
                  <span className="body-s">{label}</span>
                  <span className="mono body-s" style={{ minWidth: 56, textAlign: 'right' }}>{o.completedAt ? Fmt.time(new Date(o.completedAt), use24h) : ''}</span>
                </button>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}
