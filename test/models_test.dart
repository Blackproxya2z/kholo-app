import 'package:flutter_test/flutter_test.dart';
import 'package:kholo/core/models/health_profile.dart';
import 'package:kholo/core/models/cycle_log.dart';
import 'package:kholo/core/models/baby_profile.dart';
import 'package:kholo/core/models/pregnancy_profile.dart';
import 'package:kholo/core/models/product.dart';
import 'package:kholo/core/models/cart_item.dart';
import 'package:kholo/core/models/app_update.dart';
import 'package:kholo/core/models/sync_models.dart';
import 'package:kholo/core/services/sync_engine_service.dart';
import 'package:kholo/core/services/dynamic_config_service.dart';

void main() {
  group('Models & Serialization Unit Tests', () {
    test('HealthProfile JSON round-trip and copyWith', () {
      final profile = HealthProfile(
        cycleLength: 30,
        periodLength: 6,
        lastPeriodDate: DateTime.utc(2026, 8, 1),
        ageRange: '25-34',
        lifeStage: LifeStage.tryingToConceive,
        onboardingComplete: true,
        hasPcosPcod: true,
        dailyWaterGoalMl: 2500,
        targetSleepHours: 8.5,
      );

      final json = profile.toJson();
      final decoded = HealthProfile.fromJson(json);

      expect(decoded.cycleLength, 30);
      expect(decoded.periodLength, 6);
      expect(decoded.safeCycleLength, 30);
      expect(decoded.safePeriodLength, 6);
      expect(decoded.lastPeriodDate, DateTime.utc(2026, 8, 1));
      expect(decoded.ageRange, '25-34');
      expect(decoded.lifeStage, LifeStage.tryingToConceive);
      expect(decoded.onboardingComplete, isTrue);
      expect(decoded.hasPcosPcod, isTrue);
      expect(decoded.dailyWaterGoalMl, 2500);
      expect(decoded.targetSleepHours, 8.5);

      final updated = profile.copyWith(cycleLength: 29, hasPcosPcod: false);
      expect(updated.cycleLength, 29);
      expect(updated.periodLength, 6);
      expect(updated.hasPcosPcod, isFalse);

      // Clamping bounds test
      const clamped = HealthProfile(cycleLength: 60, periodLength: 15);
      expect(clamped.safeCycleLength, 45);
      expect(clamped.safePeriodLength, 10);
    });

    test('CycleLog JSON round-trip and default id generation', () {
      final log = CycleLog(
        eventDate: DateTime.utc(2026, 8, 15),
        eventType: CycleEventType.periodStart,
        flow: FlowIntensity.medium,
        mood: Mood.great,
        symptoms: ['Cramps', 'Headache'],
        notes: 'Feeling energized later in the day',
      );

      expect(log.id, isNotEmpty);
      final json = log.toJson();
      final decoded = CycleLog.fromJson(json);

      expect(decoded.id, log.id);
      expect(decoded.eventDate, DateTime.utc(2026, 8, 15));
      expect(decoded.eventType, CycleEventType.periodStart);
      expect(decoded.flow, FlowIntensity.medium);
      expect(decoded.mood, Mood.great);
      expect(decoded.symptoms, ['Cramps', 'Headache']);
      expect(decoded.notes, 'Feeling energized later in the day');
    });

    test('BabyProfile ageDisplay and serialization', () {
      final now = DateTime.now();
      // 2 weeks old
      final newborn = BabyProfile(
        nickname: 'Maya',
        birthDate: now.subtract(const Duration(days: 14)),
      );
      expect(newborn.ageWeeks, 2);
      expect(newborn.ageDisplay, '2 weeks old');

      // 6 months old (~26 weeks)
      final infant = BabyProfile(
        nickname: 'Leo',
        birthDate: now.subtract(const Duration(days: 180)),
      );
      expect(infant.ageDisplay.contains('month'), isTrue);

      // JSON round trip
      final json = newborn.toJson();
      final decoded = BabyProfile.fromJson(json);
      expect(decoded.nickname, 'Maya');
    });

    test('BabyLog sleepMinutes and fallback handling', () {
      final log = BabyLog(
        babyId: 'b1',
        logType: BabyLogType.sleep,
        occurredAt: DateTime.utc(2026, 8, 15, 14, 0),
        sleepEnd: DateTime.utc(2026, 8, 15, 15, 30),
      );

      expect(log.sleepMinutes, 90);

      final json = log.toJson();
      final decoded = BabyLog.fromJson(json);
      expect(decoded.sleepMinutes, 90);
      expect(decoded.logType, BabyLogType.sleep);
    });

    test('PregnancyProfile currentWeek, daysRemaining, and milestone retrieval', () {
      final dueDate = DateTime.now().add(const Duration(days: 70));
      final preg = PregnancyProfile(dueDate: dueDate);

      expect(preg.daysRemaining, greaterThanOrEqualTo(69));
      expect(preg.currentWeek, inInclusiveRange(0, 42));

      final milestone = getMilestoneForWeek(20);
      expect(milestone, isNotNull);
      expect(milestone!['size'], 'Banana');
    });

    test('Product and CartItem JSON serialization', () {
      const product = Product(
        id: 'p1',
        title: 'Calm Bath Soak',
        category: 'Cycle care',
        description: 'Soothing blend',
        usage: 'Add to bath',
        priceBdt: 500,
      );

      final pJson = product.toJson();
      final pDecoded = Product.fromJson(pJson);
      expect(pDecoded.id, 'p1');
      expect(pDecoded.priceBdt, 500);

      final cartItem = CartItem(productId: 'p1', quantity: 3);
      final cJson = cartItem.toJson();
      final cDecoded = CartItem.fromJson(cJson);
      expect(cDecoded.productId, 'p1');
      expect(cDecoded.quantity, 3);
    });

    test('DynamicAppConfig and Phase Tips serialization & fallback', () {
      final config = DynamicAppConfig.bundledDefault;
      expect(config.schemaVersion, 1);
      expect(config.phaseTips.length, 4);

      final json = config.toJson();
      final decoded = DynamicAppConfig.fromJson(json);
      expect(decoded.schemaVersion, 1);
      expect(decoded.phaseTips.first.phaseKey, 'menstrual');
      expect(decoded.featureFlags['animated_cycle_ring'], isTrue);
    });

    test('AppUpdate parses PRD snake_case schema with SHA-256 and minRequiredVersionCode', () {
      final prdJson = {
        'latest_version': '2.1.0',
        'version_code': 21,
        'min_required_version_code': 15,
        'download_url': 'https://github.com/Blackproxya2z/kholo-app/releases/download/v2.1.0/app-release.apk',
        'apk_sha256': 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        'release_notes': 'Security patches and UI performance upgrades.',
      };

      final update = AppUpdate.fromJson(prdJson);
      expect(update.latestVersion, '2.1.0');
      expect(update.versionCode, 21);
      expect(update.minRequiredVersionCode, 15);
      expect(update.apkUrl, contains('app-release.apk'));
      expect(update.apkSha256, 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855');
      expect(update.releaseNotes, 'Security patches and UI performance upgrades.');

      // Mandatory check: installed build 10 is below min 15 -> must force
      expect(update.isMandatory(10), isTrue);
      // Installed build 16 is above min 15 -> optional update
      expect(update.isMandatory(16), isFalse);
    });

    test('AppUpdate parses legacy camelCase schema and string-coerced values safely', () {
      final legacyJson = {
        'latestVersion': '1.3.0',
        'versionCode': '3',
        'minRequiredVersionCode': '2',
        'apkUrl': 'https://github.com/Blackproxya2z/kholo-app/releases/download/v1.3.0/app-release.apk',
        'releaseNotes': 'Dual key backward compatibility.',
        'forceUpdate': 'false',
      };

      final update = AppUpdate.fromJson(legacyJson);
      expect(update.latestVersion, '1.3.0');
      expect(update.versionCode, 3);
      expect(update.minRequiredVersionCode, 2);
      expect(update.apkUrl, contains('app-release.apk'));
      expect(update.forceUpdate, isFalse);
    });

    test('SyncQueueItem serialization and SyncEngine LWW conflict resolution', () {
      final queueItem = SyncQueueItem(
        queueId: 'q-101',
        collection: SyncCollection.cycleLogs,
        recordId: 'log-1',
        action: SyncAction.create,
        payload: {'flow': 'heavy', 'mood': 'great'},
        clientTimestamp: DateTime.utc(2026, 8, 16, 4, 0, 0),
      );

      final json = queueItem.toJson();
      final decoded = SyncQueueItem.fromJson(json);
      expect(decoded.queueId, 'q-101');
      expect(decoded.collection, SyncCollection.cycleLogs);
      expect(decoded.action, SyncAction.create);
      expect(decoded.payload['flow'], 'heavy');

      // Test Last-Write-Wins (LWW) conflict resolution
      final olderLocal = {
        'id': 'rec-1',
        'notes': 'Old note',
        'updated_at': '2026-08-15T10:00:00.000Z',
      };
      final newerRemote = {
        'id': 'rec-1',
        'notes': 'New remote note',
        'updated_at': '2026-08-16T12:00:00.000Z',
      };

      final result1 = SyncEngineService.resolveConflictLWW(
        localRecord: olderLocal,
        remoteRecord: newerRemote,
      );
      expect(result1['notes'], 'New remote note');

      // If local is newer than remote (offline local modification wins)
      final newerLocal = {
        'id': 'rec-1',
        'notes': 'Offline edited note',
        'updated_at': '2026-08-16T14:00:00.000Z',
      };
      final result2 = SyncEngineService.resolveConflictLWW(
        localRecord: newerLocal,
        remoteRecord: newerRemote,
      );
      expect(result2['notes'], 'Offline edited note');
    });
  });
}
