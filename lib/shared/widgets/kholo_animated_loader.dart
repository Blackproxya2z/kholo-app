import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/colors.dart';

/// ─── AESTHETIC FEMININE GLOWING LOGO WITH BLOOM & SPARKLE PARTICLES ────────
///
/// Designed specifically for KHOLO to create a high-engagement, warm, luxury,
/// and comforting aesthetic for women.
///
/// Features:
/// 1. Blooming harmonic lotus petals (smooth custom-painted geometry).
/// 2. Orbiting starlight sparkles with variable twinkle opacity.
/// 3. Deep Wine-Magenta jewel badge with warm gold accents.
/// 4. Breathing ambient rose-gold halo aura.
/// ────────────────────────────────────────────────────────────────────────────
class KholoGlowingLogo extends StatefulWidget {
  const KholoGlowingLogo({
    super.key,
    this.size = 110,
    this.showSparkles = true,
    this.showHalo = true,
  });

  /// The diameter of the central jewel badge.
  final double size;

  /// Whether to render the orbiting fairy sparkles.
  final bool showSparkles;

  /// Whether to render the pulsing background glow aura.
  final bool showHalo;

  @override
  State<KholoGlowingLogo> createState() => _KholoGlowingLogoState();
}

class _KholoGlowingLogoState extends State<KholoGlowingLogo>
    with TickerProviderStateMixin {
  late final AnimationController _bloomCtrl;
  late final AnimationController _orbitCtrl;
  late final AnimationController _twinkleCtrl;

  late final Animation<double> _bloomScale;
  late final Animation<double> _haloIntensity;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();

    // 1. Organic Breathing & Petal Bloom Cycle (2.4s gentle yoyo)
    _bloomCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _bloomScale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _bloomCtrl, curve: Curves.easeInOutCubic),
    );

    _haloIntensity = Tween<double>(begin: 16.0, end: 36.0).animate(
      CurvedAnimation(parent: _bloomCtrl, curve: Curves.easeInOutSine),
    );

    // 2. Slow Stardust Orbit Rotation (12s infinite loop)
    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 12000),
    )..repeat();

    _rotation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _orbitCtrl, curve: Curves.linear),
    );

    // 3. Fairy Sparkle Twinkle Cycle (1.8s loop)
    _twinkleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bloomCtrl.dispose();
    _orbitCtrl.dispose();
    _twinkleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;

    return AnimatedBuilder(
      animation: Listenable.merge([_bloomCtrl, _orbitCtrl, _twinkleCtrl]),
      builder: (context, _) {
        return SizedBox(
          width: s * 1.6,
          height: s * 1.6,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // 1. Ambient Rose-Gold Glow Halo
              if (widget.showHalo)
                Container(
                  width: s * 1.3,
                  height: s * 1.3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF62477).withValues(
                          alpha: 0.28 * (_bloomScale.value - 0.9) * 10,
                        ),
                        blurRadius: _haloIntensity.value * 1.5,
                        spreadRadius: 6,
                      ),
                      BoxShadow(
                        color: const Color(0xFFF8D880).withValues(
                          alpha: 0.18 * (_bloomScale.value - 0.9) * 10,
                        ),
                        blurRadius: _haloIntensity.value,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),

              // 2. Blooming Lotus Petals (Custom Canvas Painter)
              Transform.scale(
                scale: _bloomScale.value,
                child: CustomPaint(
                  size: Size(s * 1.4, s * 1.4),
                  painter: _LotusPetalsPainter(
                    bloomProgress: _bloomCtrl.value,
                  ),
                ),
              ),

              // 3. Central Gradient Jewel Badge
              Transform.scale(
                scale: _bloomScale.value,
                child: Container(
                  width: s,
                  height: s,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF92003A), // KHOLO Velvet Wine
                        Color(0xFFBA1C56),
                        Color(0xFFF62477), // Vibrant Magenta
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF92003A).withValues(alpha: 0.42),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: const Color(0xFFF8D880).withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(-2, -2),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Inner ambient floral glyph
                      Icon(
                        Icons.spa_rounded,
                        color: Colors.white.withValues(alpha: 0.95),
                        size: s * 0.44,
                      ),

                      // Golden Star Crest
                      Positioned(
                        top: s * 0.21,
                        right: s * 0.22,
                        child: Transform.scale(
                          scale: 0.85 + (0.3 * _twinkleCtrl.value),
                          child: Icon(
                            Icons.auto_awesome,
                            color: const Color(0xFFF8D880),
                            size: s * 0.18,
                            shadows: [
                              Shadow(
                                color: const Color(0xFFF8D880).withValues(alpha: 0.8),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Orbiting Starlight & Sparkle Particles
              if (widget.showSparkles)
                Transform.rotate(
                  angle: _rotation.value,
                  child: SizedBox(
                    width: s * 1.5,
                    height: s * 1.5,
                    child: Stack(
                      children: [
                        // Top Sparkle (Golden Star)
                        Align(
                          alignment: Alignment.topCenter,
                          child: _FloatingSparkle(
                            icon: Icons.star_rounded,
                            color: const Color(0xFFF8D880),
                            size: s * 0.15,
                            opacity: 0.4 + (0.6 * _twinkleCtrl.value),
                          ),
                        ),

                        // Right Sparkle (Pink Diamond)
                        Align(
                          alignment: Alignment.centerRight,
                          child: _FloatingSparkle(
                            icon: Icons.auto_awesome,
                            color: const Color(0xFFFF85A2),
                            size: s * 0.14,
                            opacity: 0.3 + (0.7 * (1.0 - _twinkleCtrl.value)),
                          ),
                        ),

                        // Bottom Sparkle (Rose Gem)
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: _FloatingSparkle(
                            icon: Icons.brightness_1_rounded,
                            color: const Color(0xFFFFAEC9),
                            size: s * 0.08,
                            opacity: 0.5 + (0.5 * _twinkleCtrl.value),
                          ),
                        ),

                        // Left Sparkle (Starlight)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _FloatingSparkle(
                            icon: Icons.auto_awesome,
                            color: const Color(0xFFF8D880),
                            size: s * 0.13,
                            opacity: 0.4 + (0.6 * _twinkleCtrl.value),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom painter rendering harmonic blooming lotus petals around the core.
class _LotusPetalsPainter extends CustomPainter {
  final double bloomProgress;

  _LotusPetalsPainter({required this.bloomProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.38;

    const int petalCount = 8;
    for (int i = 0; i < petalCount; i++) {
      final angle = (i * 2 * math.pi / petalCount) + (bloomProgress * 0.08);
      final petalCenter = Offset(
        center.dx + math.cos(angle) * (radius * (0.88 + 0.12 * bloomProgress)),
        center.dy + math.sin(angle) * (radius * (0.88 + 0.12 * bloomProgress)),
      );

      final paint = Paint()
        ..color = (i % 2 == 0
                ? const Color(0xFFF62477)
                : const Color(0xFFFFAEC9))
            .withValues(alpha: 0.14 + 0.08 * math.sin(bloomProgress * math.pi))
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawCircle(petalCenter, size.width * 0.12, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LotusPetalsPainter oldDelegate) =>
      oldDelegate.bloomProgress != bloomProgress;
}

class _FloatingSparkle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double opacity;

  const _FloatingSparkle({
    required this.icon,
    required this.color,
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Icon(
        icon,
        color: color,
        size: size,
        shadows: [
          Shadow(
            color: color.withValues(alpha: 0.9),
            blurRadius: 10,
          ),
        ],
      ),
    );
  }
}

/// ─── AESTHETIC ANIMATED LOADER WIDGET & MODAL OVERLAY ───────────────────────
class KholoAnimatedLoader extends StatelessWidget {
  const KholoAnimatedLoader({
    super.key,
    this.message = 'Loading your space...',
    this.size = 85,
    this.showMessage = true,
    this.isFullScreen = false,
  });

  final String message;
  final double size;
  final bool showMessage;
  final bool isFullScreen;

  /// Displays a modal loading overlay with the glowing blooming logo
  static void show(BuildContext context, {String message = 'Loading your space...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
              decoration: BoxDecoration(
                color: KholoColors.canvas,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: KholoColors.wine.withValues(alpha: 0.3),
                    blurRadius: 36,
                    offset: const Offset(0, 12),
                  ),
                ],
                border: Border.all(
                  color: KholoColors.magenta.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: KholoAnimatedLoader(
                message: message,
                size: 75,
                isFullScreen: false,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Closes the modal loading overlay
  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Beautiful Glowing Blooming Logo
        KholoGlowingLogo(
          size: size,
          showSparkles: true,
          showHalo: true,
        ),

        if (showMessage) ...[
          const SizedBox(height: 18),
          Text(
            'KHOLO',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 3.0,
              color: KholoColors.wine,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: tt.bodySmall?.copyWith(
              color: KholoColors.inkMuted,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ],
    );

    if (isFullScreen) {
      return Scaffold(
        backgroundColor: KholoColors.canvas,
        body: Center(child: content),
      );
    }

    return content;
  }
}
