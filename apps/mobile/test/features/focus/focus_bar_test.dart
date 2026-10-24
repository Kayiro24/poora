import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poora/core/db/database.dart';
import 'package:poora/core/providers.dart';
import 'package:poora/core/time/date_utils.dart';
import 'package:poora/features/focus/application/focus_bar.dart';
import 'package:poora/features/focus/application/focus_controller.dart';
import 'package:poora/features/focus/domain/timer_engine.dart';

void main() {
  test('focus bar carries two weeks of days, the goal and the live session', () async {
    final db = AppDatabase.memory();
    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(() async {
      await container.read(focusControllerProvider.notifier).discard();
      container.dispose();
      await db.close();
    });

    final idle = container.read(focusBarDataProvider);
    expect(idle.minutesByDay.length, 14);
    expect(idle.goalMin, 120);
    expect(jsonDecode(idle.encode()), isNot(contains('live')));

    await container.read(focusControllerProvider.notifier).start(const FocusConfig(), strict: true);
    final live = jsonDecode(container.read(focusBarDataProvider).encode()) as Map<String, Object?>;
    final l = live['live']! as Map<String, Object?>;
    expect(l['strict'], isTrue);
    expect(l['since'], greaterThan(0));
    expect(l['capMs'], 25 * 60000);
    expect((live['days']! as Map).containsKey(Days.iso(Days.of(DateTime.now()))), isTrue);
  });
}
