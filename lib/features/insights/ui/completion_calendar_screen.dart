import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poora/core/providers.dart';
import 'package:poora/core/theme/motion.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';
import 'package:poora/core/time/date_utils.dart';
import 'package:poora/core/widgets/pill_chip.dart';
import 'package:poora/core/widgets/round_icon_button.dart';
import 'package:poora/core/widgets/stat_tile.dart';
import 'package:poora/features/insights/data/insights_repository.dart';
import 'package:poora/features/insights/domain/metrics.dart';
import 'package:poora/features/insights/ui/completion_calendar.dart';
import 'package:poora/features/tasks/domain/recurrence.dart';

class CompletionCalendarScreen extends ConsumerStatefulWidget {
  const CompletionCalendarScreen({this.initialDay, this.initialFilter, super.key});

  final DateTime? initialDay;
  final String? initialFilter;

  @override
  ConsumerState<CompletionCalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CompletionCalendarScreen> {
  static const _origin = 1200; // page index of the current month
  late final DateTime _base = Days.monthStart(ref.read(todayProvider));
  late final PageController _pages;
  late DateTime _month;
  late CalendarFilter _filter = CalendarFilter.decode(widget.initialFilter);
  bool _year = false;

  @override
  void initState() {
    super.initState();
    final start = widget.initialDay ?? _base;
    _month = Days.monthStart(start);
    _pages = PageController(initialPage: _origin + _monthsBetween(_base, _month));
    final day = widget.initialDay;
    if (day != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !day.isAfter(ref.read(todayProvider))) showDayDetailSheet(context, day);
      });
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  int _monthsBetween(DateTime a, DateTime b) => (b.year - a.year) * 12 + b.month - a.month;
  DateTime _monthAt(int page) => DateTime.utc(_base.year, _base.month + page - _origin);

  void _go(int delta) => _pages.animateToPage(
    _pages.page!.round() + delta,
    duration: Motion.of(context),
    curve: Motion.curve,
  );

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(insightsRepositoryProvider);
    final range = DateRange.month(_month);
    final days = repo.dayCompletion(range, filter: _filter);
    final perfect = days.values.where((d) => d.isPerfect).length;
    final partial = days.values.where((d) => const {DayTier.high, DayTier.mid, DayTier.low}.contains(d.tier)).length;
    final missed = days.values.where((d) => d.tier == DayTier.missed).length;
    final done = days.values.fold(0, (a, d) => a + d.done);
    final scheduled = days.values.fold(0, (a, d) => a + (d.tier == DayTier.today ? 0 : d.scheduled));
    final doneExclToday = days.values.fold(0, (a, d) => a + (d.tier == DayTier.today ? 0 : d.done));
    final rate = scheduled == 0 ? null : (doneExclToday / scheduled * 100).round();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.side, Space.m, Space.side, Space.x4),
          children: [
            Row(
              children: [
                RoundIconButton(
                  icon: Icons.arrow_back_rounded,
                  semanticLabel: 'Back',
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      _year ? 'THE YEAR' : '${monthLong[_month.month - 1]} ${_month.year}'.toUpperCase(),
                      style: AppText.h2,
                    ),
                  ),
                ),
                if (!_year) ...[
                  RoundIconButton(icon: Icons.chevron_left_rounded, semanticLabel: 'Previous month', onTap: () => _go(-1)),
                  RoundIconButton(icon: Icons.chevron_right_rounded, semanticLabel: 'Next month', onTap: () => _go(1)),
                ],
              ],
            ),
            const SizedBox(height: Space.l),
            Row(
              children: [
                _Segmented(year: _year, onChanged: (y) => setState(() => _year = y)),
                const Spacer(),
                _FilterPill(filter: _filter, onChanged: (f) => setState(() => _filter = f)),
              ],
            ),
            const SizedBox(height: Space.xl),
            if (_year)
              CompletionYearGrid(
                filter: _filter,
                onDayTap: (d) {
                  setState(() {
                    _year = false;
                    _month = Days.monthStart(d);
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _pages.jumpToPage(_origin + _monthsBetween(_base, _month));
                    showDayDetailSheet(context, d);
                  });
                },
              )
            else
              SizedBox(
                height: 6 * 52 + 24,
                child: PageView.builder(
                  controller: _pages,
                  onPageChanged: (p) => setState(() => _month = _monthAt(p)),
                  itemBuilder: (context, p) => Align(
                    alignment: Alignment.topCenter,
                    child: CompletionMonthGrid(
                      month: _monthAt(p),
                      filter: _filter,
                      onDayTap: (d) => showDayDetailSheet(context, d),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: Space.l),
            if (!_year) ...[
              Wrap(
                spacing: 20,
                runSpacing: 14,
                children: [
                  StatTile(value: '$perfect', label: 'perfect', color: Tokens.dayPerfect, labelColor: Tokens.textSecondary, size: 26),
                  StatTile(value: '$partial', label: 'partial', size: 26, labelColor: Tokens.textSecondary),
                  StatTile(value: '$missed', label: 'missed', size: 26, labelColor: Tokens.textSecondary),
                  StatTile(value: rate == null ? '–' : '$rate%', label: 'month rate', size: 26, labelColor: Tokens.textSecondary),
                  StatTile(
                    value: '${repo.bestPerfectRun(range, filter: _filter)}',
                    label: 'best streak',
                    size: 26,
                    labelColor: Tokens.textSecondary,
                  ),
                ],
              ),
              if (done == 0 && scheduled == 0)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text('No tasks this month yet.', style: AppText.bodyS),
                ),
              const SizedBox(height: Space.l),
            ],
            const TierLegend(),
          ],
        ),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({required this.year, required this.onChanged});
  final bool year;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: Tokens.surface, borderRadius: BorderRadius.circular(Radii.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (v, label) in [(false, 'Month'), (true, 'Year')])
            Semantics(
              button: true,
              selected: year == v,
              child: GestureDetector(
                onTap: () => onChanged(v),
                child: AnimatedContainer(
                  duration: Motion.of(context, Motion.fast),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: year == v ? Tokens.periwinkle : Colors.transparent,
                    borderRadius: BorderRadius.circular(Radii.pill),
                  ),
                  child: Text(label, style: AppText.label),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterPill extends ConsumerWidget {
  const _FilterPill({required this.filter, required this.onChanged});
  final CalendarFilter filter;
  final ValueChanged<CalendarFilter> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(insightsRepositoryProvider);
    final series = repo.recurringSeries();
    final label = filter.tag ??
        (filter.seriesId == null ? 'All tasks' : repo.seriesTask(filter.seriesId!)?.title ?? 'Task');
    return PillChip(
      label: label,
      trailingIcon: Icons.expand_more_rounded,
      onTap: () async {
        final picked = await showModalBottomSheet<CalendarFilter>(
          context: context,
          isScrollControlled: true,
          builder: (c) => SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(c).height * 0.7),
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    title: Text('All tasks', style: AppText.bodyL),
                    onTap: () => Navigator.pop(c, const CalendarFilter.all()),
                  ),
                  if (repo.tags().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text('TAGS', style: AppText.bodyS),
                    ),
                  for (final t in repo.tags())
                    ListTile(
                      leading: const Icon(Icons.sell_outlined, color: Tokens.textSecondary),
                      title: Text(t, style: AppText.bodyL),
                      onTap: () => Navigator.pop(c, CalendarFilter.tag(t)),
                    ),
                  if (series.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text('RECURRING TASKS', style: AppText.bodyS),
                    ),
                  for (final s in series)
                    ListTile(
                      leading: CircleAvatar(radius: 6, backgroundColor: Color(s.task.color)),
                      title: Text(s.task.title, style: AppText.bodyL),
                      onTap: () => Navigator.pop(c, CalendarFilter.series(s.seriesId)),
                    ),
                ],
              ),
            ),
          ),
        );
        if (picked != null) onChanged(picked);
      },
    );
  }
}
