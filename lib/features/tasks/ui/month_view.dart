import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poora/core/providers.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';
import 'package:poora/core/time/date_utils.dart';
import 'package:poora/features/insights/data/insights_repository.dart';
import 'package:poora/features/insights/ui/day_cell.dart';
import 'package:poora/features/settings/settings_controller.dart';
import 'package:poora/features/tasks/application/tasks_providers.dart';
import 'package:poora/features/tasks/application/tasks_view.dart';
import 'package:poora/features/tasks/domain/recurrence.dart';

/// Month grid: up to 3 coloured dots per day + "+n". With "Show completion"
/// on, cells show the completion-calendar day states instead (§4.11).
class MonthView extends ConsumerWidget {
  const MonthView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tasksViewProvider);
    final mondayFirst = ref.watch(settingsProvider.select((s) => s.mondayFirst));
    final today = ref.watch(todayProvider);
    final month = DateRange.month(state.selected);
    final gridStart = Days.weekStart(month.from, mondayFirst: mondayFirst);
    final weeks = ((Days.between(gridStart, month.to) + 1) / 7).ceil();
    final grid = DateRange(gridStart, Days.add(gridStart, weeks * 7 - 1));
    final occ = ref.watch(occurrencesProvider(grid));
    final byDay = <DateTime, List<int>>{};
    for (final o in occ) {
      (byDay[o.date] ??= []).add(o.task.color);
    }
    final completion = state.showCompletion
        ? ref.watch(insightsRepositoryProvider).dayCompletion(grid)
        : null;
    final names = [for (var i = 0; i < 7; i++) weekdayLetters[(i + (mondayFirst ? 0 : 6)) % 7]];
    final ctrl = ref.read(tasksViewProvider.notifier);

    return GestureDetector(
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v.abs() > 200) ctrl.page(v < 0 ? 1 : -1);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.side - 4),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '${monthLong[month.from.month - 1]} ${month.from.year}'.toUpperCase(),
                style: AppText.h3,
              ),
            ),
            Row(
              children: [
                for (final n in names)
                  Expanded(
                    child: Center(child: Text(n, style: AppText.body(12, color: Tokens.textSecondary))),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            for (var w = 0; w < weeks; w++)
              Row(
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: () {
                        final d = Days.add(gridStart, w * 7 + i);
                        final inMonth = d.month == month.from.month;
                        void open() {
                          ctrl
                            ..select(d)
                            ..setView(TaskView.day);
                        }

                        if (completion != null) {
                          return Opacity(
                            opacity: inMonth ? 1 : 0.35,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: DayCell(completion: completion[d]!, isToday: Days.same(d, today), onTap: open),
                            ),
                          );
                        }
                        return _PlainCell(
                          day: d,
                          inMonth: inMonth,
                          today: Days.same(d, today),
                          selected: Days.same(d, state.selected),
                          colors: byDay[d] ?? const [],
                          onTap: open,
                        );
                      }(),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PlainCell extends StatelessWidget {
  const _PlainCell({
    required this.day,
    required this.inMonth,
    required this.today,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final DateTime day;
  final bool inMonth;
  final bool today;
  final bool selected;
  final List<int> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final extra = colors.length - 3;
    return Semantics(
      button: true,
      label: '${day.day} ${day.monthShort}, ${colors.length} tasks',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 64,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: selected ? Tokens.surfaceHigh : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: today ? Border.all(color: Tokens.ice) : null,
          ),
          child: Opacity(
            opacity: inMonth ? 1 : 0.35,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${day.day}', style: AppText.mono(14, color: today ? Tokens.ice : Tokens.textPrimary)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final c in colors.take(3))
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(color: Color(c), shape: BoxShape.circle),
                      ),
                  ],
                ),
                if (extra > 0) Text('+$extra', style: AppText.mono(9, color: Tokens.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
