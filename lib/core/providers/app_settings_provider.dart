import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kDarkModeKey = 'kholo_dark_mode';
const _kBiometricKey = 'kholo_biometric_lock';

/// Persisted app settings (dark mode, biometric lock).
class AppSettingsNotifier extends StateNotifier<AppSettings> {
  final SharedPreferences _prefs;

  AppSettingsNotifier(this._prefs)
      : super(AppSettings(
          darkMode: _prefs.getBool(_kDarkModeKey) ?? false,
          biometricLock: _prefs.getBool(_kBiometricKey) ?? false,
        ));

  Future<void> setDarkMode(bool value) async {
    await _prefs.setBool(_kDarkModeKey, value);
    state = state.copyWith(darkMode: value);
  }

  Future<void> setBiometricLock(bool value) async {
    await _prefs.setBool(_kBiometricKey, value);
    state = state.copyWith(biometricLock: value);
  }
}

class AppSettings {
  final bool darkMode;
  final bool biometricLock;

  const AppSettings({required this.darkMode, required this.biometricLock});

  AppSettings copyWith({bool? darkMode, bool? biometricLock}) => AppSettings(
        darkMode: darkMode ?? this.darkMode,
        biometricLock: biometricLock ?? this.biometricLock,
      );

  ThemeMode get themeMode =>
      darkMode ? ThemeMode.dark : ThemeMode.light;
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  throw UnimplementedError(
      'Override appSettingsProvider with initialized SharedPreferences');
});
