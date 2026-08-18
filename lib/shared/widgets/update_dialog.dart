import 'package:flutter/material.dart';
import '../../app/theme/colors.dart';
import '../../core/models/app_update.dart';
import '../../core/services/update_service.dart';

/// ─── LUXURY IN-APP UPDATE DIALOG ───────────────────────────────────────────
///
/// Features:
/// 1. Clear release notes and file size indicator.
/// 2. Resumable chunked progress indicator with retry mechanism.
/// 3. SHA-256 cryptographic verification badge.
/// 4. User-friendly error messages without raw technical traces.
/// 5. Cancel / Later button (for non-mandatory updates) and Retry CTA.
/// ────────────────────────────────────────────────────────────────────────────
class UpdateDialog extends StatefulWidget {
  const UpdateDialog({
    super.key,
    required this.update,
    this.currentVersionCode = 1,
  });

  final AppUpdate update;
  final int currentVersionCode;

  /// Convenience static method to show the dialog.
  static Future<void> show(
    BuildContext context,
    AppUpdate update, {
    int currentVersionCode = 1,
  }) {
    final isMandatory = update.isMandatory(currentVersionCode);
    return showDialog(
      context: context,
      barrierDismissible: !isMandatory,
      builder: (_) => UpdateDialog(
        update: update,
        currentVersionCode: currentVersionCode,
      ),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  _Phase _phase = _Phase.idle;
  double _progress = 0;
  String _statusText = 'Downloading...';
  String? _errorMsg;

  bool get _isMandatory =>
      widget.update.isMandatory(widget.currentVersionCode);

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return PopScope(
      canPop: !_isMandatory &&
          _phase != _Phase.downloading &&
          _phase != _Phase.verifying,
      child: Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: context.kCard,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [KholoColors.wine, KholoColors.magenta],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: KholoColors.wine.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.system_update_rounded,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isMandatory
                              ? 'Required Update'
                              : 'New Version Available',
                          style: tt.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: context.kInk,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'v${widget.update.latestVersion} (Build ${widget.update.versionCode})',
                              style: tt.bodySmall
                                  ?.copyWith(color: context.kInkMuted),
                            ),
                            if (widget.update.formattedFileSize != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: context.isDark
                                      ? context.kCardElevated
                                      : KholoColors.lavenderLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  widget.update.formattedFileSize!,
                                  style: tt.labelSmall?.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: context.isDark
                                        ? KholoColors.blush
                                        : KholoColors.plum,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Security & Integrity Badge
              if (widget.update.apkSha256 != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFA5D6A7)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_rounded,
                          color: Color(0xFF2E7D32), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Signed build • SHA-256 Verified',
                          style: tt.labelSmall?.copyWith(
                            color: const Color(0xFF1B5E20),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Release notes
              if (widget.update.releaseNotes.isNotEmpty) ...[
                Text("What's new",
                    style: tt.titleSmall?.copyWith(color: context.kInkMuted)),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 140),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.isDark
                        ? context.kCardElevated
                        : KholoColors.lavenderLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      widget.update.releaseNotes,
                      style: tt.bodySmall
                          ?.copyWith(height: 1.6, color: context.kInk),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Progress bar & verification status
              if (_phase == _Phase.downloading ||
                  _phase == _Phase.verifying ||
                  _phase == _Phase.installing) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _statusText,
                        style: tt.bodySmall?.copyWith(
                          color: context.kInk,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_phase == _Phase.downloading)
                      Text('${(_progress * 100).toStringAsFixed(0)}%',
                          style: tt.bodySmall?.copyWith(
                              color: context.isDark
                                  ? KholoColors.magenta
                                  : KholoColors.plum,
                              fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _phase == _Phase.downloading ? _progress : null,
                    minHeight: 10,
                    backgroundColor: context.isDark
                        ? context.kCardElevated
                        : KholoColors.lavenderLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      context.isDark
                          ? KholoColors.magenta
                          : KholoColors.wine,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // User-Friendly Error message
              if (_errorMsg != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.isDark
                        ? const Color(0xFF3B1824)
                        : const Color(0xFFFDE8E8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: context.isDark
                          ? const Color(0xFFF87171).withValues(alpha: 0.4)
                          : const Color(0xFFF87171),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.wifi_off_rounded,
                          color: KholoColors.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMsg!,
                          style: tt.bodySmall?.copyWith(
                            color: context.isDark
                                ? const Color(0xFFFFB3B3)
                                : KholoColors.error,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Action buttons
              Row(
                children: [
                  if (!_isMandatory)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: (_phase == _Phase.downloading ||
                                _phase == _Phase.verifying ||
                                _phase == _Phase.installing)
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('Later'),
                      ),
                    ),
                  if (!_isMandatory) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: (_phase == _Phase.downloading ||
                              _phase == _Phase.verifying ||
                              _phase == _Phase.installing)
                          ? null
                          : _startDownloadAndInstall,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.isDark
                            ? KholoColors.magenta
                            : KholoColors.wine,
                        foregroundColor: Colors.white,
                      ),
                      child: (_phase == _Phase.downloading ||
                              _phase == _Phase.verifying ||
                              _phase == _Phase.installing)
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              _phase == _Phase.error
                                  ? 'Retry Download'
                                  : (_isMandatory
                                      ? 'Update Now (Required)'
                                      : 'Update Now'),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startDownloadAndInstall() async {
    setState(() {
      _phase = _Phase.downloading;
      _progress = 0;
      _statusText = 'Downloading update...';
      _errorMsg = null;
    });

    try {
      final path = await UpdateService.downloadApk(
        widget.update.effectiveApkUrl,
        mirrorUrls: widget.update.mirrorUrls,
        expectedSha256: widget.update.apkSha256,
        expectedFileSize: widget.update.fileSize,
        targetVersion: widget.update.latestVersion,
        targetVersionCode: widget.update.versionCode,
        onProgress: (p) {
          if (mounted) {
            setState(() {
              _progress = p;
              _statusText = 'Downloading (${(p * 100).toStringAsFixed(0)}%)...';
            });
          }
        },
        onStatusChange: (status) {
          if (mounted) {
            setState(() {
              _statusText = status;
              if (status.contains('Verifying')) {
                _phase = _Phase.verifying;
              }
            });
          }
        },
      );

      if (!mounted) return;

      setState(() {
        _phase = _Phase.installing;
        _statusText = 'Launching Package Installer...';
      });

      final installed = await UpdateService.installApk(path);
      if (installed) {
        await UpdateService.recordUpdateCompleted(widget.update.versionCode);
      }

      if (mounted && !_isMandatory) {
        Navigator.pop(context);
      }
    } on SecurityIntegrityException catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.error;
          _errorMsg = e.message;
        });
      }
    } on UpdateDownloadException catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.error;
          _errorMsg = e.userMessage;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _phase = _Phase.error;
          _errorMsg =
              'Update download failed. Please check your internet connection and try again.';
        });
      }
    }
  }
}

enum _Phase { idle, downloading, verifying, installing, error }
