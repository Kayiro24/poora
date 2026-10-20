import { useEffect, useRef, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router';
import { useToday } from '../../../core/hooks';
import { T } from '../../../core/theme/tokens';
import { Days, Range, type Day } from '../../../core/time/days';
import { monthLong } from '../../../core/time/format';
import { IconButton, OptionSheet, Pill, StatTile } from '../../../core/widgets/widgets';
import { Filters, useInsights, type CalendarFilter } from '../data/insightsRepository';
import { DC } from '../domain/metrics';
import { CompletionMonthGrid, CompletionYearGrid, openDaySheet, TierLegend } from './calendar';

/** "THE MONTH": completion calendar with Month | Year, filter, summary strip (§4.11). */
export function CalendarScreen() {
  const navigate = useNavigate();
  const [params] = useSearchParams();
  const today = useToday();
  const repo = useInsights();
  const initialDay = params.get('day');
  const [month, setMonth] = useState<Day>(Days.monthStart(initialDay ?? today));
  const [filter, setFilter] = useState<CalendarFilter>(Filters.decode(params.get('filter')));
  const [year, setYear] = useState(false);
  const [picker, setPicker] = useState(false);
  const touch = useRef<number | null>(null);

  useEffect(() => {
    if (initialDay && initialDay <= today) openDaySheet(initialDay);
  }, [initialDay, today]);

  const range = Range.month(month);
  const days = [...repo.dayCompletion(range, filter).values()];
  const perfect = days.filter((d) => d.tier === 'perfect').length;
  const partial = days.filter((d) => d.tier === 'high' || d.tier === 'mid' || d.tier === 'low').length;
  const missed = days.filter((d) => d.tier === 'missed').length;
  const past = days.filter((d) => d.tier !== 'today');
  const scheduled = past.reduce((a, d) => a + DC.scheduled(d), 0);
  const done = past.reduce((a, d) => a + d.done, 0);
  const rate = scheduled ? Math.round((done / scheduled) * 100) : null;
  const series = repo.recurringSeries();
  const tags = repo.tags();
  const filterLabel = filter.tag ?? (filter.seriesId ? repo.seriesTask(filter.seriesId)?.title ?? 'Task' : 'All tasks');

  return (
    <div className="page">
      <header className="screen-header">
        <IconButton icon="back" label="Back" onClick={() => navigate(-1)} />
        <h1 className="display d32" style={{ flex: 1 }}>{year ? 'The year' : `${monthLong[Days.month(month) - 1]} ${Days.year(month)}`}</h1>
        {!year && (
          <>
            <IconButton icon="chevronLeft" label="Previous month" onClick={() => setMonth(Days.addMonths(month, -1))} />
            <IconButton icon="chevronRight" label="Next month" onClick={() => setMonth(Days.addMonths(month, 1))} />
          </>
        )}
      </header>

      <div className="row" style={{ margin: '16px 0 20px' }}>
        <div className="row" role="tablist" style={{ background: T.surface, borderRadius: 999, padding: 3, gap: 0 }}>
          {[false, true].map((v) => (
            <button
              key={String(v)}
              type="button"
              role="tab"
              aria-selected={year === v}
              onClick={() => setYear(v)}
              className="label"
              style={{ padding: '8px 16px', borderRadius: 999, background: year === v ? T.periwinkle : 'transparent', color: year === v ? T.textInverse : T.textPrimary }}
            >
              {v ? 'Year' : 'Month'}
            </button>
          ))}
        </div>
        <span className="spacer" />
        <Pill label={filterLabel} trailingIcon="expand" onClick={() => setPicker(true)} />
      </div>

      {year ? (
        <CompletionYearGrid
          filter={filter}
          onDayTap={(d) => {
            setYear(false);
            setMonth(Days.monthStart(d));
            openDaySheet(d);
          }}
        />
      ) : (
        <div
          key={month}
          style={{ animation: 'page-in 280ms var(--ease)' }}
          onTouchStart={(e) => (touch.current = e.touches[0].clientX)}
          onTouchEnd={(e) => {
            if (touch.current == null) return;
            const dx = e.changedTouches[0].clientX - touch.current;
            if (Math.abs(dx) > 60) setMonth(Days.addMonths(month, dx < 0 ? 1 : -1));
            touch.current = null;
          }}
        >
          <CompletionMonthGrid month={month} filter={filter} onDayTap={openDaySheet} />
        </div>
      )}

      {!year && (
        <div className="row wrap" style={{ gap: 20, marginTop: 20 }}>
          <StatTile value={String(perfect)} label="perfect" color={T.dayPerfect} labelColor={T.textSecondary} size={26} />
          <StatTile value={String(partial)} label="partial" labelColor={T.textSecondary} size={26} />
          <StatTile value={String(missed)} label="missed" labelColor={T.textSecondary} size={26} />
          <StatTile value={rate == null ? '–' : `${rate}%`} label="month rate" labelColor={T.textSecondary} size={26} />
          <StatTile value={String(repo.bestPerfectRun(range, filter))} label="best streak" labelColor={T.textSecondary} size={26} />
        </div>
      )}
      <div style={{ marginTop: 16 }}>
        <TierLegend />
      </div>

      <OptionSheet<string>
        open={picker}
        title="Show"
        options={[
          { label: 'All tasks', value: 'all', selected: !filter.tag && !filter.seriesId },
          ...tags.map((t) => ({ label: `#  ${t}`, value: `tag:${t}`, selected: filter.tag === t })),
          ...series.map((s) => ({ label: s.task.title, value: `task:${s.seriesId}`, hint: 'recurring', selected: filter.seriesId === s.seriesId })),
        ]}
        onPick={(v) => {
          setFilter(v === 'all' ? Filters.all : Filters.decode(v));
          setPicker(false);
        }}
        onClose={() => setPicker(false)}
      />
    </div>
  );
}
