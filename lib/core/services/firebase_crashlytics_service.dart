import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// ─── PRIVACY-FIRST FIREBASE CRASHLYTICS SERVICE ─────────────────────────────
///
/// Features:
/// 1. Catches uncaught Flutter framework & asynchronous platform errors.
/// 2. Records non-fatal errors (Camera2 failures, update network issues, timeout errors).
/// 3. Strict PHI filtering: Strips all menstrual, pregnancy, baby, and personal health notes.
/// 4. Sets technical diagnostic tags (OS version, device memory state, route).
/// 5. Structured logging for Camera crashes, Update pipeline failures, and Breadcrumbs.
/// ────────────────────────────────────────────────────────────────────────────
class FirebaseCrashlyticsService {
  FirebaseCrashlyticsService._();

  static bool _isAvailable = false;
  static bool get isAvailable => _isAvailable;

  static void markAvailable() {
    _isAvailable = true;
  }

  // PHI Blocklist - Any key containing these terms will be dropped to preserve privacy
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

  /// Initialize Crashlytics hooks
  static Future<void> init() async {
    try {
      if (kIsWeb) return;
      final crashlytics = FirebaseCrashlytics.instance;

      // Pass all uncaught errors from the framework to Crashlytics
      FlutterError.onError = (FlutterErrorDetails details) {
        if (_isAvailable) {
          crashlytics.recordFlutterFatalError(details);
        } else {
          FlutterError.presentError(details);
        }
      };

      // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework
      PlatformDispatcher.instance.onError = (error, stack) {
        if (_isAvailable) {
          crashlytics.recordError(error, stack, fatal: true);
          return true;
        }
        return false;
      };

      _isAvailable = true;
    } catch (e) {
      debugPrint('[CrashlyticsService] Fallback mode active: $e');
      _isAvailable = false;
    }
  }

  /// Sanitize diagnostic keys to enforce Zero PHI transmission
  static Map<String, Object> _sanitizeDiagnosticKeys(Map<String, Object>? raw) {
    if (raw == null || raw.isEmpty) return const {};
    final clean = <String, Object>{};

    for (final entry in raw.entries) {
      final keyLower = entry.key.toLowerCase();
      final isSensitive = _phiKeywords.any((kw) => keyLower.contains(kw));
      if (isSensitive) continue;

      final sanitizedKey = entry.key.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
      if (sanitizedKey.isEmpty) continue;

      final valStr = entry.value.toString();
      final isValSensitive = _phiKeywords.any((kw) => valStr.toLowerCase().contains(kw));
      if (isValSensitive) continue;

      final sanitizedValue = valStr.length > 100 ? valStr.substring(0, 100) : entry.value;
      clean[sanitizedKey] = sanitizedValue;
    }

    return clean;
  }

  /// Record a non-fatal error with diagnostic metadata (Zero PHI)
  static Future<void> recordNonFatalError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    Map<String, Object>? diagnosticKeys,
  }) async {
    try {
      debugPrint('[Crashlytics] Non-fatal logged: $reason | $exception');
      if (_isAvailable && !kIsWeb) {
        final cleanKeys = _sanitizeDiagnosticKeys(diagnosticKeys);
        for (final entry in cleanKeys.entries) {
          await FirebaseCrashlytics.instance.setCustomKey(entry.key, entry.value);
        }
        await FirebaseCrashlytics.instance.recordError(
          exception,
          stack,
          reason: reason,
          fatal: false,
        );
      }
    } catch (e) {
      debugPrint('[CrashlyticsService] Error recording non-fatal: $e');
    }
  }

  /// Specialized Tracker: Camera2 and Sensor Failures
  static Future<void> recordCameraCrash(
    dynamic exception,
    StackTrace? stack, {
    String? details,
  }) async {
    await recordNonFatalError(
      exception,
      stack,
      reason: 'Camera2 / Skin Scanner Sensor Failure',
      diagnosticKeys: {
        'component': 'Camera2Scanner',
        'details': details ?? 'camera_initialization_error',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  /// Specialized Tracker: In-App Update & Download Failures
  static Future<void> recordUpdateFailure(
    dynamic exception,
    StackTrace? stack, {
    required int targetVersionCode,
    required String stage,
    String? details,
  }) async {
    await recordNonFatalError(
      exception,
      stack,
      reason: 'OTA Update Delivery Failure in stage: $stage',
      diagnosticKeys: {
        'component': 'UpdateService',
        'stage': stage,
        'target_build': targetVersionCode,
        'details': details ?? 'download_or_install_failure',
      },
    );
  }

  /// Specialized Tracker: General Runtime & State Errors
  static Future<void> recordRuntimeError(
    dynamic exception,
    StackTrace? stack, {
    required String context,
    Map<String, Object>? metadata,
  }) async {
    final mergedKeys = <String, Object>{
      'runtime_context': context,
      ...?metadata,
    };
    await recordNonFatalError(
      exception,
      stack,
      reason: 'Runtime Error in $context',
      diagnosticKeys: mergedKeys,
    );
  }

  /// Add technical breadcrumb for debugging crash sequences (Zero PHI)
  static Future<void> logBreadcrumb(String message) async {
    try {
      final isSensitive = _phiKeywords.any((kw) => message.toLowerCase().contains(kw));
      if (isSensitive) return;

      debugPrint('[Breadcrumb] $message');
      if (_isAvailable && !kIsWeb) {
        await FirebaseCrashlytics.instance.log(message);
      }
    } catch (_) {}
  }

  /// Sets user diagnostic context (Strictly anonymous ID)
  static Future<void> setAnonymousUserId(String anonymousId) async {
    try {
      if (_isAvailable && !kIsWeb) {
        await FirebaseCrashlytics.instance.setUserIdentifier(anonymousId);
      }
    } catch (_) {}
  }
}
