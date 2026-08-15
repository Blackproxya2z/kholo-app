import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/health_profile.dart';
import '../models/cycle_log.dart';
import '../models/pregnancy_profile.dart';
import '../models/baby_profile.dart';
import '../models/cart_item.dart';

/// Keys for SharedPreferences.
class _Keys {
  static const authUser = 'kholo_auth_user';
  static const healthProfile = 'kholo_health_profile';
  static const cycleLogs = 'kholo_cycle_logs';
  static const pregnancyProfile = 'kholo_pregnancy_profile';
  static const pregnancyLogs = 'kholo_pregnancy_logs';
  static const babies = 'kholo_babies';
  static const babyLogs = 'kholo_baby_logs';
  static const cartItems = 'kholo_cart_items';
  static const dynamicConfig = 'kholo_dynamic_config';
}

/// Simple local-persistence layer backed by SharedPreferences.
/// In production this would be replaced by a server-side persistence layer.
class LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  // ── Auth ──────────────────────────────────────────────────────────────────

  String? getAuthUser() => _prefs.getString(_Keys.authUser);

  Future<void> saveAuthUser(String userId) =>
      _prefs.setString(_Keys.authUser, userId);

  Future<void> clearAuthUser() => _prefs.remove(_Keys.authUser);

  // ── Health profile ─────────────────────────────────────────────────────────

  HealthProfile? getHealthProfile() {
    final raw = _prefs.getString(_Keys.healthProfile);
    if (raw == null) return null;
    return HealthProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveHealthProfile(HealthProfile profile) =>
      _prefs.setString(_Keys.healthProfile, jsonEncode(profile.toJson()));

  // ── Cycle logs ────────────────────────────────────────────────────────────

  List<CycleLog> getCycleLogs() {
    final raw = _prefs.getString(_Keys.cycleLogs);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => CycleLog.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveCycleLog(CycleLog log) async {
    final logs = getCycleLogs();
    final idx = logs.indexWhere((l) => l.id == log.id);
    if (idx >= 0) {
      logs[idx] = log;
    } else {
      logs.add(log);
    }
    await _prefs.setString(
      _Keys.cycleLogs,
      jsonEncode(logs.map((l) => l.toJson()).toList()),
    );
  }

  Future<void> deleteCycleLog(String id) async {
    final logs = getCycleLogs()..removeWhere((l) => l.id == id);
    await _prefs.setString(
      _Keys.cycleLogs,
      jsonEncode(logs.map((l) => l.toJson()).toList()),
    );
  }

  // ── Pregnancy profile ─────────────────────────────────────────────────────

  PregnancyProfile? getPregnancyProfile() {
    final raw = _prefs.getString(_Keys.pregnancyProfile);
    if (raw == null) return null;
    return PregnancyProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> savePregnancyProfile(PregnancyProfile profile) =>
      _prefs.setString(_Keys.pregnancyProfile, jsonEncode(profile.toJson()));

  Future<void> clearPregnancyProfile() => _prefs.remove(_Keys.pregnancyProfile);

  // ── Pregnancy logs ────────────────────────────────────────────────────────

  List<PregnancyLog> getPregnancyLogs() {
    final raw = _prefs.getString(_Keys.pregnancyLogs);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => PregnancyLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> savePregnancyLog(PregnancyLog log) async {
    final logs = getPregnancyLogs();
    final idx = logs.indexWhere((l) => l.id == log.id);
    if (idx >= 0) {
      logs[idx] = log;
    } else {
      logs.add(log);
    }
    await _prefs.setString(
      _Keys.pregnancyLogs,
      jsonEncode(logs.map((l) => l.toJson()).toList()),
    );
  }

  // ── Babies ────────────────────────────────────────────────────────────────

  List<BabyProfile> getBabies() {
    final raw = _prefs.getString(_Keys.babies);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => BabyProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveBaby(BabyProfile baby) async {
    final babies = getBabies();
    final idx = babies.indexWhere((b) => b.id == baby.id);
    if (idx >= 0) {
      babies[idx] = baby;
    } else {
      babies.add(baby);
    }
    await _prefs.setString(
      _Keys.babies,
      jsonEncode(babies.map((b) => b.toJson()).toList()),
    );
  }

  Future<void> deleteBaby(String id) async {
    final babies = getBabies()..removeWhere((b) => b.id == id);
    await _prefs.setString(
      _Keys.babies,
      jsonEncode(babies.map((b) => b.toJson()).toList()),
    );
    // Also delete logs for this baby
    final logs = getBabyLogs()..removeWhere((l) => l.babyId == id);
    await _prefs.setString(
      _Keys.babyLogs,
      jsonEncode(logs.map((l) => l.toJson()).toList()),
    );
  }

  // ── Baby logs ─────────────────────────────────────────────────────────────

  List<BabyLog> getBabyLogs({String? babyId}) {
    final raw = _prefs.getString(_Keys.babyLogs);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    final all = list
        .map((e) => BabyLog.fromJson(e as Map<String, dynamic>))
        .toList();
    if (babyId != null) return all.where((l) => l.babyId == babyId).toList();
    return all;
  }

  Future<void> saveBabyLog(BabyLog log) async {
    final logs = getBabyLogs();
    final idx = logs.indexWhere((l) => l.id == log.id);
    if (idx >= 0) {
      logs[idx] = log;
    } else {
      logs.add(log);
    }
    await _prefs.setString(
      _Keys.babyLogs,
      jsonEncode(logs.map((l) => l.toJson()).toList()),
    );
  }

  // ── Cart ──────────────────────────────────────────────────────────────────

  List<CartItem> getCartItems() {
    final raw = _prefs.getString(_Keys.cartItems);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveCartItems(List<CartItem> items) =>
      _prefs.setString(
        _Keys.cartItems,
        jsonEncode(items.map((i) => i.toJson()).toList()),
      );

  // ── Dynamic OTA Config ───────────────────────────────────────────────────

  String? getDynamicConfig() => _prefs.getString(_Keys.dynamicConfig);

  Future<void> saveDynamicConfig(String rawJson) =>
      _prefs.setString(_Keys.dynamicConfig, rawJson);

  // ── Full account wipe ─────────────────────────────────────────────────────

  Future<void> clearAllData() async {
    await _prefs.clear();
  }
}
