/// Display formatting for times and durations.
abstract final class Fmt {
  /// "9:05 am" / "09:05".
  static String minute(int minute, {required bool use24h}) {
    final h = (minute ~/ 60) % 24;
    final m = minute % 60;
    final mm = m.toString().padLeft(2, '0');
    if (use24h) return '${h.toString().padLeft(2, '0')}:$mm';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:$mm ${h < 12 ? 'am' : 'pm'}';
  }

  static String time(DateTime t, {required bool use24h}) =>
      minute(t.hour * 60 + t.minute, use24h: use24h);

  /// Compact hour label for rails and charts: "9 am" / "09".
  static String hour(int h, {required bool use24h}) {
    if (use24h) return h.toString().padLeft(2, '0');
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12 ${h % 24 < 12 ? 'am' : 'pm'}';
  }

  /// "45 min", "1 h 30 min".
  static String duration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h h' : '$h h $m min';
  }

  /// Countdown "0:42:10".
  static String countdown(Duration d) {
    final s = d.inSeconds < 0 ? 0 : d.inSeconds;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    return '$h:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  /// "just now", "12 min ago", "2 h ago", "3 d ago".
  static String ago(DateTime then, DateTime now) {
    final d = now.difference(then);
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes} min ago';
    if (d.inDays < 1) return '${d.inHours} h ago';
    return '${d.inDays} d ago';
  }

  /// "UTC+5:30".
  static String utcOffset(Duration offset) {
    final sign = offset.isNegative ? '-' : '+';
    final mins = offset.inMinutes.abs();
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? 'UTC$sign$h' : 'UTC$sign$h:${m.toString().padLeft(2, '0')}';
  }

  static String hours(double minutes) {
    final h = minutes / 60;
    return h >= 10 ? h.toStringAsFixed(0) : h.toStringAsFixed(1);
  }
}
