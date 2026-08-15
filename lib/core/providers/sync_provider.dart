import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sync_engine_service.dart';
import 'providers.dart';

/// State representation for UI synchronization status.
class SyncState {
  final SyncStatus status;
  final DateTime? lastSyncedAt;
  final int pendingCount;
  final String? errorMessage;

  const SyncState({
    required this.status,
    this.lastSyncedAt,
    this.pendingCount = 0,
    this.errorMessage,
  });

  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSyncedAt,
    int? pendingCount,
    String? errorMessage,
  }) {
    return SyncState(
      status: status ?? this.status,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      pendingCount: pendingCount ?? this.pendingCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  String get statusDisplay {
    switch (status) {
      case SyncStatus.idle:
        return pendingCount > 0 ? '$pendingCount changes queued' : 'Up to date';
      case SyncStatus.syncing:
        return 'Syncing data...';
      case SyncStatus.synced:
        return 'Synced with cloud';
      case SyncStatus.offline:
        return 'Offline (Changes stored locally)';
      case SyncStatus.error:
        return errorMessage ?? 'Sync error (Retrying...)';
    }
  }
}

/// Notifier managing synchronization lifecycles and background triggers.
class SyncNotifier extends StateNotifier<SyncState> {
  final SyncEngineService _engine;
  final Ref _ref;

  SyncNotifier(this._engine, this._ref)
      : super(SyncState(
          status: SyncStatus.idle,
          lastSyncedAt: _engine.getLastSyncedAt(),
          pendingCount: _engine.pendingCount,
        ));

  /// Refresh pending count and sync state.
  void refresh() {
    state = state.copyWith(
      pendingCount: _engine.pendingCount,
      lastSyncedAt: _engine.getLastSyncedAt(),
    );
  }

  /// Trigger full sync cycle.
  Future<void> triggerSync() async {
    state = state.copyWith(status: SyncStatus.syncing, errorMessage: null);

    try {
      final storage = _ref.read(localStorageProvider);
      final result = await _engine.syncAll(storage);

      state = state.copyWith(
        status: result,
        lastSyncedAt: _engine.getLastSyncedAt(),
        pendingCount: _engine.pendingCount,
      );
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        errorMessage: e.toString(),
        pendingCount: _engine.pendingCount,
      );
    }
  }
}

/// Provider for SyncEngineService.
final syncEngineServiceProvider = Provider<SyncEngineService>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return SyncEngineService(prefs);
});

/// Provider for the SyncNotifier and its current SyncState.
final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  final engine = ref.watch(syncEngineServiceProvider);
  return SyncNotifier(engine, ref);
});
