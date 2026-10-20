import { useNavigate } from 'react-router';
import { updateSettings, useSettings } from '../../../core/hooks';
import { Feedback } from '../../../core/platform/feedback';
import { T } from '../../../core/theme/tokens';
import { Icon } from '../../../core/widgets/Icon';
import { Group, ScreenHeader, SRow, SwitchRow } from '../../../core/widgets/widgets';
import { chimes, type AppSettings } from '../../settings/appSettings';
import { TimerFormat } from '../domain/timerFormat';

const SAMPLE_MS = (24 * 60 + 59) * 1000 + 870;

export function FocusSettingsScreen() {
  const navigate = useNavigate();
  const s = useSettings();
  const set = (patch: Partial<AppSettings>) => updateSettings((x) => ({ ...x, ...patch }));
  const fmt = new TimerFormat(s.showSeconds, s.showSubSeconds);
  return (
    <div className="page">
      <ScreenHeader title="Focus settings" size={32} onBack={() => navigate(-1)} />
      <div style={{ marginTop: 24 }}>
        <Group title="Timer display">
          {/* Exactly what the running screen shows (same TimerFormat). */}
          <div aria-label={`Preview: ${fmt.main(SAMPLE_MS)} ${fmt.unit ?? ''}`} style={{ height: 96, display: 'grid', placeItems: 'center', background: T.bg }}>
            <span className="row" style={{ alignItems: 'baseline', gap: 6 }}>
              <span className="mono" style={{ fontSize: 48, fontWeight: 400 }}>{fmt.main(SAMPLE_MS)}</span>
              {fmt.unit && <span className="muted" style={{ fontSize: 16 }}>{fmt.unit}</span>}
            </span>
          </div>
          <SwitchRow title="Show seconds" value={s.showSeconds} onChange={(v) => set({ showSeconds: v })} />
          <SwitchRow
            title="Show milliseconds"
            subtitle={s.showSeconds ? 'Two digits, refreshed every frame' : 'Turn on seconds first'}
            value={fmt.effectiveSubSeconds}
            disabled={!s.showSeconds}
            onChange={(v) => set({ showSubSeconds: v })}
          />
        </Group>
        <Group title="Session flow">
          <SwitchRow title="Auto-start breaks" value={s.autoStartBreaks} onChange={(v) => set({ autoStartBreaks: v })} />
          <SwitchRow title="Auto-start next focus" value={s.autoStartFocus} onChange={(v) => set({ autoStartFocus: v })} />
          <SwitchRow title="Long-press to end session" value={s.longPressToEnd} onChange={(v) => set({ longPressToEnd: v })} />
        </Group>
        <Group title="Quiet">
          <SwitchRow title="Hold app reminders during focus" subtitle="Always on. Held reminders arrive together when you finish." value disabled />
          <SRow
            title="Silence other apps"
            subtitle="Browsers can’t do this. Turn on your system’s Focus / Do Not Disturb — or use the Android app, which can switch it for you."
          />
          <SwitchRow title="Keep screen awake" value={s.keepAwake} onChange={(v) => set({ keepAwake: v })} />
        </Group>
        <Group title="Sound">
          {chimes.map((c) => (
            <SRow
              key={c.id}
              title={c.label}
              onClick={() => {
                set({ chime: c.id });
                Feedback.chime(c.id);
              }}
              trailing={s.chime === c.id ? <span style={{ color: T.sage }}><Icon name="check" /></span> : undefined}
            />
          ))}
          <SwitchRow title="Haptics" subtitle="On devices that support vibration" value={s.haptics} onChange={(v) => set({ haptics: v })} />
        </Group>
      </div>
    </div>
  );
}
