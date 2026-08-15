import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/colors.dart';
import '../../core/models/product.dart';
import '../../core/providers/providers.dart';

/// Product detail screen with image, info, quantity picker, and add-to-cart.
class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final String productId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final product = kSampleProducts
        .where((p) => p.id == widget.productId)
        .toList();

    if (product.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product')),
        body: const Center(child: Text('Product not found.')),
      );
    }

    final p = product.first;
    final cartCount = ref.watch(cartProvider)
        .where((i) => i.productId == p.id)
        .fold(0, (sum, i) => sum + i.quantity);
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: KholoColors.canvas,
      body: CustomScrollView(
        slivers: [
          // Hero image area
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: KholoColors.lavenderLight,
            foregroundColor: KholoColors.ink,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded, size: 18),
              ),
              onPressed: () => context.go('/shop'),
            ),
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shopping_bag_outlined, size: 18),
                    ),
                    onPressed: () => context.go('/cart'),
                    tooltip: 'View cart',
                  ),
                  if (cartCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: KholoColors.rose,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$cartCount',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: KholoColors.lavenderLight,
                child: Center(
                  child: Icon(
                    _categoryIcon(p.category),
                    color: KholoColors.plum,
                    size: 80,
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: KholoColors.lavenderLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      p.category,
                      style: tt.labelMedium?.copyWith(color: KholoColors.plum),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Title & price
                  Text(p.title, style: tt.displaySmall),
                  const SizedBox(height: 8),
                  Text(
                    '৳${p.priceBdt.toInt()}',
                    style: tt.headlineMedium?.copyWith(color: KholoColors.plum),
                  ),

                  if (!p.isAvailable) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: KholoColors.cream,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: KholoColors.divider),
                      ),
                      child: Text(
                        'Currently unavailable — coming soon',
                        style: tt.bodySmall?.copyWith(color: KholoColors.inkMuted),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Description
                  _InfoSection('About this product', p.description),
                  const SizedBox(height: 20),

                  // Usage
                  _InfoSection('How to use', p.usage),
                  const SizedBox(height: 20),

                  // Ingredients / materials
                  if (p.ingredients.isNotEmpty) ...[
                    Text('Ingredients / materials',
                        style: tt.titleMedium?.copyWith(color: KholoColors.plum)),
                    const SizedBox(height: 8),
                    ...p.ingredients.map((ing) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.circle, size: 6, color: KholoColors.lavender),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(ing,
                                    style: tt.bodySmall
                                        ?.copyWith(color: KholoColors.inkMuted, height: 1.5)),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 20),
                  ],

                  // Tags
                  if (p.tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: p.tags.map((t) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: KholoColors.cream,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: KholoColors.divider),
                            ),
                            child: Text(
                              t,
                              style: tt.labelSmall?.copyWith(color: KholoColors.inkMuted),
                            ),
                          )).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // No reviews disclaimer
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: KholoColors.cream,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: KholoColors.divider),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_outlined,
                            color: KholoColors.plum, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'KHOLO does not display fabricated ratings, reviews, or endorsements.',
                            style: tt.bodySmall
                                ?.copyWith(color: KholoColors.inkMuted, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // Add to cart bottom bar
      bottomNavigationBar: p.isAvailable
          ? _AddToCartBar(
              product: p,
              qty: _qty,
              cartCount: cartCount,
              onQtyChanged: (v) => setState(() => _qty = v),
              onAdd: () {
                ref
                    .read(cartProvider.notifier)
                    .setItem(p.id, cartCount + _qty);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(children: [
                      const Icon(Icons.check_circle_outline,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text('$_qty × "${p.title}" added to cart'),
                    ]),
                    backgroundColor: KholoColors.plum,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    duration: const Duration(seconds: 2),
                    action: SnackBarAction(
                      label: 'View cart',
                      textColor: Colors.white,
                      onPressed: () => context.go('/cart'),
                    ),
                  ),
                );
              },
            )
          : null,
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

class _InfoSection extends StatelessWidget {
  const _InfoSection(this.title, this.body);
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: tt.titleMedium?.copyWith(color: KholoColors.plum)),
        const SizedBox(height: 8),
        Text(body, style: tt.bodyMedium?.copyWith(color: KholoColors.inkMuted, height: 1.6)),
      ],
    );
  }
}

class _AddToCartBar extends StatelessWidget {
  const _AddToCartBar({
    required this.product,
    required this.qty,
    required this.cartCount,
    required this.onQtyChanged,
    required this.onAdd,
  });

  final Product product;
  final int qty;
  final int cartCount;
  final ValueChanged<int> onQtyChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: KholoColors.divider)),
      ),
      child: Row(
        children: [
          // Quantity selector
          Container(
            decoration: BoxDecoration(
              color: KholoColors.cream,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: KholoColors.divider),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_rounded, size: 18),
                  onPressed: qty > 1 ? () => onQtyChanged(qty - 1) : null,
                  color: KholoColors.plum,
                ),
                Text('$qty',
                    style: tt.titleMedium?.copyWith(color: KholoColors.plum)),
                IconButton(
                  icon: const Icon(Icons.add_rounded, size: 18),
                  onPressed: () => onQtyChanged(qty + 1),
                  color: KholoColors.plum,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: onAdd,
              child: Text(
                cartCount > 0
                    ? 'Add ৳${(product.priceBdt * qty).toInt()}'
                    : 'Add to cart · ৳${(product.priceBdt * qty).toInt()}',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
