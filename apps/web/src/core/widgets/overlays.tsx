import { useEffect, useSyncExternalStore } from 'react';
import { createPortal } from 'react-dom';
import { create } from 'zustand';

/*
 * Promise-based dialogs and toasts (the app's AlertDialog + SnackBar).
 *   if (await confirm({ title, body, action })) …
 *   toast('Task deleted', { label: 'Undo', run: () => … })
 */

interface DialogReq {
  title: string;
  body?: string;
  action: string;
  cancel?: string;
  danger?: boolean;
  input?: { placeholder: string; initial?: string; maxLength?: number };
  choices?: { label: string; value: string }[];
  resolve: (v: string | boolean | null) => void;
}

interface ToastReq {
  id: number;
  message: string;
  action?: { label: string; run: () => void };
}

const useOverlay = create<{ dialog: DialogReq | null; toast: ToastReq | null; text: string }>(() => ({ dialog: null, toast: null, text: '' }));
const open = (dialog: DialogReq) =>
  useOverlay.setState({ dialog, text: dialog.input?.initial ?? dialog.choices?.[0]?.value ?? '' });

export function confirm(opts: Omit<DialogReq, 'resolve' | 'input'>): Promise<boolean> {
  return new Promise((resolve) => open({ ...opts, resolve: (v) => resolve(v === true) }));
}

export function prompt(opts: Omit<DialogReq, 'resolve'> & { input: NonNullable<DialogReq['input']> }): Promise<string | null> {
  return new Promise((resolve) =>
    open({ ...opts, resolve: (v) => resolve(typeof v === 'string' ? v : null) }),
  );
}

/** Radio choice dialog; resolves to the chosen value or null. */
export function choose<V extends string>(opts: { title: string; action?: string; choices: { label: string; value: V }[] }): Promise<V | null> {
  return new Promise((resolve) =>
    open({ title: opts.title, action: opts.action ?? 'OK', choices: opts.choices, resolve: (v) => resolve(typeof v === 'string' ? (v as V) : null) }),
  );
}

let toastId = 0;
export function toast(message: string, action?: ToastReq['action']) {
  useOverlay.setState({ toast: { id: ++toastId, message, action } });
}

const noop = () => () => {};

export function OverlayHost() {
  // Portals mount after hydration so prerendered pages hydrate cleanly.
  const mounted = useSyncExternalStore(noop, () => true, () => false);
  const { dialog, toast: t, text } = useOverlay();
  const setText = (v: string) => useOverlay.setState({ text: v });

  useEffect(() => {
    if (!t) return;
    const id = setTimeout(() => useOverlay.setState((s) => (s.toast?.id === t.id ? { toast: null } : s)), 4000);
    return () => clearTimeout(id);
  }, [t]);

  const close = (v: string | boolean | null) => {
    dialog?.resolve(v);
    useOverlay.setState({ dialog: null });
  };

  if (!mounted) return null;
  return createPortal(
    <>
      {dialog && (
        <div className="scrim center" onMouseDown={(e) => e.target === e.currentTarget && close(null)}>
          <div className="dialog" role="alertdialog" aria-modal="true" aria-labelledby="dlg-title">
            <h2 id="dlg-title" className="display d24">{dialog.title}</h2>
            {dialog.body && <p style={{ margin: 0, lineHeight: 1.5 }}>{dialog.body}</p>}
            {dialog.input && (
              <input
                className="input"
                autoFocus
                maxLength={dialog.input.maxLength}
                placeholder={dialog.input.placeholder}
                value={text}
                onChange={(e) => setText(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && close(text.trim())}
              />
            )}
            {dialog.choices && (
              <div role="radiogroup" style={{ display: 'grid', gap: 4 }}>
                {dialog.choices.map((c) => (
                  <label key={c.value} className="list-item body-l" style={{ cursor: 'pointer' }}>
                    <input type="radio" name="choice" checked={text === c.value} onChange={() => setText(c.value)} style={{ accentColor: 'var(--coral)', width: 18, height: 18 }} />
                    {c.label}
                  </label>
                ))}
              </div>
            )}
            <div className="actions">
              <button type="button" className="text-btn" onClick={() => close(null)}>{dialog.cancel ?? 'Cancel'}</button>
              <button
                type="button"
                className={`text-btn ${dialog.danger ? 'danger' : 'coral'}`}
                onClick={() => close(dialog.input ? text.trim() : dialog.choices ? text : true)}
                autoFocus={!dialog.input}
              >
                {dialog.action}
              </button>
            </div>
          </div>
        </div>
      )}
      {t && (
        <div className="toast-wrap" role="status">
          <div className="toast">
            <span>{t.message}</span>
            {t.action && (
              <button
                type="button"
                className="text-btn coral"
                onClick={() => {
                  t.action!.run();
                  useOverlay.setState({ toast: null });
                }}
              >
                {t.action.label}
              </button>
            )}
          </div>
        </div>
      )}
    </>,
    document.body,
  );
}
