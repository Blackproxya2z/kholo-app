import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../app/theme/colors.dart';
import '../../../core/models/cycle_log.dart';

/// Fluid wave and particle animation reflecting menstrual flow intensity.
class LiquidFlowAnimation extends StatefulWidget {
  final FlowIntensity flow;
  final double height;

  const LiquidFlowAnimation({
    super.key,
    this.flow = FlowIntensity.medium,
    this.height = 90,
  });

  @override
  State<LiquidFlowAnimation> createState() => _LiquidFlowAnimationState();
}

class _LiquidFlowAnimationState extends State<LiquidFlowAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _durationForFlow(widget.flow),
    )..repeat();
  }

  @override
  void didUpdateWidget(LiquidFlowAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.flow != widget.flow) {
      _controller.duration = _durationForFlow(widget.flow);
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    }
  }

  Duration _durationForFlow(FlowIntensity flow) {
    switch (flow) {
      case FlowIntensity.spotting:
      case FlowIntensity.light:
        return const Duration(milliseconds: 3200);
      case FlowIntensity.medium:
        return const Duration(milliseconds: 2200);
      case FlowIntensity.heavy:
        return const Duration(milliseconds: 1400);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _LiquidWavePainter(
                progress: _controller.value,
                flow: widget.flow,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LiquidWavePainter extends CustomPainter {
  final double progress;
  final FlowIntensity flow;

  _LiquidWavePainter({
    required this.progress,
    required this.flow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final (primaryColor, secondaryColor, amplitude, waveCount) = _styleForFlow(flow);

    // Background soft tint
    final bgPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Wave 1 (Back wave)
    final wave1Paint = Paint()
      ..shader = LinearGradient(
        colors: [
          secondaryColor.withValues(alpha: 0.35),
          primaryColor.withValues(alpha: 0.25),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path1 = Path();
    path1.moveTo(0, size.height);

    final baseHeight = size.height * 0.52;
    for (double x = 0; x <= size.width; x += 1) {
      final y = baseHeight +
          math.sin((x / size.width * waveCount * 2 * math.pi) + (progress * 2 * math.pi)) *
              (amplitude * 0.8);
      path1.lineTo(x, y);
    }
    path1.lineTo(size.width, size.height);
    path1.close();
    canvas.drawPath(path1, wave1Paint);

    // Wave 2 (Front wave)
    final wave2Paint = Paint()
      ..shader = LinearGradient(
        colors: [
          primaryColor.withValues(alpha: 0.65),
          secondaryColor.withValues(alpha: 0.5),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x += 1) {
      final y = baseHeight + 8 +
          math.sin((x / size.width * waveCount * 2 * math.pi) - (progress * 2 * math.pi) + 1.2) *
              amplitude;
      path2.lineTo(x, y);
    }
    path2.lineTo(size.width, size.height);
    path2.close();
    canvas.drawPath(path2, wave2Paint);

    // Floating micro-bubbles
    final bubblePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    final bubbleOffsets = [
      Offset(size.width * 0.2, (size.height * 0.45 - (progress * 16)) % size.height),
      Offset(size.width * 0.55, (size.height * 0.6 - (progress * 24)) % size.height),
      Offset(size.width * 0.8, (size.height * 0.35 - (progress * 20)) % size.height),
    ];

    for (int i = 0; i < bubbleOffsets.length; i++) {
      final radius = (i == 1) ? 3.5 : 2.5;
      canvas.drawCircle(bubbleOffsets[i], radius, bubblePaint);
    }
  }

  (Color primary, Color secondary, double amplitude, double waveCount) _styleForFlow(FlowIntensity f) {
    switch (f) {
      case FlowIntensity.spotting:
      case FlowIntensity.light:
        return (KholoColors.blush, KholoColors.roseLight, 4.0, 1.5);
      case FlowIntensity.medium:
        return (KholoColors.rose, KholoColors.blush, 7.0, 2.0);
      case FlowIntensity.heavy:
        return (KholoColors.wine, KholoColors.magenta, 11.0, 2.5);
    }
  }

  @override
  bool shouldRepaint(covariant _LiquidWavePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.flow != flow;
  }
}
