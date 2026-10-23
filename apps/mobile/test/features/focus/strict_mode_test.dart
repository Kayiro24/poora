import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poora/core/db/database.dart';
import 'package:poora/core/providers.dart';
import 'package:poora/features/focus/application/focus_controller.dart';
import 'package:poora/features/focus/domain/timer_engine.dart';
import 'package:poora/features/settings/settings_controller.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  FocusController ctrl() => container.read(focusControllerProvider.notifier);
  FocusSession? session() => container.read(focusControllerProvider).session;

  setUp(() {
    db = AppDatabase.memory();
    container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
  });
  tearDown(() async {
    await ctrl().discard();
    container.dispose();
    await db.close();
  });

  test('strict focus cannot be paused, skipped or ended early', () async {
    await container.read(settingsProvider.notifier).update((s) => s.copyWith(strictMode: true));
    await ctrl().start(const FocusConfig());
    expect(session()!.locked, isTrue);

    ctrl().pause();
    expect(session()!.timer.isPaused, isFalse);
    await ctrl().skip();
    expect(session()!.timer.isFocus, isTrue);
    await ctrl().end();
    expect(session(), isNotNull);
    expect(container.read(focusControllerProvider).summary, isNull);
  });

  test('strict mode is stored with the live session and survives a restart', () async {
    await ctrl().start(const FocusConfig(), strict: true);
    final live = await container.read(focusDaoProvider).liveState();
    expect(live!.strict, isTrue);

    // A fresh app run: a locked session resumes by itself — no "close" option.
    final again = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(again.dispose);
    await again.read(focusControllerProvider.notifier).checkRecovery();
    final ui = again.read(focusControllerProvider);
    expect(ui.recovery, isNull);
    expect(ui.session?.locked, isTrue);
    await again.read(focusControllerProvider.notifier).discard();
  });

  test('without strict mode, ending early works', () async {
    await ctrl().start(const FocusConfig());
    expect(session()!.locked, isFalse);
    await ctrl().end();
    expect(session(), isNull);
    expect(container.read(focusControllerProvider).summary!.endedEarly, isTrue);
  });
}
