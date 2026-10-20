import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:poora/core/db/tables.dart';

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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement(
        'CREATE INDEX idx_records_task ON occurrence_records (task_id)',
      );
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
