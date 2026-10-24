import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poora/app_router.dart';
import 'package:poora/core/notifications/notification_service.dart';
import 'package:poora/core/providers.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';
import 'package:poora/core/time/date_utils.dart';
import 'package:poora/core/time/format.dart';
import 'package:poora/core/widgets/pill_chip.dart';
import 'package:poora/core/widgets/wheel_picker.dart';
import 'package:poora/features/settings/settings_controller.dart';
import 'package:poora/features/tasks/application/tasks_providers.dart';
import 'package:poora/features/tasks/application/tasks_view.dart';
import 'package:poora/features/tasks/domain/models.dart';
import 'package:poora/features/tasks/domain/recurrence.dart';
import 'package:poora/features/tasks/domain/series_edits.dart';
import 'package:poora/features/tasks/ui/repeat_picker.dart';
import 'package:poora/features/tasks/ui/task_actions.dart';
import 'package:uuid/uuid.dart';

Future<void> showTaskEditor(
  BuildContext context, {
  Occurrence? occurrence,
  DateTime? date,
  int? startMinute,
  int? durationMin,
}) {
  return showModalBottomSheet<void>(
    context: context,
    // Above the shell's floating nav bar, so nothing at the bottom is hidden.
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.5,
      snap: true,
      snapSizes: const [0.82],
      builder: (context, scroll) => TaskEditor(
        scrollController: scroll,
        occurrence: occurrence,
        date: date,
        startMinute: startMinute,
        durationMin: durationMin,
      ),
    ),
  );
}

class TaskEditor extends ConsumerStatefulWidget {
  const TaskEditor({
    required this.scrollController,
    this.occurrence,
    this.date,
    this.startMinute,
    this.durationMin,
    super.key,
  });

  final ScrollController scrollController;
  final Occurrence? occurrence;
  final DateTime? date;
  final int? startMinute;
  final int? durationMin;

  @override
  ConsumerState<TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends ConsumerState<TaskEditor> {
  static const _uuid = Uuid();

  late final TextEditingController _title;
  late final TextEditingController _notes;
  late final TextEditingController _tag;
  late int _color;
  late DateTime _date;
  late bool _allDay;
  late int _startMinute;
  late int _duration;
  late RepeatRule _rule;
  late List<TaskReminder> _reminders;
  late Priority _priority;
  List<String> _tags = const [];
  bool _saving = false;

  Occurrence? get _occ => widget.occurrence;
  bool get _editing => _occ != null;

  @override
  void initState() {
    super.initState();
    final o = _occ;
    final settings = ref.read(settingsProvider);
    if (o != null) {
      final t = o.task;
      _title = TextEditingController(text: o.title);
      _notes = TextEditingController(text: t.notes ?? '');
      _tag = TextEditingController(text: t.tag ?? '');
      _color = t.color;
      _date = o.date;
      _allDay = t.allDay;
      _startMinute = o.startMinute ?? 9 * 60;
      _duration = t.durationMin ?? 30;
      _rule = RepeatRule.fromTask(t);
      _reminders = [...t.reminders];
      _priority = t.priority;
    } else {
      final now = ref.read(clockProvider).now();
      _title = TextEditingController();
      _notes = TextEditingController();
      _tag = TextEditingController();
      _color = TaskColors.all.first.toARGB32();
      _date = widget.date ?? ref.read(tasksViewProvider).selected;
      _allDay = false;
      final next = ((now.hour * 60 + now.minute) ~/ 30 + 1) * 30;
      _startMinute = widget.startMinute ?? next.clamp(0, 23 * 60 + 30);
      _duration = widget.durationMin ?? 30;
      _rule = RepeatRule.none;
      _reminders = [
        if (settings.defaultReminderMin != null)
          TaskReminder(id: _uuid.v4(), offsetMin: -settings.defaultReminderMin!),
      ];
      _priority = Priority.none;
    }
    ref.read(tasksRepositoryProvider).tags().then((t) {
      if (mounted) setState(() => _tags = t);
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _tag.dispose();
    super.dispose();
  }

  bool get _use24h => ref.read(settingsProvider).use24h;
  String _time(int m) => Fmt.minute(m, use24h: _use24h);

  Task _build() {
    final now = ref.read(clockProvider).now();
    final o = _occ;
    final tag = _tag.text.trim();
    final notes = _notes.text.trim();
    final base =
        o?.task ??
        Task(
          id: _uuid.v4(),
          title: '',
          color: _color,
          startDate: _date,
          seriesId: '',
          createdAt: now,
          updatedAt: now,
          timeZone: NotificationService.localZoneName,
        );
    final task = base.copyWith(
      title: _title.text.trim(),
      notes: notes.isEmpty ? null : notes,
      color: _color,
      tag: tag.isEmpty ? null : tag,
      priority: _priority,
      allDay: _allDay,
      startDate: _date,
      startMinute: _allDay ? null : _startMinute,
      durationMin: _allDay ? null : _duration,
      seriesId: base.seriesId.isEmpty ? base.id : base.seriesId,
      reminders: _reminders,
      updatedAt: now,
    );
    return _rule.applyTo(task);
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty || _saving) return;
    final repo = ref.read(tasksRepositoryProvider);
    final edited = _build();
    final o = _occ;
    var scope = EditScope.all;
    if (o != null && o.task.isRecurring) {
      final s = await askScope(context);
      if (s == null) return;
      scope = s;
    }
    setState(() => _saving = true);
    if (o == null) {
      await repo.create(edited);
    } else {
      await repo.save(edited, occ: o, scope: scope);
    }
    ref.read(feedbackProvider).light();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    // Permission is asked once, at onboarding; afterwards only Settings can
    // turn notifications on, so just point there.
    if (_reminders.isNotEmpty && !await ref.read(notificationServiceProvider).notificationsEnabled()) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Notifications are off — reminders won’t appear.'),
          action: SnackBarAction(
            label: 'Settings',
            textColor: Tokens.coral,
            onPressed: () => appRouter.push(Routes.settings),
          ),
        ),
      );
    }
  }

  Future<void> _delete() async {
    final o = _occ;
    if (o == null) return;
    final nav = Navigator.of(context);
    if (await deleteOccurrence(context, ref, o) && mounted) nav.pop();
  }

  // --- Pickers ------------------------------------------------------------

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime(_date.year, _date.month, _date.day),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _date = Days.of(d));
  }

  Future<int?> _pickTime(int minute) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minute ~/ 60, minute: minute % 60),
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: _use24h),
        child: child!,
      ),
    );
    return t == null ? null : t.hour * 60 + t.minute;
  }

  Future<void> _pickRepeat() async {
    final r = await showRepeatPicker(context, start: _date, current: _rule);
    if (r != null) setState(() => _rule = r);
  }

  Future<void> _addReminder() async {
    if (_reminders.length >= 5) return;
    final options = _allDay
        ? <(String, TaskReminder?)>[
            ('On the day at ${_time(540)}', TaskReminder(id: _uuid.v4(), offsetMin: 0, atMinute: 540)),
            ('Day before at ${_time(1080)}', TaskReminder(id: _uuid.v4(), offsetMin: -1440, atMinute: 1080)),
            ('On the day at…', null),
            ('Day before at…', null),
          ]
        : <(String, TaskReminder?)>[
            for (final m in [0, 5, 10, 15, 30, 60])
              (TaskReminder(id: '', offsetMin: -m).label(), TaskReminder(id: _uuid.v4(), offsetMin: -m)),
            ('1 day before (at ${_time(540)})', TaskReminder(id: _uuid.v4(), offsetMin: -1440, atMinute: 540)),
            ('Custom…', null),
          ];
    final picked = await showModalBottomSheet<int>(
      context: context,
      builder: (c) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            for (var i = 0; i < options.length; i++)
              ListTile(
                title: Text(options[i].$1, style: AppText.bodyL),
                onTap: () => Navigator.pop(c, i),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    var reminder = options[picked].$2;
    if (reminder == null) {
      if (_allDay) {
        final m = await _pickTime(540);
        if (m == null) return;
        reminder = TaskReminder(id: _uuid.v4(), offsetMin: picked == 2 ? 0 : -1440, atMinute: m);
      } else {
        if (!mounted) return;
        final m = await showWheelPicker(
          context,
          title: 'Minutes before',
          min: 1,
          max: 240,
          value: 20,
          unit: 'min before',
          accent: Tokens.coral,
        );
        if (m == null) return;
        reminder = TaskReminder(id: _uuid.v4(), offsetMin: -m);
      }
    }
    if (_reminders.contains(reminder)) return;
    setState(() => _reminders = [..._reminders, reminder!]);
  }

  // --- UI -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final valid = _title.text.trim().isNotEmpty;
    return Material(
      color: Tokens.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.card)),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(color: Tokens.outline, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
                Expanded(
                  child: Text(
                    _editing ? 'EDIT TASK' : 'NEW TASK',
                    style: AppText.h4,
                    textAlign: TextAlign.center,
                  ),
                ),
                FilledButton(
                  onPressed: valid && !_saving ? _save : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: Tokens.coral,
                    foregroundColor: Tokens.textInverse,
                    disabledBackgroundColor: Tokens.surfaceHigh,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: EdgeInsets.fromLTRB(20, 12, 20, 32 + MediaQuery.viewInsetsOf(context).bottom),
              children: [
                // 1. Title
                TextField(
                  controller: _title,
                  autofocus: !_editing,
                  textCapitalization: TextCapitalization.sentences,
                  style: AppText.display(30),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'WHAT NEEDS DOING?',
                    hintStyle: AppText.display(30, color: Tokens.textSecondary),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                if (_editing) ...[const SizedBox(height: 8), _StatusRow(occurrence: _occ!)],
                const SizedBox(height: 20),
                // 2. Colour
                const _Label('Colour'),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (var i = 0; i < TaskColors.all.length; i++)
                      _Swatch(
                        color: TaskColors.all[i],
                        name: TaskColors.names[i],
                        selected: TaskColors.all[i].toARGB32() == _color,
                        onTap: () => setState(() => _color = TaskColors.all[i].toARGB32()),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                // 3. Category tag
                const _Label('Category'),
                TextField(
                  controller: _tag,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(hintText: 'e.g. Health, Work'),
                  onChanged: (_) => setState(() {}),
                ),
                if (_tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final t in _tags.where(
                        (t) => t.toLowerCase().contains(_tag.text.trim().toLowerCase()) && t != _tag.text.trim(),
                      ).take(8))
                        PillChip(label: t, dense: true, onTap: () => setState(() => _tag.text = t)),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                _Group(
                  children: [
                    // 4. Date
                    _Row(
                      icon: Icons.event_rounded,
                      title: 'Date',
                      value: '${_date.shortWeekday}, ${_date.dayMonth} ${_date.year}',
                      onTap: _pickDate,
                    ),
                    // 5. All day / time / duration
                    SwitchListTile.adaptive(
                      value: _allDay,
                      onChanged: (v) => setState(() {
                        _allDay = v;
                        _reminders = []; // reminder kinds differ for all-day
                      }),
                      secondary: const Icon(Icons.wb_sunny_outlined, color: Tokens.textSecondary),
                      title: Text('All day', style: AppText.bodyL),
                      activeTrackColor: Tokens.coral,
                    ),
                    if (!_allDay) ...[
                      _Row(
                        icon: Icons.schedule_rounded,
                        title: 'Start time',
                        value: _time(_startMinute),
                        mono: true,
                        onTap: () async {
                          final m = await _pickTime(_startMinute);
                          if (m != null) setState(() => _startMinute = m);
                        },
                      ),
                      _Row(
                        icon: Icons.timelapse_rounded,
                        title: 'Duration',
                        value: '${Fmt.duration(_duration)} · ends ${_time((_startMinute + _duration) % 1440)}',
                        mono: true,
                        onTap: _pickDuration,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                // 6. Repeat
                _Group(
                  children: [
                    _Row(
                      icon: Icons.repeat_rounded,
                      title: 'Repeat',
                      value: _rule.summary(_date),
                      onTap: _pickRepeat,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 7. Reminders
                _Group(
                  children: [
                    for (final r in _reminders)
                      ListTile(
                        leading: const Icon(Icons.notifications_none_rounded, color: Tokens.textSecondary),
                        title: Text(r.label(allDay: _allDay, time: _time), style: AppText.bodyL),
                        trailing: IconButton(
                          tooltip: 'Remove reminder',
                          icon: const Icon(Icons.close_rounded, color: Tokens.textSecondary),
                          onPressed: () => setState(() => _reminders = [..._reminders]..remove(r)),
                        ),
                      ),
                    if (_reminders.length < 5)
                      ListTile(
                        leading: const Icon(Icons.add_alert_outlined, color: Tokens.coral),
                        title: Text('Add reminder', style: AppText.bodyL.copyWith(color: Tokens.coral)),
                        onTap: _addReminder,
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                // 8. Notes
                const _Label('Notes'),
                TextField(
                  controller: _notes,
                  minLines: 3,
                  maxLines: 8,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(hintText: 'Add details'),
                ),
                const SizedBox(height: 20),
                // 9. Priority
                const _Label('Priority'),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final p in Priority.values)
                      PillChip(
                        label: switch (p) {
                          Priority.none => 'None',
                          Priority.low => 'Low',
                          Priority.high => 'High',
                        },
                        dot: p == Priority.high ? Tokens.sun : null,
                        filled: _priority == p,
                        color: _priority == p ? Tokens.textPrimary : null,
                        onTap: () => setState(() => _priority = p),
                      ),
                  ],
                ),
                if (_editing) ...[
                  const SizedBox(height: 32),
                  Center(
                    child: TextButton.icon(
                      onPressed: _delete,
                      icon: const Icon(Icons.delete_outline_rounded, color: Tokens.coralSoft),
                      label: Text('Delete task', style: AppText.label.copyWith(color: Tokens.coralSoft)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDuration() async {
    final choice = await showModalBottomSheet<int>(
      context: context,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('DURATION', style: AppText.h3),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in [15, 30, 45, 60, 90, 120, 180])
                    PillChip(
                      label: Fmt.duration(m),
                      filled: m == _duration,
                      color: m == _duration ? Tokens.coral : null,
                      onTap: () => Navigator.pop(c, m),
                    ),
                  PillChip(label: 'Other…', onTap: () => Navigator.pop(c, -1)),
                  PillChip(label: 'Set end time', icon: Icons.schedule_rounded, onTap: () => Navigator.pop(c, -2)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (choice == null || !mounted) return;
    if (choice > 0) return setState(() => _duration = choice);
    if (choice == -1) {
      final m = await showWheelPicker(
        context,
        title: 'Duration',
        min: 15,
        max: 720,
        step: 15,
        value: _duration - _duration % 15 < 15 ? 15 : _duration - _duration % 15,
        accent: Tokens.coral,
      );
      if (m != null) setState(() => _duration = m);
      return;
    }
    final end = await _pickTime((_startMinute + _duration) % 1440);
    if (end == null) return;
    var d = end - _startMinute;
    if (d <= 0) d += 1440;
    setState(() => _duration = d);
  }
}

/// Done / skip toggles inside the editor for an existing occurrence.
class _StatusRow extends ConsumerWidget {
  const _StatusRow({required this.occurrence});
  final Occurrence occurrence;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    // Re-read the live occurrence so toggles reflect immediately.
    final live = ref
        .watch(occurrencesProvider(DateRange.day(occurrence.date)))
        .where((o) => o.key == occurrence.key)
        .firstOrNull;
    final o = live ?? occurrence;
    final repo = ref.read(tasksRepositoryProvider);
    final late = o.date.isBefore(today);
    void setDone(bool done) {
      if (o.isDone != done) toggleDone(ref, o);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Completed / Not completed (Google Calendar's task states).
        SegmentedButton<bool>(
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: o.isDone ? Tokens.mint : Tokens.surfaceHigh,
            selectedForegroundColor: o.isDone ? Tokens.textInverse : Tokens.textPrimary,
          ),
          segments: [
            ButtonSegment(value: true, icon: const Icon(Icons.check_rounded), label: Text(late && !o.isDone ? 'Completed (late)' : 'Completed')),
            const ButtonSegment(value: false, icon: Icon(Icons.radio_button_unchecked_rounded), label: Text('Not completed')),
          ],
          selected: {o.isDone},
          onSelectionChanged: (v) => setDone(v.first),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (!o.isDone)
              PillChip(
                label: 'Focus on this',
                icon: Icons.timer_outlined,
                filled: true,
                color: Tokens.sage,
                onTap: () async {
                  Navigator.pop(context);
                  await focusOnTask(rootNavigatorKey.currentContext ?? context, ref, o);
                },
              ),
            if (o.task.isRecurring)
              PillChip(
                label: o.status == OccurrenceStatus.skipped ? 'Skipped' : 'Skip this time',
                icon: Icons.redo_rounded,
                filled: o.status == OccurrenceStatus.skipped,
                color: o.status == OccurrenceStatus.skipped ? Tokens.textSecondary : null,
                onTap: () => repo.setSkipped(o, skipped: o.status != OccurrenceStatus.skipped),
              ),
            PillChip(
              label: 'Delete',
              icon: Icons.delete_outline_rounded,
              color: Tokens.coralSoft,
              foreground: Tokens.coralSoft,
              onTap: () async {
                final nav = Navigator.of(context);
                if (await deleteOccurrence(context, ref, o)) nav.pop();
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text.toUpperCase(),
      style: AppText.body(12, weight: FontWeight.w500, color: Tokens.textSecondary),
    ),
  );
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: selected ? Tokens.textPrimary : Colors.transparent, width: 3),
          ),
          child: selected ? Icon(Icons.check_rounded, size: 18, color: TaskColors.onColor(color)) : null,
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Material(
    color: Tokens.surfaceHigh,
    borderRadius: BorderRadius.circular(Radii.inner),
    clipBehavior: Clip.antiAlias,
    child: Column(children: children),
  );
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    this.mono = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;
  final bool mono;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: Tokens.textSecondary),
    title: Text(title, style: AppText.bodyL),
    trailing: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 200),
      child: Text(
        value,
        textAlign: TextAlign.right,
        maxLines: 2,
        style: mono ? AppText.mono(13, color: Tokens.textSecondary) : AppText.body(14, color: Tokens.textSecondary),
      ),
    ),
    onTap: onTap,
  );
}

/// Exact-alarm status (Android 12+), for the in-app banner.
final exactAlarmProvider = FutureProvider<bool>(
  (ref) => ref.read(notificationServiceProvider).canScheduleExact(),
);
