import 'package:flutter_test/flutter_test.dart';
import 'package:poora/features/focus/domain/focus_tracker.dart';
import 'package:poora/features/focus/domain/timer_engine.dart';

void main() {
  final t0 = DateTime(2026, 10, 21, 9);
  DateTime at(int min, [int sec = 0]) => t0.add(Duration(minutes: min, seconds: sec));
  final focusEnd = at(25);

  group('interruptions', () {
    test('leaving and returning counts one interruption with its duration', () {
      var t = FocusTracker.leave(FocusTracking.empty, at(5), focusPhaseEndsAt: focusEnd);
      expect(t.isAway, isTrue);
      t = FocusTracker.returnTo(t, at(8));
      expect(t.interruptions, 1);
      expect(t.awayMs, 3 * 60000);
      expect(t.isAway, isFalse);
    });

    test('glances under 2 s are ignored', () {
      var t = FocusTracker.leave(FocusTracking.empty, at(5), focusPhaseEndsAt: focusEnd);
      t = FocusTracker.returnTo(t, at(5, 1));
      expect(t.interruptions, 0);
      expect(t.awayMs, 0);
    });

    test('leaving during a break or after the focus phase is not an interruption', () {
      expect(FocusTracker.leave(FocusTracking.empty, at(5), focusPhaseEndsAt: null).isAway, isFalse);
      expect(FocusTracker.leave(FocusTracking.empty, at(26), focusPhaseEndsAt: focusEnd).isAway, isFalse);
    });

    test('away time is clipped at the end of the focus phase', () {
      var t = FocusTracker.leave(FocusTracking.empty, at(20), focusPhaseEndsAt: focusEnd);
      t = FocusTracker.returnTo(t, at(40)); // came back during the break
      expect(t.awayMs, 5 * 60000);
    });

    test('several trips accumulate; a second leave while away is ignored', () {
      var t = FocusTracker.leave(FocusTracking.empty, at(1), focusPhaseEndsAt: focusEnd);
      t = FocusTracker.leave(t, at(2), focusPhaseEndsAt: focusEnd);
      t = FocusTracker.returnTo(t, at(3));
      t = FocusTracker.leave(t, at(10), focusPhaseEndsAt: focusEnd);
      t = FocusTracker.returnTo(t, at(10, 30));
      expect(t.interruptions, 2);
      expect(t.awayMs, 2 * 60000 + 30000);
    });
  });

  group('recovery', () {
    test('killed while away: away interval closes at recovery', () {
      final t = FocusTracker.leave(FocusTracking.empty, at(5), focusPhaseEndsAt: focusEnd);
      final r = FocusTracker.recover(t, at(15), focusPhaseEndsAt: focusEnd);
      expect(r.interruptions, 1);
      expect(r.awayMs, 10 * 60000);
    });

    test('died on screen (restart): gap since last heartbeat counts as away', () {
      final t = FocusTracker.heartbeat(FocusTracking.empty, at(4));
      final r = FocusTracker.recover(t, at(12), focusPhaseEndsAt: focusEnd);
      expect(r.interruptions, 1);
      expect(r.awayMs, 8 * 60000);
    });

    test('a short heartbeat gap is not an interruption', () {
      final t = FocusTracker.heartbeat(FocusTracking.empty, at(4));
      final r = FocusTracker.recover(t, at(4, 30), focusPhaseEndsAt: focusEnd);
      expect(r.interruptions, 0);
    });

    test('finish closes an open away interval', () {
      final t = FocusTracker.leave(FocusTracking.empty, at(5), focusPhaseEndsAt: focusEnd);
      expect(FocusTracker.finish(t, at(7)).awayMs, 2 * 60000);
    });
  });

  group('time categories', () {
    test('focus, paused, away and app-usage time stay distinct', () {
      const cfg = FocusConfig(longEvery: 1, longMin: 5);
      const e = TimerEngine(cfg);
      var s = e.start(t0);
      s = e.pause(s, at(10));
      s = e.resume(s, at(14)); // 4 min paused
      var tr = FocusTracker.leave(FocusTracking.empty, at(16), focusPhaseEndsAt: e.phaseEndsAt(s));
      tr = FocusTracker.returnTo(tr, at(19)); // 3 min away (timer keeps running)
      final end = at(29);
      s = e.tick(s, end).state;
      expect(e.focusMsSoFar(s, end), 25 * 60000);
      expect(e.pausedMsSoFar(s, end), 4 * 60000);
      expect(tr.awayMs, 3 * 60000);
      expect(FocusTracker.appUsageMs(startedAt: t0, endedAt: end, awayMs: tr.awayMs), 26 * 60000);
    });

    test('paused total survives phase changes and counts an open pause', () {
      const e = TimerEngine(FocusConfig(longEvery: 2), autoStartFocus: true);
      var s = e.start(t0);
      s = e.resume(e.pause(s, at(5)), at(7)); // 2 min
      s = e.tick(s, at(32)).state; // focus done (ends at 27) → break
      expect(s.pausedTotalMs, 2 * 60000);
      s = e.pause(s, at(30));
      expect(e.pausedMsSoFar(s, at(33)), 5 * 60000);
    });
  });
}
