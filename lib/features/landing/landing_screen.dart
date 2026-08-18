import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/colors.dart';
import '../../core/models/app_update.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/update_service.dart';
import '../../shared/widgets/kholo_glowing_logo.dart';
import '../../shared/widgets/update_banner.dart';

/// ─── KHOLO LUXURY EMOTIONAL LANDING & SPLASH EXPERIENCE ───────────────────
///
/// Features:
/// 1. Blooming glowing logo with dynamic star sparkles.
/// 2. Shifting chromatic radiance orb with luxury gradients.
/// 3. In-App live update banner with SHA-256 verification status.
/// 4. Responsive mobile & wide desktop-tablet layout.
/// 5. Full light & dark luxury mode support.
/// ────────────────────────────────────────────────────────────────────────────
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _orbCtrl;
  late final Animation<Alignment> _orbAlign;
  AppUpdate? _pendingUpdate;
  int _currentVersionCode = 20;

  @override
  void initState() {
    super.initState();
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _orbAlign = AlignmentTween(
      begin: const Alignment(-0.6, -0.8),
      end: const Alignment(0.6, 0.2),
    ).animate(CurvedAnimation(parent: _orbCtrl, curve: Curves.easeInOut));

    NotificationService.requestPermission();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    final code = await UpdateService.currentVersionCode();
    final name = await UpdateService.currentVersionName();
    final update = await UpdateService.checkForUpdate();
    if (mounted && update != null && update.isNewerThan(code, name)) {
      setState(() {
        _currentVersionCode = code;
        _pendingUpdate = update;
      });

      final shouldNotify =
          await UpdateService.shouldShowUpdateNotification(
        update.versionCode,
        remoteVersionName: update.latestVersion,
      );
      if (shouldNotify) {
        await NotificationService.showUpdateNotification(
          version: update.latestVersion,
          versionCode: update.versionCode,
          releaseNotes: update.releaseNotes,
        );
        await UpdateService.recordNotificationSent(update.versionCode);
      }
    }
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 768;

    return Scaffold(
      backgroundColor: context.kCanvas,
      body: Stack(
        children: [
          // Shifting colour orb background
          AnimatedBuilder(
            animation: _orbAlign,
            builder: (_, __) => Align(
              alignment: _orbAlign.value,
              child: Container(
                width: size.width * 0.8,
                height: size.width * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      KholoColors.magenta.withValues(
                          alpha: context.isDark ? 0.22 : 0.14),
                      KholoColors.blush.withValues(
                          alpha: context.isDark ? 0.16 : 0.20),
                      KholoColors.warmGold.withValues(
                          alpha: context.isDark ? 0.10 : 0.12),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.4, 0.7, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: isWide
                ? _WideLayout(onGetStarted: _goAuth, onShop: _goShop)
                : _NarrowLayout(
                    onGetStarted: _goAuth,
                    onShop: _goShop,
                    pendingUpdate: _pendingUpdate,
                    currentVersionCode: _currentVersionCode,
                    onDismissUpdate: () =>
                        setState(() => _pendingUpdate = null),
                  ),
          ),
        ],
      ),
    );
  }

  void _goAuth() {
    HapticFeedback.selectionClick();
    context.go('/auth');
  }

  void _goShop() {
    HapticFeedback.selectionClick();
    context.go('/auth');
  }
}

// ── Narrow / mobile layout ────────────────────────────────────────────────────

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({
    required this.onGetStarted,
    required this.onShop,
    this.pendingUpdate,
    this.currentVersionCode = 20,
    this.onDismissUpdate,
  });
  final VoidCallback onGetStarted;
  final VoidCallback onShop;
  final AppUpdate? pendingUpdate;
  final int currentVersionCode;
  final VoidCallback? onDismissUpdate;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pendingUpdate != null) ...[
            const SizedBox(height: 12),
            UpdateBanner(
              update: pendingUpdate!,
              currentVersionCode: currentVersionCode,
              onDismiss: onDismissUpdate ?? () {},
            ),
          ],
          const SizedBox(height: 24),
          // Wordmark
          _KholoWordmark(),
          const SizedBox(height: 28),

          // Glowing Blooming Hero Logo
          const Center(
            child: KholoGlowingLogo(
              size: 96,
              showSparkles: true,
              showHalo: true,
            ),
          ),
          const SizedBox(height: 32),

          // Hero headline
          Text(
            'One calm home\nfor body, baby,\nand everyday care.',
            style: GoogleFonts.playfairDisplay(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: context.kInk,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Track your cycle, support your pregnancy, log your baby\'s growth, and discover curated care essentials — all in one trusted space.',
            style: tt.bodyMedium?.copyWith(
              color: context.kInkMuted,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),

          // Floating phase preview card
          _FloatingPhasePreview(),
          const SizedBox(height: 36),

          // CTAs
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onGetStarted,
              child: const Text('Create your private space'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onShop,
              child: const Text('Explore the shop'),
            ),
          ),
          const SizedBox(height: 48),

          // Feature pillars
          const _FeaturePillars(),
          const SizedBox(height: 40),

          // Health disclaimer
          const _Disclaimer(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
            child: Center(
              child: Text(
                'Developed by Azmain • KHOLO Luxury Health',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w500,
                  color: context.kInkSubtle.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Wide / tablet-desktop layout ─────────────────────────────────────────────

class _WideLayout extends StatelessWidget {
  const _WideLayout({required this.onGetStarted, required this.onShop});
  final VoidCallback onGetStarted;
  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column — copy & CTAs
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _KholoWordmark(),
                  const SizedBox(height: 48),
                  Text(
                    'One calm home for body, baby, and everyday care.',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: context.kInk,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Track your cycle, support your pregnancy, log baby milestones, and discover curated care essentials — all in one trusted, private space.',
                    style: tt.bodyLarge?.copyWith(
                      color: context.kInkMuted,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      ElevatedButton(
                        onPressed: onGetStarted,
                        child: const Text('Create your private space'),
                      ),
                      OutlinedButton(
                        onPressed: onShop,
                        child: const Text('Explore the shop'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  const _FeaturePillars(),
                  const SizedBox(height: 32),
                  const _Disclaimer(),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
                    child: Text(
                      'Developed by Azmain • KHOLO Luxury Health',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w500,
                        color: context.kInkSubtle.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 32),

            // Right column — phase preview card
            SizedBox(
              width: 340,
              child: _FloatingPhasePreview(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared components ─────────────────────────────────────────────────────────

class _KholoWordmark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: KholoColors.plum,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              'K',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'KHOLO',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: context.kInk,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class _FloatingPhasePreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.isDark ? context.kCardElevated : KholoColors.lavenderLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (context.isDark ? KholoColors.magenta : KholoColors.lavender)
              .withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: KholoColors.wine
                .withValues(alpha: context.isDark ? 0.25 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: KholoColors.blush.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_florist_outlined,
                    color: KholoColors.wine, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Follicular phase',
                      style: tt.titleLarge?.copyWith(color: context.kInk),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Energy may be rising',
                      style: tt.bodySmall?.copyWith(color: context.kInkMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 0.4,
              backgroundColor: KholoColors.blush.withValues(alpha: 0.3),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(KholoColors.magenta),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _PreviewChip('Day 8 of 28', Icons.radio_button_checked),
              _PreviewChip('20d until period', Icons.schedule_outlined),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.kCard.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.kDivider),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_rounded,
                    color: KholoColors.warmGold, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Estimated fertile window starts in 4 days*',
                    style: tt.bodySmall?.copyWith(color: context.kInkMuted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '* Estimates only — not medical advice.',
            style: tt.labelSmall?.copyWith(color: context.kInkSubtle),
          ),
        ],
      ),
    );
  }
}

class _PreviewChip extends StatelessWidget {
  const _PreviewChip(this.label, this.icon);
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: context.kCard.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.kDivider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 11,
              color: context.isDark ? KholoColors.magenta : KholoColors.wine),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: context.kInkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturePillars extends StatelessWidget {
  const _FeaturePillars();

  static const _pillars = [
    (Icons.water_drop_outlined, 'Cycle tracking', 'Phase-aware calendar and insights'),
    (Icons.child_friendly_outlined, 'Baby care', 'Feeding, sleep, and milestone logs'),
    (Icons.storefront_outlined, 'Care shop', 'Curated essentials, no fake reviews'),
    (Icons.lock_outline_rounded, 'Private by default', 'Your data stays yours'),
  ];

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      children: _pillars.map((p) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.isDark
                      ? context.kCardElevated
                      : KholoColors.lavenderLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  p.$1,
                  color: context.isDark
                      ? KholoColors.magenta
                      : KholoColors.plum,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.$2,
                      style: tt.titleMedium?.copyWith(color: context.kInk),
                    ),
                    Text(
                      p.$3,
                      style: tt.bodySmall?.copyWith(color: context.kInkMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.isDark ? context.kCardElevated : KholoColors.cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.kDivider),
      ),
      child: Text(
        'KHOLO provides self-tracking, estimates, and educational content. It does not diagnose medical conditions or replace clinical care. All cycle and fertility predictions are estimates.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.kInkSubtle,
              height: 1.5,
            ),
      ),
    );
  }
}
