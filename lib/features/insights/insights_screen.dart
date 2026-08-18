import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/colors.dart';
import '../../core/providers/providers.dart';
import '../../core/models/cycle_log.dart';
import '../../core/utils/cycle_engine.dart';

/// ─── LUXURY CYCLE INSIGHTS & RHYTHM DASHBOARD ──────────────────────────────
///
/// Features:
/// 1. Real-time phase context card with countdown to next period.
/// 2. Cycle rhythm & historical interval averages.
/// 3. Symptom frequency analytics with progress indicators.
/// 4. Phase-aware emotional wellbeing prompts.
/// 5. Full Light & Dark luxury theme tokens.
/// ────────────────────────────────────────────────────────────────────────────
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(cycleLogsProvider);
    final profile = ref.watch(healthProfileProvider);
    final tt = Theme.of(context).textTheme;

    // Period-start logs sorted oldest first
    final periodStarts = logs
        .where((l) => l.eventType == CycleEventType.periodStart)
        .toList()
      ..sort((a, b) => a.eventDate.compareTo(b.eventDate));

    // Symptom frequency map
    final symptomCounts = <String, int>{};
    for (final log in logs) {
      for (final s in log.symptoms) {
        symptomCounts[s] = (symptomCounts[s] ?? 0) + 1;
      }
    }
    final topSymptoms = symptomCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Cycle intervals
    final intervals = <int>[];
    for (int i = 1; i < periodStarts.length; i++) {
      intervals.add(periodStarts[i]
          .eventDate
          .difference(periodStarts[i - 1].eventDate)
          .inDays);
    }
    final avgCycle = intervals.isEmpty
        ? profile.safeCycleLength
        : intervals.reduce((a, b) => a + b) ~/ intervals.length;

    final phaseCtx = profile.lastPeriodDate != null
        ? CycleEngine.phaseContext(profile)
        : null;

    return Scaffold(
      backgroundColor: context.kCanvas,
      appBar: AppBar(
        title: Text(
          'Cycle Insights',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
            color: context.kInk,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          // Current phase hero
          if (phaseCtx != null) ...[
            const _SectionTitle('Current phase'),
            const SizedBox(height: 12),
            _PhaseHero(ctx: phaseCtx),
            const SizedBox(height: 24),
          ],

          // Cycle rhythm
          const _SectionTitle('Cycle rhythm'),
          const SizedBox(height: 12),
          if (periodStarts.length >= 2) ...[
            _CycleRhythmCard(
              avgCycle: avgCycle,
              recentStarts: periodStarts.reversed
                  .take(3)
                  .map((l) => l.eventDate)
                  .toList(),
              intervals: intervals,
            ),
          ] else ...[
            const _MinDataState(
              message:
                  'Log at least 2 period start dates to see your personalized cycle rhythm.',
              neededLogs: 2,
            ),
          ],

          const SizedBox(height: 24),

          // Symptom patterns
          const _SectionTitle('Symptom patterns'),
          const SizedBox(height: 12),
          if (logs.length >= 3 && topSymptoms.isNotEmpty) ...[
            _SymptomPatternsCard(topSymptoms: topSymptoms.take(6).toList()),
          ] else ...[
            const _MinDataState(
              message: 'Log at least 3 daily check-ins to see symptom patterns.',
              neededLogs: 3,
            ),
          ],

          const SizedBox(height: 24),

          // Wellbeing prompt
          if (phaseCtx != null) ...[
            const _SectionTitle('Wellbeing prompt'),
            const SizedBox(height: 12),
            _WellbeingPrompt(phase: phaseCtx.phase.phaseKey),
          ],

          const SizedBox(height: 24),

          // Disclaimer
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.kCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.kDivider),
            ),
            child: Text(
              'Insights are derived solely from your own logged data. They are not medical diagnoses. For any health concerns, please consult a qualified healthcare provider.',
              style: tt.bodySmall
                  ?.copyWith(color: context.kInkSubtle, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 1.2,
            color: context.kInkSubtle,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _PhaseHero extends StatelessWidget {
  const _PhaseHero({required this.ctx});
  final PhaseContext ctx;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final color = context.isDark
        ? KholoColors.magenta
        : KholoColors.phaseColor(ctx.phase.phaseKey);
    final light = context.isDark
        ? context.kCardElevated
        : KholoColors.phaseLightColor(ctx.phase.phaseKey);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: light,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: context.isDark ? 0.2 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: context.isDark ? 0.25 : 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Center(
              child: Text(
                '${ctx.cycleDay}',
                style: GoogleFonts.playfairDisplay(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${ctx.phase.displayName} phase',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: context.kInk,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ctx.phase.description,
                  style: tt.bodySmall?.copyWith(color: context.kInkMuted),
                ),
                const SizedBox(height: 6),
                Text(
                  'Next period in ~${ctx.daysUntilNextPeriod} days*',
                  style: tt.bodySmall?.copyWith(color: context.kInkSubtle),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CycleRhythmCard extends StatelessWidget {
  const _CycleRhythmCard({
    required this.avgCycle,
    required this.recentStarts,
    required this.intervals,
  });

  final int avgCycle;
  final List<DateTime> recentStarts;
  final List<int> intervals;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: context.isDark
                      ? context.kCardElevated
                      : KholoColors.lavenderLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$avgCycle days',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: context.isDark
                        ? KholoColors.blush
                        : KholoColors.plum,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Average cycle length\nbased on your logged history',
                  style: tt.bodySmall
                      ?.copyWith(color: context.kInkMuted, height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Recent cycle lengths',
            style: tt.labelMedium?.copyWith(color: context.kInk),
          ),
          const SizedBox(height: 8),
          if (intervals.isNotEmpty)
            Row(
              children: intervals.reversed.take(3).map((days) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.isDark
                          ? context.kCardElevated
                          : KholoColors.lavenderLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.kDivider),
                    ),
                    child: Text(
                      '$days d',
                      style: tt.bodySmall?.copyWith(
                        color: context.isDark
                            ? KholoColors.blush
                            : KholoColors.plum,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _SymptomPatternsCard extends StatelessWidget {
  const _SymptomPatternsCard({required this.topSymptoms});
  final List<MapEntry<String, int>> topSymptoms;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final maxCount = topSymptoms.isEmpty
        ? 1
        : (topSymptoms.first.value == 0 ? 1 : topSymptoms.first.value);

    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: topSymptoms.map((entry) {
          final progress = (entry.value / maxCount).clamp(0.0, 1.0);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style:
                          tt.bodyMedium?.copyWith(color: context.kInk),
                    ),
                    Text(
                      '${entry.value}×',
                      style: tt.bodySmall?.copyWith(
                        color: context.isDark
                            ? KholoColors.magenta
                            : KholoColors.wine,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: context.kDivider,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      context.isDark
                          ? KholoColors.magenta
                          : KholoColors.wine,
                    ),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MinDataState extends StatelessWidget {
  const _MinDataState({required this.message, required this.neededLogs});
  final String message;
  final int neededLogs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.kDivider),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              color: context.kInkSubtle, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: context.kInkMuted, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// Phase-aware wellbeing prompts — editorial copy, not diagnosis.
const _wellbeingPrompts = {
  'menstrual': (
    'Rest and restore',
    'This is often a time to slow down. Gentle movement, warmth, and rest can feel especially supportive during your period.',
  ),
  'follicular': (
    'Energy rising',
    'Many people feel a natural lift in energy during this phase. It can be a good time for new projects, social plans, or creative work.',
  ),
  'ovulation': (
    'Peak energy',
    'Midcycle often brings peak energy and confidence. Notice what feels most natural for you today.',
  ),
  'luteal': (
    'Wind down',
    'The second half of your cycle may call for quieter rhythms. Nourishing foods, walks, and early rest can feel grounding.',
  ),
  'unknown': (
    'Tune in',
    'Start logging to discover patterns in your own cycle. Every entry helps build a clearer picture.',
  ),
};

class _WellbeingPrompt extends StatelessWidget {
  const _WellbeingPrompt({required this.phase});
  final String phase;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final data = _wellbeingPrompts[phase] ?? _wellbeingPrompts['unknown']!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: context.isDark
              ? [
                  const Color(0xFF2E1228),
                  const Color(0xFF1E1020),
                ]
              : [
                  KholoColors.blush.withValues(alpha: 0.5),
                  KholoColors.tertiaryLight.withValues(alpha: 0.5),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (context.isDark ? KholoColors.magenta : KholoColors.wine)
              .withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_outlined,
                  color: context.isDark ? KholoColors.magenta : KholoColors.wine,
                  size: 20),
              const SizedBox(width: 8),
              Text(
                data.$1,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.isDark ? KholoColors.blush : KholoColors.wine,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            data.$2,
            style: tt.bodyMedium
                ?.copyWith(color: context.kInkMuted, height: 1.6),
          ),
          const SizedBox(height: 10),
          Text(
            'This is general wellbeing guidance, not medical advice.',
            style: tt.labelSmall?.copyWith(color: context.kInkSubtle),
          ),
        ],
      ),
    );
  }
}
