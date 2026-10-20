import react from '@vitejs/plugin-react';
import { defineConfig } from 'vitest/config';
import { VitePWA } from 'vite-plugin-pwa';

// Served from the domain root on Vercel; BASE_PATH supports sub-path hosting if ever needed.
const base = process.env.BASE_PATH ?? '/';
// Canonical site URL: explicit VITE_SITE_URL, else Vercel's production domain
// (set automatically at build time), else local dev.
const siteUrl =
  process.env.VITE_SITE_URL ??
  (process.env.VERCEL_PROJECT_PRODUCTION_URL ? `https://${process.env.VERCEL_PROJECT_PRODUCTION_URL}` : 'http://localhost:5173');

export default defineConfig(({ isSsrBuild }) => ({
  base,
  define: {
    __BUILD_YEAR__: JSON.stringify(String(new Date().getFullYear())),
    'import.meta.env.VITE_SITE_URL': JSON.stringify(siteUrl),
  },
  plugins: [
    react(),
    VitePWA({
      // The SSR (prerender) build must not emit a service worker.
      disable: !!isSsrBuild,
      registerType: 'autoUpdate',
      includeAssets: ['assets/branding/favicon.svg', 'assets/branding/apple_touch_180.png'],
      manifest: {
        name: 'Poora',
        short_name: 'Poora',
        description: 'Make every day whole. A calm focus timer and daily planner.',
        theme_color: '#161616',
        background_color: '#161616',
        display: 'standalone',
        orientation: 'any',
        // Installed app opens straight into the app, not the landing page.
        start_url: `${base}start`,
        scope: base,
        icons: [
          { src: 'assets/branding/web_192.png', sizes: '192x192', type: 'image/png' },
          { src: 'assets/branding/web_512.png', sizes: '512x512', type: 'image/png' },
          { src: 'assets/branding/web_maskable_512.png', sizes: '512x512', type: 'image/png', purpose: 'maskable' },
        ],
      },
      workbox: {
        globPatterns: ['**/*.{js,css,html,svg,png,webp,ttf,wav,webmanifest}'],
        maximumFileSizeToCacheInBytes: 4 * 1024 * 1024,
        // Offline, any route falls back to index.html, which boots the full app and routes client-side.
        navigateFallback: `${base}index.html`,
      },
    }),
  ],
  test: {
    environment: 'node',
    include: ['src/**/*.test.ts'],
  },
}));
