/** Running-screen timer text — shared with the settings preview (§4.3). */
export class TimerFormat {
  constructor(
    readonly showSeconds: boolean,
    /** Stored preference; only effective while seconds are on. */
    readonly showSubSeconds: boolean,
  ) {}

  get effectiveSubSeconds() {
    return this.showSeconds && this.showSubSeconds;
  }

  main(remainingMs: number): string {
    const ms = Math.max(0, remainingMs);
    if (!this.showSeconds) return String(Math.ceil(ms / 60000));
    const totalCs = this.effectiveSubSeconds ? Math.ceil(ms / 10) : Math.ceil(ms / 1000) * 100;
    const totalSec = Math.floor(totalCs / 100);
    const base = `${String(Math.floor(totalSec / 60)).padStart(2, '0')}:${String(totalSec % 60).padStart(2, '0')}`;
    return this.effectiveSubSeconds ? `${base}.${String(totalCs % 100).padStart(2, '0')}` : base;
  }

  get unit(): string | null {
    return this.showSeconds ? null : 'min';
  }
}
