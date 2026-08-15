import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import '../models/app_update.dart';

/// Custom exception thrown when an APK fails cryptographic checksum validation.
class SecurityIntegrityException implements Exception {
  final String message;
  const SecurityIntegrityException(this.message);

  @override
  String toString() => 'SecurityIntegrityException: $message';
}

/// ─── IN-APP AUTO-UPDATE & ANTI-TAMPER ENGINE ────────────────────────────────
///
/// Features:
/// 1. Zero-Rate-Limit GitHub Raw / Cloudflare cached version polling.
/// 2. Cryptographic SHA-256 streaming checksum validation.
/// 3. In-place upgrade via Android PackageInstaller (preserving all local data).
/// 4. Anti-tampering defense (deletes corrupted/manipulated binaries immediately).
/// ────────────────────────────────────────────────────────────────────────────
class UpdateService {
  /// GitHub raw version manifest endpoint (cached and CDN-backed).
  static const String versionManifestUrl =
      'https://raw.githubusercontent.com/Blackproxya2z/kholo-releases/main/version.json';

  UpdateService._();

  /// Checks if a newer version is available.
  /// Returns [AppUpdate] if update exists, null otherwise.
  static Future<AppUpdate?> checkForUpdate() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentCode = int.tryParse(info.buildNumber) ?? 1;

      final response = await http
          .get(
            Uri.parse(versionManifestUrl),
            headers: {
              'Accept': 'application/json',
              'Cache-Control': 'no-cache',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final update = AppUpdate.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );

      // Only show update if remote versionCode is strictly greater
      if (update.versionCode > currentCode && update.apkUrl.isNotEmpty) {
        return update;
      }
      return null;
    } catch (e) {
      debugPrint('[UpdateService] checkForUpdate error: $e');
      return null;
    }
  }

  /// Calculates SHA-256 hash using chunked stream without loading whole APK into memory.
  static Future<String> calculateSha256(File file) async {
    final stream = file.openRead();
    final digest = await sha256.bind(stream).first;
    return digest.toString().toLowerCase();
  }

  /// Validates file integrity against expected SHA-256 checksum string.
  static Future<bool> verifyChecksum(File file, String expectedSha256) async {
    if (!await file.exists()) return false;
    final cleanExpected = expectedSha256.trim().toLowerCase();
    if (cleanExpected.isEmpty) return true;

    final actualSha256 = await calculateSha256(file);
    final isValid = actualSha256 == cleanExpected;

    if (!isValid) {
      debugPrint('[UpdateService] SHA-256 Mismatch!');
      debugPrint('   Expected: $cleanExpected');
      debugPrint('   Actual:   $actualSha256');
    }

    return isValid;
  }

  /// Downloads the APK at [apkUrl], tracks progress, and executes SHA-256 verification.
  ///
  /// If SHA-256 fails or file is manipulated, the file is deleted immediately and
  /// [SecurityIntegrityException] is reported.
  static Future<String?> downloadApk(
    String apkUrl, {
    String? expectedSha256,
    required ValueChanged<double> onProgress,
    ValueChanged<String>? onStatusChange,
  }) async {
    try {
      // Request install permission on Android 8.0+
      if (Platform.isAndroid) {
        final status = await Permission.requestInstallPackages.request();
        if (!status.isGranted) {
          debugPrint('[UpdateService] Install permission not granted.');
          return null;
        }
      }

      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/kholo_update_staged.apk';
      final file = File(savePath);

      // Delete any previous staged file
      if (await file.exists()) {
        await file.delete();
      }

      onStatusChange?.call('Downloading update...');

      final dio = Dio();
      await dio.download(
        apkUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0) onProgress(received / total);
        },
        options: Options(
          receiveTimeout: const Duration(minutes: 10),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      // Verify SHA-256 Checksum if provided
      if (expectedSha256 != null && expectedSha256.trim().isNotEmpty) {
        onStatusChange?.call('Verifying integrity (SHA-256)...');
        final isVerified = await verifyChecksum(file, expectedSha256);

        if (!isVerified) {
          // Immediately wipe tampered payload
          if (await file.exists()) {
            await file.delete();
          }
          throw const SecurityIntegrityException(
            'APK integrity check failed! Binary may be tampered or corrupted.',
          );
        }
      }

      return savePath;
    } catch (e) {
      debugPrint('[UpdateService] downloadApk error: $e');
      rethrow;
    }
  }

  /// Triggers the Android system package installer for an in-place upgrade.
  /// Existing user data, SQLite records, and SharedPreferences are preserved.
  static Future<OpenResult> installApk(String filePath) async {
    debugPrint('[UpdateService] Triggering in-place installation: $filePath');
    return await OpenFilex.open(filePath, type: 'application/vnd.android.package-archive');
  }

  /// Returns current app version display string, e.g. "1.0.0 (build 1)"
  static Future<String> currentVersionDisplay() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return '${info.version} (build ${info.buildNumber})';
    } catch (_) {
      return '1.0.0 (build 1)';
    }
  }

  /// Returns current app versionCode integer
  static Future<int> currentVersionCode() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return int.tryParse(info.buildNumber) ?? 1;
    } catch (_) {
      return 1;
    }
  }
}
