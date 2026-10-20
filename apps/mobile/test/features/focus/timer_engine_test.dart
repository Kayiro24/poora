import 'package:flutter_test/flutter_test.dart';
import 'package:poora/core/time/clock.dart';
import 'package:poora/features/focus/domain/timer_engine.dart';
import 'package:poora/features/focus/domain/timer_format.dart';

void main() {
  const cfg = FocusConfig(longEvery: 2); // 25 / 5 / 15, long after 2
  late FakeClock clock;
  setUp(() => clock = FakeClock(DateTime(2026, 10, 19, 9)));

  group('TimerEngine', () {
    test('remaining time is derived from the wall clock', () {
      const e = TimerEngine(cfg);
      final s = e.start(clock.now());
      clock.advance(const Duration(minutes: 10, seconds: 30));
      expect(e.remainingMs(s, clock.now()), (14 * 60 + 30) * 1000);
      expect(e.progress(s, clock.now()), closeTo(0.42, 0.001));
    });

    test('pause freezes time; resume accumulates paused duration', () {
      const e = TimerEngine(cfg);
      var s = e.start(clock.now());
      clock.advance(const Duration(minutes: 5));
      s = e.pause(s, clock.now());
      clock.advance(const Duration(minutes: 30));
      expect(e.remainingMs(s, clock.now()), 20 * 60000);
      s = e.resume(s, clock.now());
      expect(s.pausedAccumMs, 30 * 60000);
      clock.advance(const Duration(minutes: 1));
      expect(e.remainingMs(s, clock.now()), 19 * 60000);
      expect(e.phaseEndsAt(s), DateTime(2026, 10, 19, 9, 55));
    });

    test('phase cadence: focus, short, focus, long, complete', () {
      const e = TimerEngine(cfg, autoStartFocus: true);
      var s = e.start(clock.now());
      final seen = <FocusPhase>[s.phase];
      while (!s.cycleComplete) {
        clock.set(e.phaseEndsAt(s)!);
        s = e.tick(s, clock.now()).state;
        if (!s.cycleComplete) seen.add(s.phase);
      }
      expect(seen, [
        FocusPhase.focus,
        FocusPhase.shortBreak,
        FocusPhase.focus,
        FocusPhase.longBreak,
      ]);
      expect(s.focusMsCompleted, 50 * 60000);
      expect(s.phasesCompleted, 4);
    });

    test('catch-up after the app was killed for a long time', () {
      const e = TimerEngine(cfg, autoStartFocus: true);
      final s = e.start(clock.now());
      // 25 focus + 5 break + 10 into focus #2.
      clock.advance(const Duration(minutes: 40));
      final r = e.tick(s, clock.now());
      expect(r.ended.map((x) => x.phase), [
        FocusPhase.focus,
        FocusPhase.shortBreak,
      ]);
      expect(r.state.phase, FocusPhase.focus);
      expect(r.state.focusIndex, 2);
      expect(e.remainingMs(r.state, clock.now()), 15 * 60000);
      expect(e.focusMsSoFar(r.state, clock.now()), 35 * 60000);
    });

    test('auto-start focus off: next focus waits for the user', () {
      const e = TimerEngine(cfg);
      var s = e.start(clock.now());
      clock.advance(const Duration(minutes: 31));
      s = e.tick(s, clock.now()).state;
      expect(s.phase, FocusPhase.focus);
      expect(s.isWaiting, isTrue);
      expect(e.remainingMs(s, clock.now()), 25 * 60000);
      clock.advance(const Duration(hours: 2));
      s = e.startWaiting(s, clock.now());
      clock.advance(const Duration(minutes: 1));
      expect(e.remainingMs(s, clock.now()), 24 * 60000);
    });

    test('auto-start breaks off: break waits', () {
      const e = TimerEngine(cfg, autoStartBreaks: false);
      var s = e.start(clock.now());
      clock.advance(const Duration(minutes: 26));
      s = e.tick(s, clock.now()).state;
      expect(s.phase, FocusPhase.shortBreak);
      expect(s.isWaiting, isTrue);
    });

    test('skip ends the phase early and keeps partial focus time', () {
      const e = TimerEngine(cfg);
      var s = e.start(clock.now());
      clock.advance(const Duration(minutes: 7));
      final r = e.skip(s, clock.now());
      s = r.state;
      expect(s.phase, FocusPhase.shortBreak);
      expect(s.focusMsCompleted, 7 * 60000);
      expect(s.phasesCompleted, 0);
      expect(s.isRunning, isTrue);
    });

    test('projected cycle end covers remaining phases', () {
      const e = TimerEngine(cfg);
      final s = e.start(clock.now());
      expect(
        e.projectedCycleEnd(s, clock.now()),
        clock.now().add(cfg.cycleDuration),
      );
      expect(cfg.cycleDuration, const Duration(minutes: 25 + 5 + 25 + 15));
    });
  });

  group('TimerFormat', () {
    const ms = (24 * 60 + 59) * 1000 + 870;
    test('seconds off shows whole minutes', () {
      const f = TimerFormat(showSeconds: false, showSubSeconds: true);
      expect(f.main(ms), '25');
      expect(f.unit, 'min');
      expect(f.effectiveSubSeconds, isFalse);
    });
    test('seconds on', () {
      const f = TimerFormat(showSeconds: true, showSubSeconds: false);
      expect(f.main(ms), '25:00');
      expect(f.main(ms - 1000), '24:59');
      expect(f.main(0), '00:00');
    });
    test('seconds + centiseconds', () {
      const f = TimerFormat(showSeconds: true, showSubSeconds: true);
      expect(f.main(ms), '24:59.87');
      expect(f.main(5), '00:00.01');
    });
  });
}
