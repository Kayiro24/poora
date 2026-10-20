import { useEffect, useRef, useState } from 'react';
import { useNavigate } from 'react-router';
import { AppInfo } from '../../core/appInfo';
import { useReducedMotion, useSettings } from '../../core/hooks';
import { PooraMark } from '../../core/widgets/widgets';

const DURATION = 1500;
const ease = (t: number) => (t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2);

/** Brand moment: the ring closes, then name + tagline settle in. Tap to skip. */
export function SplashScreen() {
  const navigate = useNavigate();
  const { onboarded } = useSettings();
  const reduced = useReducedMotion();
  const [t, setT] = useState(reduced ? 1 : 0);
  const left = useRef(false);

  useEffect(() => {
    const leave = () => {
      if (left.current) return;
      left.current = true;
      navigate(onboarded ? '/home' : '/welcome', { replace: true });
    };
    if (reduced) {
      const id = setTimeout(leave, 500);
      return () => clearTimeout(id);
    }
    let raf = 0;
    const start = performance.now();
    const step = (now: number) => {
      const v = Math.min((now - start) / DURATION, 1);
      setT(v);
      if (v < 1) raf = requestAnimationFrame(step);
      else setTimeout(leave, 350);
    };
    raf = requestAnimationFrame(step);
    const skip = () => leave();
    window.addEventListener('pointerdown', skip);
    return () => {
      cancelAnimationFrame(raf);
      window.removeEventListener('pointerdown', skip);
    };
  }, [navigate, onboarded, reduced]);

  const text = ease(Math.min(Math.max((t - 0.55) / 0.45, 0), 1));
  return (
    <div style={{ minHeight: '100%', display: 'grid', placeItems: 'center', padding: 24 }}>
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
        <PooraMark size={120} progress={ease(Math.min(t / 0.7, 1))} />
        <div style={{ marginTop: 28, textAlign: 'center', opacity: text, transform: `translateY(${12 * (1 - text)}px)` }}>
          <h1 className="display" style={{ fontSize: 48 }}>{AppInfo.name}</h1>
          <div style={{ fontSize: 16, marginTop: 8 }}>{AppInfo.tagline}</div>
          <div className="muted" style={{ fontSize: 13, marginTop: 4 }}>{AppInfo.subline}</div>
        </div>
      </div>
    </div>
  );
}
