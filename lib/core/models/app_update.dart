/// ─── KHOLO REMOTE CONTROLLED APP UPDATE & VERSION MIGRATION MODEL ─────────
///
/// Supports:
/// - Minimum supported version (minRequiredVersionCode / minSupportedVersion)
/// - Latest available version (versionCode / latestVersion)
/// - Force update flag (forceUpdate / updateRequired)
/// - Update title & message
/// - Release notes (String or List<String>) & update benefits
/// - Direct APK download URL, mirror URLs, and fallback endpoints
/// - Expected file size & formatted display
/// - Cryptographic SHA-256 checksum
/// - Multi-format schema resolution (camelCase & snake_case)
/// ────────────────────────────────────────────────────────────────────────────
class AppUpdate {
  final String latestVersion;
  final int versionCode;
  final int? minRequiredVersionCode;
  final String minSupportedVersion;
  final String updateTitle;
  final String updateMessage;
  final String releaseNotes;
  final List<String> benefits;
  final String apkUrl;
  final List<String> mirrorUrls;
  final String? apkSha256;
  final int? fileSize;
  final bool forceUpdate;

  const AppUpdate({
    required this.latestVersion,
    required this.versionCode,
    this.minRequiredVersionCode,
    this.minSupportedVersion = '1.0.0',
    this.updateTitle = 'Your KHOLO experience has improved',
    this.updateMessage =
        'Please update to the latest version to continue using KHOLO safely.',
    required this.releaseNotes,
    this.benefits = const [
      'Enhanced on-device health privacy & encrypted baselines',
      'Refined cycle & ovulation prediction algorithms',
      'Interactive pregnancy kick counter & contraction timer',
      'Multi-baby timeline logs & developmental milestones',
      'Intelligent AI skin wellness companion with zero battery drain',
    ],
    required this.apkUrl,
    this.mirrorUrls = const [],
    this.apkSha256,
    this.fileSize,
    required this.forceUpdate,
  });

  /// Factory constructor supporting both camelCase and snake_case keys from remote JSON
  factory AppUpdate.fromJson(Map<String, dynamic> json) {
    final latestVer =
        (json['latest_version'] ?? json['latestVersion'] ?? '1.3.0').toString().trim();

    final rawCode = json['version_code'] ?? json['versionCode'] ?? 20;
    final code =
        rawCode is int ? rawCode : int.tryParse(rawCode.toString()) ?? 20;

    final rawMinCode =
        json['min_required_version_code'] ?? json['minRequiredVersionCode'];
    final minCode = rawMinCode is int
        ? rawMinCode
        : (rawMinCode != null ? int.tryParse(rawMinCode.toString()) : null);

    final minVer = (json['min_supported_version'] ??
            json['minSupportedVersion'] ??
            json['minimumSupportedVersion'] ??
            '1.0.0')
        .toString().trim();

    final title = (json['update_title'] ??
            json['updateTitle'] ??
            'Your KHOLO experience has improved')
        .toString().trim();

    final msg = (json['update_message'] ??
            json['updateMessage'] ??
            'Please update to the latest version to continue using KHOLO safely.')
        .toString().trim();

    // Handle releaseNotes whether it is a List<String> or a String
    final rawNotes = json['release_notes'] ?? json['releaseNotes'];
    final String notes;
    if (rawNotes is List) {
      notes = rawNotes.map((e) => '• $e').join('\n');
    } else if (rawNotes != null && rawNotes.toString().trim().isNotEmpty) {
      notes = rawNotes.toString().trim();
    } else {
      notes = '🌸 New features, performance enhancements, and security upgrades.';
    }

    final rawBenefits = json['benefits'] ?? json['update_benefits'];
    final benefitsList = rawBenefits is List
        ? rawBenefits.map((e) => e.toString().trim()).toList()
        : const [
            'Enhanced on-device health privacy & encrypted baselines',
            'Refined cycle & ovulation prediction algorithms',
            'Interactive pregnancy kick counter & contraction timer',
            'Multi-baby timeline logs & developmental milestones',
            'Intelligent AI skin wellness companion with zero battery drain',
          ];

    var url = (json['download_url'] ??
            json['downloadUrl'] ??
            json['apk_url'] ??
            json['apkUrl'] ??
            '')
        .toString().trim();

    if (url.isEmpty) {
      url =
          'https://github.com/Blackproxya2z/kholo-app/releases/download/v$latestVer/app-release.apk';
    }

    final rawMirrors = json['mirror_urls'] ??
        json['mirrorUrls'] ??
        json['fallback_urls'] ??
        json['fallbackUrls'] ??
        json['mirrors'];
    final List<String> mirrors = [];
    if (rawMirrors is List) {
      for (final m in rawMirrors) {
        final str = m?.toString().trim() ?? '';
        if (str.isNotEmpty) mirrors.add(str);
      }
    }

    final sha = (json['apk_sha256'] ?? json['apkSha256'] ?? json['sha256'])
        ?.toString()
        .trim();

    final rawSize = json['file_size'] ??
        json['fileSize'] ??
        json['apk_size'] ??
        json['apkSize'] ??
        json['size'];
    final size = rawSize is int
        ? rawSize
        : (rawSize != null ? int.tryParse(rawSize.toString()) : null);

    final rawForce = json['force_update'] ??
        json['forceUpdate'] ??
        json['update_required'] ??
        json['updateRequired'];

    final explicitForce = rawForce is bool
        ? rawForce
        : (rawForce?.toString().toLowerCase() == 'true');

    return AppUpdate(
      latestVersion: latestVer,
      versionCode: code,
      minRequiredVersionCode: minCode,
      minSupportedVersion: minVer,
      updateTitle: title,
      updateMessage: msg,
      releaseNotes: notes,
      benefits: benefitsList,
      apkUrl: url,
      mirrorUrls: mirrors,
      apkSha256: sha != null && sha.isNotEmpty ? sha : null,
      fileSize: size,
      forceUpdate: explicitForce,
    );
  }

  /// Resolved reliable download URL guarantee (primary URL)
  String get effectiveApkUrl {
    if (apkUrl.isNotEmpty) return apkUrl;
    return 'https://github.com/Blackproxya2z/kholo-app/releases/download/v$latestVersion/app-release.apk';
  }

  /// Ordered candidate list of download endpoints (Primary + Mirrors + Fallback)
  List<String> get candidateUrls {
    final list = <String>[];
    if (apkUrl.isNotEmpty && !list.contains(apkUrl)) {
      list.add(apkUrl);
    }
    for (final mirror in mirrorUrls) {
      if (mirror.isNotEmpty && !list.contains(mirror)) {
        list.add(mirror);
      }
    }
    final githubFallback =
        'https://github.com/Blackproxya2z/kholo-app/releases/download/v$latestVersion/app-release.apk';
    if (!list.contains(githubFallback)) {
      list.add(githubFallback);
    }
    return list;
  }

  /// Formatted human-readable file size (e.g. "62.8 MB")
  String? get formattedFileSize {
    if (fileSize == null || fileSize! <= 0) return null;
    final mb = fileSize! / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  /// Determines if an installed version requires a mandatory (forced) update
  bool isMandatory(int currentVersionCode) {
    if (forceUpdate) return true;
    if (minRequiredVersionCode != null &&
        currentVersionCode < minRequiredVersionCode!) {
      return true;
    }
    return false;
  }

  /// Checks if this remote update is strictly newer than current installed build
  bool isNewerThan(int currentCode, String currentVersionName) {
    // If current installed version is semantically higher (e.g. installed 1.3.0 vs remote 1.2.0),
    // remote is definitely not newer.
    if (isSemanticNewer(currentVersionName, latestVersion)) {
      return false;
    }
    // If remote version is semantically higher (e.g. remote 1.4.0 vs installed 1.3.0),
    // remote is strictly newer.
    if (isSemanticNewer(latestVersion, currentVersionName)) {
      return true;
    }
    // If semantic versions are identical (e.g. both 1.3.0), compare build codes.
    return versionCode > currentCode;
  }

  /// Compares semantic versions (e.g. "1.3.0" > "1.2.0")
  static bool isSemanticNewer(String remoteVer, String currentVer) {
    try {
      // Strip potential 'v' prefix
      final cleanRemote = remoteVer.replaceAll(RegExp(r'^v'), '').split('+')[0];
      final cleanCurrent = currentVer.replaceAll(RegExp(r'^v'), '').split('+')[0];

      final rParts = cleanRemote.split('.').map((p) => int.tryParse(p) ?? 0).toList();
      final cParts = cleanCurrent.split('.').map((p) => int.tryParse(p) ?? 0).toList();

      final maxLen = rParts.length > cParts.length ? rParts.length : cParts.length;

      for (int i = 0; i < maxLen; i++) {
        final r = i < rParts.length ? rParts[i] : 0;
        final c = i < cParts.length ? cParts[i] : 0;
        if (r > c) return true;
        if (r < c) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  AppUpdate copyWith({
    String? latestVersion,
    int? versionCode,
    int? minRequiredVersionCode,
    String? minSupportedVersion,
    String? updateTitle,
    String? updateMessage,
    String? releaseNotes,
    List<String>? benefits,
    String? apkUrl,
    List<String>? mirrorUrls,
    String? apkSha256,
    int? fileSize,
    bool? forceUpdate,
  }) {
    return AppUpdate(
      latestVersion: latestVersion ?? this.latestVersion,
      versionCode: versionCode ?? this.versionCode,
      minRequiredVersionCode:
          minRequiredVersionCode ?? this.minRequiredVersionCode,
      minSupportedVersion: minSupportedVersion ?? this.minSupportedVersion,
      updateTitle: updateTitle ?? this.updateTitle,
      updateMessage: updateMessage ?? this.updateMessage,
      releaseNotes: releaseNotes ?? this.releaseNotes,
      benefits: benefits ?? this.benefits,
      apkUrl: apkUrl ?? this.apkUrl,
      mirrorUrls: mirrorUrls ?? this.mirrorUrls,
      apkSha256: apkSha256 ?? this.apkSha256,
      fileSize: fileSize ?? this.fileSize,
      forceUpdate: forceUpdate ?? this.forceUpdate,
    );
  }

  Map<String, dynamic> toJson() => {
        'latest_version': latestVersion,
        'version_code': versionCode,
        'min_required_version_code': minRequiredVersionCode,
        'min_supported_version': minSupportedVersion,
        'update_title': updateTitle,
        'update_message': updateMessage,
        'release_notes': releaseNotes,
        'benefits': benefits,
        'download_url': apkUrl,
        'mirror_urls': mirrorUrls,
        'apk_sha256': apkSha256,
        'file_size': fileSize,
        'force_update': forceUpdate,
      };
}
