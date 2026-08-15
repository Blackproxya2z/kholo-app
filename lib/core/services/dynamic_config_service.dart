import 'dart:convert';
import '../models/health_profile.dart';
import 'local_storage_service.dart';

/// Dynamic Over-The-Air (OTA) Application Configuration.
/// Allows updating phase advice, banners, feature flags, and clinical guidelines
/// without needing full store re-releases.
class DynamicAppConfig {
  final int schemaVersion;
  final String environment;
  final Map<String, bool> featureFlags;
  final List<DynamicPhaseTip> phaseTips;
  final List<DynamicBannerAlert> activeBanners;
  final Map<String, String> contactHotlines;

  const DynamicAppConfig({
    this.schemaVersion = 1,
    this.environment = 'production',
    this.featureFlags = const {
      'animated_cycle_ring': true,
      'liquid_flow_waves': true,
      'pcos_pcod_support': true,
      'fertility_insights': true,
      'ota_config_polling': true,
    },
    this.phaseTips = const [],
    this.activeBanners = const [],
    this.contactHotlines = const {
      'general_health': '16263',
      'maternal_health': '109',
    },
  });

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'environment': environment,
    'featureFlags': featureFlags,
    'phaseTips': phaseTips.map((t) => t.toJson()).toList(),
    'activeBanners': activeBanners.map((b) => b.toJson()).toList(),
    'contactHotlines': contactHotlines,
  };

  factory DynamicAppConfig.fromJson(Map<String, dynamic> json) {
    return DynamicAppConfig(
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      environment: json['environment'] as String? ?? 'production',
      featureFlags: (json['featureFlags'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as bool),
          ) ??
          const {},
      phaseTips: (json['phaseTips'] as List<dynamic>?)
              ?.map((e) => DynamicPhaseTip.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      activeBanners: (json['activeBanners'] as List<dynamic>?)
              ?.map((e) => DynamicBannerAlert.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      contactHotlines: (json['contactHotlines'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ) ??
          const {},
    );
  }

  /// Bundled fallback offline configuration.
  static DynamicAppConfig get bundledDefault => const DynamicAppConfig(
    schemaVersion: 1,
    phaseTips: [
      DynamicPhaseTip(
        phaseKey: 'menstrual',
        title: 'Menstrual Phase (Winter)',
        summary: 'Your hormone levels are at their baseline. Rest, nourish, and hydrate.',
        nutritionTip: 'Iron-rich foods (spinach, lentils), warm soups, and herbal teas.',
        movementTip: 'Gentle stretching, slow walking, and calming yoga.',
      ),
      DynamicPhaseTip(
        phaseKey: 'follicular',
        title: 'Follicular Phase (Spring)',
        summary: 'Estrogen rises, bringing renewed vitality, focus, and creativity.',
        nutritionTip: 'Fermented foods, colorful fresh produce, lean proteins.',
        movementTip: 'Cardio, strength training, and upbeat movement.',
      ),
      DynamicPhaseTip(
        phaseKey: 'ovulation',
        title: 'Ovulation Phase (Summer)',
        summary: 'Estrogen & LH peak. Peak energy, connection, and highest fertility.',
        nutritionTip: 'Antioxidants, berries, avocados, leafy greens, zinc.',
        movementTip: 'High intensity interval training and group sports.',
      ),
      DynamicPhaseTip(
        phaseKey: 'luteal',
        title: 'Luteal Phase (Autumn)',
        summary: 'Progesterone rises. Prioritize steady blood sugar and self-care.',
        nutritionTip: 'Complex carbs (sweet potatoes, oats), magnesium, dark chocolate.',
        movementTip: 'Pilates, yoga, incline walking, and restorative breathing.',
      ),
    ],
  );
}

class DynamicPhaseTip {
  final String phaseKey;
  final String title;
  final String summary;
  final String nutritionTip;
  final String movementTip;

  const DynamicPhaseTip({
    required this.phaseKey,
    required this.title,
    required this.summary,
    required this.nutritionTip,
    required this.movementTip,
  });

  Map<String, dynamic> toJson() => {
    'phaseKey': phaseKey,
    'title': title,
    'summary': summary,
    'nutritionTip': nutritionTip,
    'movementTip': movementTip,
  };

  factory DynamicPhaseTip.fromJson(Map<String, dynamic> json) => DynamicPhaseTip(
    phaseKey: json['phaseKey'] as String? ?? 'unknown',
    title: json['title'] as String? ?? '',
    summary: json['summary'] as String? ?? '',
    nutritionTip: json['nutritionTip'] as String? ?? '',
    movementTip: json['movementTip'] as String? ?? '',
  );
}

class DynamicBannerAlert {
  final String id;
  final String title;
  final String message;
  final String type; // 'info', 'update', 'tip'
  final bool isDismissible;

  const DynamicBannerAlert({
    required this.id,
    required this.title,
    required this.message,
    this.type = 'info',
    this.isDismissible = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'type': type,
    'isDismissible': isDismissible,
  };

  factory DynamicBannerAlert.fromJson(Map<String, dynamic> json) =>
      DynamicBannerAlert(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        message: json['message'] as String? ?? '',
        type: json['type'] as String? ?? 'info',
        isDismissible: json['isDismissible'] as bool? ?? true,
      );
}

/// Service managing dynamic over-the-air configs and local cache synchronization.
class DynamicConfigService {
  final LocalStorageService _storage;

  DynamicConfigService(this._storage);

  /// Load cached dynamic configuration with instant fallback to bundled defaults.
  DynamicAppConfig loadCurrentConfig() {
    try {
      final cachedRaw = _storage.getDynamicConfig();
      if (cachedRaw != null) {
        final decoded = jsonDecode(cachedRaw) as Map<String, dynamic>;
        return DynamicAppConfig.fromJson(decoded);
      }
    } catch (_) {
      // Fallback silently if cache is corrupt
    }
    return DynamicAppConfig.bundledDefault;
  }

  /// Updates local config cache with fresh remote payload.
  Future<void> updateConfig(DynamicAppConfig newConfig) async {
    await _storage.saveDynamicConfig(jsonEncode(newConfig.toJson()));
  }

  /// Get tips for a specific cycle phase.
  DynamicPhaseTip getTipForPhase(CyclePhase phase) {
    final config = loadCurrentConfig();
    final key = phase.phaseKey;
    return config.phaseTips.firstWhere(
      (t) => t.phaseKey == key,
      orElse: () => DynamicAppConfig.bundledDefault.phaseTips.firstWhere(
        (t) => t.phaseKey == key,
        orElse: () => DynamicPhaseTip(
          phaseKey: key,
          title: phase.displayName,
          summary: phase.description,
          nutritionTip: 'Balanced wholesome nutrition.',
          movementTip: 'Intuitive gentle movement.',
        ),
      ),
    );
  }
}
