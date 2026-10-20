import { Outlet, type RouteObject } from 'react-router';
import { SeoSync } from '../seo/Seo';
import { ContactPage } from '../site/ContactPage';
import { LandingPage } from '../site/LandingPage';
import { NotFoundPage } from '../site/NotFoundPage';
import { PrivacyPage } from '../site/PrivacyPage';
import { SiteLayout } from '../site/SiteLayout';

/** Root: renders the matched page and keeps <head> in sync. No DOM of its own. */
function Root() {
  return (
    <>
      <Outlet />
      <SeoSync />
    </>
  );
}

/**
 * Public pages — eager so prerendered HTML hydrates without a loading gap.
 * Shared with the server entry (entry-server.tsx) so both trees match.
 */
export const siteRoutes: RouteObject = {
  element: <SiteLayout />,
  children: [
    { path: '/', element: <LandingPage /> },
    { path: '/privacy', element: <PrivacyPage /> },
    { path: '/contact', element: <ContactPage /> },
    { path: '*', element: <NotFoundPage /> },
  ],
};

/** Root + public pages (+ the app routes in the browser). Server-safe: imports no app code. */
export const withRoot = (children: RouteObject[]): RouteObject[] => [{ element: <Root />, children }];

export const basename = import.meta.env.BASE_URL.replace(/\/$/, '') || '/';
