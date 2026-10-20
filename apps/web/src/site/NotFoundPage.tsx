import { Link } from 'react-router';
import { Mascot } from '../core/widgets/widgets';

/** Custom 404 (prerendered to 404.html; Vercel serves it with a real 404 status). */
export function NotFoundPage() {
  return (
    <div className="site-page" style={{ textAlign: 'center', paddingTop: 48 }}>
      <Mascot mood="sleepy" size={120} />
      <h1 className="display d40" style={{ marginTop: 24 }}>This page wandered off</h1>
      <p className="muted" style={{ maxWidth: 440, margin: '12px auto 0', lineHeight: 1.5 }}>
        The link may be old or mistyped. These are good places to pick up again:
      </p>
      <nav aria-label="Helpful links" className="row wrap" style={{ gap: 10, justifyContent: 'center', marginTop: 24 }}>
        <Link to="/" className="btn coral">Poora home</Link>
        <Link to="/start" className="pill">Open the app</Link>
        <Link to="/privacy" className="pill">Privacy policy</Link>
        <Link to="/contact" className="pill">Contact</Link>
      </nav>
    </div>
  );
}
