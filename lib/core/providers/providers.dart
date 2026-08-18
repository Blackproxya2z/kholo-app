import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/local_storage_service.dart';
import '../models/health_profile.dart';
import '../models/cycle_log.dart';
import '../models/pregnancy_profile.dart';
import '../models/baby_profile.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

export 'dynamic_config_provider.dart';
export 'update_provider.dart';

// ── Infrastructure ────────────────────────────────────────────────────────────

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Call ProviderScope override with initialized prefs');
});

final localStorageProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService(ref.watch(sharedPrefsProvider));
});

final localStorageServiceProvider = localStorageProvider;

// ── Auth ──────────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<String?> {
  final LocalStorageService _storage;

  AuthNotifier(this._storage) : super(null) {
    // Load persisted user on startup
    state = _storage.getAuthUser();
  }

  Future<void> signIn(String userId) async {
    await _storage.saveAuthUser(userId);
    state = userId;
  }

  Future<void> signOut() async {
    await _storage.clearAuthUser();
    state = null;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, String?>((ref) {
  return AuthNotifier(ref.watch(localStorageProvider));
});

bool get isSignedIn => false; // helper; real check via authProvider

// ── Health profile ─────────────────────────────────────────────────────────────

class HealthProfileNotifier extends StateNotifier<HealthProfile> {
  final LocalStorageService _storage;

  HealthProfileNotifier(this._storage)
      : super(_storage.getHealthProfile() ?? const HealthProfile());

  Future<void> save(HealthProfile profile) async {
    await _storage.saveHealthProfile(profile);
    state = profile;
  }

  void update(HealthProfile Function(HealthProfile) updater) {
    final updated = updater(state);
    _storage.saveHealthProfile(updated);
    state = updated;
  }
}

final healthProfileProvider =
    StateNotifierProvider<HealthProfileNotifier, HealthProfile>((ref) {
  return HealthProfileNotifier(ref.watch(localStorageProvider));
});

// ── Cycle logs ────────────────────────────────────────────────────────────────

class CycleLogsNotifier extends StateNotifier<List<CycleLog>> {
  final LocalStorageService _storage;

  CycleLogsNotifier(this._storage) : super(_storage.getCycleLogs());

  Future<void> addOrUpdate(CycleLog log) async {
    await _storage.saveCycleLog(log);
    state = _storage.getCycleLogs();
  }

  Future<void> delete(String id) async {
    await _storage.deleteCycleLog(id);
    state = _storage.getCycleLogs();
  }
}

final cycleLogsProvider =
    StateNotifierProvider<CycleLogsNotifier, List<CycleLog>>((ref) {
  return CycleLogsNotifier(ref.watch(localStorageProvider));
});

// ── Pregnancy profile ─────────────────────────────────────────────────────────

class PregnancyProfileNotifier extends StateNotifier<PregnancyProfile?> {
  final LocalStorageService _storage;

  PregnancyProfileNotifier(this._storage)
      : super(_storage.getPregnancyProfile());

  Future<void> save(PregnancyProfile profile) async {
    await _storage.savePregnancyProfile(profile);
    state = profile;
  }

  Future<void> clear() async {
    await _storage.clearPregnancyProfile();
    state = null;
  }
}

final pregnancyProfileProvider =
    StateNotifierProvider<PregnancyProfileNotifier, PregnancyProfile?>((ref) {
  return PregnancyProfileNotifier(ref.watch(localStorageProvider));
});

// ── Pregnancy logs ────────────────────────────────────────────────────────────

class PregnancyLogsNotifier extends StateNotifier<List<PregnancyLog>> {
  final LocalStorageService _storage;

  PregnancyLogsNotifier(this._storage) : super(_storage.getPregnancyLogs());

  Future<void> add(PregnancyLog log) async {
    await _storage.savePregnancyLog(log);
    state = _storage.getPregnancyLogs();
  }
}

final pregnancyLogsProvider =
    StateNotifierProvider<PregnancyLogsNotifier, List<PregnancyLog>>((ref) {
  return PregnancyLogsNotifier(ref.watch(localStorageProvider));
});

// ── Babies ────────────────────────────────────────────────────────────────────

class BabiesNotifier extends StateNotifier<List<BabyProfile>> {
  final LocalStorageService _storage;

  BabiesNotifier(this._storage) : super(_storage.getBabies());

  Future<void> add(BabyProfile baby) async {
    await _storage.saveBaby(baby);
    state = _storage.getBabies();
  }

  Future<void> delete(String id) async {
    await _storage.deleteBaby(id);
    state = _storage.getBabies();
  }
}

final babiesProvider =
    StateNotifierProvider<BabiesNotifier, List<BabyProfile>>((ref) {
  return BabiesNotifier(ref.watch(localStorageProvider));
});

final babyProfilesProvider = babiesProvider;

// ── Baby logs ─────────────────────────────────────────────────────────────────

class BabyLogsNotifier extends StateNotifier<List<BabyLog>> {
  final LocalStorageService _storage;

  BabyLogsNotifier(this._storage) : super(_storage.getBabyLogs());

  Future<void> add(BabyLog log) async {
    await _storage.saveBabyLog(log);
    state = _storage.getBabyLogs();
  }

  Future<void> addFeed(BabyLog log) => add(log);
  Future<void> addSleep(BabyLog log) => add(log);
  Future<void> addDiaper(BabyLog log) => add(log);
}

extension BabyLogListX on List<BabyLog> {
  List<BabyLog> get feedLogs =>
      where((l) => l.logType == BabyLogType.feeding).toList();
  List<BabyLog> get sleepLogs =>
      where((l) => l.logType == BabyLogType.sleep).toList();
  List<BabyLog> get diaperLogs =>
      where((l) => l.logType == BabyLogType.diaper).toList();
  List<BabyLog> get growthLogs =>
      where((l) => l.logType == BabyLogType.growth).toList();
  List<BabyLog> get milestoneLogs =>
      where((l) => l.logType == BabyLogType.milestone).toList();
}

final babyLogsProvider =
    StateNotifierProvider<BabyLogsNotifier, List<BabyLog>>((ref) {
  return BabyLogsNotifier(ref.watch(localStorageProvider));
});

// ── Cart ──────────────────────────────────────────────────────────────────────

class CartNotifier extends StateNotifier<List<CartItem>> {
  final LocalStorageService _storage;

  CartNotifier(this._storage) : super(_storage.getCartItems());

  Future<void> setItem(String productId, int quantity) async {
    final items = List<CartItem>.from(state);
    final idx = items.indexWhere((i) => i.productId == productId);
    if (quantity <= 0) {
      if (idx >= 0) items.removeAt(idx);
    } else if (idx >= 0) {
      items[idx] = items[idx].copyWith(quantity: quantity);
    } else {
      items.add(CartItem(productId: productId, quantity: quantity));
    }
    await _storage.saveCartItems(items);
    state = items;
  }

  Future<void> removeItem(String productId) async {
    final items = List<CartItem>.from(state)
      ..removeWhere((i) => i.productId == productId);
    await _storage.saveCartItems(items);
    state = items;
  }

  Future<void> clearCart() async {
    await _storage.saveCartItems([]);
    state = [];
  }

  int countForProduct(String productId) {
    final item = state.where((i) => i.productId == productId).toList();
    return item.isEmpty ? 0 : item.first.quantity;
  }

  double subtotal(List<Product> catalog) {
    double total = 0;
    for (final item in state) {
      final product = catalog.where((p) => p.id == item.productId).toList();
      if (product.isNotEmpty) {
        total += product.first.priceBdt * item.quantity;
      }
    }
    return total;
  }
}

final cartProvider =
    StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier(ref.watch(localStorageProvider));
});

/// Total items in cart (for badge).
final cartCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).fold(0, (sum, item) => sum + item.quantity);
});

// ── Shop filters ──────────────────────────────────────────────────────────────

class ShopFiltersNotifier extends StateNotifier<ShopFilters> {
  ShopFiltersNotifier() : super(const ShopFilters());

  void setCategory(String category) =>
      state = state.copyWith(category: category);
  void setPriceBand(String band) => state = state.copyWith(priceBand: band);
  void setSearch(String query) => state = state.copyWith(searchQuery: query);
  void clearAll() => state = const ShopFilters();
}

class ShopFilters {
  final String category;
  final String priceBand;
  final String searchQuery;

  const ShopFilters({
    this.category = 'All',
    this.priceBand = 'All prices',
    this.searchQuery = '',
  });

  ShopFilters copyWith({String? category, String? priceBand, String? searchQuery}) =>
      ShopFilters(
        category: category ?? this.category,
        priceBand: priceBand ?? this.priceBand,
        searchQuery: searchQuery ?? this.searchQuery,
      );
}

final shopFiltersProvider =
    StateNotifierProvider<ShopFiltersNotifier, ShopFilters>((ref) {
  return ShopFiltersNotifier();
});

/// Filtered product list derived from catalog and filters.
final filteredProductsProvider = Provider<List<Product>>((ref) {
  final filters = ref.watch(shopFiltersProvider);
  return kSampleProducts.where((p) {
    final matchCat = filters.category == 'All' || p.category == filters.category;
    final matchPrice = priceInBand(p.priceBdt, filters.priceBand);
    final q = filters.searchQuery.toLowerCase();
    final matchSearch = q.isEmpty ||
        p.title.toLowerCase().contains(q) ||
        p.category.toLowerCase().contains(q) ||
        p.description.toLowerCase().contains(q) ||
        p.tags.any((t) => t.toLowerCase().contains(q));
    return matchCat && matchPrice && matchSearch;
  }).toList();
});

// ── Selected baby ─────────────────────────────────────────────────────────────

final selectedBabyIdProvider = StateProvider<String?>((ref) => null);

