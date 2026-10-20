import { StrictMode } from 'react';
import { createRoot, hydrateRoot } from 'react-dom/client';
import { RouterProvider } from 'react-router';
import { registerSW } from 'virtual:pwa-register';
import { router } from './app/router';
import { OverlayHost } from './core/widgets/overlays';
import { Analytics } from './seo/analytics';
import './styles/global.css';

// Offline + installable; updates apply on the next load.
registerSW({ immediate: true });
Analytics.init();

const container = document.getElementById('root')!;
const app = (
  <StrictMode>
    <RouterProvider router={router} />
    <OverlayHost />
  </StrictMode>
);

// Prerendered public pages hydrate; everything else (app screens, or a URL
// that landed on 404.html) renders fresh.
const base = import.meta.env.BASE_URL.replace(/\/$/, '');
const path = location.pathname.slice(base.length).replace(/\/+$/, '') || '/';
if (container.dataset.prerendered === path) {
  hydrateRoot(container, app);
} else {
  container.replaceChildren();
  createRoot(container).render(app);
}
