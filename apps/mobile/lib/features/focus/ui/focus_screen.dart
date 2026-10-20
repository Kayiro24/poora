import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poora/app_router.dart';
import 'package:poora/core/app_info.dart';
import 'package:poora/core/db/daos/focus_dao.dart';
import 'package:poora/core/providers.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';
import 'package:poora/core/time/format.dart';
import 'package:poora/core/widgets/accent_panel.dart';
import 'package:poora/core/widgets/arrow_circle_button.dart';
import 'package:poora/core/widgets/common.dart';
import 'package:poora/core/widgets/floating_nav_bar.dart';
import 'package:poora/core/widgets/pill_chip.dart';
import 'package:poora/core/widgets/round_icon_button.dart';
import 'package:poora/core/widgets/screen_header.dart';
import 'package:poora/core/widgets/wheel_picker.dart';
import 'package:poora/features/focus/application/focus_controller.dart';
import 'package:poora/features/focus/application/focus_draft.dart';
import 'package:poora/features/focus/domain/timer_engine.dart';
import 'package:poora/features/focus/ui/focus_dial.dart';
import 'package:poora/features/settings/settings_controller.dart';
import 'package:poora/features/tasks/application/tasks_providers.dart';
import 'package:poora/features/tasks/domain/models.dart';
import 'package:uuid/uuid.dart';

/// Starts a session with [config], showing the one-time iOS Focus tip first.
Future<void> startFocus(WidgetRef ref, BuildContext context, FocusConfig config) async {
  final settings = ref.read(settingsProvider);
  if (!kIsWeb && Platform.isIOS && !settings.iosFocusTipShown) {
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('A QUIET TIP'),
        content: const Text(
          'iOS doesn’t let apps silence other apps. For a fully quiet session, '
          'turn on a Focus mode from Control Center. ${AppInfo.name} will hold its own '
          'reminders until you’re done.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Got it')),
        ],
      ),
    );
    await ref.read(settingsProvider.notifier).update((s) => s.copyWith(iosFocusTipShown: true));
  }
  ref.read(feedbackProvider).light();
  final link = ref.read(focusLinkProvider);
  await ref
      .read(focusControllerProvider.notifier)
      .start(config, linkedTaskId: link?.$1, linkedDate: link?.$2);
  ref.read(focusLinkProvider.notifier).set(null);
}

class FocusScreen extends ConsumerWidget {
  const FocusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(focusDraftProvider);
    final settings = ref.watch(settingsProvider);
    final now = ref.watch(nowProvider).value ?? DateTime.now();
    final saved = ref.watch(presetsProvider).value ?? const <FocusPreset>[];
    final session = ref.watch(focusControllerProvider.select((s) => s.session));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            Space.side,
            Space.m,
            Space.side,
            FloatingNavBar.reservedHeight(context),
          ),
          children: [
            AccentPanel(
              color: Tokens.sage,
              child: Column(
                children: [
                  ScreenHeader(
                    title: 'Focus',
                    onPastel: true,
                    trailing: [
                      RoundIconButton(
                        icon: Icons.tune_rounded,
                        semanticLabel: 'Focus settings',
                        background: Tokens.white,
                        foreground: Tokens.textInverse,
                        onTap: () => context.push(Routes.focusSettings),
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.l),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 280),
                    child: FocusDial(config: draft, now: now, use24h: settings.use24h),
                  ),
                  const SizedBox(height: Space.m),
                  Row(
                    children: [
                      Text(
                        Fmt.utcOffset(now.timeZoneOffset),
                        style: AppText.mono(12, color: Tokens.textInverse.withValues(alpha: 0.7)),
                      ),
                      const Spacer(),
                      Text(
                        Fmt.time(now, use24h: settings.use24h),
                        style: AppText.mono(12, color: Tokens.textInverse.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.l),
                  _HeroButton(
                    label: session == null ? 'START FOCUS' : 'RETURN TO SESSION',
                    onTap: session == null
                        ? () => startFocus(ref, context, draft)
                        : () => context.push(Routes.focusRun),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.xxl),
            if (settings.lastFocusAt != null) ...[
              _LastSession(
                config: settings.lastFocus,
                at: settings.lastFocusAt!,
                now: now,
                onStart: session == null
                    ? () => startFocus(ref, context, settings.lastFocus)
                    : null,
              ),
              const SizedBox(height: Space.xxl),
            ],
            const SectionTitle('Break timings'),
            SettingsGroup(
              title: 'Per cycle',
              children: [
                _TimingRow(
                  label: 'Focus length',
                  value: draft.focusMin,
                  min: 5,
                  max: 180,
                  step: 5,
                  onPicked: (v) => ref.read(focusDraftProvider.notifier).set(draft.copyWith(focusMin: v)),
                ),
                _TimingRow(
                  label: 'Short break',
                  value: draft.shortMin,
                  min: 1,
                  max: 60,
                  onPicked: (v) => ref.read(focusDraftProvider.notifier).set(draft.copyWith(shortMin: v)),
                ),
                _TimingRow(
                  label: 'Long break',
                  value: draft.longMin,
                  min: 5,
                  max: 60,
                  onPicked: (v) => ref.read(focusDraftProvider.notifier).set(draft.copyWith(longMin: v)),
                ),
                _TimingRow(
                  label: 'Long break after every',
                  value: draft.longEvery,
                  min: 2,
                  max: 8,
                  unit: 'sessions',
                  onPicked: (v) => ref.read(focusDraftProvider.notifier).set(draft.copyWith(longEvery: v)),
                ),
              ],
            ),
            const SectionTitle('Presets'),
            _Presets(draft: draft, saved: saved),
            const SizedBox(height: Space.xxl),
            const _LinkTaskChip(),
          ],
        ),
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: Tokens.bg,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: SizedBox(
            height: 64,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_arrow_rounded, color: Tokens.sage, size: 28),
                const SizedBox(width: 8),
                Text(label, style: AppText.display(26, color: Tokens.sage)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LastSession extends StatelessWidget {
  const _LastSession({
    required this.config,
    required this.at,
    required this.now,
    required this.onStart,
  });

  final FocusConfig config;
  final DateTime at;
  final DateTime now;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LAST USED', style: AppText.display(16, color: Tokens.textSecondary)),
                const SizedBox(height: 6),
                Text(
                  '${config.focusMin} min focus · ${config.shortMin} min break · '
                  '${Fmt.ago(at, now)}',
                  style: AppText.bodyM,
                ),
              ],
            ),
          ),
          ArrowCircleButton(onTap: onStart, semanticLabel: 'Start with last used settings'),
        ],
      ),
    );
  }
}

class _TimingRow extends StatelessWidget {
  const _TimingRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onPicked,
    this.step = 1,
    this.unit = 'min',
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final String unit;
  final ValueChanged<int> onPicked;

  @override
  Widget build(BuildContext context) {
    return SettingsRow(
      title: label,
      onTap: () async {
        final v = await showWheelPicker(
          context,
          title: label,
          min: min,
          max: max,
          step: step,
          value: value,
          unit: unit,
        );
        if (v != null) onPicked(v);
      },
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$value', style: AppText.mono(18, color: Tokens.sage)),
          const SizedBox(width: 4),
          Text(unit, style: AppText.bodyS),
          const Icon(Icons.chevron_right_rounded, color: Tokens.textSecondary),
        ],
      ),
    );
  }
}

class _Presets extends ConsumerWidget {
  const _Presets({required this.draft, required this.saved});
  final FocusConfig draft;
  final List<FocusPreset> saved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = [
      for (final (name, c) in builtInPresets) (name, c, null as String?),
      for (final p in saved) (p.name, p.config, p.id),
    ];
    final matched = all.any((p) => p.$2 == draft);
    void select(FocusConfig c) {
      ref.read(feedbackProvider).selection();
      ref.read(focusDraftProvider.notifier).set(c);
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (name, config, id) in all)
          GestureDetector(
            onLongPress: id == null ? null : () => _confirmDelete(context, ref, id, name),
            child: PillChip(
              label: name,
              filled: config == draft,
              color: config == draft ? Tokens.sage : null,
              onTap: () => select(config),
            ),
          ),
        PillChip(
          label: 'Custom',
          filled: !matched,
          color: !matched ? Tokens.sage : null,
          onTap: () async {
            final v = await showWheelPicker(
              context,
              title: 'Focus length',
              min: 5,
              max: 180,
              step: 5,
              value: draft.focusMin,
            );
            if (v != null) select(draft.copyWith(focusMin: v));
          },
        ),
        if (!matched && saved.length < maxSavedPresets)
          PillChip(
            label: 'Save preset',
            icon: Icons.add_rounded,
            onTap: () => _save(context, ref),
          ),
      ],
    );
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: draft.label);
    final name = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('SAVE PRESET'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 16,
          decoration: const InputDecoration(hintText: 'Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(c, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    await ref
        .read(focusDaoProvider)
        .upsertPreset(
          FocusPreset(id: const Uuid().v4(), name: name, config: draft, sort: saved.length),
        );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, String id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('DELETE PRESET?'),
        content: Text('“$name” will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Keep')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok ?? false) await ref.read(focusDaoProvider).deletePreset(id);
  }
}

class _LinkTaskChip extends ConsumerWidget {
  const _LinkTaskChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final link = ref.watch(focusLinkProvider);
    final today = ref.watch(todayOccurrencesProvider);
    Occurrence? linked;
    if (link != null) {
      for (final o in today) {
        if (o.task.id == link.$1 && o.originalDate == link.$2) linked = o;
      }
    }
    return Row(
      children: [
        PillChip(
          label: linked == null ? 'Link a task' : linked.title,
          icon: Icons.link_rounded,
          filled: linked != null,
          color: linked == null ? null : Color(linked.task.color),
          onTap: () => _pick(context, ref, today),
        ),
        if (linked != null)
          IconButton(
            tooltip: 'Unlink task',
            onPressed: () => ref.read(focusLinkProvider.notifier).set(null),
            icon: const Icon(Icons.close_rounded, color: Tokens.textSecondary),
          ),
      ],
    );
  }

  Future<void> _pick(BuildContext context, WidgetRef ref, List<Occurrence> today) async {
    final open = today.where((o) => o.status == OccurrenceStatus.pending).toList();
    final picked = await showModalBottomSheet<Occurrence>(
      context: context,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('LINK A TASK', style: AppText.h3),
              const SizedBox(height: 12),
              if (open.isEmpty)
                const EmptyState(message: 'No open tasks today.', compact: true)
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final o in open)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(radius: 6, backgroundColor: Color(o.task.color)),
                          title: Text(o.title, style: AppText.bodyL),
                          onTap: () => Navigator.pop(c, o),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) {
      ref.read(focusLinkProvider.notifier).set((picked.task.id, picked.originalDate));
    }
  }
}
