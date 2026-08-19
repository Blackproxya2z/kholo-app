import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kholo/core/models/bloom_models.dart';
import 'package:kholo/core/models/health_profile.dart';
import 'package:kholo/core/services/bloom_health_service.dart';
import 'package:kholo/core/services/bloom_ai_guide_service.dart';
import 'package:kholo/core/providers/providers.dart';
import 'package:kholo/features/bloom/bloom_hub_screen.dart';
import 'package:kholo/features/bloom/bloom_article_detail_screen.dart';
import 'package:kholo/features/bloom/bloom_search_screen.dart';
import 'package:kholo/features/bloom/bloom_ai_assistant_screen.dart';
import 'package:kholo/features/bloom/widgets/bloom_card.dart';
import 'package:kholo/features/bloom/widgets/bloom_daily_tip_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KHOLO Bloom Health Hub — Service & Business Logic Tests', () {
    late SharedPreferences prefs;
    late BloomHealthService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      service = BloomHealthService(prefs);
    });

    test('BloomHealthService retrieves articles across all 6 core categories', () {
      final all = service.getAllArticles();
      expect(all.length, greaterThanOrEqualTo(8));

      for (final cat in BloomCategory.values) {
        final categoryArticles = service.getArticlesByCategory(cat);
        expect(categoryArticles, isNotEmpty,
            reason: 'Category ${cat.name} should contain curated articles');
      }
    });

    test('Realtime Search matches English and Bengali queries accurately', () {
      // English queries
      final periodResults = service.searchArticles('cramps');
      expect(periodResults, isNotEmpty);
      expect(periodResults.first.category, equals(BloomCategory.womenHealth));

      final skinResults = service.searchArticles('barrier');
      expect(skinResults, isNotEmpty);
      expect(skinResults.first.category, equals(BloomCategory.skinCare));

      // Bengali queries
      final bnPeriodResults = service.searchArticles('মাসিক');
      expect(bnPeriodResults, isNotEmpty);

      final bnSkinResults = service.searchArticles('ব্রণ');
      expect(bnSkinResults, isNotEmpty);

      final bnPregnancyResults = service.searchArticles('গর্ভ');
      expect(bnPregnancyResults, isNotEmpty);
    });

    test('AI Personalization engine prioritizes articles based on user profile', () {
      // 1. Pregnant user profile
      const pregnantProfile = HealthProfile(
        lifeStage: LifeStage.pregnant,
        onboardingComplete: true,
      );
      final pregnantFeed = service.getPersonalizedFeed(pregnantProfile);
      expect(pregnantFeed.any((a) => a.targetLifeStages.contains('pregnancy')), isTrue);

      // 2. PCOS profile
      const pcosProfile = HealthProfile(
        lifeStage: LifeStage.notPregnant,
        hasPcosPcod: true,
        onboardingComplete: true,
      );
      final pcosFeed = service.getPersonalizedFeed(pcosProfile);
      expect(pcosFeed.any((a) => a.tags.contains('PCOS')), isTrue);
    });

    test('Daily tip deterministic rotation & streak progression', () async {
      final tip = service.getDailyTip(DateTime(2026, 8, 19));
      expect(tip.id, isNotEmpty);
      expect(tip.titleEn, isNotEmpty);
      expect(tip.titleBn, isNotEmpty);

      final initialProgress = service.getUserProgress();
      expect(initialProgress.streakDays, equals(1));

      // Record reading an article
      await service.recordArticleRead('art_wh_period_pain');
      final updatedProgress = service.getUserProgress();
      expect(updatedProgress.completedArticleIds, contains('art_wh_period_pain'));
    });

    test('Bookmark saving and toggling persists in SharedPreferences', () async {
      expect(service.getSavedArticleIds(), isEmpty);

      final isSaved = await service.toggleBookmark('art_sk_barrier_repair');
      expect(isSaved, isTrue);
      expect(service.getSavedArticleIds(), contains('art_sk_barrier_repair'));

      final isUnsaved = await service.toggleBookmark('art_sk_barrier_repair');
      expect(isUnsaved, isFalse);
      expect(service.getSavedArticleIds(), isEmpty);
    });

    test('Language preference switching and persistence', () async {
      expect(service.getLanguage(), equals(BloomLanguage.bn));

      await service.setLanguage(BloomLanguage.en);
      expect(service.getLanguage(), equals(BloomLanguage.en));

      await service.setLanguage(BloomLanguage.bn);
      expect(service.getLanguage(), equals(BloomLanguage.bn));
    });
  });

  group('KHOLO AI Health Guide — Clinical Assistant Tests', () {
    test('Welcome message delivers respectful clinical greeting and disclaimer', () {
      final welcomeBn = BloomAiGuideService.getWelcomeMessage(BloomLanguage.bn);
      expect(welcomeBn.isUser, isFalse);
      expect(welcomeBn.title, contains('KHOLO AI Health Guide'));
      expect(welcomeBn.clinicalSource, isNotNull);

      final welcomeEn = BloomAiGuideService.getWelcomeMessage(BloomLanguage.en);
      expect(welcomeEn.isUser, isFalse);
      expect(welcomeEn.title, contains('KHOLO AI Health Guide'));
    });

    test('AI Guide answers irregular period queries with medical citations', () async {
      final responseBn = await BloomAiGuideService.askQuestion(
          'আমার period irregular কেন?', BloomLanguage.bn);
      expect(responseBn.isUser, isFalse);
      expect(responseBn.bulletPoints, isNotEmpty);
      expect(responseBn.isMedicalDisclaimer, isTrue);
      expect(responseBn.clinicalSource, contains('ACOG'));

      final responseEn = await BloomAiGuideService.askQuestion(
          'Why is my period irregular?', BloomLanguage.en);
      expect(responseEn.isUser, isFalse);
      expect(responseEn.bulletPoints, isNotEmpty);
      expect(responseEn.isMedicalDisclaimer, isTrue);
    });

    test('AI Guide answers skincare and acne queries with AAD citations', () async {
      final response = await BloomAiGuideService.askQuestion(
          'Acne কেন হচ্ছে?', BloomLanguage.bn);
      expect(response.isUser, isFalse);
      expect(response.title, contains('ব্রণ'));
      expect(response.clinicalSource, contains('AAD'));
    });

    test('AI Guide answers pregnancy nutrition queries with WHO citations', () async {
      final response = await BloomAiGuideService.askQuestion(
          'What foods help during pregnancy?', BloomLanguage.en);
      expect(response.isUser, isFalse);
      expect(response.title, contains('Pregnancy Nutrition'));
      expect(response.clinicalSource, contains('WHO'));
    });
  });

  group('KHOLO Bloom Health Hub — Widget UI Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    Widget createWidgetForTesting(Widget child) {
      return ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          home: child,
        ),
      );
    }

    testWidgets('BloomHubScreen renders headers, daily tip, category chips and cards',
        (tester) async {
      await tester.pumpWidget(createWidgetForTesting(const BloomHubScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('KHOLO Bloom'), findsOneWidget);
      expect(find.byType(BloomDailyTipCard), findsOneWidget);
      expect(find.byType(BloomCard), findsWidgets);
    });

    testWidgets('BloomArticleDetailScreen renders title, takeaways, and medical disclaimer',
        (tester) async {
      await tester.pumpWidget(createWidgetForTesting(
        const BloomArticleDetailScreen(articleId: 'art_wh_period_pain'),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('মাসিকে পেট বা কোমর ব্যথা'), findsOneWidget);
      expect(find.textContaining('মূল স্বাস্থ্য তথ্য ও টেকঅ্যাওয়ে'), findsOneWidget);
      expect(find.textContaining('মেডিকেল সেফটি ও সতর্কতা'), findsOneWidget);
    });

    testWidgets('BloomSearchScreen renders search bar and trending searches',
        (tester) async {
      await tester.pumpWidget(createWidgetForTesting(const BloomSearchScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.textContaining('জনপ্রিয় অনুসন্ধানসমূহ'), findsOneWidget);
    });

    testWidgets('BloomAiAssistantScreen renders AI chat interface and prompt chips',
        (tester) async {
      await tester.pumpWidget(createWidgetForTesting(const BloomAiAssistantScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('KHOLO AI Health Guide'), findsWidgets);
      expect(find.textContaining('আমার period irregular কেন?'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
