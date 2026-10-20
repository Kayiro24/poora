/// Calendar dates without a time of day.
///
/// A "day" is represented as a `DateTime` at UTC midnight. Arithmetic on UTC
/// values never crosses a DST transition, so adding days is exact and dates
/// never drift. Wall-clock instants for a day are produced with [Days.at].
abstract final class Days {
  static DateTime of(DateTime t) => DateTime.utc(t.year, t.month, t.day);

  static DateTime ymd(int y, int m, int d) => DateTime.utc(y, m, d);

  static DateTime today(DateTime now) => of(now);

  static DateTime add(DateTime day, int n) =>
      DateTime.utc(day.year, day.month, day.day + n);

  static int between(DateTime a, DateTime b) =>
      of(b).difference(of(a)).inDays;

  static bool same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Local wall-clock instant on [day] at [minute] minutes past midnight.
  static DateTime at(DateTime day, int minute) =>
      DateTime(day.year, day.month, day.day, 0, minute);

  /// First day of the week containing [day].
  static DateTime weekStart(DateTime day, {required bool mondayFirst}) {
    final wd = day.weekday; // 1 = Mon … 7 = Sun
    final back = mondayFirst ? wd - 1 : wd % 7;
    return add(of(day), -back);
  }

  static DateTime monthStart(DateTime day) => DateTime.utc(day.year, day.month);

  static int daysInMonth(int year, int month) =>
      DateTime.utc(year, month + 1, 0).day;

  static String iso(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  static DateTime parse(String iso) {
    final p = iso.split('-');
    return DateTime.utc(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  /// Every day in [from, to] inclusive.
  static Iterable<DateTime> range(DateTime from, DateTime to) sync* {
    for (var d = of(from); !d.isAfter(to); d = add(d, 1)) {
      yield d;
    }
  }
}

/// Inclusive range of days.
class DateRange {
  DateRange(DateTime from, DateTime to) : from = Days.of(from), to = Days.of(to);

  factory DateRange.day(DateTime d) => DateRange(d, d);

  factory DateRange.week(DateTime d, {required bool mondayFirst}) {
    final s = Days.weekStart(d, mondayFirst: mondayFirst);
    return DateRange(s, Days.add(s, 6));
  }

  factory DateRange.month(DateTime d) {
    final s = Days.monthStart(d);
    return DateRange(s, DateTime.utc(s.year, s.month + 1, 0));
  }

  final DateTime from;
  final DateTime to;

  int get length => Days.between(from, to) + 1;
  Iterable<DateTime> get days => Days.range(from, to);
  bool contains(DateTime d) => !d.isBefore(from) && !d.isAfter(to);

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);

  @override
  String toString() => 'DateRange(${Days.iso(from)}..${Days.iso(to)})';
}
