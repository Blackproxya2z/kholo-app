/// Cycle phase enumeration with display helpers.
enum CyclePhase {
  menstrual,
  follicular,
  ovulation,
  luteal,
  unknown;

  String get displayName {
    switch (this) {
      case CyclePhase.menstrual:
        return 'Menstrual';
      case CyclePhase.follicular:
        return 'Follicular';
      case CyclePhase.ovulation:
        return 'Ovulation';
      case CyclePhase.luteal:
        return 'Luteal';
      case CyclePhase.unknown:
        return 'Unknown';
    }
  }

  String get description {
    switch (this) {
      case CyclePhase.menstrual:
        return 'Period days';
      case CyclePhase.follicular:
        return 'Energy may be rising';
      case CyclePhase.ovulation:
        return 'Estimated ovulation day';
      case CyclePhase.luteal:
        return 'Wind-down phase';
      case CyclePhase.unknown:
        return 'Log your period to personalise';
    }
  }

  String get phaseKey {
    return name;
  }
}

/// Life-stage preference captured during onboarding.
enum LifeStage {
  notPregnant,
  tryingToConceive,
  pregnant,
  postpartum;

  String get displayName {
    switch (this) {
      case LifeStage.notPregnant:
        return 'Not pregnant';
      case LifeStage.tryingToConceive:
        return 'Trying to conceive';
      case LifeStage.pregnant:
        return 'Pregnant';
      case LifeStage.postpartum:
        return 'Postpartum';
    }
  }
}

/// The user's private health baseline.
class HealthProfile {
  final int cycleLength; // 20–45 days
  final int periodLength; // 2–10 days
  final DateTime? lastPeriodDate;
  final String? ageRange;
  final LifeStage lifeStage;
  final bool onboardingComplete;
  final bool hasPcosPcod;
  final int dailyWaterGoalMl;
  final double targetSleepHours;
  final bool trackMood;

  const HealthProfile({
    this.cycleLength = 28,
    this.periodLength = 5,
    this.lastPeriodDate,
    this.ageRange,
    this.lifeStage = LifeStage.notPregnant,
    this.onboardingComplete = false,
    this.hasPcosPcod = false,
    this.dailyWaterGoalMl = 2000,
    this.targetSleepHours = 8.0,
    this.trackMood = true,
  });

  /// Guaranteed safe cycle length within 20..45 days.
  int get safeCycleLength => cycleLength.clamp(20, 45);

  /// Guaranteed safe period length within 2..10 days.
  int get safePeriodLength => periodLength.clamp(2, 10);

  HealthProfile copyWith({
    int? cycleLength,
    int? periodLength,
    DateTime? lastPeriodDate,
    String? ageRange,
    LifeStage? lifeStage,
    bool? onboardingComplete,
    bool? hasPcosPcod,
    int? dailyWaterGoalMl,
    double? targetSleepHours,
    bool? trackMood,
  }) {
    return HealthProfile(
      cycleLength: (cycleLength ?? this.cycleLength).clamp(20, 45),
      periodLength: (periodLength ?? this.periodLength).clamp(2, 10),
      lastPeriodDate: lastPeriodDate ?? this.lastPeriodDate,
      ageRange: ageRange ?? this.ageRange,
      lifeStage: lifeStage ?? this.lifeStage,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      hasPcosPcod: hasPcosPcod ?? this.hasPcosPcod,
      dailyWaterGoalMl: dailyWaterGoalMl ?? this.dailyWaterGoalMl,
      targetSleepHours: targetSleepHours ?? this.targetSleepHours,
      trackMood: trackMood ?? this.trackMood,
    );
  }

  Map<String, dynamic> toJson() => {
    'cycleLength': cycleLength,
    'periodLength': periodLength,
    'lastPeriodDate': lastPeriodDate?.toIso8601String(),
    'ageRange': ageRange,
    'lifeStage': lifeStage.name,
    'onboardingComplete': onboardingComplete,
    'hasPcosPcod': hasPcosPcod,
    'dailyWaterGoalMl': dailyWaterGoalMl,
    'targetSleepHours': targetSleepHours,
    'trackMood': trackMood,
  };

  factory HealthProfile.fromJson(Map<String, dynamic> json) => HealthProfile(
    cycleLength: (json['cycleLength'] as int? ?? 28).clamp(20, 45),
    periodLength: (json['periodLength'] as int? ?? 5).clamp(2, 10),
    lastPeriodDate: json['lastPeriodDate'] != null
        ? DateTime.tryParse(json['lastPeriodDate'] as String)
        : null,
    ageRange: json['ageRange'] as String?,
    lifeStage: LifeStage.values.firstWhere(
      (s) => s.name == json['lifeStage'],
      orElse: () => LifeStage.notPregnant,
    ),
    onboardingComplete: json['onboardingComplete'] as bool? ?? false,
    hasPcosPcod: json['hasPcosPcod'] as bool? ?? false,
    dailyWaterGoalMl: json['dailyWaterGoalMl'] as int? ?? 2000,
    targetSleepHours: (json['targetSleepHours'] as num?)?.toDouble() ?? 8.0,
    trackMood: json['trackMood'] as bool? ?? true,
  );
}
