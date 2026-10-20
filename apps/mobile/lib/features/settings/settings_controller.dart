import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poora/core/providers.dart';
import 'package:poora/features/settings/app_settings.dart';

/// Loaded before `runApp` and injected via override, so the first frame
/// already has the user's settings.
final initialSettingsProvider = Provider<AppSettings>(
  (ref) => const AppSettings(),
);

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(initialSettingsProvider);

  /// Back to defaults in memory only — for after the settings table was wiped.
  void reset() => state = const AppSettings();

  Future<void> update(AppSettings Function(AppSettings s) change) async {
    final before = state.toMap();
    state = change(state);
    final dao = ref.read(settingsDaoProvider);
    for (final e in state.toMap().entries) {
      if (before[e.key] != e.value) await dao.set(e.key, e.value);
    }
  }
}
