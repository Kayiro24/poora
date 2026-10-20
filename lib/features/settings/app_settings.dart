import 'dart:convert';

import 'package:poora/features/focus/domain/timer_engine.dart';

enum Chime {
  bowl('Bowl', 'sounds/bowl.wav'),
  wood('Wood', 'sounds/wood.wav'),
  softBell('Soft bell', 'sounds/soft_bell.wav'),
  none('None', null);

  Chime(this.label, this.asset);
  final String label;
  final String? asset;
}

/// All user settings, persisted as key/value rows.
class AppSettings {
  const AppSettings({
    this.name = '',
    this.mondayFirst = true,
    this.defaultReminderMin = 10,
    this.use24h = false,
    this.showSeconds = true,
    this.showSubSeconds = false,
    this.autoStartBreaks = true,
    this.autoStartFocus = false,
    this.longPressToEnd = true,
    this.silencePhone = false,
    this.keepAwake = true,
    this.chime = Chime.bowl,
    this.haptics = true,
    this.lastFocus = const FocusConfig(),
    this.lastFocusAt,
    this.iosFocusTipShown = false,
    this.onboarded = false,
  });

  final String name;
  final bool mondayFirst;

  /// Minutes before start for new timed tasks; null = no default reminder.
  final int? defaultReminderMin;
  final bool use24h;

  // Focus display (§4.5). `showSubSeconds` is remembered even while seconds
  // are off; the running screen uses TimerFormat.effectiveSubSeconds.
  final bool showSeconds;
  final bool showSubSeconds;

  final bool autoStartBreaks;
  final bool autoStartFocus;
  final bool longPressToEnd;
  final bool silencePhone;
  final bool keepAwake;
  final Chime chime;
  final bool haptics;
  final FocusConfig lastFocus;
  final DateTime? lastFocusAt;
  final bool iosFocusTipShown;

  /// First-run welcome completed.
  final bool onboarded;

  AppSettings copyWith({
    String? name,
    bool? mondayFirst,
    Object? defaultReminderMin = _keep,
    bool? use24h,
    bool? showSeconds,
    bool? showSubSeconds,
    bool? autoStartBreaks,
    bool? autoStartFocus,
    bool? longPressToEnd,
    bool? silencePhone,
    bool? keepAwake,
    Chime? chime,
    bool? haptics,
    FocusConfig? lastFocus,
    DateTime? lastFocusAt,
    bool? iosFocusTipShown,
    bool? onboarded,
  }) => AppSettings(
    name: name ?? this.name,
    mondayFirst: mondayFirst ?? this.mondayFirst,
    defaultReminderMin: identical(defaultReminderMin, _keep)
        ? this.defaultReminderMin
        : defaultReminderMin as int?,
    use24h: use24h ?? this.use24h,
    showSeconds: showSeconds ?? this.showSeconds,
    showSubSeconds: showSubSeconds ?? this.showSubSeconds,
    autoStartBreaks: autoStartBreaks ?? this.autoStartBreaks,
    autoStartFocus: autoStartFocus ?? this.autoStartFocus,
    longPressToEnd: longPressToEnd ?? this.longPressToEnd,
    silencePhone: silencePhone ?? this.silencePhone,
    keepAwake: keepAwake ?? this.keepAwake,
    chime: chime ?? this.chime,
    haptics: haptics ?? this.haptics,
    lastFocus: lastFocus ?? this.lastFocus,
    lastFocusAt: lastFocusAt ?? this.lastFocusAt,
    iosFocusTipShown: iosFocusTipShown ?? this.iosFocusTipShown,
    onboarded: onboarded ?? this.onboarded,
  );

  Map<String, String> toMap() => {
    'name': name,
    'mondayFirst': '$mondayFirst',
    'defaultReminderMin': '${defaultReminderMin ?? ''}',
    'use24h': '$use24h',
    'showSeconds': '$showSeconds',
    'showSubSeconds': '$showSubSeconds',
    'autoStartBreaks': '$autoStartBreaks',
    'autoStartFocus': '$autoStartFocus',
    'longPressToEnd': '$longPressToEnd',
    'silencePhone': '$silencePhone',
    'keepAwake': '$keepAwake',
    'chime': chime.name,
    'haptics': '$haptics',
    'lastFocus': jsonEncode(lastFocus.toJson()),
    'lastFocusAt': '${lastFocusAt?.millisecondsSinceEpoch ?? ''}',
    'iosFocusTipShown': '$iosFocusTipShown',
    'onboarded': '$onboarded',
  };

  factory AppSettings.fromMap(Map<String, String> m) {
    const d = AppSettings();
    bool b(String k, bool def) => m[k] == null ? def : m[k] == 'true';
    final lastAt = int.tryParse(m['lastFocusAt'] ?? '');
    var focus = d.lastFocus;
    final rawFocus = m['lastFocus'];
    if (rawFocus != null && rawFocus.isNotEmpty) {
      try {
        focus = FocusConfig.fromJson(jsonDecode(rawFocus) as Map<String, Object?>);
      } on FormatException {
        focus = d.lastFocus;
      }
    }
    return AppSettings(
      name: m['name'] ?? d.name,
      mondayFirst: b('mondayFirst', d.mondayFirst),
      defaultReminderMin: m.containsKey('defaultReminderMin')
          ? int.tryParse(m['defaultReminderMin']!)
          : d.defaultReminderMin,
      use24h: b('use24h', d.use24h),
      showSeconds: b('showSeconds', d.showSeconds),
      showSubSeconds: b('showSubSeconds', d.showSubSeconds),
      autoStartBreaks: b('autoStartBreaks', d.autoStartBreaks),
      autoStartFocus: b('autoStartFocus', d.autoStartFocus),
      longPressToEnd: b('longPressToEnd', d.longPressToEnd),
      silencePhone: b('silencePhone', d.silencePhone),
      keepAwake: b('keepAwake', d.keepAwake),
      chime: Chime.values.asNameMap()[m['chime']] ?? d.chime,
      haptics: b('haptics', d.haptics),
      lastFocus: focus,
      lastFocusAt: lastAt == null ? null : DateTime.fromMillisecondsSinceEpoch(lastAt),
      iosFocusTipShown: b('iosFocusTipShown', d.iosFocusTipShown),
      onboarded: b('onboarded', d.onboarded),
    );
  }
}

const Object _keep = Object();
