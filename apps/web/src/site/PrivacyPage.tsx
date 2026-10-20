import { Link } from 'react-router';
import { AppInfo } from '../core/appInfo';
import { metaFor, Site } from '../seo/site';
import { Breadcrumbs, Prose } from './SiteLayout';

const UPDATED = '21 October 2026';

/** Plain-language privacy policy; accurate to how both apps actually behave. */
export function PrivacyPage() {
  return (
    <div className="site-page">
      <Breadcrumbs crumbs={metaFor('/privacy').crumbs!} />
      <h1 className="display d40">Privacy policy</h1>
      <p className="body-s">Last updated {UPDATED}</p>
      <Prose>
        <p>
          {AppInfo.name} is built so your tasks, focus sessions and settings never leave your device. This page explains exactly what
          the website and the Android app do with data.
        </p>

        <h2>The short version</h2>
        <ul>
          <li>No account, no sign-in, no servers that store your data.</li>
          <li>Your tasks and focus history are stored only on your device — in your browser’s local storage on the web, and in a local database on Android.</li>
          <li>We never sell or share data. There are no ads.</li>
          <li>Analytics on this website runs only if you agree to it, and never sees your tasks.</li>
        </ul>

        <h2>Data stored on your device</h2>
        <p>
          Tasks, repeat rules, reminders, completions, focus sessions, presets and preferences are saved locally so the app works offline.
          Clearing your browser’s site data, uninstalling the app, or using <strong>Settings → Delete all data</strong> removes them
          permanently. Exports you create are files you control.
        </p>

        <h2>Notifications</h2>
        <p>
          If you allow notifications, reminders are scheduled on your device. On Android, the optional “Silence phone during focus”
          feature changes your Do Not Disturb setting during a session and restores it afterwards; this permission is used for nothing else.
        </p>

        <h2 id="analytics">Website analytics</h2>
        {Site.gaId ? (
          <p>
            With your consent, this website uses Google Analytics 4 to count page views (with IP anonymisation, and Google Signals and
            ad personalisation turned off). It sets cookies only after you choose <em>Allow</em> in the banner. Task data is never sent.
            You can change your choice by clearing this site’s data in your browser. Google’s processing is described in{' '}
            <a href="https://policies.google.com/privacy" rel="noopener">Google’s privacy policy</a>.
          </p>
        ) : (
          <p>This website currently runs no analytics and sets no tracking cookies.</p>
        )}

        <h2>Contact form</h2>
        <p>
          When you send a message through the <Link to="/contact">contact page</Link>, the name, email address and message you enter are
          delivered to us{Site.contactEndpoint ? ' via our form provider (Formspree)' : ' by opening a GitHub issue under your GitHub account'}.
          We use them only to reply.
        </p>

        <h2>Hosting</h2>
        <p>
          The website is hosted on Vercel, and Android releases are published on GitHub. Both may log technical data such as IP
          addresses when files are served; see <a href="https://vercel.com/legal/privacy-policy" rel="noopener">Vercel’s privacy policy</a> and{' '}
          <a href="https://docs.github.com/site-policy/privacy-policies/github-general-privacy-statement" rel="noopener">GitHub’s privacy statement</a>.
        </p>

        <h2>Children</h2>
        <p>{AppInfo.name} doesn’t knowingly collect personal information from anyone, including children.</p>

        <h2>Changes and questions</h2>
        <p>
          If this policy changes, the date above will change too. Questions? <Link to="/contact">Contact us</Link>.
        </p>
      </Prose>
    </div>
  );
}
