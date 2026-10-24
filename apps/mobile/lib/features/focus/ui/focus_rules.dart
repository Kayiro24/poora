import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poora/app_router.dart';
import 'package:poora/core/app_info.dart';
import 'package:poora/core/platform/permissions_service.dart';
import 'package:poora/core/providers.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';
import 'package:poora/core/time/date_utils.dart';
import 'package:poora/core/widgets/accent_panel.dart';
import 'package:poora/core/widgets/common.dart';
import 'package:poora/core/widgets/wheel_picker.dart';
import 'package:poora/features/focus/application/focus_draft.dart';
import 'package:poora/features/focus/domain/focus_history.dart';
import 'package:poora/features/focus/domain/focus_session.dart';
import 'package:poora/features/focus/ui/focus_breakdown.dart';
import 'package:poora/features/settings/permissions_list.dart';
import 'package:poora/features/settings/settings_controller.dart';

bool get _isAndroid => !kIsWeb && Platform.isAndroid;

/// "You versus you": today's focus against your own daily goal, and the
/// streak of days you reached it. No one else's numbers, ever.
class DailyGoalCard extends ConsumerWidget {
  const DailyGoalCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(focusSessionsProvider).value ?? const <FocusSessionRecord>[];
    final today = ref.watch(todayProvider);
    final goal = ref.watch(settingsProvider.select((s) => s.dailyFocusGoalMin));
    final done = FocusHistory.totals(FocusHistory.inRange(sessions, DateRange.day(today))).focusMs;
    final p = goal <= 0 ? 0.0 : (done / 60000 / goal).clamp(0.0, 1.0);
    final streak = FocusHistory.goalStreak(sessions, goal, today);
    final reached = p >= 1;

    Future<void> pick() async {
      final v = await showWheelPicker(context, title: 'Daily focus goal', min: 15, max: 600, step: 15, value: goal);
      if (v != null) await ref.read(settingsProvider.notifier).update((s) => s.copyWith(dailyFocusGoalMin: v));
    }

    return Semantics(
      button: true,
      label: 'Today ${fmtMs(done)} of ${fmtMs(goal * 60000)} focus goal, $streak day streak. Change goal',
      excludeSemantics: true,
      child: AppCard(
        onTap: pick,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('TODAY’S FOCUS', style: AppText.display(16, color: Tokens.textSecondary))),
                Text(AppInfo.motto, style: AppText.body(12, color: Tokens.textSecondary)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(fmtMs(done), style: AppText.mono(30, color: reached ? Tokens.mint : Tokens.sage)),
                const SizedBox(width: 8),
                Expanded(child: Text('of ${fmtMs(goal * 60000)}', style: AppText.body(14, color: Tokens.textSecondary))),
                const Icon(Icons.edit_outlined, size: 18, color: Tokens.textSecondary),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: p,
                minHeight: 10,
                backgroundColor: Tokens.surfaceHigh,
                color: reached ? Tokens.mint : Tokens.sage,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              reached
                  ? 'Goal reached — you beat yesterday’s you.${streak > 1 ? ' $streak days in a row.' : ''}'
                  : streak > 0
                  ? '$streak-day streak. ${fmtMs((goal * 60000 - done).clamp(0, goal * 60000))} to keep it going.'
                  : 'Reach your goal to start a streak.',
              style: AppText.bodyS,
            ),
          ],
        ),
      ),
    );
  }
}

/// Strict mode, blocked apps and the Android focus guard that enforces them.
class FocusRules extends ConsumerWidget {
  const FocusRules({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final perms = ref.watch(specialPermissionsProvider).value;
    bool on(SpecialPermission p) => perms?[p] ?? true;
    // Blocking works through the focus guard, or Usage access + overlay; strict also wants uninstall protection.
    final canBlock = on(SpecialPermission.accessibility) || (on(SpecialPermission.usage) && on(SpecialPermission.overlay));
    final missing = !_isAndroid || perms == null
        ? null
        : !canBlock && (s.strictMode || s.blockedApps.isNotEmpty)
        ? (on(SpecialPermission.usage) ? SpecialPermission.overlay : SpecialPermission.usage)
        : s.strictMode && !on(SpecialPermission.admin)
        ? SpecialPermission.admin
        : null;
    return SettingsGroup(
      title: 'Focus rules',
      children: [
        SwitchRow(
          title: 'Strict mode',
          subtitle: _isAndroid
              ? 'Focus can’t be paused or ended early, and Poora can’t be uninstalled until it ends'
              : 'Focus can’t be paused or ended early',
          value: s.strictMode,
          onChanged: (v) => ref.read(settingsProvider.notifier).update((x) => x.copyWith(strictMode: v)),
        ),
        if (_isAndroid)
          SettingsRow(
            title: 'Blocked apps',
            subtitle: s.blockedApps.isEmpty ? 'Apps that won’t open during focus' : '${s.blockedApps.length} blocked during focus',
            trailing: const Icon(Icons.chevron_right_rounded, color: Tokens.textSecondary),
            onTap: () => context.push(Routes.blockedApps),
          ),
        if (missing != null)
          SettingsRow(
            title: 'Turn on: ${missing.title}',
            subtitle: '${missing.why}. Without it, ${missing == SpecialPermission.admin ? 'Poora can be uninstalled during strict focus' : 'blocked apps still open'}.',
            trailing: TextButton(
              onPressed: () => ref.read(permissionsServiceProvider).open(missing),
              child: Text('Allow', style: AppText.label.copyWith(color: Tokens.coral)),
            ),
          ),
      ],
    );
  }
}
