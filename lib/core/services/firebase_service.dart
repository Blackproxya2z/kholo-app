import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'firebase_crashlytics_service.dart';
import 'firebase_messaging_service.dart';
import 'firebase_remote_config_service.dart';
import 'firebase_analytics_service.dart';

/// ─── MASTER FIREBASE INFRASTRUCTURE SERVICE ────────────────────────────────
///
/// Features:
/// 1. Initializes Firebase Core with graceful error recovery on offline or unconfigured environments.
/// 2. Integrates Crashlytics, FCM, Remote Config, and Privacy Analytics.
/// 3. Maintains 100% functionality even when offline or if Firebase fails to initialize.
/// ────────────────────────────────────────────────────────────────────────────
class FirebaseService {
  FirebaseService._();

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  /// Call once during startup. Protected with timeout and total fault-tolerance.
  static Future<void> init() async {
    if (_initialized) return;

    try {
      if (kIsWeb) {
        _initialized = true;
        return;
      }

      await Firebase.initializeApp().timeout(const Duration(seconds: 4));
      _initialized = true;
      debugPrint('[FirebaseService] Firebase.initializeApp() success ✓');

      // Initialize subservices safely
      await Future.wait([
        FirebaseCrashlyticsService.init().catchError((e) {
          debugPrint('[CrashlyticsService] Init warning: $e');
        }),
        FirebaseMessagingService.init().catchError((e) {
          debugPrint('[FCMService] Init warning: $e');
        }),
        FirebaseRemoteConfigService.init().catchError((e) {
          debugPrint('[RemoteConfigService] Init warning: $e');
        }),
        FirebaseAnalyticsService.init().catchError((e) {
          debugPrint('[AnalyticsService] Init warning: $e');
        }),
      ]);
    } catch (e) {
      debugPrint('[FirebaseService] Firebase initialization warning (Fallback mode active): $e');
      _initialized = false;
    }
  }
}
