import 'package:flutter/material.dart';
import 'package:poora/core/theme/motion.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';
import 'package:poora/core/widgets/completion_ring.dart';
import 'package:poora/features/insights/domain/metrics.dart';
import 'package:poora/features/tasks/domain/recurrence.dart';

Color tierColor(DayTier t) => switch (t) {
  DayTier.perfect => Tokens.dayPerfect,
  DayTier.high => Tokens.dayHigh,
  DayTier.mid => Tokens.dayMid,
  DayTier.low => Tokens.dayLow,
  DayTier.missed => Tokens.dayMissed,
  DayTier.today => Tokens.ice,
  _ => Tokens.dayEmpty,
};

String tierLabel(DayTier t) => switch (t) {
  DayTier.perfect => 'all done',
  DayTier.high => 'mostly done',
  DayTier.mid => 'about half done',
  DayTier.low => 'a little done',
  DayTier.missed => 'missed',
  DayTier.rest => 'rest day',
  DayTier.today => 'in progress',
  DayTier.future => 'upcoming',
  DayTier.beforeFirstUse => 'before you started',
};

/// One completion-calendar day (§4.11): ring arc = exact %, tier-tinted fill,
/// mono date and a ✓ ◐ ✕ icon so state never relies on colour alone.
class DayCell extends StatefulWidget {
  const DayCell({
    required this.completion,
    required this.isToday,
    this.onTap,
    this.size = 44,
    this.delay = Duration.zero,
    this.pulse = false,
    super.key,
  });

  final DayCompletion completion;
  final bool isToday;
  final VoidCallback? onTap;
  final double size;

  /// Stagger for the draw-in on month open.
  final Duration delay;

  /// One soft pulse (today's ring just closed).
  final bool pulse;

  @override
  State<DayCell> createState() => _DayCellState();
}

class _DayCellState extends State<DayCell> with SingleTickerProviderStateMixin {
  AnimationController? _breath;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final wants = widget.isToday && !Motion.reduced(context);
    if (wants && _breath == null) {
      _breath = AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..repeat(reverse: true);
    } else if (!wants) {
      _breath?.dispose();
      _breath = null;
    }
  }

  @override
  void dispose() {
    _breath?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.completion;
    final s = widget.size;
    final tier = c.tier;
    final dim = tier == DayTier.future || tier == DayTier.beforeFirstUse;
    final label =
        '${c.day.day} ${c.day.monthShort}: ${tierLabel(tier)}'
        '${c.scheduled > 0 && !dim ? ', ${c.done} of ${c.scheduled} done' : ''}';

    final date = Text(
      '${c.day.day}',
      style: AppText.mono(
        13,
        color: tier == DayTier.beforeFirstUse
            ? Tokens.textSecondary.withValues(alpha: 0.35)
            : dim
            ? Tokens.textSecondary
            : Tokens.textPrimary,
      ),
    );

    final icon = switch (tier) {
      DayTier.perfect => Icons.check_rounded,
      DayTier.high || DayTier.mid || DayTier.low => Icons.contrast_rounded,
      DayTier.missed => Icons.close_rounded,
      _ => null,
    };

    Widget inner = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        date,
        if (icon != null)
          Icon(icon, size: 9, color: Tokens.textPrimary.withValues(alpha: 0.8))
        else if (tier == DayTier.future && c.pending > 0)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < c.pending.clamp(1, 3); i++)
                Container(
                  width: 3,
                  height: 3,
                  margin: const EdgeInsets.only(top: 3, left: 1, right: 1),
                  decoration: const BoxDecoration(color: Tokens.textSecondary, shape: BoxShape.circle),
                ),
            ],
          )
        else if (tier == DayTier.rest)
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 3),
            decoration: const BoxDecoration(color: Tokens.outline, shape: BoxShape.circle),
          ),
      ],
    );

    final hasRing = switch (tier) {
      DayTier.rest || DayTier.future || DayTier.beforeFirstUse => false,
      _ => true,
    };
    if (hasRing) {
      final color = tierColor(tier);
      final rate = c.rate ?? 0;
      final perfect = tier == DayTier.perfect;
      final missed = tier == DayTier.missed;
      // Today shows progress in its tier colour, but never red.
      final progressTier = CompletionTiers.tierFor(rate);
      final todayColor = progressTier == DayTier.missed ? Tokens.ice : tierColor(progressTier);
      inner = CompletionRing(
        value: missed ? 1 : rate,
        color: tier == DayTier.today ? todayColor : color,
        size: s,
        stroke: missed ? 1.5 : 3,
        fill: tier == DayTier.today
            ? null
            : color.withValues(alpha: perfect ? 0.35 : 0.2),
        glow: perfect,
        delay: widget.delay,
        child: inner,
      );
    }

    if (widget.isToday) {
      final b = _breath;
      final ring = inner;
      inner = b == null
          ? _todayOutline(ring, 0.8)
          : AnimatedBuilder(
              animation: b,
              builder: (context, child) => _todayOutline(child!, 0.45 + 0.45 * b.value),
              child: ring,
            );
    }

    if (widget.pulse) {
      inner = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        builder: (context, v, child) =>
            Transform.scale(scale: 1 + 0.08 * (1 - (2 * v - 1).abs()), child: child),
        child: inner,
      );
    }

    return Semantics(
      button: widget.onTap != null,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: s + 4,
          child: Center(child: SizedBox.square(dimension: s, child: Center(child: inner))),
        ),
      ),
    );
  }

  Widget _todayOutline(Widget child, double alpha) => Container(
    padding: const EdgeInsets.all(1.5),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: Tokens.ice.withValues(alpha: alpha), width: 1.5),
    ),
    child: child,
  );
}
