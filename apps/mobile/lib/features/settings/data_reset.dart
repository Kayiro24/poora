import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poora/core/providers.dart';
import 'package:poora/features/focus/application/focus_controller.dart';
import 'package:poora/features/focus/application/focus_draft.dart';
import 'package:poora/features/home/home_screen.dart';
import 'package:poora/features/settings/settings_controller.dart';
import 'package:poora/features/tasks/application/tasks_view.dart';

/// "Delete all data": returns the app to a first-launch state.
///
/// Order matters: the live focus session is discarded first so the user's
/// Do Not Disturb setting is restored while its saved value still exists.
class DataReset {
  DataReset(this._ref);
  final Ref _ref;

  Future<void> run() async {
    await _ref.read(focusControllerProvider.notifier).discard();
    await _ref.read(databaseProvider).deleteEverything();
    await _ref.read(notificationServiceProvider).cancelAll();
    _ref.read(settingsProvider.notifier).reset();
    _ref
      ..invalidate(focusDraftProvider)
      ..invalidate(focusLinkProvider)
      ..invalidate(tasksViewProvider)
      ..invalidate(homeDayProvider);
    await _ref.read(reminderSchedulerProvider).reschedule();
  }
}

final dataResetProvider = Provider(DataReset.new);
