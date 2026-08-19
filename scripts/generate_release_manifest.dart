// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

/// ─── KHOLO PRIVATE DISTRIBUTION RELEASE MANIFEST GENERATOR ────────────────
///
/// Usage:
///   dart run scripts/generate_release_manifest.dart [apkPath] [version] [buildNumber]
///
/// Example:
///   dart run scripts/generate_release_manifest.dart build/app/outputs/flutter-apk/app-release.apk 1.4.0 22
/// ────────────────────────────────────────────────────────────────────────────
void main(List<String> args) async {
  print('====================================================');
  print('🌸 KHOLO PRIVATE DISTRIBUTION RELEASE GENERATOR 🌸');
  print('====================================================\n');

  final apkPath = args.isNotEmpty
      ? args[0]
      : 'build/app/outputs/flutter-apk/app-release.apk';
  final version = args.length > 1 ? args[1] : '1.4.0';
  final buildNumber =
      args.length > 2 ? int.tryParse(args[2]) ?? 22 : 22;

  final apkFile = File(apkPath);
  if (!await apkFile.exists()) {
    print('❌ Error: APK file not found at "$apkPath".');
    print('   Please run: flutter build apk --release first.\n');
    exit(1);
  }

  print('📦 Analyzing APK: $apkPath');
  final fileSize = await apkFile.length();
  final sizeMb = (fileSize / (1024 * 1024)).toStringAsFixed(2);
  print('   File Size: $fileSize bytes ($sizeMb MB)');

  print('🔐 Calculating Cryptographic SHA-256 Hash...');
  final stream = apkFile.openRead();
  final digest = await sha256.bind(stream).first;
  final sha256Hex = digest.toString().toLowerCase();
  print('   SHA-256:   $sha256Hex\n');

  final releaseManifest = {
    "latestVersion": version,
    "versionCode": buildNumber,
    "buildNumber": buildNumber,
    "minRequiredVersionCode": 20,
    "minimumSupportedVersion": "1.0.0",
    "updateTitle": "New KHOLO Update Available 🌸",
    "updateMessage": "A new version of KHOLO is ready. Update now to enjoy new features.",
    "releaseNotes": [
      "Enhanced on-device health privacy & encrypted baselines",
      "Refined cycle & ovulation prediction algorithms",
      "Interactive pregnancy kick counter & contraction timer",
      "Multi-baby timeline logs & developmental milestones",
      "Intelligent AI skin wellness companion with zero battery drain",
      "Performance optimizations & security enhancements"
    ],
    "benefits": [
      "Complete offline data preservation & privacy lock",
      "Faster cycle calculations & adaptive hormone insights",
      "Direct in-app OTA download & 1-tap installation"
    ],
    "apkUrl": "https://github.com/Blackproxya2z/kholo-app/releases/download/v$version/app-release.apk",
    "apkDownloadUrl": "https://github.com/Blackproxya2z/kholo-app/releases/download/v$version/app-release.apk",
    "mirrorUrls": [
      "https://github.com/Blackproxya2z/kholo-releases/raw/main/v$version/app-release.apk"
    ],
    "apkSha256": sha256Hex,
    "fileSize": fileSize,
    "forceUpdate": false,
    "optionalUpdate": true
  };

  final prettyJson = const JsonEncoder.withIndent('  ').convert(releaseManifest);

  // Write to assets/version.json
  final assetFile = File('assets/version.json');
  await assetFile.writeAsString('$prettyJson\n');
  print('✅ Updated assets/version.json successfully.');

  // Output for Firebase Remote Config
  print('\n📋 PASTE INTO FIREBASE REMOTE CONFIG (`app_update_info`):');
  print('----------------------------------------------------');
  print(prettyJson);
  print('----------------------------------------------------');

  // Output for FCM Notification Campaign
  print('\n📢 FIREBASE CLOUD MESSAGING (FCM) NOTIFICATION PAYLOAD:');
  print('----------------------------------------------------');
  final fcmPayload = {
    "to": "/topics/kholo_updates",
    "notification": {
      "title": "New KHOLO Update Available 🌸",
      "body": "A new version of KHOLO is ready. Update now to enjoy new features."
    },
    "data": {
      "payload": "kholo_update",
      "latest_version": version,
      "version_code": buildNumber.toString(),
      "force_update": "false"
    }
  };
  print(const JsonEncoder.withIndent('  ').convert(fcmPayload));
  print('----------------------------------------------------\n');
  print('🚀 Release manifest generation completed!\n');
}
