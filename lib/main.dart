import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'core/providers/providers.dart';
import 'core/providers/app_settings_provider.dart';
import 'core/services/notification_service.dart';
import 'core/services/update_service.dart';
import 'core/services/firebase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // Initialize Firebase Production Infrastructure (Crashlytics, FCM, RemoteConfig)
  await FirebaseService.init();

  // Sync installed version and clear old update artifacts
  await UpdateService.syncInstalledVersionOnLaunch();

  // Initialise local notifications before runApp
  await NotificationService.init();

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        appSettingsProvider.overrideWith(
          (ref) => AppSettingsNotifier(prefs),
        ),
      ],
      child: const KholoApp(),
    ),
  );
}
