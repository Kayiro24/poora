import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:poora/core/theme/theme.dart';
import 'package:poora/core/time/date_utils.dart';
import 'package:poora/core/widgets/floating_nav_bar.dart';
import 'package:poora/features/focus/ui/focus_screen.dart';
import 'package:poora/features/focus/ui/focus_settings_screen.dart';
import 'package:poora/features/focus/ui/running_screen.dart';
import 'package:poora/features/gallery/gallery_screen.dart';
import 'package:poora/features/home/home_screen.dart';
import 'package:poora/features/insights/ui/completion_calendar_screen.dart';
import 'package:poora/features/insights/ui/insights_screen.dart';
import 'package:poora/features/insights/ui/recurring_detail_screen.dart';
import 'package:poora/features/onboarding/splash_screen.dart';
import 'package:poora/features/onboarding/welcome_screen.dart';
import 'package:poora/features/settings/settings_screen.dart';
import 'package:poora/features/tasks/ui/tasks_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

abstract final class Routes {
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const home = '/home';
  static const focus = '/focus';
  static const focusRun = '/focus/run';
  static const focusSettings = '/focus/settings';
  static const tasks = '/tasks';
  static const insights = '/insights';
  static const settings = '/settings';
  static const gallery = '/gallery';

  static String calendar({DateTime? day, String? filter}) => Uri(
    path: '/insights/calendar',
    queryParameters: {
      if (day != null) 'day': Days.iso(day),
      'filter': ?filter,
    },
  ).toString();

  static String recurring(String taskId) => '/insights/task/$taskId';
}

Page<void> _calm(GoRouterState state, Widget child) => CustomTransitionPage<void>(
  key: state.pageKey,
  child: child,
  transitionDuration: const Duration(milliseconds: 360),
  reverseTransitionDuration: const Duration(milliseconds: 280),
  transitionsBuilder: (context, animation, _, child) =>
      CalmTransition(animation: animation, child: child),
);

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: Routes.splash,
  routes: [
    GoRoute(
      path: Routes.splash,
      pageBuilder: (c, s) => const NoTransitionPage(child: SplashScreen()),
    ),
    GoRoute(
      path: Routes.welcome,
      pageBuilder: (c, s) => _calm(s, const WelcomeScreen()),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.home,
              pageBuilder: (c, s) => _calm(s, const HomeScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.focus,
              pageBuilder: (c, s) => _calm(s, const FocusScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.tasks,
              pageBuilder: (c, s) => _calm(s, const TasksScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.insights,
              pageBuilder: (c, s) => _calm(s, const InsightsScreen()),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: Routes.focusRun,
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (c, s) => _calm(s, const FocusRunningScreen()),
    ),
    GoRoute(
      path: Routes.focusSettings,
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (c, s) => _calm(s, const FocusSettingsScreen()),
    ),
    GoRoute(
      path: Routes.settings,
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (c, s) => _calm(s, const SettingsScreen()),
    ),
    GoRoute(
      path: '/insights/calendar',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (c, s) {
        final day = s.uri.queryParameters['day'];
        return _calm(
          s,
          CompletionCalendarScreen(
            initialDay: day == null ? null : Days.parse(day),
            initialFilter: s.uri.queryParameters['filter'],
          ),
        );
      },
    ),
    GoRoute(
      path: '/insights/task/:id',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (c, s) =>
          _calm(s, RecurringDetailScreen(taskId: s.pathParameters['id']!)),
    ),
    if (kDebugMode)
      GoRoute(
        path: Routes.gallery,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (c, s) => _calm(s, const GalleryScreen()),
      ),
  ],
);

/// Tab scaffold with the floating pill nav bar over the content.
class AppShell extends StatelessWidget {
  const AppShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  static const items = [
    NavItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
    NavItem(Icons.timer_outlined, Icons.timer_rounded, 'Focus'),
    NavItem(Icons.calendar_month_outlined, Icons.calendar_month_rounded, 'Tasks'),
    NavItem(Icons.insights_outlined, Icons.insights_rounded, 'Insights'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: shell,
      bottomNavigationBar: FloatingNavBar(
        items: items,
        index: shell.currentIndex,
        onTap: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
    );
  }
}
