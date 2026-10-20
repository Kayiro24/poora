import { useState, type FormEvent } from 'react';
import { Link } from 'react-router';
import { AppInfo } from '../core/appInfo';
import { T } from '../core/theme/tokens';
import { Icon } from '../core/widgets/Icon';
import { metaFor, Site } from '../seo/site';
import { Breadcrumbs } from './SiteLayout';

type Status = 'idle' | 'sending' | 'sent' | 'error';
const topics = ['Feedback', 'Bug report', 'Question', 'Other'];

/**
 * Working contact form. With VITE_CONTACT_ENDPOINT (e.g. a Formspree form
 * URL) it posts the message; without one it opens a pre-filled GitHub issue,
 * so it always has a real destination.
 */
export function ContactPage() {
  const [status, setStatus] = useState<Status>('idle');
  const [errors, setErrors] = useState<Record<string, string>>({});

  const submit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const form = e.currentTarget;
    const data = Object.fromEntries(new FormData(form)) as Record<string, string>;
    if (data.website) return; // honeypot: bots fill hidden fields
    const errs: Record<string, string> = {};
    if (!data.name?.trim()) errs.name = 'Please enter your name.';
    if (!/^\S+@\S+\.\S+$/.test(data.email ?? '')) errs.email = 'Please enter a valid email address.';
    if ((data.message ?? '').trim().length < 10) errs.message = 'Please write at least a sentence (10+ characters).';
    setErrors(errs);
    if (Object.keys(errs).length) {
      form.querySelector<HTMLElement>(`[name="${Object.keys(errs)[0]}"]`)?.focus();
      return;
    }
    const subject = `[${data.topic}] ${AppInfo.name} — message from ${data.name}`;
    if (!Site.contactEndpoint) {
      const body = `${data.message}\n\n—\nFrom: ${data.name} (${data.email})`;
      window.open(`${Site.repo}/issues/new?title=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`, '_blank', 'noopener');
      setStatus('sent');
      form.reset();
      return;
    }
    setStatus('sending');
    try {
      const res = await fetch(Site.contactEndpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
        body: JSON.stringify({ name: data.name, email: data.email, topic: data.topic, message: data.message, _subject: subject }),
      });
      if (!res.ok) throw new Error(String(res.status));
      setStatus('sent');
      form.reset();
    } catch {
      setStatus('error');
    }
  };

  const field = (name: string) => ({
    id: `c-${name}`,
    name,
    'aria-invalid': errors[name] ? true : undefined,
    'aria-describedby': errors[name] ? `c-${name}-err` : undefined,
  });
  const err = (name: string) => errors[name] && <p id={`c-${name}-err`} className="field-error">{errors[name]}</p>;

  return (
    <div className="site-page">
      <Breadcrumbs crumbs={metaFor('/contact').crumbs!} />
      <h1 className="display d40">Contact</h1>
      <p className="muted" style={{ maxWidth: 560, lineHeight: 1.5 }}>
        Feedback, a bug, or an idea for {AppInfo.name}? Send it here — every message is read. For privacy questions, see the{' '}
        <Link to="/privacy">privacy policy</Link> first.
      </p>

      {status === 'sent' ? (
        <div className="card" role="status" style={{ marginTop: 24, maxWidth: 560 }}>
          <div className="row" style={{ gap: 12 }}>
            <span style={{ width: 40, height: 40, borderRadius: '50%', background: T.mint, color: T.textInverse, display: 'grid', placeItems: 'center' }}>
              <Icon name="check" />
            </span>
            <div>
              <h2 className="display d24">Thanks — message sent</h2>
              <p className="muted" style={{ margin: '4px 0 0' }}>
                {Site.contactEndpoint ? 'We’ll reply to the email you gave.' : 'Finish posting it on the GitHub tab that just opened.'}
              </p>
            </div>
          </div>
          <button type="button" className="text-btn coral" style={{ marginTop: 12 }} onClick={() => setStatus('idle')}>Send another</button>
        </div>
      ) : (
        <form className="contact-form" onSubmit={submit} noValidate aria-describedby="c-note">
          <div className="field">
            <label htmlFor="c-name">Name</label>
            <input className="input" type="text" autoComplete="name" required {...field('name')} />
            {err('name')}
          </div>
          <div className="field">
            <label htmlFor="c-email">Email</label>
            <input className="input" type="email" autoComplete="email" required {...field('email')} />
            {err('email')}
          </div>
          <div className="field">
            <label htmlFor="c-topic">Topic</label>
            <select className="input" {...field('topic')} defaultValue="Feedback">
              {topics.map((t) => <option key={t}>{t}</option>)}
            </select>
          </div>
          <div className="field">
            <label htmlFor="c-message">Message</label>
            <textarea className="input" rows={6} required {...field('message')} />
            {err('message')}
          </div>
          {/* Honeypot — hidden from people and screen readers. */}
          <div aria-hidden="true" style={{ position: 'absolute', left: '-10000px' }}>
            <label htmlFor="c-website">Website</label>
            <input id="c-website" name="website" type="text" tabIndex={-1} autoComplete="off" />
          </div>
          {status === 'error' && <p className="field-error" role="alert">Couldn’t send just now. Please try again in a moment.</p>}
          <button type="submit" className="btn coral" disabled={status === 'sending'}>{status === 'sending' ? 'Sending…' : 'Send message'}</button>
          <p id="c-note" className="body-s">
            {Site.contactEndpoint
              ? 'We use your details only to reply.'
              : 'Sending opens a pre-filled GitHub issue (a free GitHub account is needed). We use your details only to reply.'}
          </p>
        </form>
      )}
    </div>
  );
}
