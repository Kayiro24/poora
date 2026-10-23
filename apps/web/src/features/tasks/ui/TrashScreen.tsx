import { useNavigate } from 'react-router';
import { useNow, useTrashed } from '../../../core/hooks';
import { css, T } from '../../../core/theme/tokens';
import { Icon } from '../../../core/widgets/Icon';
import { confirm } from '../../../core/widgets/overlays';
import { EmptyState, ScreenHeader } from '../../../core/widgets/widgets';
import { TasksRepository } from '../data/tasksRepository';
import { Rules } from '../domain/recurrence';

const DAY = 86_400_000;

function ago(d: number, now: number) {
  const days = Math.floor((now - d) / DAY);
  return days === 0 ? 'today' : days === 1 ? 'yesterday' : `${days} days ago`;
}

function left(d: number, now: number) {
  const n = TasksRepository.trashDays - Math.floor((now - d) / DAY);
  return n <= 1 ? '1 day' : `${n} days`;
}

/** Trash: deleted tasks are kept 30 days (like Google Calendar), then purged. */
export function TrashScreen() {
  const navigate = useNavigate();
  const trashed = useTrashed();
  const now = useNow(60_000).getTime();
  const empty = async () => {
    const n = trashed.length;
    if (await confirm({ title: 'Empty Trash?', body: `${n} task${n === 1 ? '' : 's'} will be deleted forever.`, action: 'Empty', cancel: 'Cancel', danger: true })) {
      TasksRepository.emptyTrash();
    }
  };
  return (
    <div className="page">
      <ScreenHeader
        title="Trash"
        size={32}
        onBack={() => navigate(-1)}
        trailing={trashed.length > 0 && <button type="button" className="text-btn" style={{ color: T.coralSoft }} onClick={empty}>Empty</button>}
      />
      <p className="muted" style={{ margin: '8px 0 24px' }}>
        Deleted tasks stay here for {TasksRepository.trashDays} days, then they’re removed for good.
      </p>
      {trashed.length === 0 ? (
        <EmptyState message="Trash is empty." mood="calm" />
      ) : (
        <div className="stack">
          {trashed.map((t) => (
            <div key={t.id} className="card row" style={{ padding: 0, overflow: 'hidden', alignItems: 'stretch', gap: 0 }}>
              <span style={{ width: 4, flex: 'none', background: css(t.color) }} />
              <div style={{ flex: 1, minWidth: 0, padding: '12px 4px 12px 14px' }}>
                <div className="display d18 truncate">{t.title}</div>
                <div className="body-s">
                  {Rules.summary(Rules.fromTask(t), t.startDate)} · deleted {ago(t.deletedAt!, now)} · {left(t.deletedAt!, now)} left
                </div>
              </div>
              <div className="row" style={{ gap: 4, paddingRight: 8 }}>
                <button type="button" className="text-btn" style={{ color: T.mint }} onClick={() => TasksRepository.restore(t.id)}>
                  Restore
                </button>
                <button type="button" className="text-btn" aria-label={`Delete ${t.title} forever`} title="Delete forever" onClick={() => TasksRepository.deleteForever(t.id)}>
                  <Icon name="deleteForever" />
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
