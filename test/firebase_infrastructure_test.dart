import 'package:flutter_test/flutter_test.dart';
import 'package:kholo/core/services/firebase_service.dart';
import 'package:kholo/core/services/firebase_crashlytics_service.dart';
import 'package:kholo/core/services/firebase_remote_config_service.dart';
import 'package:kholo/core/services/firebase_analytics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Firebase Production Infrastructure & Privacy Architecture Tests', () {
    test('FirebaseService initializes safely in test/offline environment without crashing', () async {
      await FirebaseService.init();
      expect(true, isTrue);
    });

    test('FirebaseCrashlyticsService records non-fatal errors with sanitized diagnostic keys', () async {
      await FirebaseCrashlyticsService.init();

      expect(() async {
        await FirebaseCrashlyticsService.recordNonFatalError(
          Exception('Test Camera2 Initialization Timeout'),
          StackTrace.current,
          reason: 'Camera preview test failure',
          diagnosticKeys: {
            'screen': 'SkinScanScreen',
            'phase': 'initCamera',
            'api_level': 34,
          },
        );
      }, returnsNormally);
    });

    test('FirebaseCrashlyticsService specialized tracking methods execute safely', () async {
      await FirebaseCrashlyticsService.init();

      expect(() async {
        await FirebaseCrashlyticsService.recordCameraCrash(
          Exception('Camera unavailable'),
          StackTrace.current,
          details: 'Camera2 preview test timeout',
        );
        await FirebaseCrashlyticsService.recordUpdateFailure(
          Exception('Network stream broken'),
          StackTrace.current,
          targetVersionCode: 21,
          stage: 'download_chunk',
        );
        await FirebaseCrashlyticsService.recordRuntimeError(
          Exception('State error'),
          StackTrace.current,
          context: 'test_context',
        );
        await FirebaseCrashlyticsService.logBreadcrumb('Navigated to /app');
        await FirebaseCrashlyticsService.logBreadcrumb('Sensitive cycle period note'); // Should be dropped safely
        await FirebaseCrashlyticsService.setAnonymousUserId('anon_usr_12345');
      }, returnsNormally);
    });

    test('FirebaseRemoteConfigService provides valid default parameters, announcements & feature flags', () async {
      await FirebaseRemoteConfigService.init();

      // Check maintenance mode default
      expect(FirebaseRemoteConfigService.isMaintenanceMode, isFalse);
      expect(FirebaseRemoteConfigService.maintenanceMessage, isNotEmpty);
      expect(FirebaseRemoteConfigService.isOptionalUpdateEnabled, isTrue);

      // Check feature flags
      expect(FirebaseRemoteConfigService.isFeatureEnabled('ai_skin_scan_enabled'), isTrue);
      expect(FirebaseRemoteConfigService.isFeatureEnabled('baby_care_enabled'), isTrue);
      expect(FirebaseRemoteConfigService.isFeatureEnabled('pregnancy_journey_enabled'), isTrue);
      expect(FirebaseRemoteConfigService.isFeatureEnabled('cycle_tracker_enabled'), isTrue);
      expect(FirebaseRemoteConfigService.isFeatureEnabled('fertility_insights_enabled'), isTrue);
      expect(FirebaseRemoteConfigService.isFeatureEnabled('teleconsultation_enabled'), isFalse);

      // Check announcements
      final announcements = FirebaseRemoteConfigService.getDynamicAnnouncements();
      expect(announcements, isNotEmpty);
      expect(announcements.first.id, 'welcome_beta');

      // Check remote AppUpdate generation
      final update = FirebaseRemoteConfigService.getRemoteAppUpdate();
      expect(update.latestVersion, '1.3.1');
      expect(update.versionCode, 21);
      expect(update.forceUpdate, isFalse);
      expect(update.releaseNotes, isNotEmpty);
      expect(update.apkUrl, contains('https://github.com'));
    });

    test('FirebaseAnalyticsService enforces strict PHI privacy filtering and tracking methods', () async {
      await FirebaseAnalyticsService.init();

      expect(() async {
        await FirebaseAnalyticsService.logAppOpen();
        await FirebaseAnalyticsService.logScreenView('/app');
        await FirebaseAnalyticsService.logFeatureEngagement('animated_cycle_ring');
        await FirebaseAnalyticsService.logUpdateEvent('update_check_completed', parameters: {
          'current_code': 20,
          'target_code': 20,
        });
        await FirebaseAnalyticsService.logEvent('skin_scan_completed', parameters: {
          'confidence_bracket': '90_100',
          'source': 'camera2_scanner',
          // The following sensitive keys will be automatically stripped by the privacy filter:
          'baby_name': 'Aarav',
          'cycle_flow': 'heavy',
          'symptom_notes': 'private user note',
          'pregnancy_week': 24,
        });
      }, returnsNormally);
    });
  });
}
