import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/colors.dart';
import '../../core/models/app_update.dart';
import '../../core/services/update_service.dart';

/// ─── PREMIUM KHOLO IN-APP UPDATE EXPERIENCE ─────────────────────────────────
///
/// Features:
/// 1. Supports both Optional (Dismissible with "Later") and Mandatory (Force Update) flows.
/// 2. Branded KHOLO luxury theme: Blush, Wine, Terracotta, Sage, Warm Gold, Oatmeal.
/// 3. Categorized What's New Section: New Features, Improvements, Bug Fixes.
/// 4. Live Resumable APK Download Manager with percentage and MB progress.
/// 5. Streaming SHA-256 Anti-Tamper Verification with green verified badge.
/// 6. Automatic APK installer launch & Zero Data Loss guarantee.
/// ────────────────────────────────────────────────────────────────────────────
class MandatoryUpdateScreen extends StatefulWidget {
  const MandatoryUpdateScreen({
    super.key,
    this.update,
    this.currentVersionCode,
    this.currentVersionName,
  });

  final AppUpdate? update;
  final int? currentVersionCode;
  final String? currentVersionName;

  @override
  State<MandatoryUpdateScreen> createState() => _MandatoryUpdateScreenState();
}

enum _UpdatePhase {
  idle,
  downloading,
  verifying,
  readyToInstall,
  installing,
  error,
}

class _MandatoryUpdateScreenState extends State<MandatoryUpdateScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  _UpdatePhase _phase = _UpdatePhase.idle;
  double _downloadProgress = 0.0;
  String _statusMessage = '';
  String? _stagedFilePath;
  String? _errorMessage;

  late AppUpdate _effectiveUpdate;
  late int _effectiveCurrentCode;
  late String _effectiveCurrentName;

  bool get _isMandatory => _effectiveUpdate.isMandatory(_effectiveCurrentCode);

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _effectiveUpdate = widget.update ??
        const AppUpdate(
          latestVersion: '1.3.0',
          versionCode: 20,
          releaseNotes:
              '🌸 নতুন ফিচার, পারফরম্যান্স ও সিকিউরিটি আপগ্রেড সহ KHOLO এর লেটেস্ট ভার্সন।',
          apkUrl:
              'https://github.com/Blackproxya2z/kholo-app/releases/download/v1.3.0/app-release.apk',
          forceUpdate: false,
        );
    _effectiveCurrentCode = widget.currentVersionCode ?? 20;
    _effectiveCurrentName = widget.currentVersionName ?? '1.3.0';

    _resolveLatestUpdateDetails();
  }

  Future<void> _resolveLatestUpdateDetails() async {
    try {
      final code = await UpdateService.currentVersionCode();
      final name = await UpdateService.currentVersionName();
      final latest = await UpdateService.checkForUpdate();
      if (mounted) {
        setState(() {
          _effectiveCurrentCode = code;
          _effectiveCurrentName = name;
          if (latest != null) {
            _effectiveUpdate = latest;
          }
        });
      }
    } catch (_) {}
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
        _effectiveUpdate.effectiveApkUrl,
        mirrorUrls: _effectiveUpdate.mirrorUrls,
        expectedSha256: _effectiveUpdate.apkSha256,
        expectedFileSize: _effectiveUpdate.fileSize,
        targetVersion: _effectiveUpdate.latestVersion,
        targetVersionCode: _effectiveUpdate.versionCode,
        onProgress: (prog) {
          if (mounted) {
            setState(() {
              _downloadProgress = prog;
              final percent = (prog * 100).toInt();
              if (_effectiveUpdate.fileSize != null && _effectiveUpdate.fileSize! > 0) {
                final downloadedMb = (prog * _effectiveUpdate.fileSize! / (1024 * 1024)).toStringAsFixed(1);
                final totalMb = (_effectiveUpdate.fileSize! / (1024 * 1024)).toStringAsFixed(1);
                _statusMessage = 'Downloading: $downloadedMb MB / $totalMb MB ($percent%)';
              } else {
                _statusMessage = 'Downloading update: $percent%';
              }
            });
          }
        },
        onStatusChange: (status) {
          if (mounted) {
            setState(() {
              _statusMessage = status;
              if (status.contains('Verifying') || status.contains('signature')) {
                _phase = _UpdatePhase.verifying;
              }
            });
          }
        },
      );

      if (!mounted) return;

      setState(() {
        _phase = _UpdatePhase.readyToInstall;
        _stagedFilePath = filePath;
        _statusMessage = 'Update verified. Ready to install.';
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _phase = _UpdatePhase.error;
          _errorMessage =
              'Update download failed. Please check your internet connection and try again.\n(Error: ${e.toString()})';
        });
      }
    }
  }

  Future<void> _installStagedApk() async {
    if (_stagedFilePath == null) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _phase = _UpdatePhase.installing;
      _statusMessage = 'Launching Android Package Installer...';
    });

    final success = await UpdateService.installApk(_stagedFilePath!);
    if (success) {
      await UpdateService.recordUpdateCompleted(_effectiveUpdate.versionCode);
    }

    if (mounted) {
      setState(() {
        _phase = _UpdatePhase.readyToInstall;
        _statusMessage = 'Tap "Install Update" if installer was closed.';
      });
    }
  }

  void _onDismissOrLater() {
    if (_isMandatory) return;
    HapticFeedback.selectionClick();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/app');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isMandatory &&
          _phase != _UpdatePhase.downloading &&
          _phase != _UpdatePhase.verifying,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_isMandatory) {
          _onDismissOrLater();
        }
      },
      child: Scaffold(
        backgroundColor: context.kCanvas,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: !_isMandatory
              ? IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: context.kInk,
                    size: 20,
                  ),
                  onPressed: (_phase == _UpdatePhase.downloading ||
                          _phase == _UpdatePhase.verifying)
                      ? null
                      : _onDismissOrLater,
                  tooltip: 'Back',
                )
              : null,
          title: Text(
            _isMandatory ? 'Critical Update Required' : 'Software Update',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.kInk,
            ),
          ),
          centerTitle: true,
          actions: [
            if (!_isMandatory)
              TextButton(
                onPressed: (_phase == _UpdatePhase.downloading ||
                        _phase == _UpdatePhase.verifying)
                    ? null
                    : _onDismissOrLater,
                child: Text(
                  'Later',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.kInkMuted,
                  ),
                ),
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            children: [
              // ── HERO BADGE WITH SMOOTH LOTUS GLOW ──────────────────────────
              Center(
                child: AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, child) {
                    final scale = 1.0 + (_pulseCtrl.value * 0.05);
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: _phase == _UpdatePhase.readyToInstall
                                ? const [Color(0xFF2E7D32), Color(0xFF4CAF50)]
                                : [KholoColors.wine, KholoColors.magenta],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_phase == _UpdatePhase.readyToInstall
                                      ? const Color(0xFF4CAF50)
                                      : KholoColors.magenta)
                                  .withValues(alpha: 0.35 * _pulseCtrl.value),
                              blurRadius: 26,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          _phase == _UpdatePhase.readyToInstall
                              ? Icons.verified_rounded
                              : Icons.system_security_update_good_rounded,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // ── HEADLINE & INTRO ──────────────────────────────────────────
              Text(
                _effectiveUpdate.updateTitle.isNotEmpty
                    ? _effectiveUpdate.updateTitle
                    : (_isMandatory
                        ? 'Mandatory Security & Health Upgrade'
                        : 'A Refined KHOLO Experience'),
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  color: context.kInk,
                  height: 1.25,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                _effectiveUpdate.updateMessage.isNotEmpty
                    ? _effectiveUpdate.updateMessage
                    : 'Experience enhanced cycle insights, AI skin companion speed, and upgraded on-device privacy.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: context.kInkMuted,
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 18),

              // ── VERSION COMPARISON & FILE SIZE PILL ────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: context.kCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: context.kDivider),
                  boxShadow: [
                    BoxShadow(
                      color: context.isDark
                          ? Colors.black.withValues(alpha: 0.25)
                          : KholoColors.wine.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text(
                          'Installed',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: context.kInkSubtle,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'v$_effectiveCurrentName ($_effectiveCurrentCode)',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.kInkMuted,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: context.isDark
                            ? KholoColors.magenta
                            : KholoColors.plum,
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          'Available Build',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: context.isDark
                                ? KholoColors.blush
                                : KholoColors.wine,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: KholoColors.wine,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'v${_effectiveUpdate.latestVersion} (${_effectiveUpdate.versionCode})',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_effectiveUpdate.formattedFileSize != null) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.isDark
                              ? context.kCardElevated
                              : KholoColors.warmGold.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _effectiveUpdate.formattedFileSize!,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: context.isDark
                                ? KholoColors.warmGold
                                : const Color(0xFF8D5B00),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ── SHA-256 ANTI-TAMPER BADGE ──────────────────────────────────
              if (_effectiveUpdate.apkSha256 != null && _effectiveUpdate.apkSha256!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: Color(0xFF4CAF50), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Official Signed Release • SHA-256 Cryptographic Tamper Protection',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // ── CATEGORIZED WHAT'S NEW SECTION ─────────────────────────────
              _buildCategoryCard(
                title: '🌟 New Features & Capabilities',
                color: KholoColors.wine,
                items: [
                  'AI Skin Wellness Scanner with zero-latency face alignment',
                  'Interactive Baby Growth milestones & feeding rhythm trackers',
                  'Dynamic Phase Advice with clinical nutrition recommendations',
                ],
              ),

              const SizedBox(height: 12),

              _buildCategoryCard(
                title: '⚡ Performance & Smoothness',
                color: const Color(0xFFE07A5F), // Terracotta
                items: [
                  'Resumable multi-threaded chunked downloads with auto-reconnect',
                  'Ultra-smooth blooming animations optimized for low-power mode',
                  'Near-instant startup and zero redundant network polling',
                ],
              ),

              const SizedBox(height: 12),

              _buildCategoryCard(
                title: '🛡️ Privacy & Security Enhancements',
                color: const Color(0xFF819B88), // Sage
                items: [
                  '100% on-device private health storage (zero PHI in cloud)',
                  'Android 14/15 modern permissions and edge-to-edge support',
                  'Automatic stale cache cleanup & encrypted integrity checks',
                ],
              ),

              // ── RELEASE NOTES SUMMARY ──────────────────────────────────────
              if (_effectiveUpdate.releaseNotes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.kCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.kDivider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Release Notes',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: context.kInkSubtle,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _effectiveUpdate.releaseNotes,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: context.kInkMuted,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 22),

              // ── LIVE DOWNLOAD PROGRESS / STATUS AREA ───────────────────────
              if (_phase == _UpdatePhase.downloading ||
                  _phase == _UpdatePhase.verifying ||
                  _phase == _UpdatePhase.readyToInstall ||
                  _phase == _UpdatePhase.installing) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.kCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _phase == _UpdatePhase.readyToInstall
                          ? const Color(0xFF4CAF50)
                          : KholoColors.magenta.withValues(alpha: 0.4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: KholoColors.magenta.withValues(alpha: 0.08),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _phase == _UpdatePhase.readyToInstall
                                ? 'Download Complete ✓'
                                : (_phase == _UpdatePhase.verifying
                                    ? 'Verifying Signature...'
                                    : 'Downloading Update...'),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _phase == _UpdatePhase.readyToInstall
                                  ? const Color(0xFF2E7D32)
                                  : context.kInk,
                            ),
                          ),
                          if (_phase == _UpdatePhase.downloading)
                            Text(
                              '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: KholoColors.wine,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _phase == _UpdatePhase.downloading
                              ? _downloadProgress
                              : (_phase == _UpdatePhase.readyToInstall ? 1.0 : null),
                          minHeight: 8,
                          backgroundColor: context.isDark
                              ? context.kCardElevated
                              : KholoColors.blush.withValues(alpha: 0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _phase == _UpdatePhase.readyToInstall
                                ? const Color(0xFF4CAF50)
                                : KholoColors.magenta,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _statusMessage,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: context.kInkMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── ERROR MESSAGE BOX ──────────────────────────────────────────
              if (_phase == _UpdatePhase.error && _errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.isDark
                        ? const Color(0xFF3B1824)
                        : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF87171)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.wifi_off_rounded, color: KholoColors.error, size: 20),
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

              // ── ACTION BUTTONS ─────────────────────────────────────────────
              Row(
                children: [
                  if (!_isMandatory) ...[
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: (_phase == _UpdatePhase.downloading ||
                                  _phase == _UpdatePhase.verifying)
                              ? null
                              : _onDismissOrLater,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: context.kDivider),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Later',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: context.kInkMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: _isMandatory ? 1 : 2,
                    child: SizedBox(
                      height: 52,
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
                              : KholoColors.wine,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shadowColor: KholoColors.wine.withValues(alpha: 0.35),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: (_phase == _UpdatePhase.downloading ||
                                _phase == _UpdatePhase.verifying)
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _phase == _UpdatePhase.readyToInstall
                                        ? Icons.install_mobile_rounded
                                        : Icons.upgrade_rounded,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _phase == _UpdatePhase.readyToInstall
                                        ? 'Install Update'
                                        : (_phase == _UpdatePhase.error
                                            ? 'Retry Download'
                                            : (_isMandatory
                                                ? 'Update Now (Required)'
                                                : 'Update Now')),
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── DATA PRESERVATION GUARANTEE ────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline_rounded, size: 14, color: context.kInkSubtle),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Zero Data Loss: Your cycle logs, baby logs, and health profile remain 100% safe.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: context.kInkSubtle,
                      ),
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

  Widget _buildCategoryCard({
    required String title,
    required Color color,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.kDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.kInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2, right: 8),
                    child: Icon(Icons.check_circle_rounded, size: 13, color: color),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: context.kInkMuted,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
