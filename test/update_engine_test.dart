import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kholo/core/models/app_update.dart';
import 'package:kholo/core/services/update_service.dart';
import 'package:kholo/core/providers/update_provider.dart';
import 'package:kholo/features/update/mandatory_update_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KHOLO Release, Versioning & Update Delivery Pipeline Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('Scenario 1: User on old version receives update and notification once', () async {
      const currentCode = 2;
      const currentVersion = '1.2.0';

      const update = AppUpdate(
        latestVersion: '1.3.0',
        versionCode: 20,
        minRequiredVersionCode: 1,
        releaseNotes: '🌸 New release with baby care, AI skin doctor, and luxury themes.',
        apkUrl: 'https://github.com/Blackproxya2z/kholo-app/releases/download/v1.3.0/app-release.apk',
        forceUpdate: false,
      );

      // 1. Version check: Remote build 20 (v1.3.0) is strictly newer than installed build 2 (v1.2.0)
      expect(update.isNewerThan(currentCode, currentVersion), isTrue);

      // 2. Notification eligibility: User has not been notified yet
      final shouldNotifyFirstTime =
          await UpdateService.shouldShowUpdateNotification(
        update.versionCode,
        currentInstalledCode: currentCode,
      );
      expect(shouldNotifyFirstTime, isTrue);

      // 3. Mark notification dispatched
      await UpdateService.recordNotificationSent(update.versionCode);

      // 4. Deduplication: Subsequent check will NOT trigger duplicate notification
      final shouldNotifySecondTime =
          await UpdateService.shouldShowUpdateNotification(
        update.versionCode,
        currentInstalledCode: currentCode,
      );
      expect(shouldNotifySecondTime, isFalse);
    });

    test('Scenario 2: User on latest version receives NO update notification', () async {
      const currentCode = 20;
      const currentVersion = '1.3.0';

      const update = AppUpdate(
        latestVersion: '1.3.0',
        versionCode: 20,
        minRequiredVersionCode: 1,
        releaseNotes: 'Up to date build.',
        apkUrl: 'https://github.com/Blackproxya2z/kholo-app/releases/download/v1.3.0/app-release.apk',
        forceUpdate: false,
      );

      // 1. Version check: Installed is already at latest release
      expect(update.isNewerThan(currentCode, currentVersion), isFalse);

      // 2. Notification must not be dispatched
      final shouldNotify =
          await UpdateService.shouldShowUpdateNotification(
        update.versionCode,
        currentInstalledCode: currentCode,
      );
      expect(shouldNotify, isFalse);
    });

    test('Scenario 3: App launch synchronization cleans up old update state and cache', () async {
      // Setup previous state with pending notification
      await prefs.setInt('kholo_installed_version_code', 2);
      await prefs.setInt('kholo_last_notified_version_code', 20);

      // Simulate app launch on upgraded version 20
      await UpdateService.syncInstalledVersionOnLaunch();

      final installedVersion = prefs.getInt('kholo_installed_version_code');
      expect(installedVersion, UpdateService.defaultVersionCode);

      final migrationStatus = prefs.getString('kholo_migration_status');
      expect(migrationStatus, 'completed');
    });

    test('Semantic version comparison handles patch, minor, major versions safely', () {
      expect(AppUpdate.isSemanticNewer('1.3.0', '1.2.0'), isTrue);
      expect(AppUpdate.isSemanticNewer('1.2.1', '1.2.0'), isTrue);
      expect(AppUpdate.isSemanticNewer('2.0.0', '1.9.9'), isTrue);
      expect(AppUpdate.isSemanticNewer('v1.3.0', '1.3.0'), isFalse);
      expect(AppUpdate.isSemanticNewer('1.3.0', '1.3.0'), isFalse);
      expect(AppUpdate.isSemanticNewer('1.2.0', '1.3.0'), isFalse);
      expect(AppUpdate.isSemanticNewer('1.0.0', '2.0.0'), isFalse);
    });

    test('AppUpdate effectiveApkUrl resolves dynamic GitHub release fallback when empty', () {
      const updateWithoutUrl = AppUpdate(
        latestVersion: '1.3.0',
        versionCode: 20,
        releaseNotes: 'Notes',
        apkUrl: '',
        forceUpdate: false,
      );

      expect(
        updateWithoutUrl.effectiveApkUrl,
        'https://github.com/Blackproxya2z/kholo-app/releases/download/v1.3.0/app-release.apk',
      );
    });

    test('Cryptographic SHA-256 verification detects corrupted or tampered file', () async {
      final tempDir = Directory.systemTemp.createTempSync('kholo_test_');
      final testFile = File('${tempDir.path}/test_app.apk');
      await testFile.writeAsString('KHOLO official signed production binary content');

      final correctHash = await UpdateService.calculateSha256(testFile);
      expect(correctHash.isNotEmpty, isTrue);

      // 1. Correct hash matches
      final isValid = await UpdateService.verifyChecksum(testFile, correctHash);
      expect(isValid, isTrue);

      // 2. Tampered hash is rejected
      final isTampered =
          await UpdateService.verifyChecksum(testFile, 'bad0000000000000000000000000000000000000000000000000000000000000');
      expect(isTampered, isFalse);

      tempDir.deleteSync(recursive: true);
    });

    test('UpdateNotifier state management initializes with correct version', () async {
      final notifier = UpdateNotifier();
      expect(notifier.state.currentVersionCode, UpdateService.defaultVersionCode);
      expect(notifier.state.currentVersionName, UpdateService.defaultVersionName);
      expect(notifier.state.status, UpdateStatus.idle);
    });

    test('AppUpdate candidateUrls, mirror failover, and formattedFileSize', () {
      const update = AppUpdate(
        latestVersion: '1.3.0',
        versionCode: 20,
        releaseNotes: 'Notes',
        apkUrl: 'https://custom-cdn.kholo.care/app-release.apk',
        mirrorUrls: [
          'https://raw.githubusercontent.com/Blackproxya2z/kholo-releases/main/app-release.apk',
        ],
        fileSize: 65860000,
        forceUpdate: false,
      );

      expect(update.formattedFileSize, '62.8 MB');
      expect(update.candidateUrls.length, 3);
      expect(update.candidateUrls.first, 'https://custom-cdn.kholo.care/app-release.apk');
      expect(update.candidateUrls[1], 'https://raw.githubusercontent.com/Blackproxya2z/kholo-releases/main/app-release.apk');
      expect(update.candidateUrls.last, contains('github.com'));
    });

    test('UpdateDownloadException formats friendly user message', () {
      const exception = UpdateDownloadException('HttpException: Connection closed while receiving data');
      expect(exception.toString(), contains('ইন্টারনেট সংযোগ চেক করে'));
      expect(exception.toString(), contains('Please check your internet connection'));
    });

    testWidgets('MandatoryUpdateScreen renders optional update mode with Later and Update Now', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const update = AppUpdate(
        latestVersion: '1.3.1',
        versionCode: 21,
        releaseNotes: 'Performance optimization and bug fixes.',
        apkUrl: 'https://github.com/Blackproxya2z/kholo-app/releases/download/v1.3.1/app-release.apk',
        apkSha256: 'a1b2c3d4e5f6',
        forceUpdate: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: MandatoryUpdateScreen(
            update: update,
            currentVersionCode: 20,
            currentVersionName: '1.3.0',
          ),
        ),
      );

      expect(find.text('Software Update'), findsOneWidget);
      expect(find.text('Update Now'), findsOneWidget);
      expect(find.text('Later'), findsWidgets);
      expect(find.text('v1.3.1 (21)'), findsOneWidget);
      expect(find.textContaining('Zero Data Loss'), findsOneWidget);
    });

    testWidgets('MandatoryUpdateScreen renders force update mode with Update Now (Required) only', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const update = AppUpdate(
        latestVersion: '2.0.0',
        versionCode: 30,
        releaseNotes: 'Critical security migration.',
        apkUrl: 'https://github.com/Blackproxya2z/kholo-app/releases/download/v2.0.0/app-release.apk',
        forceUpdate: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: MandatoryUpdateScreen(
            update: update,
            currentVersionCode: 20,
            currentVersionName: '1.3.0',
          ),
        ),
      );

      expect(find.text('Critical Update Required'), findsOneWidget);
      expect(find.text('Update Now (Required)'), findsOneWidget);
      expect(find.text('Later'), findsNothing);
    });
  });
}

