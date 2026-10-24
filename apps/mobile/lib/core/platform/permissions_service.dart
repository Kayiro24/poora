import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android's special permissions behind focus: each is switched on by the user
/// on a system screen (Poora can only open it), so they're listed up front at
/// first launch and again in Settings → Permissions.
enum SpecialPermission {
  /// Which app is in front during focus (blocking without Accessibility) and
  /// minutes in distracting apps.
  usage('usage', 'Usage access', 'See which app is open during focus, to block the ones you pick'),

  /// Lets the focus service put the block screen over a blocked app.
  overlay('overlay', 'Display over other apps', 'Show the block screen on top of a blocked app'),

  /// The focus guard: blocks instantly and keeps strict focus from being undone in Settings.
  accessibility('accessibility', 'Poora focus guard', 'Accessibility service: instant blocking and strict-mode protection'),

  /// Device admin: Android refuses to uninstall Poora while it's active.
  admin('admin', 'Uninstall protection', 'Poora can’t be uninstalled while strict focus runs'),

  /// Keeps the focus bar and guard alive in the background.
  battery('battery', 'Run in background', 'Battery unrestricted, so the focus bar and blocking never stop');

  SpecialPermission(this.key, this.title, this.why);
  final String key;
  final String title;
  final String why;
}

class PermissionsService {
  static const _channel = MethodChannel('poora/perms');

  bool get supported => !kIsWeb && Platform.isAndroid;

  /// Granted state of every special permission (all false off Android).
  Future<Map<SpecialPermission, bool>> status() async {
    if (!supported) return {for (final p in SpecialPermission.values) p: false};
    try {
      final m = await _channel.invokeMapMethod<String, bool>('status') ?? const {};
      return {for (final p in SpecialPermission.values) p: m[p.key] ?? false};
    } on PlatformException {
      return {for (final p in SpecialPermission.values) p: false};
    }
  }

  /// Opens the system screen where the user switches [p] on.
  Future<void> open(SpecialPermission p) => _open(p.key);

  /// App info — where Android 13+ hides "Allow restricted settings" (⋮ menu),
  /// needed before Accessibility can be turned on for an app installed from a file.
  Future<void> openAppInfo() => _open('appInfo');

  Future<void> _open(String which) async {
    if (!supported) return;
    try {
      await _channel.invokeMethod<void>('open', {'which': which});
    } on PlatformException {
      // Nothing to open.
    }
  }
}
