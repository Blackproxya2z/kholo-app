import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/providers.dart';
import '../features/landing/landing_screen.dart';
import '../features/auth/auth_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/today/today_screen.dart';
import '../features/cycle/cycle_screen.dart';
import '../features/insights/insights_screen.dart';
import '../features/pregnancy/pregnancy_screen.dart';
import '../features/baby/baby_screen.dart';
import '../features/shop/shop_screen.dart';
import '../features/product/product_detail_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/checkout/checkout_screen.dart';
import '../features/profile/profile_screen.dart';
import '../shared/widgets/kholo_bottom_nav.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = auth != null;
      final path = state.uri.path;
      final isPublic = path == '/' || path == '/auth' || path == '/onboarding';

      if (!isLoggedIn && !isPublic) return '/';
      if (isLoggedIn && path == '/') return '/app';
      return null;
    },
    routes: [
      // ── Public routes ───────────────────────────────────────────────────
      GoRoute(
        path: '/',
        pageBuilder: (context, state) =>
            _fade(state, const LandingScreen()),
      ),
      GoRoute(
        path: '/auth',
        pageBuilder: (context, state) =>
            _fade(state, const AuthScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) =>
            _fade(state, const OnboardingScreen()),
      ),

      // ── Authenticated shell with bottom nav ─────────────────────────────
      ShellRoute(
        builder: (context, state, child) =>
            KholoBottomNav(child: child),
        routes: [
          GoRoute(
            path: '/app',
            pageBuilder: (context, state) =>
                _slide(state, const TodayScreen()),
          ),
          GoRoute(
            path: '/cycle',
            pageBuilder: (context, state) =>
                _slide(state, const CycleScreen()),
          ),
          GoRoute(
            path: '/insights',
            pageBuilder: (context, state) =>
                _slide(state, const InsightsScreen()),
          ),
          GoRoute(
            path: '/pregnancy',
            pageBuilder: (context, state) =>
                _slide(state, const PregnancyScreen()),
          ),
          GoRoute(
            path: '/baby',
            pageBuilder: (context, state) =>
                _slide(state, const BabyScreen()),
          ),
          GoRoute(
            path: '/shop',
            pageBuilder: (context, state) =>
                _slide(state, const ShopScreen()),
          ),
          GoRoute(
            path: '/shop/:productId',
            pageBuilder: (context, state) {
              final id = state.pathParameters['productId']!;
              return _slide(state, ProductDetailScreen(productId: id));
            },
          ),
          GoRoute(
            path: '/cart',
            pageBuilder: (context, state) =>
                _slide(state, const CartScreen()),
          ),
          GoRoute(
            path: '/checkout',
            pageBuilder: (context, state) =>
                _slide(state, const CheckoutScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                _slide(state, const ProfileScreen()),
          ),
        ],
      ),
    ],
  );
});

CustomTransitionPage<void> _fade(GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    );

CustomTransitionPage<void> _slide(GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.05, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
        child: FadeTransition(opacity: anim, child: child),
      ),
    );
