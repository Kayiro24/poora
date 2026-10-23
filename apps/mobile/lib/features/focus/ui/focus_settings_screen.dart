import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poora/core/app_info.dart';
import 'package:poora/core/providers.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';
import 'package:poora/core/widgets/common.dart';
import 'package:poora/core/widgets/screen_header.dart';
import 'package:poora/features/focus/domain/timer_format.dart';
import 'package:poora/features/settings/app_settings.dart';
import 'package:poora/features/settings/settings_controller.dart';

class FocusSettingsScreen extends ConsumerStatefulWidget {
  const FocusSettingsScreen({super.key});

  @override
  ConsumerState<FocusSettingsScreen> createState() => _FocusSettingsState();
}

class _FocusSettingsState extends ConsumerState<FocusSettingsScreen> with WidgetsBindingObserver {
  bool _awaitingDndGrant = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Back from the system DND-access screen: enable only if granted.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_awaitingDndGrant) return;
    _awaitingDndGrant = false;
    unawaited(() async {
      final granted = await ref.read(dndServiceProvider).hasAccess();
      await _update((s) => s.copyWith(silencePhone: granted));
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Do Not Disturb access wasn’t granted.')));
      }
    }());
  }

  Future<void> _update(AppSettings Function(AppSettings) f) => ref.read(settingsProvider.notifier).update(f);

  Future<void> _toggleSilence(bool on) async {
    if (!on) return _update((s) => s.copyWith(silencePhone: false));
    final dnd = ref.read(dndServiceProvider);
    if (await dnd.hasAccess()) return _update((s) => s.copyWith(silencePhone: true));
    if (!mounted) return;
    final go = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('SILENCE YOUR PHONE?'),
        content: const Text(
          'To quiet other apps while you focus, ${AppInfo.name} needs Do Not Disturb '
          'access. Android will open a settings page — find ${AppInfo.name} and allow it.\n\n'
          '${AppInfo.name} switches to Priority only when a session starts and puts '
          'your previous setting back when it ends, however it ends.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Not now')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Open settings')),
        ],
      ),
    );
    if (go ?? false) {
      _awaitingDndGrant = true;
      await dnd.requestAccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final dnd = ref.watch(dndServiceProvider);
    final format = TimerFormat(showSeconds: s.showSeconds, showSubSeconds: s.showSubSeconds);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.side, Space.m, Space.side, Space.x4),
          children: [
            ScreenHeader(title: 'Focus settings', size: 32, onBack: () => Navigator.pop(context)),
            const SizedBox(height: Space.xxl),
            SettingsGroup(
              title: 'Timer display',
              children: [
                _Preview(format: format),
                SwitchRow(
                  title: 'Show seconds',
                  value: s.showSeconds,
                  onChanged: (v) => _update((x) => x.copyWith(showSeconds: v)),
                ),
                SwitchRow(
                  title: 'Show milliseconds',
                  subtitle: s.showSeconds ? 'Two digits, refreshed every frame' : 'Turn on seconds first',
                  // Stored preference stays as-is; it is only shown as off.
                  value: format.effectiveSubSeconds,
                  enabled: s.showSeconds,
                  onChanged: (v) => _update((x) => x.copyWith(showSubSeconds: v)),
                ),
              ],
            ),
            SettingsGroup(
              title: 'Session flow',
              children: [
                SwitchRow(
                  title: 'Auto-start breaks',
                  value: s.autoStartBreaks,
                  onChanged: (v) => _update((x) => x.copyWith(autoStartBreaks: v)),
                ),
                SwitchRow(
                  title: 'Auto-start next focus',
                  value: s.autoStartFocus,
                  onChanged: (v) => _update((x) => x.copyWith(autoStartFocus: v)),
                ),
                SwitchRow(
                  title: 'Long-press to end session',
                  value: s.longPressToEnd,
                  onChanged: (v) => _update((x) => x.copyWith(longPressToEnd: v)),
                ),
              ],
            ),
            SettingsGroup(
              title: 'Quiet',
              children: [
                const SwitchRow(
                  title: 'Hold app reminders during focus',
                  subtitle: 'Always on. Held reminders arrive together when you finish.',
                  value: true,
                  onChanged: null,
                ),
                if (dnd.supported)
                  SwitchRow(
                    title: 'Silence phone during focus',
                    subtitle: 'Uses Do Not Disturb (Priority only)',
                    value: s.silencePhone,
                    onChanged: _toggleSilence,
                  ),
                SwitchRow(
                  title: 'Keep screen awake',
                  value: s.keepAwake,
                  onChanged: (v) => _update((x) => x.copyWith(keepAwake: v)),
                ),
              ],
            ),
            SettingsGroup(
              title: 'Sound',
              children: [
                for (final c in Chime.values)
                  SettingsRow(
                    title: c.label,
                    onTap: () {
                      _update((x) => x.copyWith(chime: c));
                      ref.read(feedbackProvider).chime(c);
                    },
                    trailing: s.chime == c ? const Icon(Icons.check_rounded, color: Tokens.sage) : null,
                  ),
                SwitchRow(
                  title: 'Haptics',
                  value: s.haptics,
                  onChanged: (v) => _update((x) => x.copyWith(haptics: v)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Exactly what the running screen will show (same [TimerFormat]).
class _Preview extends StatelessWidget {
  const _Preview({required this.format});
  final TimerFormat format;

  static const _sampleMs = (24 * 60 + 59) * 1000 + 870;

  @override
  Widget build(BuildContext context) {
    final unit = format.unit;
    return Semantics(
      label: 'Preview: ${format.main(_sampleMs)} ${unit ?? ''}',
      excludeSemantics: true,
      child: Container(
        height: 96,
        alignment: Alignment.center,
        color: Tokens.bg,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(format.main(_sampleMs), style: AppText.mono(48, weight: FontWeight.w400)),
            if (unit != null) ...[const SizedBox(width: 6), Text(unit, style: AppText.body(16, color: Tokens.textSecondary))],
          ],
        ),
      ),
    );
  }
}
