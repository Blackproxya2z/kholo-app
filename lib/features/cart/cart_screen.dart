import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/colors.dart';
import '../../core/models/product.dart';
import '../../core/providers/providers.dart';

/// Cart screen — line items, quantity controls, subtotal.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);
    final tt = Theme.of(context).textTheme;

    double subtotal = 0;
    final lineItems = <_LineItem>[];
    for (final item in items) {
      final products = kSampleProducts.where((p) => p.id == item.productId).toList();
      if (products.isNotEmpty) {
        final p = products.first;
        subtotal += p.priceBdt * item.quantity;
        lineItems.add(_LineItem(product: p, quantity: item.quantity));
      }
    }

    return Scaffold(
      backgroundColor: KholoColors.canvas,
      appBar: AppBar(
        title: const Text('My cart'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/shop'),
        ),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(cartProvider.notifier).clearCart(),
              child: const Text('Clear', style: TextStyle(color: KholoColors.error)),
            ),
        ],
      ),
      body: items.isEmpty
          ? _EmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    children: [
                      ...lineItems.map((li) => _CartLineItem(
                            item: li,
                            onQuantityChanged: (q) => ref
                                .read(cartProvider.notifier)
                                .setItem(li.product.id, q),
                            onRemove: () => ref
                                .read(cartProvider.notifier)
                                .removeItem(li.product.id),
                          )),
                      const SizedBox(height: 16),
                      // Subtotal
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: KholoColors.cream,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: KholoColors.divider),
                        ),
                        child: Column(
                          children: [
                            _SummaryRow('Subtotal',
                                '৳${subtotal.toStringAsFixed(0)}', false),
                            const Divider(height: 20),
                            const _SummaryRow(
                                'Delivery', 'Calculated at checkout', false),
                            const Divider(height: 20),
                            _SummaryRow(
                                'Total (estimated)',
                                '৳${subtotal.toStringAsFixed(0)}+',
                                true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: KholoColors.lavenderLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'All prices are in Bangladeshi Taka (৳ BDT). Final price including delivery will be confirmed at checkout.',
                          style: tt.bodySmall
                              ?.copyWith(color: KholoColors.inkMuted, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
                // Checkout CTA
                Container(
                  padding: EdgeInsets.fromLTRB(
                      20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: KholoColors.divider)),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.go('/checkout'),
                      child: Text(
                          'Continue to checkout · ৳${subtotal.toStringAsFixed(0)}'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _LineItem {
  final Product product;
  final int quantity;
  const _LineItem({required this.product, required this.quantity});
}

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_bag_outlined,
                color: KholoColors.inkSubtle, size: 56),
            const SizedBox(height: 20),
            Text('Your cart is empty', style: tt.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Browse care essentials in the shop.',
              style: tt.bodyMedium?.copyWith(color: KholoColors.inkMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/shop'),
              child: const Text('Explore the shop'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartLineItem extends StatelessWidget {
  const _CartLineItem({
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  final _LineItem item;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final lineTotal = item.product.priceBdt * item.quantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KholoColors.cream,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: KholoColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: KholoColors.lavenderLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.spa_outlined, color: KholoColors.wine, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.title,
                    style: tt.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('৳${item.product.priceBdt.toInt()} each',
                    style: tt.bodySmall?.copyWith(color: KholoColors.inkMuted)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _SmallBtn(
                        icon: Icons.remove_rounded,
                        onTap: item.quantity > 1
                            ? () => onQuantityChanged(item.quantity - 1)
                            : onRemove),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('${item.quantity}',
                          style: tt.titleMedium?.copyWith(color: KholoColors.plum)),
                    ),
                    _SmallBtn(
                        icon: Icons.add_rounded,
                        onTap: () => onQuantityChanged(item.quantity + 1)),
                    const Spacer(),
                    Text(
                      '৳${lineTotal.toStringAsFixed(0)}',
                      style: tt.titleMedium?.copyWith(color: KholoColors.ink),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            color: KholoColors.inkSubtle,
            onPressed: onRemove,
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }
}

class _SmallBtn extends StatelessWidget {
  const _SmallBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: KholoColors.lavenderLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: KholoColors.plum),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value, this.isTotal);
  final String label;
  final String value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? tt.titleMedium
              : tt.bodyMedium?.copyWith(color: KholoColors.inkMuted),
        ),
        Text(
          value,
          style: isTotal
              ? tt.titleMedium?.copyWith(color: KholoColors.plum)
              : tt.bodyMedium,
        ),
      ],
    );
  }
}
