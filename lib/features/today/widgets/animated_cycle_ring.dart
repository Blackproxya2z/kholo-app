import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/colors.dart';
import '../../../core/models/health_profile.dart';

/// Real-time animated cycle ring dashboard reflecting the current phase.
class AnimatedCycleRing extends StatefulWidget {
  final int currentDay;
  final int totalDays;
  final CyclePhase phase;
  final String phaseName;
  final String phaseDescription;
  final VoidCallback? onTap;

  const AnimatedCycleRing({
    super.key,
    required this.currentDay,
    required this.totalDays,
    required this.phase,
    required this.phaseName,
    required this.phaseDescription,
    this.onTap,
  });

  @override
  State<AnimatedCycleRing> createState() => _AnimatedCycleRingState();
}

class _AnimatedCycleRingState extends State<AnimatedCycleRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  (Color primary, Color secondary, Color glow) _getPhaseColors() {
    switch (widget.phase) {
      case CyclePhase.menstrual:
        return (KholoColors.magenta, KholoColors.wine, KholoColors.blush);
      case CyclePhase.follicular:
        return (KholoColors.lavender, KholoColors.plum, KholoColors.lavenderLight);
      case CyclePhase.ovulation:
        return (KholoColors.plum, KholoColors.wine, KholoColors.blush);
      case CyclePhase.luteal:
        return (KholoColors.warmGold, KholoColors.tertiaryDark, KholoColors.tertiaryLight);
      case CyclePhase.unknown:
        return (KholoColors.inkMuted, KholoColors.inkSubtle, KholoColors.cream);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getPhaseColors();
    final progress = (widget.totalDays > 0)
        ? (widget.currentDay / widget.totalDays).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: widget.onTap,
      child: Center(
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: child,
            );
          },
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors.$3.withValues(alpha: 0.4),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Custom Painted Ring
                CustomPaint(
                  size: const Size(220, 220),
                  painter: _CycleRingPainter(
                    progress: progress,
                    primaryColor: colors.$1,
                    secondaryColor: colors.$2,
                  ),
                ),

                // Inner content
                Container(
                  width: 176,
                  height: 176,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colors.$1.withValues(alpha: 0.1),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'DAY',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.0,
                          color: KholoColors.inkSubtle,
                        ),
                      ),
                      Text(
                        '${widget.currentDay}',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: colors.$2,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: colors.$1.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.phaseName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colors.$2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'of ${widget.totalDays} days',
                        style: const TextStyle(
                          fontSize: 11,
                          color: KholoColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CycleRingPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;

  _CycleRingPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 24) / 2;
    const strokeWidth = 14.0;

    // Track Background
    final trackPaint = Paint()
      ..color = KholoColors.lavender.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Active Gradient Arc
    final sweepAngle = 2 * math.pi * progress;
    final arcPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: (3 * math.pi) / 2,
        colors: [primaryColor, secondaryColor, primaryColor],
        stops: const [0.0, 0.7, 1.0],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      arcPaint,
    );

    // Endpoint Indicator Glow Dot
    if (progress > 0.02) {
      final currentAngle = (-math.pi / 2) + sweepAngle;
      final dotOffset = Offset(
        center.dx + radius * math.cos(currentAngle),
        center.dy + radius * math.sin(currentAngle),
      );

      final glowPaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.4)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(dotOffset, strokeWidth * 0.9, glowPaint);

      final dotPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(dotOffset, strokeWidth * 0.45, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CycleRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor;
  }
}
