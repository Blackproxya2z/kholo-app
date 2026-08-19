import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/theme/colors.dart';
import '../../core/models/app_update.dart';
import '../../core/models/cycle_log.dart';
import '../../core/models/health_profile.dart';
import '../../core/models/product.dart';
import '../../core/providers/providers.dart';
import '../../core/services/update_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/utils/cycle_engine.dart';
import '../../shared/widgets/phase_card.dart';
import '../../shared/widgets/log_bottom_sheet.dart';
import '../../shared/widgets/update_banner.dart';
import '../../shared/widgets/brand_emotional_avatar.dart';
import '../../core/services/brand_emotional_state_service.dart';
import 'widgets/animated_cycle_ring.dart';
import 'widgets/liquid_flow_animation.dart';
import 'widgets/daily_hormonal_insight_card.dart';
import 'widgets/bloom_today_spotlight_card.dart';

/// Today dashboard — award-winning redesign with:
/// • Dynamic brand emotional connection & breathing avatar
/// • OTA update banner
/// • Gradient greeting hero
/// • Premium action tiles with scale animation
/// • Rich section headers with accent bar
/// • Phase insight card with tailored self-care advice
/// • Daily hormonal insight banner
/// • Cycle phase cards for next cycle
/// • Curated wellness shop highlights
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen>
    with WidgetsBindingObserver {
  AppUpdate? _pendingUpdate;
  int _currentVersionCode = 20;
  BrandEmotionalState _brandState = BrandEmotionalState.active;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initTodayScreen();
  }

  Future<void> _initTodayScreen() async {
    await NotificationService.requestPermission();
    await _checkForUpdate();
    await _initBrandState();
  }

  Future<void> _initBrandState() async {
    final state = await BrandEmotionalStateService.recordAppOpen();
    if (mounted) {
      setState(() => _brandState = state);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForUpdate(showNotification: false);
    }
  }

  Future<void> _checkForUpdate({bool showNotification = true}) async {
    try {
      final currentCode = await UpdateService.currentVersionCode();
      final currentName = await UpdateService.currentVersionName();
      final update = await UpdateService.checkForUpdate();
      if (!mounted) return;

      if (update != null && update.isNewerThan(currentCode, currentName)) {
        final isMandatory = update.isMandatory(currentCode);
        final prefs = await SharedPreferences.getInstance();
        final dismissedCode = prefs.getInt('kholo_dismissed_update_code') ?? 0;
        final isDismissed = !isMandatory && dismissedCode >= update.versionCode;

        if (showNotification) {
          final shouldNotify = await UpdateService.shouldShowUpdateNotification(
            update.versionCode,
            currentInstalledCode: currentCode,
          );
          if (shouldNotify && !isDismissed) {
            await NotificationService.showUpdateNotification(
              version: update.latestVersion,
              versionCode: update.versionCode,
              title: update.updateTitle,
              message: update.updateMessage,
              releaseNotes: update.releaseNotes,
              force: false,
            );
            await UpdateService.recordNotificationSent(update.versionCode);
          }
        }

        if (isMandatory) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.go('/update', extra: {
                'update': update,
                'currentVersionCode': currentCode,
                'currentVersionName': currentName,
              });
            }
          });
        } else {
          setState(() {
            _currentVersionCode = currentCode;
            _pendingUpdate = isDismissed ? null : update;
          });
        }
      } else {
        setState(() {
          _currentVersionCode = currentCode;
          _pendingUpdate = null;
        });
        await NotificationService.cancelUpdateNotification();
      }
    } catch (e) {
      debugPrint('[TodayScreen] _checkForUpdate error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(healthProfileProvider);
    final logs = ref.watch(cycleLogsProvider);
    final tt = Theme.of(context).textTheme;
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good morning ☀️'
        : hour < 17
            ? 'Good afternoon 🌤️'
            : 'Good evening 🌙';

    final phaseCtx = profile.lastPeriodDate != null
        ? CycleEngine.phaseContext(profile)
        : null;

    final latestLog = logs.isNotEmpty ? logs.first : null;

    return Scaffold(
      backgroundColor: context.kCanvas,
      appBar: AppBar(
        backgroundColor: context.kCanvas,
        elevation: 0,
        title: Text(
          'KHOLO',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: context.kInk,
            letterSpacing: 1,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none_rounded, color: context.kInk),
            onPressed: () {},
            tooltip: 'Notifications',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          LogBottomSheet.show(context);
        },
        backgroundColor: KholoColors.wine,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log today',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: RefreshIndicator(
        color: KholoColors.wine,
        onRefresh: () async {
          await _checkForUpdate(showNotification: false);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          children: [
            const SizedBox(height: 8),

            // ── OTA Update Banner ─────────────────────────────────────────
            if (_pendingUpdate != null)
              UpdateBanner(
                update: _pendingUpdate!,
                currentVersionCode: _currentVersionCode,
                onDismiss: () async {
                  final code = _pendingUpdate?.versionCode;
                  setState(() => _pendingUpdate = null);
                  if (code != null) {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setInt('kholo_dismissed_update_code', code);
                  }
                },
              ),

            // ── Greeting Hero ─────────────────────────────────────────────
            _GreetingHero(
              greeting: greeting,
              profile: profile,
              brandState: _brandState,
            ),
            const SizedBox(height: 16),

            // ── AI Skin Doctor Scanner Entry ──────────────────────────────
            _AiSkinScannerBanner(onTap: () => context.go('/skin-scan')),
            const SizedBox(height: 20),

            // ── KHOLO Bloom Health Hub Spotlight ──────────────────────────
            const BloomTodaySpotlightCard(),

            // ── Phase / Cycle Section ─────────────────────────────────────
            if (phaseCtx != null) ...[
              AnimatedCycleRing(
                currentDay: phaseCtx.cycleDay,
                totalDays: phaseCtx.cycleLength,
                phase: phaseCtx.phase,
                phaseName: phaseCtx.phase.displayName,
                phaseDescription: phaseCtx.phase.description,
                onTap: () => context.go('/cycle'),
              ),
              const SizedBox(height: 20),

              // Liquid Flow Card — menstrual phase only
              if (phaseCtx.phase == CyclePhase.menstrual) ...[
                _MenstrualFlowCard(latestLog: latestLog),
                const SizedBox(height: 20),
              ],

              // Hormonal Insight
              DailyHormonalInsightCard(
                phase: phaseCtx.phase,
                cycleDay: phaseCtx.cycleDay,
                isFertile: phaseCtx.isInFertileWindow,
                isOvulation: phaseCtx.phase == CyclePhase.ovulation,
              ),
              const SizedBox(height: 20),

              PhaseCard(
                phase: phaseCtx.phase,
                cycleDay: phaseCtx.cycleDay,
                cycleLength: phaseCtx.cycleLength,
                daysUntilNextPeriod: phaseCtx.daysUntilNextPeriod,
                isInFertileWindow: phaseCtx.isInFertileWindow,
              ),
            ] else ...[
              _SetupPromptCard(onSetup: () => context.go('/onboarding')),
            ],

            const SizedBox(height: 24),

            // ── Life Stage Cards ──────────────────────────────────────────
            _LifeStageCards(profile: profile),

            const SizedBox(height: 24),

            // ── Quick Actions ─────────────────────────────────────────────
            const _PremiumSectionHeader(
              label: 'Quick Actions',
              icon: Icons.flash_on_rounded,
            ),
            const SizedBox(height: 14),
            _QuickActions(profile: profile),

            const SizedBox(height: 24),

            // ── Care Essentials ───────────────────────────────────────────
            const _PremiumSectionHeader(
              label: 'Your Care Essentials',
              icon: Icons.spa_outlined,
            ),
            const SizedBox(height: 14),
            _RecentProducts(),

            const SizedBox(height: 20),

            // Disclaimer
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.kCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.kDivider),
              ),
              child: Text(
                'Phase estimates are based on your logged data and are not medical advice. Contact a qualified clinician for health concerns.',
                style: tt.bodySmall
                    ?.copyWith(color: context.kInkSubtle, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Developed by Azmain',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withValues(alpha: 0.45) ??
                      Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Greeting Hero ─────────────────────────────────────────────────────────────

class _GreetingHero extends StatelessWidget {
  const _GreetingHero({
    required this.greeting,
    required this.profile,
    required this.brandState,
  });

  final String greeting;
  final HealthProfile profile;
  final BrandEmotionalState brandState;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF92003A),
            Color(0xFFBA1C56),
            Color(0xFFF62477),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: KholoColors.wine.withValues(alpha: 0.32),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Dynamic Emotional Avatar
          BrandEmotionalAvatar(
            size: 48,
            state: brandState,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: tt.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  brandState.title,
                  style: tt.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          // Date badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: Column(
              children: [
                Text(
                  '${now.day}',
                  style: tt.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                Text(
                  _month(now.month).substring(0, 3).toUpperCase(),
                  style: tt.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _month(int m) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[(m - 1).clamp(0, 11)];
  }
}

// ── Premium Section Header ────────────────────────────────────────────────────

class _PremiumSectionHeader extends StatelessWidget {
  const _PremiumSectionHeader({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [KholoColors.wine, KholoColors.magenta],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, size: 16, color: KholoColors.wine),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: tt.labelMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: context.kInk,
          ),
        ),
      ],
    );
  }
}

// ── Menstrual Flow Card ───────────────────────────────────────────────────────

class _MenstrualFlowCard extends StatelessWidget {
  const _MenstrualFlowCard({required this.latestLog});
  final CycleLog? latestLog;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: context.kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.kDivider),
        boxShadow: [
          BoxShadow(
            color: context.isDark
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0x0F92003A),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.water_drop_rounded,
                      color: KholoColors.wine, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Active Menstrual Flow',
                    style: tt.titleSmall?.copyWith(
                      color: context.isDark ? KholoColors.blush : KholoColors.wine,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Text(
                latestLog?.flow?.displayName ?? 'Tracking Flow',
                style: tt.labelMedium?.copyWith(
                  color: KholoColors.magenta,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LiquidFlowAnimation(
            flow: latestLog?.flow ?? FlowIntensity.medium,
            height: 70,
          ),
        ],
      ),
    );
  }
}

// ── Setup Prompt Card ─────────────────────────────────────────────────────────

class _SetupPromptCard extends StatefulWidget {
  const _SetupPromptCard({required this.onSetup});
  final VoidCallback onSetup;

  @override
  State<_SetupPromptCard> createState() => _SetupPromptCardState();
}

class _SetupPromptCardState extends State<_SetupPromptCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (_, child) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [KholoColors.blush, KholoColors.tertiaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Color.lerp(
              KholoColors.wine.withValues(alpha: 0.18),
              KholoColors.magenta.withValues(alpha: 0.4),
              _shimmerCtrl.value,
            )!,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: KholoColors.blush.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome_rounded,
              color: KholoColors.wine, size: 32),
          const SizedBox(height: 12),
          Text('Personalise your dashboard',
              style: tt.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Add a few details to see your current phase, fertile window estimate, and personalised insights.',
            style:
                tt.bodyMedium?.copyWith(color: KholoColors.inkMuted, height: 1.5),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: widget.onSetup,
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: const Text('Set up my profile'),
          ),
        ],
      ),
    );
  }
}

// ── Life Stage Cards ──────────────────────────────────────────────────────────

class _LifeStageCards extends ConsumerWidget {
  const _LifeStageCards({required this.profile});
  final HealthProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pregnancyProfile = ref.watch(pregnancyProfileProvider);
    final babies = ref.watch(babiesProvider);

    final cards = <Widget>[];

    if (profile.lifeStage == LifeStage.pregnant && pregnancyProfile != null) {
      cards.add(_PremiumContextCard(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE8F0), Color(0xFFFFF0F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        accent: KholoColors.rose,
        icon: Icons.child_friendly_outlined,
        title: 'Week ${pregnancyProfile.currentWeek}',
        subtitle: '${pregnancyProfile.daysRemaining}d until due date',
        action: 'Open pregnancy',
        onTap: () => context.go('/pregnancy'),
      ));
    }

    if (babies.isNotEmpty) {
      final baby = babies.first;
      cards.add(_PremiumContextCard(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF1EB), Color(0xFFFFFAF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        accent: KholoColors.sage,
        icon: Icons.child_care_rounded,
        title: baby.nickname,
        subtitle: baby.ageDisplay,
        action: 'Log baby care',
        onTap: () => context.go('/baby'),
      ));
    }

    cards.add(_PremiumContextCard(
      gradient: const LinearGradient(
        colors: [Color(0xFFFFF0FA), Color(0xFFFFFDFF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      accent: KholoColors.lavender,
      icon: Icons.insights_outlined,
      title: 'Cycle insights',
      subtitle: 'See patterns from logs',
      action: 'View insights',
      onTap: () => context.go('/insights'),
    ));

    if (cards.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 170,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => cards[i],
      ),
    );
  }
}

class _PremiumContextCard extends StatelessWidget {
  const _PremiumContextCard({
    required this.gradient,
    required this.accent,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onTap,
  });

  final LinearGradient gradient;
  final Color accent;
  final IconData icon;
  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 190,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accent.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: tt.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: tt.bodySmall
                        ?.copyWith(color: KholoColors.inkMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(action,
                        style: tt.labelSmall?.copyWith(
                            color: accent, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded,
                        size: 12, color: accent),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick Actions ─────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.profile});
  final HealthProfile profile;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.0,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _PremiumActionTile(
          icon: Icons.water_drop_rounded,
          label: 'Log period',
          gradient: const LinearGradient(
            colors: [Color(0xFFFFE6F3), Color(0xFFFFF0F7)],
          ),
          iconColor: KholoColors.rose,
          onTap: () => LogBottomSheet.show(context),
        ),
        _PremiumActionTile(
          icon: Icons.calendar_month_rounded,
          label: 'View cycle',
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF0FA), Color(0xFFFFF8FF)],
          ),
          iconColor: KholoColors.lavender,
          onTap: () => context.go('/cycle'),
        ),
        _PremiumActionTile(
          icon: Icons.storefront_rounded,
          label: 'Shop care',
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF1EB), Color(0xFFFFFAF8)],
          ),
          iconColor: KholoColors.sage,
          onTap: () => context.go('/shop'),
        ),
        _PremiumActionTile(
          icon: Icons.child_care_rounded,
          label: 'Baby log',
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFDE8), Color(0xFFFFFEF8)],
          ),
          iconColor: KholoColors.tertiaryDark,
          onTap: () => context.go('/baby'),
        ),
      ],
    );
  }
}

class _PremiumActionTile extends StatefulWidget {
  const _PremiumActionTile({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  State<_PremiumActionTile> createState() => _PremiumActionTileState();
}

class _PremiumActionTileState extends State<_PremiumActionTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.selectionClick();
        _ctrl.forward();
      },
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: widget.iconColor.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: widget.iconColor.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: widget.iconColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: widget.iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  widget.label,
                  style: tt.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Recent Products ───────────────────────────────────────────────────────────

class _RecentProducts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final products = kSampleProducts.take(4).toList();
    return SizedBox(
      height: 176,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) {
          final p = products[i];
          return GestureDetector(
            onTap: () => context.go('/shop/${p.id}'),
            child: Container(
              width: 156,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.kCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.kDivider),
                boxShadow: [
                  BoxShadow(
                    color: context.isDark
                        ? Colors.black.withValues(alpha: 0.3)
                        : KholoColors.wine.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: context.isDark
                            ? [
                                KholoColors.magenta.withValues(alpha: 0.25),
                                KholoColors.wine.withValues(alpha: 0.25),
                              ]
                            : [
                                KholoColors.lavenderLight,
                                KholoColors.blush,
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.spa_outlined,
                        color: context.isDark
                            ? KholoColors.magenta
                            : KholoColors.plum,
                        size: 22),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: context.kTint(KholoColors.magenta,
                          lightAlpha: 0.12, darkAlpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      p.category,
                      style: TextStyle(
                          fontSize: 8,
                          color: context.isDark
                              ? KholoColors.blush
                              : KholoColors.plum,
                          fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(p.title,
                      style: Theme.of(ctx)
                          .textTheme
                          .titleSmall
                          ?.copyWith(color: context.kInk),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    '৳${p.priceBdt.toInt()}',
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: context.isDark
                            ? KholoColors.magenta
                            : KholoColors.plum,
                        fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AiSkinScannerBanner extends StatelessWidget {
  const _AiSkinScannerBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2A1124), Color(0xFF1B0F2A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFF62477).withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF62477).withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFF62477), Color(0xFF92003A)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF62477).withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'AI স্কিন ডক্টর স্ক্যানার',
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8D880),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF3E1B00),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ক্যামেরায় ফেস স্ক্যান করে ইনস্ট্যান্ট স্কিনকেয়ার পরামর্শ নিন',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 12,
                      color: const Color(0xFFE2DCE8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFF8D880), size: 16),
          ],
        ),
      ),
    );
  }
}

