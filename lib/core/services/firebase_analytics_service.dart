import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// ─── PRIVACY-FIRST FIREBASE ANALYTICS SERVICE ──────────────────────────────
///
/// CRITICAL PRIVACY ARCHITECTURE:
/// Zero Personal Health Information (PHI) is transmitted.
/// We NEVER log cycle dates, menstrual flow, baby names, pregnancy timelines,
/// personal symptoms, or private user notes to Firebase Analytics.
///
/// Permitted Events (Aggregated technical & UX flows only):
/// - app_open
/// - screen_view (route names only)
/// - feature_engaged (feature identifier only)
/// - theme_changed
/// - update_check_completed
/// - update_download_started
/// - update_download_completed
/// - update_download_failed
/// - update_installed
/// - skin_scan_completed (confidence bracket only, no image data)
/// ────────────────────────────────────────────────────────────────────────────
class FirebaseAnalyticsService {
  FirebaseAnalyticsService._();

  static bool _isAvailable = false;
  static bool get isAvailable => _isAvailable;

  static const List<String> _phiKeywords = [
    'cycle',
    'period',
    'flow',
    'symptom',
    'mood',
    'baby',
    'pregnancy',
    'gestation',
    'trimester',
    'ovulation',
    'follicle',
    'cervical',
    'breast',
    'pain',
    'cramp',
    'note',
    'name',
    'email',
    'phone',
    'address',
  ];

  static Future<void> init() async {
    try {
      if (kIsWeb) return;
      _isAvailable = true;
    } catch (e) {
      _isAvailable = false;
    }
  }

  /// Log application open event
  static Future<void> logAppOpen() async {
    try {
      if (_isAvailable && !kIsWeb) {
        await FirebaseAnalytics.instance.logAppOpen();
      }
    } catch (_) {}
  }

  /// Log generic screen view (route path only, e.g. /app, /cycle, /pregnancy, /shop)
  static Future<void> logScreenView(String screenName) async {
    try {
      if (_isAvailable && !kIsWeb) {
        // Strip any accidental sensitive query parameters
        final cleanPath = screenName.split('?').first;
        await FirebaseAnalytics.instance.logScreenView(screenName: cleanPath);
      }
    } catch (_) {}
  }

  /// Log feature engagement event (feature key only, zero health details)
  static Future<void> logFeatureEngagement(String featureName) async {
    await logEvent('feature_engaged', parameters: {
      'feature_id': featureName,
    });
  }

  /// Log update pipeline lifecycle events
  static Future<void> logUpdateEvent(String eventName, {Map<String, Object>? parameters}) async {
    await logEvent(eventName, parameters: parameters);
  }

  /// Log generic anonymous app action with strict PHI scrubbing
  static Future<void> logEvent(String eventName, {Map<String, Object>? parameters}) async {
    try {
      if (_isAvailable && !kIsWeb) {
        final cleanParams = <String, Object>{};
        if (parameters != null) {
          for (final entry in parameters.entries) {
            final keyLower = entry.key.toLowerCase();
            final isKeySensitive = _phiKeywords.any((kw) => keyLower.contains(kw));
            if (isKeySensitive) continue;

            final sanitizedKey = entry.key.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
            if (sanitizedKey.isEmpty) continue;

            final valStr = entry.value.toString();
            final isValSensitive = _phiKeywords.any((kw) => valStr.toLowerCase().contains(kw));
            if (isValSensitive) continue;

            final sanitizedValue = valStr.length > 100 ? valStr.substring(0, 100) : entry.value;
            cleanParams[sanitizedKey] = sanitizedValue;
          }
        }
        await FirebaseAnalytics.instance.logEvent(
          name: eventName,
          parameters: cleanParams.isEmpty ? null : cleanParams,
        );
      }
    } catch (_) {}
  }
}
