import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poora/core/db/daos/focus_dao.dart';
import 'package:poora/core/platform/dnd_service.dart';
import 'package:poora/core/providers.dart';
import 'package:poora/core/time/date_utils.dart';
import 'package:poora/features/focus/domain/focus_session.dart';
import 'package:poora/features/focus/domain/focus_tracker.dart';
import 'package:poora/features/focus/domain/timer_engine.dart';
import 'package:poora/features/settings/settings_controller.dart';
import 'package:uuid/uuid.dart';

/// Live session as the UI sees it.
class FocusSession {
  const FocusSession({
    required this.id,
    required this.config,
    required this.timer,
    required this.startedAt,
    this.linkedTaskId,
    this.linkedDate,
    this.tracking = FocusTracking.empty,
    this.strict = false,
  });

  final String id;
  final FocusConfig config;
  final TimerState timer;
  final DateTime startedAt;
  final String? linkedTaskId;
  final DateTime? linkedDate;

  /// Interruptions and time away (Regain-style tracking).
  final FocusTracking tracking;

  /// Strict mode: a started focus phase can't be paused, skipped or ended.
  final bool strict;

  /// True while strict mode holds: a focus phase has started and isn't over.
  bool get locked => strict && timer.isFocus && timer.phaseStartedAt != null && !timer.cycleComplete;

  FocusSession withTimer(TimerState t) => _copy(timer: t);
  FocusSession withTracking(FocusTracking t) => _copy(tracking: t);

  FocusSession _copy({TimerState? timer, FocusTracking? tracking}) => FocusSession(
    id: id,
    config: config,
    timer: timer ?? this.timer,
    startedAt: startedAt,
    linkedTaskId: linkedTaskId,
    linkedDate: linkedDate,
    tracking: tracking ?? this.tracking,
    strict: strict,
  );
}

class FocusSummary {
  const FocusSummary({
    required this.focusMinutes,
    required this.sessionsCompleted,
    required this.endedEarly,
    this.linkedTaskId,
    this.linkedDate,
    this.pausedMs = 0,
    this.awayMs = 0,
    this.interruptions = 0,
    this.appUsageMs = 0,
    this.distractions = const {},
  });

  final int focusMinutes;
  final int sessionsCompleted;
  final bool endedEarly;
  final String? linkedTaskId;
  final DateTime? linkedDate;
  final int pausedMs;
  final int awayMs;
  final int interruptions;
  final int appUsageMs;

  /// Package → ms in monitored apps (Android usage access).
  final Map<String, int> distractions;
}

/// A session found on launch after the app was killed (§4.3).
class FocusRecovery {
  const FocusRecovery({required this.session, required this.canResume});
  final FocusSession session;
  final bool canResume;
}

class FocusUiState {
  const FocusUiState({this.session, this.summary, this.recovery});
  final FocusSession? session;
  final FocusSummary? summary;
  final FocusRecovery? recovery;
}

final focusControllerProvider =
    NotifierProvider<FocusController, FocusUiState>(FocusController.new);

class FocusController extends Notifier<FocusUiState> {
  static const _dndKey = 'dnd_prev_filter';
  static const _pauseDndRestore = Duration(minutes: 5);

  static const _heartbeatEvery = Duration(seconds: 30);

  Timer? _phaseTimer;
  Timer? _pauseTimer;
  Timer? _heartbeat;
  bool _dndRestoredForPause = false;

  @override
  FocusUiState build() {
    ref.onDispose(() {
      _phaseTimer?.cancel();
      _pauseTimer?.cancel();
      _heartbeat?.cancel();
    });
    return const FocusUiState();
  }

  FocusDao get _dao => ref.read(focusDaoProvider);
  DateTime get _now => ref.read(clockProvider).now();

  TimerEngine engineFor(FocusConfig config) {
    final s = ref.read(settingsProvider);
    return TimerEngine(
      config,
      autoStartBreaks: s.autoStartBreaks,
      autoStartFocus: s.autoStartFocus,
    );
  }

  TimerEngine? get engine {
    final s = state.session;
    return s == null ? null : engineFor(s.config);
  }

  // --- Lifecycle ----------------------------------------------------------

  /// Called once at launch: restores DND if a previous run left it changed,
  /// and surfaces an interrupted session.
  Future<void> checkRecovery() async {
    final live = await _dao.liveState();
    if (live == null) {
      await _restoreDnd();
      return;
    }
    final row = await _dao.session(live.sessionId);
    if (row == null) {
      await _dao.clearLiveState();
      await _restoreDnd();
      return;
    }
    final eng = engineFor(row.config);
    final now = _now;
    // Time since the last heartbeat (killed or restarted) counts as away.
    final tracking = FocusTracker.recover(
      live.tracking,
      now,
      focusPhaseEndsAt: live.timer.isFocus ? eng.phaseEndsAt(live.timer) : null,
    );
    final timer = eng.tick(live.timer, now).state;
    final session = FocusSession(
      id: row.id,
      config: row.config,
      timer: timer,
      startedAt: row.startedAt,
      linkedTaskId: row.linkedTaskId,
      linkedDate: row.linkedOccurrenceDate,
      tracking: tracking,
      strict: live.strict,
    );
    state = FocusUiState(
      recovery: FocusRecovery(session: session, canResume: !timer.cycleComplete),
    );
    // Strict focus survives a kill or restart: no "close session" way out.
    if (session.locked) await resumeRecovered();
  }

  Future<void> resumeRecovered() async {
    final r = state.recovery;
    if (r == null) return;
    state = FocusUiState(session: r.session);
    await _persist();
    await _holdReminders();
    await _silence();
    _arm();
    _startHeartbeat();
  }

  Future<void> closeRecovered() async {
    final r = state.recovery;
    if (r == null) return;
    state = FocusUiState(session: r.session);
    await _finish(endedEarly: !r.session.timer.cycleComplete, showSummary: false);
  }

  Future<void> start(
    FocusConfig config, {
    String? linkedTaskId,
    DateTime? linkedDate,
    bool? strict,
  }) async {
    if (state.session != null) return;
    final now = _now;
    final eng = engineFor(config);
    final session = FocusSession(
      id: const Uuid().v4(),
      config: config,
      timer: eng.start(now),
      startedAt: now,
      linkedTaskId: linkedTaskId,
      linkedDate: linkedDate == null ? null : Days.of(linkedDate),
      strict: strict ?? ref.read(settingsProvider).strictMode,
    );
    state = FocusUiState(session: session);
    await _dao.upsertSession(_record(session, endedAt: null));
    await _persist();
    await ref
        .read(settingsProvider.notifier)
        .update((s) => s.copyWith(lastFocus: config, lastFocusAt: now));
    await _holdReminders();
    await _silence();
    _arm();
    _startHeartbeat();
  }

  /// Focus straight from a task: one countdown of [minutes], no breaks.
  Future<void> startForTask({required String taskId, required DateTime date, required int minutes}) => start(
    FocusConfig(focusMin: minutes, shortMin: 0, longMin: 0, longEvery: 1),
    linkedTaskId: taskId,
    linkedDate: date,
  );

  void pause() {
    final s = state.session;
    final eng = engine;
    if (s == null || eng == null || !s.timer.isRunning || s.locked) return;
    _set(eng.pause(s.timer, _now));
    _phaseTimer?.cancel();
    _pauseTimer?.cancel();
    _pauseTimer = Timer(_pauseDndRestore, () async {
      _dndRestoredForPause = true;
      await _restoreDnd();
    });
  }

  Future<void> resume() async {
    final s = state.session;
    final eng = engine;
    if (s == null || eng == null) return;
    _pauseTimer?.cancel();
    if (s.timer.isWaiting) {
      _set(eng.startWaiting(s.timer, _now));
    } else {
      _set(eng.resume(s.timer, _now));
    }
    if (_dndRestoredForPause) {
      _dndRestoredForPause = false;
      await _silence();
    }
    await _holdReminders();
    _arm();
  }

  Future<void> skip() async {
    final s = state.session;
    final eng = engine;
    if (s == null || eng == null || s.locked) return;
    final r = eng.skip(s.timer, _now);
    await _handleEnded(r);
  }

  /// "End session" — always recorded as ended early. Not while strict
  /// mode holds a focus phase.
  Future<void> end() async {
    if (state.session?.locked ?? false) return;
    await _finish(endedEarly: true);
  }

  void dismissSummary() => state = const FocusUiState();

  /// Drops any live session without recording it (Delete all data). Puts the
  /// phone's DND back first, while the saved filter still exists.
  Future<void> discard() async {
    _phaseTimer?.cancel();
    _pauseTimer?.cancel();
    _heartbeat?.cancel();
    _dndRestoredForPause = false;
    await _restoreDnd();
    await ref.read(guardServiceProvider).clear();
    ref.read(reminderSchedulerProvider).holdUntil = null;
    state = const FocusUiState();
  }

  /// App went to background: schedule the single allowed notification.
  Future<void> onBackground() async {
    final s = state.session;
    final eng = engine;
    if (s == null || eng == null) return;
    _heartbeat?.cancel();
    _setTracking(
      FocusTracker.leave(s.tracking, _now, focusPhaseEndsAt: s.timer.isFocus ? eng.phaseEndsAt(s.timer) : null),
    );
    final at = eng.phaseEndsAt(s.timer);
    if (at == null) return;
    final notif = ref.read(notificationServiceProvider);
    final String title;
    final String body;
    if (s.timer.isFocus) {
      final held = await ref.read(reminderSchedulerProvider).heldCount();
      title = 'Focus complete';
      body = held == 0
          ? 'Nice work. Time for a break.'
          : '$held reminder${held == 1 ? ' was' : 's were'} held';
    } else {
      title = 'Break is over';
      body = 'Ready when you are.';
    }
    await notif.scheduleFocusEnd(
      at: at,
      title: title,
      body: body,
      exact: await notif.canScheduleExact(),
    );
  }

  Future<void> onForeground() async {
    await ref.read(notificationServiceProvider).cancelFocusEnd();
    final s = state.session;
    if (s != null) {
      _setTracking(FocusTracker.returnTo(s.tracking, _now));
      _startHeartbeat();
    }
    _onTick();
  }

  // --- Internals ----------------------------------------------------------

  void _set(TimerState t) {
    final s = state.session;
    if (s == null) return;
    state = FocusUiState(session: s.withTimer(t));
    unawaited(_persist());
  }

  void _setTracking(FocusTracking t) {
    final s = state.session;
    if (s == null) return;
    state = FocusUiState(session: s.withTracking(t));
    unawaited(_persist());
  }

  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(_heartbeatEvery, (_) {
      final s = state.session;
      if (s != null) _setTracking(FocusTracker.heartbeat(s.tracking, _now));
    });
  }

  Future<void> _persist() async {
    final s = state.session;
    if (s == null) return;
    await _dao.saveLiveState(s.id, s.timer, s.tracking, strict: s.strict);
    await _syncGuard();
  }

  /// Arms the Android focus guard for a running focus phase (blocked apps,
  /// and uninstall protection in strict mode); clears it otherwise. It
  /// expires on its own at the phase end, even if Poora is killed.
  Future<void> _syncGuard() async {
    final guard = ref.read(guardServiceProvider);
    if (!guard.supported) return;
    final s = state.session;
    final end = s == null ? null : engine?.phaseEndsAt(s.timer);
    final blocked = ref.read(settingsProvider).blockedApps;
    if (s == null || end == null || !s.timer.isFocus || (!s.strict && blocked.isEmpty)) {
      await guard.clear();
      return;
    }
    await guard.arm(until: end, strict: s.strict, blocked: blocked);
  }

  void _arm() {
    _phaseTimer?.cancel();
    final s = state.session;
    final eng = engine;
    if (s == null || eng == null) return;
    final end = eng.phaseEndsAt(s.timer);
    if (end == null) return;
    final wait = end.difference(_now);
    _phaseTimer = Timer(wait.isNegative ? Duration.zero : wait, _onTick);
  }

  void _onTick() {
    final s = state.session;
    final eng = engine;
    if (s == null || eng == null) return;
    unawaited(_handleEnded(eng.tick(s.timer, _now)));
  }

  Future<void> _handleEnded(TickResult r) async {
    final s = state.session;
    if (s == null) return;
    if (r.ended.isNotEmpty) {
      final fb = ref.read(feedbackProvider);
      unawaited(fb.chime());
      fb.success();
    }
    if (r.state.cycleComplete) {
      state = FocusUiState(session: s.withTimer(r.state));
      await _finish(endedEarly: false);
      return;
    }
    _set(r.state);
    if (r.ended.isNotEmpty) await _holdReminders();
    _arm();
  }

  Future<void> _finish({required bool endedEarly, bool showSummary = true}) async {
    final s = state.session;
    if (s == null) return;
    _phaseTimer?.cancel();
    _pauseTimer?.cancel();
    _heartbeat?.cancel();
    final eng = engineFor(s.config);
    final now = _now;
    final focusMs = eng.focusMsSoFar(s.timer, now);
    final tracking = FocusTracker.finish(s.tracking, now);
    final watched = ref.read(settingsProvider).distractingApps.toSet();
    final distractions = await ref.read(usageServiceProvider).usage(from: s.startedAt, to: now, packages: watched);
    final rec = _record(
      s,
      endedAt: now,
      focusMs: focusMs,
      endedEarly: endedEarly,
      pausedMs: eng.pausedMsSoFar(s.timer, now),
      tracking: tracking,
      distractions: distractions,
    );
    await _dao.upsertSession(rec);
    await _dao.clearLiveState();
    await ref.read(guardServiceProvider).clear();
    await ref.read(notificationServiceProvider).cancelFocusEnd();
    await _restoreDnd();
    await ref.read(reminderSchedulerProvider).releaseHeld();
    // Focus phases behind us: the current one only counts once it's over.
    final completedFocus = s.timer.isFocus && !s.timer.cycleComplete
        ? s.timer.focusIndex - 1
        : s.timer.focusIndex;
    state = FocusUiState(
      summary: showSummary
          ? FocusSummary(
              focusMinutes: (focusMs / 60000).round(),
              sessionsCompleted: completedFocus.clamp(0, s.config.longEvery),
              endedEarly: endedEarly,
              linkedTaskId: s.linkedTaskId,
              linkedDate: s.linkedDate,
              pausedMs: rec.pausedMs,
              awayMs: rec.awayMs,
              interruptions: rec.interruptions,
              appUsageMs: rec.appUsageMs,
              distractions: distractions,
            )
          : null,
    );
  }

  FocusSessionRecord _record(
    FocusSession s, {
    required DateTime? endedAt,
    int focusMs = 0,
    bool endedEarly = false,
    int pausedMs = 0,
    FocusTracking tracking = FocusTracking.empty,
    Map<String, int> distractions = const {},
  }) => FocusSessionRecord(
    id: s.id,
    startedAt: s.startedAt,
    endedAt: endedAt,
    config: s.config,
    focusMsCompleted: focusMs,
    phasesCompleted: s.timer.phasesCompleted,
    endedEarly: endedEarly,
    linkedTaskId: s.linkedTaskId,
    linkedOccurrenceDate: s.linkedDate,
    pausedMs: pausedMs,
    awayMs: tracking.awayMs,
    interruptions: tracking.interruptions,
    distractions: distractions,
  );

  /// §4.4 step 1: hold every reminder until the projected end of the cycle.
  Future<void> _holdReminders() async {
    final s = state.session;
    final eng = engine;
    if (s == null || eng == null) return;
    final scheduler = ref.read(reminderSchedulerProvider)
      ..holdUntil = eng.projectedCycleEnd(s.timer, _now);
    await scheduler.reschedule();
  }

  /// §4.4 step 3: save the current interruption filter, then silence.
  Future<void> _silence() async {
    final settings = ref.read(settingsProvider);
    final dnd = ref.read(dndServiceProvider);
    if (!settings.silencePhone || !dnd.supported || !await dnd.hasAccess()) {
      return;
    }
    final dao = ref.read(settingsDaoProvider);
    if (await dao.get(_dndKey) == null) {
      final prev = await dnd.currentFilter();
      if (prev == null) return;
      await dao.set(_dndKey, '$prev');
    }
    await dnd.setFilter(DndService.filterPriority);
  }

  /// Restores the user's previous DND state; safe to call on every exit path.
  Future<void> _restoreDnd() async {
    final dao = ref.read(settingsDaoProvider);
    final prev = int.tryParse(await dao.get(_dndKey) ?? '');
    if (prev == null) return;
    await ref.read(dndServiceProvider).setFilter(prev);
    await dao.remove(_dndKey);
  }
}
