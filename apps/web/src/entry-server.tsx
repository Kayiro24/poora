import { StrictMode } from 'react';
import { renderToString } from 'react-dom/server';
import { createStaticHandler, createStaticRouter, StaticRouterProvider } from 'react-router';
import { basename, siteRoutes, withRoot } from './app/routes';

/**
 * Build-time server rendering of the public pages (scripts/prerender.mjs).
 * Uses the same route objects as the browser router, so the HTML hydrates.
 */
export async function render(path: string): Promise<string> {
  const handler = createStaticHandler(withRoot([siteRoutes]), { basename });
  const url = `http://localhost${basename === '/' ? '' : basename}${path}`;
  const context = await handler.query(new Request(url));
  if (context instanceof Response) throw new Error(`Unexpected redirect while rendering ${path}`);
  const router = createStaticRouter(handler.dataRoutes, context);
  return renderToString(
    <StrictMode>
      <StaticRouterProvider router={router} context={context} hydrate={false} />
    </StrictMode>,
  );
}

export { headHtml, metaFor, pages, redirects, Site } from './seo/site';
