import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_update.dart';
import '../services/notification_service.dart';
import '../services/update_service.dart';

enum UpdateStatus {
  idle,
  checking,
  updateAvailable,
  downloading,
  verifying,
  readyToInstall,
  completed,
  upToDate,
  error,
}

class UpdateState {
  final UpdateStatus status;
  final AppUpdate? update;
  final int currentVersionCode;
  final String currentVersionName;
  final double downloadProgress;
  final String statusMessage;
  final String? errorMessage;
  final String? stagedFilePath;

  const UpdateState({
    this.status = UpdateStatus.idle,
    this.update,
    this.currentVersionCode = 20,
    this.currentVersionName = '1.3.0',
    this.downloadProgress = 0.0,
    this.statusMessage = '',
    this.errorMessage,
    this.stagedFilePath,
  });

  bool get isMandatory =>
      update != null && update!.isMandatory(currentVersionCode);

  UpdateState copyWith({
    UpdateStatus? status,
    AppUpdate? update,
    int? currentVersionCode,
    String? currentVersionName,
    double? downloadProgress,
    String? statusMessage,
    String? errorMessage,
    String? stagedFilePath,
    bool clearUpdate = false,
  }) {
    return UpdateState(
      status: status ?? this.status,
      update: clearUpdate ? null : (update ?? this.update),
      currentVersionCode: currentVersionCode ?? this.currentVersionCode,
      currentVersionName: currentVersionName ?? this.currentVersionName,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      statusMessage: statusMessage ?? this.statusMessage,
      errorMessage: errorMessage,
      stagedFilePath: stagedFilePath ?? this.stagedFilePath,
    );
  }
}

class UpdateNotifier extends StateNotifier<UpdateState> {
  UpdateNotifier() : super(const UpdateState()) {
    _initVersionInfo();
  }

  Future<void> _initVersionInfo() async {
    final code = await UpdateService.currentVersionCode();
    final name = await UpdateService.currentVersionName();
    state = state.copyWith(
      currentVersionCode: code,
      currentVersionName: name,
    );
  }

  /// Checks remote release server for new updates.
  Future<AppUpdate?> checkForUpdate({bool notifyIfAvailable = true}) async {
    state = state.copyWith(
      status: UpdateStatus.checking,
      statusMessage: 'Checking for updates...',
      errorMessage: null,
    );

    final code = await UpdateService.currentVersionCode();
    final name = await UpdateService.currentVersionName();
    final update = await UpdateService.checkForUpdate();

    if (update != null && update.isNewerThan(code, name)) {
      state = state.copyWith(
        status: UpdateStatus.updateAvailable,
        update: update,
        currentVersionCode: code,
        currentVersionName: name,
        statusMessage: 'Update v${update.latestVersion} available',
      );

      if (notifyIfAvailable) {
        final shouldNotify =
            await UpdateService.shouldShowUpdateNotification(
          update.versionCode,
          remoteVersionName: update.latestVersion,
        );
        if (shouldNotify) {
          await NotificationService.showUpdateNotification(
            version: update.latestVersion,
            versionCode: update.versionCode,
            releaseNotes: update.releaseNotes,
          );
          await UpdateService.recordNotificationSent(update.versionCode);
        }
      }
      return update;
    } else {
      state = state.copyWith(
        status: UpdateStatus.upToDate,
        clearUpdate: true,
        currentVersionCode: code,
        currentVersionName: name,
        statusMessage: 'You are on the latest version of KHOLO.',
      );
      return null;
    }
  }

  /// Downloads and automatically triggers installation for [targetUpdate].
  Future<bool> downloadAndInstall(AppUpdate targetUpdate) async {
    state = state.copyWith(
      status: UpdateStatus.downloading,
      update: targetUpdate,
      downloadProgress: 0.0,
      statusMessage: 'Connecting to KHOLO update server...',
      errorMessage: null,
    );

    try {
      final filePath = await UpdateService.downloadApk(
        targetUpdate.effectiveApkUrl,
        mirrorUrls: targetUpdate.mirrorUrls,
        expectedSha256: targetUpdate.apkSha256,
        expectedFileSize: targetUpdate.fileSize,
        targetVersion: targetUpdate.latestVersion,
        targetVersionCode: targetUpdate.versionCode,
        onProgress: (prog) {
          state = state.copyWith(
            downloadProgress: prog,
            statusMessage: 'Downloading update: ${(prog * 100).toInt()}%',
          );
        },
        onStatusChange: (status) {
          state = state.copyWith(
            statusMessage: status,
            status: status.contains('Verifying')
                ? UpdateStatus.verifying
                : state.status,
          );
        },
      );

      state = state.copyWith(
        status: UpdateStatus.readyToInstall,
        stagedFilePath: filePath,
        statusMessage: 'Release verified. Opening installer...',
      );

      final installed = await UpdateService.installApk(filePath);
      if (installed) {
        state = state.copyWith(
          status: UpdateStatus.completed,
          statusMessage: 'Installation launched successfully.',
        );
        await UpdateService.recordUpdateCompleted(targetUpdate.versionCode);
      }
      return installed;
    } on SecurityIntegrityException catch (e) {
      state = state.copyWith(
        status: UpdateStatus.error,
        errorMessage: 'Security verification failed: ${e.message}',
        statusMessage: 'Update aborted due to checksum mismatch.',
      );
      return false;
    } on UpdateDownloadException catch (e) {
      state = state.copyWith(
        status: UpdateStatus.error,
        errorMessage: e.userMessage,
        statusMessage: 'Download interrupted.',
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        status: UpdateStatus.error,
        errorMessage:
            'Update download failed. Please check your internet connection and try again.',
        statusMessage: 'Failed to download update.',
      );
      return false;
    }
  }

  /// Installs previously downloaded and staged APK.
  Future<bool> installStagedApk() async {
    if (state.stagedFilePath == null) return false;
    final success = await UpdateService.installApk(state.stagedFilePath!);
    if (success && state.update != null) {
      await UpdateService.recordUpdateCompleted(state.update!.versionCode);
      state = state.copyWith(
        status: UpdateStatus.completed,
        statusMessage: 'Installation completed.',
      );
    }
    return success;
  }

  /// Clears error states and resets update prompt
  void resetError() {
    state = state.copyWith(
      status: state.update != null
          ? UpdateStatus.updateAvailable
          : UpdateStatus.idle,
      errorMessage: null,
    );
  }
}

final updateProvider =
    StateNotifierProvider<UpdateNotifier, UpdateState>((ref) {
  return UpdateNotifier();
});
