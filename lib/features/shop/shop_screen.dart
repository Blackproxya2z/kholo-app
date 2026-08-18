import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/colors.dart';
import '../../core/models/product.dart';
import '../../core/providers/providers.dart';

/// Shop screen with search, category filters, and product grid.
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(shopFiltersProvider);
    final products = ref.watch(filteredProductsProvider);
    final cartCount = ref.watch(cartCountProvider);
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: context.kCanvas,
      appBar: AppBar(
        title: Text('Shop', style: TextStyle(color: context.kInk)),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.shopping_bag_outlined, color: context.kInk),
                onPressed: () => context.go('/cart'),
                tooltip: 'View cart',
              ),
              if (cartCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: KholoColors.rose,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$cartCount',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search products…',
                prefixIcon: Icon(Icons.search_rounded, color: context.kInkSubtle),
                suffixIcon: filters.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref.read(shopFiltersProvider.notifier).setSearch('');
                        },
                      )
                    : null,
              ),
              onChanged: (v) =>
                  ref.read(shopFiltersProvider.notifier).setSearch(v),
            ),
          ),

          // Category chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: kProductCategories.map((cat) {
                final isSelected = filters.category == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (_) =>
                        ref.read(shopFiltersProvider.notifier).setCategory(cat),
                    selectedColor: KholoColors.plum,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : context.kInk,
                      fontSize: 13,
                    ),
                    backgroundColor: context.kSurface,
                    side: BorderSide(
                      color: isSelected ? KholoColors.plum : context.kDivider,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Price band filter
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: kPriceBands.map((band) {
                final isSelected = filters.priceBand == band;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(band),
                    selected: isSelected,
                    onSelected: (_) =>
                        ref.read(shopFiltersProvider.notifier).setPriceBand(band),
                    selectedColor: KholoColors.lavenderLight,
                    checkmarkColor: KholoColors.plum,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? (context.isDark ? KholoColors.magenta : KholoColors.plum)
                          : context.kInkMuted,
                    ),
                    backgroundColor: context.kSurface,
                    side: BorderSide(
                      color: isSelected ? KholoColors.lavender : context.kDivider,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${products.length} product${products.length == 1 ? '' : 's'}',
                  style: tt.bodySmall?.copyWith(color: context.kInkMuted),
                ),
                const Spacer(),
                if (filters.category != 'All' || filters.priceBand != 'All prices')
                  TextButton.icon(
                    onPressed: () {
                      ref.read(shopFiltersProvider.notifier).clearAll();
                    },
                    icon: const Icon(Icons.clear, size: 14),
                    label: const Text('Clear filters', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),

          // Product grid
          Expanded(
            child: products.isEmpty
                ? _EmptySearchState(query: filters.searchQuery)
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: products.length,
                    itemBuilder: (ctx, i) => _ProductCard(product: products[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  const _ProductCard({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final cartCount = ref.watch(cartProvider)
        .where((i) => i.productId == product.id)
        .fold(0, (sum, i) => sum + i.quantity);

    return GestureDetector(
      onTap: () => context.go('/shop/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: context.kSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.kDivider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image placeholder
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Container(
                height: 110,
                color: context.kTint(KholoColors.lavender, lightAlpha: 0.2, darkAlpha: 0.25),
                child: Center(
                  child: Icon(
                    _categoryIcon(product.category),
                    color: context.isDark ? KholoColors.magenta : KholoColors.plum,
                    size: 40,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: context.kTint(KholoColors.lavender, lightAlpha: 0.2, darkAlpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      product.category,
                      style: TextStyle(
                          fontSize: 9,
                          color: context.isDark ? KholoColors.magenta : KholoColors.plum,
                          fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.title,
                    style: tt.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '৳${product.priceBdt.toInt()}',
                    style: tt.titleMedium?.copyWith(
                        color: context.isDark ? KholoColors.magenta : KholoColors.plum),
                  ),
                  if (!product.isAvailable)
                    Text('Coming soon',
                        style: tt.labelSmall?.copyWith(color: context.kInkSubtle)),
                ],
              ),
            ),
            const Spacer(),
            if (product.isAvailable)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: cartCount > 0
                    ? _CartCounter(product: product, count: cartCount)
                    : SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: ElevatedButton(
                          onPressed: () {
                            ref
                                .read(cartProvider.notifier)
                                .setItem(product.id, 1);
                            ScaffoldMessenger.of(context)
                              ..clearSnackBars()
                              ..showSnackBar(
                                SnackBar(
                                  content: const Row(children: [
                                    Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
                                    SizedBox(width: 8),
                                    Expanded(child: Text('Added to cart')),
                                  ]),
                                  backgroundColor: KholoColors.plum,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  duration: const Duration(seconds: 2),
                                  action: SnackBarAction(
                                    label: '✕',
                                    textColor: Colors.white,
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                    },
                                  ),
                                ),
                              );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            textStyle: const TextStyle(fontSize: 13),
                          ),
                          child: const Text('Add to cart'),
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Cycle care':
        return Icons.water_drop_outlined;
      case 'Fertility support':
        return Icons.favorite_border_rounded;
      case 'Pregnancy comfort':
        return Icons.child_friendly_outlined;
      case 'Postpartum care':
        return Icons.healing_outlined;
      case 'Newborn essentials':
        return Icons.crib_outlined;
      case 'Baby care':
        return Icons.child_care_outlined;
      default:
        return Icons.spa_outlined;
    }
  }
}

class _CartCounter extends ConsumerWidget {
  const _CartCounter({required this.product, required this.count});
  final Product product;
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        _CounterButton(
          icon: Icons.remove_rounded,
          onTap: () => ref.read(cartProvider.notifier).setItem(product.id, count - 1),
        ),
        Expanded(
          child: Center(
            child: Text(
              '$count',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: context.isDark ? KholoColors.magenta : KholoColors.plum),
            ),
          ),
        ),
        _CounterButton(
          icon: Icons.add_rounded,
          onTap: () => ref.read(cartProvider.notifier).setItem(product.id, count + 1),
        ),
      ],
    );
  }
}

class _CounterButton extends StatelessWidget {
  const _CounterButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: context.kTint(KholoColors.lavender, lightAlpha: 0.2, darkAlpha: 0.25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16,
            color: context.isDark ? KholoColors.magenta : KholoColors.plum),
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, color: context.kInkSubtle, size: 48),
            const SizedBox(height: 16),
            Text(
              query.isNotEmpty
                  ? 'No products found for "$query"'
                  : 'No products match your filters.',
              style: tt.bodyMedium?.copyWith(color: context.kInkMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
