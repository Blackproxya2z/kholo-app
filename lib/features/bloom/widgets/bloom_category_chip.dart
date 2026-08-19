import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/colors.dart';
import '../../../core/models/bloom_models.dart';

/// ─── BLOOM CATEGORY FILTER CHIP ──────────────────────────────────────────────
class BloomCategoryChip extends StatelessWidget {
  const BloomCategoryChip({
    super.key,
    required this.category,
    required this.isSelected,
    required this.lang,
    required this.onTap,
  });

  final BloomCategory? category;
  final bool isSelected;
  final BloomLanguage lang;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = category == null
        ? (lang == BloomLanguage.bn ? 'সব বিষয় ✨' : 'All ✨')
        : '${category!.icon} ${category!.localizedTitle(lang)}';

    final activeColor = category?.accentColor ?? KholoColors.wine;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (context.isDark ? activeColor.withValues(alpha: 0.25) : activeColor.withValues(alpha: 0.12))
              : (context.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? activeColor
                : (context.isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08)),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (context.isDark ? Colors.white : activeColor)
                : (context.isDark ? Colors.white70 : context.kInkMuted),
          ),
        ),
      ),
    );
  }
}
