import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poora/core/db/database.dart';
import 'package:poora/core/providers.dart';
import 'package:poora/features/focus/application/focus_controller.dart';
import 'package:poora/features/focus/domain/timer_engine.dart';
import 'package:poora/features/settings/data_reset.dart';
import 'package:poora/features/settings/settings_controller.dart';

void main() {
  test('Delete all data empties every table and restores first-run settings', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(container.dispose);

    // Seed: a task with a reminder and a completion, a preset, settings and a
    // live focus session (which also writes focus_state + a session row).
    await db.into(db.tasks).insert(
      TasksCompanion.insert(
        id: 't1',
        title: 'Read',
        color: 0xFFF2705E,
        startDate: '2026-10-20',
        seriesId: 't1',
        createdAt: 0,
        updatedAt: 0,
      ),
    );
    await db.into(db.taskReminders).insert(
      TaskRemindersCompanion.insert(id: 'r1', taskId: 't1', offsetMin: -10),
    );
    await db.into(db.occurrenceRecords).insert(
      OccurrenceRecordsCompanion.insert(
        id: 'o1',
        taskId: 't1',
        occurrenceDate: '2026-10-20',
        status: const Value('done'),
      ),
    );
    await db.into(db.presets).insert(
      PresetsCompanion.insert(id: 'p1', name: 'Deep', focusMin: 50, shortMin: 10, longMin: 30, longEvery: 3),
    );
    await container
        .read(settingsProvider.notifier)
        .update((s) => s.copyWith(name: 'Asha', onboarded: true, use24h: true));
    await container.read(focusControllerProvider.notifier).start(const FocusConfig());
    expect(container.read(focusControllerProvider).session, isNotNull);

    await container.read(dataResetProvider).run();

    for (final table in db.allTables) {
      expect(await db.select(table).get(), isEmpty, reason: '${table.actualTableName} not empty');
    }
    final s = container.read(settingsProvider);
    expect(s.name, '');
    expect(s.onboarded, isFalse);
    expect(s.use24h, isFalse);
    expect(container.read(focusControllerProvider).session, isNull);
    expect(container.read(reminderSchedulerProvider).holdUntil, isNull);
  });
}
