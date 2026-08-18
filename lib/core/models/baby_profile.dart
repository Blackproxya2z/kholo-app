import 'package:uuid/uuid.dart';

/// One infant or child profile — multiple allowed per account.
class BabyProfile {
  final String id;
  final String nickname;
  final DateTime birthDate;
  final String gender;
  final double? weightKg;
  final double? lengthCm;

  BabyProfile({
    String? id,
    String? name,
    String? nickname,
    required this.birthDate,
    this.gender = 'girl',
    this.weightKg,
    this.lengthCm,
  })  : id = id ?? const Uuid().v4(),
        nickname = nickname ?? name ?? 'Baby';

  String get name => nickname;

  /// Age in weeks (non-negative).
  int get ageWeeks {
    final nowUtc = DateTime.utc(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final birthUtc =
        DateTime.utc(birthDate.year, birthDate.month, birthDate.day);
    final days = nowUtc.difference(birthUtc).inDays;
    return days < 0 ? 0 : days ~/ 7;
  }

  /// Age display string.
  String get ageDisplay {
    final weeks = ageWeeks;
    if (weeks < 4) return '$weeks week${weeks == 1 ? '' : 's'} old';
    final months = weeks ~/ 4;
    if (months < 24) return '$months month${months == 1 ? '' : 's'} old';
    final years = months ~/ 12;
    return '$years year${years == 1 ? '' : 's'} old';
  }

  String get ageString => ageDisplay;

  Map<String, dynamic> toJson() => {
    'id': id,
    'nickname': nickname,
    'birthDate': birthDate.toIso8601String(),
    'gender': gender,
    'weightKg': weightKg,
    'lengthCm': lengthCm,
  };

  factory BabyProfile.fromJson(Map<String, dynamic> json) => BabyProfile(
    id: json['id'] as String?,
    nickname: (json['nickname'] ?? json['name'] ?? 'Baby') as String,
    birthDate: DateTime.parse(json['birthDate'] as String),
    gender: (json['gender'] ?? 'girl') as String,
    weightKg: (json['weightKg'] as num?)?.toDouble(),
    lengthCm: (json['lengthCm'] as num?)?.toDouble(),
  );
}

/// Type of baby log entry.
enum BabyLogType { feeding, sleep, growth, milestone, diaper }

extension BabyLogTypeDisplay on BabyLogType {
  String get displayName {
    switch (this) {
      case BabyLogType.feeding:
        return 'Feeding';
      case BabyLogType.sleep:
        return 'Sleep';
      case BabyLogType.growth:
        return 'Growth';
      case BabyLogType.milestone:
        return 'Milestone';
      case BabyLogType.diaper:
        return 'Diaper';
    }
  }

  String get emoji {
    switch (this) {
      case BabyLogType.feeding:
        return '🍼';
      case BabyLogType.sleep:
        return '😴';
      case BabyLogType.growth:
        return '📏';
      case BabyLogType.milestone:
        return '🌟';
      case BabyLogType.diaper:
        return '👶';
    }
  }
}

/// Feeding method.
enum FeedingMethod { breast, bottle, solid }

/// One care event for a baby.
class BabyLog {
  final String id;
  final String babyId;
  final BabyLogType logType;
  final DateTime occurredAt;
  // Feeding fields
  final FeedingMethod? feedingMethod;
  final double? amountMl;
  final String? feedType;
  // Sleep fields
  final DateTime? sleepEnd;
  final int? durationMinutes;
  // Growth fields
  final double? weightKg;
  final double? heightCm;
  final double? headCm;
  // Milestone
  final String? milestoneLabel;
  // Diaper
  final String? diaperStatus;
  // Common
  final String? note;

  BabyLog({
    String? id,
    required this.babyId,
    required this.logType,
    required this.occurredAt,
    this.feedingMethod,
    this.amountMl,
    this.feedType,
    this.sleepEnd,
    this.durationMinutes,
    this.weightKg,
    this.heightCm,
    this.headCm,
    this.milestoneLabel,
    this.diaperStatus,
    this.note,
  }) : id = id ?? const Uuid().v4();

  DateTime get timestamp => occurredAt;
  DateTime get startTime => occurredAt;
  String get status => diaperStatus ?? 'Wet';

  /// Sleep duration in minutes (null if end not set).
  int? get sleepMinutes {
    if (durationMinutes != null) return durationMinutes;
    if (sleepEnd == null) return null;
    return sleepEnd!.difference(occurredAt).inMinutes;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'babyId': babyId,
    'logType': logType.name,
    'occurredAt': occurredAt.toIso8601String(),
    'feedingMethod': feedingMethod?.name,
    'amountMl': amountMl,
    'feedType': feedType,
    'sleepEnd': sleepEnd?.toIso8601String(),
    'durationMinutes': durationMinutes,
    'weightKg': weightKg,
    'heightCm': heightCm,
    'headCm': headCm,
    'milestoneLabel': milestoneLabel,
    'diaperStatus': diaperStatus,
    'note': note,
  };

  factory BabyLog.fromJson(Map<String, dynamic> json) => BabyLog(
    id: json['id'] as String?,
    babyId: json['babyId'] as String,
    logType: BabyLogType.values.firstWhere(
      (t) => t.name == json['logType'],
      orElse: () => BabyLogType.feeding,
    ),
    occurredAt: DateTime.parse(json['occurredAt'] as String),
    feedingMethod: json['feedingMethod'] != null
        ? FeedingMethod.values.firstWhere(
            (m) => m.name == json['feedingMethod'],
            orElse: () => FeedingMethod.breast,
          )
        : null,
    amountMl: (json['amountMl'] as num?)?.toDouble(),
    feedType: json['feedType'] as String?,
    sleepEnd: json['sleepEnd'] != null
        ? DateTime.parse(json['sleepEnd'] as String)
        : null,
    durationMinutes: json['durationMinutes'] as int?,
    weightKg: (json['weightKg'] as num?)?.toDouble(),
    heightCm: (json['heightCm'] as num?)?.toDouble(),
    headCm: (json['headCm'] as num?)?.toDouble(),
    milestoneLabel: json['milestoneLabel'] as String?,
    diaperStatus: json['diaperStatus'] as String?,
    note: json['note'] as String?,
  );
}

// ── Convenient subclass wrappers for timeline views ─────────────────────────
class BabyFeedLog extends BabyLog {
  BabyFeedLog({
    super.id,
    required super.babyId,
    required DateTime timestamp,
    required String feedType,
    int? amountMl,
    super.note,
  }) : super(
          logType: BabyLogType.feeding,
          occurredAt: timestamp,
          feedType: feedType,
          amountMl: amountMl?.toDouble(),
        );
}

class BabySleepLog extends BabyLog {
  BabySleepLog({
    super.id,
    required super.babyId,
    required DateTime startTime,
    required DateTime endTime,
    required int durationMinutes,
    super.note,
  }) : super(
          logType: BabyLogType.sleep,
          occurredAt: startTime,
          sleepEnd: endTime,
          durationMinutes: durationMinutes,
        );
}

class BabyDiaperLog extends BabyLog {
  BabyDiaperLog({
    super.id,
    required super.babyId,
    required DateTime timestamp,
    required String status,
    super.note,
  }) : super(
          logType: BabyLogType.diaper,
          occurredAt: timestamp,
          diaperStatus: status,
        );
}

/// Curated milestone labels.
const List<String> kMilestoneLabels = [
  'First smile 😊',
  'First laugh',
  'Held head up',
  'Rolled over',
  'Sat without support',
  'First solid food 🥣',
  'First tooth 🦷',
  'Started crawling',
  'Pulled to stand',
  'First steps 👣',
  'First words',
  'First birthday 🎂',
];
