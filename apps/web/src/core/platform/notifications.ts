/** Browser notifications (shown via the service worker when available). */
export const Notify = {
  supported: () => typeof window !== 'undefined' && 'Notification' in window,

  permission: (): NotificationPermission | 'unsupported' => (Notify.supported() ? Notification.permission : 'unsupported'),

  async request(): Promise<boolean> {
    if (!Notify.supported()) return false;
    if (Notification.permission === 'granted') return true;
    return (await Notification.requestPermission()) === 'granted';
  },

  async show(title: string, body: string, tag?: string) {
    if (!Notify.supported() || Notification.permission !== 'granted') return;
    const icon = `${import.meta.env.BASE_URL}assets/branding/web_192.png`;
    const reg = await navigator.serviceWorker?.getRegistration().catch(() => undefined);
    if (reg) await reg.showNotification(title, { body, tag, icon, badge: icon });
    else new Notification(title, { body, tag, icon });
  },
};
