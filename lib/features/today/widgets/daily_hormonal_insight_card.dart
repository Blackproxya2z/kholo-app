import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/colors.dart';
import '../../../core/models/health_profile.dart';

/// Daily hormonal report card summarizing conception probability,
/// energy forecast, and personalized phase-aligned lifestyle guidance.
class DailyHormonalInsightCard extends StatelessWidget {
  final CyclePhase phase;
  final int cycleDay;
  final bool isFertile;
  final bool isOvulation;

  const DailyHormonalInsightCard({
    super.key,
    required this.phase,
    required this.cycleDay,
    required this.isFertile,
    required this.isOvulation,
  });

  String get _conceptionProbability {
    if (isOvulation) return 'Peak';
    if (isFertile) return 'High';
    if (phase == CyclePhase.follicular) return 'Medium';
    return 'Low';
  }

  Color get _conceptionColor {
    if (isOvulation) return KholoColors.wine;
    if (isFertile) return KholoColors.magenta;
    if (phase == CyclePhase.follicular) return KholoColors.plum;
    return KholoColors.inkMuted;
  }

  String get _energyForecast {
    switch (phase) {
      case CyclePhase.menstrual:
        return 'Restorative & Grounded (Estrogen Low)';
      case CyclePhase.follicular:
        return 'Rising & Energetic (Estrogen Climbing)';
      case CyclePhase.ovulation:
        return 'Peak Vitality & Magnetic (Estrogen & LH Peak)';
      case CyclePhase.luteal:
        return 'Cozy, Mindful & Focused (Progesterone High)';
      case CyclePhase.unknown:
        return 'Steady & Balanced';
    }
  }

  String get _nutritionTip {
    switch (phase) {
      case CyclePhase.menstrual:
        return 'Focus on warm, iron-rich foods, leafy greens, berries, and soothing ginger or chamomile tea.';
      case CyclePhase.follicular:
        return 'Include fermented foods, sprouted seeds, light lean proteins, and citrus for collagen support.';
      case CyclePhase.ovulation:
        return 'Enjoy antioxidant-packed colorful veggies, berries, avocados, and zinc-rich pumpkin seeds.';
      case CyclePhase.luteal:
        return 'Prioritize complex carbs (sweet potatoes, oats), magnesium-rich dark chocolate, and roasted root vegetables.';
      case CyclePhase.unknown:
        return 'Maintain balanced wholesome meals, rich in fiber, healthy fats, and adequate hydration.';
    }
  }

  String get _movementTip {
    switch (phase) {
      case CyclePhase.menstrual:
        return 'Gentle yin yoga, slow walks in nature, and restorative stretching.';
      case CyclePhase.follicular:
        return 'Cardio, dance, moderate strength training, and trying new active hobbies.';
      case CyclePhase.ovulation:
        return 'High-intensity workouts (HIIT), heavy resistance training, and group fitness.';
      case CyclePhase.luteal:
        return 'Pilates, steady-state incline walking, and relaxing mobility routines.';
      case CyclePhase.unknown:
        return 'Listen to your body rhythm and choose intuitive movement that feels joyful.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KholoColors.divider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F92003A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with conception probability pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today’s Hormonal Rhythm',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: KholoColors.ink,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _conceptionColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _conceptionColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bubble_chart_rounded, size: 13, color: _conceptionColor),
                    const SizedBox(width: 4),
                    Text(
                      '$_conceptionProbability Conception',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _conceptionColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Energy forecast
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: KholoColors.lavenderLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded, color: KholoColors.plum, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Energy & Mood Forecast',
                        style: tt.labelSmall?.copyWith(
                          color: KholoColors.plum,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _energyForecast,
                        style: tt.bodySmall?.copyWith(
                          color: KholoColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Nutrition & Movement tips
          _InsightItem(
            icon: Icons.restaurant_rounded,
            title: 'Nourishment tip',
            description: _nutritionTip,
          ),
          const Divider(height: 20, color: KholoColors.divider),
          _InsightItem(
            icon: Icons.self_improvement_rounded,
            title: 'Movement & Self-care',
            description: _movementTip,
          ),
        ],
      ),
    );
  }
}

class _InsightItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InsightItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: KholoColors.blush.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: KholoColors.wine, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: tt.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: KholoColors.wine,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: tt.bodySmall?.copyWith(
                  color: KholoColors.inkMuted,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
