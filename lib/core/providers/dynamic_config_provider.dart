import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/health_profile.dart';
import '../services/dynamic_config_service.dart';
import 'providers.dart';

/// Provider for DynamicConfigService instance.
final dynamicConfigServiceProvider = Provider<DynamicConfigService>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return DynamicConfigService(storage);
});

/// StateNotifier providing active dynamic OTA configuration.
final dynamicConfigProvider =
    StateNotifierProvider<DynamicConfigNotifier, DynamicAppConfig>((ref) {
  final service = ref.watch(dynamicConfigServiceProvider);
  return DynamicConfigNotifier(service);
});

class DynamicConfigNotifier extends StateNotifier<DynamicAppConfig> {
  final DynamicConfigService _service;

  DynamicConfigNotifier(this._service) : super(_service.loadCurrentConfig());

  /// Refresh / reload local configuration cache.
  void reload() {
    state = _service.loadCurrentConfig();
  }

  /// Apply an updated remote configuration payload.
  Future<void> applyRemoteConfig(DynamicAppConfig config) async {
    await _service.updateConfig(config);
    state = config;
  }
}

/// Provider for retrieving current phase tip dynamically.
final dynamicPhaseTipProvider =
    Provider.family<DynamicPhaseTip, CyclePhase>((ref, phase) {
  final service = ref.watch(dynamicConfigServiceProvider);
  // Re-read whenever config updates
  ref.watch(dynamicConfigProvider);
  return service.getTipForPhase(phase);
});
