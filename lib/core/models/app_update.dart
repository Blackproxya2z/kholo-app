/// Data model representing an available app update fetched from the remote
/// version manifest (version.json hosted on GitHub Releases / Cloudflare CDN).
///
/// Follows the PRD schema with full anti-tamper and checksum verification support.
class AppUpdate {
  /// The latest available version string, e.g. "2.1.0"
  final String latestVersion;

  /// Integer build number used for numeric comparison
  final int versionCode;

  /// Minimum supported build number. If installed app is below this, update is forced.
  final int? minRequiredVersionCode;

  /// Human-readable changelog shown in the update dialog
  final String releaseNotes;

  /// Direct download URL for the signed release APK
  final String apkUrl;

  /// SHA-256 checksum string for anti-tamper validation.
  /// If provided, download will verify file integrity before triggering installation.
  final String? apkSha256;

  /// If true, user cannot dismiss the update dialog — update is mandatory
  final bool forceUpdate;

  const AppUpdate({
    required this.latestVersion,
    required this.versionCode,
    this.minRequiredVersionCode,
    required this.releaseNotes,
    required this.apkUrl,
    this.apkSha256,
    required this.forceUpdate,
  });

  /// Factory constructor supporting both camelCase and snake_case keys (PRD specification)
  factory AppUpdate.fromJson(Map<String, dynamic> json) {
    final latestVer = (json['latest_version'] ?? json['latestVersion'] ?? '1.0.0').toString();
    final rawCode = json['version_code'] ?? json['versionCode'] ?? 1;
    final code = rawCode is int ? rawCode : int.tryParse(rawCode.toString()) ?? 1;

    final rawMinCode = json['min_required_version_code'] ?? json['minRequiredVersionCode'];
    final minCode = rawMinCode is int
        ? rawMinCode
        : (rawMinCode != null ? int.tryParse(rawMinCode.toString()) : null);

    final notes = (json['release_notes'] ?? json['releaseNotes'] ?? '').toString();
    final url = (json['download_url'] ?? json['apkUrl'] ?? json['apk_url'] ?? '').toString();
    final sha = (json['apk_sha256'] ?? json['apkSha256'])?.toString();
    final rawForce = json['force_update'] ?? json['forceUpdate'];
    final explicitForce = rawForce is bool
        ? rawForce
        : (rawForce?.toString().toLowerCase() == 'true');

    return AppUpdate(
      latestVersion: latestVer,
      versionCode: code,
      minRequiredVersionCode: minCode,
      releaseNotes: notes,
      apkUrl: url,
      apkSha256: sha != null && sha.trim().isNotEmpty ? sha.trim() : null,
      forceUpdate: explicitForce,
    );
  }

  /// Determines if an installed version requires a mandatory (forced) update
  bool isMandatory(int currentVersionCode) {
    if (forceUpdate) return true;
    if (minRequiredVersionCode != null && currentVersionCode < minRequiredVersionCode!) {
      return true;
    }
    return false;
  }

  Map<String, dynamic> toJson() => {
        'latest_version': latestVersion,
        'version_code': versionCode,
        'min_required_version_code': minRequiredVersionCode,
        'release_notes': releaseNotes,
        'download_url': apkUrl,
        'apk_sha256': apkSha256,
        'force_update': forceUpdate,
      };
}
