import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poora/app_router.dart';
import 'package:poora/core/app_info.dart';
import 'package:poora/core/theme/motion.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';
import 'package:poora/core/widgets/poora_logo.dart';
import 'package:poora/features/focus/application/focus_controller.dart';
import 'package:poora/features/settings/settings_controller.dart';

/// Brand moment after the native splash: the mark draws itself (the ring
/// closes), then the name and tagline settle in. Short, calm, skippable.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  bool _left = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isAnimating || _c.isCompleted) return;
    if (Motion.reduced(context)) {
      _c.value = 1;
      unawaited(Future<void>.delayed(const Duration(milliseconds: 500), _leave));
    } else {
      unawaited(_c.forward().then((_) => Future<void>.delayed(const Duration(milliseconds: 350), _leave)));
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _leave() async {
    if (_left || !mounted) return;
    _left = true;
    final onboarded = ref.read(settingsProvider).onboarded;
    context.go(onboarded ? Routes.home : Routes.welcome);
    // Only now look for an interrupted focus session, so its dialog never
    // lands on top of the splash.
    if (onboarded) await ref.read(focusControllerProvider.notifier).checkRecovery();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Tokens.bg,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _leave,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final text = Curves.easeOutCubic.transform(((_c.value - 0.55) / 0.45).clamp(0, 1));
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PooraMark(size: 120, progress: Curves.easeInOutCubic.transform((_c.value / 0.7).clamp(0, 1))),
                  const SizedBox(height: 28),
                  Opacity(
                    opacity: text,
                    child: Transform.translate(
                      offset: Offset(0, 12 * (1 - text)),
                      child: Column(
                        children: [
                          Text(AppInfo.name.toUpperCase(), style: AppText.display(48)),
                          const SizedBox(height: 8),
                          Text(AppInfo.tagline, style: AppText.body(16)),
                          const SizedBox(height: 4),
                          Text(AppInfo.subline, style: AppText.body(13, color: Tokens.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
