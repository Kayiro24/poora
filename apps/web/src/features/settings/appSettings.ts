import { defaultFocus, type FocusConfig } from '../focus/domain/timerEngine';

export type Chime = 'bowl' | 'wood' | 'softBell' | 'none';

export const chimes: { id: Chime; label: string; file: string | null }[] = [
  { id: 'bowl', label: 'Bowl', file: 'bowl.wav' },
  { id: 'wood', label: 'Wood', file: 'wood.wav' },
  { id: 'softBell', label: 'Soft bell', file: 'soft_bell.wav' },
  { id: 'none', label: 'None', file: null },
];

/** User settings — same keys and string encoding as the app, so exports round-trip. */
export interface AppSettings {
  name: string;
  mondayFirst: boolean;
  defaultReminderMin: number | null;
  use24h: boolean;
  showSeconds: boolean;
  showSubSeconds: boolean;
  autoStartBreaks: boolean;
  autoStartFocus: boolean;
  longPressToEnd: boolean;
  silencePhone: boolean;
  keepAwake: boolean;
  chime: Chime;
  haptics: boolean;
  lastFocus: FocusConfig;
  lastFocusAt: number | null;
  iosFocusTipShown: boolean;
  onboarded: boolean;
  /** Android package names (set in the app); kept so exports round-trip. */
  distractingApps: string[];
  /** Strict mode: a running focus phase can't be paused, skipped or ended. */
  strictMode: boolean;
  /** "You versus you": the day's focus target, in minutes. */
  dailyFocusGoalMin: number;
  /** Android packages blocked during focus (set in the app); kept so exports round-trip. */
  blockedApps: string[];
}

export const defaultSettings: AppSettings = {
  name: '',
  mondayFirst: true,
  defaultReminderMin: 10,
  use24h: false,
  showSeconds: true,
  showSubSeconds: false,
  autoStartBreaks: true,
  autoStartFocus: false,
  longPressToEnd: true,
  silencePhone: false,
  keepAwake: true,
  chime: 'bowl',
  haptics: true,
  lastFocus: defaultFocus,
  lastFocusAt: null,
  iosFocusTipShown: false,
  onboarded: false,
  distractingApps: [],
  strictMode: false,
  dailyFocusGoalMin: 120,
  blockedApps: [],
};

export function settingsToMap(s: AppSettings): Record<string, string> {
  return {
    name: s.name,
    mondayFirst: String(s.mondayFirst),
    defaultReminderMin: s.defaultReminderMin == null ? '' : String(s.defaultReminderMin),
    use24h: String(s.use24h),
    showSeconds: String(s.showSeconds),
    showSubSeconds: String(s.showSubSeconds),
    autoStartBreaks: String(s.autoStartBreaks),
    autoStartFocus: String(s.autoStartFocus),
    longPressToEnd: String(s.longPressToEnd),
    silencePhone: String(s.silencePhone),
    keepAwake: String(s.keepAwake),
    chime: s.chime,
    haptics: String(s.haptics),
    lastFocus: JSON.stringify(s.lastFocus),
    lastFocusAt: s.lastFocusAt == null ? '' : String(s.lastFocusAt),
    iosFocusTipShown: String(s.iosFocusTipShown),
    onboarded: String(s.onboarded),
    distractingApps: s.distractingApps.join(','),
    strictMode: String(s.strictMode),
    dailyFocusGoalMin: String(s.dailyFocusGoalMin),
    blockedApps: s.blockedApps.join(','),
  };
}

export function settingsFromMap(m: Record<string, string>): AppSettings {
  const d = defaultSettings;
  const b = (k: string, def: boolean) => (m[k] == null ? def : m[k] === 'true');
  let lastFocus = d.lastFocus;
  try {
    if (m.lastFocus) lastFocus = { ...defaultFocus, ...(JSON.parse(m.lastFocus) as Partial<FocusConfig>) };
  } catch {
    lastFocus = d.lastFocus;
  }
  const n = (v: string | undefined) => (v == null || v === '' || Number.isNaN(Number(v)) ? null : Number(v));
  return {
    name: m.name ?? d.name,
    mondayFirst: b('mondayFirst', d.mondayFirst),
    defaultReminderMin: 'defaultReminderMin' in m ? n(m.defaultReminderMin) : d.defaultReminderMin,
    use24h: b('use24h', d.use24h),
    showSeconds: b('showSeconds', d.showSeconds),
    showSubSeconds: b('showSubSeconds', d.showSubSeconds),
    autoStartBreaks: b('autoStartBreaks', d.autoStartBreaks),
    autoStartFocus: b('autoStartFocus', d.autoStartFocus),
    longPressToEnd: b('longPressToEnd', d.longPressToEnd),
    silencePhone: b('silencePhone', d.silencePhone),
    keepAwake: b('keepAwake', d.keepAwake),
    chime: (['bowl', 'wood', 'softBell', 'none'] as Chime[]).find((c) => c === m.chime) ?? d.chime,
    haptics: b('haptics', d.haptics),
    lastFocus,
    lastFocusAt: n(m.lastFocusAt),
    iosFocusTipShown: b('iosFocusTipShown', d.iosFocusTipShown),
    onboarded: b('onboarded', d.onboarded),
    distractingApps: (m.distractingApps ?? '').split(',').filter(Boolean),
    strictMode: b('strictMode', d.strictMode),
    dailyFocusGoalMin: n(m.dailyFocusGoalMin) ?? d.dailyFocusGoalMin,
    blockedApps: (m.blockedApps ?? '').split(',').filter(Boolean),
  };
}
