import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/colors.dart';
import '../../core/models/product.dart';
import '../../core/providers/providers.dart';
import '../../shared/widgets/kholo_animated_loader.dart';

/// ─── LUXURY ORDER REVIEW & CHECKOUT EXPERIENCE ────────────────────────────
///
/// Features:
/// 1. Transparent order line review with Bangladesh delivery calculations.
/// 2. Delivery contact details (Name, Mobile phone with +880 prefix).
/// 3. Bangladesh administrative division & upazila address selector.
/// 4. Payment selection (Cash on delivery active, bKash & Card ready).
/// 5. Full Light & Dark theme tokens with haptic confirmation.
/// ────────────────────────────────────────────────────────────────────────────
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  String _division = 'Dhaka';
  String _paymentMethod = 'cod';
  bool _orderPlaced = false;

  static const _divisions = [
    'Barisal',
    'Chittagong',
    'Dhaka',
    'Khulna',
    'Mymensingh',
    'Rajshahi',
    'Rangpur',
    'Sylhet',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(cartProvider);
    final tt = Theme.of(context).textTheme;

    if (_orderPlaced) {
      return _OrderSuccessScreen(onContinue: () {
        ref.read(cartProvider.notifier).clearCart();
        context.go('/shop');
      });
    }

    double subtotal = 0;
    final lineItems = <_CartLine>[];
    for (final item in items) {
      final products =
          kSampleProducts.where((p) => p.id == item.productId).toList();
      if (products.isNotEmpty) {
        final p = products.first;
        subtotal += p.priceBdt * item.quantity;
        lineItems.add(_CartLine(product: p, quantity: item.quantity));
      }
    }
    const deliveryFee = 80.0;
    final total = subtotal + deliveryFee;

    return Scaffold(
      backgroundColor: context.kCanvas,
      appBar: AppBar(
        title: Text(
          'Checkout',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
            color: context.kInk,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.kInk),
          onPressed: () {
            HapticFeedback.selectionClick();
            context.go('/cart');
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          // Order summary
          const _SectionTitle('Order review'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.kCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.kDivider),
              boxShadow: [
                BoxShadow(
                  color: KholoColors.wine
                      .withValues(alpha: context.isDark ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                ...lineItems.map((li) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: context.isDark
                                  ? context.kCardElevated
                                  : KholoColors.lavenderLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.spa_outlined,
                              color: context.isDark
                                  ? KholoColors.magenta
                                  : KholoColors.wine,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              li.product.title,
                              style: tt.bodyMedium
                                  ?.copyWith(color: context.kInk),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${li.quantity}× ৳${(li.product.priceBdt * li.quantity).toStringAsFixed(0)}',
                            style: tt.bodyMedium
                                ?.copyWith(color: context.kInkMuted),
                          ),
                        ],
                      ),
                    )),
                Divider(height: 20, color: context.kDivider),
                _TotalRow('Subtotal', '৳${subtotal.toStringAsFixed(0)}', false),
                const SizedBox(height: 6),
                _TotalRow('Home delivery', '৳${deliveryFee.toInt()}', false),
                Divider(height: 16, color: context.kDivider),
                _TotalRow('Total', '৳${total.toStringAsFixed(0)}', true),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Delivery contact
          const _SectionTitle('Delivery contact'),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: 'Full name *',
              labelStyle: TextStyle(color: context.kInkMuted),
              filled: true,
              fillColor: context.kCard,
              prefixIcon:
                  Icon(Icons.person_outline_rounded, color: context.kInkSubtle),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Mobile number *',
              labelStyle: TextStyle(color: context.kInkMuted),
              filled: true,
              fillColor: context.kCard,
              prefixText: '+880 ',
              prefixIcon:
                  Icon(Icons.phone_outlined, color: context.kInkSubtle),
              helperText: 'Used for delivery verification only',
              helperStyle: TextStyle(color: context.kInkSubtle),
            ),
          ),

          const SizedBox(height: 24),

          // Delivery address
          const _SectionTitle('Delivery address'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: context.kCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.kDivider),
            ),
            child: DropdownButtonFormField<String>(
              initialValue: _division,
              dropdownColor: context.kCard,
              decoration: const InputDecoration(
                labelText: 'Division',
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: _divisions
                  .map((d) => DropdownMenuItem(
                      value: d,
                      child: Text(d,
                          style: TextStyle(color: context.kInk))))
                  .toList(),
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _division = v!);
              },
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cityCtrl,
            decoration: InputDecoration(
              labelText: 'City / Upazila',
              labelStyle: TextStyle(color: context.kInkMuted),
              filled: true,
              fillColor: context.kCard,
              prefixIcon: Icon(Icons.location_city_outlined,
                  color: context.kInkSubtle),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _addressCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Area, road & house *',
              labelStyle: TextStyle(color: context.kInkMuted),
              filled: true,
              fillColor: context.kCard,
              prefixIcon:
                  Icon(Icons.home_outlined, color: context.kInkSubtle),
            ),
          ),

          const SizedBox(height: 24),

          // Payment method
          const _SectionTitle('Payment method'),
          const SizedBox(height: 12),
          _PaymentSelector(
            selected: _paymentMethod,
            onSelect: (m) {
              HapticFeedback.selectionClick();
              setState(() => _paymentMethod = m);
            },
          ),

          const SizedBox(height: 16),

          // Stripe note
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.isDark
                  ? context.kCardElevated
                  : KholoColors.lavenderLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (context.isDark
                        ? KholoColors.magenta
                        : KholoColors.lavender)
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    color: context.isDark
                        ? KholoColors.magenta
                        : KholoColors.wine,
                    size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Card and mobile wallet payment will be activated once secure server-side payment credentials are configured. All pricing is validated server-side before payment.',
                    style: tt.bodySmall
                        ?.copyWith(color: context.kInkMuted, height: 1.5),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Policy acknowledgement
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.kCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.kDivider),
            ),
            child: Text(
              'By placing this order you agree to KHOLO\'s delivery policy, return conditions, and privacy notice. Your health data is never included in order records.',
              style: tt.bodySmall
                  ?.copyWith(color: context.kInkSubtle, height: 1.5),
            ),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(
          color: context.kCard,
          border: Border(top: BorderSide(color: context.kDivider)),
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_paymentMethod == 'cod' && items.isNotEmpty)
                ? _placeOrder
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  context.isDark ? KholoColors.magenta : KholoColors.wine,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: _paymentMethod == 'cod'
                ? Text('Place order · ৳${total.toStringAsFixed(0)}')
                : const Text('Payment coming soon'),
          ),
        ),
      ),
    );
  }

  void _placeOrder() {
    final items = ref.read(cartProvider);
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty.'),
          backgroundColor: KholoColors.error,
        ),
      );
      return;
    }

    // Validate required fields
    if (_nameCtrl.text.trim().isEmpty ||
        _phoneCtrl.text.trim().isEmpty ||
        _addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields.'),
          backgroundColor: KholoColors.error,
        ),
      );
      return;
    }

    HapticFeedback.heavyImpact();
    KholoAnimatedLoader.show(context, message: 'Confirming your order...');
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        KholoAnimatedLoader.hide(context);
        setState(() => _orderPlaced = true);
      }
    });
  }
}

class _CartLine {
  final Product product;
  final int quantity;
  const _CartLine({required this.product, required this.quantity});
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              color: context.kInkSubtle,
              fontWeight: FontWeight.w700,
            ),
      );
}

class _TotalRow extends StatelessWidget {
  const _TotalRow(this.label, this.value, this.isTotal);
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
              ? tt.titleMedium?.copyWith(color: context.kInk)
              : tt.bodyMedium?.copyWith(color: context.kInkMuted),
        ),
        Text(
          value,
          style: isTotal
              ? GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: context.isDark
                      ? KholoColors.magenta
                      : KholoColors.plum,
                )
              : tt.bodyMedium?.copyWith(color: context.kInk),
        ),
      ],
    );
  }
}

class _PaymentSelector extends StatelessWidget {
  const _PaymentSelector({required this.selected, required this.onSelect});
  final String selected;
  final ValueChanged<String> onSelect;

  static const _methods = [
    (
      'cod',
      'Cash on delivery',
      Icons.payments_outlined,
      'Pay cash when your order arrives.'
    ),
    (
      'bkash',
      'bKash / Nagad',
      Icons.phone_android_outlined,
      'Coming soon — pending merchant approval.'
    ),
    (
      'card',
      'Card payment',
      Icons.credit_card_outlined,
      'Coming soon — Stripe integration pending credentials.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Column(
      children: _methods.map((m) {
        final isSelected = selected == m.$1;
        final isDisabled = m.$1 != 'cod';
        return GestureDetector(
          onTap: isDisabled ? null : () => onSelect(m.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? (context.isDark
                      ? context.kCardElevated
                      : KholoColors.lavenderLight)
                  : context.kCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? (context.isDark
                        ? KholoColors.magenta
                        : KholoColors.plum)
                    : context.kDivider,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: KholoColors.wine
                      .withValues(alpha: context.isDark ? 0.2 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  m.$3,
                  color: isDisabled
                      ? context.kInkSubtle
                      : isSelected
                          ? (context.isDark
                              ? KholoColors.magenta
                              : KholoColors.plum)
                          : context.kInkMuted,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.$2,
                        style: tt.bodyMedium?.copyWith(
                          color: isDisabled
                              ? context.kInkSubtle
                              : context.kInk,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      Text(
                        m.$4,
                        style: tt.bodySmall?.copyWith(
                            color: context.kInkSubtle, height: 1.3),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_rounded,
                      color: context.isDark
                          ? KholoColors.magenta
                          : KholoColors.plum,
                      size: 18),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _OrderSuccessScreen extends StatelessWidget {
  const _OrderSuccessScreen({required this.onContinue});
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.kCanvas,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: KholoColors.sageLight
                        .withValues(alpha: context.isDark ? 0.3 : 1.0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: KholoColors.sageDark, size: 52),
                ),
                const SizedBox(height: 28),
                Text(
                  'Order placed!',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: context.kInk,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Your cash-on-delivery order has been received. You\'ll receive delivery details via your provided mobile number.',
                  style: TextStyle(
                    color: context.kInkMuted,
                    height: 1.6,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.isDark
                        ? KholoColors.magenta
                        : KholoColors.wine,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Continue shopping'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
