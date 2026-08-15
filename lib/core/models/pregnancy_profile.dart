import 'package:uuid/uuid.dart';

/// Pregnancy profile anchored by a due date.
class PregnancyProfile {
  final DateTime dueDate;

  const PregnancyProfile({required this.dueDate});

  /// Current week of pregnancy (0-based from LMP; clamped to 0–42).
  int get currentWeek {
    final nowUtc = DateTime.utc(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final dueUtc =
        DateTime.utc(dueDate.year, dueDate.month, dueDate.day);
    final lmp = dueUtc.subtract(const Duration(days: 280));
    final daysSinceLmp = nowUtc.difference(lmp).inDays;
    return (daysSinceLmp ~/ 7).clamp(0, 42);
  }

  /// Days remaining until due date (never negative in display).
  int get daysRemaining {
    final nowUtc = DateTime.utc(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final dueUtc =
        DateTime.utc(dueDate.year, dueDate.month, dueDate.day);
    final remaining = dueUtc.difference(nowUtc).inDays;
    return remaining < 0 ? 0 : remaining;
  }

  Map<String, dynamic> toJson() => {
    'dueDate': dueDate.toIso8601String(),
  };

  factory PregnancyProfile.fromJson(Map<String, dynamic> json) =>
      PregnancyProfile(
        dueDate: DateTime.parse(json['dueDate'] as String),
      );
}

/// A single private pregnancy journal entry.
class PregnancyLog {
  final String id;
  final int pregnancyWeek;
  final DateTime eventDate;
  final List<String> symptoms;
  final String? note;

  PregnancyLog({
    String? id,
    required this.pregnancyWeek,
    required this.eventDate,
    this.symptoms = const [],
    this.note,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
    'id': id,
    'pregnancyWeek': pregnancyWeek,
    'eventDate': eventDate.toIso8601String(),
    'symptoms': symptoms,
    'note': note,
  };

  factory PregnancyLog.fromJson(Map<String, dynamic> json) => PregnancyLog(
    id: json['id'] as String?,
    pregnancyWeek: json['pregnancyWeek'] as int,
    eventDate: DateTime.parse(json['eventDate'] as String),
    symptoms: (json['symptoms'] as List<dynamic>?)
            ?.map((s) => s as String)
            .toList() ??
        [],
    note: json['note'] as String?,
  );
}

/// Weekly milestone metaphor — one original comparison per week.
const Map<int, Map<String, String>> kWeeklyMilestones = {
  4: {
    'size': 'Poppy seed',
    'detail': 'The embryo is forming its first structures this week.',
  },
  5: {
    'size': 'Sesame seed',
    'detail': 'The heart starts to beat around this time.',
  },
  6: {
    'size': 'Lentil',
    'detail': 'Facial features begin to develop.',
  },
  8: {
    'size': 'Raspberry',
    'detail': 'Fingers and toes are forming.',
  },
  10: {
    'size': 'Strawberry',
    'detail': 'All essential organs are in place.',
  },
  12: {
    'size': 'Lime',
    'detail': 'The first trimester is almost complete.',
  },
  16: {
    'size': 'Avocado',
    'detail': 'Movement may begin to be noticeable.',
  },
  20: {
    'size': 'Banana',
    'detail': 'Halfway through the journey.',
  },
  24: {
    'size': 'Ear of corn',
    'detail': 'Hearing is developing this week.',
  },
  28: {
    'size': 'Aubergine',
    'detail': 'The third trimester begins.',
  },
  32: {
    'size': 'Squash',
    'detail': 'Rapid brain development is happening.',
  },
  36: {
    'size': 'Honeydew melon',
    'detail': 'Almost ready — baby is gaining weight.',
  },
  40: {
    'size': 'Small watermelon',
    'detail': 'Full term. Every day is a gift.',
  },
};

/// Returns the closest milestone at or before [week].
Map<String, String>? getMilestoneForWeek(int week) {
  final keys = kWeeklyMilestones.keys.where((k) => k <= week).toList()..sort();
  if (keys.isEmpty) return null;
  return kWeeklyMilestones[keys.last];
}
