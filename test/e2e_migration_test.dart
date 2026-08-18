import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kholo/core/models/app_update.dart';
import 'package:kholo/core/models/health_profile.dart';
import 'package:kholo/core/models/baby_profile.dart';
import 'package:kholo/core/models/cycle_log.dart';
import 'package:kholo/core/services/update_service.dart';
import 'package:kholo/core/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End Migration & Update Flow Test (Old Version to Latest)', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('Full Lifecycle: Old installed version -> Notification -> Update -> Data Preservation', () async {
      // ───────────────────────────────────────────────────────────────────────
      // STEP 1: Simulate Old User State (v1.0.0, Build 2) with active data
      // ───────────────────────────────────────────────────────────────────────
      const oldVersionCode = 2;
      const oldVersionName = '1.0.0';

      final initialProfile = HealthProfile(
        cycleLength: 28,
        periodLength: 5,
        lastPeriodDate: DateTime(2026, 8, 1),
        ageRange: '25-30',
        lifeStage: LifeStage.notPregnant,
        onboardingComplete: true,
        dailyWaterGoalMl: 2500,
        targetSleepHours: 8.0,
      );

      final initialBaby = BabyProfile(
        id: 'baby_001',
        name: 'Aarav',
        birthDate: DateTime(2026, 1, 15),
        gender: 'boy',
      );

      final initialLog = CycleLog(
        id: 'log_001',
        eventDate: DateTime(2026, 8, 15),
        eventType: CycleEventType.periodStart,
        flow: FlowIntensity.medium,
        mood: Mood.great,
        symptoms: ['cramps', 'bloating'],
      );

      // Save old user data to SharedPreferences (simulating LocalStorageService)
      await prefs.setInt('kholo_installed_version_code', oldVersionCode);
      await prefs.setString('health_profile', jsonEncode(initialProfile.toJson()));
      await prefs.setString('baby_profiles', jsonEncode([initialBaby.toJson()]));
      await prefs.setString('cycle_logs', jsonEncode([initialLog.toJson()]));
      await prefs.setString('kholo_theme_mode', 'dark');

      expect(prefs.getInt('kholo_installed_version_code'), 2);

      // ───────────────────────────────────────────────────────────────────────
      // STEP 2: App opens on old version & checks for update
      // ───────────────────────────────────────────────────────────────────────
      const remoteUpdate = AppUpdate(
        latestVersion: '1.3.0',
        versionCode: 20,
        minRequiredVersionCode: 1,
        releaseNotes: '🌸 নতুন KHOLO v1.3.0 আপডেট! বেবি কেয়ার, স্কিন স্ক্যানার ও লাক্সারি থিম।',
        apkUrl: 'https://github.com/Blackproxya2z/kholo-app/releases/download/v1.3.0/app-release.apk',
        mirrorUrls: [
          'https://raw.githubusercontent.com/Blackproxya2z/kholo-releases/main/app-release.apk'
        ],
        fileSize: 65860000,
        apkSha256: '8b37a29abe1a1763f106df1acc57ecb45f0218d4cd2063c413208b2565e2804b',
        forceUpdate: false,
      );

      // Verify that remote update is detected as strictly newer
      final isNewer = remoteUpdate.isNewerThan(oldVersionCode, oldVersionName);
      expect(isNewer, isTrue, reason: 'v1.3.0 (build 20) must be recognized as newer than v1.0.0 (build 2)');

      // Check notification eligibility
      final shouldNotify = await UpdateService.shouldShowUpdateNotification(
        remoteUpdate.versionCode,
        currentInstalledCode: oldVersionCode,
        remoteVersionName: remoteUpdate.latestVersion,
        currentInstalledName: oldVersionName,
      );
      expect(shouldNotify, isTrue, reason: 'Old user must receive update notification');

      // ───────────────────────────────────────────────────────────────────────
      // STEP 3: Dispatch update notification to system tray
      // ───────────────────────────────────────────────────────────────────────
      await NotificationService.showUpdateNotification(
        version: remoteUpdate.latestVersion,
        versionCode: remoteUpdate.versionCode,
        releaseNotes: remoteUpdate.releaseNotes,
      );
      await UpdateService.recordNotificationSent(remoteUpdate.versionCode);

      expect(prefs.getInt('kholo_last_notified_version_code'), 20);

      // Verify deduplication: User will NOT receive duplicate spam notifications
      final shouldNotifyAgain = await UpdateService.shouldShowUpdateNotification(
        remoteUpdate.versionCode,
        currentInstalledCode: oldVersionCode,
        remoteVersionName: remoteUpdate.latestVersion,
        currentInstalledName: oldVersionName,
      );
      expect(shouldNotifyAgain, isFalse, reason: 'Notification must not be duplicated');

      // ───────────────────────────────────────────────────────────────────────
      // STEP 4: User clicks "Update Now" -> APK download and verification
      // ───────────────────────────────────────────────────────────────────────
      final tempDir = Directory.systemTemp.createTempSync('kholo_e2e_');
      final simulatedApk = File('${tempDir.path}/kholo_v1.3.0_b20_simulated.apk');
      await simulatedApk.writeAsString('KHOLO_OFFICIAL_V1.3.0_RELEASE_BINARY_PAYLOAD_TEST');

      final sha256Checksum = await UpdateService.calculateSha256(simulatedApk);
      final isValidApk = await UpdateService.verifyChecksum(simulatedApk, sha256Checksum);
      expect(isValidApk, isTrue, reason: 'Downloaded APK passes SHA-256 integrity check');

      // ───────────────────────────────────────────────────────────────────────
      // STEP 5: Installation succeeds & app upgrades to v1.3.0 (Build 20)
      // ───────────────────────────────────────────────────────────────────────
      await UpdateService.recordUpdateCompleted(remoteUpdate.versionCode);
      expect(prefs.getInt('kholo_update_completed_version_code'), 20);

      // ───────────────────────────────────────────────────────────────────────
      // STEP 6: New Version Launches & runs syncInstalledVersionOnLaunch
      // ───────────────────────────────────────────────────────────────────────
      await UpdateService.syncInstalledVersionOnLaunch(currentInstalledCode: 20);

      expect(prefs.getInt('kholo_installed_version_code'), 20);
      expect(prefs.getString('kholo_migration_status'), 'completed');

      // ───────────────────────────────────────────────────────────────────────
      // STEP 7: Verify Complete Data Preservation across Upgrade
      // ───────────────────────────────────────────────────────────────────────
      final rawProfile = prefs.getString('health_profile');
      expect(rawProfile, isNotNull);
      final restoredProfile = HealthProfile.fromJson(jsonDecode(rawProfile!));
      expect(restoredProfile.cycleLength, 28);
      expect(restoredProfile.periodLength, 5);
      expect(restoredProfile.ageRange, '25-30');
      expect(restoredProfile.dailyWaterGoalMl, 2500);

      final rawBabies = prefs.getString('baby_profiles');
      expect(rawBabies, isNotNull);
      final restoredBabies = (jsonDecode(rawBabies!) as List)
          .map((e) => BabyProfile.fromJson(e as Map<String, dynamic>))
          .toList();
      expect(restoredBabies.length, 1);
      expect(restoredBabies.first.name, 'Aarav');

      final rawLogs = prefs.getString('cycle_logs');
      expect(rawLogs, isNotNull);
      final restoredLogs = (jsonDecode(rawLogs!) as List)
          .map((e) => CycleLog.fromJson(e as Map<String, dynamic>))
          .toList();
      expect(restoredLogs.length, 1);
      expect(restoredLogs.first.symptoms, contains('cramps'));

      final themeMode = prefs.getString('kholo_theme_mode');
      expect(themeMode, 'dark');

      // ───────────────────────────────────────────────────────────────────────
      // STEP 8: New version checks for updates -> Up to date (No notifications)
      // ───────────────────────────────────────────────────────────────────────
      final postUpgradeIsNewer = remoteUpdate.isNewerThan(20, '1.3.0');
      expect(postUpgradeIsNewer, isFalse, reason: 'Already on latest version 1.3.0');

      final postUpgradeShouldNotify = await UpdateService.shouldShowUpdateNotification(
        remoteUpdate.versionCode,
        currentInstalledCode: 20,
        remoteVersionName: '1.3.0',
        currentInstalledName: '1.3.0',
      );
      expect(postUpgradeShouldNotify, isFalse, reason: 'No update notification when on latest version');

      tempDir.deleteSync(recursive: true);
    });
  });
}
