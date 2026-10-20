# Poora export format — v1

One JSON file moves your data between the **Android app** (Settings → Export / Import data) and the
**web app** (Settings → Export / Import data), in either direction. Both apps write and read exactly
this structure; [`sample-v1.json`](sample-v1.json) is the contract. Both test suites import it and
export it again, and the result must match field for field:

- app: `apps/mobile/test/features/settings/export_format_test.dart`
- web: `apps/web/src/features/settings/dataTransfer.test.ts`

Importing **replaces** everything on the receiving side (it's a transfer, not a merge).

## Top level

| Key | Type | Notes |
|---|---|---|
| `app` | string | `"Poora"` |
| `format` | int | `1`. Readers reject any other value. |
| `exportedAt` | string | ISO timestamp; informational |
| `tasks` | Task[] | includes soft-deleted rows (`deletedAt` set) |
| `taskReminders` | Reminder[] | |
| `occurrenceRecords` | Record[] | only occurrences that differ from the generated default |
| `focusSessions` | Session[] | finished sessions |
| `presets` | Preset[] | user-saved focus presets |
| `settings` | `{ key, value }[]` | all values are strings |

The live focus session and held reminders are device-local and never exported.

## Conventions

- **Calendar dates** (`startDate`, `endsOn`, `occurrenceDate`, `overrideDate`, `linkedOccurrenceDate`):
  `"YYYY-MM-DD"` strings, in the user's local calendar.
- **Instants** (`createdAt`, `updatedAt`, `deletedAt`, `completedAt`, `startedAt`, `endedAt`): epoch
  **milliseconds** (int).
- **Minutes of day** (`startMinute`, `overrideStartMinute`, `atMinute`): 0–1439.
- **Colours**: ARGB int, e.g. coral `0xFFF2705E` = `4294078558`.
- Missing optional values are `null`, never omitted.

## Rows

**Task**: `id`, `title`, `notes?`, `color`, `tag?`, `priority` (0 none · 1 low · 2 high), `allDay`,
`startDate`, `startMinute?`, `durationMin?`, `repeatKind` (`none` · `rrule` · `quota`), `rrule?`
(RFC 5545 body without DTSTART/UNTIL/COUNT, e.g. `FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE,FR`),
`quotaPerWeek?`, `quotaPreferredDays?` (ISO weekdays, `"2,4,6"`), `endsOn?`, `endsAfterCount?`,
`seriesId`, `timeZone?`, `createdAt`, `updatedAt`, `deletedAt?`.

**Reminder**: `id`, `taskId`, `offsetMin` (negative = before), `atMinute?` (set for "on the day at …").

**Record**: `id`, `taskId`, `occurrenceDate` (the original generated date — unique per task), `status`
(`none` · `done` · `skipped` · `deleted`; "missed" is derived, never stored), `completedAt?`,
`overrideDate?`, `overrideStartMinute?`, `overrideTitle?`, `late` (back-filled completion).

**Session**: `id`, `startedAt`, `endedAt?`, `plannedFocusMin`, `shortBreakMin`, `longBreakMin`,
`longEvery`, `focusMsCompleted`, `phasesCompleted`, `endedEarly`, `linkedTaskId?`, `linkedOccurrenceDate?`.

**Preset**: `id`, `name`, `focusMin`, `shortMin`, `longMin`, `longEvery`, `sort`.

## Changing the format

Bump `format`, update `sample-v<n>.json` and both tests in the same change, and keep each reader
accepting the previous version (or migrate it) so older exports still import.
