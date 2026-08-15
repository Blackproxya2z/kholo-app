/// Action type for an offline queued sync item.
enum SyncAction {
  create,
  update,
  delete,
}

/// Collection type identifiers for local and remote syncing.
class SyncCollection {
  static const String healthProfile = 'health_profile';
  static const String cycleLogs = 'cycle_logs';
  static const String pregnancyProfile = 'pregnancy_profile';
  static const String pregnancyLogs = 'pregnancy_logs';
  static const String babies = 'babies';
  static const String babyLogs = 'baby_logs';
}

/// An individual change operation stored in the offline sync queue.
class SyncQueueItem {
  final String queueId;
  final String collection;
  final String recordId;
  final SyncAction action;
  final Map<String, dynamic> payload;
  final DateTime clientTimestamp;
  final int retryCount;

  SyncQueueItem({
    required this.queueId,
    required this.collection,
    required this.recordId,
    required this.action,
    required this.payload,
    required this.clientTimestamp,
    this.retryCount = 0,
  });

  SyncQueueItem copyWith({
    int? retryCount,
  }) {
    return SyncQueueItem(
      queueId: queueId,
      collection: collection,
      recordId: recordId,
      action: action,
      payload: payload,
      clientTimestamp: clientTimestamp,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'queueId': queueId,
        'collection': collection,
        'recordId': recordId,
        'action': action.name,
        'payload': payload,
        'clientTimestamp': clientTimestamp.toIso8601String(),
        'retryCount': retryCount,
      };

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) {
    return SyncQueueItem(
      queueId: json['queueId'] as String,
      collection: json['collection'] as String,
      recordId: json['recordId'] as String,
      action: SyncAction.values.firstWhere(
        (a) => a.name == json['action'],
        orElse: () => SyncAction.update,
      ),
      payload: (json['payload'] as Map<String, dynamic>?) ?? {},
      clientTimestamp: DateTime.tryParse(json['clientTimestamp'] as String? ?? '') ??
          DateTime.now().toUtc(),
      retryCount: json['retryCount'] as int? ?? 0,
    );
  }
}

/// Metadata attached to synchronized records for timestamp-based conflict resolution.
class SyncMetadata {
  final String id;
  final DateTime updatedAt;
  final String? version;
  final bool isDeleted;

  const SyncMetadata({
    required this.id,
    required this.updatedAt,
    this.version,
    this.isDeleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'updatedAt': updatedAt.toIso8601String(),
        'version': version,
        'isDeleted': isDeleted,
      };

  factory SyncMetadata.fromJson(Map<String, dynamic> json) {
    return SyncMetadata(
      id: json['id'] as String,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now().toUtc(),
      version: json['version'] as String?,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }
}
