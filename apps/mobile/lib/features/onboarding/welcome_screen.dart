import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
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

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> with WidgetsBindingObserver {
  final _pages = PageController();
  final _name = TextEditingController();
  int _page = 0;
  static const _count = 5;

  /// The notifications step — Skip lands here, never past it.
  static const _notifPage = 3;

  /// null = not asked yet; true/false = the answer.
  bool? _notifGranted;

  /// Android 12+ exact alarms (reminders on the minute). null = not checked.
  bool? _exactGranted;

  static bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  // Back from a system settings screen: re-read both permissions.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _notifGranted != null) unawaited(_refreshPermissions());
  }

  Future<void> _refreshPermissions() async {
    final notif = ref.read(notificationServiceProvider);
    final granted = await notif.notificationsEnabled();
    final exact = await notif.canScheduleExact();
    if (!mounted) return;
    setState(() {
      _notifGranted = granted;
      _exactGranted = exact;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pages.dispose();
    _name.dispose();
    super.dispose();
  }

  /// Every permission reminders need is asked here, once: notifications,
  /// then (Android 12+) exact alarms so reminders fire on the minute. If
  /// declined, only Settings can turn them on later.
  Future<void> _askNotifications() async {
    final notif = ref.read(notificationServiceProvider);
    final granted = await notif.requestNotifications();
    await ref.read(settingsDaoProvider).set('asked_reminder_permissions', 'true');
    var exact = await notif.canScheduleExact();
    if (granted && !exact) exact = await notif.requestExact();
    if (!mounted) return;
    setState(() {
      _notifGranted = granted;
      _exactGranted = exact;
    });
    if (granted && exact) {
      ref.read(feedbackProvider).success();
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (mounted) _next();
    }
  }

  Future<void> _declineNotifications() async {
    await ref.read(settingsDaoProvider).set('asked_reminder_permissions', 'true');
    final exact = await ref.read(notificationServiceProvider).canScheduleExact();
    if (!mounted) return;
    setState(() {
      _notifGranted = false;
      _exactGranted = exact;
    });
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
    await ref.read(settingsProvider.notifier).update((s) => s.copyWith(onboarded: true, name: name.isEmpty ? s.name : name));
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
                  if (_page < _notifPage) TextButton(onPressed: () => _pages.jumpToPage(_notifPage), child: const Text('Skip')),
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
                        'you’re done — on Android, ${AppInfo.name} can silence your phone and block distracting apps. '
                        'No leaderboards, no groups. ${AppInfo.motto}',
                  ),
                  const _Page(
                    hero: _RingHero(),
                    title: 'Finish fully.',
                    body:
                        'Plan with repeats like a calendar, tick things off, and see each day’s '
                        'ring close. Everything stays on this phone — no account, no cloud.',
                  ),
                  _NotificationsPage(
                    granted: _notifGranted,
                    exact: _isAndroid ? _exactGranted : true,
                    onOpenSettings: () => ref.read(notificationServiceProvider).openSystemSettings(),
                    onAllowExact: () => ref.read(notificationServiceProvider).requestExact(),
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
                      decoration: BoxDecoration(color: i == _page ? Tokens.coral : Tokens.outline, borderRadius: BorderRadius.circular(4)),
                    ),
                  const Spacer(),
                  if (_page == _notifPage && _notifGranted == null) ...[
                    TextButton(onPressed: _declineNotifications, child: const Text('Not now')),
                    const SizedBox(width: 4),
                  ],
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      onPressed: _page == _notifPage && _notifGranted == null ? _askNotifications : _next,
                      style: FilledButton.styleFrom(
                        backgroundColor: Tokens.coral,
                        foregroundColor: Tokens.textInverse,
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        last ? 'GET STARTED' : (_page == _notifPage && _notifGranted == null ? 'ALLOW' : 'NEXT'),
                        style: AppText.display(20, color: Tokens.textInverse),
                      ),
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
        const SizedBox(
          height: 140,
          child: Center(child: Mascot(mood: MascotMood.happy, size: 120)),
        ),
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
          decoration: InputDecoration(
            hintText: 'YOUR NAME',
            hintStyle: AppText.display(28, color: Tokens.textSecondary),
          ),
        ),
      ],
    );
  }
}

/// Step 4: ask for every reminder permission once, explaining why. If any is
/// denied, says where it can be turned on later.
class _NotificationsPage extends StatelessWidget {
  const _NotificationsPage({required this.granted, required this.exact, required this.onOpenSettings, required this.onAllowExact});
  final bool? granted;
  final bool? exact;
  final VoidCallback onOpenSettings;
  final VoidCallback onAllowExact;

  @override
  Widget build(BuildContext context) {
    final allSet = granted == true && exact != false;
    final denied = granted == false || (granted == true && exact == false);
    final (title, body) = switch (granted) {
      null => (
        'STAY ON TIME.',
        'Allow notifications so task reminders ring at the right minute, with Poora’s own tone. '
            'They’re held while you focus and delivered together after.',
      ),
      _ when allSet => ('YOU’RE ALL SET.', 'Reminders will ring on time — and stay quiet while you focus.'),
      false => ('NO PROBLEM.', 'Poora won’t ask again, so reminders won’t appear for now.'),
      _ => ('ALMOST THERE.', 'Notifications are on, but exact alarms are off — reminders may arrive a few minutes late.'),
    };
    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.side, Space.x3, Space.side, Space.xl),
      children: [
        SizedBox(
          height: 200,
          child: Center(
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(color: denied ? Tokens.surfaceHigh : Tokens.ice, shape: BoxShape.circle),
              child: Icon(
                allSet
                    ? Icons.notifications_active_rounded
                    : denied
                    ? Icons.notifications_off_outlined
                    : Icons.notifications_rounded,
                size: 64,
                color: denied ? Tokens.textSecondary : Tokens.textInverse,
              ),
            ),
          ),
        ),
        const SizedBox(height: Space.x3),
        Text(title, style: AppText.h1),
        const SizedBox(height: Space.m),
        Text(body, style: AppText.body(16, color: Tokens.textSecondary, height: 1.5)),
        if (granted != null) ...[
          const SizedBox(height: Space.l),
          _PermissionLine(label: 'Notifications', on: granted!),
          if (exact != null) _PermissionLine(label: 'Exact alarms (on-the-minute reminders)', on: exact!),
        ],
        if (denied) ...[
          const SizedBox(height: Space.l),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Tokens.surface, borderRadius: BorderRadius.circular(Radii.inner)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOU CAN TURN THIS ON ANY TIME',
                  style: AppText.body(12, weight: FontWeight.w500, color: Tokens.textSecondary),
                ),
                const SizedBox(height: 8),
                Text('• In Poora: Settings → Notifications', style: AppText.body(15, height: 1.5)),
                Text(
                  '• On your phone: Settings → Apps → Poora → Notifications'
                  '${exact == false ? ', and Alarms & reminders' : ''}',
                  style: AppText.body(15, height: 1.5),
                ),
                const SizedBox(height: 8),
                if (granted == false)
                  TextButton(
                    onPressed: onOpenSettings,
                    child: Text('Open phone settings', style: AppText.label.copyWith(color: Tokens.coral)),
                  )
                else if (exact == false)
                  TextButton(
                    onPressed: onAllowExact,
                    child: Text('Allow exact alarms', style: AppText.label.copyWith(color: Tokens.coral)),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PermissionLine extends StatelessWidget {
  const _PermissionLine({required this.label, required this.on});
  final String label;
  final bool on;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(on ? Icons.check_circle_rounded : Icons.cancel_outlined, size: 20, color: on ? Tokens.mint : Tokens.coralSoft),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: AppText.body(15))),
        Text(on ? 'On' : 'Off', style: AppText.body(13, color: Tokens.textSecondary)),
      ],
    ),
  );
}
