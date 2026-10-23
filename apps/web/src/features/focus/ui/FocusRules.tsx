import { useMemo, useState } from 'react';
import { AppInfo } from '../../../core/appInfo';
import { useDb } from '../../../core/db/store';
import { updateSettings, useSettings, useToday } from '../../../core/hooks';
import { T } from '../../../core/theme/tokens';
import { Range } from '../../../core/time/days';
import { Icon } from '../../../core/widgets/Icon';
import { Group, NumberSheet, SRow, SwitchRow } from '../../../core/widgets/widgets';
import { sessionFromRow } from '../../insights/data/insightsRepository';
import { FocusHistory } from '../domain/focusHistory';
import { fmtMs } from './FocusBreakdown';

/** "You versus you": today's focus against your own daily goal, and the streak of days you reached it. */
export function DailyGoalCard() {
  const rows = useDb((s) => s.focusSessions);
  const today = useToday();
  const goal = useSettings().dailyFocusGoalMin;
  const [picking, setPicking] = useState(false);
  const sessions = useMemo(() => rows.filter((r) => r.endedAt != null).map(sessionFromRow), [rows]);
  const done = FocusHistory.totals(FocusHistory.inRange(sessions, Range.day(today))).focusMs;
  const p = goal <= 0 ? 0 : Math.min(done / 60000 / goal, 1);
  const streak = FocusHistory.goalStreak(sessions, goal, today);
  const reached = p >= 1;
  const color = reached ? T.mint : T.sage;
  return (
    <>
      <button
        type="button"
        className="card clickable"
        style={{ width: '100%', textAlign: 'left' }}
        aria-label={`Today ${fmtMs(done)} of ${fmtMs(goal * 60000)} focus goal, ${streak} day streak. Change goal`}
        onClick={() => setPicking(true)}
      >
        <div className="row">
          <span className="display d16 muted" style={{ flex: 1 }}>Today’s focus</span>
          <span className="body-s">{AppInfo.motto}</span>
        </div>
        <div className="row" style={{ alignItems: 'baseline', gap: 8, marginTop: 8 }}>
          <span className="mono" style={{ fontSize: 30, color }}>{fmtMs(done)}</span>
          <span className="muted" style={{ flex: 1 }}>of {fmtMs(goal * 60000)}</span>
          <Icon name="tune" size={18} className="muted" />
        </div>
        <div className="outcome-bar" style={{ height: 10, marginTop: 10 }}>
          <span style={{ width: `${p * 100}%`, background: color }} />
        </div>
        <p className="body-s" style={{ margin: '10px 0 0' }}>
          {reached
            ? `Goal reached — you beat yesterday’s you.${streak > 1 ? ` ${streak} days in a row.` : ''}`
            : streak > 0
              ? `${streak}-day streak. ${fmtMs(Math.max(goal * 60000 - done, 0))} to keep it going.`
              : 'Reach your goal to start a streak.'}
        </p>
      </button>
      <NumberSheet
        open={picking}
        title="Daily focus goal"
        min={15}
        max={600}
        step={15}
        value={goal}
        unit="minutes"
        onPick={(v) => {
          updateSettings((s) => ({ ...s, dailyFocusGoalMin: v }));
          setPicking(false);
        }}
        onClose={() => setPicking(false)}
      />
    </>
  );
}

/** Strict mode here; app blocking and uninstall protection live in the Android app. */
export function FocusRules() {
  const s = useSettings();
  return (
    <Group title="Focus rules">
      <SwitchRow
        title="Strict mode"
        subtitle="Focus can’t be paused or ended early. On Android, Poora also can’t be uninstalled until it ends."
        value={s.strictMode}
        onChange={(v) => updateSettings((x) => ({ ...x, strictMode: v }))}
      />
      <SRow title="Blocked apps" subtitle="Android app only — apps you pick won’t open during focus. In the browser, leaving the tab is counted as an interruption." />
    </Group>
  );
}
