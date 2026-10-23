import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poora/core/providers.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';
import 'package:poora/core/widgets/wheel_picker.dart';
import 'package:poora/features/focus/application/focus_controller.dart';
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
    await deleteOccurrence(context, ref, o);
  }
}

/// Google Calendar delete: recurring tasks ask "This / This and following /
/// All"; then it's deleted at once with an Undo snackbar (no extra confirm).
/// Returns false if the user cancelled.
Future<bool> deleteOccurrence(BuildContext context, WidgetRef ref, Occurrence o) async {
  final repo = ref.read(tasksRepositoryProvider);
  final messenger = ScaffoldMessenger.of(context);
  var scope = EditScope.all;
  if (o.task.isRecurring) {
    final s = await askScope(context, title: 'DELETE RECURRING TASK');
    if (s == null) return false;
    scope = s;
  }
  final undo = await repo.delete(o, scope: scope);
  ref.read(feedbackProvider).selection();
  messenger.showSnackBar(
    SnackBar(
      content: Text(switch (scope) {
        EditScope.thisOne when o.task.isRecurring => 'This task deleted',
        EditScope.thisAndFollowing => 'This and following tasks deleted',
        _ => 'Task moved to Trash',
      }),
      action: SnackBarAction(label: 'Undo', textColor: Tokens.coral, onPressed: undo),
    ),
  );
  return true;
}

/// "Focus on this task": pick 15 / 25 / 45 / 60 min (or custom) and start a
/// single countdown linked to the task.
Future<void> focusOnTask(BuildContext context, WidgetRef ref, Occurrence o) async {
  final minutes = await showModalBottomSheet<int>(
    context: context,
    builder: (c) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FOCUS ON TASK', style: AppText.h3),
            const SizedBox(height: 4),
            Text(o.title, style: AppText.body(15, color: Tokens.textSecondary)),
            const SizedBox(height: 16),
            Row(
              children: [
                for (final m in focusDurations)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Material(
                        color: Tokens.sage,
                        borderRadius: BorderRadius.circular(Radii.inner),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(Radii.inner),
                          onTap: () => Navigator.pop(c, m),
                          child: SizedBox(
                            height: 72,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('$m', style: AppText.mono(26, color: Tokens.textInverse)),
                                Text('min', style: AppText.body(12, color: Tokens.textInverse)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: () => Navigator.pop(c, -1), child: const Text('Custom length…')),
          ],
        ),
      ),
    ),
  );
  if (minutes == null || !context.mounted) return;
  var m = minutes;
  if (m < 0) {
    final picked = await showWheelPicker(context, title: 'Focus length', min: 5, max: 180, step: 5, value: 30);
    if (picked == null) return;
    m = picked;
  }
  ref.read(feedbackProvider).light();
  await ref.read(focusControllerProvider.notifier).startForTask(taskId: o.task.id, date: o.originalDate, minutes: m);
}

/// Quick focus lengths (Regain-style).
const focusDurations = [15, 25, 45, 60];

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
