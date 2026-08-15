import 'package:flutter/material.dart';
import '../../app/theme/colors.dart';
import '../../core/models/app_update.dart';
import '../../core/services/update_service.dart';

/// Full-screen update dialog showing release notes and a download progress bar.
/// Opens when user taps the UpdateBanner or the update menu item.
class UpdateDialog extends StatefulWidget {
  const UpdateDialog({super.key, required this.update});
  final AppUpdate update;

  /// Convenience static method to show the dialog.
  static Future<void> show(BuildContext context, AppUpdate update) {
    return showDialog(
      context: context,
      barrierDismissible: !update.forceUpdate,
      builder: (_) => UpdateDialog(update: update),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  _Phase _phase = _Phase.idle;
  double _progress = 0;
  String? _errorMsg;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: KholoColors.canvas,
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
                  ),
                  child: const Icon(Icons.system_update_rounded,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('New version ready',
                          style: tt.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700, color: KholoColors.ink)),
                      Text(
                        'v${widget.update.latestVersion}',
                        style: tt.bodySmall?.copyWith(color: KholoColors.inkMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Release notes
            if (widget.update.releaseNotes.isNotEmpty) ...[
              Text("What's new", style: tt.titleSmall?.copyWith(color: KholoColors.inkMuted)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: KholoColors.lavenderLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  widget.update.releaseNotes,
                  style: tt.bodySmall?.copyWith(height: 1.6, color: KholoColors.ink),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Progress bar (visible during download)
            if (_phase == _Phase.downloading) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Downloading...', style: tt.bodySmall?.copyWith(color: KholoColors.inkMuted)),
                  Text('${(_progress * 100).toStringAsFixed(0)}%',
                      style: tt.bodySmall?.copyWith(
                          color: KholoColors.plum, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 10,
                  backgroundColor: KholoColors.lavenderLight,
                  valueColor: const AlwaysStoppedAnimation<Color>(KholoColors.wine),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Error message
            if (_errorMsg != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE8E8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: KholoColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_errorMsg!,
                            style: tt.bodySmall?.copyWith(color: KholoColors.error))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action buttons
            Row(
              children: [
                if (!widget.update.forceUpdate)
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _phase == _Phase.downloading ? null : () => Navigator.pop(context),
                      child: const Text('Later'),
                    ),
                  ),
                if (!widget.update.forceUpdate) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _phase == _Phase.downloading ? null : _startDownload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KholoColors.wine,
                      foregroundColor: Colors.white,
                    ),
                    child: _phase == _Phase.downloading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Update Now'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startDownload() async {
    setState(() {
      _phase = _Phase.downloading;
      _progress = 0;
      _errorMsg = null;
    });

    final path = await UpdateService.downloadApk(
      widget.update.apkUrl,
      onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      },
    );

    if (!mounted) return;

    if (path == null) {
      setState(() {
        _phase = _Phase.error;
        _errorMsg = 'Download failed. Check your connection and try again.';
      });
      return;
    }

    setState(() => _phase = _Phase.installing);
    await UpdateService.installApk(path);

    if (mounted) Navigator.pop(context);
  }
}

enum _Phase { idle, downloading, installing, error }
