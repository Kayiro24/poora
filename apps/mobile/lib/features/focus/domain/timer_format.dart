/// Running-screen timer text (§4.3), shared with the settings preview so the
/// two always match exactly.
class TimerFormat {
  const TimerFormat({required this.showSeconds, required this.showSubSeconds});

  final bool showSeconds;

  /// Stored preference; only effective while [showSeconds] is on.
  final bool showSubSeconds;

  bool get effectiveSubSeconds => showSeconds && showSubSeconds;

  /// Main digits for [remainingMs]. With seconds off this is whole minutes,
  /// rounded up so "25" shows for the full first minute.
  String main(int remainingMs) {
    final ms = remainingMs < 0 ? 0 : remainingMs;
    if (!showSeconds) return '${(ms / 60000).ceil()}';
    // Count down so the display reaches 00:00 exactly at the end.
    final totalCs = effectiveSubSeconds ? (ms / 10).ceil() : (ms / 1000).ceil() * 100;
    final totalSec = totalCs ~/ 100;
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    final base = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    if (!effectiveSubSeconds) return base;
    return '$base.${(totalCs % 100).toString().padLeft(2, '0')}';
  }

  /// Small unit label shown next to the digits ("min" with seconds off).
  String? get unit => showSeconds ? null : 'min';

  /// How often the digits change — used to throttle rebuilds.
  Duration get refresh => !showSeconds
      ? const Duration(seconds: 1)
      : effectiveSubSeconds
      ? Duration.zero // every frame
      : const Duration(milliseconds: 200);
}
