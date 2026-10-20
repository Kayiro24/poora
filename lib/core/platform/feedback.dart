import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:poora/features/settings/app_settings.dart';

/// Haptics and the session-end chime, honouring user settings (§2.7).
class AppFeedback {
  AppFeedback(this._settings);

  final AppSettings Function() _settings;
  AudioPlayer? _player;

  void light() {
    if (_settings().haptics) HapticFeedback.lightImpact();
  }

  void selection() {
    if (_settings().haptics) HapticFeedback.selectionClick();
  }

  void success() {
    if (_settings().haptics) HapticFeedback.mediumImpact();
  }

  Future<void> chime([Chime? override]) async {
    final asset = (override ?? _settings().chime).asset;
    if (asset == null) return;
    try {
      final player = _player ??= AudioPlayer();
      await player.setPlayerMode(PlayerMode.lowLatency);
      await player.stop();
      await player.play(AssetSource(asset));
    } on Object {
      // Audio is a nicety; never let it break the session flow.
    }
  }
}
