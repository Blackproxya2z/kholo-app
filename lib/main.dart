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

  SharedPreferences prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (e) {
    debugPrint('[main] SharedPreferences init fallback: $e');
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  }

  // Launch the UI immediately so splash screen mounts in < 50ms
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

  // Initialize background services asynchronously without blocking app startup
  _initAppServices();
}

Future<void> _initAppServices() async {
  try {
    await FirebaseService.init();
  } catch (e) {
    debugPrint('[main] FirebaseService.init error: $e');
  }

  try {
    await NotificationService.init();
  } catch (e) {
    debugPrint('[main] NotificationService.init error: $e');
  }

  try {
    await UpdateService.syncInstalledVersionOnLaunch();
  } catch (e) {
    debugPrint('[main] UpdateService.syncInstalledVersionOnLaunch error: $e');
  }

  try {
    UpdateService.performProactiveUpdateCheck(notifyUser: true);
  } catch (e) {
    debugPrint('[main] UpdateService.performProactiveUpdateCheck error: $e');
  }
}
