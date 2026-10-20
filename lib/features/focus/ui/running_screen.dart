import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poora/core/providers.dart';
import 'package:poora/core/theme/motion.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';
import 'package:poora/core/time/date_utils.dart';
import 'package:poora/features/focus/application/focus_controller.dart';
import 'package:poora/features/focus/domain/timer_engine.dart';
import 'package:poora/features/focus/domain/timer_format.dart';
import 'package:poora/features/settings/settings_controller.dart';
import 'package:poora/features/tasks/application/tasks_providers.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Full-screen, distraction-free session (§4.3). Shows only the phase label,
/// the timer and its ring; controls appear for 4 s on tap.
class FocusRunningScreen extends ConsumerStatefulWidget {
  const FocusRunningScreen({super.key});

  @override
  ConsumerState<FocusRunningScreen> createState() => _RunningState();
}

class _RunningState extends ConsumerState<FocusRunningScreen>
    with TickerProviderStateMixin {
  late final Ticker _ticker;
  late final AnimationController _breath;
  final _now = ValueNotifier<DateTime>(DateTime.now());
  bool _controls = false;
  Timer? _hide;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky));
    if (ref.read(settingsProvider).keepAwake) unawaited(WakelockPlus.enable());
    _ticker = createTicker((_) => _now.value = ref.read(clockProvider).now())..start();
    _breath = AnimationController(vsync: this, duration: const Duration(seconds: 8));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _breath.stop();
    } else if (!_breath.isAnimating) {
      _breath.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _breath.dispose();
    _hide?.cancel();
    _now.dispose();
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    unawaited(WakelockPlus.disable());
    super.dispose();
  }

  void _reveal() {
    setState(() => _controls = true);
    _hide?.cancel();
    _hide = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _controls = false);
    });
  }

  Future<void> _onSessionGone(FocusSummary? summary) async {
    if (_closing) return;
    _closing = true;
    if (summary != null && mounted) {
      await showModalBottomSheet<void>(
        context: context,
        isDismissible: false,
        enableDrag: false,
        builder: (_) => _SummarySheet(summary: summary),
      );
      ref.read(focusControllerProvider.notifier).dismissSummary();
    }
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(focusControllerProvider, (prev, next) {
      if (next.session == null && next.recovery == null) {
        unawaited(_onSessionGone(next.summary));
      }
    });
    final ui = ref.watch(focusControllerProvider);
    final session = ui.session;
    final settings = ref.watch(settingsProvider);
    if (session == null) {
      if (ui.summary == null && !_closing) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _onSessionGone(null));
      }
      return const Scaffold(backgroundColor: Tokens.bg);
    }
    final ctrl = ref.read(focusControllerProvider.notifier);
    final engine = ctrl.engineFor(session.config);
    final timer = session.timer;
    final format = TimerFormat(
      showSeconds: settings.showSeconds,
      showSubSeconds: settings.showSubSeconds,
    );
    final accent = timer.isFocus ? Tokens.sage : Tokens.ice;
    final label = switch (timer.phase) {
      FocusPhase.focus => 'FOCUS · ${timer.focusIndex} of ${session.config.longEvery}',
      FocusPhase.shortBreak => 'SHORT BREAK',
      FocusPhase.longBreak => 'LONG BREAK',
    };

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _reveal,
          child: AnimatedBuilder(
            animation: _breath,
            builder: (context, child) => DecoratedBox(
              decoration: BoxDecoration(
                color: Color.lerp(
                  Tokens.bg,
                  Color.alphaBlend(Tokens.sage.withValues(alpha: 0.04), Tokens.bg),
                  Curves.easeInOut.transform(_breath.value),
                ),
              ),
              child: child,
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: AppText.display(18, color: Tokens.textPrimary.withValues(alpha: 0.4)),
                        ),
                        const SizedBox(height: 28),
                        _TimerFace(
                          now: _now,
                          engine: engine,
                          timer: timer,
                          format: format,
                          accent: accent,
                        ),
                        const SizedBox(height: 28),
                        // Waiting phases need a visible start; everything else
                        // stays hidden until tapped.
                        SizedBox(
                          height: 56,
                          child: timer.isWaiting
                              ? _ControlPill(
                                  label: timer.isFocus ? 'START FOCUS' : 'START BREAK',
                                  icon: Icons.play_arrow_rounded,
                                  color: accent,
                                  onTap: ctrl.resume,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 32,
                    child: IgnorePointer(
                      ignoring: !_controls,
                      child: AnimatedOpacity(
                        opacity: _controls ? 1 : 0,
                        duration: Motion.of(context),
                        curve: Motion.curve,
                        child: _Controls(
                          paused: timer.isPaused,
                          waiting: timer.isWaiting,
                          longPressToEnd: settings.longPressToEnd,
                          onPauseResume: () {
                            _reveal();
                            timer.isPaused ? ctrl.resume() : ctrl.pause();
                          },
                          onSkip: () {
                            _reveal();
                            ctrl.skip();
                          },
                          onEnd: () {
                            HapticFeedback.mediumImpact();
                            ctrl.end();
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ring + digits. Repaints per frame via [now]; the text only rebuilds when
/// the formatted string changes.
class _TimerFace extends StatelessWidget {
  const _TimerFace({
    required this.now,
    required this.engine,
    required this.timer,
    required this.format,
    required this.accent,
  });

  final ValueNotifier<DateTime> now;
  final TimerEngine engine;
  final TimerState timer;
  final TimerFormat format;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final size = math.min(MediaQuery.sizeOf(context).width - 48, 340).toDouble();
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _RingPainter(
          now: now,
          engine: engine,
          timer: timer,
          color: accent,
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(size * 0.12),
            child: ValueListenableBuilder<DateTime>(
              valueListenable: now,
              builder: (context, t, _) => _Digits(
                text: format.main(engine.remainingMs(timer, t)),
                unit: format.unit,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Digits extends StatelessWidget {
  const _Digits({required this.text, required this.unit});
  final String text;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: false,
      label: unit == null ? '$text remaining' : '$text minutes remaining',
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(text, style: AppText.mono(104, weight: FontWeight.w400)),
            if (unit != null) ...[
              const SizedBox(width: 8),
              Text(unit!, style: AppText.body(22, color: Tokens.textSecondary)),
            ],
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.now,
    required this.engine,
    required this.timer,
    required this.color,
  }) : super(repaint: now);

  final ValueNotifier<DateTime> now;
  final TimerEngine engine;
  final TimerState timer;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 4;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Tokens.outline,
    );
    final p = engine.progress(timer, now.value);
    if (p <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * p,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.timer != timer || old.color != color;
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.paused,
    required this.waiting,
    required this.longPressToEnd,
    required this.onPauseResume,
    required this.onSkip,
    required this.onEnd,
  });

  final bool paused;
  final bool waiting;
  final bool longPressToEnd;
  final VoidCallback onPauseResume;
  final VoidCallback onSkip;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!waiting) ...[
              _ControlPill(
                label: paused ? 'RESUME' : 'PAUSE',
                icon: paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                onTap: onPauseResume,
              ),
              const SizedBox(width: 10),
            ],
            _ControlPill(label: 'SKIP', icon: Icons.skip_next_rounded, onTap: onSkip),
            const SizedBox(width: 10),
            _ControlPill(
              label: 'END',
              icon: Icons.stop_rounded,
              onTap: longPressToEnd ? null : onEnd,
              onLongPress: longPressToEnd ? onEnd : null,
              color: Tokens.coralSoft,
            ),
          ],
        ),
        if (longPressToEnd) ...[
          const SizedBox(height: 10),
          Text('Hold END to finish early', style: AppText.bodyS),
        ],
      ],
    );
  }
}

class _ControlPill extends StatelessWidget {
  const _ControlPill({
    required this.label,
    required this.icon,
    this.onTap,
    this.onLongPress,
    this.color = Tokens.textPrimary,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: onLongPress != null ? '$label, hold to activate' : label,
      excludeSemantics: true,
      child: Material(
        color: Tokens.surface,
        shape: StadiumBorder(side: BorderSide(color: color.withValues(alpha: 0.4))),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap ?? (onLongPress == null ? null : () {}),
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Text(label, style: AppText.display(18, color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummarySheet extends ConsumerWidget {
  const _SummarySheet({required this.summary});
  final FocusSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linkedDate = summary.linkedDate;
    final linked = summary.linkedTaskId == null || linkedDate == null
        ? null
        : ref
              .watch(occurrencesProvider(DateRange.day(linkedDate)))
              .where((o) => o.task.id == summary.linkedTaskId && o.originalDate == linkedDate)
              .firstOrNull;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              summary.endedEarly ? 'SESSION ENDED EARLY' : 'CYCLE COMPLETE',
              style: AppText.h2,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _Stat(value: '${summary.focusMinutes}', label: 'focus minutes')),
                Expanded(child: _Stat(value: '${summary.sessionsCompleted}', label: 'sessions completed')),
              ],
            ),
            if (linked != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Tokens.surfaceHigh,
                  borderRadius: BorderRadius.circular(Radii.inner),
                ),
                child: Row(
                  children: [
                    Container(width: 4, height: 32, color: Color(linked.task.color)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(linked.title.toUpperCase(), style: AppText.h4)),
                    if (linked.isDone)
                      const Icon(Icons.check_circle_rounded, color: Tokens.mint)
                    else
                      TextButton(
                        onPressed: () {
                          ref.read(feedbackProvider).success();
                          ref.read(tasksRepositoryProvider).setDone(linked, done: true);
                        },
                        child: const Text('Mark task done'),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Tokens.sage,
                  foregroundColor: Tokens.textInverse,
                  shape: const StadiumBorder(),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text('DONE', style: AppText.display(20, color: Tokens.textInverse)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: AppText.mono(44, color: Tokens.sage)),
      const SizedBox(height: 4),
      Text(label, style: AppText.bodyS),
    ],
  );
}
