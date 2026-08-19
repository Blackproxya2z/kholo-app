import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/app_update.dart';
import 'notification_service.dart';
import 'firebase_remote_config_service.dart';
import 'firebase_crashlytics_service.dart';
import 'firebase_analytics_service.dart';

/// Custom exception thrown when an APK fails cryptographic checksum validation.
class SecurityIntegrityException implements Exception {
  final String message;
  const SecurityIntegrityException(this.message);

  @override
  String toString() => 'SecurityIntegrityException: $message';
}

/// User-facing download failure exception replacing cryptic network exceptions.
class UpdateDownloadException implements Exception {
  final String technicalMessage;
  final String userMessage;

  const UpdateDownloadException(
    this.technicalMessage, {
    this.userMessage =
        'আপডেট ডাউনলোড সম্পন্ন হতে পারেনি। অনুগ্রহ করে ইন্টারনেট সংযোগ চেক করে আবার চেষ্টা করুন।\n(Update download failed. Please check your internet connection and try again.)',
  });

  @override
  String toString() => userMessage;
}

/// ─── IN-APP AUTO-UPDATE, RESUMABLE DOWNLOAD & RELEASE ENGINE ───────────────
///
/// Production Features:
/// 1. Resumable chunked APK download with HTTP Range header & auto-reconnect.
/// 2. Automatic retry mechanism (up to 3 retries with exponential backoff).
/// 3. Multi-source mirror failover (Primary URL -> CDN Mirrors -> Release Assets).
/// 4. Stale cache purge & zero-cached-APK guarantee.
/// 5. Streaming SHA-256 anti-tamper checksum validation before install.
/// 6. Clear user-friendly error translations without exposing technical stack traces.
/// 7. Post-update verification, notification dismissal & one-time deduplication.
/// ────────────────────────────────────────────────────────────────────────────
class UpdateService {
  /// GitHub raw version manifest endpoints (Primary repo + releases repo CDN).
  static const List<String> versionManifestEndpoints = [
    'https://raw.githubusercontent.com/Blackproxya2z/kholo-app/main/version.json',
    'https://raw.githubusercontent.com/Blackproxya2z/kholo-releases/main/version.json',
  ];

  static const String versionManifestUrl =
      'https://raw.githubusercontent.com/Blackproxya2z/kholo-app/main/version.json';

  static const String _keyInstalledVersion = 'kholo_installed_version_code';
  static const String _keyLastNotifiedVersion = 'kholo_last_notified_version_code';
  static const String _keyUpdateCompletedVersion =
      'kholo_update_completed_version_code';
  static const String _keyMigrationStatus = 'kholo_migration_status';

  UpdateService._();

  /// Default fallback build code when PackageInfo is unavailable (e.g. unit tests)
  static const int defaultVersionCode = 24;
  static const String defaultVersionName = '1.4.2';

  /// Gets current installed app version code (build number, e.g. 20).
  static Future<int> currentVersionCode() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final code = int.tryParse(info.buildNumber);
      if (code != null && code > 0) return code;
    } catch (_) {}

    return defaultVersionCode;
  }

  /// Gets current installed app version name (e.g. "1.3.0").
  static Future<String> currentVersionName() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version.isNotEmpty ? info.version : defaultVersionName;
    } catch (_) {
      return defaultVersionName;
    }
  }

  /// Called on application start to register the current version and clear obsolete update state.
  static Future<void> syncInstalledVersionOnLaunch({
    int? currentInstalledCode,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCode = currentInstalledCode ?? await currentVersionCode();
      final previousInstalled = prefs.getInt(_keyInstalledVersion) ?? 0;

      if (currentCode >= previousInstalled) {
        // App was freshly installed or updated! Clean up all staged APKs and obsolete flags
        await cleanupOldApkCache();
        await prefs.setInt(_keyInstalledVersion, currentCode);
        await prefs.setInt(_keyUpdateCompletedVersion, currentCode);
        await prefs.setString(_keyMigrationStatus, 'completed');

        // Cancel any lingering update notification
        await NotificationService.cancelUpdateNotification();
        debugPrint(
            '[UpdateService] App at build $currentCode. Cleared old update state & cache.');
      }
    } catch (e) {
      debugPrint('[UpdateService] syncInstalledVersionOnLaunch error: $e');
    }
  }

  /// Purges any outdated downloaded APK files and partial temporary downloads.
  static Future<void> cleanupOldApkCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        final files = tempDir.listSync();
        for (final f in files) {
          if (f is File) {
            final name = f.path.toLowerCase();
            if (name.endsWith('.apk') ||
                name.endsWith('.part') ||
                name.endsWith('.tmp') ||
                name.contains('kholo_v')) {
              try {
                await f.delete();
                debugPrint('[UpdateService] Deleted stale APK cache: ${f.path}');
              } catch (_) {}
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[UpdateService] cleanupOldApkCache error: $e');
    }
  }

  /// Checks if a newer version is available from Remote Config or GitHub CDN.
  /// Returns [AppUpdate] if a newer release exists, null otherwise.
  static Future<AppUpdate?> checkForUpdate() async {
    try {
      final currentCode = await currentVersionCode();
      final currentName = await currentVersionName();
      AppUpdate? candidateUpdate;

      // 1. Try fetching from GitHub CDN endpoints with cache buster
      for (final endpoint in versionManifestEndpoints) {
        try {
          final cacheBuster = DateTime.now().millisecondsSinceEpoch;
          final uri = Uri.parse('$endpoint?nocache=$cacheBuster');
          final response = await http
              .get(
                uri,
                headers: {
                  'Accept': 'application/json',
                  'Cache-Control': 'no-cache, no-store, must-revalidate',
                  'Pragma': 'no-cache',
                },
              )
              .timeout(const Duration(seconds: 8));

          if (response.statusCode == 200) {
            final json = jsonDecode(response.body) as Map<String, dynamic>;
            final parsed = AppUpdate.fromJson(json);
            if (candidateUpdate == null || parsed.versionCode > candidateUpdate.versionCode) {
              candidateUpdate = parsed;
            }
            if (candidateUpdate.versionCode >= 22) {
              break; // Found latest release manifest
            }
          }
        } catch (e) {
          debugPrint('[UpdateService] Manifest endpoint error ($endpoint): $e');
        }
      }

      // 2. Fallback to Firebase Remote Config if CDN is unreachable or older
      try {
        final remoteConfigUpdate = FirebaseRemoteConfigService.getRemoteAppUpdate();
        if (candidateUpdate == null ||
            remoteConfigUpdate.versionCode > candidateUpdate.versionCode) {
          candidateUpdate = remoteConfigUpdate;
        }
      } catch (_) {}

      // 3. Fallback to local asset version manifest if newer
      try {
        final assetString = await rootBundle.loadString('assets/version.json');
        final assetJson = jsonDecode(assetString) as Map<String, dynamic>;
        final assetUpdate = AppUpdate.fromJson(assetJson);
        if (candidateUpdate == null ||
            assetUpdate.versionCode > candidateUpdate.versionCode) {
          candidateUpdate = assetUpdate;
        }
      } catch (_) {}

      if (candidateUpdate == null) return null;

      final update = candidateUpdate;
      debugPrint(
          '[UpdateService] Remote build: ${update.versionCode} (v${update.latestVersion}), Installed: $currentCode (v$currentName)');

      final prefs = await SharedPreferences.getInstance();

      // If installed app is already at or above remote release, mark completed
      if (!update.isNewerThan(currentCode, currentName)) {
        await prefs.setInt(_keyLastNotifiedVersion, currentCode);
        await prefs.setInt(_keyUpdateCompletedVersion, currentCode);
        await prefs.setString(_keyMigrationStatus, 'completed');
        await NotificationService.cancelUpdateNotification();
        return null;
      }

      final effectiveApkUrl = update.effectiveApkUrl;
      return update.copyWith(apkUrl: effectiveApkUrl);
    } catch (e, stack) {
      debugPrint('[UpdateService] checkForUpdate error: $e');
      FirebaseCrashlyticsService.recordNonFatalError(e, stack, reason: 'checkForUpdate failure');
      return null;
    }
  }

  /// Performs an active update check upon app launch or foreground resume.
  /// If a newer version is found and [notifyUser] is true, triggers a local push notification.
  static Future<AppUpdate?> performProactiveUpdateCheck({bool notifyUser = true}) async {
    try {
      final update = await checkForUpdate();
      if (update != null) {
        final currentCode = await currentVersionCode();
        final shouldNotify = await shouldShowUpdateNotification(
          update.versionCode,
          currentInstalledCode: currentCode,
        );

        debugPrint('[UpdateService] Proactive check found update v${update.latestVersion} (Build ${update.versionCode}). shouldNotify=$shouldNotify');

        if (shouldNotify && notifyUser) {
          await NotificationService.showUpdateNotification(
            version: update.latestVersion,
            versionCode: update.versionCode,
            title: update.updateTitle,
            message: update.updateMessage,
            releaseNotes: update.releaseNotes,
            force: update.isMandatory(currentCode),
          );
          await recordNotificationSent(update.versionCode);
        }
      }
      return update;
    } catch (e) {
      debugPrint('[UpdateService] performProactiveUpdateCheck error: $e');
      return null;
    }
  }

  /// Determines if a notification should be shown for this version (Strictly once per release).
  static Future<bool> shouldShowUpdateNotification(
    int remoteVersionCode, {
    int? currentInstalledCode,
    String? remoteVersionName,
    String? currentInstalledName,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastNotified = prefs.getInt(_keyLastNotifiedVersion) ?? 0;
      final currentCode = currentInstalledCode ?? await currentVersionCode();
      final currentName = currentInstalledName ?? await currentVersionName();

      // If semantic versions are provided and current installed is newer than remote, never notify
      if (remoteVersionName != null &&
          AppUpdate.isSemanticNewer(currentName, remoteVersionName)) {
        return false;
      }

      // Never notify if current installed version code is at or above remote build
      if (currentCode >= remoteVersionCode && remoteVersionName == null) {
        return false;
      }

      // Only notify if remoteVersionCode is strictly higher than last notified version
      return remoteVersionCode > lastNotified;
    } catch (_) {
      return false;
    }
  }

  /// Marks that an update notification has been dispatched for [remoteVersionCode].
  static Future<void> recordNotificationSent(int remoteVersionCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLastNotifiedVersion, remoteVersionCode);
      await prefs.setString(_keyMigrationStatus, 'notified');
    } catch (_) {}
  }

  /// Marks migration as completed for [installedVersionCode] and cancels update alerts.
  static Future<void> recordUpdateCompleted(int installedVersionCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyUpdateCompletedVersion, installedVersionCode);
      await prefs.setInt(_keyLastNotifiedVersion, installedVersionCode);
      await prefs.setString(_keyMigrationStatus, 'completed');
      await NotificationService.cancelUpdateNotification();
    } catch (_) {}
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

  /// ─── RESILIENT CHUNKED APK DOWNLOAD WITH AUTO-RETRY & MIRROR FAILOVER ─────
  ///
  /// Features:
  /// - Resumes interrupted downloads using HTTP Range header (`bytes=N-`).
  /// - Automatic retries (up to 3 attempts with exponential backoff).
  /// - Mirror failover if primary endpoint fails.
  /// - Clean file staging with unique isolated filename: `kholo_v{version}_{timestamp}.apk`.
  /// - SHA-256 cryptographic verification & size integrity check.
  /// - User-friendly error translations without raw technical traces.
  static Future<String> downloadApk(
    String apkUrl, {
    List<String> mirrorUrls = const [],
    String? expectedSha256,
    int? expectedFileSize,
    String? targetVersion,
    int? targetVersionCode,
    required ValueChanged<double> onProgress,
    ValueChanged<String>? onStatusChange,
  }) async {
    // 1. Wipe stale APK and partial cache first
    await cleanupOldApkCache();

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final verTag = targetVersion != null
        ? 'v${targetVersion}_b${targetVersionCode ?? 0}_'
        : '';
    final finalApkPath = '${tempDir.path}/kholo_$verTag$timestamp.apk';
    final partFilePath = '$finalApkPath.part';
    final partFile = File(partFilePath);
    final finalFile = File(finalApkPath);

    // Build ordered list of candidate URLs
    final candidateUrls = <String>[];
    if (apkUrl.trim().isNotEmpty) candidateUrls.add(apkUrl.trim());
    for (final m in mirrorUrls) {
      if (m.trim().isNotEmpty && !candidateUrls.contains(m.trim())) {
        candidateUrls.add(m.trim());
      }
    }
    if (candidateUrls.isEmpty) {
      candidateUrls.add(
        'https://github.com/Blackproxya2z/kholo-app/releases/download/v${targetVersion ?? defaultVersionName}/app-release.apk',
      );
    }

    onStatusChange?.call('Connecting to secure KHOLO update server...');
    FirebaseAnalyticsService.logUpdateEvent('update_download_started', parameters: {
      'target_version': targetVersion ?? defaultVersionName,
      'target_code': targetVersionCode ?? defaultVersionCode,
    });

    Exception? lastError;

    for (int urlIndex = 0; urlIndex < candidateUrls.length; urlIndex++) {
      final currentUrl = candidateUrls[urlIndex];
      debugPrint(
          '[UpdateService] Attempting download from endpoint [${urlIndex + 1}/${candidateUrls.length}]: $currentUrl');

      const maxRetries = 3;
      int downloadedBytes = 0;
      int totalBytes = expectedFileSize ?? 0;

      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          if (partFile.existsSync()) {
            downloadedBytes = partFile.lengthSync();
          } else {
            downloadedBytes = 0;
          }

          if (attempt > 1) {
            final mb = (downloadedBytes / (1024 * 1024)).toStringAsFixed(1);
            onStatusChange?.call(
                'Reconnecting... Resuming download from $mb MB (Attempt $attempt of $maxRetries)');
            await Future.delayed(Duration(seconds: attempt));
          } else {
            onStatusChange?.call('Downloading latest KHOLO build...');
          }

          final dio = Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 45),
              receiveTimeout: const Duration(minutes: 15),
              sendTimeout: const Duration(seconds: 45),
              followRedirects: true,
              maxRedirects: 15,
              validateStatus: (status) => status != null && status < 400,
              headers: {
                'Accept': '*/*',
                'User-Agent':
                    'KHOLO-App/${targetVersion ?? defaultVersionName} (Android; Mobile)',
                'Cache-Control': 'no-cache, no-store, must-revalidate',
                'Pragma': 'no-cache',
                if (downloadedBytes > 0) 'Range': 'bytes=$downloadedBytes-',
              },
            ),
          );

          final response = await dio.get<ResponseBody>(
            currentUrl,
            options: Options(
              responseType: ResponseType.stream,
              headers: {
                if (downloadedBytes > 0) 'Range': 'bytes=$downloadedBytes-',
              },
            ),
          );

          final statusCode = response.statusCode ?? 200;
          final isPartial = statusCode == 206;

          // Determine content length
          final contentRangeHeader =
              response.headers.value(HttpHeaders.contentRangeHeader);
          final contentLengthHeader =
              response.headers.value(HttpHeaders.contentLengthHeader);

          if (contentRangeHeader != null) {
            // E.g. "bytes 1048576-65860000/65860001"
            final match = RegExp(r'/(\d+)').firstMatch(contentRangeHeader);
            if (match != null) {
              totalBytes = int.tryParse(match.group(1)!) ?? totalBytes;
            }
          } else if (contentLengthHeader != null) {
            final len = int.tryParse(contentLengthHeader) ?? 0;
            if (isPartial) {
              totalBytes = downloadedBytes + len;
            } else {
              totalBytes = len;
            }
          }

          // Open stream in append mode if resuming, or write from 0
          final fileMode = isPartial && downloadedBytes > 0
              ? FileMode.append
              : FileMode.write;

          if (!isPartial && downloadedBytes > 0) {
            downloadedBytes = 0;
          }

          final sink = partFile.openWrite(mode: fileMode);

          try {
            await for (final chunk in response.data!.stream) {
              sink.add(chunk);
              downloadedBytes += chunk.length;

              if (totalBytes > 0) {
                final progress =
                    (downloadedBytes / totalBytes).clamp(0.0, 1.0);
                onProgress(progress);
              }
            }
          } finally {
            await sink.flush();
            await sink.close();
          }

          // Stream finished successfully!
          if (partFile.existsSync() && partFile.lengthSync() >= 5 * 1024 * 1024) {
            // Rename partial file to final APK
            if (finalFile.existsSync()) finalFile.deleteSync();
            partFile.renameSync(finalApkPath);
            onProgress(1.0);

            // 2. Cryptographic SHA-256 Anti-Tamper Verification
            if (expectedSha256 != null && expectedSha256.trim().isNotEmpty) {
              onStatusChange
                  ?.call('Verifying release cryptographic signature...');
              final isValid =
                  await verifyChecksum(finalFile, expectedSha256);

              if (!isValid) {
                await finalFile.delete();
                const integrityEx = SecurityIntegrityException(
                  'APK checksum verification failed. The downloaded file signature does not match the official release.',
                );
                FirebaseCrashlyticsService.recordUpdateFailure(
                  integrityEx,
                  StackTrace.current,
                  targetVersionCode: targetVersionCode ?? defaultVersionCode,
                  stage: 'checksum_validation',
                );
                FirebaseAnalyticsService.logUpdateEvent('update_checksum_failed', parameters: {
                  'target_code': targetVersionCode ?? defaultVersionCode,
                });
                throw integrityEx;
              }
            }

            onStatusChange?.call('Ready to install');
            debugPrint(
                '[UpdateService] Download & validation successful: $finalApkPath');
            FirebaseAnalyticsService.logUpdateEvent('update_download_completed', parameters: {
              'target_version': targetVersion ?? defaultVersionName,
              'target_code': targetVersionCode ?? defaultVersionCode,
            });
            return finalApkPath;
          }
        } catch (e, stack) {
          debugPrint(
              '[UpdateService] Download attempt $attempt failed from $currentUrl: $e');
          lastError = e is Exception ? e : Exception(e.toString());
          if (e is SecurityIntegrityException) {
            rethrow;
          }
          FirebaseCrashlyticsService.recordUpdateFailure(
            e,
            stack,
            targetVersionCode: targetVersionCode ?? defaultVersionCode,
            stage: 'download_chunk',
            details: 'endpoint: $currentUrl, attempt: $attempt',
          );
        }
      }
    }

    // Clean up temporary partial file on complete failure
    if (partFile.existsSync()) {
      try {
        partFile.deleteSync();
      } catch (_) {}
    }

    debugPrint('[UpdateService] All download attempts failed: $lastError');
    FirebaseAnalyticsService.logUpdateEvent('update_download_failed', parameters: {
      'target_code': targetVersionCode ?? defaultVersionCode,
    });
    throw UpdateDownloadException(
      lastError?.toString() ?? 'Network connection closed prematurely.',
    );
  }

  /// Requests package installation permission on Android 8.0+ and triggers system package installer.
  static Future<bool> installApk(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint(
            '[UpdateService] Cannot install: file does not exist: $filePath');
        return false;
      }

      if (Platform.isAndroid) {
        final installPermission =
            await Permission.requestInstallPackages.status;
        if (!installPermission.isGranted) {
          final requested = await Permission.requestInstallPackages.request();
          if (!requested.isGranted) {
            debugPrint(
                '[UpdateService] REQUEST_INSTALL_PACKAGES permission denied by user.');
            return false;
          }
        }
      }

      FirebaseAnalyticsService.logUpdateEvent('update_install_triggered');

      final result = await OpenFilex.open(
        filePath,
        type: 'application/vnd.android.package-archive',
      );

      debugPrint(
          '[UpdateService] OpenFilex result: ${result.type} - ${result.message}');
      return result.type == ResultType.done;
    } catch (e, stack) {
      debugPrint('[UpdateService] installApk error: $e');
      FirebaseCrashlyticsService.recordUpdateFailure(
        e,
        stack,
        targetVersionCode: defaultVersionCode,
        stage: 'install_launch',
      );
      return false;
    }
  }
}
