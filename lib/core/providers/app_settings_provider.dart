import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeModeKey = 'kholo_theme_mode';
const _kDarkModeLegacyKey = 'kholo_dark_mode';
const _kBiometricKey = 'kholo_biometric_lock';

/// Supported theme modes in KHOLO
enum AppThemePreference {
  light,
  dark,
  system,
}

/// Persisted app settings (Theme Mode: Light / Dark / Follow System, Biometric Lock).
class AppSettingsNotifier extends StateNotifier<AppSettings> {
  final SharedPreferences _prefs;

  AppSettingsNotifier(this._prefs)
      : super(AppSettings(
          themePreference: _readThemePreference(_prefs),
          biometricLock: _prefs.getBool(_kBiometricKey) ?? false,
        ));

  static AppThemePreference _readThemePreference(SharedPreferences prefs) {
    final savedMode = prefs.getString(_kThemeModeKey);
    if (savedMode == 'dark') return AppThemePreference.dark;
    if (savedMode == 'light') return AppThemePreference.light;
    if (savedMode == 'system') return AppThemePreference.system;

    // Fallback to legacy boolean if present
    if (prefs.containsKey(_kDarkModeLegacyKey)) {
      final isDark = prefs.getBool(_kDarkModeLegacyKey) ?? false;
      return isDark ? AppThemePreference.dark : AppThemePreference.light;
    }

    return AppThemePreference.system;
  }

  Future<void> setThemePreference(AppThemePreference pref) async {
    final modeString = switch (pref) {
      AppThemePreference.light => 'light',
      AppThemePreference.dark => 'dark',
      AppThemePreference.system => 'system',
    };
    await _prefs.setString(_kThemeModeKey, modeString);
    await _prefs.setBool(
        _kDarkModeLegacyKey, pref == AppThemePreference.dark);
    state = state.copyWith(themePreference: pref);
  }

  Future<void> setDarkMode(bool isDark) async {
    await setThemePreference(
        isDark ? AppThemePreference.dark : AppThemePreference.light);
  }

  Future<void> setBiometricLock(bool value) async {
    await _prefs.setBool(_kBiometricKey, value);
    state = state.copyWith(biometricLock: value);
  }
}

class AppSettings {
  final AppThemePreference themePreference;
  final bool biometricLock;

  const AppSettings({
    required this.themePreference,
    required this.biometricLock,
  });

  bool get darkMode => themePreference == AppThemePreference.dark;

  ThemeMode get themeMode => switch (themePreference) {
        AppThemePreference.light => ThemeMode.light,
        AppThemePreference.dark => ThemeMode.dark,
        AppThemePreference.system => ThemeMode.system,
      };

  AppSettings copyWith({
    AppThemePreference? themePreference,
    bool? darkMode,
    bool? biometricLock,
  }) {
    if (themePreference != null) {
      return AppSettings(
        themePreference: themePreference,
        biometricLock: biometricLock ?? this.biometricLock,
      );
    }
    if (darkMode != null) {
      return AppSettings(
        themePreference:
            darkMode ? AppThemePreference.dark : AppThemePreference.light,
        biometricLock: biometricLock ?? this.biometricLock,
      );
    }
    return AppSettings(
      themePreference: this.themePreference,
      biometricLock: biometricLock ?? this.biometricLock,
    );
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  throw UnimplementedError(
      'Override appSettingsProvider with initialized SharedPreferences');
});
