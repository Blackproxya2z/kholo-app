import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'theme/theme.dart';
import '../core/providers/app_settings_provider.dart';
import '../core/services/notification_service.dart';

/// Root widget wiring together the router, light/dark theme, settings,
/// and proactive notification tap handlers.
class KholoApp extends ConsumerStatefulWidget {
  const KholoApp({super.key});

  @override
  ConsumerState<KholoApp> createState() => _KholoAppState();
}

class _KholoAppState extends ConsumerState<KholoApp> {
  @override
  void initState() {
    super.initState();
    NotificationService.onNotificationTap = (payload) {
      if (payload == 'kholo_update' || payload == 'OPEN_UPDATE') {
        ref.read(routerProvider).go('/update');
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(appSettingsProvider);

    return MaterialApp.router(
      title: 'KHOLO',
      theme: KholoTheme.light,
      darkTheme: KholoTheme.dark,
      themeMode: settings.themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
