import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/colors.dart';
import '../../core/providers/providers.dart';
import '../../core/models/cycle_log.dart';
import '../../core/utils/cycle_engine.dart';

/// Insights screen — honest data views derived from the user's own logs.
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
        ? profile.cycleLength
        : intervals.reduce((a, b) => a + b) ~/ intervals.length;

    final phaseCtx = profile.lastPeriodDate != null
        ? CycleEngine.phaseContext(profile)
        : null;

    return Scaffold(
      backgroundColor: KholoColors.canvas,
      appBar: AppBar(title: const Text('Insights')),
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
              recentStarts: periodStarts.reversed.take(3).map((l) => l.eventDate).toList(),
              intervals: intervals,
            ),
          ] else ...[
            _MinDataState(
              message: 'Log at least 2 period start dates to see your cycle rhythm.',
              neededLogs: (2 - periodStarts.length).clamp(0, 2),
            ),
          ],

          const SizedBox(height: 24),

          // Symptom patterns
          const _SectionTitle('Symptom patterns'),
          const SizedBox(height: 12),
          if (logs.length >= 3 && topSymptoms.isNotEmpty) ...[
            _SymptomPatternsCard(topSymptoms: topSymptoms.take(6).toList()),
          ] else ...[
            _MinDataState(
              message: 'Log at least 3 check-ins to see symptom patterns.',
              neededLogs: (3 - logs.length).clamp(0, 3),
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
              color: KholoColors.cream,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: KholoColors.divider),
            ),
            child: Text(
              'Insights are derived only from your own logged data. They are not medical diagnoses. For health concerns, please consult a qualified clinician.',
              style: tt.bodySmall?.copyWith(color: KholoColors.inkSubtle, height: 1.5),
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
            color: KholoColors.inkSubtle,
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
    final color = KholoColors.phaseColor(ctx.phase.phaseKey);
    final light = KholoColors.phaseLightColor(ctx.phase.phaseKey);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: light,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Center(
              child: Text(
                '${ctx.cycleDay}',
                style: tt.headlineMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${ctx.phase.displayName} phase',
                    style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                Text(ctx.phase.description,
                    style: tt.bodySmall?.copyWith(color: KholoColors.inkMuted)),
                const SizedBox(height: 6),
                Text('Next period in ~${ctx.daysUntilNextPeriod} days*',
                    style: tt.bodySmall?.copyWith(color: KholoColors.inkSubtle)),
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
        color: KholoColors.cream,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KholoColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: KholoColors.lavenderLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$avgCycle days',
                  style: tt.headlineSmall?.copyWith(color: KholoColors.plum),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Average cycle length\nbased on your logs',
                  style: tt.bodySmall?.copyWith(color: KholoColors.inkMuted, height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Recent cycle lengths', style: tt.labelMedium),
          const SizedBox(height: 8),
          if (intervals.isNotEmpty)
            Row(
              children: intervals.reversed.take(3).map((days) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: KholoColors.lavenderLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$days d',
                      style: tt.bodySmall
                          ?.copyWith(color: KholoColors.plum, fontWeight: FontWeight.w600),
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
        color: KholoColors.cream,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KholoColors.divider),
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
                    Text(entry.key, style: tt.bodyMedium),
                    Text(
                      '${entry.value}×',
                      style: tt.bodySmall
                          ?.copyWith(color: KholoColors.inkMuted, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: KholoColors.blush.withValues(alpha: 0.3),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(KholoColors.magenta),
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
        color: KholoColors.cream,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KholoColors.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: KholoColors.inkSubtle, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: KholoColors.inkMuted, height: 1.5),
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
        gradient: const LinearGradient(
          colors: [KholoColors.blush, KholoColors.tertiaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KholoColors.wine.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_outlined, color: KholoColors.wine, size: 20),
              const SizedBox(width: 8),
              Text(data.$1, style: tt.titleMedium?.copyWith(color: KholoColors.wine)),
            ],
          ),
          const SizedBox(height: 10),
          Text(data.$2, style: tt.bodyMedium?.copyWith(color: KholoColors.inkMuted, height: 1.6)),
          const SizedBox(height: 10),
          Text(
            'This is general wellbeing guidance, not medical advice.',
            style: tt.labelSmall?.copyWith(color: KholoColors.inkSubtle),
          ),
        ],
      ),
    );
  }
}
