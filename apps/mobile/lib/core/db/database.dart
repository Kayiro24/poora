import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:poora/core/db/tables.dart';
import 'package:poora/core/theme/tokens.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Tasks,
    TaskReminders,
    OccurrenceRecords,
    FocusSessions,
    FocusStates,
    Presets,
    HeldReminders,
    Settings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// In-memory database for tests.
  factory AppDatabase.memory() => AppDatabase(NativeDatabase.memory());

  /// Opens the database file directly — also usable from the notification
  /// background isolate, which has no plugin access.
  factory AppDatabase.atPath(String path) =>
      AppDatabase(NativeDatabase(File(path)));

  static const fileName = 'poora.sqlite';

  static Future<String> defaultPath() async {
    final dir = await getApplicationSupportDirectory();
    return p.join(dir.path, fileName);
  }

  static Future<AppDatabase> open() async {
    final path = await defaultPath();
    return AppDatabase(NativeDatabase.createInBackground(File(path)));
  }

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement(
        'CREATE INDEX idx_records_task ON occurrence_records (task_id)',
      );
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // Focus tracking: interruptions, away/paused time, distracting apps.
        await m.addColumn(focusSessions, focusSessions.pausedMs);
        await m.addColumn(focusSessions, focusSessions.awayMs);
        await m.addColumn(focusSessions, focusSessions.interruptions);
        await m.addColumn(focusSessions, focusSessions.distractions);
        await m.addColumn(focusStates, focusStates.pausedTotalMs);
        await m.addColumn(focusStates, focusStates.interruptions);
        await m.addColumn(focusStates, focusStates.awayMs);
        await m.addColumn(focusStates, focusStates.awayStartedAt);
        await m.addColumn(focusStates, focusStates.awayCapAt);
        await m.addColumn(focusStates, focusStates.lastSeenAt);
      }
      if (from < 3) {
        await m.addColumn(focusStates, focusStates.strict);
        // Palette shade shift: move tasks on old swatches to the new ones.
        for (final e in TaskColors.legacy.entries) {
          await customStatement('UPDATE tasks SET color = ? WHERE color = ?', [e.value, e.key]);
        }
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Wipes every user table (Settings → Delete all data).
  Future<void> deleteEverything() => transaction(() async {
    for (final t in allTables) {
      await delete(t).go();
    }
  });
}
