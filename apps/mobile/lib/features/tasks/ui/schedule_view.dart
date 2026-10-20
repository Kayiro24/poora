import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poora/core/providers.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';
import 'package:poora/core/time/date_utils.dart';
import 'package:poora/core/widgets/common.dart';
import 'package:poora/features/tasks/application/tasks_providers.dart';
import 'package:poora/features/tasks/application/tasks_view.dart';
import 'package:poora/features/tasks/domain/models.dart';
import 'package:poora/features/tasks/domain/recurrence.dart';
import 'package:poora/features/tasks/ui/task_card.dart';

/// Search field shown at the top of the Schedule view.
class ScheduleSearch extends ConsumerStatefulWidget {
  const ScheduleSearch({super.key});

  @override
  ConsumerState<ScheduleSearch> createState() => _ScheduleSearchState();
}

class _ScheduleSearchState extends ConsumerState<ScheduleSearch> {
  late final _c = TextEditingController(text: ref.read(tasksViewProvider).query);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.side, 4, Space.side, 8),
      child: TextField(
        controller: _c,
        onChanged: ref.read(tasksViewProvider.notifier).search,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search tasks',
          prefixIcon: const Icon(Icons.search_rounded, color: Tokens.textSecondary),
          suffixIcon: _c.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    _c.clear();
                    ref.read(tasksViewProvider.notifier).search('');
                  },
                ),
        ),
      ),
    );
  }
}

/// Agenda list grouped by day with sticky day headers (Google Calendar's
/// Schedule view). Returns slivers.
class ScheduleSlivers extends ConsumerWidget {
  const ScheduleSlivers({super.key});

  static const _window = 60;
  static const _searchWindow = 365;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tasksViewProvider);
    final today = ref.watch(todayProvider);
    final q = state.query.trim().toLowerCase();
    final from = q.isEmpty ? state.selected : Days.add(today, -_searchWindow);
    final to = Days.add(q.isEmpty ? state.selected : today, q.isEmpty ? _window : _searchWindow);
    var occ = ref.watch(occurrencesProvider(DateRange(from, to)));
    if (q.isNotEmpty) {
      occ = occ
          .where(
            (o) =>
                o.title.toLowerCase().contains(q) ||
                (o.task.tag?.toLowerCase().contains(q) ?? false) ||
                (o.task.notes?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }
    final groups = <DateTime, List<Occurrence>>{};
    for (final o in occ) {
      (groups[o.date] ??= []).add(o);
    }
    if (groups.isEmpty) {
      return SliverToBoxAdapter(
        child: EmptyState(
          message: q.isEmpty ? 'Nothing scheduled in the next two months.' : 'No tasks match “${state.query}”.',
        ),
      );
    }
    return SliverMainAxisGroup(
      slivers: [
        for (final e in groups.entries)
          SliverMainAxisGroup(
            slivers: [
              SliverPersistentHeader(pinned: true, delegate: _DayHeader(e.key, today)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(Space.side, 0, Space.side, Space.l),
                sliver: SliverList.separated(
                  itemCount: e.value.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => TaskCard(occurrence: e.value[i]),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _DayHeader extends SliverPersistentHeaderDelegate {
  _DayHeader(this.day, this.today);
  final DateTime day;
  final DateTime today;

  @override
  double get minExtent => 40;
  @override
  double get maxExtent => 40;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isToday = Days.same(day, today);
    final label = isToday
        ? 'TODAY · ${day.dayMonth}'
        : Days.same(day, Days.add(today, 1))
        ? 'TOMORROW · ${day.dayMonth}'
        : '${day.shortWeekday} ${day.dayMonth}'.toUpperCase();
    return Container(
      color: Tokens.bg,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: Space.side),
      child: Text(label, style: AppText.display(18, color: isToday ? Tokens.ice : Tokens.textSecondary)),
    );
  }

  @override
  bool shouldRebuild(_DayHeader old) => old.day != day || old.today != today;
}
