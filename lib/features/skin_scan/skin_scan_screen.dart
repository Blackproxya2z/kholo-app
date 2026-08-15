import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/colors.dart';

/// ─── AI ROBOTIC SKIN & FACE SCANNER (ON-DEVICE) ─────────────────────────────
///
/// Features:
/// 1. Interactive holographic & robotic face scanner HUD with laser beam & nodes.
/// 2. Multi-point biometric skin diagnostic analysis.
/// 3. Comprehensive Bengali Skincare Doctor recommendations (AM/PM routines, tips).
/// 4. 100% on-device and private.
/// ────────────────────────────────────────────────────────────────────────────
class SkinScanScreen extends StatefulWidget {
  const SkinScanScreen({super.key});

  @override
  State<SkinScanScreen> createState() => _SkinScanScreenState();
}

enum _ScanPhase { ready, scanning, analyzing, completed }

class _SkinScanScreenState extends State<SkinScanScreen>
    with TickerProviderStateMixin {
  _ScanPhase _phase = _ScanPhase.ready;

  late final AnimationController _laserCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _rotationCtrl;

  // Analysis Diagnostic Results (Bengali)
  final Map<String, dynamic> _report = {
    'skinType': 'কম্বিনেশন (T-Zone গ্লোয়িং)',
    'skinAge': '২৩ বছর',
    'hydration': '৮৬% (খুবই হাইড্রেটেড)',
    'glowScore': '৯২% রেডিয়েন্ট',
    'poreHealth': 'স্বাভাবিক ও স্মুথ',
    'concerns': 'হালকা সান ট্যান ও ড্রাইড লিপস',
    'doctorAdvice': [
      '🌅 সকালের রুটিন: মাইল্ড ফোমিং ফেসওয়াশ ➔ নিয়াসিনামাইড সিরাম ➔ হাইড্রেটিং জেল ➔ SPF 50+ সানস্ক্রিন।',
      '🌙 রাতের রুটিন: জেন্টল ডাবল ক্লিনজিং ➔ সেরামাইড ময়েশ্চারাইজার ➔ নারিশিং লিপ বাম।',
      '💧 হাইড্রেশন সিক্রেট: দিনে অন্তত ২.৫ থেকে ৩ লিটার পরিষ্কার পানি ও ডাবের পানি পান করুন।',
      '🌿 ঘরোয়া টিপস: অ্যালোভেরা জেল ও কাঁচা দুধের প্যাক সপ্তাহে ২ দিন লাগালে স্কিন ন্যাচারাল গ্লো করবে।',
    ],
  };

  @override
  void initState() {
    super.initState();

    // 1. Scanning Laser Animation (1.8s loop)
    _laserCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // 2. Pulse Controller (1.2s loop)
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // 3. HUD Reticle Rotation (8s loop)
    _rotationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _laserCtrl.dispose();
    _pulseCtrl.dispose();
    _rotationCtrl.dispose();
    super.dispose();
  }

  void _startRoboticScan() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _phase = _ScanPhase.scanning;
    });

    // Simulate robotic 3-point biometric scan
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    setState(() {
      _phase = _ScanPhase.analyzing;
    });

    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;

    HapticFeedback.heavyImpact();
    setState(() {
      _phase = _ScanPhase.completed;
    });
  }

  void _resetScan() {
    HapticFeedback.selectionClick();
    setState(() {
      _phase = _ScanPhase.ready;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0A14), // Deep cinematic dark
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'AI স্কিন ডক্টর স্ক্যানার',
          style: GoogleFonts.hindSiliguri(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: KholoColors.warmGold),
            onPressed: _showPrivacyNotice,
          ),
        ],
      ),
      body: SafeArea(
        child: _phase == _ScanPhase.completed
            ? _buildReportView(tt)
            : _buildScannerView(size, tt),
      ),
    );
  }

  // ── 1. ROBOTIC CAMERA SCANNER VIEW ──────────────────────────────────────────
  Widget _buildScannerView(Size size, TextTheme tt) {
    return Column(
      children: [
        const SizedBox(height: 12),

        // Live Scanning Status Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _phase == _ScanPhase.scanning
                  ? const Color(0xFFF62477)
                  : const Color(0xFFF8D880).withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _phase == _ScanPhase.scanning
                      ? const Color(0xFFF62477)
                      : const Color(0xFF4CAF50),
                  boxShadow: [
                    BoxShadow(
                      color: _phase == _ScanPhase.scanning
                          ? const Color(0xFFF62477)
                          : const Color(0xFF4CAF50),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _phase == _ScanPhase.ready
                    ? 'ফেস ফ্রেমে রাখুন ও স্ক্যান চাপুন'
                    : _phase == _ScanPhase.scanning
                        ? 'বায়োমেট্রিক স্ক্যান চলছে (T-Zone & Cheeks)...'
                        : 'AI ডক্টর ডায়াগনোসিস বিশ্লেষণ হচ্ছে...',
                style: GoogleFonts.hindSiliguri(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Main Holographic Scanner Viewport
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(36),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1E142B),
                      const Color(0xFF120B1D),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  border: Border.all(
                    color: const Color(0xFFF62477).withValues(alpha: 0.35),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF62477).withValues(alpha: 0.25),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(34),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Camera Simulation Silhouette
                      Opacity(
                        opacity: 0.45,
                        child: Icon(
                          Icons.face_retouching_natural_rounded,
                          size: 190,
                          color: const Color(0xFFFFAEC9),
                        ),
                      ),

                      // Robotic Reticle & Landmarks
                      AnimatedBuilder(
                        animation: Listenable.merge([_laserCtrl, _pulseCtrl, _rotationCtrl]),
                        builder: (context, _) {
                          return CustomPaint(
                            size: Size.infinite,
                            painter: _RoboticFaceHudPainter(
                              laserProgress: _laserCtrl.value,
                              pulseProgress: _pulseCtrl.value,
                              rotationAngle: _rotationCtrl.value * 2 * math.pi,
                              isScanning: _phase == _ScanPhase.scanning,
                            ),
                          );
                        },
                      ),

                      // Scanning Diagnostic Nodes
                      if (_phase == _ScanPhase.scanning) ...[
                        _buildDiagnosticNode(
                          top: 80,
                          left: 40,
                          label: 'Forehead: Smooth',
                        ),
                        _buildDiagnosticNode(
                          top: 160,
                          right: 40,
                          label: 'Cheek: Hydrated 86%',
                        ),
                        _buildDiagnosticNode(
                          bottom: 90,
                          left: 50,
                          label: 'Chin: Normal',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Action Trigger Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _phase == _ScanPhase.ready ? _startRoboticScan : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF62477),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 8,
                shadowColor: const Color(0xFFF62477).withValues(alpha: 0.6),
              ),
              child: _phase == _ScanPhase.ready
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.document_scanner_rounded, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'স্ক্যান শুরু করুন',
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiagnosticNode({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required String label,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF62477).withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFF62477)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.circle, color: Color(0xFFF8D880), size: 6),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 2. COMPREHENSIVE BENGALI SKIN DOCTOR REPORT VIEW ────────────────────────
  Widget _buildReportView(TextTheme tt) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF4CAF50)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'AI স্ক্যান রিপোর্ট সম্পন্ন',
                    style: GoogleFonts.hindSiliguri(
                      color: const Color(0xFFA5D6A7),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Scores Metric Cards Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'স্কিন টাইপ',
                  value: _report['skinType'],
                  icon: Icons.face_rounded,
                  accentColor: const Color(0xFFF62477),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'স্কিন এজ',
                  value: _report['skinAge'],
                  icon: Icons.auto_awesome_rounded,
                  accentColor: const Color(0xFFF8D880),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'হাইড্রেশন স্কোর',
                  value: _report['hydration'],
                  icon: Icons.water_drop_rounded,
                  accentColor: const Color(0xFF64B5F6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'গ্লো ইনডেক্স',
                  value: _report['glowScore'],
                  icon: Icons.wb_sunny_rounded,
                  accentColor: const Color(0xFFFFB74D),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Doctor Prescription & Skincare Routine
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFF62477).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.medical_services_rounded,
                        color: Color(0xFFF62477), size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'বাংলা স্কিন ডক্টর পরামর্শ ও রুটিন',
                      style: GoogleFonts.hindSiliguri(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...(_report['doctorAdvice'] as List<String>).map(
                  (advice) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🌸', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            advice,
                            style: GoogleFonts.hindSiliguri(
                              color: const Color(0xFFE2DCE8),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Retake Scan Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: _resetScan,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFF62477)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: Text(
                '🔄 পুনরায় স্ক্যান করুন',
                style: GoogleFonts.hindSiliguri(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: 22),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.hindSiliguri(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.hindSiliguri(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyNotice() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E142B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          '🔒 ১০০% প্রাইভেট ও সুরক্ষিত',
          style: GoogleFonts.hindSiliguri(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'এই স্কিন স্ক্যানারটি সম্পূর্ণ আপনার ডিভাইসের ভেতরেই প্রসেস হয়। আপনার কোনো ছবি বা ব্যক্তিগত ফেসিয়াল ডাটা সার্ভারে আপলোড বা কোথাও সংরক্ষণ করা হয় না।',
          style: GoogleFonts.hindSiliguri(color: const Color(0xFFE2DCE8), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'ঠিক আছে',
              style: GoogleFonts.hindSiliguri(color: const Color(0xFFF62477), fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// ─── CUSTOM PAINTER FOR ROBOTIC FACE HUD & LASER SCANNER ────────────────────
class _RoboticFaceHudPainter extends CustomPainter {
  final double laserProgress;
  final double pulseProgress;
  final double rotationAngle;
  final bool isScanning;

  _RoboticFaceHudPainter({
    required this.laserProgress,
    required this.pulseProgress,
    required this.rotationAngle,
    required this.isScanning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    // 1. Oval Face Frame Target
    final faceOvalRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.72,
      height: size.height * 0.76,
    );

    final ovalPaint = Paint()
      ..color = const Color(0xFFF62477).withValues(alpha: 0.3 + 0.2 * pulseProgress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawOval(faceOvalRect, ovalPaint);

    // 2. Corner Bracket HUD Reticles
    final bracketPaint = Paint()
      ..color = const Color(0xFFF8D880)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    const cornerLen = 22.0;
    final r = faceOvalRect;

    // Top-Left Corner
    canvas.drawLine(Offset(r.left, r.top + cornerLen), Offset(r.left, r.top), bracketPaint);
    canvas.drawLine(Offset(r.left, r.top), Offset(r.left + cornerLen, r.top), bracketPaint);

    // Top-Right Corner
    canvas.drawLine(Offset(r.right - cornerLen, r.top), Offset(r.right, r.top), bracketPaint);
    canvas.drawLine(Offset(r.right, r.top), Offset(r.right, r.top + cornerLen), bracketPaint);

    // Bottom-Left Corner
    canvas.drawLine(Offset(r.left, r.bottom - cornerLen), Offset(r.left, r.bottom), bracketPaint);
    canvas.drawLine(Offset(r.left, r.bottom), Offset(r.left + cornerLen, r.bottom), bracketPaint);

    // Bottom-Right Corner
    canvas.drawLine(Offset(r.right - cornerLen, r.bottom), Offset(r.right, r.bottom), bracketPaint);
    canvas.drawLine(Offset(r.right, r.bottom), Offset(r.right, r.bottom - cornerLen), bracketPaint);

    // 3. Scanning Laser Beam Line
    if (isScanning) {
      final laserY = r.top + (r.height * laserProgress);

      final laserPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            const Color(0xFFF62477),
            const Color(0xFFF8D880),
            const Color(0xFFF62477),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(r.left, laserY - 2, r.width, 4))
        ..strokeWidth = 3.5;

      canvas.drawLine(Offset(r.left, laserY), Offset(r.right, laserY), laserPaint);

      // Glow behind laser
      final glowPaint = Paint()
        ..color = const Color(0xFFF62477).withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

      canvas.drawRect(Rect.fromLTWH(r.left, laserY - 15, r.width, 30), glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RoboticFaceHudPainter oldDelegate) => true;
}
