import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';
import 'package:poora/core/widgets/common.dart';
import 'package:poora/core/widgets/mascot.dart';
import 'package:poora/core/widgets/screen_header.dart';
import 'package:poora/features/tasks/application/tasks_providers.dart';
import 'package:poora/features/tasks/data/tasks_repository.dart';
import 'package:poora/features/tasks/domain/recurrence.dart';

/// Trash: deleted tasks are kept 30 days (like Google Calendar), then purged.
class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trashed = ref.watch(trashedTasksProvider).value ?? const [];
    final repo = ref.read(tasksRepositoryProvider);
    final now = DateTime.now();
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.side, Space.m, Space.side, Space.x4),
          children: [
            ScreenHeader(
              title: 'Trash',
              size: 32,
              onBack: () => Navigator.pop(context),
              trailing: [
                if (trashed.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('EMPTY TRASH?'),
                          content: Text('${trashed.length} task${trashed.length == 1 ? '' : 's'} will be deleted forever.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                            TextButton(
                              onPressed: () => Navigator.pop(c, true),
                              child: Text('Empty', style: AppText.label.copyWith(color: Tokens.coralSoft)),
                            ),
                          ],
                        ),
                      );
                      if (ok ?? false) await repo.emptyTrash();
                    },
                    child: Text('Empty', style: AppText.label.copyWith(color: Tokens.coralSoft)),
                  ),
              ],
            ),
            const SizedBox(height: Space.s),
            Text(
              'Deleted tasks stay here for ${TasksRepository.trashDays} days, then they’re removed for good.',
              style: AppText.body(14, color: Tokens.textSecondary),
            ),
            const SizedBox(height: Space.xl),
            if (trashed.isEmpty)
              const EmptyState(message: 'Trash is empty.', mood: MascotMood.calm)
            else
              for (final t in trashed)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(color: Tokens.surface, borderRadius: BorderRadius.circular(Radii.inner)),
                  clipBehavior: Clip.antiAlias,
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(width: 4, color: Color(t.color)),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.title.toUpperCase(), style: AppText.h4, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text(
                                  '${RepeatRule.fromTask(t).summary(t.startDate)} · deleted ${_ago(t.deletedAt!, now)} · '
                                  '${_left(t.deletedAt!, now)} left',
                                  style: AppText.bodyS,
                                ),
                              ],
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => repo.restore(t.id),
                          child: Text('Restore', style: AppText.label.copyWith(color: Tokens.mint)),
                        ),
                        IconButton(
                          tooltip: 'Delete forever',
                          onPressed: () => repo.deleteForever(t.id),
                          icon: const Icon(Icons.delete_forever_rounded, color: Tokens.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  static String _ago(DateTime d, DateTime now) {
    final days = now.difference(d).inDays;
    return days == 0
        ? 'today'
        : days == 1
        ? 'yesterday'
        : '$days days ago';
  }

  static String _left(DateTime d, DateTime now) {
    final left = TasksRepository.trashDays - now.difference(d).inDays;
    return left <= 1 ? '1 day' : '$left days';
  }
}
