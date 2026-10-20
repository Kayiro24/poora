import { useState } from 'react';
import { useOccurrences, useToday } from '../../../core/hooks';
import { Notify } from '../../../core/platform/notifications';
import { T } from '../../../core/theme/tokens';
import { Range } from '../../../core/time/days';
import { Icon } from '../../../core/widgets/Icon';
import { CoralFab, Mascot, OptionSheet, Pill, ScreenHeader, StatTile } from '../../../core/widgets/widgets';
import { useSnapshot } from '../../../core/hooks';
import { openEditor, TasksView, useTasksView, views, type TaskView } from './tasksUi';
import { MonthView, ScheduleView, TimelineView, WeekStrip } from './views';

export function TasksScreen() {
  const { view, selected, showCompletion } = useTasksView();
  const [picker, setPicker] = useState(false);
  const label = views.find((v) => v.id === view)!.label;
  return (
    <div className="page wide">
      <ScreenHeader
        title="Tasks"
        trailing={
          <div className="row">
            <Pill label={label} trailingIcon="expand" onClick={() => setPicker(true)} title="Change view" />
            <Pill label="Today" onClick={TasksView.today} />
          </div>
        }
      />
      <div className="tasks-layout">
        <aside className="tasks-side">
          <NotificationBanner />
          <StatsPanel />
        </aside>
        <div className="tasks-main">
          {view !== 'month' && (
            <div style={{ position: 'sticky', top: 0, zIndex: 8, background: T.bg }}>
              <WeekStrip />
            </div>
          )}
          {view === 'schedule' ? <ScheduleView /> : view === 'month' ? <MonthView /> : <TimelineView view={view} />}
        </div>
      </div>
      <CoralFab onClick={() => openEditor({ date: selected })} />
      <OptionSheet<TaskView | 'completion'>
        open={picker}
        title="View"
        options={[
          ...views.map((v) => ({ label: v.label, value: v.id as TaskView | 'completion', selected: v.id === view })),
          ...(view === 'month' ? [{ label: 'Show completion', value: 'completion' as const, selected: showCompletion }] : []),
        ]}
        onPick={(v) => {
          if (v === 'completion') TasksView.toggleCompletion();
          else TasksView.setView(v);
          setPicker(false);
        }}
        onClose={() => setPicker(false)}
      />
    </div>
  );
}

/** Coral panel: "6 due today" / "4 done" + mascot. */
function StatsPanel() {
  const selected = useTasksView((s) => s.selected);
  const today = useToday();
  const occ = useOccurrences(Range.day(selected)).filter((o) => o.status !== 'skipped');
  const done = occ.filter((o) => o.status === 'done').length;
  return (
    <div className="panel coral row" style={{ padding: '16px 12px 16px 20px', gap: 24 }}>
      <StatTile value={String(occ.length)} label={selected === today ? 'due\ntoday' : 'due\nthat day'} color={T.textInverse} />
      <StatTile value={String(done)} label="done" color={T.textInverse} />
      <span className="spacer" />
      <Mascot mood={done === occ.length && occ.length ? 'happy' : 'calm'} size={56} />
    </div>
  );
}

/** Web equivalent of the exact-alarm banner: reminders need notification permission. */
function NotificationBanner() {
  const tasks = useSnapshot().tasks;
  const [perm, setPerm] = useState(Notify.permission());
  if (perm === 'granted' || perm === 'unsupported' || !tasks.some((t) => t.reminders.length)) return null;
  return (
    <button type="button" className="banner" style={{ width: '100%', textAlign: 'left', marginBottom: 12 }} onClick={async () => { await Notify.request(); setPerm(Notify.permission()); }}>
      <Icon name="alarmOff" />
      {perm === 'denied'
        ? 'Notifications are blocked for this site — allow them in your browser’s site settings to get reminders.'
        : 'Reminders need notification permission. Tap to allow.'}
    </button>
  );
}
