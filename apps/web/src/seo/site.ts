import { AppInfo } from '../core/appInfo';

/**
 * Public site configuration, from build-time env vars (set them in Vercel →
 * Settings → Environment Variables):
 *
 *   VITE_SITE_URL              absolute site root, no trailing slash
 *   VITE_GA_MEASUREMENT_ID     Google Analytics 4 ID (G-XXXX); analytics off when unset
 *   VITE_GSC_VERIFICATION      Search Console HTML-tag verification token
 *   VITE_CONTACT_ENDPOINT      Formspree-style form endpoint; falls back to GitHub issues
 */
export const Site = {
  url: (import.meta.env.VITE_SITE_URL ?? 'http://localhost:5173').replace(/\/$/, ''),
  base: import.meta.env.BASE_URL,
  repo: 'https://github.com/Kayiro24/poora',
  gaId: import.meta.env.VITE_GA_MEASUREMENT_ID as string | undefined,
  gscToken: import.meta.env.VITE_GSC_VERIFICATION as string | undefined,
  contactEndpoint: import.meta.env.VITE_CONTACT_ENDPOINT as string | undefined,
  locale: 'en_IN',
  twitter: undefined as string | undefined,
};

export const abs = (path: string) => `${Site.url}${path === '/' ? '/' : path}`;
export const asset = (path: string) => `${Site.url}/${path.replace(/^\//, '')}`;

export interface Crumb {
  name: string;
  path: string;
}

export interface PageMeta {
  path: string;
  title: string;
  description: string;
  /** Public pages are indexed; app screens hold on-device data and are not. */
  index: boolean;
  og?: string;
  crumbs?: Crumb[];
  /** Include in sitemap.xml (indexable pages only). */
  priority?: number;
  changefreq?: 'weekly' | 'monthly' | 'yearly';
}

const home: Crumb = { name: 'Home', path: '/' };
const suffix = ` · ${AppInfo.name}`;

/** Every route's metadata — the single source for <head>, the sitemap and prerendering. */
export const pages: PageMeta[] = [
  {
    path: '/',
    title: `${AppInfo.name} — Focus timer & daily planner. ${AppInfo.tagline}`,
    description:
      'Poora is a calm Pomodoro focus timer and day planner with calendar-style repeats and a completion calendar that shows each day come together. Free, offline, no account.',
    index: true,
    og: 'og/og-home.png',
    priority: 1,
    changefreq: 'monthly',
  },
  {
    path: '/privacy',
    title: `Privacy policy${suffix}`,
    description: 'How Poora handles your data: everything stays on your device, no account, no tracking without consent.',
    index: true,
    og: 'og/og-privacy.png',
    crumbs: [home, { name: 'Privacy policy', path: '/privacy' }],
    priority: 0.5,
    changefreq: 'yearly',
  },
  {
    path: '/contact',
    title: `Contact${suffix}`,
    description: 'Send feedback, report a bug or ask a question about Poora, the calm focus timer and day planner.',
    index: true,
    og: 'og/og-contact.png',
    crumbs: [home, { name: 'Contact', path: '/contact' }],
    priority: 0.6,
    changefreq: 'yearly',
  },
  { path: '/404', title: `Page not found${suffix}`, description: 'This page doesn’t exist. Head back to Poora.', index: false },
  // App screens (client-rendered, private data → noindex).
  { path: '/start', title: `${AppInfo.name} — ${AppInfo.tagline}`, description: 'Opening Poora.', index: false },
  { path: '/welcome', title: `Welcome${suffix}`, description: 'Get started with Poora.', index: false },
  { path: '/home', title: `Today${suffix}`, description: 'Your day at a glance.', index: false },
  { path: '/focus', title: `Focus${suffix}`, description: 'Start a calm focus session.', index: false },
  { path: '/focus/run', title: `Focusing…${suffix}`, description: 'Focus session in progress.', index: false },
  { path: '/focus/settings', title: `Focus settings${suffix}`, description: 'Timer display, quiet mode and chime.', index: false, crumbs: [{ name: 'Focus', path: '/focus' }, { name: 'Settings', path: '/focus/settings' }] },
  { path: '/focus/history', title: `Focus history${suffix}`, description: 'Daily and weekly focus, grouped by task.', index: false, crumbs: [{ name: 'Focus', path: '/focus' }, { name: 'History', path: '/focus/history' }] },
  { path: '/tasks', title: `Tasks${suffix}`, description: 'Plan your day.', index: false },
  { path: '/trash', title: `Trash${suffix}`, description: 'Deleted tasks, kept for 30 days.', index: false },
  { path: '/insights', title: `Insights${suffix}`, description: 'How your days are going.', index: false },
  { path: '/insights/calendar', title: `Completion calendar${suffix}`, description: 'Every day’s ring at a glance.', index: false, crumbs: [{ name: 'Insights', path: '/insights' }, { name: 'Calendar', path: '/insights/calendar' }] },
  { path: '/insights/task', title: `Recurring task${suffix}`, description: 'History of a recurring task.', index: false, crumbs: [{ name: 'Insights', path: '/insights' }, { name: 'Recurring task', path: '/insights' }] },
  { path: '/settings', title: `Settings${suffix}`, description: 'Poora settings.', index: false },
];

/** Metadata for a pathname (dynamic routes match by prefix). */
export function metaFor(pathname: string): PageMeta {
  const p = pathname.replace(/\/+$/, '') || '/';
  const exact = pages.find((m) => m.path === p);
  if (exact) return exact;
  // Dynamic routes: the longest matching prefix wins (/insights/task/x → /insights/task).
  const prefix = pages
    .filter((m) => m.path !== '/' && p.startsWith(`${m.path}/`))
    .sort((a, b) => b.path.length - a.path.length)[0];
  return prefix ?? pages.find((m) => m.path === '/404')!;
}

/**
 * Permanent redirects (old/alternate URLs → canonical ones). Vercel serves
 * these as real 301s from vercel.json — a test keeps the two lists identical.
 */
export const redirects: [from: string, to: string][] = [
  ['/app', '/start'],
  ['/open', '/start'],
  ['/privacy-policy', '/privacy'],
  ['/contact-us', '/contact'],
  ['/calendar', '/insights/calendar'],
  ['/download', 'https://github.com/Kayiro24/poora/releases/latest'],
];

// ---------------------------------------------------------------- Structured data

export function organizationLd() {
  return {
    '@context': 'https://schema.org',
    '@type': 'Organization',
    name: AppInfo.name,
    url: abs('/'),
    logo: asset('assets/branding/web_512.png'),
    sameAs: [Site.repo],
    contactPoint: { '@type': 'ContactPoint', contactType: 'customer support', url: abs('/contact') },
  };
}

export function websiteLd() {
  return { '@context': 'https://schema.org', '@type': 'WebSite', name: AppInfo.name, url: abs('/'), description: AppInfo.tagline };
}

export function softwareLd() {
  return {
    '@context': 'https://schema.org',
    '@type': 'SoftwareApplication',
    name: AppInfo.name,
    applicationCategory: 'ProductivityApplication',
    operatingSystem: 'Android, Web',
    description: pages[0].description,
    url: abs('/'),
    downloadUrl: `${Site.repo}/releases/latest`,
    offers: { '@type': 'Offer', price: '0', priceCurrency: 'USD' },
    publisher: { '@type': 'Organization', name: AppInfo.name, url: abs('/') },
  };
}

export function breadcrumbLd(crumbs: Crumb[]) {
  return {
    '@context': 'https://schema.org',
    '@type': 'BreadcrumbList',
    itemListElement: crumbs.map((c, i) => ({ '@type': 'ListItem', position: i + 1, name: c.name, item: abs(c.path) })),
  };
}

export function jsonLdFor(meta: PageMeta): object[] {
  if (!meta.index) return [];
  const out: object[] = [organizationLd()];
  if (meta.path === '/') out.push(websiteLd(), softwareLd());
  if (meta.crumbs) out.push(breadcrumbLd(meta.crumbs));
  return out;
}

const esc = (s: string) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

/** Head tags for a page, as HTML — used by the prerenderer. */
export function headHtml(meta: PageMeta, canonicalPath = meta.path): string {
  const url = abs(canonicalPath);
  const og = asset(meta.og ?? 'og/og-home.png');
  const tags = [
    `<title>${esc(meta.title)}</title>`,
    `<meta name="description" content="${esc(meta.description)}" />`,
    `<meta name="robots" content="${meta.index ? 'index, follow' : 'noindex, follow'}" />`,
    meta.path === '/404' ? '' : `<link rel="canonical" href="${url}" />`,
    `<meta property="og:type" content="website" />`,
    `<meta property="og:site_name" content="${AppInfo.name}" />`,
    `<meta property="og:locale" content="${Site.locale}" />`,
    `<meta property="og:title" content="${esc(meta.title)}" />`,
    `<meta property="og:description" content="${esc(meta.description)}" />`,
    `<meta property="og:url" content="${url}" />`,
    `<meta property="og:image" content="${og}" />`,
    `<meta property="og:image:width" content="1200" />`,
    `<meta property="og:image:height" content="630" />`,
    `<meta property="og:image:alt" content="${esc(`${AppInfo.name} — ${AppInfo.tagline}`)}" />`,
    `<meta name="twitter:card" content="summary_large_image" />`,
    `<meta name="twitter:title" content="${esc(meta.title)}" />`,
    `<meta name="twitter:description" content="${esc(meta.description)}" />`,
    `<meta name="twitter:image" content="${og}" />`,
    Site.gscToken ? `<meta name="google-site-verification" content="${esc(Site.gscToken)}" />` : '',
    ...jsonLdFor(meta).map((ld) => `<script type="application/ld+json">${JSON.stringify(ld).replace(/</g, '\\u003c')}</script>`),
  ];
  return tags.filter(Boolean).join('\n    ');
}
