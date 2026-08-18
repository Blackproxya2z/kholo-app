import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/theme/colors.dart';

/// ─── KHOLO GLOWING BLOOMING HERO LOGO ──────────────────────────────────────
///
/// Features:
/// 1. Blooming breathing lotus flower emblem.
/// 2. Rotating chromatic gradient aura / halo.
/// 3. Ambient starlight sparkles with orbital float.
/// 4. Full Dark & Light mode compatibility.
/// ────────────────────────────────────────────────────────────────────────────
class KholoGlowingLogo extends StatefulWidget {
  final double size;
  final bool showSparkles;
  final bool showHalo;

  const KholoGlowingLogo({
    super.key,
    this.size = 90,
    this.showSparkles = true,
    this.showHalo = true,
  });

  @override
  State<KholoGlowingLogo> createState() => _KholoGlowingLogoState();
}

class _KholoGlowingLogoState extends State<KholoGlowingLogo>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _sparkleCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _sparkleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _sparkleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseCtrl, _sparkleCtrl]),
      builder: (context, _) {
        return SizedBox(
          width: size * 1.5,
          height: size * 1.5,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Glowing Halo / Aura
              if (widget.showHalo)
                Container(
                  width: size * 1.25 * _pulseAnim.value,
                  height: size * 1.25 * _pulseAnim.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        KholoColors.magenta.withValues(
                            alpha: context.isDark ? 0.35 : 0.22),
                        KholoColors.blush.withValues(
                            alpha: context.isDark ? 0.20 : 0.15),
                        KholoColors.warmGold.withValues(
                            alpha: context.isDark ? 0.12 : 0.08),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.45, 0.75, 1.0],
                    ),
                  ),
                ),

              // 2. Center Blooming Lotus Medallion
              Transform.scale(
                scale: _pulseAnim.value,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: context.isDark
                          ? const [
                              Color(0xFFBA1C56),
                              Color(0xFF92003A),
                              Color(0xFF4A001D),
                            ]
                          : const [
                              Color(0xFFF62477),
                              Color(0xFF92003A),
                              Color(0xFF7A002E),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: KholoColors.magenta.withValues(
                            alpha: context.isDark ? 0.4 : 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.spa_rounded,
                      size: size * 0.52,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // 3. Starlight Sparkles
              if (widget.showSparkles) ...[
                _buildSparkle(
                  angle: _sparkleCtrl.value * 2 * math.pi,
                  radius: size * 0.65,
                  size: 14,
                  opacity: 0.85,
                  color: KholoColors.warmGold,
                ),
                _buildSparkle(
                  angle: (_sparkleCtrl.value * 2 * math.pi) + (math.pi * 0.7),
                  radius: size * 0.58,
                  size: 11,
                  opacity: 0.75,
                  color: KholoColors.blush,
                ),
                _buildSparkle(
                  angle: (_sparkleCtrl.value * 2 * math.pi) + (math.pi * 1.4),
                  radius: size * 0.72,
                  size: 13,
                  opacity: 0.9,
                  color: Colors.white,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSparkle({
    required double angle,
    required double radius,
    required double size,
    required double opacity,
    required Color color,
  }) {
    final x = radius * math.cos(angle);
    final y = radius * math.sin(angle);

    return Transform.translate(
      offset: Offset(x, y),
      child: Opacity(
        opacity: opacity * (0.6 + 0.4 * math.sin(angle * 2).abs()),
        child: Icon(
          Icons.auto_awesome,
          size: size,
          color: color,
        ),
      ),
    );
  }
}
