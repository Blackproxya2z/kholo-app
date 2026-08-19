import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/colors.dart';
import '../../../core/models/bloom_models.dart';

/// ─── DAILY HEALTH CARD & STREAK TRACKER WIDGET ───────────────────────────────
class BloomDailyTipCard extends StatelessWidget {
  const BloomDailyTipCard({
    super.key,
    required this.tip,
    required this.streakDays,
    required this.lang,
    required this.onTap,
  });

  final BloomDailyTip tip;
  final int streakDays;
  final BloomLanguage lang;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isBn = lang == BloomLanguage.bn;
    final isDark = context.isDark;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF2C2226),
                  const Color(0xFF1E1E24),
                ]
              : [
                  const Color(0xFFFFF0F2),
                  const Color(0xFFF9EAE1),
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? KholoColors.blush.withValues(alpha: 0.25)
              : KholoColors.blush.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: KholoColors.wine.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Daily Badge + Streak Counter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: KholoColors.wine.withValues(alpha: isDark ? 0.3 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(tip.category.icon,
                          style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 6),
                      Text(
                        tip.getTitle(lang),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : KholoColors.wine,
                        ),
                      ),
                    ],
                  ),
                ),

                // Streak Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF7E5F), Color(0xFFFEB47B)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF7E5F).withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department_rounded,
                          size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        isBn
                            ? '$streakDays দিনের স্ট্রিক 🔥'
                            : '$streakDays Day Streak 🔥',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tip Body
            Text(
              tip.getBody(lang),
              style: isBn
                  ? GoogleFonts.hindSiliguri(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: context.kInk,
                      height: 1.45,
                    )
                  : GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: context.kInk,
                      height: 1.4,
                    ),
            ),
            const SizedBox(height: 12),

            // Action Step Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: KholoColors.sage.withValues(alpha: 0.2),
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 16,
                      color: KholoColors.terracotta,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBn ? 'আজকের করণীয় পদক্ষেপ' : 'Today’s Micro-Action',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: KholoColors.terracotta,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tip.getActionStep(lang),
                          style: isBn
                              ? GoogleFonts.hindSiliguri(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: context.kInk,
                                )
                              : GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: context.kInk,
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
