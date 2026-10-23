import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poora/core/platform/usage_service.dart';
import 'package:poora/core/providers.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';

/// Installed apps by package (labels/icons for distracting-app stats).
final installedAppsProvider = FutureProvider<Map<String, InstalledApp>>((ref) async {
  final apps = await ref.read(usageServiceProvider).launchableApps();
  return {for (final a in apps) a.package: a};
});

/// Whether Android Usage access is granted (re-read with ref.invalidate).
final usageAccessProvider = FutureProvider<bool>((ref) => ref.read(usageServiceProvider).hasAccess());

String fmtMs(int ms) {
  final m = (ms / 60000).round();
  if (ms > 0 && m == 0) return '<1 min';
  if (m < 60) return '$m min';
  return m % 60 == 0 ? '${m ~/ 60} h' : '${m ~/ 60} h ${m % 60} min';
}

/// The four kinds of time, always shown apart and labelled the same way.
class FocusBreakdown extends ConsumerWidget {
  const FocusBreakdown({
    required this.focusMs,
    required this.pausedMs,
    required this.awayMs,
    required this.interruptions,
    required this.appUsageMs,
    this.distractions = const {},
    this.dense = false,
    super.key,
  });

  final int focusMs;
  final int pausedMs;
  final int awayMs;
  final int interruptions;
  final int appUsageMs;
  final Map<String, int> distractions;
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apps = ref.watch(installedAppsProvider).value ?? const {};
    final top = distractions.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    Widget row(String label, String value, String hint, Color color) => Padding(
      padding: EdgeInsets.symmetric(vertical: dense ? 3 : 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: label,
                    style: AppText.body(dense ? 13 : 14, weight: FontWeight.w500),
                  ),
                  if (!dense)
                    TextSpan(
                      text: '  $hint',
                      style: AppText.body(12, color: Tokens.textSecondary),
                    ),
                ],
              ),
            ),
          ),
          Text(value, style: AppText.mono(dense ? 12 : 14)),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row('Focus', fmtMs(focusMs), 'timer running', Tokens.sage),
        row('Paused', fmtMs(pausedMs), 'you paused', Tokens.textSecondary),
        row('Away', '${fmtMs(awayMs)} · $interruptions×', 'left the app', Tokens.coralSoft),
        row('App use', fmtMs(appUsageMs), 'Poora on screen', Tokens.ice),
        if (top.isNotEmpty) ...[
          SizedBox(height: dense ? 4 : 8),
          Text(
            'DISTRACTING APPS',
            style: AppText.body(11, weight: FontWeight.w500, color: Tokens.textSecondary),
          ),
          for (final e in top.take(dense ? 2 : 5))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  if (apps[e.key]?.icon != null)
                    Image.memory(apps[e.key]!.icon!, width: 18, height: 18)
                  else
                    const Icon(Icons.apps_rounded, size: 18, color: Tokens.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(apps[e.key]?.label ?? e.key, style: AppText.body(13), overflow: TextOverflow.ellipsis),
                  ),
                  Text(fmtMs(e.value), style: AppText.mono(12, color: Tokens.coralSoft)),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
