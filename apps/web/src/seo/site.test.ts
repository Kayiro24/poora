import { describe, expect, test } from 'vitest';
import { readFileSync } from 'node:fs';
import { headHtml, jsonLdFor, metaFor, pages, redirects, Site } from './site';

describe('SEO metadata', () => {
  test('every page has a unique title and description', () => {
    expect(new Set(pages.map((p) => p.title)).size).toBe(pages.length);
    expect(new Set(pages.map((p) => p.description)).size).toBe(pages.length);
  });

  test('dynamic routes use the longest matching prefix; unknown paths are 404', () => {
    expect(metaFor('/insights/task/abc').path).toBe('/insights/task');
    expect(metaFor('/insights/').path).toBe('/insights');
    expect(metaFor('/nope/deeper').path).toBe('/404');
  });

  test('public pages are indexable with canonical, OG and JSON-LD; app screens are noindex', () => {
    const privacy = headHtml(metaFor('/privacy'));
    expect(privacy).toContain(`rel="canonical" href="${Site.url}/privacy"`);
    expect(privacy).toContain(`og:image" content="${Site.url}/og/og-privacy.png"`);
    expect(privacy).toContain('"@type":"BreadcrumbList"');
    expect(headHtml(metaFor('/home'))).toContain('content="noindex, follow"');
    expect(jsonLdFor(metaFor('/')).map((x) => (x as { '@type': string })['@type'])).toEqual(['Organization', 'WebSite', 'SoftwareApplication']);
    expect(headHtml(metaFor('/404'))).not.toContain('rel="canonical"');
  });

  test('vercel.json serves exactly the redirects defined in site.ts, as 301s', () => {
    const vercel = JSON.parse(readFileSync(new URL('../../vercel.json', import.meta.url), 'utf8')) as {
      redirects: { source: string; destination: string; statusCode: number }[];
    };
    expect(vercel.redirects.map((r) => [r.source, r.destination])).toEqual(redirects);
    expect(vercel.redirects.every((r) => r.statusCode === 301)).toBe(true);
  });
});
