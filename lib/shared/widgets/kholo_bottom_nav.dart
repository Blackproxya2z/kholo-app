import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';

/// Persistent bottom navigation bar for KHOLO mobile experience.
class KholoBottomNav extends ConsumerWidget {
  const KholoBottomNav({super.key, required this.child});
  final Widget child;

  static const _routes = ['/app', '/cycle', '/baby', '/shop', '/profile'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartCountProvider);
    final location = GoRouterState.of(context).uri.path;
    int currentIndex = 0;
    for (int i = 0; i < _routes.length; i++) {
      if (location.startsWith(_routes[i])) {
        currentIndex = i;
        break;
      }
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: _KholoNavBar(
        currentIndex: currentIndex,
        cartCount: cartCount,
        onTap: (index) {
          context.go(_routes[index]);
        },
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
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: KholoColors.divider, width: 1)),
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
    final color = isActive ? KholoColors.wine : KholoColors.inkSubtle;

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
                            color: KholoColors.blush.withValues(alpha: 0.4),
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
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
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
