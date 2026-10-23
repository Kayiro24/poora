/// App identity. Change the name and taglines here only.
abstract final class AppInfo {
  static const name = 'Poora';

  /// "Poora" (पूरा) is Hindi for whole, complete, done.
  static const meaning = 'Poora (पूरा) — whole, complete, done.';

  /// Primary tagline: splash, onboarding, About, store listing.
  static const tagline = 'Make every day whole.';

  /// Secondary line used under the tagline.
  static const subline = 'Focus fully. Finish fully.';

  /// The focus promise: no leaderboards, no groups — only your own yesterday.
  static const motto = 'You versus you.';

  /// Injected by CI from the git tag (`--dart-define=APP_VERSION=1.2.0`);
  /// local builds show the pubspec version.
  static const version = String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');
}
