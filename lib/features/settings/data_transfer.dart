import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:poora/core/app_info.dart';
import 'package:poora/core/db/database.dart';

/// JSON export/import of every table (Settings → Export / Import).
class DataTransfer {
  DataTransfer(this.db);
  final AppDatabase db;

  static const format = 1;

  Future<Map<String, Object?>> exportMap() async => {
    'app': AppInfo.name,
    'format': format,
    'exportedAt': DateTime.now().toIso8601String(),
    'tasks': [for (final r in await db.select(db.tasks).get()) r.toJson()],
    'taskReminders': [for (final r in await db.select(db.taskReminders).get()) r.toJson()],
    'occurrenceRecords': [for (final r in await db.select(db.occurrenceRecords).get()) r.toJson()],
    'focusSessions': [for (final r in await db.select(db.focusSessions).get()) r.toJson()],
    'presets': [for (final r in await db.select(db.presets).get()) r.toJson()],
    'settings': [for (final r in await db.select(db.settings).get()) r.toJson()],
  };

  /// Writes the export to a temp file and returns its path.
  Future<String> exportFile() async {
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().substring(0, 10);
    final file = File(p.join(dir.path, '${AppInfo.name.toLowerCase()}-export-$stamp.json'));
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(await exportMap()));
    return file.path;
  }

  /// Replaces all data with [json]. Throws [FormatException] on bad input;
  /// nothing is changed unless the whole import succeeds.
  Future<void> importJson(String json) async {
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException {
      throw const FormatException('This file isn’t valid JSON.');
    }
    if (decoded is! Map<String, Object?> || decoded['format'] != format) {
      throw const FormatException('This doesn’t look like a ${AppInfo.name} export.');
    }
    List<Map<String, dynamic>> rows(String key) =>
        ((decoded! as Map<String, Object?>)[key] as List? ?? const []).cast<Map<String, dynamic>>();

    await db.transaction(() async {
      await db.deleteEverything();
      for (final j in rows('tasks')) {
        await db.into(db.tasks).insert(TaskRow.fromJson(j));
      }
      for (final j in rows('taskReminders')) {
        await db.into(db.taskReminders).insert(TaskReminderRow.fromJson(j));
      }
      for (final j in rows('occurrenceRecords')) {
        await db.into(db.occurrenceRecords).insert(OccurrenceRecordRow.fromJson(j));
      }
      for (final j in rows('focusSessions')) {
        await db.into(db.focusSessions).insert(FocusSessionRow.fromJson(j));
      }
      for (final j in rows('presets')) {
        await db.into(db.presets).insert(PresetRow.fromJson(j));
      }
      for (final j in rows('settings')) {
        await db.into(db.settings).insert(SettingRow.fromJson(j));
      }
    });
  }
}
