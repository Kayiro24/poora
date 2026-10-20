import { useEffect } from 'react';
import { useLocation } from 'react-router';
import { abs, asset, metaFor } from './site';
import { trackPageView } from './analytics';

function setMeta(attr: 'name' | 'property', key: string, content: string) {
  let el = document.head.querySelector<HTMLMetaElement>(`meta[${attr}="${key}"]`);
  if (!el) {
    el = document.createElement('meta');
    el.setAttribute(attr, key);
    document.head.appendChild(el);
  }
  el.content = content;
}

/**
 * Keeps <head> in sync on client-side navigation: unique title, description,
 * canonical, robots and Open Graph per route. Prerendered pages already ship
 * the same tags in their HTML (see scripts/prerender.mjs).
 */
export function SeoSync() {
  const { pathname } = useLocation();
  useEffect(() => {
    const base = import.meta.env.BASE_URL.replace(/\/$/, '');
    const path = pathname.startsWith(base) ? pathname.slice(base.length) || '/' : pathname;
    const m = metaFor(path);
    document.title = m.title;
    setMeta('name', 'description', m.description);
    setMeta('name', 'robots', m.index ? 'index, follow' : 'noindex, follow');
    setMeta('property', 'og:title', m.title);
    setMeta('property', 'og:description', m.description);
    setMeta('property', 'og:url', abs(path));
    setMeta('property', 'og:image', asset(m.og ?? 'og/og-home.png'));
    let link = document.head.querySelector<HTMLLinkElement>('link[rel="canonical"]');
    if (!link) {
      link = document.createElement('link');
      link.rel = 'canonical';
      document.head.appendChild(link);
    }
    link.href = abs(path);
    trackPageView(path, m.title);
  }, [pathname]);
  return null;
}
