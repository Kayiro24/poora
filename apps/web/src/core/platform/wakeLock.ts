/** Screen Wake Lock (keeps the screen on during focus where supported). */
let sentinel: WakeLockSentinel | null = null;
let wanted = false;

async function acquire() {
  try {
    sentinel = (await navigator.wakeLock?.request('screen')) ?? null;
  } catch {
    sentinel = null;
  }
}

// The browser drops the lock when the tab is hidden; take it back on return.
document.addEventListener('visibilitychange', () => {
  if (wanted && document.visibilityState === 'visible') void acquire();
});

export const WakeLock = {
  async enable() {
    wanted = true;
    await acquire();
  },
  async disable() {
    wanted = false;
    await sentinel?.release().catch(() => {});
    sentinel = null;
  },
};
