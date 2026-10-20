import { useRef, useState } from 'react';
import { useNavigate } from 'react-router';
import { AppInfo } from '../../core/appInfo';
import { updateSettings, useSettings } from '../../core/hooks';
import { Notify } from '../../core/platform/notifications';
import { ReminderScheduler } from '../../core/platform/reminderScheduler';
import { T } from '../../core/theme/tokens';
import { Icon } from '../../core/widgets/Icon';
import { confirm, toast } from '../../core/widgets/overlays';
import { Group, PooraMark, ScreenHeader, SRow, Wordmark } from '../../core/widgets/widgets';
import type { AppSettings } from './appSettings';
import { resetAllData } from './dataReset';
import { downloadExport, importJson } from './dataTransfer';

function Segmented<V extends string | boolean>({ value, options, onChange, label }: { value: V; options: [V, string][]; onChange: (v: V) => void; label: string }) {
  return (
    <div className="row" role="radiogroup" aria-label={label} style={{ background: T.surfaceHigh, borderRadius: 999, padding: 3, gap: 0, flex: 'none' }}>
      {options.map(([v, l]) => (
        <button
          key={String(v)}
          type="button"
          role="radio"
          aria-checked={value === v}
          onClick={() => onChange(v)}
          className="label"
          style={{ padding: '6px 14px', borderRadius: 999, background: value === v ? T.sageDeep : 'transparent', color: value === v ? T.textInverse : T.textPrimary }}
        >
          {l}
        </button>
      ))}
    </div>
  );
}

export function SettingsScreen() {
  const navigate = useNavigate();
  const s = useSettings();
  const set = (patch: Partial<AppSettings>) => updateSettings((x) => ({ ...x, ...patch }));
  const [perm, setPerm] = useState(Notify.permission());
  const file = useRef<HTMLInputElement>(null);

  const doImport = async (f: File) => {
    try {
      importJson(await f.text());
      ReminderScheduler.reschedule();
      toast('Import complete.');
    } catch (e) {
      toast(e instanceof Error ? e.message : 'Import failed.');
    }
  };

  const deleteAll = async () => {
    if (
      !(await confirm({
        title: 'Delete all data?',
        body: 'Every task, completion, focus session, preset and setting in this browser will be erased, and all scheduled reminders cancelled.',
        action: 'Continue',
        danger: true,
      }))
    ) return;
    if (!(await confirm({ title: 'Are you sure?', body: 'This can’t be undone. Export first if you might want it back.', action: 'Delete everything', danger: true }))) return;
    resetAllData();
    navigate('/welcome', { replace: true });
  };

  return (
    <div className="page">
      <ScreenHeader title="Settings" size={32} onBack={() => navigate(-1)} />
      <div style={{ marginTop: 24 }}>
        <Group title="You">
          <div style={{ padding: '12px 16px' }}>
            <label className="caps-label" htmlFor="name">Name</label>
            <input id="name" className="input" style={{ marginTop: 6 }} placeholder="Shown as “Hi, …” on Home" value={s.name} onChange={(e) => set({ name: e.target.value })} />
          </div>
        </Group>

        <Group title="Calendar">
          <SRow title="Week starts on" trailing={<Segmented label="Week starts on" value={s.mondayFirst} options={[[true, 'Mon'], [false, 'Sun']]} onChange={(v) => set({ mondayFirst: v })} />} />
          <SRow title="Time format" trailing={<Segmented label="Time format" value={s.use24h} options={[[false, '12h'], [true, '24h']]} onChange={(v) => set({ use24h: v })} />} />
          <SRow
            title="Default task reminder"
            trailing={
              <select
                className="input"
                style={{ width: 'auto', padding: '8px 12px' }}
                aria-label="Default task reminder"
                value={s.defaultReminderMin == null ? '' : String(s.defaultReminderMin)}
                onChange={(e) => set({ defaultReminderMin: e.target.value === '' ? null : Number(e.target.value) })}
              >
                {[null, 0, 5, 10, 15, 30, 60].map((m) => (
                  <option key={String(m)} value={m == null ? '' : String(m)}>{m == null ? 'None' : m === 0 ? 'At start' : `${m} min before`}</option>
                ))}
              </select>
            }
          />
        </Group>

        <Group title="Notifications">
          <SRow
            title="Notifications"
            subtitle={
              perm === 'unsupported' ? 'Not supported in this browser'
                : perm === 'granted' ? 'Allowed — reminders appear while Poora is open in a tab or installed'
                  : perm === 'denied' ? 'Blocked — allow them in your browser’s site settings'
                    : 'Off — reminders won’t appear'
            }
            trailing={
              perm === 'default' ? (
                <button type="button" className="text-btn coral" onClick={async () => { await Notify.request(); setPerm(Notify.permission()); ReminderScheduler.reschedule(); }}>Fix</button>
              ) : perm === 'granted' ? <span style={{ color: T.mint }}><Icon name="check" /></span> : undefined
            }
          />
          <SRow title="Focus settings" subtitle="Timer display, quiet mode, chime" onClick={() => navigate('/focus/settings')} trailing={<Icon name="chevronRight" className="icon muted" />} />
        </Group>

        <Group title="Data">
          <SRow
            title="Sync with the app"
            subtitle={`Export here and import in the ${AppInfo.name} Android app (Settings → Import data), or the other way round. Same file format on both.`}
          />
          <SRow title="Export data" subtitle="Download a JSON file" onClick={downloadExport} trailing={<Icon name="download" className="icon muted" />} />
          <SRow
            title="Import data"
            subtitle="Replace everything from an export (web or app)"
            onClick={async () => {
              if (await confirm({ title: 'Replace all data?', body: 'Importing replaces every task, record, session and setting with the file’s contents.', action: 'Choose file' })) file.current?.click();
            }}
            trailing={<Icon name="upload" className="icon muted" />}
          />
          <input
            ref={file}
            type="file"
            accept="application/json,.json"
            hidden
            onChange={(e) => {
              const f = e.target.files?.[0];
              if (f) void doImport(f);
              e.target.value = '';
            }}
          />
        </Group>

        <Group title="Danger zone">
          <SRow title="Delete all data" subtitle="Erase everything in this browser and start fresh" onClick={deleteAll} trailing={<span style={{ color: T.dayMissed }}><Icon name="deleteForever" /></span>} />
        </Group>

        <Group title="About">
          <div style={{ padding: '20px 16px 4px' }}>
            <Wordmark size={30} tagline />
          </div>
          <SRow title={`Version ${AppInfo.version}`} subtitle={`${AppInfo.meaning}\n${AppInfo.subline} Offline, no account — your data stays in this browser.`} />
          <a className="srow" href={AppInfo.androidUrl} target="_blank" rel="noreferrer" style={{ textDecoration: 'none' }}>
            <span className="t"><span className="title">Get the Android app</span><span className="body-s" style={{ display: 'block' }}>Free on GitHub Releases</span></span>
            <Icon name="android" className="icon" />
          </a>
        </Group>
        <div style={{ display: 'grid', placeItems: 'center', padding: 16 }}>
          <PooraMark size={32} />
        </div>
      </div>
    </div>
  );
}
