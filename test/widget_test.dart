import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kholo/app/app.dart';
import 'package:kholo/app/theme/theme.dart';
import 'package:kholo/core/providers/providers.dart';
import 'package:kholo/core/models/health_profile.dart';
import 'package:kholo/features/landing/landing_screen.dart';
import 'package:kholo/features/today/today_screen.dart';
import 'package:kholo/shared/widgets/phase_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Widget & UI Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('LandingScreen renders hero text and CTA buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: KholoTheme.light,
          home: const LandingScreen(),
        ),
      );

      expect(find.text('KHOLO'), findsOneWidget);
      expect(find.text('Create your private space'), findsOneWidget);
      expect(find.text('Explore the shop'), findsOneWidget);
    });

    testWidgets('PhaseCard displays phase details and cycle day', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: KholoTheme.light,
          home: const Scaffold(
            body: PhaseCard(
              phase: CyclePhase.follicular,
              cycleDay: 8,
              cycleLength: 28,
              daysUntilNextPeriod: 20,
              isInFertileWindow: false,
            ),
          ),
        ),
      );

      expect(find.text('Follicular'), findsOneWidget);
      expect(find.text('Day 8 of 28'), findsOneWidget);
      expect(find.text('20d until period'), findsOneWidget);
    });

    testWidgets('TodayScreen renders properly with ProviderScope', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPrefsProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            theme: KholoTheme.light,
            home: const TodayScreen(),
          ),
        ),
      );

      expect(find.text('KHOLO'), findsOneWidget);
      expect(find.text('Here\'s your overview'), findsOneWidget);
    });

    testWidgets('KholoApp initializes and mounts without throwing', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPrefsProvider.overrideWithValue(prefs),
          ],
          child: const KholoApp(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('KHOLO'), findsWidgets);
    });
  });
}
