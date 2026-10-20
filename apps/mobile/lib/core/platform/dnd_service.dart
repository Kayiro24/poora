import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android Do Not Disturb via the "poora/dnd" channel in MainActivity.
///
/// iOS has no API for this — there the app only shows a Focus-mode tip.
class DndService {
  static const _channel = MethodChannel('poora/dnd');

  /// NotificationManager.INTERRUPTION_FILTER_PRIORITY.
  static const filterPriority = 2;

  bool get supported => !kIsWeb && Platform.isAndroid;

  Future<bool> hasAccess() async {
    if (!supported) return false;
    return await _channel.invokeMethod<bool>('hasAccess') ?? false;
  }

  /// Opens the system "Do Not Disturb access" screen.
  Future<void> requestAccess() async {
    if (supported) await _channel.invokeMethod<void>('requestAccess');
  }

  Future<int?> currentFilter() async {
    if (!supported) return null;
    return _channel.invokeMethod<int>('getFilter');
  }

  Future<bool> setFilter(int filter) async {
    if (!supported) return false;
    return await _channel.invokeMethod<bool>('setFilter', {'filter': filter}) ??
        false;
  }
}
