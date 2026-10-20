import 'package:poora/core/time/date_utils.dart';
import 'package:poora/features/tasks/domain/models.dart';

enum Freq { daily, weekly, monthly, yearly }

enum MonthlyMode { dayOfMonth, nthWeekday, lastWeekday }

const _rruleDays = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
const weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const weekdayLong = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const monthLong = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
const _ordinals = ['first', 'second', 'third', 'fourth', 'fifth'];

/// Editable repeat rule (§4.8). Serialises fixed rules to RFC 5545 RRULE
/// bodies; "times per week" is a separate quota kind.
class RepeatRule {
  const RepeatRule({
    this.kind = RepeatKind.none,
    this.freq = Freq.daily,
    this.interval = 1,
    this.weekdays = const {},
    this.monthlyMode = MonthlyMode.dayOfMonth,
    this.quota = 3,
    this.preferredDays = const {},
    this.endsOn,
    this.endsAfter,
  });

  static const none = RepeatRule();

  final RepeatKind kind;
  final Freq freq;
  final int interval;

  /// ISO weekdays 1..7 (weekly rules).
  final Set<int> weekdays;
  final MonthlyMode monthlyMode;
  final int quota;
  final Set<int> preferredDays;
  final DateTime? endsOn;
  final int? endsAfter;

  // --- Quick options ------------------------------------------------------

  static RepeatRule daily() =>
      const RepeatRule(kind: RepeatKind.rrule);
  static RepeatRule everyOtherDay() =>
      const RepeatRule(kind: RepeatKind.rrule, interval: 2);
  static RepeatRule weekdaysOnly() => const RepeatRule(
    kind: RepeatKind.rrule,
    freq: Freq.weekly,
    weekdays: {1, 2, 3, 4, 5},
  );
  static RepeatRule weeklyOn(DateTime start) => RepeatRule(
    kind: RepeatKind.rrule,
    freq: Freq.weekly,
    weekdays: {start.weekday},
  );
  static RepeatRule monthlyOnDay() =>
      const RepeatRule(kind: RepeatKind.rrule, freq: Freq.monthly);
  static RepeatRule yearly() =>
      const RepeatRule(kind: RepeatKind.rrule, freq: Freq.yearly);
  static RepeatRule timesPerWeek(int n) =>
      RepeatRule(kind: RepeatKind.quota, quota: n);

  RepeatRule copyWith({
    RepeatKind? kind,
    Freq? freq,
    int? interval,
    Set<int>? weekdays,
    MonthlyMode? monthlyMode,
    int? quota,
    Set<int>? preferredDays,
    Object? endsOn = _keep,
    Object? endsAfter = _keep,
  }) => RepeatRule(
    kind: kind ?? this.kind,
    freq: freq ?? this.freq,
    interval: interval ?? this.interval,
    weekdays: weekdays ?? this.weekdays,
    monthlyMode: monthlyMode ?? this.monthlyMode,
    quota: quota ?? this.quota,
    preferredDays: preferredDays ?? this.preferredDays,
    endsOn: identical(endsOn, _keep) ? this.endsOn : endsOn as DateTime?,
    endsAfter: identical(endsAfter, _keep) ? this.endsAfter : endsAfter as int?,
  );

  // --- Serialisation ------------------------------------------------------

  /// RRULE body for a series starting on [start]. Month day / weekday parts
  /// are always explicit so the rule never depends on DTSTART defaults.
  String? toRRule(DateTime start) {
    if (kind != RepeatKind.rrule) return null;
    final parts = <String>['FREQ=${freq.name.toUpperCase()}'];
    if (interval > 1) parts.add('INTERVAL=$interval');
    switch (freq) {
      case Freq.daily:
        break;
      case Freq.weekly:
        final days = (weekdays.isEmpty ? {start.weekday} : weekdays).toList()
          ..sort();
        parts.add('BYDAY=${days.map((d) => _rruleDays[d - 1]).join(',')}');
      case Freq.monthly:
        switch (monthlyMode) {
          case MonthlyMode.dayOfMonth:
            parts.add('BYMONTHDAY=${start.day}');
          case MonthlyMode.nthWeekday:
            parts.add('BYDAY=${nthOfMonth(start)}${_rruleDays[start.weekday - 1]}');
          case MonthlyMode.lastWeekday:
            parts.add('BYDAY=-1${_rruleDays[start.weekday - 1]}');
        }
      case Freq.yearly:
        parts
          ..add('BYMONTH=${start.month}')
          ..add('BYMONTHDAY=${start.day}');
    }
    return parts.join(';');
  }

  /// Reconstructs the editable rule from a stored task.
  factory RepeatRule.fromTask(Task t) {
    switch (t.repeatKind) {
      case RepeatKind.none:
        return RepeatRule.none;
      case RepeatKind.quota:
        return RepeatRule(
          kind: RepeatKind.quota,
          quota: t.quotaPerWeek ?? 3,
          preferredDays: t.quotaPreferredDays.toSet(),
          endsOn: t.endsOn,
        );
      case RepeatKind.rrule:
        final map = parseRRule(t.rrule ?? 'FREQ=DAILY');
        final freq = Freq.values.firstWhere(
          (f) => f.name.toUpperCase() == map['FREQ'],
          orElse: () => Freq.daily,
        );
        var weekdays = <int>{};
        var mode = MonthlyMode.dayOfMonth;
        final byDay = map['BYDAY'];
        if (byDay != null) {
          if (freq == Freq.monthly) {
            mode = byDay.startsWith('-1')
                ? MonthlyMode.lastWeekday
                : MonthlyMode.nthWeekday;
          } else {
            weekdays = byDay
                .split(',')
                .map((d) => _rruleDays.indexOf(d.replaceAll(RegExp('[-0-9]'), '')) + 1)
                .where((d) => d > 0)
                .toSet();
          }
        }
        return RepeatRule(
          kind: RepeatKind.rrule,
          freq: freq,
          interval: int.tryParse(map['INTERVAL'] ?? '1') ?? 1,
          weekdays: weekdays,
          monthlyMode: mode,
          endsOn: t.endsOn,
          endsAfter: t.endsAfterCount,
        );
    }
  }

  static Map<String, String> parseRRule(String body) {
    final map = <String, String>{};
    for (final part in body.replaceFirst('RRULE:', '').split(';')) {
      final i = part.indexOf('=');
      if (i > 0) map[part.substring(0, i).toUpperCase()] = part.substring(i + 1);
    }
    return map;
  }

  /// 1-based week-of-month ordinal of [d]'s weekday (third Monday → 3).
  static int nthOfMonth(DateTime d) => ((d.day - 1) ~/ 7) + 1;

  // --- Human summary ------------------------------------------------------

  String summary(DateTime start) {
    final base = _baseSummary(start);
    if (kind == RepeatKind.none) return base;
    final end = endsOn;
    if (end != null) {
      return '$base, until ${monthLong[end.month - 1].substring(0, 3)} '
          '${end.day}, ${end.year}';
    }
    if (endsAfter != null) return '$base, $endsAfter times';
    return base;
  }

  String _baseSummary(DateTime start) {
    switch (kind) {
      case RepeatKind.none:
        return 'Does not repeat';
      case RepeatKind.quota:
        return quota == 1 ? 'Once a week' : '$quota times a week';
      case RepeatKind.rrule:
        break;
    }
    final n = interval;
    switch (freq) {
      case Freq.daily:
        return n == 1 ? 'Every day' : 'Every $n days';
      case Freq.weekly:
        final days = (weekdays.isEmpty ? {start.weekday} : weekdays).toList()
          ..sort();
        if (n == 1 && days.length == 5 && days.every((d) => d <= 5)) {
          return 'Every weekday';
        }
        if (n == 1 && days.length == 7) return 'Every day';
        final names = days.map((d) => weekdayShort[d - 1]).join(', ');
        return n == 1 ? 'Weekly on $names' : 'Every $n weeks on $names';
      case Freq.monthly:
        final prefix = n == 1 ? 'Monthly' : 'Every $n months';
        switch (monthlyMode) {
          case MonthlyMode.dayOfMonth:
            return '$prefix on day ${start.day}';
          case MonthlyMode.nthWeekday:
            final nth = nthOfMonth(start);
            return '$prefix on the ${_ordinals[nth - 1]} '
                '${weekdayLong[start.weekday - 1]}';
          case MonthlyMode.lastWeekday:
            return '$prefix on the last ${weekdayLong[start.weekday - 1]}';
        }
      case Freq.yearly:
        final date = '${monthLong[start.month - 1]} ${start.day}';
        return n == 1 ? 'Annually on $date' : 'Every $n years on $date';
    }
  }

  /// Writes this rule's fields onto [t] (for the given start date).
  Task applyTo(Task t) => t.copyWith(
    repeatKind: kind,
    rrule: toRRule(t.startDate),
    quotaPerWeek: kind == RepeatKind.quota ? quota : null,
    quotaPreferredDays: kind == RepeatKind.quota
        ? (preferredDays.toList()..sort())
        : const [],
    endsOn: kind == RepeatKind.none ? null : endsOn,
    endsAfterCount: kind == RepeatKind.rrule ? endsAfter : null,
  );

  @override
  bool operator ==(Object other) =>
      other is RepeatRule &&
      other.kind == kind &&
      other.freq == freq &&
      other.interval == interval &&
      _setEq(other.weekdays, weekdays) &&
      other.monthlyMode == monthlyMode &&
      other.quota == quota &&
      _setEq(other.preferredDays, preferredDays) &&
      other.endsOn == endsOn &&
      other.endsAfter == endsAfter;

  @override
  int get hashCode => Object.hash(
    kind,
    freq,
    interval,
    Object.hashAllUnordered(weekdays),
    monthlyMode,
    quota,
    endsOn,
    endsAfter,
  );

  static bool _setEq(Set<int> a, Set<int> b) =>
      a.length == b.length && a.containsAll(b);
}

const Object _keep = Object();

/// Mondays-first ISO weekday letters for toggles.
const weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

String isoWeekdayRRule(int isoWeekday) => _rruleDays[isoWeekday - 1];

extension DayLabel on DateTime {
  String get shortWeekday => weekdayShort[weekday - 1];
  String get monthShort => monthLong[month - 1].substring(0, 3);
  String get dayMonth => '$day $monthShort';
  String get isoDay => Days.iso(this);
}
