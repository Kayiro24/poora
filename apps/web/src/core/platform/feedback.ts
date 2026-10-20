import { getSettings } from '../hooks';
import { chimes, type Chime } from '../../features/settings/appSettings';

/** Haptics (where the browser supports vibration) and the session chime. */
export const Feedback = {
  light() {
    if (getSettings().haptics) navigator.vibrate?.(10);
  },
  selection() {
    if (getSettings().haptics) navigator.vibrate?.(5);
  },
  success() {
    if (getSettings().haptics) navigator.vibrate?.([15, 40, 15]);
  },
  chime(override?: Chime) {
    const file = chimes.find((c) => c.id === (override ?? getSettings().chime))?.file;
    if (!file) return;
    const audio = new Audio(`${import.meta.env.BASE_URL}assets/sounds/${file}`);
    audio.volume = 0.8;
    // Autoplay can be blocked until the user has interacted; that's fine.
    audio.play().catch(() => {});
  },
};
