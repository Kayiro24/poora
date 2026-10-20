// Cross-device sync contract: the shared sample (also used by the web app's
// src/features/settings/dataTransfer.test.ts) must import and re-export
// unchanged, and read back as the same tasks.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:poora/core/db/daos/settings_dao.dart';
import 'package:poora/core/db/daos/tasks_dao.dart';
import 'package:poora/core/db/database.dart';
import 'package:poora/core/time/date_utils.dart';
import 'package:poora/features/settings/app_settings.dart';
import 'package:poora/features/settings/data_transfer.dart';
import 'package:poora/features/tasks/domain/occurrence_generator.dart';
import 'package:poora/features/tasks/domain/recurrence.dart';

/// Tests run with the working directory at apps/mobile.
final _sample = File('../../shared/export-format/sample-v1.json');
const _tables = [
  'tasks',
  'taskReminders',
  'occurrenceRecords',
  'focusSessions',
  'presets',
  'settings',
];

void main() {
  late AppDatabase db;
  late Map<String, Object?> sample;

  setUp(() {
    db = AppDatabase.memory();
    sample = jsonDecode(_sample.readAsStringSync()) as Map<String, Object?>;
  });
  tearDown(() => db.close());

  test('import → export round-trips every table unchanged', () async {
    final transfer = DataTransfer(db);
    await transfer.importJson(_sample.readAsStringSync());
    final out = jsonDecode(jsonEncode(await transfer.exportMap())) as Map<String, Object?>;
    expect(out['app'], 'Poora');
    expect(out['format'], 1);
    for (final t in _tables) {
      expect(out[t], sample[t], reason: t);
    }
    expect(out.keys.toSet(), sample.keys.toSet());
  });

  test('imported rows read back as the same tasks, rules and settings', () async {
    await DataTransfer(db).importJson(_sample.readAsStringSync());
    final snap = await TasksDao(db).loadSnapshot();
    expect(snap.tasks.map((t) => t.title), ['Morning pages', 'Gym', 'Run', 'File taxes']);
    final gym = snap.tasks.firstWhere((t) => t.title == 'Gym');
    expect(
      RepeatRule.fromTask(gym).summary(gym.startDate),
      'Every 2 weeks on Mon, Wed, Fri, until Dec 31, 2026',
    );
    final run = snap.tasks.firstWhere((t) => t.title == 'Run');
    expect(run.quotaPreferredDays, [2, 4, 6]);
    expect(run.reminders.single.atMinute, 420);
    final s = AppSettings.fromMap(await SettingsDao(db).all());
    expect([s.name, s.chime, s.lastFocus.longEvery, s.onboarded], ['Asha', Chime.softBell, 2, true]);

    final occ = OccurrenceGenerator(mondayFirst: true).generate(
      snapshot: snap,
      range: DateRange(Days.ymd(2026, 10, 12), Days.ymd(2026, 10, 16)),
      today: Days.ymd(2026, 10, 16),
    );
    final moved = occ.firstWhere((o) => o.task.title == 'Gym' && Days.iso(o.originalDate) == '2026-10-14');
    expect([Days.iso(moved.date), moved.startMinute, moved.title], ['2026-10-15', 1140, 'Gym (late slot)']);
    expect(
      occ.any((o) => o.task.title == 'Morning pages' && Days.iso(o.date) == '2026-10-14'),
      isFalse,
    );
  });
}
