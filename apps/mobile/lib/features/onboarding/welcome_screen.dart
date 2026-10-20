import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poora/app_router.dart';
import 'package:poora/core/app_info.dart';
import 'package:poora/core/providers.dart';
import 'package:poora/core/theme/motion.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';
import 'package:poora/core/widgets/accent_panel.dart';
import 'package:poora/core/widgets/completion_ring.dart';
import 'package:poora/core/widgets/mascot.dart';
import 'package:poora/core/widgets/poora_logo.dart';
import 'package:poora/features/settings/settings_controller.dart';

/// First-run welcome: what the name means, the two halves of the app, and a
/// name for "Hi, …". Shown once (and again after "Delete all data").
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _pages = PageController();
  final _name = TextEditingController();
  int _page = 0;
  static const _count = 4;

  @override
  void dispose() {
    _pages.dispose();
    _name.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _count - 1) {
      _pages.nextPage(duration: Motion.of(context), curve: Motion.curve);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    ref.read(feedbackProvider).success();
    final name = _name.text.trim();
    await ref
        .read(settingsProvider.notifier)
        .update((s) => s.copyWith(onboarded: true, name: name.isEmpty ? s.name : name));
    if (mounted) context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _count - 1;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.side, Space.m, Space.s, 0),
              child: Row(
                children: [
                  const PooraWordmark(size: 26),
                  const Spacer(),
                  if (!last) TextButton(onPressed: () => _pages.jumpToPage(_count - 1), child: const Text('Skip')),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (p) => setState(() => _page = p),
                children: [
                  const _Page(
                    hero: _MeaningHero(),
                    title: AppInfo.tagline,
                    body:
                        '${AppInfo.meaning}\n\nA calm place to focus on one thing, plan your day, '
                        'and watch it come together.',
                  ),
                  const _Page(
                    hero: _PanelHero(color: Tokens.sage, icon: Icons.timer_rounded, label: '25:00'),
                    title: 'Focus fully.',
                    body:
                        'A quiet timer with nothing else on screen. Your reminders wait until '
                        'you’re done — on Android, ${AppInfo.name} can silence your phone too.',
                  ),
                  const _Page(
                    hero: _RingHero(),
                    title: 'Finish fully.',
                    body:
                        'Plan with repeats like a calendar, tick things off, and see each day’s '
                        'ring close. Everything stays on this phone — no account, no cloud.',
                  ),
                  _NamePage(controller: _name, onSubmit: _finish),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.side, 0, Space.side, Space.xl),
              child: Row(
                children: [
                  for (var i = 0; i < _count; i++)
                    AnimatedContainer(
                      duration: Motion.of(context, Motion.fast),
                      margin: const EdgeInsets.only(right: 6),
                      width: i == _page ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page ? Tokens.coral : Tokens.outline,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  const Spacer(),
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      onPressed: _next,
                      style: FilledButton.styleFrom(
                        backgroundColor: Tokens.coral,
                        foregroundColor: Tokens.textInverse,
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        shape: const StadiumBorder(),
                      ),
                      child: Text(last ? 'GET STARTED' : 'NEXT', style: AppText.display(20, color: Tokens.textInverse)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.hero, required this.title, required this.body});
  final Widget hero;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.side, Space.x3, Space.side, Space.xl),
      children: [
        SizedBox(height: 260, child: Center(child: hero)),
        const SizedBox(height: Space.x3),
        Text(title.toUpperCase(), style: AppText.h1),
        const SizedBox(height: Space.m),
        Text(body, style: AppText.body(16, color: Tokens.textSecondary, height: 1.5)),
      ],
    );
  }
}

class _MeaningHero extends StatelessWidget {
  const _MeaningHero();

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Motion.of(context, const Duration(milliseconds: 1200)),
    curve: Curves.easeInOutCubic,
    builder: (context, v, _) => PooraMark(size: 200, progress: v),
  );
}

class _PanelHero extends StatelessWidget {
  const _PanelHero({required this.color, required this.icon, required this.label});
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 260,
    child: AccentPanel(
      color: color,
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: Tokens.textInverse),
          const SizedBox(height: 12),
          Text(label, style: AppText.mono(64, color: Tokens.textInverse)),
        ],
      ),
    ),
  );
}

class _RingHero extends StatelessWidget {
  const _RingHero();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final (v, c) in [(0.6, Tokens.dayMid), (0.85, Tokens.dayHigh), (1.0, Tokens.dayPerfect)])
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: CompletionRing(
            value: v,
            color: c,
            size: 72,
            stroke: 6,
            glow: v == 1,
            fill: c.withValues(alpha: v == 1 ? 0.35 : 0.15),
            duration: Motion.of(context, const Duration(milliseconds: 900)),
            child: v == 1 ? const Icon(Icons.check_rounded, color: Tokens.textPrimary) : null,
          ),
        ),
    ],
  );
}

class _NamePage extends StatelessWidget {
  const _NamePage({required this.controller, required this.onSubmit});
  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.side, Space.x3, Space.side, Space.xl),
      children: [
        const SizedBox(height: 140, child: Center(child: Mascot(mood: MascotMood.happy, size: 120))),
        const SizedBox(height: Space.x3),
        Text('WHAT SHOULD WE CALL YOU?', style: AppText.h2),
        const SizedBox(height: Space.m),
        Text('Just for the “Hi” on your home screen. You can skip this.', style: AppText.body(15, color: Tokens.textSecondary)),
        const SizedBox(height: Space.xl),
        TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
          style: AppText.display(28),
          decoration: InputDecoration(hintText: 'YOUR NAME', hintStyle: AppText.display(28, color: Tokens.textSecondary)),
        ),
      ],
    );
  }
}
