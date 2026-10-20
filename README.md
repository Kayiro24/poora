<p align="center"><img src="apps/mobile/assets/branding/icon_1024.png" width="112" alt="Poora logo: a P whose bowl is a closed completion ring"></p>

# Poora

**Make every day whole.** *Focus fully. Finish fully.*

Poora (पूरा, "whole, complete, done") is a calm focus timer and daily planner: a distraction-free
Pomodoro timer, a calendar-style task planner, and insights with a completion calendar where each
day's ring closes as you finish. Offline-first, no account.

| | Where | Built with |
|---|---|---|
| **Android app** (iOS-ready) | [`apps/mobile`](apps/mobile) | Flutter 3.47, Drift (SQLite), Riverpod |
| **Website + web app** | [`apps/web`](apps/web) | React 19, Vite 8, TypeScript, prerendered for SEO |
| **Shared export format** | [`shared/export-format`](shared/export-format) | JSON spec + contract sample |

Both apps have the same screens, design and behaviour. Recurrence, the focus timer and every insight
metric are tested against the **same expected values** on both sides.

## Moving data between phone and web

There's no cloud: data stays on each device. To move it, use **Settings → Export data** on one side
and **Settings → Import data** on the other — the file format is identical, in both directions. The
contract is [`shared/export-format/sample-v1.json`](shared/export-format/sample-v1.json), which both
test suites import and re-export unchanged.

## Repository layout

```
apps/mobile/            Flutter app (Android + iOS)
apps/web/               React website + web app (PWA)
shared/export-format/   Export file spec + sample used by both test suites
.github/workflows/      mobile-ci · mobile-release · web-ci · web-deploy
package.json            npm workspaces root (web)
```

## Quick start

```sh
# Web (Node 22.22+)
npm install
npm run web:dev            # http://localhost:5173
npm run web:test
npm run web:build          # prerendered site in apps/web/dist

# Mobile (Flutter 3.47)
cd apps/mobile
flutter pub get
dart run build_runner build
flutter run
```

## How the repo is run

| What | Runs on | Triggered by |
|---|---|---|
| Mobile checks (`mobile-ci.yml`) | GitHub Actions | push/PR touching `apps/mobile` or `shared` |
| Android release (`mobile-release.yml`) | GitHub Actions → GitHub Releases | pushing a tag `v1.2.3` |
| Web checks (`web-ci.yml`) | GitHub Actions | push/PR touching `apps/web`, `shared` or `apps/mobile/assets` |
| Website + web app | **Vercel** | every push (production on `main`, previews on PRs) |

**Android → GitHub Releases.** `git tag v1.0.1 && git push origin v1.0.1`. Needs four repository
secrets: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`,
`ANDROID_KEY_PASSWORD` (see [apps/mobile/README.md](apps/mobile/README.md)).

**Web → Vercel** (one-time setup):
1. vercel.com → *Add New → Project* → import this GitHub repo.
2. **Root Directory: `apps/web`**. Leave "Include files outside the root directory" **on**: the build
   reads shared fonts and logos from `apps/mobile/assets`.
3. Framework, install and build commands come from [`apps/web/vercel.json`](apps/web/vercel.json); don't override them.
4. Optional *Environment Variables* (Production):

   | Variable | Turns on |
   |---|---|
   | `VITE_SITE_URL` | Your custom domain, e.g. `https://poora.app` (default: the project's `*.vercel.app` domain) |
   | `VITE_GA_MEASUREMENT_ID` | Google Analytics 4 (consent banner first; nothing loads until "Allow") |
   | `VITE_GSC_VERIFICATION` | Google Search Console "HTML tag" verification |
   | `VITE_CONTACT_ENDPOINT` | Contact form posts to your Formspree form; without it, it opens a pre-filled GitHub issue |

5. Deploy. Commits that only touch the mobile app skip the web build (`ignoreCommand`).

**Protect `main`** (Settings → Rules → New ruleset → target `main`): require a pull request and
these status checks: `Mobile CI / check`, `Web CI / check`, and the Vercel deployment.

See [apps/web/README.md](apps/web/README.md) for the SEO setup.

## Licence

Not chosen yet — add a `LICENSE` file before inviting contributions.
