import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import '../models/app_update.dart';
import 'dynamic_config_service.dart';

/// ─── FIREBASE REMOTE CONFIG & APP CONTROL SERVICE ───────────────────────────
///
/// Parameters Managed:
/// - latest_version: String (e.g., "1.3.0")
/// - version_code: int (e.g., 20)
/// - force_update: bool
/// - optional_update: bool
/// - release_notes: String
/// - apk_url: String
/// - apk_sha256: String
/// - maintenance_mode: bool
/// - maintenance_message: String
/// - feature_flags: JSON Map
/// - announcements: JSON Array of DynamicBannerAlert objects
/// ────────────────────────────────────────────────────────────────────────────
class FirebaseRemoteConfigService {
  FirebaseRemoteConfigService._();

  static bool _isAvailable = false;
  static bool get isAvailable => _isAvailable;

  // Local resilient default values
  static final Map<String, dynamic> _defaults = {
    'latest_version': '1.3.1',
    'version_code': 21,
    'force_update': false,
    'optional_update': true,
    'release_notes': '🌸 নতুন KHOLO v1.3.1 আপডেট! বেবি কেয়ার, AI স্কিন ডক্টর এবং নতুন সিকিউরিটি ইঞ্জিন।',
    'apk_url': 'https://github.com/Blackproxya2z/kholo-app/releases/download/v1.3.1/app-release.apk',
    'apk_sha256': '',
    'maintenance_mode': false,
    'maintenance_message': 'KHOLO is undergoing scheduled maintenance to improve your experience.',
    'feature_flags': jsonEncode({
      'ai_skin_scan_enabled': true,
      'baby_care_enabled': true,
      'pregnancy_journey_enabled': true,
      'cycle_tracker_enabled': true,
      'shop_enabled': true,
      'fertility_insights_enabled': true,
      'teleconsultation_enabled': false,
    }),
    'announcements': jsonEncode([
      {
        'id': 'welcome_beta',
        'title': 'Welcome to KHOLO Beta',
        'message': 'Enjoy personalized cycle, pregnancy, and baby care insights.',
        'type': 'info',
        'isDismissible': true,
      }
    ]),
  };

  /// Initialize Remote Config with default fallback parameters and cache interval
  static Future<void> init() async {
    try {
      if (kIsWeb || Firebase.apps.isEmpty) {
        _isAvailable = false;
        return;
      }
      final remoteConfig = FirebaseRemoteConfig.instance;

      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode
              ? const Duration(minutes: 1)
              : const Duration(hours: 1),
        ),
      );

      await remoteConfig.setDefaults(_defaults);
      await remoteConfig.fetchAndActivate();

      _isAvailable = true;
      debugPrint('[RemoteConfig] Initialized successfully. Latest: ${remoteConfig.getString('latest_version')}');
    } catch (e) {
      debugPrint('[RemoteConfig] Fallback default values active: $e');
      _isAvailable = false;
    }
  }

  /// Manually trigger fetch and activation of latest remote configuration
  static Future<bool> fetchAndActivate() async {
    try {
      if (!_isAvailable || kIsWeb) return false;
      return await FirebaseRemoteConfig.instance.fetchAndActivate();
    } catch (e) {
      debugPrint('[RemoteConfig] fetchAndActivate error: $e');
      return false;
    }
  }

  /// Check whether maintenance mode is active
  static bool get isMaintenanceMode {
    if (!_isAvailable || kIsWeb) {
      return _defaults['maintenance_mode'] as bool;
    }
    return FirebaseRemoteConfig.instance.getBool('maintenance_mode');
  }

  /// Get maintenance mode announcement message
  static String get maintenanceMessage {
    if (!_isAvailable || kIsWeb) {
      return _defaults['maintenance_message'] as String;
    }
    return FirebaseRemoteConfig.instance.getString('maintenance_message');
  }

  /// Check whether optional update banner is active
  static bool get isOptionalUpdateEnabled {
    if (!_isAvailable || kIsWeb) {
      return _defaults['optional_update'] as bool;
    }
    return FirebaseRemoteConfig.instance.getBool('optional_update');
  }

  /// Check if a specific dynamic feature flag is enabled
  static bool isFeatureEnabled(String flagName) {
    try {
      final rawJson = (_isAvailable && !kIsWeb)
          ? FirebaseRemoteConfig.instance.getString('feature_flags')
          : (_defaults['feature_flags'] as String);
      final map = jsonDecode(rawJson) as Map<String, dynamic>;
      return map[flagName] == true;
    } catch (e) {
      return true; // Safe fallback
    }
  }

  /// Retrieve dynamic announcements published by administrators
  static List<DynamicBannerAlert> getDynamicAnnouncements() {
    try {
      final rawJson = (_isAvailable && !kIsWeb)
          ? FirebaseRemoteConfig.instance.getString('announcements')
          : (_defaults['announcements'] as String);
      final list = jsonDecode(rawJson) as List<dynamic>;
      return list
          .map((e) => DynamicBannerAlert.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Parse the current remote AppUpdate configuration
  static AppUpdate getRemoteAppUpdate() {
    try {
      if (_isAvailable && !kIsWeb) {
        final config = FirebaseRemoteConfig.instance;
        return AppUpdate(
          latestVersion: config.getString('latest_version'),
          versionCode: config.getInt('version_code'),
          forceUpdate: config.getBool('force_update'),
          releaseNotes: config.getString('release_notes'),
          apkUrl: config.getString('apk_url'),
          apkSha256: config.getString('apk_sha256'),
        );
      }
    } catch (e) {
      debugPrint('[RemoteConfig] Error reading remote AppUpdate: $e');
    }

    // Default fallback
    return AppUpdate(
      latestVersion: _defaults['latest_version'] as String,
      versionCode: _defaults['version_code'] as int,
      forceUpdate: _defaults['force_update'] as bool,
      releaseNotes: _defaults['release_notes'] as String,
      apkUrl: _defaults['apk_url'] as String,
      apkSha256: _defaults['apk_sha256'] as String,
    );
  }
}
