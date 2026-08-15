import 'package:flutter/material.dart';
import '../../app/theme/colors.dart';
import '../../core/models/health_profile.dart';

/// Hero phase card displayed on the Today screen and calendar header.
/// Shows phase name, description, cycle day, and estimate label.
class PhaseCard extends StatelessWidget {
  const PhaseCard({
    super.key,
    required this.phase,
    required this.cycleDay,
    required this.cycleLength,
    this.daysUntilNextPeriod,
    this.isInFertileWindow = false,
  });

  final CyclePhase phase;
  final int cycleDay;
  final int cycleLength;
  final int? daysUntilNextPeriod;
  final bool isInFertileWindow;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final bg = KholoColors.phaseLightColor(phase.phaseKey);
    final accent = KholoColors.phaseColor(phase.phaseKey);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _PhaseIcon(phase: phase),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      phase.displayName,
                      style: tt.headlineMedium?.copyWith(color: KholoColors.ink),
                    ),
                    Text(
                      phase.description,
                      style: tt.bodySmall?.copyWith(color: KholoColors.inkMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Cycle progress bar
          _CycleProgressBar(
            cycleDay: cycleDay,
            cycleLength: cycleLength,
            phase: phase,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoChip(
                label: 'Day $cycleDay of $cycleLength',
                icon: Icons.radio_button_checked,
                color: accent,
              ),
              if (daysUntilNextPeriod != null) ...[
                const SizedBox(width: 8),
                _InfoChip(
                  label: '${daysUntilNextPeriod}d until period',
                  icon: Icons.schedule_outlined,
                  color: KholoColors.inkMuted,
                ),
              ],
              if (isInFertileWindow) ...[
                const SizedBox(width: 8),
                const _InfoChip(
                  label: 'Fertile window*',
                  icon: Icons.star_rounded,
                  color: KholoColors.wine,
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '* These are estimates, not medical advice.',
            style: tt.labelSmall?.copyWith(color: KholoColors.inkSubtle),
          ),
        ],
      ),
    );
  }
}

class _PhaseIcon extends StatelessWidget {
  const _PhaseIcon({required this.phase});
  final CyclePhase phase;

  @override
  Widget build(BuildContext context) {
    final color = KholoColors.phaseColor(phase.phaseKey);
    final icon = switch (phase) {
      CyclePhase.menstrual => Icons.water_drop_rounded,
      CyclePhase.follicular => Icons.local_florist_outlined,
      CyclePhase.ovulation => Icons.star_rounded,
      CyclePhase.luteal => Icons.nights_stay_outlined,
      CyclePhase.unknown => Icons.help_outline_rounded,
    };
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Icon(icon, color: color, size: 24, semanticLabel: phase.displayName),
    );
  }
}

class _CycleProgressBar extends StatelessWidget {
  const _CycleProgressBar({
    required this.cycleDay,
    required this.cycleLength,
    required this.phase,
  });

  final int cycleDay;
  final int cycleLength;
  final CyclePhase phase;

  @override
  Widget build(BuildContext context) {
    final progress = cycleDay / cycleLength;
    final color = KholoColors.phaseColor(phase.phaseKey);

    return Semantics(
      label: 'Cycle progress: day $cycleDay of $cycleLength',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: color.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KholoColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact version for calendar day marker.
class PhaseDot extends StatelessWidget {
  const PhaseDot({super.key, required this.phase, this.size = 8.0});
  final CyclePhase phase;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: KholoColors.phaseColor(phase.phaseKey),
        shape: BoxShape.circle,
      ),
    );
  }
}
