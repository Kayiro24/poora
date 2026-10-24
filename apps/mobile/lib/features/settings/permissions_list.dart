import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poora/core/platform/permissions_service.dart';
import 'package:poora/core/providers.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';

/// Granted state of each special permission; re-read with ref.invalidate.
final specialPermissionsProvider = FutureProvider<Map<SpecialPermission, bool>>(
  (ref) => ref.read(permissionsServiceProvider).status(),
);

/// The first permission still off, in the order they're asked for.
SpecialPermission? nextMissing(Map<SpecialPermission, bool>? status) {
  if (status == null) return null;
  for (final p in SpecialPermission.values) {
    if (!(status[p] ?? false)) return p;
  }
  return null;
}

/// One row per special permission: what it's for, on/off, and a button that
/// opens the system screen where the user switches it on. Re-checks when
/// Poora comes back to the front.
class PermissionsList extends ConsumerStatefulWidget {
  const PermissionsList({super.key});

  @override
  ConsumerState<PermissionsList> createState() => _PermissionsListState();
}

class _PermissionsListState extends ConsumerState<PermissionsList> with WidgetsBindingObserver {
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) ref.invalidate(specialPermissionsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.read(permissionsServiceProvider);
    final status = ref.watch(specialPermissionsProvider).value;
    return Column(
      children: [
        for (final p in SpecialPermission.values)
          _Row(
            permission: p,
            on: status?[p],
            onAllow: () => service.open(p),
            onAppInfo: p == SpecialPermission.accessibility ? service.openAppInfo : null,
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.permission, required this.on, required this.onAllow, this.onAppInfo});
  final SpecialPermission permission;
  final bool? on;
  final VoidCallback onAllow;
  final VoidCallback? onAppInfo;

  @override
  Widget build(BuildContext context) {
    final granted = on ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(color: Tokens.surface, borderRadius: BorderRadius.circular(Radii.inner)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                granted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                size: 22,
                color: granted ? Tokens.mint : Tokens.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(permission.title, style: AppText.body(15, weight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(permission.why, style: AppText.bodyS),
                  ],
                ),
              ),
              if (on == null)
                const SizedBox(width: 64)
              else if (granted)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text('On', style: AppText.body(13, color: Tokens.mint)),
                )
              else
                TextButton(onPressed: onAllow, child: Text('Allow', style: AppText.label.copyWith(color: Tokens.coral))),
            ],
          ),
          // Android 13+: Accessibility is greyed out for apps installed from a file.
          if (!granted && onAppInfo != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 34, right: 8),
              child: Text(
                'Switch greyed out? Open App info → ⋮ (top right) → “Allow restricted settings”, then come back and tap Allow.',
                style: AppText.body(12, color: Tokens.textSecondary, height: 1.4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: TextButton(onPressed: onAppInfo, child: Text('Open App info', style: AppText.label.copyWith(color: Tokens.coral))),
            ),
          ],
        ],
      ),
    );
  }
}
