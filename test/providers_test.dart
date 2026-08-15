import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kholo/core/services/local_storage_service.dart';
import 'package:kholo/core/providers/providers.dart';
import 'package:kholo/core/models/health_profile.dart';
import 'package:kholo/core/models/product.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Providers & LocalStorageService Tests', () {
    late LocalStorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storage = LocalStorageService(prefs);
    });

    test('AuthNotifier saves and clears user', () async {
      final notifier = AuthNotifier(storage);
      expect(notifier.state, isNull);

      await notifier.signIn('user@kholo.app');
      expect(notifier.state, 'user@kholo.app');
      expect(storage.getAuthUser(), 'user@kholo.app');

      await notifier.signOut();
      expect(notifier.state, isNull);
      expect(storage.getAuthUser(), isNull);
    });

    test('HealthProfileNotifier saves and updates profile', () async {
      final notifier = HealthProfileNotifier(storage);
      expect(notifier.state.cycleLength, 28);

      await notifier.save(const HealthProfile(cycleLength: 32, periodLength: 6));
      expect(notifier.state.cycleLength, 32);
      expect(notifier.state.periodLength, 6);

      notifier.update((p) => p.copyWith(periodLength: 5));
      expect(notifier.state.periodLength, 5);
    });

    test('CartNotifier handles item add, update, remove, and subtotal', () async {
      final cart = CartNotifier(storage);
      expect(cart.state, isEmpty);

      // Add item 1 with qty 2
      await cart.setItem('p001', 2);
      expect(cart.state.length, 1);
      expect(cart.countForProduct('p001'), 2);

      // Add item 2 with qty 1
      await cart.setItem('p002', 1);
      expect(cart.state.length, 2);

      // Calculate subtotal
      final subtotal = cart.subtotal(kSampleProducts);
      final p1Price = kSampleProducts.firstWhere((p) => p.id == 'p001').priceBdt;
      final p2Price = kSampleProducts.firstWhere((p) => p.id == 'p002').priceBdt;
      expect(subtotal, (p1Price * 2) + (p2Price * 1));

      // Setting quantity to 0 removes item
      await cart.setItem('p001', 0);
      expect(cart.state.length, 1);
      expect(cart.countForProduct('p001'), 0);

      // Clear cart
      await cart.clearCart();
      expect(cart.state, isEmpty);
    });

    test('ShopFiltersNotifier filters by category, price, and search text', () {
      final notifier = ShopFiltersNotifier();
      expect(notifier.state.category, 'All');

      notifier.setCategory('Cycle care');
      expect(notifier.state.category, 'Cycle care');

      notifier.setSearch('patch');
      expect(notifier.state.searchQuery, 'patch');

      notifier.clearAll();
      expect(notifier.state.category, 'All');
      expect(notifier.state.searchQuery, isEmpty);
    });
  });
}
