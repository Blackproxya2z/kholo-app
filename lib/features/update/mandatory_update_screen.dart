import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/colors.dart';
import '../../core/models/app_update.dart';
import '../../core/services/update_service.dart';

/// ─── PREMIUM MANDATORY VERSION MIGRATION & FORCE UPDATE SCREEN ─────────────
///
/// Displayed when a user's installed version falls below the minimum required
/// version or when remote admin triggers a mandatory migration campaign.
/// ────────────────────────────────────────────────────────────────────────────
class MandatoryUpdateScreen extends StatefulWidget {
  const MandatoryUpdateScreen({
    super.key,
    required this.update,
    required this.currentVersionCode,
    this.currentVersionName = '1.0.0',
  });

  final AppUpdate update;
  final int currentVersionCode;
  final String currentVersionName;

  @override
  State<MandatoryUpdateScreen> createState() => _MandatoryUpdateScreenState();
}

enum _UpdatePhase { idle, downloading, verifying, readyToInstall, error }

class _MandatoryUpdateScreenState extends State<MandatoryUpdateScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  _UpdatePhase _phase = _UpdatePhase.idle;
  double _downloadProgress = 0.0;
  String _statusMessage = '';
  String? _stagedFilePath;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _startUpdateFlow() async {
    HapticFeedback.heavyImpact();
    setState(() {
      _phase = _UpdatePhase.downloading;
      _downloadProgress = 0.0;
      _statusMessage = 'Connecting to secure KHOLO update server...';
      _errorMessage = null;
    });

    try {
      final filePath = await UpdateService.downloadApk(
        widget.update.effectiveApkUrl,
        mirrorUrls: widget.update.mirrorUrls,
        expectedSha256: widget.update.apkSha256,
        expectedFileSize: widget.update.fileSize,
        targetVersion: widget.update.latestVersion,
        targetVersionCode: widget.update.versionCode,
        onProgress: (prog) {
          if (mounted) {
            setState(() {
              _downloadProgress = prog;
              _statusMessage = 'Downloading update: ${(prog * 100).toInt()}%';
            });
          }
        },
        onStatusChange: (status) {
          if (mounted) {
            setState(() {
              _statusMessage = status;
              if (status.contains('Verifying')) {
                _phase = _UpdatePhase.verifying;
              }
            });
          }
        },
      );

      setState(() {
        _phase = _UpdatePhase.readyToInstall;
        _stagedFilePath = filePath;
        _statusMessage = 'Update verified. Opening installer...';
      });

      await Future.delayed(const Duration(milliseconds: 600));
      await _installStagedApk();
    } on SecurityIntegrityException catch (e) {
      if (mounted) {
        setState(() {
          _phase = _UpdatePhase.error;
          _errorMessage = e.message;
        });
      }
    } on UpdateDownloadException catch (e) {
      if (mounted) {
        setState(() {
          _phase = _UpdatePhase.error;
          _errorMessage = e.userMessage;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _phase = _UpdatePhase.error;
          _errorMessage =
              'Update download failed. Please check your internet connection and try again.';
        });
      }
    }
  }

  Future<void> _installStagedApk() async {
    if (_stagedFilePath == null) return;
    HapticFeedback.mediumImpact();
    final success = await UpdateService.installApk(_stagedFilePath!);
    if (success) {
      await UpdateService.recordUpdateCompleted(widget.update.versionCode);
    } else if (mounted) {
      setState(() {
        _phase = _UpdatePhase.readyToInstall;
        _statusMessage = 'Tap "Install Update" to continue.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: context.kCanvas,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            children: [
              const SizedBox(height: 12),

              // Glowing Shield / Update Badge
              Center(
                child: AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, child) {
                    final scale = 1.0 + (_pulseCtrl.value * 0.06);
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [KholoColors.wine, KholoColors.magenta],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: KholoColors.magenta
                                  .withValues(alpha: 0.35 * _pulseCtrl.value),
                              blurRadius: 28,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.system_security_update_good_rounded,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                widget.update.updateTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: context.kInk,
                  height: 1.25,
                ),
              ),

              const SizedBox(height: 10),

              // Message
              Text(
                widget.update.updateMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: context.kInkMuted,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 20),

              // Version Comparison Pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: context.kCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.kDivider),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Your version: v${widget.currentVersionName}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: context.kInkMuted,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward_rounded,
                          size: 14,
                          color: context.isDark
                              ? KholoColors.magenta
                              : KholoColors.plum),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: KholoColors.wine,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'New: v${widget.update.latestVersion}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (widget.update.formattedFileSize != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(${widget.update.formattedFileSize})',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: context.isDark
                              ? KholoColors.blush
                              : KholoColors.plum,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Benefits of Updating Section
              Text(
                'Key Improvements & Security',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.kInk,
                ),
              ),
              const SizedBox(height: 12),

              ...widget.update.benefits.map((benefit) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: context.isDark
                                ? const Color(0xFF1B3820)
                                : const Color(0xFFE8F5E9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 12,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            benefit,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: context.kInk,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),

              const SizedBox(height: 16),

              // What's New Release Notes Box
              if (widget.update.releaseNotes.isNotEmpty) ...[
                Text(
                  "What's New in KHOLO",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.kInk,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.kCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.kDivider),
                  ),
                  child: Text(
                    widget.update.releaseNotes,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: context.kInkMuted,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Download / Progress / Error Area
              if (_phase == _UpdatePhase.downloading ||
                  _phase == _UpdatePhase.verifying) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.kCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.kDivider),
                  ),
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                        value: _phase == _UpdatePhase.verifying
                            ? null
                            : _downloadProgress,
                        backgroundColor: context.kTint(KholoColors.magenta,
                            lightAlpha: 0.15, darkAlpha: 0.25),
                        valueColor: const AlwaysStoppedAnimation(
                            KholoColors.magenta),
                        borderRadius: BorderRadius.circular(8),
                        minHeight: 8,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _statusMessage,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.isDark
                              ? KholoColors.magenta
                              : KholoColors.wine,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (_phase == _UpdatePhase.error && _errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.isDark
                        ? const Color(0xFF381515)
                        : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: context.isDark
                          ? const Color(0xFF5E1B1B)
                          : const Color(0xFFFFCDD2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off_rounded,
                          color: KholoColors.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
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

              // CTA Action Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: (_phase == _UpdatePhase.downloading ||
                          _phase == _UpdatePhase.verifying)
                      ? null
                      : (_phase == _UpdatePhase.readyToInstall
                          ? _installStagedApk
                          : _startUpdateFlow),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.isDark
                        ? KholoColors.magenta
                        : KholoColors.plum,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shadowColor: KholoColors.wine.withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _phase == _UpdatePhase.readyToInstall
                            ? Icons.install_mobile_rounded
                            : Icons.upgrade_rounded,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _phase == _UpdatePhase.readyToInstall
                            ? 'Install Update'
                            : (_phase == _UpdatePhase.error
                                ? 'Retry Download'
                                : 'Update Now'),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Trust & Data Safety Footnote
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline_rounded,
                      size: 14, color: context.kInkSubtle),
                  const SizedBox(width: 6),
                  Text(
                    'All your cycle, baby, and health logs remain 100% safe.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: context.kInkSubtle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
