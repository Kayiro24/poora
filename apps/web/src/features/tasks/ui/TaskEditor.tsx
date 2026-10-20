import { useMemo, useState, type ReactNode } from 'react';
import { db } from '../../../core/db/store';
import { getSettings, useOccurrences, useSettings, useToday } from '../../../core/hooks';
import { Feedback } from '../../../core/platform/feedback';
import { Notify } from '../../../core/platform/notifications';
import { css, T, TaskColors } from '../../../core/theme/tokens';
import { Range, type Day } from '../../../core/time/days';
import { Fmt } from '../../../core/time/format';
import { Icon, type IconName } from '../../../core/widgets/Icon';
import { confirm, toast } from '../../../core/widgets/overlays';
import { NumberSheet, Pill, Sheet } from '../../../core/widgets/widgets';
import { TasksRepository } from '../data/tasksRepository';
import { isRecurring, newId, Occ, Reminders, type Occurrence, type Priority, type Task, type TaskReminder } from '../domain/models';
import { Rules, type RepeatRule } from '../domain/recurrence';
import { RepeatPicker } from './RepeatPicker';
import { askScope, closeEditor, toggleDone, useEditor, useTasksView } from './tasksUi';

const ASKED_KEY = 'asked_reminder_permissions';
const toTime = (m: number) => `${String(Math.floor(m / 60) % 24).padStart(2, '0')}:${String(m % 60).padStart(2, '0')}`;
const fromTime = (v: string) => {
  const [h, m] = v.split(':').map(Number);
  return h * 60 + m;
};

/** Global host: one editor sheet for the whole app. */
export function TaskEditorHost() {
  const e = useEditor();
  return (
    <Sheet open={e.open} onClose={closeEditor} tall label={e.occurrence ? 'Edit task' : 'New task'}>
      {e.open && <TaskEditor key={e.nonce} />}
    </Sheet>
  );
}

function TaskEditor() {
  const e = useEditor.getState();
  const settings = useSettings();
  const selectedDay = useTasksView((s) => s.selected);
  const o = e.occurrence;
  const editing = !!o;

  const init = useMemo(() => {
    if (o) {
      const t = o.task;
      return {
        title: o.title, notes: t.notes ?? '', tag: t.tag ?? '', color: t.color, date: o.date, allDay: t.allDay,
        startMinute: o.startMinute ?? 540, duration: t.durationMin ?? 30, rule: Rules.fromTask(t), reminders: [...t.reminders], priority: t.priority,
      };
    }
    const now = new Date();
    const next = Math.min((Math.floor((now.getHours() * 60 + now.getMinutes()) / 30) + 1) * 30, 23 * 60 + 30);
    const s = getSettings();
    return {
      title: '', notes: '', tag: '', color: TaskColors.all[0], date: e.date ?? selectedDay, allDay: false,
      startMinute: e.startMinute ?? next, duration: e.durationMin ?? 30, rule: Rules.none,
      reminders: s.defaultReminderMin != null ? [{ id: newId(), offsetMin: -s.defaultReminderMin, atMinute: null }] : [],
      priority: 0 as Priority,
    };
  }, [o, e.date, e.startMinute, e.durationMin, selectedDay]);

  const [title, setTitle] = useState(init.title);
  const [notes, setNotes] = useState(init.notes);
  const [tag, setTag] = useState(init.tag);
  const [color, setColor] = useState(init.color);
  const [date, setDate] = useState<Day>(init.date);
  const [allDay, setAllDay] = useState(init.allDay);
  const [startMinute, setStartMinute] = useState(init.startMinute);
  const [duration, setDuration] = useState(init.duration);
  const [rule, setRule] = useState<RepeatRule>(init.rule);
  const [reminders, setReminders] = useState<TaskReminder[]>(init.reminders);
  const [priority, setPriority] = useState<Priority>(init.priority);
  const [sheet, setSheet] = useState<'repeat' | 'reminder' | 'duration' | null>(null);
  const tags = useMemo(() => TasksRepository.tags(), []);
  const time = (m: number) => Fmt.minute(m, settings.use24h);
  const valid = title.trim().length > 0;

  const build = (): Task => {
    const now = Date.now();
    const base: Task = o?.task ?? {
      id: newId(), title: '', notes: null, color, tag: null, priority: 0, allDay: false, startDate: date,
      startMinute: null, durationMin: null, repeatKind: 'none', rrule: null, quotaPerWeek: null, quotaPreferredDays: [],
      endsOn: null, endsAfterCount: null, seriesId: '', timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone,
      createdAt: now, updatedAt: now, deletedAt: null, reminders: [],
    };
    return Rules.applyTo(rule, {
      ...base,
      title: title.trim(),
      notes: notes.trim() || null,
      color,
      tag: tag.trim() || null,
      priority,
      allDay,
      startDate: date,
      startMinute: allDay ? null : startMinute,
      durationMin: allDay ? null : duration,
      seriesId: base.seriesId || base.id,
      reminders,
      updatedAt: now,
    });
  };

  const save = async () => {
    if (!valid) return;
    const edited = build();
    if (o && isRecurring(o.task)) {
      const scope = await askScope();
      if (!scope) return;
      TasksRepository.save(edited, o, scope);
    } else if (o) TasksRepository.save(edited, o);
    else TasksRepository.create(edited);
    Feedback.light();
    closeEditor();
    if (reminders.length && !db().settings[ASKED_KEY]) {
      db().setSettings({ [ASKED_KEY]: 'true' });
      const ok = await Notify.request();
      if (!ok) toast('Reminders need notification permission — you can allow it in Settings.');
    }
  };

  const remove = async () => {
    if (!o) return;
    if (isRecurring(o.task)) {
      const scope = await askScope('Delete recurring task');
      if (!scope) return;
      TasksRepository.delete(o, scope);
    } else {
      if (!(await confirm({ title: 'Delete task?', body: `“${o.title}” will be removed.`, action: 'Delete', cancel: 'Keep', danger: true }))) return;
      TasksRepository.delete(o);
    }
    closeEditor();
  };

  const matchingTags = tags.filter((t) => t.toLowerCase().includes(tag.trim().toLowerCase()) && t !== tag.trim()).slice(0, 8);

  return (
    <div>
      <div className="row" style={{ position: 'sticky', top: 0, background: T.surface, zIndex: 2, padding: '4px 0 12px' }}>
        <button type="button" className="text-btn" aria-label="Close" onClick={closeEditor}>
          <Icon name="close" />
        </button>
        <h2 className="display d20" style={{ flex: 1, textAlign: 'center' }}>{editing ? 'Edit task' : 'New task'}</h2>
        <button type="button" className="btn coral" style={{ height: 40, fontSize: 16, padding: '0 20px' }} disabled={!valid} onClick={save}>
          Save
        </button>
      </div>

      {/* 1. Title */}
      <input
        className="title-input"
        placeholder="WHAT NEEDS DOING?"
        aria-label="Title"
        value={title}
        autoFocus={!editing}
        onChange={(ev) => setTitle(ev.target.value)}
        onKeyDown={(ev) => ev.key === 'Enter' && save()}
      />
      {o && <StatusRow occurrence={o} />}

      {/* 2. Colour */}
      <Label>Colour</Label>
      <div className="row wrap" style={{ gap: 10 }} role="radiogroup" aria-label="Colour">
        {TaskColors.all.map((c, i) => (
          <button
            key={c}
            type="button"
            role="radio"
            aria-checked={c === color}
            aria-label={TaskColors.names[i]}
            onClick={() => setColor(c)}
            style={{ width: 40, height: 40, borderRadius: '50%', background: css(c), border: `3px solid ${c === color ? T.textPrimary : 'transparent'}`, display: 'grid', placeItems: 'center', color: T.textInverse }}
          >
            {c === color && <Icon name="check" size={18} />}
          </button>
        ))}
      </div>

      {/* 3. Category */}
      <Label>Category</Label>
      <input className="input" placeholder="e.g. Health, Work" value={tag} onChange={(ev) => setTag(ev.target.value)} aria-label="Category" />
      {matchingTags.length > 0 && (
        <div className="chip-row" style={{ marginTop: 8 }}>
          {matchingTags.map((t) => <Pill key={t} label={t} dense onClick={() => setTag(t)} />)}
        </div>
      )}

      {/* 4–5. Date, all day, time, duration */}
      <Group>
        <Row icon="event" title="Date">
          <input type="date" className="input editor-field" value={date} onChange={(ev) => ev.target.value && setDate(ev.target.value)} aria-label="Date" />
        </Row>
        <button type="button" className="srow" role="switch" aria-checked={allDay} onClick={() => { setAllDay(!allDay); setReminders([]); }}>
          <Icon name="sun" className="icon muted" />
          <span className="t body-l">All day</span>
          <span className={`switch${allDay ? ' on' : ''}`} style={allDay ? { background: T.coral } : undefined} aria-hidden />
        </button>
        {!allDay && (
          <>
            <Row icon="schedule" title="Start time">
              <input type="time" className="input editor-field mono" value={toTime(startMinute)} onChange={(ev) => ev.target.value && setStartMinute(fromTime(ev.target.value))} aria-label="Start time" />
            </Row>
            <Row icon="timer" title="Duration">
              <button type="button" className="input editor-field mono" style={{ textAlign: 'right' }} onClick={() => setSheet('duration')}>
                {Fmt.duration(duration)}
              </button>
            </Row>
            <Row icon="schedule" title="Ends at">
              <input
                type="time"
                className="input editor-field mono"
                value={toTime((startMinute + duration) % 1440)}
                aria-label="End time"
                onChange={(ev) => {
                  if (!ev.target.value) return;
                  let d = fromTime(ev.target.value) - startMinute;
                  if (d <= 0) d += 1440;
                  setDuration(d);
                }}
              />
            </Row>
          </>
        )}
      </Group>

      {/* 6. Repeat */}
      <Group>
        <button type="button" className="srow" onClick={() => setSheet('repeat')}>
          <Icon name="repeat" className="icon muted" />
          <span className="t body-l">Repeat</span>
          <span className="muted" style={{ textAlign: 'right' }}>{Rules.summary(rule, date)}</span>
          <Icon name="chevronRight" className="icon muted" />
        </button>
      </Group>

      {/* 7. Reminders */}
      <Group>
        {reminders.map((r) => (
          <div key={r.id} className="srow">
            <Icon name="notify" className="icon muted" />
            <span className="t body-l">{Reminders.label(r, time)}</span>
            <button type="button" className="text-btn" aria-label="Remove reminder" onClick={() => setReminders(reminders.filter((x) => x !== r))}>
              <Icon name="close" />
            </button>
          </div>
        ))}
        {reminders.length < 5 && (
          <button type="button" className="srow" onClick={() => setSheet('reminder')}>
            <Icon name="plus" className="icon" />
            <span className="t body-l" style={{ color: T.coral }}>Add reminder</span>
          </button>
        )}
      </Group>
      {reminders.length > 0 && Notify.permission() === 'unsupported' && (
        <p className="body-s">This browser doesn’t support notifications.</p>
      )}

      {/* 8. Notes */}
      <Label>Notes</Label>
      <textarea className="input" placeholder="Add details" value={notes} onChange={(ev) => setNotes(ev.target.value)} aria-label="Notes" rows={3} />

      {/* 9. Priority */}
      <Label>Priority</Label>
      <div className="chip-row">
        {(['None', 'Low', 'High'] as const).map((l, i) => (
          <Pill key={l} label={l} dot={i === 2 ? T.sun : undefined} filled={priority === i} color={priority === i ? T.textPrimary : undefined} onClick={() => setPriority(i as Priority)} />
        ))}
      </div>

      {editing && (
        <div style={{ textAlign: 'center', marginTop: 32 }}>
          <button type="button" className="text-btn danger" onClick={remove}>
            <span className="row"><Icon name="delete" /> Delete task</span>
          </button>
        </div>
      )}

      <RepeatPicker open={sheet === 'repeat'} start={date} current={rule} onPick={setRule} onClose={() => setSheet(null)} />
      <NumberSheet
        open={sheet === 'duration'}
        title="Duration (minutes)"
        min={15}
        max={720}
        step={15}
        value={Math.max(15, duration - (duration % 15))}
        accent={T.coral}
        onPick={(v) => { setDuration(v); setSheet(null); }}
        onClose={() => setSheet(null)}
      />
      <ReminderSheet
        open={sheet === 'reminder'}
        allDay={allDay}
        time={time}
        onPick={(r) => {
          if (!reminders.some((x) => Reminders.same(x, r))) setReminders([...reminders, r]);
          setSheet(null);
        }}
        onClose={() => setSheet(null)}
      />
    </div>
  );
}

const Label = ({ children }: { children: string }) => (
  <p className="caps-label" style={{ margin: '20px 0 8px' }}>{children}</p>
);

const Group = ({ children }: { children: ReactNode }) => (
  <div className="group" style={{ background: T.surfaceHigh, marginTop: 12, marginBottom: 0 }}>{children}</div>
);

const Row = ({ icon, title, children }: { icon: IconName; title: string; children: ReactNode }) => (
  <label className="srow" style={{ cursor: 'pointer' }}>
    <Icon name={icon} className="icon muted" />
    <span className="t body-l">{title}</span>
    {children}
  </label>
);

function ReminderSheet(p: { open: boolean; allDay: boolean; time: (m: number) => string; onPick: (r: TaskReminder) => void; onClose: () => void }) {
  const [at, setAt] = useState(540);
  const [custom, setCustom] = useState(20);
  const mk = (offsetMin: number, atMinute: number | null = null): TaskReminder => ({ id: newId(), offsetMin, atMinute });
  return (
    <Sheet open={p.open} onClose={p.onClose} label="Add reminder">
      <h2 className="display d24" style={{ margin: '4px 0 8px' }}>Add reminder</h2>
      {p.allDay ? (
        <>
          <label className="srow" style={{ padding: '8px 0' }}>
            <span className="t body-l">At</span>
            <input type="time" className="input editor-field mono" value={toTime(at)} onChange={(e) => e.target.value && setAt(fromTime(e.target.value))} />
          </label>
          <button type="button" className="list-item body-l" onClick={() => p.onPick(mk(0, at))}>On the day at {p.time(at)}</button>
          <button type="button" className="list-item body-l" onClick={() => p.onPick(mk(-1440, at))}>Day before at {p.time(at)}</button>
        </>
      ) : (
        <>
          {[0, 5, 10, 15, 30, 60].map((m) => (
            <button key={m} type="button" className="list-item body-l" onClick={() => p.onPick(mk(-m))}>
              {Reminders.label(mk(-m), p.time)}
            </button>
          ))}
          <button type="button" className="list-item body-l" onClick={() => p.onPick(mk(-1440, 540))}>1 day before (at {p.time(540)})</button>
          <div className="srow" style={{ padding: '8px 4px' }}>
            <span className="t body-l">Custom</span>
            <input type="number" min={1} max={1440} className="input mono" style={{ width: 90 }} value={custom} onChange={(e) => setCustom(Number(e.target.value))} aria-label="Minutes before" />
            <span className="muted">min before</span>
            <button type="button" className="text-btn coral" disabled={!(custom > 0)} onClick={() => p.onPick(mk(-custom))}>Add</button>
          </div>
        </>
      )}
    </Sheet>
  );
}

/** Done / skip toggles inside the editor, reading the live occurrence. */
function StatusRow({ occurrence }: { occurrence: Occurrence }) {
  const today = useToday();
  const live = useOccurrences(Range.day(occurrence.date)).find((x) => Occ.key(x) === Occ.key(occurrence)) ?? occurrence;
  const done = live.status === 'done';
  const skipped = live.status === 'skipped';
  return (
    <div className="chip-row" style={{ marginTop: 8 }}>
      <Pill
        label={done ? 'Done' : live.date < today ? 'Mark done (late)' : 'Mark done'}
        icon={done ? 'check' : undefined}
        filled={done}
        color={done ? T.mint : undefined}
        onClick={() => toggleDone(live)}
      />
      {isRecurring(live.task) && (
        <Pill label={skipped ? 'Skipped' : 'Skip this time'} icon="redo" filled={skipped} color={skipped ? T.textSecondary : undefined} onClick={() => TasksRepository.setSkipped(live, !skipped)} />
      )}
    </div>
  );
}
