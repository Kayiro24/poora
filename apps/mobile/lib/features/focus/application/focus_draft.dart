import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poora/core/db/daos/focus_dao.dart';
import 'package:poora/core/providers.dart';
import 'package:poora/features/focus/domain/focus_session.dart';
import 'package:poora/features/focus/domain/timer_engine.dart';
import 'package:poora/features/settings/settings_controller.dart';

/// Built-in presets (§4.2). Long-break values for 50/10 and 90/20 are our
/// choice — see DECISIONS.md.
const builtInPresets = <(String, FocusConfig)>[
  ('25 / 5', FocusConfig()),
  ('50 / 10', FocusConfig(focusMin: 50, shortMin: 10, longMin: 30, longEvery: 3)),
  ('90 / 20', FocusConfig(focusMin: 90, shortMin: 20, longMin: 30, longEvery: 2)),
];

const maxSavedPresets = 6;

/// The pre-start screen's editable config; opens with the last-used values.
final focusDraftProvider = NotifierProvider<FocusDraft, FocusConfig>(
  FocusDraft.new,
);

class FocusDraft extends Notifier<FocusConfig> {
  @override
  FocusConfig build() => ref.read(settingsProvider).lastFocus;

  void set(FocusConfig c) => state = c;
}

/// Task linked to the next session: (taskId, occurrence date).
final focusLinkProvider = NotifierProvider<FocusLink, (String, DateTime)?>(
  FocusLink.new,
);

class FocusLink extends Notifier<(String, DateTime)?> {
  @override
  (String, DateTime)? build() => null;
  void set((String, DateTime)? v) => state = v;
}

final presetsProvider = StreamProvider<List<FocusPreset>>(
  (ref) => ref.watch(focusDaoProvider).watchPresets(),
);

final focusSessionsProvider = StreamProvider<List<FocusSessionRecord>>(
  (ref) => ref.watch(focusDaoProvider).watchSessions(),
);
