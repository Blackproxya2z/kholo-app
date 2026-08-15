import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import '../models/app_update.dart';

/// ─── HOW TO USE THIS SYSTEM ───────────────────────────────────────────────
///
/// 1. Build your new APK:
///      flutter build apk --release
///
/// 2. Upload APK to a GitHub Release:
///    - Go to github.com → your repo → Releases → "New release"
///    - Tag: v1.1.0, upload the APK
///    - Copy the APK direct download URL
///
/// 3. Host version.json (one-time setup):
///    - Create a public GitHub repo e.g. "kholo-releases"
///    - Add a "version.json" file with the JSON below
///    - Use the raw GitHub URL in [versionManifestUrl]
///
/// 4. Update version.json when you release:
///    {
///      "latestVersion": "1.1.0",
///      "versionCode": 2,
///      "releaseNotes": "• Bug fixes\n• Improved dashboard",
///      "apkUrl": "https://github.com/YOUR_USER/kholo-releases/releases/download/v1.1.0/kholo.apk",
///      "forceUpdate": false
///    }
///
/// 5. Update pubspec.yaml version: 1.1.0+2
///    Users on v1.0.0 will see the update banner automatically!
/// ──────────────────────────────────────────────────────────────────────────

class UpdateService {
  /// 🔗 REPLACE THIS with your actual GitHub raw version.json URL.
  /// Example:
  /// "https://raw.githubusercontent.com/azmain-kholo/releases/main/version.json"
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
          .get(Uri.parse(versionManifestUrl))
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

  /// Downloads the APK at [apkUrl] and reports progress via [onProgress].
  /// Returns the local file path on success, null on failure.
  static Future<String?> downloadApk(
    String apkUrl, {
    required ValueChanged<double> onProgress,
  }) async {
    try {
      // Request INSTALL_PACKAGES permission (Android 8+)
      if (Platform.isAndroid) {
        final status = await Permission.requestInstallPackages.request();
        if (!status.isGranted) {
          debugPrint('[UpdateService] Install permission denied.');
          return null;
        }
      }

      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/kholo_update.apk';

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

      return savePath;
    } catch (e) {
      debugPrint('[UpdateService] downloadApk error: $e');
      return null;
    }
  }

  /// Triggers the Android system install prompt for the APK at [filePath].
  static Future<void> installApk(String filePath) async {
    final result = await OpenFilex.open(filePath);
    debugPrint('[UpdateService] openFilex result: ${result.type}');
  }

  /// Returns current app version string, e.g. "1.0.0 (build 1)"
  static Future<String> currentVersionDisplay() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return '${info.version} (build ${info.buildNumber})';
    } catch (_) {
      return '1.0.0 (build 1)';
    }
  }
}
