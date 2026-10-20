# Decisions

Choices made where SPEC.md was silent, ambiguous, or met a platform/tooling limit.
Rule applied throughout: pick the calmer, simpler option.

## Name & brand (2026-10-20)

- The app is **Poora** (पूरा, "whole, complete, done"), replacing the spec's placeholder "Tempo".
  Dart package `poora`, Android `applicationId`/namespace and iOS bundle ID `com.poora.app`,
  DB file `poora.sqlite`. Name and taglines live only in `AppInfo`.
- Taglines: **"Make every day whole."** (primary) and "Focus fully. Finish fully." (secondary).
- Logo: a P whose bowl is a closed completion ring (coral stem, sage ring, ice closing stroke), so the
  app's core visual idea is the brand. Drawn in code (`PooraMark`) and rendered for platforms by
  `tool/render_logo.py` → `flutter_launcher_icons` (adaptive + Android 13 themed icon, iOS set) and
  `flutter_native_splash` (incl. Android 12 splash API). Notification icon is a vector of the same mark.
- Launch: native splash (mark on charcoal), then a ~1.8 s in-app splash where the mark draws itself and
  the name and taglines settle in (tap to skip; 0.5 s and static under reduce motion), then a
  four-page first-run welcome (meaning, Focus, Finish, name). Interrupted-focus recovery is checked only
  after the splash, so its dialog never covers it.
- **Delete all data** moved to its own "Danger zone" in Settings: double confirmation, then it
  discards any live focus session (restoring DND first), wipes every table, cancels all notifications,
  resets in-memory state and returns to the welcome flow. Covered by `test/features/settings/data_reset_test.dart`.
- Production: R8 shrinking with keep rules for the notification plugin, release signing from
  `android/key.properties` (debug fallback for local runs only), predictive back, global error
  handlers with a calm release-mode error widget, iOS notification delegate and background-action
  registrant. No `INTERNET` permission (verified in the merged release manifest).

## Versions (resolved 2026-10-19, Flutter 3.47.7 / Dart 3.13.5)

| Package | Version |
|---|---|
| flutter_riverpod | 3.4.3 |
| go_router | 18.1.0 |
| drift / drift_dev | 2.35.2 / 2.35.1 (sqlite3 3.5.2, native lib bundled via build hooks) |
| rrule | 0.2.18 |
| flutter_local_notifications | 22.3.2 |
| flutter_launcher_icons / flutter_native_splash (dev) | 0.14.4 / 2.4.8 |
| timezone / flutter_timezone | 0.11.2 / 5.1.1 |
| wakelock_plus | 1.8.1 |
| fl_chart | 1.2.0 |
| flutter_svg | 2.3.0 |
| audioplayers | 6.8.1 |
| uuid | 4.6.0 |
| share_plus / file_picker | 13.3.1 / 13.1.0 |
| very_good_analysis | 11.0.0 |
| build_runner | 2.16.2 |

## Deviations from the tech stack (§8)

- **No `riverpod_generator`.** Providers are hand-written `Provider` / `Notifier` / `StreamProvider`.
  Drift already needs build_runner; avoiding a second generator keeps builds fast and code greppable.
- **No `permission_handler`.** Its Android plugin requires compileSdk 37, which doesn't resolve on the
  current SDK. All flows it would cover go through `flutter_local_notifications`
  (notifications, exact alarms) and the `tempo/dnd` channel (DND access), so nothing is lost.
- **No `sqlite3_flutter_libs`.** It is end-of-life; sqlite3 3.x bundles the native library itself.
- **No `flutter_animate`.** All motion uses Flutter's implicit animations
  (`AnimatedContainer`, `TweenAnimationBuilder`, …) so reduce-motion is honoured in one helper
  (`Motion.of`). Adding the package back is trivial if wanted.
- **DND** uses a ~40-line platform channel in `MainActivity.kt` (`hasAccess`, `requestAccess`,
  `getFilter`, `setFilter`) rather than a third-party plugin.

## Data model

- `occurrence_records.late` (BOOL) added — §4.11 requires back-fills to be flagged `late = true`.
- `occurrence_records.status` also allows `deleted` — "delete this occurrence" of a recurring task.
- `held_reminders.title` added so the grouped "While you focused" notification can name tasks.
- Calendar dates are stored as ISO `yyyy-MM-dd` text and handled in Dart as UTC-midnight
  `DateTime`s (`Days` helper), so day arithmetic never crosses DST. Instants are epoch ms
  (drift's default DateTime storage drops milliseconds, which the timer needs).
- The live focus session (`focus_state`) stores the timer snapshot; the session config lives in its
  `focus_sessions` row (`ended_at` NULL until finished).

## Recurrence

- RRULEs are always written with explicit `BYDAY` / `BYMONTHDAY` / `BYMONTH`, so no rule depends on
  DTSTART defaults.
- `UNTIL` and `COUNT` are applied by the generator from `ends_on` / `ends_after_count` (the stored RRULE
  body has neither), so "this and following" can move them without rewriting rules.
- A start date that doesn't match its own rule (e.g. weekly Mon/Wed starting on a Tuesday) doesn't
  produce an occurrence on the start date — the rrule package's behaviour, which is also what most
  people expect.
- **"This task" edits:** title/date/time-only changes become record overrides; any other field change
  detaches the occurrence into a one-off task in the same `series_id` (status carried over), and hides
  the original. **Drag-to-reschedule "this event"** always uses record overrides.
- "This and following" with a COUNT carries over the remaining count to the new series.
- **Times-per-week:** past days only show if done (never "missed"); today/future days show while the
  week's quota is unmet; once met, a collapsed "n/n done this week ✓" chip appears on the Day view.
  Preferred days limit *reminders*, not visibility. Quota tasks are excluded from all daily figures
  and counted weekly (§7).

## Focus

- Built-in presets: `25 / 5` (long 15, every 4), `50 / 10` (long 30, every 3), `90 / 20`
  (long 30, every 2). Saved presets (max 6) are long-press-to-delete.
- A "cycle" ends after the long break; the summary then appears. "Sessions completed" = focus phases
  finished.
- Focus-end notification is scheduled only when the app goes to background, and cancelled on return
  (§4.4 step 2 "only if the app is not in foreground").
- Reminders are held until the **projected end of the whole cycle** (assuming phases auto-advance) and
  re-projected on pause/resume and phase change.
- DND: the previous filter is persisted (`settings.dnd_prev_filter`) so it can be restored after a
  kill; restore runs on end, on pause > 5 min, on recovery-close, and at every launch with no live
  session.
- Waiting phases (auto-start off) show a visible START button; all other controls stay hidden until tap.
- iOS: one-time Focus-mode tip before the first session; no DND toggle shown.
- Milliseconds = centiseconds (2 digits), as the spec's constraints table says.

## Notifications

- Rolling 14-day window, capped at 60 pending (iOS limit 64 minus room for focus/summary).
- Recomputed on launch, on resume, on every task/record change (600 ms debounce) and after focus ends.
  There is no Dart "midnight job" while the app is closed (that needs WorkManager/BGTasks); the
  14-day horizon covers it, and the in-app `todayProvider` ticks at midnight while running.
- Reboot: the plugin's `ScheduledNotificationBootReceiver` restores pending notifications.
- "Done" from a notification in a background isolate opens the database file directly (path is in
  the payload) and cancels sibling reminders of that occurrence. In foreground it goes through the
  repository so UI streams update.
- Notification permission + exact alarm are requested the first time a task with a reminder is
  saved; denial shows a banner on Tasks and a Fix button in Settings.

## Insights & accessibility

- "Before first use" = days before the earliest task's `created_at`.
- Overall day streak counts back from today; today only counts once it qualifies, rest days are
  neutral (don't break, don't count).
- Recurring cards group by `series_id`, so split series keep one history.
- The "ring closed" pulse plays once per day per app run (in-memory flag).
- **Contrast:** dark ink on periwinkle is 4.65:1 (passes AA); light ink is 3.45:1 (fails), so every
  task colour and pastel panel uses full-strength dark text — never dimmed on periwinkle.
- **Category donut palette:** the spec's pastels fail categorical-palette checks on dark (too light,
  mint/ice read grey, sun≈mint). The donut uses deeper steps of the same hues — `#E8604E #2E8CB0
  #B8861A #8A5FD0 #2F9C6E #5C66E8`, validated for lightness band, chroma, CVD separation (worst ΔE
  7.8, so it also ships a direct-labelled legend and 2px gaps) and ≥3:1 contrast. 7+ categories
  fold into "Other". Single-series charts use one brand hue each (coral / sage).

## Lints

`very_good_analysis` with a few style-only rules disabled (see `analysis_options.yaml`), notably
`unnecessary_type_name_in_constructor` (pushes brand-new syntax), `discarded_futures` and
`async_return_with_no_await` (fire on nearly every Flutter callback). `unawaited_futures` stays on.

## Not done / known gaps

- 60 fps with 200 tasks was designed for, not profiled on a mid-range device.
- iOS has not been built (no macOS here); its config was written to the plugins' documented setup.
- No crash reporting: the app is offline by design, so errors are only logged locally.
