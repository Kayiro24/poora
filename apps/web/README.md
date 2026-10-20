# Poora — website + web app

The public website (landing, privacy policy, contact) and the full Poora app for the browser,
with the same screens, design and behaviour as the Android app. React 19 · Vite 8 · TypeScript ·
Zustand · react-router 8 · recharts · rrule. Installable PWA that works offline.

```sh
npm run dev        # from apps/web (or `npm run web:dev` at the repo root)
npm run lint       # eslint + type-check
npm test           # domain parity + sync contract + SEO metadata
npm run build      # client build → SSR build → prerender (dist/)
```

Shared assets (fonts, mascots, chimes, logo) are copied from `apps/mobile/assets` by
`scripts/sync-assets.mjs` before `dev` and `build`, so there is one source of truth.

## How it's put together

- **Domain logic** (`src/features/*/domain`) is a line-for-line port of the app's Dart: occurrence
  generator, repeat rules, series edits, focus timer engine, metrics. Its tests use the same cases
  and expected values as the Dart tests.
- **Storage**: the app's database tables as rows, persisted to `localStorage`
  (`src/core/db/store.ts`). Export/import uses the app's exact JSON format — see
  `shared/export-format` and `src/features/settings/dataTransfer.test.ts`.
- **Browser limits** (documented in the UI): reminders fire while Poora is open in a tab or installed
  as an app; other apps can't be silenced from a browser (the Android app can).

## SEO

| Item | How |
|---|---|
| Server-side rendering | Public pages are **server-rendered at build time** (`src/entry-server.tsx` → `scripts/prerender.mjs`) to real HTML, then hydrated. Crawlers get full content without running JS, and Vercel serves the pages from its CDN. |
| Unique titles, meta descriptions | One table, `src/seo/site.ts`, drives the prerendered `<head>` and client navigation (`SeoSync`). A test enforces uniqueness. |
| One H1 per page | Every page and app screen has exactly one `<h1>`. |
| Canonical tags | Absolute canonical per page, from `VITE_SITE_URL` or, if unset, Vercel's production domain. |
| Open Graph / Twitter | Per-page 1200×630 cards in `public/og/` (regenerate: `python scripts/render_og.py`). |
| Structured data | `Organization` on every public page; `WebSite` + `SoftwareApplication` on home; `BreadcrumbList` on subpages. |
| Breadcrumbs | Visible breadcrumbs on subpages (Privacy, Contact) plus JSON-LD. |
| Internal links | Header nav, footer link groups, in-content links, sidebar links in the app. |
| robots.txt, sitemap.xml | Generated at build and served from the domain root. The sitemap lists indexable pages only. |
| Indexing | Public pages `index`; app screens (private, on-device data) `noindex`. |
| Custom 404 | `404.html` is a real page served with a 404 status. Dynamic app URLs (`/insights/task/:id`) are rewritten to the app in `vercel.json`. |
| 301 redirects | Real 301s from `vercel.json`. The list lives in `site.ts`, and a test keeps `vercel.json` identical. |
| Images | WebP screenshots with `srcset`, explicit width/height, `loading="lazy"` below the fold and descriptive `alt`. Decorative mascots use `alt=""`. |
| Lazy loading | App screens and charts are code-split per route; below-the-fold images load lazily. |
| Google Analytics | GA4 only when `VITE_GA_MEASUREMENT_ID` is set and only after the visitor clicks "Allow" (no script, no cookie before). IP anonymisation on; Google Signals and ad personalisation off. Page views only. |
| Search Console | Set `VITE_GSC_VERIFICATION`; after verifying, submit `sitemap.xml`. |
| Privacy policy | `/privacy`, matching how both apps actually behave (and whether analytics is enabled). |
| Contact form | Validated and accessible, with a honeypot. With `VITE_CONTACT_ENDPOINT` (a [Formspree](https://formspree.io) form URL) it posts the message; without one it opens a pre-filled GitHub issue. |

**Search Console steps:** add a *URL-prefix* property for your site URL → choose *HTML tag* →
put the `content` value in the Vercel env var `VITE_GSC_VERIFICATION` → redeploy → click *Verify* →
*Sitemaps* → submit `sitemap.xml`.

**Deploying:** Vercel, with Root Directory `apps/web` (see the root README). Preview deployments get
their own URLs for every pull request. Vercel marks preview deployments `noindex`, so only production is crawled.
