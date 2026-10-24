import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poora/app_router.dart';
import 'package:poora/core/app_info.dart';
import 'package:poora/core/providers.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';
import 'package:poora/core/widgets/common.dart';
import 'package:poora/core/widgets/poora_logo.dart';
import 'package:poora/core/widgets/screen_header.dart';
import 'package:poora/features/settings/app_settings.dart';
import 'package:poora/features/settings/data_reset.dart';
import 'package:poora/features/settings/data_transfer.dart';
import 'package:poora/features/settings/permissions_list.dart';
import 'package:poora/features/settings/settings_controller.dart';
import 'package:poora/features/tasks/ui/task_editor.dart';
import 'package:share_plus/share_plus.dart';

final notificationsEnabledProvider = FutureProvider<bool>(
  (ref) => ref.read(notificationServiceProvider).notificationsEnabled(),
);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with WidgetsBindingObserver {
  late final _name = TextEditingController(text: ref.read(settingsProvider).name);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _name.dispose();
    super.dispose();
  }

  // Back from the system settings screens: re-read the permissions.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    ref
      ..invalidate(notificationsEnabledProvider)
      ..invalidate(exactAlarmProvider);
  }

  Future<void> _update(AppSettings Function(AppSettings) f) =>
      ref.read(settingsProvider.notifier).update(f);

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _export() async {
    final path = await DataTransfer(ref.read(databaseProvider)).exportFile();
    await SharePlus.instance.share(
      ShareParams(files: [XFile(path, mimeType: 'application/json')], subject: '${AppInfo.name} export'),
    );
  }

  Future<void> _import() async {
    final ok = await _confirm(
      'REPLACE ALL DATA?',
      'Importing replaces every task, record, session and setting with the file’s contents.',
      'Choose file',
    );
    if (!ok) return;
    final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (files.isEmpty) return;
    try {
      final text = utf8.decode(await files.first.readAsBytes());
      await DataTransfer(ref.read(databaseProvider)).importJson(text);
      await _reloadSettings();
      _toast('Import complete.');
    } on FormatException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _deleteAll() async {
    if (!await _confirm(
      'DELETE ALL DATA?',
      'Every task, completion, focus session, preset and setting on this phone will be erased, '
          'and all scheduled reminders cancelled.',
      'Continue',
    )) {
      return;
    }
    if (!await _confirm('ARE YOU SURE?', 'This can’t be undone. Export first if you might want it back.', 'Delete everything')) {
      return;
    }
    await ref.read(dataResetProvider).run();
    if (!mounted) return;
    // A fresh start: back to the welcome flow.
    context.go(Routes.welcome);
  }

  Future<void> _reloadSettings() async {
    final map = await ref.read(settingsDaoProvider).all();
    final s = AppSettings.fromMap(map);
    await _update((_) => s);
    _name.text = s.name;
  }

  Future<bool> _confirm(String title, String body, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(action, style: AppText.label.copyWith(color: Tokens.coralSoft)),
            ),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final notif = ref.watch(notificationsEnabledProvider).value;
    final exact = ref.watch(exactAlarmProvider).value;
    final isAndroid = !kIsWeb && Platform.isAndroid;
    final distracting = s.distractingApps.length;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.side, Space.m, Space.side, Space.x4),
          children: [
            ScreenHeader(title: 'Settings', size: 32, onBack: () => Navigator.pop(context)),
            const SizedBox(height: Space.xxl),
            SettingsGroup(
              title: 'You',
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Name', hintText: 'Shown as “Hi, …” on Home'),
                    onChanged: (v) => _update((x) => x.copyWith(name: v.trim())),
                  ),
                ),
              ],
            ),
            SettingsGroup(
              title: 'Calendar',
              children: [
                SettingsRow(
                  title: 'Week starts on',
                  trailing: SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: true, label: Text('Mon')),
                      ButtonSegment(value: false, label: Text('Sun')),
                    ],
                    selected: {s.mondayFirst},
                    onSelectionChanged: (v) => _update((x) => x.copyWith(mondayFirst: v.first)),
                  ),
                ),
                SettingsRow(
                  title: 'Time format',
                  trailing: SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: false, label: Text('12h')),
                      ButtonSegment(value: true, label: Text('24h')),
                    ],
                    selected: {s.use24h},
                    onSelectionChanged: (v) => _update((x) => x.copyWith(use24h: v.first)),
                  ),
                ),
                SettingsRow(
                  title: 'Default task reminder',
                  trailing: DropdownButton<int?>(
                    value: s.defaultReminderMin,
                    underline: const SizedBox.shrink(),
                    dropdownColor: Tokens.surfaceHigh,
                    items: [
                      for (final m in [null, 0, 5, 10, 15, 30, 60])
                        DropdownMenuItem(
                          value: m,
                          child: Text(
                            m == null ? 'None' : (m == 0 ? 'At start' : '$m min before'),
                            style: AppText.bodyM,
                          ),
                        ),
                    ],
                    onChanged: (m) => _update((x) => x.copyWith(defaultReminderMin: m)),
                  ),
                ),
              ],
            ),
            SettingsGroup(
              title: 'Notifications',
              children: [
                SettingsRow(
                  title: 'Notifications',
                  subtitle: notif == null ? 'Checking…' : (notif ? 'Allowed' : 'Off — or turn on in phone Settings → Apps → Poora'),
                  trailing: notif == false
                      ? TextButton(
                          onPressed: () async {
                            final notif = ref.read(notificationServiceProvider);
                            // After a denial Android won't show the prompt again: open the system screen.
                            if (!await notif.requestNotifications()) await notif.openSystemSettings();
                            ref.invalidate(notificationsEnabledProvider);
                          },
                          child: Text('Fix', style: AppText.label.copyWith(color: Tokens.coral)),
                        )
                      : const Icon(Icons.check_circle_rounded, color: Tokens.mint),
                ),
                if (isAndroid)
                  SettingsRow(
                    title: 'Exact alarms',
                    subtitle: exact == null
                        ? 'Checking…'
                        : (exact ? 'Reminders fire on the minute' : 'Off — reminders may be a few minutes late'),
                    trailing: exact == false
                        ? TextButton(
                            onPressed: () async {
                              await ref.read(notificationServiceProvider).requestExact();
                              ref.invalidate(exactAlarmProvider);
                            },
                            child: Text('Fix', style: AppText.label.copyWith(color: Tokens.coral)),
                          )
                        : const Icon(Icons.check_circle_rounded, color: Tokens.mint),
                  ),
                SettingsRow(
                  title: 'Focus settings',
                  subtitle: 'Timer display, quiet mode, chime',
                  trailing: const Icon(Icons.chevron_right_rounded, color: Tokens.textSecondary),
                  onTap: () => context.push(Routes.focusSettings),
                ),
                SettingsRow(
                  title: 'Focus history',
                  subtitle: 'Daily and weekly focus, grouped by task',
                  trailing: const Icon(Icons.chevron_right_rounded, color: Tokens.textSecondary),
                  onTap: () => context.push(Routes.focusHistory),
                ),
                if (isAndroid) ...[
                  SettingsRow(
                    title: 'Blocked apps',
                    subtitle: s.blockedApps.isEmpty ? 'Apps that won’t open during focus' : '${s.blockedApps.length} blocked during focus',
                    trailing: const Icon(Icons.chevron_right_rounded, color: Tokens.textSecondary),
                    onTap: () => context.push(Routes.blockedApps),
                  ),
                  SwitchRow(
                    title: 'Focus bar',
                    subtitle: 'Today’s and this week’s focus in the notification bar — or the session while you focus',
                    value: s.focusBar,
                    onChanged: (v) => _update((x) => x.copyWith(focusBar: v)),
                  ),
                ],
                if (isAndroid)
                  SettingsRow(
                    title: 'Distracting apps',
                    subtitle: distracting == 0 ? 'Pick apps to track during focus' : '$distracting selected',
                    trailing: const Icon(Icons.chevron_right_rounded, color: Tokens.textSecondary),
                    onTap: () => context.push(Routes.distractingApps),
                  ),
              ],
            ),
            if (isAndroid) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: Space.s),
                child: Text('PERMISSIONS', style: AppText.body(12, weight: FontWeight.w500, color: Tokens.textSecondary)),
              ),
              const PermissionsList(),
              const SizedBox(height: Space.xxl),
            ],
            SettingsGroup(
              title: 'Data',
              children: [
                SettingsRow(
                  title: 'Export data',
                  subtitle: 'JSON file via the share sheet',
                  trailing: const Icon(Icons.ios_share_rounded, color: Tokens.textSecondary),
                  onTap: _export,
                ),
                SettingsRow(
                  title: 'Import data',
                  subtitle: 'Replace everything from an export (app or web)',
                  trailing: const Icon(Icons.file_open_outlined, color: Tokens.textSecondary),
                  onTap: _import,
                ),
                SettingsRow(
                  title: 'Trash',
                  subtitle: 'Deleted tasks, kept for 30 days',
                  trailing: const Icon(Icons.chevron_right_rounded, color: Tokens.textSecondary),
                  onTap: () => context.push(Routes.trash),
                ),
              ],
            ),
            SettingsGroup(
              title: 'Danger zone',
              children: [
                SettingsRow(
                  title: 'Delete all data',
                  subtitle: 'Erase everything on this phone and start fresh',
                  trailing: const Icon(Icons.delete_forever_rounded, color: Tokens.dayMissed),
                  onTap: _deleteAll,
                ),
              ],
            ),
            SettingsGroup(
              title: 'About',
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 4),
                  child: PooraWordmark(size: 30, tagline: true),
                ),
                const SettingsRow(
                  title: 'Version ${AppInfo.version}',
                  subtitle: '${AppInfo.meaning}\n${AppInfo.subline} ${AppInfo.motto} Offline, no account — your data stays on this phone.',
                ),
                SettingsRow(
                  title: 'Open-source licences',
                  trailing: const Icon(Icons.chevron_right_rounded, color: Tokens.textSecondary),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: AppInfo.name,
                    applicationVersion: AppInfo.version,
                    applicationLegalese: AppInfo.tagline,
                    applicationIcon: const Padding(padding: EdgeInsets.all(12), child: PooraMark(size: 48)),
                  ),
                ),
                if (kDebugMode)
                  SettingsRow(
                    title: 'Component gallery',
                    subtitle: 'Debug only',
                    trailing: const Icon(Icons.chevron_right_rounded, color: Tokens.textSecondary),
                    onTap: () => context.push(Routes.gallery),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
