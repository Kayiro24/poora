import { Link } from 'react-router';
import { AppInfo } from '../core/appInfo';
import { T } from '../core/theme/tokens';
import { Icon, type IconName } from '../core/widgets/Icon';
import { Mascot, PooraMark } from '../core/widgets/widgets';

const img = (name: string) => `${import.meta.env.BASE_URL}images/${name}`;

/** A WebP screenshot with explicit size (no layout shift) and lazy loading. */
function Shot({ name, alt, eager }: { name: string; alt: string; eager?: boolean }) {
  return (
    <img
      className="shot"
      src={img(`${name}.webp`)}
      srcSet={`${img(`${name}-480.webp`)} 480w, ${img(`${name}.webp`)} 780w`}
      sizes="(min-width: 960px) 340px, 78vw"
      width={390}
      height={844}
      alt={alt}
      loading={eager ? 'eager' : 'lazy'}
      decoding="async"
      fetchPriority={eager ? 'high' : undefined}
    />
  );
}

const features: { id: string; icon: IconName; color: string; title: string; body: string; points: string[]; shot: string; alt: string }[] = [
  {
    id: 'focus',
    icon: 'timer',
    color: T.sage,
    title: 'Focus fully',
    body: 'A Pomodoro timer whose running screen shows nothing but the time. Reminders wait until you finish; on Android, Poora can switch on Do Not Disturb and puts it back after.',
    points: [
      'Focus on a task for 15, 25, 45 or 60 minutes',
      'Strict mode: no pausing, no ending early',
      'Android: block distracting apps during focus',
      'A daily focus goal and streak — you versus you, no leaderboards',
    ],
    shot: 'screen-focus',
    alt: 'Poora focus screen: a paper-white dial planning 25 minutes of focus and a 5 minute break, with a Start focus button.',
  },
  {
    id: 'tasks',
    icon: 'calendar',
    color: T.coral,
    title: 'Plan like a calendar',
    body: 'A day timeline with drag-to-reschedule, plus 3-day, week, month and agenda views. Repeats work like Google Calendar — every other day, the third Monday, or simply “3 times a week”.',
    points: ['Edit this, following or all occurrences', 'Reminders at the exact minute', 'Swipe to complete or skip'],
    shot: 'screen-tasks',
    alt: 'Poora tasks screen: a week strip above an hour-by-hour timeline with a coral morning task.',
  },
  {
    id: 'insights',
    icon: 'insights',
    color: T.periwinkle,
    title: 'Finish fully',
    body: 'Every day gets a ring that closes as you tick things off. Perfect days glow green and join into streaks; recurring tasks show their weekly rhythm.',
    points: ['Completion calendar, month and year', 'Streaks, on-time rate, best hours', 'Focus minutes per day and per task'],
    shot: 'screen-insights',
    alt: 'Poora insights screen: headline stats above a month calendar of completion rings coloured from red to green.',
  },
];

export function LandingPage() {
  return (
    <>
      <section className="hero">
        <div className="hero-copy">
          <p className="eyebrow"><PooraMark size={18} /> {AppInfo.meaning}</p>
          <h1 className="display hero-title">{AppInfo.tagline}</h1>
          <p className="hero-sub">
            Poora is a calm focus timer and daily planner. Focus on one thing, plan your day like a calendar, and watch each day’s ring
            close. Free, offline, no account.
          </p>
          <div className="row wrap" style={{ gap: 12, marginTop: 28 }}>
            <Link to="/start" className="btn coral">Open in your browser</Link>
            <a href={AppInfo.androidUrl} className="btn ghost" rel="noopener">
              <Icon name="android" /> Get the Android app
            </a>
          </div>
          <p className="body-s" style={{ marginTop: 14 }}>{AppInfo.subline} {AppInfo.motto} Works offline once loaded — install it from your browser’s menu.</p>
        </div>
        <div className="hero-shot">
          <Shot name="screen-home" eager alt="Poora home screen: next task with a countdown, a Start focus card and this week’s completion bubbles." />
        </div>
      </section>

      <section id="features" className="features" aria-labelledby="features-title">
        <h2 id="features-title" className="display section-h2">Three rooms, one calm app</h2>
        {features.map((f, i) => (
          <article key={f.id} id={f.id} className={`feature${i % 2 ? ' flip' : ''}`}>
            <div className="feature-copy">
              <span className="feature-icon" style={{ background: f.color }}><Icon name={f.icon} size={24} /></span>
              <h3 className="display d40">{f.title}</h3>
              <p className="feature-body">{f.body}</p>
              <ul className="ticks">
                {f.points.map((p) => (
                  <li key={p}><Icon name="check" size={16} /> {p}</li>
                ))}
              </ul>
            </div>
            <Shot name={f.shot} alt={f.alt} />
          </article>
        ))}
      </section>

      <section id="sync" className="sync" aria-labelledby="sync-title">
        <Mascot mood="happy" size={72} />
        <h2 id="sync-title" className="display section-h2">Your data stays yours</h2>
        <p>
          No account and no cloud: Poora keeps everything on your device. To move between phone and browser, export a file in one and
          import it in the other — the format is identical on both.
        </p>
        <div className="row wrap" style={{ gap: 10, justifyContent: 'center' }}>
          <Link to="/privacy" className="pill">Read the privacy policy</Link>
          <Link to="/contact" className="pill">Questions? Contact us</Link>
        </div>
      </section>

      <section className="cta-band">
        <h2 className="display section-h2">Make today whole</h2>
        <Link to="/start" className="btn dark">Start now — it’s free</Link>
      </section>
    </>
  );
}
