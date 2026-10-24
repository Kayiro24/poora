import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// What the always-on focus bar notification shows (Android). The native
/// service adds live focus time itself, so it stays right with Poora closed.
class FocusBarData {
  const FocusBarData({
    required this.enabled,
    required this.goalMin,
    required this.mondayFirst,
    required this.streak,
    required this.minutesByDay,
    this.liveFocusMs = 0,
    this.liveSince,
    this.liveCapMs,
    this.liveEndsAt,
    this.strict = false,
  });

  final bool enabled;
  final int goalMin;
  final bool mondayFirst;
  final int streak;

  /// Finished focus minutes per local day, `YYYY-MM-DD`.
  final Map<String, double> minutesByDay;

  /// Live session: focus ms so far, the instant it started counting (null while
  /// paused or on a break), the most it can reach, and the phase end.
  final int liveFocusMs;
  final DateTime? liveSince;
  final int? liveCapMs;
  final DateTime? liveEndsAt;
  final bool strict;

  bool get hasLive => liveSince != null || liveFocusMs > 0 || liveEndsAt != null;

  String encode() => jsonEncode({
    'goalMin': goalMin,
    'mondayFirst': mondayFirst,
    'streak': streak,
    'days': minutesByDay,
    if (hasLive)
      'live': {
        'focusMs': liveFocusMs,
        'since': liveSince?.millisecondsSinceEpoch ?? 0,
        'capMs': ?liveCapMs,
        'endsAt': liveEndsAt?.millisecondsSinceEpoch ?? 0,
        'strict': strict,
      },
  });
}

class FocusBarService {
  static const _channel = MethodChannel('poora/focusbar');

  bool get supported => !kIsWeb && Platform.isAndroid;

  Future<void> update(FocusBarData d) async {
    if (!supported) return;
    try {
      await _channel.invokeMethod<bool>('update', {'enabled': d.enabled, 'data': d.encode()});
    } on PlatformException {
      // The bar is a nicety; focus works without it.
    }
  }
}
