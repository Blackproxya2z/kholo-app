import 'package:flutter_test/flutter_test.dart';
import 'package:kholo/core/models/health_profile.dart';
import 'package:kholo/core/utils/cycle_engine.dart';

void main() {
  group('CycleEngine Unit Tests', () {
    final periodStart = DateTime.utc(2026, 8, 1);
    const cycleLength = 28;
    const periodLength = 5;

    test('utcDate strips hours, minutes, seconds', () {
      final local = DateTime(2026, 8, 15, 23, 59, 59);
      final utc = CycleEngine.utcDate(local);
      expect(utc, DateTime.utc(2026, 8, 15));
    });

    test('getCycleDay returns correct 1-based cycle day', () {
      final day1 = CycleEngine.getCycleDay(periodStart, DateTime.utc(2026, 8, 1));
      final day14 = CycleEngine.getCycleDay(periodStart, DateTime.utc(2026, 8, 14));
      final before = CycleEngine.getCycleDay(periodStart, DateTime.utc(2026, 7, 31));

      expect(day1, 1);
      expect(day14, 14);
      expect(before, isNull);
    });

    test('currentCycleDay wraps seamlessly across multiple cycles', () {
      // Day 1 of cycle 1
      expect(
        CycleEngine.currentCycleDay(
          lastPeriodStart: periodStart,
          cycleLength: cycleLength,
          today: DateTime.utc(2026, 8, 1),
        ),
        1,
      );

      // Day 28 of cycle 1
      expect(
        CycleEngine.currentCycleDay(
          lastPeriodStart: periodStart,
          cycleLength: cycleLength,
          today: DateTime.utc(2026, 8, 28),
        ),
        28,
      );

      // Day 29 -> Day 1 of cycle 2
      expect(
        CycleEngine.currentCycleDay(
          lastPeriodStart: periodStart,
          cycleLength: cycleLength,
          today: DateTime.utc(2026, 8, 29),
        ),
        1,
      );
    });

    test('getCyclePhase identifies all 4 phases correctly for a 28-day cycle', () {
      // Menstrual: Days 1..5
      for (int d = 1; d <= 5; d++) {
        expect(
          CycleEngine.getCyclePhase(
            cycleDay: d,
            cycleLength: cycleLength,
            periodLength: periodLength,
          ),
          CyclePhase.menstrual,
          reason: 'Day $d should be menstrual',
        );
      }

      // Follicular: Days 6..13
      for (int d = 6; d <= 13; d++) {
        expect(
          CycleEngine.getCyclePhase(
            cycleDay: d,
            cycleLength: cycleLength,
            periodLength: periodLength,
          ),
          CyclePhase.follicular,
          reason: 'Day $d should be follicular',
        );
      }

      // Ovulation: Day 14 (28 - 14)
      expect(
        CycleEngine.getCyclePhase(
          cycleDay: 14,
          cycleLength: cycleLength,
          periodLength: periodLength,
        ),
        CyclePhase.ovulation,
      );

      // Luteal: Days 15..28
      for (int d = 15; d <= 28; d++) {
        expect(
          CycleEngine.getCyclePhase(
            cycleDay: d,
            cycleLength: cycleLength,
            periodLength: periodLength,
          ),
          CyclePhase.luteal,
          reason: 'Day $d should be luteal',
        );
      }
    });

    test('getFertilityWindow and isInFertileWindow compute accurate window', () {
      final window = CycleEngine.getFertilityWindow(
        lastPeriodStart: periodStart,
        cycleLength: cycleLength,
        today: DateTime.utc(2026, 8, 1),
      );

      // Ovulation is on day 14 -> Aug 14
      expect(window.ovulationDate, DateTime.utc(2026, 8, 14));
      // 5 days before ovulation -> Aug 9
      expect(window.start, DateTime.utc(2026, 8, 9));
      // 1 day after ovulation -> Aug 15
      expect(window.end, DateTime.utc(2026, 8, 15));

      // Check dates in and out of window
      expect(
        CycleEngine.isInFertileWindow(
          lastPeriodStart: periodStart,
          cycleLength: cycleLength,
          date: DateTime.utc(2026, 8, 8),
        ),
        isFalse,
      );
      expect(
        CycleEngine.isInFertileWindow(
          lastPeriodStart: periodStart,
          cycleLength: cycleLength,
          date: DateTime.utc(2026, 8, 9),
        ),
        isTrue,
      );
      expect(
        CycleEngine.isInFertileWindow(
          lastPeriodStart: periodStart,
          cycleLength: cycleLength,
          date: DateTime.utc(2026, 8, 14),
        ),
        isTrue,
      );
      expect(
        CycleEngine.isInFertileWindow(
          lastPeriodStart: periodStart,
          cycleLength: cycleLength,
          date: DateTime.utc(2026, 8, 15),
        ),
        isTrue,
      );
      expect(
        CycleEngine.isInFertileWindow(
          lastPeriodStart: periodStart,
          cycleLength: cycleLength,
          date: DateTime.utc(2026, 8, 16),
        ),
        isFalse,
      );
    });

    test('nextPeriodDate and daysUntilNextPeriod compute future cycles accurately', () {
      final next = CycleEngine.nextPeriodDate(
        lastPeriodStart: periodStart,
        cycleLength: cycleLength,
        today: DateTime.utc(2026, 8, 10),
      );
      expect(next, DateTime.utc(2026, 8, 29));

      final daysUntil = CycleEngine.daysUntilNextPeriod(
        lastPeriodStart: periodStart,
        cycleLength: cycleLength,
        today: DateTime.utc(2026, 8, 10),
      );
      expect(daysUntil, 19);
    });

    test('phaseContext returns null when lastPeriodDate is not set', () {
      const profile = HealthProfile(lastPeriodDate: null);
      expect(CycleEngine.phaseContext(profile), isNull);
    });

    test('phaseContext returns complete context when lastPeriodDate is present', () {
      final profile = HealthProfile(
        lastPeriodDate: periodStart,
        cycleLength: 28,
        periodLength: 5,
      );
      final ctx = CycleEngine.phaseContext(profile, date: DateTime.utc(2026, 8, 14));
      expect(ctx, isNotNull);
      expect(ctx!.phase, CyclePhase.ovulation);
      expect(ctx.cycleDay, 14);
      expect(ctx.isInFertileWindow, isTrue);
    });

    test('calculateAdaptiveCycleLength computes weighted average properly', () {
      // Empty history falls back to baseline
      expect(
        CycleEngine.calculateAdaptiveCycleLength(
          historicalCycleLengths: [],
          baselineLength: 28,
        ),
        28,
      );

      // Single history weighted 70% history + 30% baseline
      // (30 * 0.7) + (28 * 0.3) = 21 + 8.4 = 29.4 -> 29
      expect(
        CycleEngine.calculateAdaptiveCycleLength(
          historicalCycleLengths: [30],
          baselineLength: 28,
        ),
        29,
      );

      // 3 cycles: weights 50% for latest (32), 30% for middle (30), 20% for oldest (28)
      // (32 * 0.5) + (30 * 0.3) + (28 * 0.2) = 16 + 9 + 5.6 = 30.6 -> 31
      expect(
        CycleEngine.calculateAdaptiveCycleLength(
          historicalCycleLengths: [28, 30, 32],
          baselineLength: 28,
        ),
        31,
      );
    });
  });
}
