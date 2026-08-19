import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../app/theme/colors.dart';
import '../../core/models/bloom_models.dart';
import '../../core/providers/bloom_providers.dart';

/// ─── LUXURY HEALTH ARTICLE DETAIL SCREEN ─────────────────────────────────────
class BloomArticleDetailScreen extends ConsumerStatefulWidget {
  const BloomArticleDetailScreen({
    super.key,
    required this.articleId,
  });

  final String articleId;

  @override
  ConsumerState<BloomArticleDetailScreen> createState() =>
      _BloomArticleDetailScreenState();
}

class _BloomArticleDetailScreenState
    extends ConsumerState<BloomArticleDetailScreen> {
  final ScrollController _scrollCtrl = ScrollController();
  double _readProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final maxScroll = _scrollCtrl.position.maxScrollExtent;
    final currentScroll = _scrollCtrl.offset;
    if (maxScroll > 0) {
      setState(() {
        _readProgress = (currentScroll / maxScroll).clamp(0.0, 1.0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(bloomLanguageProvider);
    final service = ref.watch(bloomServiceProvider);
    final article = service.getArticleById(widget.articleId);

    final isBn = lang == BloomLanguage.bn;
    final isDark = context.isDark;

    if (article == null) {
      return Scaffold(
        backgroundColor: context.kCanvas,
        appBar: AppBar(backgroundColor: context.kCanvas),
        body: Center(
          child: Text(
            isBn ? 'লেখাটি খুঁজে পাওয়া যায়নি' : 'Article Not Found',
            style: GoogleFonts.inter(color: context.kInk),
          ),
        ),
      );
    }

    final cat = article.category;
    final allArticles = ref.watch(bloomArticlesProvider);
    final relatedArticles = allArticles
        .where((a) => a.category == cat && a.id != article.id)
        .take(3)
        .toList();

    return Scaffold(
      backgroundColor: context.kCanvas,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollCtrl,
            slivers: [
              // ── Slivery Gradient Header ─────────────────────────────────────
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: isDark ? const Color(0xFF1E1E24) : cat.accentColor,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.3),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 20),
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/bloom');
                    }
                  },
                ),
                actions: [
                  // Language Switcher
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        lang == BloomLanguage.bn ? 'EN' : 'বাং',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      ref.read(bloomLanguageProvider.notifier).toggle();
                    },
                  ),

                  // Share Button
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.3),
                      ),
                      child: const Icon(Icons.share_rounded,
                          color: Colors.white, size: 18),
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      Share.share(
                        '${article.getTitle(lang)}\n\nRead on KHOLO Bloom Health Hub:\nhttps://kholo.care/bloom/${article.id}',
                      );
                    },
                  ),

                  // Bookmark Button
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.3),
                      ),
                      child: Icon(
                        article.isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: article.isSaved
                            ? Colors.amberAccent
                            : Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      ref
                          .read(bloomArticlesProvider.notifier)
                          .toggleBookmark(article.id);
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          cat.gradient.first,
                          cat.gradient.last,
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Decorative Elements
                        Positioned(
                          right: -30,
                          bottom: -30,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 90, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(cat.icon,
                                        style: const TextStyle(fontSize: 13)),
                                    const SizedBox(width: 6),
                                    Text(
                                      cat.localizedTitle(lang),
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.schedule_rounded,
                                      size: 14, color: Colors.white70),
                                  const SizedBox(width: 5),
                                  Text(
                                    isBn
                                        ? '${article.readTimeMinutes} মিনিট পড়ার সময়'
                                        : '${article.readTimeMinutes} min read',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.verified_user_rounded,
                                      size: 14, color: Colors.white70),
                                  const SizedBox(width: 5),
                                  Text(
                                    isBn ? 'মেডিক্যালি ভেরিফাইড' : 'Clinically Verified',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Article Content Body ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        article.getTitle(lang),
                        style: isBn
                            ? GoogleFonts.hindSiliguri(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: context.kInk,
                                height: 1.3,
                              )
                            : GoogleFonts.playfairDisplay(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: context.kInk,
                                height: 1.25,
                              ),
                      ),
                      const SizedBox(height: 14),

                      // Author / Medical Reviewer Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.shield_outlined,
                                size: 16, color: cat.accentColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${isBn ? 'মেডিকেল রিভিউ ও তথ্যসূত্র:' : 'Medical Review & Source:'} ${article.authorOrSource}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: context.kInkMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Key Takeaways Box ────────────────────────────────────
                      _KeyTakeawaysBox(
                        takeaways: article.getKeyTakeaways(lang),
                        lang: lang,
                        accentColor: cat.accentColor,
                      ),
                      const SizedBox(height: 24),

                      // Full Article Body
                      _ArticleBodyContent(
                        content: article.getContent(lang),
                        isBn: isBn,
                      ),
                      const SizedBox(height: 32),

                      // ── Medical Disclaimer Box ──────────────────────────────
                      _MedicalDisclaimerBox(lang: lang),
                      const SizedBox(height: 36),

                      // ── Related Articles Section ─────────────────────────────
                      if (relatedArticles.isNotEmpty) ...[
                        Text(
                          isBn ? 'সম্পর্কিত অন্যান্য লেখা' : 'Related Articles',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: context.kInk,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ...relatedArticles.map((rel) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: rel.category.accentColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(rel.category.icon,
                                    style: const TextStyle(fontSize: 18)),
                              ),
                            ),
                            title: Text(
                              rel.getTitle(lang),
                              style: isBn
                                  ? GoogleFonts.hindSiliguri(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: context.kInk,
                                    )
                                  : GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
                                      color: context.kInk,
                                    ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              isBn
                                  ? '${rel.readTimeMinutes} মিনিট'
                                  : '${rel.readTimeMinutes} min read',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: context.kInkMuted,
                              ),
                            ),
                            trailing: Icon(Icons.chevron_right_rounded,
                                color: context.kInkMuted),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              context.pushReplacement('/bloom/article/${rel.id}');
                            },
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Top Reading Progress Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value: _readProgress,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation<Color>(KholoColors.wine),
              minHeight: 3.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// ─── KEY MEDICAL TAKEAWAYS BOX ───────────────────────────────────────────────
class _KeyTakeawaysBox extends StatelessWidget {
  const _KeyTakeawaysBox({
    required this.takeaways,
    required this.lang,
    required this.accentColor,
  });

  final List<String> takeaways;
  final BloomLanguage lang;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final isBn = lang == BloomLanguage.bn;
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? accentColor.withValues(alpha: 0.12)
            : accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.3 : 0.2),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 18, color: accentColor),
              const SizedBox(width: 8),
              Text(
                isBn ? 'মূল স্বাস্থ্য তথ্য ও টেকঅ্যাওয়ে' : 'Key Medical Takeaways',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...takeaways.map((point) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(Icons.check_circle_rounded,
                        size: 14, color: accentColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      point,
                      style: isBn
                          ? GoogleFonts.hindSiliguri(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: context.kInk,
                              height: 1.4,
                            )
                          : GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.kInk,
                              height: 1.4,
                            ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// ─── ARTICLE BODY TEXT PARSER ────────────────────────────────────────────────
class _ArticleBodyContent extends StatelessWidget {
  const _ArticleBodyContent({
    required this.content,
    required this.isBn,
  });

  final String content;
  final bool isBn;

  @override
  Widget build(BuildContext context) {
    final lines = content.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final clean = line.trim();
        if (clean.isEmpty) return const SizedBox(height: 10);

        if (clean.startsWith('### ')) {
          return Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 6),
            child: Text(
              clean.replaceFirst('### ', ''),
              style: isBn
                  ? GoogleFonts.hindSiliguri(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: context.kInk,
                    )
                  : GoogleFonts.playfairDisplay(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: context.kInk,
                    ),
            ),
          );
        }

        if (clean.startsWith('- ') || clean.startsWith('• ') || RegExp(r'^\d+\.').hasMatch(clean)) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  ',
                    style: TextStyle(
                        fontSize: 16,
                        color: KholoColors.terracotta,
                        fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(
                    clean.replaceAll(RegExp(r'^[-•\d+\.]\s*'), '').replaceAll('**', ''),
                    style: isBn
                        ? GoogleFonts.hindSiliguri(
                            fontSize: 14.5,
                            color: context.kInk,
                            height: 1.5,
                          )
                        : GoogleFonts.inter(
                            fontSize: 14,
                            color: context.kInk,
                            height: 1.5,
                          ),
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            clean.replaceAll('**', ''),
            style: isBn
                ? GoogleFonts.hindSiliguri(
                    fontSize: 15,
                    color: context.kInk,
                    height: 1.6,
                  )
                : GoogleFonts.inter(
                    fontSize: 14.5,
                    color: context.kInk,
                    height: 1.55,
                  ),
          ),
        );
      }).toList(),
    );
  }
}

/// ─── CLINICAL DISCLAIMER BOX ─────────────────────────────────────────────────
class _MedicalDisclaimerBox extends StatelessWidget {
  const _MedicalDisclaimerBox({required this.lang});

  final BloomLanguage lang;

  @override
  Widget build(BuildContext context) {
    final isBn = lang == BloomLanguage.bn;
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242220) : const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.amber.withValues(alpha: 0.2)
              : Colors.amber.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Colors.amber, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBn ? 'মেডিকেল সেফটি ও সতর্কতা' : 'Medical Safety Disclaimer',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.brown.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isBn
                      ? 'এই তথ্য সম্পূর্ণ সাধারণ স্বাস্থ্য শিক্ষার উদ্দেশ্যে রচিত। এটি কোনো রোগ নির্ণয় বা বিশেষজ্ঞ ডাক্তারের প্রেসক্রিপশনের বিকল্প নয়। জরুরি প্রয়োজনে রেজিস্টার্ড চিকিৎসকের পরামর্শ নিন।'
                      : 'This content is strictly for educational purposes and is not a substitute for professional medical diagnosis or clinical treatment. Always consult a qualified healthcare professional regarding any medical symptoms.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: context.kInkMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
