import 'package:uuid/uuid.dart';

/// Types of daily cycle events the user can log.
enum CycleEventType {
  periodStart,
  periodEnd,
  checkIn;

  String get displayName {
    switch (this) {
      case CycleEventType.periodStart:
        return 'Period start';
      case CycleEventType.periodEnd:
        return 'Period end';
      case CycleEventType.checkIn:
        return 'Daily check-in';
    }
  }
}

/// Flow intensity options.
enum FlowIntensity { spotting, light, medium, heavy }

extension FlowIntensityDisplay on FlowIntensity {
  String get displayName {
    switch (this) {
      case FlowIntensity.spotting:
        return 'Spotting';
      case FlowIntensity.light:
        return 'Light';
      case FlowIntensity.medium:
        return 'Medium';
      case FlowIntensity.heavy:
        return 'Heavy';
    }
  }
}

/// Mood labels.
enum Mood { great, good, okay, low, rough }

extension MoodDisplay on Mood {
  String get displayName {
    switch (this) {
      case Mood.great:
        return 'Happy';
      case Mood.good:
        return 'Calm';
      case Mood.okay:
        return 'Okay';
      case Mood.low:
        return 'Low';
      case Mood.rough:
        return 'Irritated';
    }
  }

  String get emoji {
    switch (this) {
      case Mood.great:
        return '🌸';
      case Mood.good:
        return '🕊️';
      case Mood.okay:
        return '🌿';
      case Mood.low:
        return '🌧️';
      case Mood.rough:
        return '⚡';
    }
  }
}

/// One cycle event entry (period, check-in, or daily log).
class CycleLog {
  final String id;
  final DateTime eventDate; // UTC date only; time is discarded
  final CycleEventType eventType;
  final FlowIntensity? flow;
  final Mood? mood;
  final List<String> symptoms; // Free string chips from a curated list
  final String? cervicalMucus; // Dry, Sticky, Creamy, Egg white, Watery
  final String? intimacy; // Protected, Unprotected, None
  final String? notes;

  CycleLog({
    String? id,
    required this.eventDate,
    required this.eventType,
    this.flow,
    this.mood,
    this.symptoms = const [],
    this.cervicalMucus,
    this.intimacy,
    this.notes,
  }) : id = id ?? const Uuid().v4();

  CycleLog copyWith({
    String? id,
    DateTime? eventDate,
    CycleEventType? eventType,
    FlowIntensity? flow,
    Mood? mood,
    List<String>? symptoms,
    String? cervicalMucus,
    String? intimacy,
    String? notes,
  }) {
    return CycleLog(
      id: id ?? this.id,
      eventDate: eventDate ?? this.eventDate,
      eventType: eventType ?? this.eventType,
      flow: flow ?? this.flow,
      mood: mood ?? this.mood,
      symptoms: symptoms ?? this.symptoms,
      cervicalMucus: cervicalMucus ?? this.cervicalMucus,
      intimacy: intimacy ?? this.intimacy,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'eventDate': eventDate.toIso8601String(),
    'eventType': eventType.name,
    'flow': flow?.name,
    'mood': mood?.name,
    'symptoms': symptoms,
    'cervicalMucus': cervicalMucus,
    'intimacy': intimacy,
    'notes': notes,
  };

  factory CycleLog.fromJson(Map<String, dynamic> json) => CycleLog(
    id: json['id'] as String?,
    eventDate: DateTime.parse(json['eventDate'] as String),
    eventType: CycleEventType.values.firstWhere(
      (t) => t.name == json['eventType'],
      orElse: () => CycleEventType.checkIn,
    ),
    flow: json['flow'] != null
        ? FlowIntensity.values.firstWhere(
            (f) => f.name == json['flow'],
            orElse: () => FlowIntensity.light,
          )
        : null,
    mood: json['mood'] != null
        ? Mood.values.firstWhere(
            (m) => m.name == json['mood'],
            orElse: () => Mood.okay,
          )
        : null,
    symptoms: (json['symptoms'] as List<dynamic>?)
            ?.map((s) => s as String)
            .toList() ??
        [],
    cervicalMucus: json['cervicalMucus'] as String?,
    intimacy: json['intimacy'] as String?,
    notes: json['notes'] as String?,
  );
}

/// Curated symptom list for chip-based multi-select.
const List<String> kSymptomOptions = [
  'Cramps',
  'Bloating',
  'Headache',
  'Fatigue',
  'Tender breasts',
  'Back pain',
  'Nausea',
  'Mood swings',
  'Insomnia',
  'Acne',
  'Cravings',
  'Joint pain',
  'Hot flashes',
  'Spotting',
  'Discharge',
];
