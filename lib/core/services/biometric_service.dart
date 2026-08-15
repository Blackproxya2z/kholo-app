import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/foundation.dart';

/// Service for biometric (fingerprint / face) app-lock.
/// Usage: call [authenticate] when app resumes from background.
class BiometricService {
  BiometricService._();

  static final _auth = LocalAuthentication();

  /// Returns true if device supports biometric auth.
  static Future<bool> isAvailable() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Returns list of available biometric types (fingerprint, face, etc.)
  static Future<List<BiometricType>> availableTypes() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Prompts the user for biometric verification.
  /// Returns true if authenticated, false otherwise.
  static Future<bool> authenticate({
    String reason = 'Authenticate to open KHOLO',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false, // Allow PIN/pattern fallback
          stickyAuth: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('[BiometricService] error: $e');
      return false;
    }
  }

  /// Stop any in-progress authentication.
  static Future<void> cancel() async {
    try {
      await _auth.stopAuthentication();
    } catch (_) {}
  }
}
