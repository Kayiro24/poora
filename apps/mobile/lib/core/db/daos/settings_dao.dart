import 'package:poora/core/db/database.dart';

/// Key/value settings plus the held-reminder queue.
class SettingsDao {
  SettingsDao(this.db);
  final AppDatabase db;

  Future<Map<String, String>> all() async {
    final rows = await db.select(db.settings).get();
    return {for (final r in rows) r.key: r.value};
  }

  Future<String?> get(String key) =>
      (db.select(db.settings)..where((s) => s.key.equals(key)))
          .getSingleOrNull()
          .then((r) => r?.value);

  Future<void> set(String key, String value) => db
      .into(db.settings)
      .insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));

  Future<void> remove(String key) =>
      (db.delete(db.settings)..where((s) => s.key.equals(key))).go();

  // --- Held reminders (§4.4) ---------------------------------------------

  Future<List<HeldReminderRow>> heldReminders() =>
      db.select(db.heldReminders).get();

  Future<void> hold(HeldReminderRow r) =>
      db.into(db.heldReminders).insertOnConflictUpdate(r);

  Future<void> clearHeld() => db.delete(db.heldReminders).go();
}
