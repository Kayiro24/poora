import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:poora/core/db/database.dart';
import 'package:poora/core/time/date_utils.dart';
import 'package:poora/features/focus/domain/focus_session.dart';
import 'package:poora/features/focus/domain/focus_tracker.dart';
import 'package:poora/features/focus/domain/timer_engine.dart';

class FocusPreset {
  const FocusPreset({
    required this.id,
    required this.name,
    required this.config,
    this.sort = 0,
  });
  final String id;
  final String name;
  final FocusConfig config;
  final int sort;
}

/// Live session snapshot persisted for kill-recovery.
class LiveFocusState {
  const LiveFocusState({required this.sessionId, required this.timer, this.tracking = FocusTracking.empty, this.strict = false});
  final String sessionId;
  final TimerState timer;
  final FocusTracking tracking;
  final bool strict;
}

class FocusDao {
  FocusDao(this.db);
  final AppDatabase db;

  // --- Presets ------------------------------------------------------------

  Stream<List<FocusPreset>> watchPresets() =>
      (db.select(db.presets)..orderBy([(p) => OrderingTerm.asc(p.sort)]))
          .watch()
          .map((rows) => rows.map(_preset).toList());

  Future<void> upsertPreset(FocusPreset p) => db
      .into(db.presets)
      .insertOnConflictUpdate(
        PresetsCompanion.insert(
          id: p.id,
          name: p.name,
          focusMin: p.config.focusMin,
          shortMin: p.config.shortMin,
          longMin: p.config.longMin,
          longEvery: p.config.longEvery,
          sort: Value(p.sort),
        ),
      );

  Future<void> deletePreset(String id) =>
      (db.delete(db.presets)..where((p) => p.id.equals(id))).go();

  static FocusPreset _preset(PresetRow r) => FocusPreset(
    id: r.id,
    name: r.name,
    sort: r.sort,
    config: FocusConfig(
      focusMin: r.focusMin,
      shortMin: r.shortMin,
      longMin: r.longMin,
      longEvery: r.longEvery,
    ),
  );

  // --- Sessions -----------------------------------------------------------

  Stream<List<FocusSessionRecord>> watchSessions() =>
      (db.select(db.focusSessions)
            ..where((s) => s.endedAt.isNotNull())
            ..orderBy([(s) => OrderingTerm.desc(s.startedAt)]))
          .watch()
          .map((rows) => rows.map(sessionFromRow).toList());

  Future<List<FocusSessionRecord>> sessions() =>
      (db.select(db.focusSessions)..where((s) => s.endedAt.isNotNull()))
          .get()
          .then((rows) => rows.map(sessionFromRow).toList());

  Future<FocusSessionRecord?> session(String id) =>
      (db.select(db.focusSessions)..where((s) => s.id.equals(id)))
          .getSingleOrNull()
          .then((r) => r == null ? null : sessionFromRow(r));

  Future<void> upsertSession(FocusSessionRecord s) =>
      db.into(db.focusSessions).insertOnConflictUpdate(sessionToRow(s));

  static FocusSessionRecord sessionFromRow(FocusSessionRow r) =>
      FocusSessionRecord(
        id: r.id,
        startedAt: DateTime.fromMillisecondsSinceEpoch(r.startedAt),
        endedAt: r.endedAt == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(r.endedAt!),
        config: FocusConfig(
          focusMin: r.plannedFocusMin,
          shortMin: r.shortBreakMin,
          longMin: r.longBreakMin,
          longEvery: r.longEvery,
        ),
        focusMsCompleted: r.focusMsCompleted,
        phasesCompleted: r.phasesCompleted,
        endedEarly: r.endedEarly,
        linkedTaskId: r.linkedTaskId,
        linkedOccurrenceDate: r.linkedOccurrenceDate == null
            ? null
            : Days.parse(r.linkedOccurrenceDate!),
        pausedMs: r.pausedMs,
        awayMs: r.awayMs,
        interruptions: r.interruptions,
        distractions: _decodeDistractions(r.distractions),
      );

  static Map<String, int> _decodeDistractions(String? raw) {
    if (raw == null || raw.isEmpty) return const {};
    try {
      return (jsonDecode(raw) as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num).toInt()));
    } on Object {
      return const {};
    }
  }

  static FocusSessionsCompanion sessionToRow(FocusSessionRecord s) =>
      FocusSessionsCompanion.insert(
        id: s.id,
        startedAt: s.startedAt.millisecondsSinceEpoch,
        endedAt: Value(s.endedAt?.millisecondsSinceEpoch),
        plannedFocusMin: s.config.focusMin,
        shortBreakMin: s.config.shortMin,
        longBreakMin: s.config.longMin,
        longEvery: s.config.longEvery,
        focusMsCompleted: Value(s.focusMsCompleted),
        phasesCompleted: Value(s.phasesCompleted),
        endedEarly: Value(s.endedEarly),
        linkedTaskId: Value(s.linkedTaskId),
        linkedOccurrenceDate: Value(
          s.linkedOccurrenceDate == null
              ? null
              : Days.iso(s.linkedOccurrenceDate!),
        ),
        pausedMs: Value(s.pausedMs),
        awayMs: Value(s.awayMs),
        interruptions: Value(s.interruptions),
        distractions: Value(s.distractions.isEmpty ? null : jsonEncode(s.distractions)),
      );

  // --- Live state ---------------------------------------------------------

  Future<LiveFocusState?> liveState() async {
    final r = await db.select(db.focusStates).getSingleOrNull();
    if (r == null) return null;
    DateTime? t(int? ms) =>
        ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
    return LiveFocusState(
      sessionId: r.sessionId,
      timer: TimerState(
        phase: FocusPhase.values.byName(r.phase),
        focusIndex: r.focusIndex,
        phaseStartedAt: t(r.phaseStartedAt),
        phaseDurationMs: r.phaseDurationMs,
        pausedAt: t(r.pausedAt),
        pausedAccumMs: r.pausedAccumMs,
        focusMsCompleted: r.focusMsCompleted,
        phasesCompleted: r.phasesCompleted,
        pausedTotalMs: r.pausedTotalMs,
      ),
      tracking: FocusTracking(
        interruptions: r.interruptions,
        awayMs: r.awayMs,
        awayStartedAt: t(r.awayStartedAt),
        awayCapAt: t(r.awayCapAt),
        lastSeenAt: t(r.lastSeenAt),
      ),
      strict: r.strict,
    );
  }

  Future<void> saveLiveState(String sessionId, TimerState s, FocusTracking tr, {bool strict = false}) => db
      .into(db.focusStates)
      .insertOnConflictUpdate(
        FocusStatesCompanion.insert(
          id: const Value(1),
          sessionId: sessionId,
          phase: s.phase.name,
          focusIndex: s.focusIndex,
          phaseStartedAt: Value(s.phaseStartedAt?.millisecondsSinceEpoch),
          phaseDurationMs: s.phaseDurationMs,
          pausedAt: Value(s.pausedAt?.millisecondsSinceEpoch),
          pausedAccumMs: Value(s.pausedAccumMs),
          focusMsCompleted: Value(s.focusMsCompleted),
          phasesCompleted: Value(s.phasesCompleted),
          pausedTotalMs: Value(s.pausedTotalMs),
          interruptions: Value(tr.interruptions),
          awayMs: Value(tr.awayMs),
          awayStartedAt: Value(tr.awayStartedAt?.millisecondsSinceEpoch),
          awayCapAt: Value(tr.awayCapAt?.millisecondsSinceEpoch),
          lastSeenAt: Value(tr.lastSeenAt?.millisecondsSinceEpoch),
          strict: Value(strict),
        ),
      );

  Future<void> clearLiveState() => db.delete(db.focusStates).go();
}
