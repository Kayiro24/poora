import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poora/core/providers.dart';
import 'package:poora/core/theme/motion.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';
import 'package:poora/core/time/date_utils.dart';
import 'package:poora/features/settings/settings_controller.dart';
import 'package:poora/features/tasks/application/tasks_providers.dart';
import 'package:poora/features/tasks/application/tasks_view.dart';
import 'package:poora/features/tasks/domain/recurrence.dart';

/// Mon–Sun strip with dots for days that have tasks. Swipe to change week,
/// tap to jump.
class WeekStrip extends ConsumerWidget {
  const WeekStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(tasksViewProvider);
    final mondayFirst = ref.watch(settingsProvider.select((s) => s.mondayFirst));
    final today = ref.watch(todayProvider);
    final week = DateRange.week(view.selected, mondayFirst: mondayFirst);
    final occ = ref.watch(occurrencesProvider(week));
    final busy = {for (final o in occ) o.date};
    final ctrl = ref.read(tasksViewProvider.notifier);

    return GestureDetector(
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v.abs() < 200) return;
        ctrl.select(Days.add(view.selected, v < 0 ? 7 : -7));
      },
      child: Container(
        color: Tokens.bg,
        padding: const EdgeInsets.fromLTRB(Space.side - 4, 8, Space.side - 4, 8),
        child: Row(
          children: [
            for (final d in week.days)
              Expanded(
                child: _DayCell(
                  day: d,
                  selected: Days.same(d, view.selected),
                  today: Days.same(d, today),
                  busy: busy.contains(d),
                  onTap: () {
                    ref.read(feedbackProvider).selection();
                    ctrl.select(d);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.selected,
    required this.today,
    required this.busy,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool today;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Tokens.textInverse : Tokens.textPrimary;
    return Semantics(
      button: true,
      selected: selected,
      label: '${weekdayLong[day.weekday - 1]} ${day.day}${busy ? ', has tasks' : ''}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.of(context, Motion.fast),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Tokens.coral : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: today && !selected ? Border.all(color: Tokens.ice) : null,
          ),
          child: Column(
            children: [
              Text(
                day.shortWeekday.substring(0, 1),
                style: AppText.body(11, weight: FontWeight.w500, color: selected ? fg : Tokens.textSecondary),
              ),
              const SizedBox(height: 4),
              Text('${day.day}', style: AppText.mono(16, color: fg)),
              const SizedBox(height: 4),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: busy ? (selected ? Tokens.textInverse : Tokens.coral) : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
