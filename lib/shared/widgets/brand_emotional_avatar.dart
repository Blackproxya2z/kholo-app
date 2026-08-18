import 'package:flutter/material.dart';
import '../../app/theme/colors.dart';
import '../../core/services/brand_emotional_state_service.dart';

/// Interactive luxury animated brand logo & emotional avatar.
class BrandEmotionalAvatar extends StatefulWidget {
  final double size;
  final BrandEmotionalState state;
  final VoidCallback? onTap;

  const BrandEmotionalAvatar({
    super.key,
    this.size = 54,
    this.state = BrandEmotionalState.active,
    this.onTap,
  });

  @override
  State<BrandEmotionalAvatar> createState() => _BrandEmotionalAvatarState();
}

class _BrandEmotionalAvatarState extends State<BrandEmotionalAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breatheController;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breatheController.dispose();
    super.dispose();
  }

  Color get _glowColor {
    switch (widget.state) {
      case BrandEmotionalState.active:
        return KholoColors.rose;
      case BrandEmotionalState.gentleWaiting:
        return KholoColors.sage;
      case BrandEmotionalState.caringReminder:
        return KholoColors.warmGold;
      case BrandEmotionalState.longingCare:
        return KholoColors.plum;
      case BrandEmotionalState.welcomingBack:
        return const Color(0xFFF62477);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _breatheController,
        builder: (context, child) {
          final scale = 1.0 + (_breatheController.value * 0.05);
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Gentle Breathing Aura
              Container(
                width: widget.size * scale,
                height: widget.size * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _glowColor.withValues(alpha: 0.28),
                      _glowColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),

              // Glass Core Circle
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFF8F5),
                      Color(0xFFF9EAE1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: _glowColor.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _glowColor.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.state.emoji,
                    style: TextStyle(fontSize: widget.size * 0.44),
                  ),
                ),
              ),

              // Emotional Badge Status Dot
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: widget.size * 0.28,
                  height: widget.size * 0.28,
                  decoration: BoxDecoration(
                    color: _glowColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: _glowColor.withValues(alpha: 0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: widget.size * 0.08,
                      height: widget.size * 0.08,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
