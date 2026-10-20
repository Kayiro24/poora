import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poora/app.dart';
import 'package:poora/core/db/daos/settings_dao.dart';
import 'package:poora/core/db/database.dart';
import 'package:poora/core/notifications/notification_service.dart';
import 'package:poora/core/providers.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';
import 'package:poora/features/settings/app_settings.dart';
import 'package:poora/features/settings/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _installErrorHandlers();

  final path = await AppDatabase.defaultPath();
  final db = await AppDatabase.open();
  final settings = AppSettings.fromMap(await SettingsDao(db).all());
  final notifications = NotificationService();
  try {
    await notifications.init();
  } on Object catch (e, s) {
    // Notifications are not essential to start the app.
    _log(e, s);
  }

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        dbPathProvider.overrideWithValue(path),
        initialSettingsProvider.overrideWithValue(settings),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
      child: const PooraApp(),
    ),
  );
}

/// No crash reporter (the app is offline by design): errors are logged, and
/// release builds show a calm fallback instead of the red error screen.
void _installErrorHandlers() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    _log(details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    _log(error, stack);
    return true;
  };
  if (kReleaseMode) {
    ErrorWidget.builder = (details) => ColoredBox(
      color: Tokens.bg,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Something didn’t load. Going back and trying again usually helps.',
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            style: AppText.body(14, color: Tokens.textSecondary),
          ),
        ),
      ),
    );
  }
}

void _log(Object error, StackTrace? stack) =>
    debugPrint('[poora] $error\n${stack ?? ''}');
