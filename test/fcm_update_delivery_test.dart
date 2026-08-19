import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kholo/core/models/app_update.dart';
import 'package:kholo/core/services/update_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FCM & App Update Notification Delivery Engine Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Condition: latest_build_number > installed_build_number triggers update availability', () async {
      const mockUpdateJson = {
        'latest_version': '1.4.0',
        'version_code': 22,
        'min_required_version_code': 1,
        'update_title': '🌸 New KHOLO Update Available',
        'update_message': 'KHOLO v1.4.0 is ready. Update now.',
        'release_notes': 'Bloom Health Hub and AI Personalization',
        'download_url': 'https://github.com/Blackproxya2z/kholo-app/releases/download/v1.4.0/app-release.apk',
        'file_size': 71180392,
        'apk_sha256': '0453d4253feb885fb59b4d9177e95ec787a347e15f4b2f4a0950ee9256ae3e1b',
        'force_update': false,
      };

      final update = AppUpdate.fromJson(mockUpdateJson);
      expect(update.versionCode, 22);
      expect(update.latestVersion, '1.4.0');

      // Test against old installed version (Build 20)
      final isNewerThanOldBuild = update.isNewerThan(20, '1.3.0');
      expect(isNewerThanOldBuild, isTrue);

      // Test against same version (Build 22)
      final isNewerThanCurrent = update.isNewerThan(22, '1.4.0');
      expect(isNewerThanCurrent, isFalse);
    });

    test('Update deduplication and one-time delivery logic', () async {
      const remoteVersionCode = 22;
      const installedCode = 20;

      // Should show notification on first check
      final shouldShowFirstTime = await UpdateService.shouldShowUpdateNotification(
        remoteVersionCode,
        currentInstalledCode: installedCode,
      );
      expect(shouldShowFirstTime, isTrue);

      // Record notification sent
      await UpdateService.recordNotificationSent(remoteVersionCode);

      // Second check should be deduplicated
      final shouldShowSecondTime = await UpdateService.shouldShowUpdateNotification(
        remoteVersionCode,
        currentInstalledCode: installedCode,
      );
      expect(shouldShowSecondTime, isFalse);
    });

    test('Multi-manifest endpoints list contains primary and secondary CDNs', () {
      expect(UpdateService.versionManifestEndpoints, contains(
        'https://raw.githubusercontent.com/Blackproxya2z/kholo-app/main/version.json',
      ));
      expect(UpdateService.versionManifestEndpoints, contains(
        'https://raw.githubusercontent.com/Blackproxya2z/kholo-releases/main/version.json',
      ));
    });
  });
}
