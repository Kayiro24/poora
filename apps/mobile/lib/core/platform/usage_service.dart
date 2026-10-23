import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class InstalledApp {
  const InstalledApp({required this.package, required this.label, this.icon});
  final String package;
  final String label;
  final Uint8List? icon;
}

/// Optional distracting-app detection (Android "Usage access"). Every call
/// degrades gracefully: unsupported platform, missing permission or a
/// platform error simply yields "no data", never an exception.
class UsageService {
  static const _channel = MethodChannel('poora/usage');

  bool get supported => !kIsWeb && Platform.isAndroid;

  Future<bool> hasAccess() async {
    if (!supported) return false;
    try {
      return await _channel.invokeMethod<bool>('hasAccess') ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Opens Settings → Usage access; the user flips Poora on there.
  Future<void> requestAccess() async {
    if (supported) await _channel.invokeMethod<void>('requestAccess');
  }

  Future<List<InstalledApp>> launchableApps() async {
    if (!supported) return const [];
    try {
      final raw = await _channel.invokeListMethod<Map<Object?, Object?>>('launchableApps') ?? const [];
      return [
        for (final m in raw)
          InstalledApp(package: m['package']! as String, label: m['label']! as String, icon: m['icon'] as Uint8List?),
      ];
    } on PlatformException {
      return const [];
    }
  }

  /// Milliseconds each of [packages] was in the foreground in [from, to].
  Future<Map<String, int>> usage({required DateTime from, required DateTime to, required Set<String> packages}) async {
    if (!supported || packages.isEmpty || !to.isAfter(from)) return const {};
    try {
      final raw = await _channel.invokeMapMethod<String, Object?>('usage', {
        'from': from.millisecondsSinceEpoch,
        'to': to.millisecondsSinceEpoch,
        'packages': packages.toList(),
      });
      return {for (final e in (raw ?? const {}).entries) e.key: (e.value! as num).toInt()};
    } on PlatformException {
      return const {};
    }
  }
}
