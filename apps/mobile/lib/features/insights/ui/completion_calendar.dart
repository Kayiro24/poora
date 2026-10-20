import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poora/core/providers.dart';
import 'package:poora/core/theme/motion.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';
import 'package:poora/core/time/date_utils.dart';
import 'package:poora/core/widgets/completion_ring.dart';
import 'package:poora/core/widgets/pill_chip.dart';
import 'package:poora/features/insights/data/insights_repository.dart';
import 'package:poora/features/insights/domain/metrics.dart';
import 'package:poora/features/insights/ui/day_cell.dart';
import 'package:poora/features/settings/settings_controller.dart';
import 'package:poora/features/tasks/application/tasks_providers.dart';
import 'package:poora/features/tasks/domain/models.dart';
import 'package:poora/features/tasks/domain/recurrence.dart';
import 'package:poora/features/tasks/ui/task_card.dart';

/// Day the "ring closed" pulse last played (in-memory; once per day).
final _pulsedDayProvider = NotifierProvider<_PulsedDay, DateTime?>(_PulsedDay.new);

class _PulsedDay extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;
  void set(DateTime d) => state = d;
}

/// Month grid of [DayCell]s with consecutive perfect days joined by a soft
/// green pill per week row; a 7+ streak gets a 🔥 on its last day.
class CompletionMonthGrid extends ConsumerStatefulWidget {
  const CompletionMonthGrid({
    required this.month,
    this.filter = const CalendarFilter.all(),
    this.onDayTap,
    super.key,
  });

  final DateTime month;
  final CalendarFilter filter;
  final ValueChanged<DateTime>? onDayTap;

  @override
  ConsumerState<CompletionMonthGrid> createState() => _MonthGridState();
}

class _MonthGridState extends ConsumerState<CompletionMonthGrid> {
  bool _firstBuild = true;

  @override
  void didUpdateWidget(CompletionMonthGrid old) {
    super.didUpdateWidget(old);
    if (old.month != widget.month) _firstBuild = true;
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(insightsRepositoryProvider);
    final mondayFirst = ref.watch(settingsProvider.select((s) => s.mondayFirst));
    final today = ref.watch(todayProvider);
    final month = DateRange.month(widget.month);
    final gridStart = Days.weekStart(month.from, mondayFirst: mondayFirst);
    final weeks = ((Days.between(gridStart, month.to) + 1) / 7).ceil();
    final grid = DateRange(gridStart, Days.add(gridStart, weeks * 7 - 1));
    final days = repo.dayCompletion(grid, filter: widget.filter);
    final quotaTask = widget.filter.seriesId == null ? null : repo.seriesTask(widget.filter.seriesId!);
    final isQuota = quotaTask?.isQuota ?? false;
    final reduce = Motion.reduced(context);
    final stagger = _firstBuild && !reduce;
    if (_firstBuild) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _firstBuild = false);
    }

    // Run length of perfect days ending at each day (continues across rows).
    final runAt = <DateTime, int>{};
    var run = 0;
    for (final d in grid.days) {
      final c = days[d]!;
      if (c.isPerfect) {
        run++;
      } else if (c.tier != DayTier.rest || run == 0) {
        run = 0;
      }
      runAt[d] = c.isPerfect ? run : 0;
    }

    // Today's ring just closed → one soft pulse + success haptic.
    final todayDone = days[today]?.isPerfect ?? false;
    final pulsed = ref.watch(_pulsedDayProvider);
    final pulseToday = todayDone && pulsed != today && grid.contains(today);
    if (pulseToday) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        HapticFeedback.mediumImpact();
        ref.read(_pulsedDayProvider.notifier).set(today);
      });
    }

    final names = [for (var i = 0; i < 7; i++) weekdayLetters[(i + (mondayFirst ? 0 : 6)) % 7]];
    var index = 0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final trailing = isQuota ? 44.0 : 0.0;
        final cellW = (constraints.maxWidth - trailing) / 7;
        final cellSize = (cellW - 4).clamp(36.0, 48.0);
        return Column(
          children: [
            Row(
              children: [
                for (final n in names)
                  SizedBox(
                    width: cellW,
                    child: Center(child: Text(n, style: AppText.body(11, color: Tokens.textSecondary))),
                  ),
                SizedBox(width: trailing),
              ],
            ),
            const SizedBox(height: 6),
            for (var w = 0; w < weeks; w++)
              Row(
                children: [
                  SizedBox(
                    width: cellW * 7,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _StreakPainter(
                              perfect: [
                                for (var i = 0; i < 7; i++)
                                  (days[Days.add(gridStart, w * 7 + i)]!.isPerfect &&
                                      Days.add(gridStart, w * 7 + i).month == month.from.month),
                              ],
                              cellSize: cellSize,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            for (var i = 0; i < 7; i++)
                              SizedBox(
                                width: cellW,
                                child: () {
                                  final d = Days.add(gridStart, w * 7 + i);
                                  final c = days[d]!;
                                  final inMonth = d.month == month.from.month;
                                  final next = Days.add(d, 1);
                                  final endsStreak = (runAt[d] ?? 0) >= 7 && !(days[next]?.isPerfect ?? false);
                                  final cell = DayCell(
                                    completion: c,
                                    isToday: Days.same(d, today),
                                    size: cellSize,
                                    pulse: pulseToday && Days.same(d, today),
                                    delay: stagger ? Duration(milliseconds: 20 * index++) : Duration.zero,
                                    onTap: widget.onDayTap == null || d.isAfter(today) || c.tier == DayTier.beforeFirstUse
                                        ? null
                                        : () => widget.onDayTap!(d),
                                  );
                                  if (!inMonth) return Opacity(opacity: 0, child: IgnorePointer(child: cell));
                                  if (!endsStreak) return cell;
                                  return Stack(
                                    clipBehavior: Clip.none,
                                    alignment: Alignment.center,
                                    children: [
                                      cell,
                                      Positioned(
                                        top: -2,
                                        right: cellW / 2 - cellSize / 2 - 4,
                                        child: ExcludeSemantics(child: Text('🔥', style: AppText.body(12))),
                                      ),
                                    ],
                                  );
                                }(),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isQuota)
                    SizedBox(
                      width: trailing,
                      child: _QuotaWeekBadge(
                        task: quotaTask!,
                        done: repo.quotaDone(widget.filter.seriesId!, Days.add(gridStart, w * 7)),
                      ),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _QuotaWeekBadge extends StatelessWidget {
  const _QuotaWeekBadge({required this.task, required this.done});
  final Task task;
  final int done;

  @override
  Widget build(BuildContext context) {
    final q = task.quotaPerWeek ?? 1;
    final met = done >= q;
    return Text(
      '$done/$q${met ? ' ✓' : ''}',
      textAlign: TextAlign.right,
      style: AppText.mono(11, color: met ? Tokens.dayPerfect : Tokens.textSecondary),
    );
  }
}

/// Soft highlighter pill behind runs of perfect days in one week row.
class _StreakPainter extends CustomPainter {
  _StreakPainter({required this.perfect, required this.cellSize});
  final List<bool> perfect;
  final double cellSize;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width / 7;
    final paint = Paint()..color = Tokens.dayPerfect.withValues(alpha: 0.16);
    var i = 0;
    while (i < 7) {
      if (!perfect[i]) {
        i++;
        continue;
      }
      var j = i;
      while (j + 1 < 7 && perfect[j + 1]) {
        j++;
      }
      if (j > i) {
        final h = cellSize + 4;
        final rect = Rect.fromLTRB(
          i * w + (w - cellSize) / 2 - 2,
          (size.height - h) / 2,
          (j + 1) * w - (w - cellSize) / 2 + 2,
          (size.height + h) / 2,
        );
        canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(h / 2)), paint);
      }
      i = j + 1;
    }
  }

  @override
  bool shouldRepaint(_StreakPainter old) =>
      old.cellSize != cellSize || !_listEq(old.perfect, perfect);

  static bool _listEq(List<bool> a, List<bool> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// GitHub-style 53×7 year grid, auto-scrolled to today.
class CompletionYearGrid extends ConsumerStatefulWidget {
  const CompletionYearGrid({
    required this.filter,
    required this.onDayTap,
    super.key,
  });

  final CalendarFilter filter;
  final ValueChanged<DateTime> onDayTap;

  @override
  ConsumerState<CompletionYearGrid> createState() => _YearGridState();
}

class _YearGridState extends ConsumerState<CompletionYearGrid> {
  final _scroll = ScrollController();
  static const _cell = 14.0;
  static const _gap = 3.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(insightsRepositoryProvider);
    final mondayFirst = ref.watch(settingsProvider.select((s) => s.mondayFirst));
    final today = ref.watch(todayProvider);
    final end = Days.add(Days.weekStart(today, mondayFirst: mondayFirst), 6);
    final start = Days.add(end, -53 * 7 + 1);
    final days = repo.dayCompletion(DateRange(start, end), filter: widget.filter);
    return SingleChildScrollView(
      controller: _scroll,
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 16,
            child: Row(
              children: [
                for (var w = 0; w < 53; w++)
                  SizedBox(
                    width: _cell + _gap,
                    child: () {
                      final d = Days.add(start, w * 7);
                      final firstOfMonth = d.day <= 7;
                      return firstOfMonth
                          ? OverflowBox(
                              maxWidth: 40,
                              alignment: Alignment.centerLeft,
                              child: Text(d.monthShort, style: AppText.body(10, color: Tokens.textSecondary)),
                            )
                          : null;
                    }(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var w = 0; w < 53; w++)
                Padding(
                  padding: const EdgeInsets.only(right: _gap),
                  child: Column(
                    children: [
                      for (var i = 0; i < 7; i++)
                        () {
                          final d = Days.add(start, w * 7 + i);
                          final c = days[d]!;
                          final color = switch (c.tier) {
                            DayTier.future || DayTier.beforeFirstUse => Tokens.surface,
                            DayTier.rest => Tokens.dayEmpty,
                            DayTier.today => Tokens.ice.withValues(alpha: 0.5),
                            _ => tierColor(c.tier),
                          };
                          return Semantics(
                            button: true,
                            label: '${d.day} ${d.monthShort} ${d.year}: ${tierLabel(c.tier)}',
                            excludeSemantics: true,
                            child: GestureDetector(
                              onTap: d.isAfter(today) ? null : () => widget.onDayTap(d),
                              child: Container(
                                width: _cell,
                                height: _cell,
                                margin: const EdgeInsets.only(bottom: _gap),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Days.same(d, today) ? Border.all(color: Tokens.ice) : null,
                                ),
                              ),
                            ),
                          );
                        }(),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Collapsible legend of the five tier swatches.
class TierLegend extends StatefulWidget {
  const TierLegend({super.key});

  @override
  State<TierLegend> createState() => _TierLegendState();
}

class _TierLegendState extends State<TierLegend> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    const items = [
      (DayTier.perfect, '100%', Icons.check_rounded),
      (DayTier.high, '80–99%', Icons.contrast_rounded),
      (DayTier.mid, '50–79%', Icons.contrast_rounded),
      (DayTier.low, '1–49%', Icons.contrast_rounded),
      (DayTier.missed, '0%', Icons.close_rounded),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Legend', style: AppText.bodyS),
                Icon(_open ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 18, color: Tokens.textSecondary),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: Motion.of(context),
          curve: Motion.curve,
          child: !_open
              ? const SizedBox(width: double.infinity)
              : Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    for (final (tier, label, icon) in items)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: tierColor(tier).withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                              border: Border.all(color: tierColor(tier), width: 2),
                            ),
                            child: Icon(icon, size: 10, color: Tokens.textPrimary),
                          ),
                          const SizedBox(width: 6),
                          Text(label, style: AppText.body(12, color: Tokens.textSecondary)),
                        ],
                      ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(color: Tokens.outline, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text('Rest day', style: AppText.body(12, color: Tokens.textSecondary)),
                      ],
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Day detail sheet (§4.11): ring, x of y, grouped occurrences with
/// back-fill actions, focus minutes. Updates live.
Future<void> showDayDetailSheet(BuildContext context, DateTime day) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FractionallySizedBox(heightFactor: 0.7, child: _DaySheet(day: day)),
    );

class _DaySheet extends ConsumerWidget {
  const _DaySheet({required this.day});
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(insightsRepositoryProvider);
    final c = repo.dayCompletion(DateRange.day(day))[day]!;
    final occ = ref.watch(occurrencesProvider(DateRange.day(day)));
    final focus = repo.focusMinutesOn(day);
    final groups = <(String, List<Occurrence>)>[
      ('Done', occ.where((o) => o.isDone).toList()),
      ('Missed', occ.where((o) => o.status == OccurrenceStatus.missed).toList()),
      ('Still open', occ.where((o) => o.status == OccurrenceStatus.pending).toList()),
      ('Skipped', occ.where((o) => o.status == OccurrenceStatus.skipped).toList()),
    ];
    final ringColor = c.tier == DayTier.today
        ? Tokens.ice
        : c.tier == DayTier.rest
        ? Tokens.outline
        : tierColor(c.tier);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        Row(
          children: [
            CompletionRing(
              value: c.tier == DayTier.missed ? 1 : (c.rate ?? 0),
              color: ringColor,
              size: 72,
              stroke: 6,
              duration: Motion.of(context, const Duration(milliseconds: 700)),
              child: Text(c.percent == null ? '–' : '${c.percent}%', style: AppText.mono(15)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${weekdayLong[day.weekday - 1]} ${day.dayMonth}'.toUpperCase(), style: AppText.h2),
                  const SizedBox(height: 4),
                  Text(
                    c.scheduled == 0 ? 'Rest day' : '${c.done} of ${c.scheduled} done',
                    style: AppText.body(15, color: Tokens.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (focus > 0) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: PillChip(
              label: '${focus.round()} min focus',
              icon: Icons.timer_outlined,
              filled: true,
              color: Tokens.sage,
            ),
          ),
        ],
        for (final (title, list) in groups)
          if (list.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(title.toUpperCase(), style: AppText.display(16, color: Tokens.textSecondary)),
            const SizedBox(height: 8),
            for (final o in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: o.status == OccurrenceStatus.missed
                    ? _MissedRow(occurrence: o)
                    : TaskCard(occurrence: o, swipe: false),
              ),
          ],
        if (occ.isEmpty) ...[
          const SizedBox(height: 24),
          Text('Nothing was scheduled. Rest is part of the rhythm.', style: AppText.bodyM),
        ],
      ],
    );
  }
}

class _MissedRow extends ConsumerWidget {
  const _MissedRow({required this.occurrence});
  final Occurrence occurrence;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final o = occurrence;
    final use24h = ref.watch(settingsProvider.select((s) => s.use24h));
    final repo = ref.read(tasksRepositoryProvider);
    return Container(
      decoration: BoxDecoration(color: Tokens.surfaceHigh, borderRadius: BorderRadius.circular(Radii.inner)),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: Color(o.task.color)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.title.toUpperCase(), style: AppText.display(18)),
                    const SizedBox(height: 2),
                    Text(
                      [occurrenceTimeLabel(o, use24h: use24h), if (o.task.tag != null) o.task.tag!].join(' · '),
                      style: AppText.mono(11, color: Tokens.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                ref.read(feedbackProvider).success();
                repo.setDone(o, done: true); // back-fill: recorded as late
              },
              child: Text('Mark done', style: AppText.label.copyWith(color: Tokens.mint)),
            ),
            TextButton(
              onPressed: () => repo.setSkipped(o, skipped: true),
              child: Text('Skip', style: AppText.label.copyWith(color: Tokens.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}
