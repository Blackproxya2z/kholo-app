import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/colors.dart';
import '../../core/models/health_profile.dart';
import '../../core/providers/providers.dart';
import '../../core/services/notification_service.dart';
import '../../shared/widgets/kholo_glowing_logo.dart';

/// ─── FIVE-STEP PREMIUM ONBOARDING EXPERIENCE ──────────────────────────────
/// Step 0: Welcome / luxury intro & brand mission
/// Step 1: Typical cycle length & period duration
/// Step 2: Last period start date
/// Step 3: Age bracket & current life stage
/// Step 4: Review & private on-device consent
/// ────────────────────────────────────────────────────────────────────────────
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  int _step = 0;
  static const int _totalSteps = 5;

  int _cycleLength = 28;
  int _periodLength = 5;
  DateTime? _lastPeriodDate;
  String _ageRange = '25–34';
  LifeStage _lifeStage = LifeStage.notPregnant;
  bool _saving = false;

  static const _ageRanges = ['Under 18', '18–24', '25–34', '35–44', '45–54', '55+'];

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isFirstStep = _step == 0;

    return Scaffold(
      backgroundColor: context.kCanvas,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator — hidden on welcome step
            if (!isFirstStep)
              _StepProgress(currentStep: _step - 1, totalSteps: _totalSteps - 1),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.06, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: _buildStep(tt),
                  ),
                ),
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() => _step--);
                        },
                        child: const Text('Back'),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: _step == 0 ? 1 : 2,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _advance,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(_step == _totalSteps - 1
                              ? 'Save and get started'
                              : _step == 0
                                  ? 'Get started'
                                  : 'Continue'),
                    ),
                  ),
                ],
              ),
            ),

            // Skip
            if (_step > 0 && _step < _totalSteps - 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextButton(
                  onPressed: _skip,
                  child: Text(
                    'Skip setup, go to shop',
                    style: TextStyle(color: context.kInkMuted),
                  ),
                ),
              )
            else if (_step == 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextButton(
                  onPressed: _skip,
                  child: Text(
                    'Skip — go straight to shop',
                    style: TextStyle(color: context.kInkMuted),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(TextTheme tt) {
    switch (_step) {
      case 0:
        return const _StepWelcome();
      case 1:
        return _StepCycleLength(
          cycleLength: _cycleLength,
          periodLength: _periodLength,
          onCycleChanged: (v) => setState(() => _cycleLength = v),
          onPeriodChanged: (v) => setState(() => _periodLength = v),
        );
      case 2:
        return _StepLastPeriod(
          lastPeriodDate: _lastPeriodDate,
          onDateChanged: (d) => setState(() => _lastPeriodDate = d),
        );
      case 3:
        return _StepAgeAndStage(
          ageRange: _ageRange,
          ageRanges: _ageRanges,
          lifeStage: _lifeStage,
          onAgeChanged: (a) => setState(() => _ageRange = a),
          onStageChanged: (s) => setState(() => _lifeStage = s),
        );
      case 4:
        return _StepReviewAndConsent(
          cycleLength: _cycleLength,
          periodLength: _periodLength,
          lastPeriodDate: _lastPeriodDate,
          ageRange: _ageRange,
          lifeStage: _lifeStage,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _advance() async {
    HapticFeedback.selectionClick();
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    } else {
      await _saveAndFinish();
    }
  }

  Future<void> _saveAndFinish() async {
    setState(() => _saving = true);
    final profile = HealthProfile(
      cycleLength: _cycleLength,
      periodLength: _periodLength,
      lastPeriodDate: _lastPeriodDate,
      ageRange: _ageRange,
      lifeStage: _lifeStage,
      onboardingComplete: true,
    );
    await ref.read(healthProfileProvider.notifier).save(profile);

    // Schedule cycle reminders after saving profile
    await NotificationService.requestPermission();
    await NotificationService.scheduleReminders(profile);

    if (mounted) context.go('/app');
  }

  void _skip() {
    HapticFeedback.selectionClick();
    ref.read(healthProfileProvider.notifier).update(
          (p) => p.copyWith(onboardingComplete: false),
        );
    context.go('/shop');
  }
}

// ── Step 0 — Welcome / App Intro ──────────────────────────────────────────────

class _StepWelcome extends StatelessWidget {
  const _StepWelcome();

  static const _features = [
    (Icons.water_drop_rounded, '🩸 Cycle tracking',
        'Phase-aware calendar, fertile window & insights', KholoColors.rose),
    (Icons.child_friendly_outlined, '🤰 Pregnancy support',
        'Week-by-week journey and due date countdown', KholoColors.sage),
    (Icons.child_care_rounded, '👶 Baby care',
        'Feeding, sleep & milestone logs', KholoColors.lavender),
    (Icons.storefront_outlined, '🛍️ Care shop',
        'Curated essentials, no fake reviews', KholoColors.warmGold),
    (Icons.lock_outline_rounded, '🔒 Private by default',
        'Your data stays on your device only', KholoColors.plum),
  ];

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24),

        // Glowing Blooming Animated Logo with Particles
        const KholoGlowingLogo(
          size: 88,
          showSparkles: true,
          showHalo: true,
        ),

        const SizedBox(height: 16),

        // App name
        Text(
          'KHOLO',
          style: GoogleFonts.playfairDisplay(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: context.kInk,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 10),

        // Tagline
        Text(
          'Your body, your journey —\nall in one calm space.',
          style: tt.bodyLarge?.copyWith(
            color: context.kInkMuted,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 32),

        // Feature highlights
        ...List.generate(_features.length, (i) {
          final f = _features[i];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 350 + i * 70),
            curve: Curves.easeOutCubic,
            builder: (_, v, child) => Opacity(
              opacity: v,
              child: Transform.translate(
                offset: Offset(0, 16 * (1 - v)),
                child: child,
              ),
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: context.kCard,
                borderRadius: BorderRadius.circular(16),
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
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: f.$4.withValues(alpha: context.isDark ? 0.25 : 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(f.$1, color: f.$4, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f.$2,
                          style: tt.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: context.kInk,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          f.$3,
                          style: tt.bodySmall
                              ?.copyWith(color: context.kInkMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 16),

        // Privacy reassurance
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.isDark
                ? context.kCardElevated
                : KholoColors.lavenderLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: (context.isDark
                        ? KholoColors.magenta
                        : KholoColors.lavender)
                    .withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.shield_outlined,
                  color: context.isDark ? KholoColors.magenta : KholoColors.plum,
                  size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your data is stored privately on your device. KHOLO never shares your health data.',
                  style: tt.bodySmall
                      ?.copyWith(color: context.kInkMuted, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Step progress indicator ───────────────────────────────────────────────────

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.currentStep, required this.totalSteps});
  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step ${currentStep + 1} of $totalSteps',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: context.kInkMuted),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (currentStep + 1) / totalSteps,
              backgroundColor: context.kDivider,
              valueColor: AlwaysStoppedAnimation<Color>(
                  context.isDark ? KholoColors.magenta : KholoColors.plum),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 1 — Cycle Length ─────────────────────────────────────────────────────

class _StepCycleLength extends StatelessWidget {
  const _StepCycleLength({
    required this.cycleLength,
    required this.periodLength,
    required this.onCycleChanged,
    required this.onPeriodChanged,
  });

  final int cycleLength;
  final int periodLength;
  final ValueChanged<int> onCycleChanged;
  final ValueChanged<int> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text('Your typical cycle',
            style: tt.displaySmall?.copyWith(color: context.kInk)),
        const SizedBox(height: 8),
        Text(
          'These help KHOLO estimate your phases. You can change them at any time.',
          style: tt.bodyMedium?.copyWith(color: context.kInkMuted),
        ),
        const SizedBox(height: 32),
        _SliderField(
          label: 'Cycle length',
          value: cycleLength,
          min: 21,
          max: 45,
          unit: 'days',
          onChanged: (v) {
            HapticFeedback.selectionClick();
            onCycleChanged(v);
          },
          hint: 'Typical range: 21–45 days',
        ),
        const SizedBox(height: 24),
        _SliderField(
          label: 'Period length',
          value: periodLength,
          min: 2,
          max: 10,
          unit: 'days',
          onChanged: (v) {
            HapticFeedback.selectionClick();
            onPeriodChanged(v);
          },
          hint: 'Typical range: 2–10 days',
        ),
      ],
    );
  }
}

class _SliderField extends StatelessWidget {
  const _SliderField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
    this.hint,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final String unit;
  final ValueChanged<int> onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: tt.titleMedium?.copyWith(color: context.kInk)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: context.isDark
                    ? context.kCardElevated
                    : KholoColors.lavenderLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.kDivider),
              ),
              child: Text(
                '$value $unit',
                style: tt.titleMedium?.copyWith(
                    color: context.isDark
                        ? KholoColors.blush
                        : KholoColors.plum),
              ),
            ),
          ],
        ),
        Semantics(
          label: '$label: $value $unit',
          child: Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            activeColor:
                context.isDark ? KholoColors.magenta : KholoColors.plum,
            inactiveColor: context.kDivider,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        if (hint != null)
          Text(hint!,
              style: tt.bodySmall?.copyWith(color: context.kInkSubtle)),
      ],
    );
  }
}

// ── Step 2 — Last Period ──────────────────────────────────────────────────────

class _StepLastPeriod extends StatelessWidget {
  const _StepLastPeriod({
    required this.lastPeriodDate,
    required this.onDateChanged,
  });
  final DateTime? lastPeriodDate;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text('Last period start',
            style: tt.displaySmall?.copyWith(color: context.kInk)),
        const SizedBox(height: 8),
        Text(
          'This helps estimate your current phase. It\'s optional — you can add it later.',
          style: tt.bodyMedium?.copyWith(color: context.kInkMuted),
        ),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: () async {
            HapticFeedback.mediumImpact();
            final picked = await showDatePicker(
              context: context,
              initialDate: lastPeriodDate ?? DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 90)),
              lastDate: DateTime.now(),
            );
            if (picked != null) onDateChanged(picked);
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.kCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: lastPeriodDate != null
                    ? (context.isDark
                        ? KholoColors.magenta
                        : KholoColors.plum)
                    : context.kDivider,
                width: lastPeriodDate != null ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: KholoColors.wine
                      .withValues(alpha: context.isDark ? 0.2 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: KholoColors.roseLight
                        .withValues(alpha: context.isDark ? 0.2 : 1.0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.water_drop_rounded,
                      color: KholoColors.rose, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('First day of last period',
                          style:
                              tt.titleMedium?.copyWith(color: context.kInk)),
                      const SizedBox(height: 4),
                      Text(
                        lastPeriodDate != null
                            ? _fmt(lastPeriodDate!)
                            : 'Tap to choose date',
                        style: tt.bodyMedium?.copyWith(
                            color: lastPeriodDate != null
                                ? (context.isDark
                                    ? KholoColors.blush
                                    : KholoColors.plum)
                                : context.kInkSubtle),
                      ),
                    ],
                  ),
                ),
                Icon(
                  lastPeriodDate != null
                      ? Icons.check_circle_rounded
                      : Icons.calendar_today_outlined,
                  color: lastPeriodDate != null
                      ? (context.isDark
                          ? KholoColors.magenta
                          : KholoColors.plum)
                      : context.kInkSubtle,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () {},
          icon: Icon(Icons.info_outline,
              size: 16,
              color: context.isDark ? KholoColors.magenta : KholoColors.wine),
          label: Text(
            'Why do we ask?',
            style: TextStyle(
                color: context.isDark ? KholoColors.magenta : KholoColors.wine),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            'Your last period date lets us estimate your current cycle phase and fertile window. This field is optional.',
            style:
                tt.bodySmall?.copyWith(color: context.kInkSubtle, height: 1.5),
          ),
        ),
      ],
    );
  }

  String _fmt(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ── Step 3 — Age & Life Stage ────────────────────────────────────────────────

class _StepAgeAndStage extends StatelessWidget {
  const _StepAgeAndStage({
    required this.ageRange,
    required this.ageRanges,
    required this.lifeStage,
    required this.onAgeChanged,
    required this.onStageChanged,
  });

  final String ageRange;
  final List<String> ageRanges;
  final LifeStage lifeStage;
  final ValueChanged<String> onAgeChanged;
  final ValueChanged<LifeStage> onStageChanged;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text('About you',
            style: tt.displaySmall?.copyWith(color: context.kInk)),
        const SizedBox(height: 8),
        Text(
          'Optional details to personalise your experience.',
          style: tt.bodyMedium?.copyWith(color: context.kInkMuted),
        ),
        const SizedBox(height: 32),
        Text('Age range',
            style: tt.titleMedium?.copyWith(color: context.kInk)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ageRanges.map((a) {
            final selected = ageRange == a;
            return ChoiceChip(
              label: Text(a),
              selected: selected,
              onSelected: (_) {
                HapticFeedback.selectionClick();
                onAgeChanged(a);
              },
              selectedColor:
                  context.isDark ? KholoColors.magenta : KholoColors.plum,
              labelStyle: TextStyle(
                  color: selected ? Colors.white : context.kInk,
                  fontWeight: FontWeight.w600),
              backgroundColor: context.isDark
                  ? context.kCardElevated
                  : KholoColors.lavenderLight,
            );
          }).toList(),
        ),
        const SizedBox(height: 28),
        Text('Where are you right now?',
            style: tt.titleMedium?.copyWith(color: context.kInk)),
        const SizedBox(height: 4),
        Text(
          'You can change this at any time in your profile.',
          style: tt.bodySmall?.copyWith(color: context.kInkMuted),
        ),
        const SizedBox(height: 12),
        ...LifeStage.values.map((s) => _StageCard(
              stage: s,
              isSelected: lifeStage == s,
              onTap: () {
                HapticFeedback.selectionClick();
                onStageChanged(s);
              },
            )),
      ],
    );
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.stage,
    required this.isSelected,
    required this.onTap,
  });

  final LifeStage stage;
  final bool isSelected;
  final VoidCallback onTap;

  static IconData _icon(LifeStage s) {
    switch (s) {
      case LifeStage.notPregnant:
        return Icons.self_improvement_outlined;
      case LifeStage.tryingToConceive:
        return Icons.favorite_border_rounded;
      case LifeStage.pregnant:
        return Icons.child_friendly_outlined;
      case LifeStage.postpartum:
        return Icons.child_care_outlined;
      case LifeStage.wellnessAndSkincare:
        return Icons.spa_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              _icon(stage),
              color: isSelected
                  ? (context.isDark
                      ? KholoColors.magenta
                      : KholoColors.plum)
                  : context.kInkMuted,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                stage.displayName,
                style: tt.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: context.kInk,
                ),
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
  }
}

// ── Step 4 — Review & Consent ─────────────────────────────────────────────────

class _StepReviewAndConsent extends StatelessWidget {
  const _StepReviewAndConsent({
    required this.cycleLength,
    required this.periodLength,
    required this.lastPeriodDate,
    required this.ageRange,
    required this.lifeStage,
  });

  final int cycleLength;
  final int periodLength;
  final DateTime? lastPeriodDate;
  final String ageRange;
  final LifeStage lifeStage;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text('Review your details',
            style: tt.displaySmall?.copyWith(color: context.kInk)),
        const SizedBox(height: 8),
        Text(
          'Saving this will personalise your dashboard. You can edit everything in Profile.',
          style: tt.bodyMedium?.copyWith(color: context.kInkMuted),
        ),
        const SizedBox(height: 28),
        _ReviewRow('Cycle length', '$cycleLength days'),
        _ReviewRow('Period length', '$periodLength days'),
        _ReviewRow(
          'Last period',
          lastPeriodDate != null ? _fmt(lastPeriodDate!) : 'Not provided',
        ),
        _ReviewRow('Age range', ageRange),
        _ReviewRow('Life stage', lifeStage.displayName),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.isDark
                ? context.kCardElevated
                : KholoColors.lavenderLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: (context.isDark
                        ? KholoColors.magenta
                        : KholoColors.lavender)
                    .withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shield_outlined,
                      color: context.isDark
                          ? KholoColors.magenta
                          : KholoColors.plum,
                      size: 18),
                  const SizedBox(width: 8),
                  Text('Privacy note',
                      style: tt.titleMedium?.copyWith(
                          color: context.isDark
                              ? KholoColors.blush
                              : KholoColors.plum)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Your health data is stored privately on your device. KHOLO does not share it with third parties, advertisers, or payment processors.\n\nAll cycle and fertility estimates are based on your inputs and should not be treated as medical advice. For health concerns, please consult a qualified clinician.',
                style: tt.bodySmall
                    ?.copyWith(color: context.kInkMuted, height: 1.55),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _fmt(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.kDivider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: tt.bodyMedium?.copyWith(color: context.kInkMuted)),
          Text(value,
              style: tt.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600, color: context.kInk)),
        ],
      ),
    );
  }
}
