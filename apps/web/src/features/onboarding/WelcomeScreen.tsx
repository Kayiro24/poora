import { useEffect, useState, type ReactNode } from 'react';
import { useNavigate } from 'react-router';
import { AppInfo } from '../../core/appInfo';
import { updateSettings } from '../../core/hooks';
import { db } from '../../core/db/store';
import { Feedback } from '../../core/platform/feedback';
import { Notify } from '../../core/platform/notifications';
import { T } from '../../core/theme/tokens';
import { Icon } from '../../core/widgets/Icon';
import { CompletionRing, Mascot, PooraMark, Wordmark } from '../../core/widgets/widgets';

/** The notifications step — Skip lands here, never past it. */
const NOTIF_PAGE = 3;

/** null = not asked yet; true/false = the answer (or what the browser already decided). */
function initialNotif(): boolean | null {
  const p = Notify.permission();
  return p === 'granted' ? true : p === 'denied' || p === 'unsupported' ? false : null;
}

/** First-run welcome: meaning, Focus, Finish, notifications, and a name for "Hi, …". */
export function WelcomeScreen() {
  const navigate = useNavigate();
  const [page, setPage] = useState(0);
  const [name, setName] = useState('');
  const [mark, setMark] = useState(0);
  const [notif, setNotif] = useState<boolean | null>(initialNotif);
  const count = 5;
  const last = page === count - 1;
  const asking = page === NOTIF_PAGE && notif == null;

  const askNotifications = async () => {
    const granted = await Notify.request();
    db().setSettings({ asked_reminder_permissions: 'true' });
    setNotif(granted);
    if (granted) Feedback.success();
    setPage(NOTIF_PAGE + 1);
  };

  const declineNotifications = () => {
    db().setSettings({ asked_reminder_permissions: 'true' });
    setNotif(false);
    setPage(NOTIF_PAGE + 1);
  };

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
      body: `A quiet timer with nothing else on screen. Your reminders wait until you’re done — on Android, ${AppInfo.name} can silence your phone and block distracting apps. No leaderboards, no groups. ${AppInfo.motto}`,
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
        {page < NOTIF_PAGE && (
          <button type="button" className="text-btn" onClick={() => setPage(NOTIF_PAGE)}>
            Skip
          </button>
        )}
      </div>

      <div key={page} style={{ flex: 1, paddingTop: 32, animation: 'page-in 360ms var(--ease)' }}>
        {page === NOTIF_PAGE ? (
          <NotificationsStep granted={notif} />
        ) : page < 3 ? (
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
        {asking && (
          <button type="button" className="text-btn" style={{ marginRight: 8 }} onClick={declineNotifications}>
            Not now
          </button>
        )}
        <button type="button" className="btn coral" onClick={last ? finish : asking ? askNotifications : () => setPage(page + 1)}>
          {last ? 'Get started' : asking ? 'Allow' : 'Next'}
        </button>
      </div>
    </div>
  );
}

/** Ask for notifications first; if declined, only Settings can turn them on. */
function NotificationsStep({ granted }: { granted: boolean | null }) {
  const unsupported = Notify.permission() === 'unsupported';
  const [title, body] =
    granted === true
      ? ['You’re all set.', 'Reminders will arrive on time — and stay quiet while you focus.']
      : unsupported
        ? ['No notifications here.', 'This browser can’t show notifications. Reminders still appear in the app — or use the Android app.']
        : granted === false
          ? ['No problem.', `${AppInfo.name} won’t ask again, so reminders won’t appear for now.`]
          : ['Stay on time.', 'Allow notifications so task reminders ring at the right minute, with Poora’s own tone. They’re held while you focus and delivered together after.'];
  return (
    <>
      <div style={{ height: 260, display: 'grid', placeItems: 'center' }}>
        <div className={`panel ${granted === false ? 'peri' : 'coral'}`} style={{ width: 160, height: 160, borderRadius: 48, display: 'grid', placeItems: 'center' }}>
          <Icon name={granted === false ? 'alarmOff' : 'bell'} size={72} />
        </div>
      </div>
      <h1 className="display d40" style={{ marginTop: 32 }}>{title}</h1>
      <p className="muted" style={{ fontSize: 16, lineHeight: 1.5, marginTop: 12 }}>{body}</p>
      {granted === false && !unsupported && (
        <div className="card" style={{ marginTop: 20 }}>
          <p className="caps-label" style={{ margin: '0 0 8px' }}>You can turn this on any time</p>
          <p style={{ margin: 0, lineHeight: 1.6 }}>
            • In {AppInfo.name}: Settings → Notifications
            <br />• In your browser: click the lock / site icon next to the address bar → Notifications → Allow
            <br />• Installed app: your system’s Settings → Notifications → {AppInfo.name}
          </p>
        </div>
      )}
    </>
  );
}
