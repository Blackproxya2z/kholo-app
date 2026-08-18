import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';

/// ─── PROFESSIONAL BOTTOM NAVIGATION & BACK BUTTON ARCHITECTURE ─────────────
///
/// Features:
/// 1. Sub-screen back navigation: Returning to previous section/dashboard.
/// 2. Double-back-press confirmation on main dashboard ('Press back again to exit KHOLO').
/// 3. Overlay / bottom-sheet / modal dismissal priority.
/// 4. Scroll position and state preservation with PageStorageBucket.
/// ────────────────────────────────────────────────────────────────────────────
class KholoBottomNav extends ConsumerStatefulWidget {
  const KholoBottomNav({super.key, required this.child});
  final Widget child;

  static const _routes = ['/app', '/cycle', '/baby', '/shop', '/profile'];

  @override
  ConsumerState<KholoBottomNav> createState() => _KholoBottomNavState();
}

class _KholoBottomNavState extends ConsumerState<KholoBottomNav> {
  final PageStorageBucket _bucket = PageStorageBucket();
  DateTime? _lastBackPressTime;

  @override
  Widget build(BuildContext context) {
    final cartCount = ref.watch(cartCountProvider);
    final location = GoRouterState.of(context).uri.path;

    int currentIndex = 0;
    for (int i = 0; i < KholoBottomNav._routes.length; i++) {
      if (location == KholoBottomNav._routes[i] ||
          (location.startsWith(KholoBottomNav._routes[i]) &&
              KholoBottomNav._routes[i] != '/app')) {
        currentIndex = i;
        break;
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // 1. Overlay & modal sheet check (close overlay first)
        final nav = Navigator.maybeOf(context);
        if (nav != null && nav.canPop()) {
          nav.pop();
          return;
        }

        // 2. Route evaluation
        final currentPath = GoRouterState.of(context).uri.path;

        if (currentPath == '/app') {
          // On Home Dashboard -> Require 2-press confirmation
          final now = DateTime.now();
          if (_lastBackPressTime == null ||
              now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
            _lastBackPressTime = now;
            HapticFeedback.selectionClick();

            ScaffoldMessenger.of(context).removeCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'Press back again to exit KHOLO',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                backgroundColor: KholoColors.wine,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                duration: const Duration(seconds: 2),
              ),
            );
          } else {
            // Second back press within 2s -> Cleanly exit app
            ScaffoldMessenger.of(context).removeCurrentSnackBar();
            await SystemNavigator.pop();
          }
        } else {
          // On Secondary Screen -> Smoothly navigate back
          HapticFeedback.selectionClick();
          if (currentPath.startsWith('/shop/') ||
              currentPath == '/cart' ||
              currentPath == '/checkout') {
            context.go('/shop');
          } else {
            context.go('/app');
          }
        }
      },
      child: Scaffold(
        body: PageStorage(
          bucket: _bucket,
          child: widget.child,
        ),
        bottomNavigationBar: _KholoNavBar(
          currentIndex: currentIndex,
          cartCount: cartCount,
          onTap: (index) {
            HapticFeedback.selectionClick();
            context.go(KholoBottomNav._routes[index]);
          },
        ),
      ),
    );
  }
}

class _KholoNavBar extends StatelessWidget {
  const _KholoNavBar({
    required this.currentIndex,
    required this.cartCount,
    required this.onTap,
  });

  final int currentIndex;
  final int cartCount;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.kSurface,
        border: Border(top: BorderSide(color: context.kDivider, width: 1)),
        boxShadow: [
          BoxShadow(
            color: context.isDark
                ? Colors.black.withValues(alpha: 0.4)
                : KholoColors.wine.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.today_outlined,
                activeIcon: Icons.today_rounded,
                label: 'Today',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.calendar_month_outlined,
                activeIcon: Icons.calendar_month_rounded,
                label: 'Cycle',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.child_care_outlined,
                activeIcon: Icons.child_care_rounded,
                label: 'Baby',
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.storefront_outlined,
                activeIcon: Icons.storefront_rounded,
                label: 'Shop',
                isActive: currentIndex == 3,
                badge: cartCount > 0 ? cartCount.toString() : null,
                onTap: () => onTap(3),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                isActive: currentIndex == 4,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? (context.isDark ? KholoColors.magenta : KholoColors.wine)
        : context.kInkSubtle;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Semantics(
          label: label,
          selected: isActive,
          button: true,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: isActive
                        ? BoxDecoration(
                            color: context.kTint(KholoColors.magenta,
                                lightAlpha: 0.18, darkAlpha: 0.32),
                            borderRadius: BorderRadius.circular(20),
                          )
                        : null,
                    child: Icon(
                      isActive ? activeIcon : icon,
                      color: color,
                      size: 22,
                      semanticLabel: label,
                    ),
                  ),
                  if (badge != null)
                    Positioned(
                      top: -4,
                      right: -2,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: KholoColors.rose,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
