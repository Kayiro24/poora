// Build-time rendering for static hosting (GitHub Pages has no server):
// public pages become real HTML (SEO), app routes get their own entry files
// (200 + unique <title>), plus 404.html, robots.txt, sitemap.xml, redirects.
import { mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const dist = join(here, '../dist');
const ssrEntry = join(here, '../dist-ssr/entry-server.js');
const { render, headHtml, metaFor, pages, redirects, Site } = await import(pathToFileURL(ssrEntry).href);

const template = readFileSync(join(dist, 'index.html'), 'utf8');
const SEO_BLOCK = /<!--seo:start-->[\s\S]*?<!--seo:end-->/;
if (!SEO_BLOCK.test(template)) throw new Error('index.html is missing the <!--seo:start--> … <!--seo:end--> block');

const out = (path) => (path === '/' ? join(dist, 'index.html') : path === '/404' ? join(dist, '404.html') : join(dist, path, 'index.html'));
const write = (file, html) => {
  mkdirSync(dirname(file), { recursive: true });
  writeFileSync(file, html);
};
const page = (meta, body, prerenderedPath) =>
  template
    .replace(SEO_BLOCK, headHtml(meta))
    .replace('<div id="root"></div>', `<div id="root"${prerenderedPath ? ` data-prerendered="${prerenderedPath}"` : ''}>${body}</div>`);

// 1. Public pages: server-rendered HTML that hydrates in the browser.
const publicPaths = pages.filter((p) => p.index).map((p) => p.path).concat('/404');
for (const path of publicPaths) {
  const html = await render(path);
  write(out(path), page(metaFor(path), html, path));
  console.log(`prerender: ${path}`);
}

// 2. App routes: client-rendered, but each URL is a real file (200, own title, noindex).
for (const meta of pages.filter((p) => !p.index && p.path !== '/404' && p.path !== '/insights/task')) {
  write(out(meta.path), page(meta, '', null));
}

// 3. Redirects. Static hosts can't send 301s, so each old URL gets a page that
// search engines treat as a permanent redirect (canonical + instant refresh),
// and _redirects carries real 301s for hosts that support it (Netlify, Cloudflare Pages).
const base = Site.base.replace(/\/$/, '');
const target = (to) => (to.startsWith('http') ? to : `${Site.url}${to}`);
for (const [from, to] of redirects) {
  const url = target(to);
  write(
    out(from),
    `<!doctype html><html lang="en"><head><meta charset="utf-8"><title>Redirecting…</title>` +
      `<link rel="canonical" href="${url}"><meta name="robots" content="noindex"><meta http-equiv="refresh" content="0; url=${url}">` +
      `<script>location.replace(${JSON.stringify(url)})</script></head><body><a href="${url}">Continue to ${url}</a></body></html>`,
  );
}
writeFileSync(join(dist, '_redirects'), redirects.map(([from, to]) => `${base}${from} ${to.startsWith('http') ? to : base + to} 301`).join('\n') + '\n');

// 4. robots.txt + sitemap.xml (indexable pages only).
writeFileSync(
  join(dist, 'robots.txt'),
  ['User-agent: *', 'Allow: /', '', `Sitemap: ${Site.url}/sitemap.xml`, ''].join('\n'),
);
const today = new Date().toISOString().slice(0, 10);
const urls = pages
  .filter((p) => p.index)
  .map(
    (p) =>
      `  <url>\n    <loc>${Site.url}${p.path === '/' ? '/' : p.path}</loc>\n    <lastmod>${today}</lastmod>\n` +
      `    <changefreq>${p.changefreq ?? 'monthly'}</changefreq>\n    <priority>${(p.priority ?? 0.5).toFixed(1)}</priority>\n  </url>`,
  );
writeFileSync(join(dist, 'sitemap.xml'), `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${urls.join('\n')}\n</urlset>\n`);

rmSync(join(here, '../dist-ssr'), { recursive: true, force: true });
console.log(`prerender: done (${publicPaths.length} pages, ${redirects.length} redirects, sitemap + robots)`);
