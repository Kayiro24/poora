import { create } from 'zustand';
import { Site } from './site';

/*
 * Google Analytics 4, consent-first: nothing loads and no cookie is set until
 * the visitor accepts in the consent banner, and only when a measurement ID
 * is configured (VITE_GA_MEASUREMENT_ID). IP anonymisation and Google Signals
 * off; your task data is never sent — only page views.
 */

type Consent = 'granted' | 'denied' | null;
const KEY = 'poora:analytics-consent';

const read = (): Consent => {
  try {
    const v = localStorage.getItem(KEY);
    return v === 'granted' || v === 'denied' ? v : null;
  } catch {
    return null;
  }
};

export const useConsent = create<{ consent: Consent }>(() => ({ consent: typeof window === 'undefined' ? null : read() }));

declare global {
  interface Window {
    dataLayer?: unknown[];
    gtag?: (...args: unknown[]) => void;
  }
}

let loaded = false;

function load() {
  if (loaded || !Site.gaId || typeof document === 'undefined') return;
  loaded = true;
  window.dataLayer = window.dataLayer ?? [];
  window.gtag = function gtag() {
    // eslint-disable-next-line prefer-rest-params
    window.dataLayer!.push(arguments);
  };
  window.gtag('js', new Date());
  window.gtag('config', Site.gaId, { send_page_view: false, anonymize_ip: true, allow_google_signals: false, allow_ad_personalization_signals: false });
  const s = document.createElement('script');
  s.async = true;
  s.src = `https://www.googletagmanager.com/gtag/js?id=${encodeURIComponent(Site.gaId)}`;
  document.head.appendChild(s);
}

export const Analytics = {
  enabled: () => !!Site.gaId,
  set(consent: 'granted' | 'denied') {
    try {
      localStorage.setItem(KEY, consent);
    } catch {
      /* private mode: remember for this session only */
    }
    useConsent.setState({ consent });
    if (consent === 'granted') {
      load();
      trackPageView(location.pathname, document.title);
    }
  },
  /** Called once at startup: load GA only if consent was given before. */
  init() {
    if (useConsent.getState().consent === 'granted') load();
  },
};

export function trackPageView(path: string, title: string) {
  if (!loaded || !window.gtag) return;
  window.gtag('event', 'page_view', { page_path: path, page_title: title, page_location: location.href });
}
