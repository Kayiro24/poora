import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poora/core/theme/typography.dart';
import 'package:poora/features/focus/application/focus_controller.dart';

/// "You were in a focus session" (§4.3 kill-recovery).
Future<void> showRecoveryDialog(BuildContext context, WidgetRef ref) async {
  final recovery = ref.read(focusControllerProvider).recovery;
  if (recovery == null) return;
  final ctrl = ref.read(focusControllerProvider.notifier);
  final resume = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (c) => AlertDialog(
      title: const Text('YOU WERE IN A FOCUS SESSION'),
      content: Text(
        recovery.canResume
            ? 'The app closed while your timer was running. The time kept going — '
                  'pick up where the clock is now, or close the session.'
            : 'Your cycle finished while the app was closed.',
        style: AppText.bodyM,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(recovery.canResume ? 'Close session' : 'Close')),
        if (recovery.canResume) TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Resume')),
      ],
    ),
  );
  if (resume ?? false) {
    await ctrl.resumeRecovered();
  } else {
    await ctrl.closeRecovered();
  }
}
