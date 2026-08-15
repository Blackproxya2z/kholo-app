import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'theme/theme.dart';
import '../core/providers/app_settings_provider.dart';

/// Root widget wiring together the router, light/dark theme, and settings.
class KholoApp extends ConsumerWidget {
  const KholoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
