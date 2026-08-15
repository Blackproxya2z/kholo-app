import '../models/health_profile.dart';

/// Deterministic cycle calculation engine.
///
/// All calculations use UTC calendar-day math to prevent time-zone shift errors.
/// Every public helper is pure and testable — no side effects.
///
/// ⚠️  KHOLO presents all outputs as *estimates*.
/// This engine does not diagnose medical conditions or guarantee conception timing.
class CycleEngine {
  CycleEngine._();

  // ── Core helpers ──────────────────────────────────────────────────────────

  /// Strips the time portion of [date] and returns a UTC date-only value.
  static DateTime utcDate(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);

  /// Returns the cycle day (1-based) for [date] given [cycleStart].
  /// Returns null if [date] is before [cycleStart].
  static int? getCycleDay(DateTime cycleStart, DateTime date) {
    final start = utcDate(cycleStart);
    final d = utcDate(date);
    final diff = d.difference(start).inDays;
    if (diff < 0) return null;
    return diff + 1;
  }

  /// Given the last period start, cycle length and today's date,
  /// returns the current cycle day (1-based, wraps across cycles).
  static int currentCycleDay({
    required DateTime lastPeriodStart,
    required int cycleLength,
    DateTime? today,
  }) {
    final now = utcDate(today ?? DateTime.now());
    final start = utcDate(lastPeriodStart);
    final daysSinceStart = now.difference(start).inDays;
    if (daysSinceStart < 0) return 1;
    return (daysSinceStart % cycleLength) + 1;
  }

  /// Returns the estimated start date of the CURRENT cycle.
  static DateTime currentCycleStart({
    required DateTime lastPeriodStart,
    required int cycleLength,
    DateTime? today,
  }) {
    final now = utcDate(today ?? DateTime.now());
    final start = utcDate(lastPeriodStart);
    final daysSinceStart = now.difference(start).inDays;
    if (daysSinceStart < 0) return start;
    final cyclesElapsed = daysSinceStart ~/ cycleLength;
    return start.add(Duration(days: cyclesElapsed * cycleLength));
  }

  // ── Phase calculation ──────────────────────────────────────────────────────

  /// Returns the [CyclePhase] for [cycleDay] given [cycleLength] and [periodLength].
  static CyclePhase getCyclePhase({
    required int cycleDay,
    required int cycleLength,
    required int periodLength,
  }) {
    final ovulationDay = _estimatedOvulationDay(cycleLength);

    if (cycleDay <= periodLength) {
      return CyclePhase.menstrual;
    } else if (cycleDay < ovulationDay) {
      return CyclePhase.follicular;
    } else if (cycleDay == ovulationDay) {
      return CyclePhase.ovulation;
    } else {
      return CyclePhase.luteal;
    }
  }

  /// Returns the [CyclePhase] for [date] relative to [lastPeriodStart].
  static CyclePhase phaseForDate({
    required DateTime lastPeriodStart,
    required int cycleLength,
    required int periodLength,
    required DateTime date,
  }) {
    final cycleDay = currentCycleDay(
      lastPeriodStart: lastPeriodStart,
      cycleLength: cycleLength,
      today: date,
    );
    return getCyclePhase(
      cycleDay: cycleDay,
      cycleLength: cycleLength,
      periodLength: periodLength,
    );
  }

  // ── Fertility window ───────────────────────────────────────────────────────

  /// Returns {start, end, ovulation} dates for the ESTIMATED fertile window
  /// in the current cycle.
  ///
  /// Fertile window = 5 days before ovulation through 1 day after.
  static FertilityWindow getFertilityWindow({
    required DateTime lastPeriodStart,
    required int cycleLength,
    DateTime? today,
  }) {
    final cycleStart = currentCycleStart(
      lastPeriodStart: lastPeriodStart,
      cycleLength: cycleLength,
      today: today,
    );
    final ovulationDay = _estimatedOvulationDay(cycleLength);
    final ovulationDate = cycleStart.add(Duration(days: ovulationDay - 1));
    final windowStart = ovulationDate.subtract(const Duration(days: 5));
    final windowEnd = ovulationDate.add(const Duration(days: 1));

    return FertilityWindow(
      start: windowStart,
      end: windowEnd,
      ovulationDate: ovulationDate,
    );
  }

  /// Returns whether [date] falls within the estimated fertile window.
  static bool isInFertileWindow({
    required DateTime lastPeriodStart,
    required int cycleLength,
    required DateTime date,
  }) {
    final window = getFertilityWindow(
      lastPeriodStart: lastPeriodStart,
      cycleLength: cycleLength,
      today: date,
    );
    final d = utcDate(date);
    return !d.isBefore(window.start) && !d.isAfter(window.end);
  }

  // ── Next period estimate ───────────────────────────────────────────────────

  /// Returns the estimated start date of the NEXT period.
  static DateTime nextPeriodDate({
    required DateTime lastPeriodStart,
    required int cycleLength,
    DateTime? today,
  }) {
    final cycleStart = currentCycleStart(
      lastPeriodStart: lastPeriodStart,
      cycleLength: cycleLength,
      today: today,
    );
    return cycleStart.add(Duration(days: cycleLength));
  }

  /// Returns the number of days until the next estimated period start.
  /// Zero if today is the estimated start day.
  static int daysUntilNextPeriod({
    required DateTime lastPeriodStart,
    required int cycleLength,
    DateTime? today,
  }) {
    final now = utcDate(today ?? DateTime.now());
    final next = nextPeriodDate(
      lastPeriodStart: lastPeriodStart,
      cycleLength: cycleLength,
      today: today,
    );
    final diff = next.difference(now).inDays;
    return diff < 0 ? 0 : diff;
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Estimated ovulation day within the cycle (1-based).
  /// Formula: cycleLength − 14 (luteal phase is assumed ~14 days).
  static int _estimatedOvulationDay(int cycleLength) =>
      (cycleLength - 14).clamp(1, cycleLength);

  // ── Profile-based shortcuts ────────────────────────────────────────────────

  /// Full phase context for a given [profile] and [date].
  static PhaseContext? phaseContext(HealthProfile profile, {DateTime? date}) {
    if (profile.lastPeriodDate == null) return null;
    final now = date ?? DateTime.now();
    final cycleDay = currentCycleDay(
      lastPeriodStart: profile.lastPeriodDate!,
      cycleLength: profile.cycleLength,
      today: now,
    );
    final phase = getCyclePhase(
      cycleDay: cycleDay,
      cycleLength: profile.cycleLength,
      periodLength: profile.periodLength,
    );
    final window = getFertilityWindow(
      lastPeriodStart: profile.lastPeriodDate!,
      cycleLength: profile.cycleLength,
      today: now,
    );
    final inWindow = isInFertileWindow(
      lastPeriodStart: profile.lastPeriodDate!,
      cycleLength: profile.cycleLength,
      date: now,
    );
    final nextPeriod = nextPeriodDate(
      lastPeriodStart: profile.lastPeriodDate!,
      cycleLength: profile.cycleLength,
      today: now,
    );
    final days = daysUntilNextPeriod(
      lastPeriodStart: profile.lastPeriodDate!,
      cycleLength: profile.cycleLength,
      today: now,
    );

    return PhaseContext(
      phase: phase,
      cycleDay: cycleDay,
      cycleLength: profile.cycleLength,
      fertilityWindow: window,
      isInFertileWindow: inWindow,
      nextPeriodDate: nextPeriod,
      daysUntilNextPeriod: days,
    );
  }
}

// ── Value objects ─────────────────────────────────────────────────────────────

/// Estimated fertile window with ovulation date.
class FertilityWindow {
  final DateTime start;
  final DateTime end;
  final DateTime ovulationDate;

  const FertilityWindow({
    required this.start,
    required this.end,
    required this.ovulationDate,
  });

  bool contains(DateTime date) {
    final d = CycleEngine.utcDate(date);
    return !d.isBefore(start) && !d.isAfter(end);
  }
}

/// Rich phase context for the current day.
class PhaseContext {
  final CyclePhase phase;
  final int cycleDay;
  final int cycleLength;
  final FertilityWindow fertilityWindow;
  final bool isInFertileWindow;
  final DateTime nextPeriodDate;
  final int daysUntilNextPeriod;

  const PhaseContext({
    required this.phase,
    required this.cycleDay,
    required this.cycleLength,
    required this.fertilityWindow,
    required this.isInFertileWindow,
    required this.nextPeriodDate,
    required this.daysUntilNextPeriod,
  });
}
