import { useEffect, useRef } from 'react';
import { Navigate, NavLink, Outlet, useLocation, useNavigate } from 'react-router';
import { AppInfo } from '../core/appInfo';
import { useSettings } from '../core/hooks';
import { ReminderScheduler } from '../core/platform/reminderScheduler';
import { Icon, type IconName } from '../core/widgets/Icon';
import { confirm } from '../core/widgets/overlays';
import { Wordmark } from '../core/widgets/widgets';
import { FocusController, useFocus } from '../features/focus/application/focusController';
import { DaySheetHost } from '../features/insights/ui/calendar';
import { TasksRepository } from '../features/tasks/data/tasksRepository';
import { FocusOnTaskHost, TaskEditorHost } from '../features/tasks/ui/TaskEditor';

const tabs: { to: string; label: string; icon: IconName; active: IconName }[] = [
  { to: '/home', label: 'Home', icon: 'homeOutline', active: 'home' },
  { to: '/focus', label: 'Focus', icon: 'timer', active: 'timer' },
  { to: '/tasks', label: 'Tasks', icon: 'calendar', active: 'calendar' },
  { to: '/insights', label: 'Insights', icon: 'insights', active: 'insights' },
];

let booted = false;

/** Tab scaffold: floating pill nav on phones, sidebar on desktop. */
export function Shell() {
  const settings = useSettings();
  const { pathname } = useLocation();
  const navigate = useNavigate();
  const sessionId = useFocus((s) => s.session?.id);
  const prevSession = useRef(sessionId);
  const isTab = tabs.some((t) => pathname === t.to);

  // A session starting anywhere opens the full-screen running room.
  useEffect(() => {
    if (!prevSession.current && sessionId) navigate('/focus/run');
    prevSession.current = sessionId;
  }, [sessionId, navigate]);

  // Once per load: reminders, and an interrupted focus session.
  useEffect(() => {
    if (booted) return;
    booted = true;
    ReminderScheduler.reschedule();
    TasksRepository.purgeOldTrash();
    FocusController.checkRecovery();
    const r = useFocus.getState().recovery;
    if (!r) return;
    void confirm({
      title: 'You were in a focus session',
      body: r.canResume
        ? 'Poora closed while your timer was running. The time kept going — pick up where the clock is now, or close the session.'
        : 'Your cycle finished while Poora was closed.',
      action: r.canResume ? 'Resume' : 'Close',
      cancel: r.canResume ? 'Close session' : 'Dismiss',
    }).then((resume) => {
      if (resume && r.canResume) FocusController.resumeRecovered();
      else FocusController.closeRecovered();
    });
  }, []);

  if (!settings.onboarded) return <Navigate to="/welcome" replace />;

  return (
    <div className="app-shell">
      <nav className="nav-side" aria-label="Main">
        <NavLink to="/home" className="brand" aria-label={`${AppInfo.name} home`}>
          <Wordmark size={26} />
        </NavLink>
        {tabs.map((t) => (
          <NavLink key={t.to} to={t.to} className={({ isActive }) => `item${isActive ? ' active' : ''}`}>
            {({ isActive }) => (
              <>
                <Icon name={isActive ? t.active : t.icon} size={22} />
                {t.label}
              </>
            )}
          </NavLink>
        ))}
        <NavLink to="/settings" className={({ isActive }) => `item${isActive ? ' active' : ''}`}>
          <Icon name="tune" size={22} />
          Settings
        </NavLink>
        <div className="foot">
          <a className="pill" href={AppInfo.androidUrl} target="_blank" rel="noreferrer">
            <Icon name="android" size={16} />
            Get the Android app
          </a>
          <p className="body-s" style={{ marginTop: 12 }}>{AppInfo.tagline}</p>
          <div className="legal">
            <NavLink to="/">About</NavLink>
            <NavLink to="/privacy">Privacy</NavLink>
            <NavLink to="/contact">Contact</NavLink>
          </div>
        </div>
      </nav>
      <main>
        <Outlet />
      </main>
      <TaskEditorHost />
      <FocusOnTaskHost />
      <DaySheetHost />
      {isTab && (
        <nav className="nav-float" aria-label="Main">
          {tabs.map((t) => (
            <NavLink key={t.to} to={t.to} aria-label={t.label} title={t.label} className={({ isActive }) => (isActive ? 'active' : '')}>
              {({ isActive }) => <Icon name={isActive ? t.active : t.icon} size={24} />}
            </NavLink>
          ))}
        </nav>
      )}
    </div>
  );
}
