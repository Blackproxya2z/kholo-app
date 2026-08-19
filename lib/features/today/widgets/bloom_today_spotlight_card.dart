import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/colors.dart';
import '../../../core/models/bloom_models.dart';
import '../../../core/providers/bloom_providers.dart';

/// ─── BLOOM HEALTH SPOTLIGHT CARD FOR TODAY DASHBOARD ─────────────────────────
class BloomTodaySpotlightCard extends ConsumerWidget {
  const BloomTodaySpotlightCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(bloomLanguageProvider);
    final dailyTip = ref.watch(bloomDailyTipProvider);
    final progress = ref.watch(bloomUserProgressProvider);
    final isBn = lang == BloomLanguage.bn;
    final isDark = context.isDark;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF2C2228),
                  const Color(0xFF1E1C22),
                ]
              : [
                  const Color(0xFFFFF2F4),
                  const Color(0xFFF9EBE3),
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? KholoColors.blush.withValues(alpha: 0.2)
              : KholoColors.blush.withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: KholoColors.wine.withValues(alpha: isDark ? 0.25 : 0.05),
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
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: KholoColors.wine.withValues(alpha: isDark ? 0.3 : 0.1),
                      ),
                      child: const Text('🌸', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bloom Health Hub',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : KholoColors.wine,
                          ),
                        ),
                        Text(
                          isBn ? 'প্রতিদিনের স্বাস্থ্য বার্তা' : 'Daily Health Discovery',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: context.kInkMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Streak pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department_rounded,
                          size: 13, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        '${progress.streakDays}d Streak',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Tip Preview
            Text(
              dailyTip.getTitle(lang),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: KholoColors.terracotta,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dailyTip.getBody(lang),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: isBn
                  ? GoogleFonts.hindSiliguri(
                      fontSize: 13,
                      color: context.kInk,
                      height: 1.4,
                    )
                  : GoogleFonts.inter(
                      fontSize: 12.5,
                      color: context.kInk,
                      height: 1.35,
                    ),
            ),
            const SizedBox(height: 16),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  context.push('/bloom');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF382A34) : Colors.white,
                  foregroundColor: isDark ? Colors.white : KholoColors.wine,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : KholoColors.blush.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.explore_rounded, size: 16, color: KholoColors.wine),
                    const SizedBox(width: 8),
                    Text(
                      isBn ? 'Bloom Health Hub এ যান ➔' : 'Explore Bloom Health Hub ➔',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : KholoColors.wine,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
