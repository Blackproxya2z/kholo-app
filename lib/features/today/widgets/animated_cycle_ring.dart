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

  (Color primary, Color secondary, Color glow) _getPhaseColors(BuildContext context) {
    final dark = context.isDark;
    switch (widget.phase) {
      case CyclePhase.menstrual:
        return (
          KholoColors.magenta,
          dark ? KholoColors.blush : KholoColors.wine,
          dark ? KholoColors.magenta.withValues(alpha: 0.35) : KholoColors.blush.withValues(alpha: 0.45)
        );
      case CyclePhase.follicular:
        return (
          dark ? KholoColors.magenta : KholoColors.lavender,
          dark ? KholoColors.blush : KholoColors.plum,
          dark ? KholoColors.magenta.withValues(alpha: 0.25) : KholoColors.lavenderLight
        );
      case CyclePhase.ovulation:
        return (
          KholoColors.plum,
          dark ? KholoColors.blush : KholoColors.wine,
          dark ? KholoColors.wine.withValues(alpha: 0.4) : KholoColors.blush.withValues(alpha: 0.4)
        );
      case CyclePhase.luteal:
        return (
          KholoColors.warmGold,
          dark ? KholoColors.warmGold : KholoColors.tertiaryDark,
          dark ? KholoColors.warmGold.withValues(alpha: 0.25) : KholoColors.tertiaryLight
        );
      case CyclePhase.unknown:
        return (
          context.kInkMuted,
          context.kInk,
          context.kCardElevated
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getPhaseColors(context);
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
                  color: colors.$3,
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
                    trackColor: context.isDark
                        ? context.kCardElevated
                        : context.kDivider.withValues(alpha: 0.6),
                  ),
                ),

                // Inner content
                Container(
                  width: 176,
                  height: 176,
                  decoration: BoxDecoration(
                    color: context.kCard,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.kDivider),
                    boxShadow: [
                      BoxShadow(
                        color: colors.$1.withValues(alpha: context.isDark ? 0.18 : 0.08),
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
                          color: context.kInkSubtle,
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
                          color: colors.$1.withValues(alpha: context.isDark ? 0.25 : 0.15),
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
                        style: TextStyle(
                          fontSize: 11,
                          color: context.kInkMuted,
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
  final Color trackColor;

  _CycleRingPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 24) / 2;
    const strokeWidth = 14.0;

    // Background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // Progress Arc with Gradient
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: 3 * math.pi / 2,
      colors: [primaryColor, secondaryColor, primaryColor],
      stops: const [0.0, 0.5, 1.0],
      transform: const GradientRotation(-math.pi / 2),
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      rect,
      -math.pi / 2, // Start at 12 o'clock
      sweepAngle,
      false,
      progressPaint,
    );

    // Glowing tip indicator
    final tipAngle = -math.pi / 2 + sweepAngle;
    final tipCenter = Offset(
      center.dx + radius * math.cos(tipAngle),
      center.dy + radius * math.sin(tipAngle),
    );

    final tipPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final tipShadow = Paint()
      ..color = primaryColor.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawCircle(tipCenter, 7, tipShadow);
    canvas.drawCircle(tipCenter, 5, tipPaint);
  }

  @override
  bool shouldRepaint(covariant _CycleRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.trackColor != trackColor;
  }
}
