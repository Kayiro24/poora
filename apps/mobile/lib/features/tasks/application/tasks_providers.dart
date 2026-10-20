import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poora/core/providers.dart';
import 'package:poora/core/time/date_utils.dart';
import 'package:poora/features/settings/settings_controller.dart';
import 'package:poora/features/tasks/data/tasks_repository.dart';
import 'package:poora/features/tasks/domain/models.dart';
import 'package:poora/features/tasks/domain/occurrence_generator.dart';

final taskSnapshotProvider = StreamProvider<TaskSnapshot>(
  (ref) => ref.watch(tasksDaoProvider).watchSnapshot(),
);

final generatorProvider = Provider<OccurrenceGenerator>(
  (ref) => OccurrenceGenerator(
    mondayFirst: ref.watch(settingsProvider.select((s) => s.mondayFirst)),
  ),
);

final tasksRepositoryProvider = Provider(
  (ref) => TasksRepository(
    dao: ref.watch(tasksDaoProvider),
    clock: ref.watch(clockProvider),
    generator: () => ref.read(generatorProvider),
  ),
);

/// Occurrences for any visible range, generated on the fly and merged with
/// records. Recomputes whenever tasks, records, today or week-start change.
final occurrencesProvider = Provider.family<List<Occurrence>, DateRange>((
  ref,
  range,
) {
  final snapshot = ref.watch(taskSnapshotProvider).value ?? TaskSnapshot.empty;
  final today = ref.watch(todayProvider);
  return ref
      .watch(generatorProvider)
      .generate(snapshot: snapshot, range: range, today: today);
});

final todayOccurrencesProvider = Provider<List<Occurrence>>((ref) {
  final today = ref.watch(todayProvider);
  return ref.watch(occurrencesProvider(DateRange.day(today)));
});

/// True while the first snapshot is still loading.
final tasksLoadingProvider = Provider<bool>(
  (ref) => ref.watch(taskSnapshotProvider).isLoading,
);

/// Overdue = today's timed tasks past their end, plus anything missed
/// yesterday. Drives the bell dot on Home.
final hasOverdueProvider = Provider<bool>((ref) {
  final now = ref.watch(nowProvider).value ?? DateTime.now();
  final today = ref.watch(todayProvider);
  final occ = ref.watch(
    occurrencesProvider(DateRange(Days.add(today, -1), today)),
  );
  return occ.any(
    (o) =>
        o.status == OccurrenceStatus.missed ||
        (o.status == OccurrenceStatus.pending &&
            o.endAt != null &&
            o.endAt!.isBefore(now)),
  );
});
