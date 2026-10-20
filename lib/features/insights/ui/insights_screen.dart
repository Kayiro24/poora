import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poora/app_router.dart';
import 'package:poora/core/providers.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';
import 'package:poora/core/time/date_utils.dart';
import 'package:poora/core/time/format.dart';
import 'package:poora/core/widgets/accent_panel.dart';
import 'package:poora/core/widgets/arrow_circle_button.dart';
import 'package:poora/core/widgets/common.dart';
import 'package:poora/core/widgets/day_rate_pills.dart';
import 'package:poora/core/widgets/floating_nav_bar.dart';
import 'package:poora/core/widgets/mascot.dart';
import 'package:poora/core/widgets/pill_chip.dart';
import 'package:poora/core/widgets/round_icon_button.dart';
import 'package:poora/core/widgets/screen_header.dart';
import 'package:poora/core/widgets/stat_tile.dart';
import 'package:poora/features/insights/data/insights_repository.dart';
import 'package:poora/features/insights/domain/metrics.dart';
import 'package:poora/features/insights/ui/charts.dart';
import 'package:poora/features/insights/ui/completion_calendar.dart';
import 'package:poora/features/insights/ui/recurring_card.dart';
import 'package:poora/features/settings/settings_controller.dart';
import 'package:poora/features/tasks/domain/recurrence.dart';

enum InsightRange {
  today('Today'),
  week('This week'),
  month('This month'),
  last30('Last 30 days'),
  all('All time');

  InsightRange(this.label);
  final String label;
}

const _emptyLine = 'Complete a few tasks and your week will show up here';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  InsightRange _range = InsightRange.week;
  int _offset = 0;

  DateRange _resolve(InsightsRepository repo, DateTime today) {
    switch (_range) {
      case InsightRange.today:
        return DateRange.day(Days.add(today, _offset));
      case InsightRange.week:
        final w = repo.week(today);
        return DateRange(Days.add(w.from, 7 * _offset), Days.add(w.to, 7 * _offset));
      case InsightRange.month:
        return DateRange.month(DateTime.utc(today.year, today.month + _offset));
      case InsightRange.last30:
        final end = Days.add(today, 30 * _offset);
        return DateRange(Days.add(end, -29), end);
      case InsightRange.all:
        return DateRange(repo.firstUse ?? today, today);
    }
  }

  String _rangeTitle(DateRange r, DateTime today) {
    if (_offset == 0) return _range.label;
    if (r.length == 1) return '${r.from.shortWeekday} ${r.from.dayMonth}';
    return '${r.from.dayMonth} – ${r.to.dayMonth}';
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(insightsRepositoryProvider);
    final today = ref.watch(todayProvider);
    final range = _resolve(repo, today);
    final canStep = _range != InsightRange.all;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(Space.side, Space.m, Space.side, FloatingNavBar.reservedHeight(context)),
          children: [
            ScreenHeader(
              title: 'Insights',
              trailing: [
                PopupMenuButton<InsightRange>(
                  tooltip: 'Change range',
                  color: Tokens.surfaceHigh,
                  onSelected: (r) => setState(() {
                    _range = r;
                    _offset = 0;
                  }),
                  itemBuilder: (_) => [
                    for (final r in InsightRange.values)
                      PopupMenuItem(value: r, child: Text(r.label, style: AppText.bodyL)),
                  ],
                  child: IgnorePointer(
                    child: PillChip(label: _rangeTitle(range, today), trailingIcon: Icons.expand_more_rounded),
                  ),
                ),
              ],
            ),
            if (canStep)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  RoundIconButton(
                    icon: Icons.arrow_back_rounded,
                    semanticLabel: 'Previous period',
                    size: 34,
                    onTap: () => setState(() => _offset--),
                  ),
                  RoundIconButton(
                    icon: Icons.arrow_forward_rounded,
                    semanticLabel: 'Next period',
                    size: 34,
                    onTap: _offset >= 0 ? null : () => setState(() => _offset++),
                  ),
                ],
              ),
            const SizedBox(height: Space.s),
            _Headline(range: range),
            const SizedBox(height: Space.xxl),
            _CalendarSection(month: range.to.isAfter(today) ? today : range.to),
            const SizedBox(height: Space.xxl),
            _WeekCapacity(day: range.to.isAfter(today) ? today : range.to),
            const SizedBox(height: Space.xxl),
            const _RecurringSection(),
            const SizedBox(height: Space.xxl),
            const _HeatmapSection(),
            const SizedBox(height: Space.xxl),
            _TimingSection(range: range),
            const SizedBox(height: Space.xxl),
            _FocusSection(range: range),
            const SizedBox(height: Space.xxl),
            _CategorySection(range: range),
          ],
        ),
      ),
    );
  }
}

class _Headline extends ConsumerWidget {
  const _Headline({required this.range});
  final DateRange range;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(insightsRepositoryProvider);
    final rate = repo.completionRate(range);
    final focus = repo.focus(range);
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      padding: EdgeInsets.zero, // don't inherit the system bottom inset
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.6,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        _Tile(child: StatTile(value: '${repo.doneCount(range)}', label: 'tasks\ncompleted', labelColor: Tokens.textSecondary)),
        _Tile(
          child: StatTile(
            value: rate == null ? '–' : '${(rate * 100).round()}%',
            label: 'completion\nrate',
            labelColor: Tokens.textSecondary,
          ),
        ),
        _Tile(
          child: StatTile(
            value: Fmt.hours(focus.totalMinutes),
            label: 'focus\nhours',
            color: Tokens.sage,
            labelColor: Tokens.textSecondary,
          ),
        ),
        _Tile(
          child: StatTile(
            value: '${repo.overallStreak()}',
            label: 'day\nstreak',
            color: Tokens.sun,
            labelColor: Tokens.textSecondary,
            leading: const Text('🔥', style: TextStyle(fontSize: 20)),
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    alignment: Alignment.centerLeft,
    decoration: BoxDecoration(color: Tokens.surface, borderRadius: BorderRadius.circular(Radii.inner)),
    child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: child),
  );
}

/// §4.11 hero: this month's completion calendar.
class _CalendarSection extends ConsumerWidget {
  const _CalendarSection({required this.month});
  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 16),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${monthLong[month.month - 1]} ${month.year}'.toUpperCase(),
                  style: AppText.h3,
                ),
              ),
              ArrowCircleButton(
                semanticLabel: 'Open completion calendar',
                onTap: () => context.push(Routes.calendar()),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: CompletionMonthGrid(month: month, onDayTap: (d) => showDayDetailSheet(context, d)),
          ),
          const Padding(padding: EdgeInsets.only(left: 6), child: TierLegend()),
        ],
      ),
    );
  }
}

/// Mirrors the reference "Venue Capacity" card: daily % pills and completed
/// vs scheduled per day.
class _WeekCapacity extends ConsumerWidget {
  const _WeekCapacity({required this.day});
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(insightsRepositoryProvider);
    final today = ref.watch(todayProvider);
    final week = repo.week(day);
    final days = repo.dayCompletion(week);
    final list = week.days.toList();
    final lastActual = list.indexWhere((d) => d.isAfter(today));
    final any = days.values.any((d) => d.scheduled > 0);
    return AccentPanel(
      color: Tokens.periwinkle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WEEK CAPACITY', style: AppText.h3.copyWith(color: Tokens.textInverse)),
          const SizedBox(height: 4),
          Text('${week.from.dayMonth} – ${week.to.dayMonth}', style: AppText.body(13, color: Tokens.textInverse)),
          const SizedBox(height: 16),
          DayRatePills(
            days: [
              for (final d in list)
                DayPill(
                  date: d,
                  label: d.shortWeekday,
                  percent: d.isAfter(today) ? null : days[d]!.percent,
                  isToday: Days.same(d, today),
                  isFuture: d.isAfter(today),
                ),
            ],
            onTap: (p) => p.isFuture ? null : showDayDetailSheet(context, p.date),
          ),
          const SizedBox(height: 16),
          if (!any)
            const EmptyState(message: _emptyLine, mood: MascotMood.thinking, compact: true, color: Tokens.textInverse)
          else ...[
            WeekAreaChart(
              labels: [for (final d in list) d.shortWeekday.substring(0, 1)],
              actual: [for (final d in list) days[d]!.done.toDouble()],
              planned: [for (final d in list) days[d]!.scheduled.toDouble()],
              lastActual: lastActual < 0 ? null : lastActual - 1,
            ),
            const SizedBox(height: 8),
            const ChartLegend(
              ink: Tokens.textInverse,
              items: [(Tokens.coral, 'Completed', false), (Tokens.textInverse, 'Scheduled', true)],
            ),
          ],
        ],
      ),
    );
  }
}

class _RecurringSection extends ConsumerWidget {
  const _RecurringSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final series = ref.watch(insightsRepositoryProvider).recurringSeries();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Recurring tasks'),
        if (series.isEmpty)
          const EmptyState(message: 'Repeat a task and its rhythm will show up here.', mood: MascotMood.thinking, compact: true)
        else
          for (final s in series)
            Padding(padding: const EdgeInsets.only(bottom: 10), child: RecurringCard(series: s)),
      ],
    );
  }
}

class _HeatmapSection extends ConsumerWidget {
  const _HeatmapSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(insightsRepositoryProvider);
    final today = ref.watch(todayProvider);
    final mondayFirst = ref.watch(settingsProvider.select((s) => s.mondayFirst));
    final start = Days.add(Days.weekStart(today, mondayFirst: mondayFirst), -77);
    final days = repo.dayCompletion(DateRange(start, Days.add(start, 83)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Consistency'),
        AppCard(
          child: repo.hasData
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ConsistencyHeatmap(
                      days: days,
                      start: start,
                      today: today,
                      onTap: (d) => showDayDetailSheet(context, d),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('Less', style: AppText.body(11, color: Tokens.textSecondary)),
                        const SizedBox(width: 6),
                        for (final a in [0.12, 0.35, 0.6, 0.8, 1.0])
                          Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.only(right: 3),
                            decoration: BoxDecoration(
                              color: Tokens.coral.withValues(alpha: a),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        const SizedBox(width: 3),
                        Text('More', style: AppText.body(11, color: Tokens.textSecondary)),
                      ],
                    ),
                  ],
                )
              : const EmptyState(message: _emptyLine, compact: true),
        ),
      ],
    );
  }
}

class _TimingSection extends ConsumerWidget {
  const _TimingSection({required this.range});
  final DateRange range;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(insightsRepositoryProvider);
    final use24h = ref.watch(settingsProvider.select((s) => s.use24h));
    final (on, late) = repo.onTime(range);
    final byHour = repo.completionsByHour(range);
    final total = byHour.fold(0, (a, b) => a + b);
    final best = Metrics.bestWindow(byHour);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Timing'),
        AppCard(
          child: total == 0
              ? const EmptyState(message: _emptyLine, compact: true)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StatTile(value: '$on', label: 'on time', color: Tokens.mint, labelColor: Tokens.textSecondary, size: 26),
                        const SizedBox(width: 24),
                        StatTile(value: '$late', label: 'late', labelColor: Tokens.textSecondary, size: 26),
                      ],
                    ),
                    if (on + late > 0) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Row(
                          children: [
                            Expanded(flex: on == 0 ? 0 : on, child: Container(height: 8, color: Tokens.mint)),
                            if (on > 0 && late > 0) const SizedBox(width: 2),
                            Expanded(flex: late == 0 ? 0 : late, child: Container(height: 8, color: Tokens.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (best != null)
                      Text(
                        'You get most done ${Fmt.hour(best, use24h: use24h)}–${Fmt.hour((best + 2) % 24, use24h: use24h)}',
                        style: AppText.bodyL,
                      ),
                    const SizedBox(height: 12),
                    SimpleBarChart(
                      values: [for (final v in byHour) v.toDouble()],
                      labels: [for (var h = 0; h < 24; h++) Fmt.hour(h, use24h: use24h)],
                      labelEvery: 6,
                      color: Tokens.coral,
                      height: 120,
                      semanticsLabel: 'Completions by hour of day',
                      tooltip: (i, v) => '${Fmt.hour(i, use24h: use24h)} · ${v.round()}',
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _FocusSection extends ConsumerWidget {
  const _FocusSection({required this.range});
  final DateRange range;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(insightsRepositoryProvider);
    final today = ref.watch(todayProvider);
    final use24h = ref.watch(settingsProvider.select((s) => s.use24h));
    // Daily bars: the selected range, capped at the most recent 31 days.
    final barsEnd = range.to.isAfter(today) ? today : range.to;
    final barsStart = range.length > 31 ? Days.add(barsEnd, -30) : range.from;
    final bars = DateRange(barsStart, barsEnd);
    final stats = repo.focus(range);
    final daily = repo.focus(bars).minutesByDay;
    final list = bars.days.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Focus'),
        AppCard(
          child: stats.completed + stats.endedEarly == 0
              ? const EmptyState(message: 'Start a focus session and your minutes will gather here.', mood: MascotMood.calm, compact: true)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SimpleBarChart(
                      values: [for (final d in list) daily[d] ?? 0],
                      labels: [for (final d in list) if (list.length <= 7) d.shortWeekday.substring(0, 1) else '${d.day}'],
                      labelEvery: list.length <= 7 ? 1 : 5,
                      color: Tokens.sage,
                      semanticsLabel: 'Focus minutes per day',
                      tooltip: (i, v) => '${list[i].dayMonth} · ${v.round()} min',
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 22,
                      runSpacing: 12,
                      children: [
                        StatTile(value: '${stats.completed}', label: 'completed', color: Tokens.sage, labelColor: Tokens.textSecondary, size: 24),
                        StatTile(value: '${stats.endedEarly}', label: 'ended early', labelColor: Tokens.textSecondary, size: 24),
                        StatTile(value: stats.averageMinutes.round().toString(), label: 'avg min', labelColor: Tokens.textSecondary, size: 24),
                        if (stats.bestHour != null)
                          StatTile(
                            value: Fmt.hour(stats.bestHour!, use24h: use24h),
                            label: 'best hour',
                            labelColor: Tokens.textSecondary,
                            size: 24,
                          ),
                      ],
                    ),
                    if (stats.minutesByTask.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text('MINUTES BY LINKED TASK', style: AppText.bodyS),
                      const SizedBox(height: 8),
                      for (final e in stats.minutesByTask.take(5))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(child: Text(repo.taskTitle(e.key), style: AppText.bodyM, overflow: TextOverflow.ellipsis)),
                              Text('${e.value.round()} min', style: AppText.mono(13, color: Tokens.sage)),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _CategorySection extends ConsumerWidget {
  const _CategorySection({required this.range});
  final DateRange range;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(insightsRepositoryProvider).byCategory(range);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('By category'),
        AppCard(
          child: entries.isEmpty
              ? const EmptyState(message: _emptyLine, compact: true)
              : CategoryDonut(entries: entries),
        ),
      ],
    );
  }
}
