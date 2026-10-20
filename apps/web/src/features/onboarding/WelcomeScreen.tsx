import { useEffect, useState, type ReactNode } from 'react';
import { useNavigate } from 'react-router';
import { AppInfo } from '../../core/appInfo';
import { updateSettings } from '../../core/hooks';
import { Feedback } from '../../core/platform/feedback';
import { T } from '../../core/theme/tokens';
import { Icon } from '../../core/widgets/Icon';
import { CompletionRing, Mascot, PooraMark, Wordmark } from '../../core/widgets/widgets';

/** First-run welcome: meaning, Focus, Finish, and a name for "Hi, …". */
export function WelcomeScreen() {
  const navigate = useNavigate();
  const [page, setPage] = useState(0);
  const [name, setName] = useState('');
  const [mark, setMark] = useState(0);
  const count = 4;
  const last = page === count - 1;

  useEffect(() => {
    let raf = 0;
    const start = performance.now();
    const step = (now: number) => {
      const v = Math.min((now - start) / 1200, 1);
      setMark(v);
      if (v < 1) raf = requestAnimationFrame(step);
    };
    raf = requestAnimationFrame(step);
    return () => cancelAnimationFrame(raf);
  }, []);

  const finish = () => {
    Feedback.success();
    updateSettings((s) => ({ ...s, onboarded: true, name: name.trim() || s.name }));
    navigate('/home', { replace: true });
  };

  const pages: { hero: ReactNode; title: string; body: ReactNode }[] = [
    {
      hero: <PooraMark size={200} progress={mark} />,
      title: AppInfo.tagline,
      body: (
        <>
          {AppInfo.meaning}
          <br />
          <br />A calm place to focus on one thing, plan your day, and watch it come together.
        </>
      ),
    },
    {
      hero: (
        <div className="panel sage" style={{ width: 260, textAlign: 'center', padding: 28 }}>
          <Icon name="timer" size={40} />
          <div className="mono" style={{ fontSize: 64, marginTop: 12 }}>25:00</div>
        </div>
      ),
      title: 'Focus fully.',
      body: `A quiet timer with nothing else on screen. Your reminders wait until you’re done — on Android, ${AppInfo.name} can silence your phone too.`,
    },
    {
      hero: (
        <div className="row" style={{ gap: 12 }}>
          {([[0.6, T.dayMid], [0.85, T.dayHigh], [1, T.dayPerfect]] as const).map(([v, c]) => (
            <CompletionRing key={v} value={v} color={c} size={72} stroke={6} glow={v === 1} fill={`${c}${v === 1 ? '59' : '26'}`}>
              {v === 1 && <Icon name="check" />}
            </CompletionRing>
          ))}
        </div>
      ),
      title: 'Finish fully.',
      body: 'Plan with repeats like a calendar, tick things off, and see each day’s ring close. Everything stays on this device — no account, no cloud.',
    },
  ];

  return (
    <div style={{ minHeight: '100%', display: 'flex', flexDirection: 'column', maxWidth: 560, margin: '0 auto', padding: '16px 20px 24px' }}>
      <div className="row">
        <Wordmark size={26} />
        <span className="spacer" />
        {!last && (
          <button type="button" className="text-btn" onClick={() => setPage(count - 1)}>
            Skip
          </button>
        )}
      </div>

      <div key={page} style={{ flex: 1, paddingTop: 32, animation: 'page-in 360ms var(--ease)' }}>
        {page < 3 ? (
          <>
            <div style={{ height: 260, display: 'grid', placeItems: 'center' }}>{pages[page].hero}</div>
            <h1 className="display d40" style={{ marginTop: 32 }}>{pages[page].title}</h1>
            <p className="muted" style={{ fontSize: 16, lineHeight: 1.5, marginTop: 12 }}>{pages[page].body}</p>
          </>
        ) : (
          <>
            <div style={{ height: 140, display: 'grid', placeItems: 'center' }}>
              <Mascot mood="happy" size={120} />
            </div>
            <h1 className="display d32" style={{ marginTop: 32 }}>What should we call you?</h1>
            <p className="muted" style={{ fontSize: 15, marginTop: 12 }}>Just for the “Hi” on your home screen. You can skip this.</p>
            <input
              className="input title-input"
              style={{ background: T.surfaceHigh, padding: '14px 16px', borderRadius: 16, fontSize: 28, marginTop: 20 }}
              placeholder="YOUR NAME"
              value={name}
              autoFocus
              onChange={(e) => setName(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && finish()}
              aria-label="Your name"
            />
          </>
        )}
      </div>

      <div className="row" style={{ marginTop: 24 }}>
        {Array.from({ length: count }, (_, i) => (
          <span
            key={i}
            style={{ width: i === page ? 22 : 8, height: 8, borderRadius: 4, marginRight: 6, background: i === page ? T.coral : T.outline, transition: 'width 280ms var(--ease)' }}
          />
        ))}
        <span className="spacer" />
        <button type="button" className="btn coral" onClick={last ? finish : () => setPage(page + 1)}>
          {last ? 'Get started' : 'Next'}
        </button>
      </div>
    </div>
  );
}
