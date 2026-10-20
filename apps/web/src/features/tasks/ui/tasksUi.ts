import { create } from 'zustand';
import { getToday } from '../../../core/hooks';
import { Feedback } from '../../../core/platform/feedback';
import { choose, toast } from '../../../core/widgets/overlays';
import { Days, type Day } from '../../../core/time/days';
import { TasksRepository } from '../data/tasksRepository';
import { isRecurring, type Occurrence } from '../domain/models';
import type { EditScope } from '../domain/seriesEdits';

export type TaskView = 'day' | 'threeDay' | 'week' | 'month' | 'schedule';
export const views: { id: TaskView; label: string; columns: number }[] = [
  { id: 'day', label: 'Day', columns: 1 },
  { id: 'threeDay', label: '3 Day', columns: 3 },
  { id: 'week', label: 'Week', columns: 7 },
  { id: 'month', label: 'Month', columns: 0 },
  { id: 'schedule', label: 'Schedule', columns: 0 },
];

interface TasksViewState {
  view: TaskView;
  selected: Day;
  showCompletion: boolean;
  query: string;
}

export const useTasksView = create<TasksViewState>(() => ({ view: 'day', selected: getToday(), showCompletion: false, query: '' }));

export const TasksView = {
  setView: (view: TaskView) => useTasksView.setState({ view }),
  select: (selected: Day) => useTasksView.setState({ selected }),
  today: () => useTasksView.setState({ selected: getToday() }),
  toggleCompletion: () => useTasksView.setState((s) => ({ showCompletion: !s.showCompletion })),
  search: (query: string) => useTasksView.setState({ query }),
  page(dir: number) {
    const { view, selected } = useTasksView.getState();
    const cols = views.find((v) => v.id === view)!.columns || 7;
    useTasksView.setState({ selected: view === 'month' ? Days.addMonths(selected, dir) : Days.add(selected, cols * dir) });
  },
  reset: () => useTasksView.setState({ view: 'day', selected: getToday(), showCompletion: false, query: '' }),
};

/** The task editor is one global sheet that any screen can open. */
interface EditorState {
  open: boolean;
  occurrence: Occurrence | null;
  date: Day | null;
  startMinute: number | null;
  durationMin: number | null;
  nonce: number;
}
export const useEditor = create<EditorState>(() => ({ open: false, occurrence: null, date: null, startMinute: null, durationMin: null, nonce: 0 }));

export function openEditor(opts: { occurrence?: Occurrence; date?: Day; startMinute?: number; durationMin?: number } = {}) {
  useEditor.setState((s) => ({
    open: true,
    occurrence: opts.occurrence ?? null,
    date: opts.date ?? null,
    startMinute: opts.startMinute ?? null,
    durationMin: opts.durationMin ?? null,
    nonce: s.nonce + 1,
  }));
}
export const closeEditor = () => useEditor.setState({ open: false });

/** "This task / This and following tasks / All tasks" (Google Calendar). */
export const askScope = (title = 'Edit recurring task') =>
  choose<EditScope>({
    title,
    choices: [
      { label: 'This task', value: 'thisOne' },
      { label: 'This and following tasks', value: 'thisAndFollowing' },
      { label: 'All tasks', value: 'all' },
    ],
  });

export function toggleDone(o: Occurrence) {
  const done = o.status !== 'done';
  if (done) Feedback.light();
  else Feedback.selection();
  TasksRepository.setDone(o, done);
}

/** Swipe-left / secondary action: skip a recurring occurrence, delete a one-off. With undo. */
export function skipOrDelete(o: Occurrence) {
  Feedback.selection();
  if (isRecurring(o.task)) {
    const skipped = o.status !== 'skipped';
    TasksRepository.setSkipped(o, skipped);
    toast(skipped ? 'Skipped this time' : 'Restored', { label: 'Undo', run: () => TasksRepository.setSkipped(o, !skipped) });
  } else {
    TasksRepository.delete(o);
    toast('Task deleted', { label: 'Undo', run: () => TasksRepository.restore(o.task) });
  }
}

export async function rescheduleOccurrence(o: Occurrence, date: Day, startMinute: number) {
  let scope: EditScope = 'thisOne';
  if (isRecurring(o.task)) {
    const s = await askScope('Move recurring task');
    if (!s) return;
    scope = s;
  }
  Feedback.light();
  TasksRepository.reschedule(o, date, startMinute, scope);
}
