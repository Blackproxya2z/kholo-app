/// Data model representing an available app update fetched from the remote
/// version manifest (version.json hosted on GitHub Releases / any CDN).
class AppUpdate {
  /// The latest available version string, e.g. "1.2.0"
  final String latestVersion;

  /// Integer build number used for numeric comparison
  final int versionCode;

  /// Human-readable changelog shown in the update dialog
  final String releaseNotes;

  /// Direct download URL for the new APK
  final String apkUrl;

  /// If true, user cannot dismiss the update dialog — update is mandatory
  final bool forceUpdate;

  const AppUpdate({
    required this.latestVersion,
    required this.versionCode,
    required this.releaseNotes,
    required this.apkUrl,
    required this.forceUpdate,
  });

  factory AppUpdate.fromJson(Map<String, dynamic> json) {
    return AppUpdate(
      latestVersion: json['latestVersion'] as String? ?? '1.0.0',
      versionCode: json['versionCode'] as int? ?? 1,
      releaseNotes: json['releaseNotes'] as String? ?? '',
      apkUrl: json['apkUrl'] as String? ?? '',
      forceUpdate: json['forceUpdate'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'latestVersion': latestVersion,
        'versionCode': versionCode,
        'releaseNotes': releaseNotes,
        'apkUrl': apkUrl,
        'forceUpdate': forceUpdate,
      };
}
