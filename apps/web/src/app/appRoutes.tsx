import type { RouteObject } from 'react-router';
import { SplashScreen } from '../features/onboarding/SplashScreen';
import { Shell } from './Shell';

const lazy = <K extends string>(load: () => Promise<Record<K, React.ComponentType>>, name: K) => async () => ({ Component: (await load())[name] });

/** The app (browser only) — client-rendered, screens loaded on demand. */
export const appRoutes: RouteObject[] = [
  { path: '/start', element: <SplashScreen /> },
  { path: '/welcome', lazy: lazy(() => import('../features/onboarding/WelcomeScreen'), 'WelcomeScreen') },
  { path: '/focus/run', lazy: lazy(() => import('../features/focus/ui/FocusRunScreen'), 'FocusRunScreen') },
  {
    element: <Shell />,
    children: [
      { path: '/home', lazy: lazy(() => import('../features/home/HomeScreen'), 'HomeScreen') },
      { path: '/focus', lazy: lazy(() => import('../features/focus/ui/FocusScreen'), 'FocusScreen') },
      { path: '/focus/settings', lazy: lazy(() => import('../features/focus/ui/FocusSettingsScreen'), 'FocusSettingsScreen') },
      { path: '/tasks', lazy: lazy(() => import('../features/tasks/ui/TasksScreen'), 'TasksScreen') },
      { path: '/insights', lazy: lazy(() => import('../features/insights/ui/InsightsScreen'), 'InsightsScreen') },
      { path: '/insights/calendar', lazy: lazy(() => import('../features/insights/ui/CalendarScreen'), 'CalendarScreen') },
      { path: '/insights/task/:id', lazy: lazy(() => import('../features/insights/ui/RecurringDetailScreen'), 'RecurringDetailScreen') },
      { path: '/settings', lazy: lazy(() => import('../features/settings/SettingsScreen'), 'SettingsScreen') },
    ],
  },
];

