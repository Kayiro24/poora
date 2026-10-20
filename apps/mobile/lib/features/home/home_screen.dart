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
import 'package:poora/core/widgets/mono_badge.dart';
import 'package:poora/core/widgets/pill_chip.dart';
import 'package:poora/core/widgets/round_icon_button.dart';
import 'package:poora/features/focus/application/focus_controller.dart';
import 'package:poora/features/focus/ui/focus_screen.dart';
import 'package:poora/features/insights/data/insights_repository.dart';
import 'package:poora/features/insights/ui/charts.dart';
import 'package:poora/features/settings/settings_controller.dart';
import 'package:poora/features/tasks/application/tasks_providers.dart';
import 'package:poora/features/tasks/application/tasks_view.dart';
import 'package:poora/features/tasks/domain/models.dart';
import 'package:poora/features/tasks/domain/recurrence.dart';
import 'package:poora/features/tasks/ui/task_actions.dart';
import 'package:poora/features/tasks/ui/task_card.dart';

/// Dashboard day (the selector pill switches the whole dashboard).
final homeDayProvider = NotifierProvider<_HomeDay, DateTime?>(_HomeDay.new);

class _HomeDay extends Notifier<DateTime?> {
  @override
  DateTime? build() => null; // null = follow today
  void set(DateTime? d) => state = d;
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final day = ref.watch(homeDayProvider) ?? today;
    final name = ref.watch(settingsProvider.select((s) => s.name));
    final overdue = ref.watch(hasOverdueProvider);
    final isToday = Days.same(day, today);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            Space.side,
            Space.m,
            Space.side,
            FloatingNavBar.reservedHeight(context),
          ),
          children: [
            Row(
              children: [
                Semantics(
                  button: true,
                  label: 'Settings',
                  child: GestureDetector(
                    onTap: () => context.push(Routes.settings),
                    child: Container(
                      width: 48,
                      height: 48,
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Tokens.surfaceHigh,
                        shape: BoxShape.circle,
                      ),
                      child: const Mascot(mood: MascotMood.happy, size: 40),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name.trim().isEmpty
                        ? 'HI THERE'
                        : 'HI, ${name.trim().toUpperCase()}',
                    style: AppText.h3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                RoundIconButton(
                  icon: Icons.search_rounded,
                  semanticLabel: 'Search tasks',
                  onTap: () {
                    ref
                        .read(tasksViewProvider.notifier)
                        .setView(TaskView.schedule);
                    context.go(Routes.tasks);
                  },
                ),
                RoundIconButton(
                  icon: Icons.notifications_none_rounded,
                  semanticLabel: overdue ? 'Overdue tasks' : 'Notifications',
                  badge: overdue,
                  onTap: () {
                    ref.read(tasksViewProvider.notifier)
                      ..setView(TaskView.schedule)
                      ..select(Days.add(today, -1));
                    context.go(Routes.tasks);
                  },
                ),
              ],
            ),
            const SizedBox(height: Space.l),
            Align(
              alignment: Alignment.centerLeft,
              child: PillChip(
                label:
                    '${isToday ? 'Today' : day.shortWeekday}, ${day.shortWeekday} ${day.dayMonth}',
                trailingIcon: Icons.expand_more_rounded,
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime(day.year, day.month, day.day),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (d != null) {
                    ref
                        .read(homeDayProvider.notifier)
                        .set(Days.same(d, today) ? null : Days.of(d));
                  }
                },
              ),
            ),
            const SizedBox(height: Space.l),
            _NextUp(day: day),
            const SizedBox(height: Space.m),
            const _QuickStart(),
            const SizedBox(height: Space.m),
            _ThisWeek(day: day),
          ],
        ),
      ),
    );
  }
}

class _NextUp extends ConsumerWidget {
  const _NextUp({required this.day});
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final occ = ref.watch(occurrencesProvider(DateRange.day(day)));
    final use24h = ref.watch(settingsProvider.select((s) => s.use24h));
    final isToday = Days.same(day, today);
    final now = ref.watch(secondTickerProvider).value ?? DateTime.now();
    final open = occ
        .where((o) => o.status == OccurrenceStatus.pending)
        .toList();
    // Next = first timed task not yet ended, else the first open all-day one.
    Occurrence? next;
    for (final o in open) {
      if (o.isTimed && (!isToday || o.endAt!.isAfter(now))) {
        next = o;
        break;
      }
    }
    next ??= open.where((o) => !o.isTimed).firstOrNull;

    if (next == null) {
      return AppCard(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Tokens.mint,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.check_rounded, color: Tokens.textInverse),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isToday ? 'ALL CLEAR FOR TODAY' : 'ALL CLEAR',
                    style: AppText.h4,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    occ.isEmpty
                        ? 'Nothing scheduled.'
                        : 'Everything’s done. Enjoy the quiet.',
                    style: AppText.bodyS,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    final o = next;
    final startAt = o.startAt;
    String? countdown;
    if (isToday && startAt != null) {
      countdown = startAt.isAfter(now)
          ? 'starts in ${Fmt.countdown(startAt.difference(now))}'
          : 'ends in ${Fmt.countdown(o.endAt!.difference(now))}';
    }
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
      onTap: () => openEditor(context, occurrence: o),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Tokens.sun,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.wb_sunny_rounded,
              color: Tokens.textInverse,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NEXT UP',
                  style: AppText.body(
                    11,
                    weight: FontWeight.w500,
                    color: Tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  o.title.toUpperCase(),
                  style: AppText.h3,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    occurrenceTimeLabel(o, use24h: use24h),
                    if (o.task.tag != null) o.task.tag!,
                  ].join(' · '),
                  style: AppText.bodyS,
                ),
                if (countdown != null) ...[
                  const SizedBox(height: 10),
                  MonoBadge(countdown),
                ],
              ],
            ),
          ),
          ArrowCircleButton(
            semanticLabel: 'Open ${o.title}',
            onTap: () => openEditor(context, occurrence: o),
          ),
        ],
      ),
    );
  }
}

class _QuickStart extends ConsumerWidget {
  const _QuickStart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final last = ref.watch(settingsProvider.select((s) => s.lastFocus));
    final running = ref.watch(
      focusControllerProvider.select((s) => s.session != null),
    );
    return AccentPanel(
      color: Tokens.sage,
      onTap: running
          ? () => context.push(Routes.focusRun)
          : () => startFocus(ref, context, last),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  running ? 'IN SESSION' : 'START FOCUS',
                  style: AppText.display(32, color: Tokens.textInverse),
                ),
                const SizedBox(height: 4),
                Text(
                  running
                      ? 'Tap to return'
                      : '${last.focusMin} / ${last.shortMin} · last used',
                  style: AppText.mono(14, color: Tokens.textInverse),
                ),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Tokens.bg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              running ? Icons.timer_rounded : Icons.play_arrow_rounded,
              color: Tokens.sage,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThisWeek extends ConsumerStatefulWidget {
  const _ThisWeek({required this.day});
  final DateTime day;

  @override
  ConsumerState<_ThisWeek> createState() => _ThisWeekState();
}

class _ThisWeekState extends ConsumerState<_ThisWeek> {
  bool _last = false;

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(insightsRepositoryProvider);
    final today = ref.watch(todayProvider);
    final week = repo.week(Days.add(widget.day, _last ? -7 : 0));
    final days = repo.dayCompletion(week);
    final list = week.days.toList();
    final firstFuture = list.indexWhere((d) => d.isAfter(today));
    final occ = repo.occurrences(week);
    final colorCounts = <int, int>{};
    for (final o in occ.where((o) => o.isDone)) {
      colorCounts[o.task.color] = (colorCounts[o.task.color] ?? 0) + 1;
    }
    final topColors =
        (colorCounts.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .take(3);

    return AccentPanel(
      color: Tokens.periwinkle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _last ? 'LAST WEEK' : 'THIS WEEK',
                  style: AppText.h3.copyWith(color: Tokens.textInverse),
                ),
              ),
              PopupMenuButton<bool>(
                tooltip: 'Choose week',
                color: Tokens.surfaceHigh,
                onSelected: (v) => setState(() => _last = v),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: false,
                    child: Text('This week', style: AppText.bodyL),
                  ),
                  PopupMenuItem(
                    value: true,
                    child: Text('Last week', style: AppText.bodyL),
                  ),
                ],
                child: IgnorePointer(
                  child: PillChip(
                    label: _last ? 'last week' : 'this week',
                    trailingIcon: Icons.expand_more_rounded,
                    filled: true,
                    color: Tokens.white,
                  ),
                ),
              ),
            ],
          ),
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
            onTap: (p) => context.push(Routes.calendar(day: p.date)),
          ),
          const SizedBox(height: 18),
          if (days.values.every((d) => d.scheduled == 0))
            const EmptyState(
              message: 'Plan a few tasks and your week will take shape here.',
              mood: MascotMood.thinking,
              compact: true,
              color: Tokens.textInverse,
            )
          else
            WeekAreaChart(
              labels: [for (final d in list) d.shortWeekday.substring(0, 1)],
              actual: [for (final d in list) days[d]!.done.toDouble()],
              planned: firstFuture < 0
                  ? null
                  : [
                      for (var i = 0; i < list.length; i++)
                        // Dashed line only from today onward: what's still planned.
                        if (i < firstFuture - 1)
                          double.nan
                        else
                          days[list[i]]!.scheduled.toDouble(),
                    ],
              lastActual: firstFuture < 0 ? null : firstFuture - 1,
              height: 120,
            ),
          if (topColors.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final e in topColors)
                  PillChip(
                    label: '${TaskColors.nameOf(Color(e.key))} · ${e.value}',
                    dense: true,
                    dot: Color(e.key),
                    filled: true,
                    color: Tokens.white,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
