import 'package:flutter/material.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';
import 'package:poora/core/time/date_utils.dart';
import 'package:poora/core/widgets/pill_chip.dart';
import 'package:poora/features/tasks/domain/models.dart';
import 'package:poora/features/tasks/domain/recurrence.dart';

/// Quick repeat options plus "Times per week…" and "Custom…" (§4.8).
Future<RepeatRule?> showRepeatPicker(
  BuildContext context, {
  required DateTime start,
  required RepeatRule current,
}) async {
  final quick = <(String, RepeatRule)>[
    ('Does not repeat', RepeatRule.none),
    ('Every day', RepeatRule.daily()),
    ('Every weekday (Mon–Fri)', RepeatRule.weekdaysOnly()),
    ('Every week on ${weekdayLong[start.weekday - 1]}', RepeatRule.weeklyOn(start)),
    ('Every month on day ${start.day}', RepeatRule.monthlyOnDay()),
    ('Every year on ${monthLong[start.month - 1]} ${start.day}', RepeatRule.yearly()),
    ('Every other day', RepeatRule.everyOtherDay()),
  ];
  final picked = await showModalBottomSheet<Object>(
    context: context,
    builder: (c) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('REPEAT', style: AppText.h3),
          ),
          for (final (label, rule) in quick)
            ListTile(
              title: Text(label, style: AppText.bodyL),
              trailing: _sameBase(rule, current)
                  ? const Icon(Icons.check_rounded, color: Tokens.coral)
                  : null,
              onTap: () => Navigator.pop(c, rule),
            ),
          ListTile(
            title: Text('Times per week…', style: AppText.bodyL),
            trailing: current.kind == RepeatKind.quota
                ? const Icon(Icons.check_rounded, color: Tokens.coral)
                : const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.pop(c, 'quota'),
          ),
          ListTile(
            title: Text('Custom…', style: AppText.bodyL),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.pop(c, 'custom'),
          ),
        ],
      ),
    ),
  );
  if (!context.mounted || picked == null) return null;
  if (picked is RepeatRule) {
    // Keep any end condition the user already set.
    return picked.kind == RepeatKind.none
        ? picked
        : picked.copyWith(endsOn: current.endsOn, endsAfter: current.endsAfter);
  }
  final seed = picked == 'quota'
      ? (current.kind == RepeatKind.quota ? current : RepeatRule.timesPerWeek(3))
      : (current.kind == RepeatKind.rrule ? current : RepeatRule.daily());
  return Navigator.of(context).push<RepeatRule>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => picked == 'quota'
          ? _QuotaScreen(initial: seed, start: start)
          : _CustomScreen(initial: seed, start: start),
    ),
  );
}

bool _sameBase(RepeatRule a, RepeatRule b) =>
    a.copyWith(endsOn: null, endsAfter: null) == b.copyWith(endsOn: null, endsAfter: null);

class _Scaffold extends StatelessWidget {
  const _Scaffold({
    required this.title,
    required this.onDone,
    required this.children,
    required this.summary,
  });

  final String title;
  final VoidCallback onDone;
  final List<Widget> children;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Tokens.bg,
        title: Text(title.toUpperCase(), style: AppText.h4),
        leading: IconButton(
          tooltip: 'Cancel',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(onPressed: onDone, child: Text('Done', style: AppText.label.copyWith(color: Tokens.coral))),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Space.side),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Tokens.coral.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(Radii.inner),
            ),
            child: Text(summary, style: AppText.bodyL.copyWith(color: Tokens.coralSoft)),
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }
}

class _CustomScreen extends StatefulWidget {
  const _CustomScreen({required this.initial, required this.start});
  final RepeatRule initial;
  final DateTime start;

  @override
  State<_CustomScreen> createState() => _CustomScreenState();
}

class _CustomScreenState extends State<_CustomScreen> {
  late RepeatRule r = widget.initial.copyWith(kind: RepeatKind.rrule);
  late final _count = TextEditingController(text: '${r.endsAfter ?? 10}');

  @override
  void dispose() {
    _count.dispose();
    super.dispose();
  }

  String get _unit => switch (r.freq) {
    Freq.daily => r.interval == 1 ? 'day' : 'days',
    Freq.weekly => r.interval == 1 ? 'week' : 'weeks',
    Freq.monthly => r.interval == 1 ? 'month' : 'months',
    Freq.yearly => r.interval == 1 ? 'year' : 'years',
  };

  @override
  Widget build(BuildContext context) {
    final s = widget.start;
    final nth = RepeatRule.nthOfMonth(s);
    const ordinals = ['first', 'second', 'third', 'fourth', 'fifth'];
    return _Scaffold(
      title: 'Custom repeat',
      summary: r.summary(s),
      onDone: () => Navigator.pop(context, r),
      children: [
        Text('REPEAT EVERY', style: AppText.bodyS),
        const SizedBox(height: 8),
        Row(
          children: [
            _Stepper(
              value: r.interval,
              min: 1,
              max: 99,
              onChanged: (v) => setState(() => r = r.copyWith(interval: v)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<Freq>(
                initialValue: r.freq,
                dropdownColor: Tokens.surfaceHigh,
                items: [
                  for (final f in Freq.values)
                    DropdownMenuItem(
                      value: f,
                      child: Text(
                        switch (f) {
                          Freq.daily => 'day',
                          Freq.weekly => 'week',
                          Freq.monthly => 'month',
                          Freq.yearly => 'year',
                        },
                        style: AppText.bodyL,
                      ),
                    ),
                ],
                onChanged: (f) => setState(
                  () => r = r.copyWith(
                    freq: f,
                    weekdays: f == Freq.weekly && r.weekdays.isEmpty ? {s.weekday} : r.weekdays,
                  ),
                ),
              ),
            ),
          ],
        ),
        Text(' $_unit', style: AppText.bodyS),
        if (r.freq == Freq.weekly) ...[
          const SizedBox(height: 24),
          Text('ON', style: AppText.bodyS),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var d = 1; d <= 7; d++)
                _DayToggle(
                  label: weekdayLetters[d - 1],
                  semantic: weekdayLong[d - 1],
                  selected: r.weekdays.contains(d),
                  onTap: () {
                    final next = {...r.weekdays};
                    next.contains(d) ? next.remove(d) : next.add(d);
                    if (next.isEmpty) return; // at least one day
                    setState(() => r = r.copyWith(weekdays: next));
                  },
                ),
            ],
          ),
        ],
        if (r.freq == Freq.monthly) ...[
          const SizedBox(height: 24),
          RadioGroup<MonthlyMode>(
            groupValue: r.monthlyMode,
            onChanged: (m) => setState(() => r = r.copyWith(monthlyMode: m)),
            child: Column(
              children: [
                _radio(MonthlyMode.dayOfMonth, 'On day ${s.day}'),
                if (nth <= 4)
                  _radio(MonthlyMode.nthWeekday, 'On the ${ordinals[nth - 1]} ${weekdayLong[s.weekday - 1]}'),
                if (Days.add(s, 7).month != s.month)
                  _radio(MonthlyMode.lastWeekday, 'On the last ${weekdayLong[s.weekday - 1]}'),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        Text('ENDS', style: AppText.bodyS),
        const SizedBox(height: 4),
        _EndsPicker(
          rule: r,
          start: s,
          countController: _count,
          allowCount: true,
          onChanged: (x) => setState(() => r = x),
        ),
      ],
    );
  }

  Widget _radio(MonthlyMode m, String label) => RadioListTile<MonthlyMode>(
    value: m,
    contentPadding: EdgeInsets.zero,
    activeColor: Tokens.coral,
    title: Text(label, style: AppText.bodyL),
  );
}

class _QuotaScreen extends StatefulWidget {
  const _QuotaScreen({required this.initial, required this.start});
  final RepeatRule initial;
  final DateTime start;

  @override
  State<_QuotaScreen> createState() => _QuotaScreenState();
}

class _QuotaScreenState extends State<_QuotaScreen> {
  late RepeatRule r = widget.initial;
  final _count = TextEditingController();

  @override
  void dispose() {
    _count.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _Scaffold(
      title: 'Times per week',
      summary: r.summary(widget.start),
      onDone: () => Navigator.pop(context, r),
      children: [
        Text('DO THIS', style: AppText.bodyS),
        const SizedBox(height: 8),
        Row(
          children: [
            _Stepper(
              value: r.quota,
              min: 1,
              max: 7,
              onChanged: (v) => setState(() => r = r.copyWith(quota: v)),
            ),
            const SizedBox(width: 12),
            Text('times per week', style: AppText.bodyL),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Shows on every day until you’ve done it ${r.quota} '
          '${r.quota == 1 ? 'time' : 'times'}, then hides for the rest of the week.',
          style: AppText.bodyS,
        ),
        const SizedBox(height: 24),
        Text('PREFERRED DAYS (OPTIONAL)', style: AppText.bodyS),
        const SizedBox(height: 4),
        Text('Reminders only fire on these days.', style: AppText.bodyS),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var d = 1; d <= 7; d++)
              _DayToggle(
                label: weekdayLetters[d - 1],
                semantic: weekdayLong[d - 1],
                selected: r.preferredDays.contains(d),
                onTap: () {
                  final next = {...r.preferredDays};
                  next.contains(d) ? next.remove(d) : next.add(d);
                  setState(() => r = r.copyWith(preferredDays: next));
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Set a daily reminder time with “Add reminder” on the task.',
          style: AppText.bodyS,
        ),
        const SizedBox(height: 24),
        Text('ENDS', style: AppText.bodyS),
        _EndsPicker(
          rule: r,
          start: widget.start,
          countController: _count,
          allowCount: false,
          onChanged: (x) => setState(() => r = x),
        ),
      ],
    );
  }
}

enum _Ends { never, on, after }

class _EndsPicker extends StatelessWidget {
  const _EndsPicker({
    required this.rule,
    required this.start,
    required this.countController,
    required this.allowCount,
    required this.onChanged,
  });

  final RepeatRule rule;
  final DateTime start;
  final TextEditingController countController;
  final bool allowCount;
  final ValueChanged<RepeatRule> onChanged;

  @override
  Widget build(BuildContext context) {
    final mode = rule.endsOn != null
        ? _Ends.on
        : rule.endsAfter != null
        ? _Ends.after
        : _Ends.never;
    return RadioGroup<_Ends>(
      groupValue: mode,
      onChanged: (m) async {
        switch (m!) {
          case _Ends.never:
            onChanged(rule.copyWith(endsOn: null, endsAfter: null));
          case _Ends.on:
            final d = await _pickEnd(context);
            if (d != null) onChanged(rule.copyWith(endsOn: d, endsAfter: null));
          case _Ends.after:
            onChanged(
              rule.copyWith(endsOn: null, endsAfter: int.tryParse(countController.text) ?? 10),
            );
        }
      },
      child: Column(
        children: [
          RadioListTile(
            value: _Ends.never,
            contentPadding: EdgeInsets.zero,
            activeColor: Tokens.coral,
            title: Text('Never', style: AppText.bodyL),
          ),
          RadioListTile(
            value: _Ends.on,
            contentPadding: EdgeInsets.zero,
            activeColor: Tokens.coral,
            title: Row(
              children: [
                Text('On', style: AppText.bodyL),
                const SizedBox(width: 12),
                PillChip(
                  label: rule.endsOn == null
                      ? 'Pick date'
                      : '${rule.endsOn!.dayMonth} ${rule.endsOn!.year}',
                  onTap: () async {
                    final d = await _pickEnd(context);
                    if (d != null) onChanged(rule.copyWith(endsOn: d, endsAfter: null));
                  },
                ),
              ],
            ),
          ),
          if (allowCount)
            RadioListTile(
              value: _Ends.after,
              contentPadding: EdgeInsets.zero,
              activeColor: Tokens.coral,
              title: Row(
                children: [
                  Text('After', style: AppText.bodyL),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 72,
                    child: TextField(
                      controller: countController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: AppText.mono(16),
                      onChanged: (v) {
                        final n = int.tryParse(v);
                        if (n != null && n > 0) onChanged(rule.copyWith(endsOn: null, endsAfter: n));
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('occurrences', style: AppText.bodyL),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<DateTime?> _pickEnd(BuildContext context) async {
    final init = rule.endsOn ?? Days.add(start, 30);
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime(init.year, init.month, init.day),
      firstDate: DateTime(start.year, start.month, start.day),
      lastDate: DateTime(2100),
    );
    return d == null ? null : Days.of(d);
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Tokens.surfaceHigh,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Decrease',
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          SizedBox(
            width: 36,
            child: Text('$value', textAlign: TextAlign.center, style: AppText.mono(20)),
          ),
          IconButton(
            tooltip: 'Increase',
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}

class _DayToggle extends StatelessWidget {
  const _DayToggle({
    required this.label,
    required this.semantic,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String semantic;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: semantic,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? Tokens.coral : Tokens.surfaceHigh,
          ),
          child: Text(
            label,
            style: AppText.body(14, weight: FontWeight.w600, color: selected ? Tokens.textInverse : Tokens.textPrimary),
          ),
        ),
      ),
    );
  }
}
