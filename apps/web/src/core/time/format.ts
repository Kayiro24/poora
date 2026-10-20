/** Display formatting for times and durations (mirrors the app's `Fmt`). */
export const Fmt = {
  minute(minute: number, use24h: boolean): string {
    const h = Math.floor(minute / 60) % 24;
    const mm = String(minute % 60).padStart(2, '0');
    if (use24h) return `${String(h).padStart(2, '0')}:${mm}`;
    const h12 = h % 12 === 0 ? 12 : h % 12;
    return `${h12}:${mm} ${h < 12 ? 'am' : 'pm'}`;
  },

  time(t: Date, use24h: boolean): string {
    return Fmt.minute(t.getHours() * 60 + t.getMinutes(), use24h);
  },

  hour(h: number, use24h: boolean): string {
    if (use24h) return String(h).padStart(2, '0');
    const h12 = h % 12 === 0 ? 12 : h % 12;
    return `${h12} ${h % 24 < 12 ? 'am' : 'pm'}`;
  },

  duration(minutes: number): string {
    if (minutes < 60) return `${minutes} min`;
    const h = Math.floor(minutes / 60);
    const m = minutes % 60;
    return m === 0 ? `${h} h` : `${h} h ${m} min`;
  },

  countdown(ms: number): string {
    const s = Math.max(0, Math.floor(ms / 1000));
    const h = Math.floor(s / 3600);
    const m = Math.floor((s % 3600) / 60);
    return `${h}:${String(m).padStart(2, '0')}:${String(s % 60).padStart(2, '0')}`;
  },

  ago(then: Date, now: Date): string {
    const mins = Math.floor((now.getTime() - then.getTime()) / 60000);
    if (mins < 1) return 'just now';
    if (mins < 60) return `${mins} min ago`;
    if (mins < 1440) return `${Math.floor(mins / 60)} h ago`;
    return `${Math.floor(mins / 1440)} d ago`;
  },

  utcOffset(date: Date): string {
    const off = -date.getTimezoneOffset();
    const sign = off < 0 ? '-' : '+';
    const a = Math.abs(off);
    const h = Math.floor(a / 60);
    const m = a % 60;
    return m === 0 ? `UTC${sign}${h}` : `UTC${sign}${h}:${String(m).padStart(2, '0')}`;
  },

  hours(minutes: number): string {
    const h = minutes / 60;
    return h >= 10 ? h.toFixed(0) : h.toFixed(1);
  },
};

export const weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
export const weekdayLong = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
export const weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
export const monthLong = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
