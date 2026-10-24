import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poora/core/db/database.dart';
import 'package:poora/core/providers.dart';
import 'package:poora/core/time/date_utils.dart';
import 'package:poora/features/tasks/domain/models.dart';
import 'package:poora/features/tasks/ui/task_card.dart';

void main() {
  final day = Days.ymd(2026, 10, 24);
  final occ = Occurrence(
    task: Task(
      id: 't',
      title: 'Test',
      color: 0xFF7679F0,
      startDate: day,
      seriesId: 't',
      createdAt: DateTime(2026, 10, 24),
      updatedAt: DateTime(2026, 10, 24),
      startMinute: 844,
      durationMin: 15,
    ),
    originalDate: day,
    date: day,
    title: 'Test',
    status: OccurrenceStatus.pending,
    startMinute: 844,
  );

  // Rail heights at 64 px/hour: 15 min (the minimum), 20, 30 and 60 min.
  for (final h in [14.0, 22.0, 30.0, 62.0]) {
    testWidgets('rail card fits a ${h.toInt()} px slot without overflow', (tester) async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(width: 340, height: h, child: RailCard(occurrence: occ)),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      expect(find.text('TEST'), findsOneWidget);
    });
  }
}
