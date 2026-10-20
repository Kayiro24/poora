import { useSyncExternalStore, type ReactNode } from 'react';
import { Link, NavLink, Outlet } from 'react-router';
import { AppInfo } from '../core/appInfo';
import { Icon } from '../core/widgets/Icon';
import { Wordmark } from '../core/widgets/widgets';
import { Analytics, useConsent } from '../seo/analytics';
import type { Crumb } from '../seo/site';

/** Public pages: header, footer, consent banner. Rendered identically on server and client. */
export function SiteLayout() {
  return (
    <div className="site">
      <a href="#main" className="skip-link">Skip to content</a>
      <header className="site-header">
        <Link to="/" className="site-brand" aria-label={`${AppInfo.name} home`}>
          <Wordmark size={24} />
        </Link>
        <nav aria-label="Site" className="site-nav">
          <a href={`${import.meta.env.BASE_URL}#features`} className="site-link hide-mobile">Features</a>
          <NavLink to="/privacy" className="site-link hide-mobile">Privacy</NavLink>
          <NavLink to="/contact" className="site-link hide-mobile">Contact</NavLink>
          <Link to="/start" className="btn coral site-cta">Open app</Link>
        </nav>
      </header>
      <main id="main">
        <Outlet />
      </main>
      <SiteFooter />
      <ConsentBanner />
    </div>
  );
}

export function SiteFooter() {
  return (
    <footer className="site-footer">
      <div className="site-footer-inner">
        <div>
          <Wordmark size={26} tagline />
          <p className="body-s" style={{ marginTop: 12, maxWidth: 320 }}>{AppInfo.meaning} Free and offline. Your data stays on your device.</p>
        </div>
        <nav aria-label="Footer" className="site-footer-links">
          <div>
            <h2 className="caps-label">Product</h2>
            <ul>
              <li><Link to="/start">Open the web app</Link></li>
              <li><a href={AppInfo.androidUrl} rel="noopener">Android app (GitHub)</a></li>
              <li><a href={`${import.meta.env.BASE_URL}#features`}>Features</a></li>
              <li><a href={`${import.meta.env.BASE_URL}#sync`}>Sync phone ↔ web</a></li>
            </ul>
          </div>
          <div>
            <h2 className="caps-label">Company</h2>
            <ul>
              <li><Link to="/contact">Contact</Link></li>
              <li><Link to="/privacy">Privacy policy</Link></li>
              <li><a href="https://github.com/Kayiro24/poora" rel="noopener">Source on GitHub</a></li>
            </ul>
          </div>
        </nav>
      </div>
      <p className="body-s site-copy">© {__BUILD_YEAR__} {AppInfo.name}. {AppInfo.subline}</p>
    </footer>
  );
}

/** Visible breadcrumbs (JSON-LD BreadcrumbList is emitted in <head>). */
export function Breadcrumbs({ crumbs }: { crumbs: Crumb[] }) {
  return (
    <nav aria-label="Breadcrumb" className="crumbs">
      <ol>
        {crumbs.map((c, i) => (
          <li key={c.path + c.name}>
            {i < crumbs.length - 1 ? (
              <>
                <Link to={c.path}>{c.name}</Link>
                <Icon name="chevronRight" size={14} />
              </>
            ) : (
              <span aria-current="page">{c.name}</span>
            )}
          </li>
        ))}
      </ol>
    </nav>
  );
}

const noop = () => () => {};
/** False during server render and hydration, true after mount. */
export const useMounted = () => useSyncExternalStore(noop, () => true, () => false);

function ConsentBanner() {
  const mounted = useMounted();
  const consent = useConsent((s) => s.consent);
  if (!mounted || !Analytics.enabled() || consent) return null;
  return (
    <div className="consent" role="dialog" aria-label="Analytics consent">
      <p>
        May we count visits with Google Analytics? It helps us see which pages are useful. No task data is ever sent.{' '}
        <Link to="/privacy#analytics">Details</Link>
      </p>
      <div className="row">
        <button type="button" className="text-btn" onClick={() => Analytics.set('denied')}>No thanks</button>
        <button type="button" className="btn coral" style={{ height: 40, fontSize: 16, padding: '0 18px' }} onClick={() => Analytics.set('granted')}>Allow</button>
      </div>
    </div>
  );
}

export const Prose = ({ children }: { children: ReactNode }) => <div className="prose">{children}</div>;
