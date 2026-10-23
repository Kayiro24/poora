import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poora/core/app_info.dart';
import 'package:poora/core/providers.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';
import 'package:poora/core/widgets/common.dart';
import 'package:poora/core/widgets/screen_header.dart';
import 'package:poora/features/focus/ui/focus_breakdown.dart';
import 'package:poora/features/settings/app_settings.dart';
import 'package:poora/features/settings/settings_controller.dart';

/// Whether the Android focus guard (Accessibility service) is on.
final guardEnabledProvider = FutureProvider<bool>((ref) => ref.read(guardServiceProvider).isEnabled());

/// Pick apps from the phone's launcher list. Two uses:
/// * **distracting** — minutes in them are reported after focus (Usage access);
/// * **blocked** — they can't be opened during focus (focus guard).
class DistractingAppsScreen extends ConsumerStatefulWidget {
  const DistractingAppsScreen({this.blocking = false, super.key});

  final bool blocking;

  @override
  ConsumerState<DistractingAppsScreen> createState() => _DistractingAppsState();
}

class _DistractingAppsState extends ConsumerState<DistractingAppsScreen> with WidgetsBindingObserver {
  String _query = '';

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

  // Back from system settings: re-check the permissions.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    ref
      ..invalidate(usageAccessProvider)
      ..invalidate(guardEnabledProvider);
  }

  List<String> _list(AppSettings s) => widget.blocking ? s.blockedApps : s.distractingApps;

  @override
  Widget build(BuildContext context) {
    final blocking = widget.blocking;
    final usage = ref.watch(usageServiceProvider);
    final guard = ref.watch(guardServiceProvider);
    final access = blocking ? (ref.watch(guardEnabledProvider).value ?? false) : (ref.watch(usageAccessProvider).value ?? false);
    final apps = ref.watch(installedAppsProvider);
    final selected = ref.watch(settingsProvider.select(_list)).toSet();

    Future<void> toggle(String pkg) => ref.read(settingsProvider.notifier).update((s) {
      final next = {..._list(s)};
      next.contains(pkg) ? next.remove(pkg) : next.add(pkg);
      final sorted = next.toList()..sort();
      return blocking ? s.copyWith(blockedApps: sorted) : s.copyWith(distractingApps: sorted);
    });

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.side, Space.m, Space.side, Space.x4),
          children: [
            ScreenHeader(title: blocking ? 'Blocked apps' : 'Distracting apps', size: 32, onBack: () => Navigator.pop(context)),
            const SizedBox(height: Space.m),
            Text(
              blocking
                  ? 'During focus, the apps you pick here won’t open — Poora sends you home and back to your timer. '
                        'Breaks are free. This needs the Poora focus guard (Accessibility), which only reads which app is '
                        'on screen. ${AppInfo.motto}'
                  : 'Poora always counts the times you leave it during focus. With Usage access, it can also tell you how long '
                        'you spent in the apps you pick here. This stays on your phone.',
              style: AppText.body(14, color: Tokens.textSecondary, height: 1.5),
            ),
            const SizedBox(height: Space.xl),
            if (!usage.supported)
              EmptyState(
                message: blocking ? 'Blocking apps needs Android.' : 'Distracting-app detection needs Android. Interruptions are still tracked.',
                compact: true,
              )
            else ...[
              SettingsGroup(
                title: 'Permission',
                children: [
                  SettingsRow(
                    title: blocking ? 'Focus guard' : 'Usage access',
                    subtitle: access
                        ? 'On'
                        : blocking
                        ? 'Off — Settings → Accessibility → Poora focus guard'
                        : 'Off — only interruptions are counted',
                    trailing: access
                        ? const Icon(Icons.check_circle_rounded, color: Tokens.mint)
                        : TextButton(
                            onPressed: blocking ? guard.openSettings : usage.requestAccess,
                            child: Text('Turn on', style: AppText.label.copyWith(color: Tokens.coral)),
                          ),
                  ),
                ],
              ),
              Text('${selected.length} selected', style: AppText.bodyS),
              const SizedBox(height: 8),
              TextField(
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                decoration: const InputDecoration(hintText: 'Search apps', prefixIcon: Icon(Icons.search_rounded, color: Tokens.textSecondary)),
              ),
              const SizedBox(height: 8),
              apps.when(
                loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
                error: (_, _) => const EmptyState(message: 'Couldn’t list apps.', compact: true),
                data: (map) {
                  final list = map.values.where((a) => _query.isEmpty || a.label.toLowerCase().contains(_query)).toList()
                    ..sort((a, b) {
                      final sa = selected.contains(a.package), sb = selected.contains(b.package);
                      if (sa != sb) return sa ? -1 : 1;
                      return a.label.toLowerCase().compareTo(b.label.toLowerCase());
                    });
                  return Column(
                    children: [
                      for (final a in list)
                        CheckboxListTile(
                          value: selected.contains(a.package),
                          onChanged: (_) => toggle(a.package),
                          controlAffinity: ListTileControlAffinity.trailing,
                          contentPadding: EdgeInsets.zero,
                          secondary: a.icon != null ? Image.memory(a.icon!, width: 32, height: 32) : const Icon(Icons.apps_rounded),
                          title: Text(a.label, style: AppText.bodyL),
                          shape: const RoundedRectangleBorder(),
                          checkboxShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(6))),
                        ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
