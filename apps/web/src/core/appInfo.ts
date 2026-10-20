/** App identity — mirrors apps/mobile/lib/core/app_info.dart. */
export const AppInfo = {
  name: 'Poora',
  meaning: 'Poora (पूरा) — whole, complete, done.',
  tagline: 'Make every day whole.',
  subline: 'Focus fully. Finish fully.',
  version: import.meta.env.VITE_APP_VERSION ?? '1.0.0',
  /** Where the Android app is published (GitHub Releases). */
  androidUrl: 'https://github.com/Kayiro24/poora/releases/latest',
} as const;
