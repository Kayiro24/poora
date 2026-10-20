import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poora/core/providers.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';
import 'package:poora/features/tasks/application/tasks_providers.dart';
import 'package:poora/features/tasks/domain/models.dart';
import 'package:poora/features/tasks/domain/series_edits.dart';
import 'package:poora/features/tasks/ui/task_editor.dart';

/// "This task / This and following tasks / All tasks" (Google Calendar).
Future<EditScope?> askScope(
  BuildContext context, {
  String title = 'EDIT RECURRING TASK',
}) {
  var scope = EditScope.thisOne;
  return showDialog<EditScope>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, set) => AlertDialog(
        title: Text(title),
        content: RadioGroup<EditScope>(
          groupValue: scope,
          onChanged: (v) => set(() => scope = v!),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (s, label) in [
                (EditScope.thisOne, 'This task'),
                (EditScope.thisAndFollowing, 'This and following tasks'),
                (EditScope.all, 'All tasks'),
              ])
                RadioListTile<EditScope>(
                  value: s,
                  contentPadding: EdgeInsets.zero,
                  activeColor: Tokens.coral,
                  title: Text(label, style: AppText.bodyL),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, scope), child: const Text('OK')),
        ],
      ),
    ),
  );
}

Future<void> toggleDone(WidgetRef ref, Occurrence o) async {
  final done = !o.isDone;
  final fb = ref.read(feedbackProvider);
  if (done) {
    fb.light();
  } else {
    fb.selection();
  }
  await ref.read(tasksRepositoryProvider).setDone(o, done: done);
}

/// Swipe-left action: skip this occurrence for recurring tasks, delete for
/// one-offs. Offers undo.
Future<void> skipOrDelete(BuildContext context, WidgetRef ref, Occurrence o) async {
  final repo = ref.read(tasksRepositoryProvider);
  final messenger = ScaffoldMessenger.of(context);
  ref.read(feedbackProvider).selection();
  if (o.task.isRecurring) {
    final skipped = o.status != OccurrenceStatus.skipped;
    await repo.setSkipped(o, skipped: skipped);
    messenger.showSnackBar(
      SnackBar(
        content: Text(skipped ? 'Skipped this time' : 'Restored'),
        action: SnackBarAction(
          label: 'Undo',
          textColor: Tokens.coral,
          onPressed: () => repo.setSkipped(o, skipped: !skipped),
        ),
      ),
    );
  } else {
    await repo.delete(o);
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Task deleted'),
        action: SnackBarAction(
          label: 'Undo',
          textColor: Tokens.coral,
          onPressed: () => repo.create(o.task),
        ),
      ),
    );
  }
}

Future<void> openEditor(
  BuildContext context, {
  Occurrence? occurrence,
  DateTime? date,
  int? startMinute,
  int? durationMin,
}) => showTaskEditor(
  context,
  occurrence: occurrence,
  date: date,
  startMinute: startMinute,
  durationMin: durationMin,
);

/// Drag on the rail → reschedule, asking for a scope on recurring tasks.
Future<void> rescheduleOccurrence(
  BuildContext context,
  WidgetRef ref,
  Occurrence o, {
  required DateTime date,
  required int startMinute,
}) async {
  var scope = EditScope.thisOne;
  if (o.task.isRecurring) {
    final s = await askScope(context, title: 'MOVE RECURRING TASK');
    if (s == null) return;
    scope = s;
  }
  ref.read(feedbackProvider).light();
  await ref
      .read(tasksRepositoryProvider)
      .reschedule(o, date: date, startMinute: startMinute, scope: scope);
}
