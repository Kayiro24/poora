import { db } from '../../core/db/store';
import { ReminderScheduler } from '../../core/platform/reminderScheduler';
import { FocusController } from '../focus/application/focusController';
import { resetFocusDraft } from '../focus/ui/FocusScreen';
import { resetHomeDay } from '../home/HomeScreen';
import { TasksView } from '../tasks/ui/tasksUi';

/** "Delete all data": back to a first-launch state (mirrors the app's DataReset). */
export function resetAllData() {
  FocusController.discard();
  ReminderScheduler.cancelAll();
  db().wipe();
  resetFocusDraft();
  resetHomeDay();
  TasksView.reset();
}
