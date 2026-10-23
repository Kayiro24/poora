import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android focus guard (an Accessibility service): blocks chosen apps during
/// focus and, in strict mode, keeps Poora from being uninstalled until the
/// focus phase ends. Every call degrades gracefully — unsupported platform,
/// service off or a platform error means "no guard", never an exception.
class GuardService {
  static const _channel = MethodChannel('poora/guard');

  bool get supported => !kIsWeb && Platform.isAndroid;

  Future<bool> isEnabled() async {
    if (!supported) return false;
    try {
      return await _channel.invokeMethod<bool>('isEnabled') ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Opens Settings → Accessibility; the user turns on "Poora focus guard".
  Future<void> openSettings() async {
    if (!supported) return;
    try {
      await _channel.invokeMethod<void>('openSettings');
    } on PlatformException {
      // Nothing to open.
    }
  }

  /// Enforces until [until] (the end of the running focus phase), so the
  /// guard lapses on its own even if Poora is killed.
  Future<void> arm({required DateTime until, required bool strict, required List<String> blocked}) async {
    if (!supported) return;
    try {
      await _channel.invokeMethod<void>('arm', {'until': until.millisecondsSinceEpoch, 'strict': strict, 'blocked': blocked});
    } on PlatformException {
      // Guard unavailable; focus still runs.
    }
  }

  Future<void> clear() async {
    if (!supported) return;
    try {
      await _channel.invokeMethod<void>('clear');
    } on PlatformException {
      // Nothing armed.
    }
  }
}
