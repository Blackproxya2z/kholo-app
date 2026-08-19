import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/colors.dart';
import '../../core/models/bloom_models.dart';
import '../../core/providers/bloom_providers.dart';
import 'widgets/bloom_card.dart';

/// ─── REALTIME BILINGUAL MEDICAL SEARCH SYSTEM ────────────────────────────────
class BloomSearchScreen extends ConsumerStatefulWidget {
  const BloomSearchScreen({super.key});

  @override
  ConsumerState<BloomSearchScreen> createState() => _BloomSearchScreenState();
}

class _BloomSearchScreenState extends ConsumerState<BloomSearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  static const List<Map<String, String>> _trendingSearches = [
    {'bn': 'period pain কেন হয়', 'en': 'Why do period cramps happen'},
    {'bn': 'PCOS লক্ষণ ও প্রতিকার', 'en': 'PCOS symptoms & diet'},
    {'bn': 'স্কিন ব্যারিয়ার মেরামত', 'en': 'Skin barrier repair guide'},
    {'bn': 'গর্ভাবস্থায় পুষ্টিকর খাবার', 'en': 'Pregnancy nutrition'},
    {'bn': 'নায়াসিনামাইড ব্যবহারের নিয়ম', 'en': 'How to use Niacinamide'},
    {'bn': 'মানসিক চাপ ও দুশ্চিন্তা কমানো', 'en': 'Stress & cortisol relief'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    ref.read(bloomSearchQueryProvider.notifier).state = query;
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(bloomLanguageProvider);
    final searchResults = ref.watch(bloomSearchResultsProvider);
    final currentQuery = ref.watch(bloomSearchQueryProvider);

    final isBn = lang == BloomLanguage.bn;
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: context.kCanvas,
      appBar: AppBar(
        backgroundColor: context.kCanvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: context.kInk,
          onPressed: () {
            ref.read(bloomSearchQueryProvider.notifier).state = '';
            context.pop();
          },
        ),
        title: Container(
          height: 44,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: TextField(
            controller: _searchCtrl,
            focusNode: _focusNode,
            onChanged: _onSearch,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: context.kInk,
            ),
            decoration: InputDecoration(
              hintText: isBn ? 'আপনার স্বাস্থ্যবিষয়ক প্রশ্ন খুঁজুন...' : 'Search your health question...',
              hintStyle: GoogleFonts.inter(
                fontSize: 13,
                color: context.kInkMuted,
              ),
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: KholoColors.wine),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      color: context.kInkMuted,
                      onPressed: () {
                        _searchCtrl.clear();
                        _onSearch('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 60),
        children: [
          // Trending search queries when query is empty
          if (currentQuery.isEmpty) ...[
            Text(
              isBn ? 'জনপ্রিয় অনুসন্ধানসমূহ 🔥' : 'Trending Health Searches 🔥',
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.kInk,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: _trendingSearches.map((item) {
                final text = isBn ? item['bn']! : item['en']!;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _searchCtrl.text = text;
                    _onSearch(text);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.trending_up_rounded, size: 14, color: KholoColors.terracotta),
                        const SizedBox(width: 6),
                        Text(
                          text,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: context.kInk,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            Text(
              isBn ? 'প্রস্তাবিত স্বাস্থ্য নির্দেশিকা' : 'Suggested Health Guides',
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.kInk,
              ),
            ),
            const SizedBox(height: 14),
          ] else ...[
            // Result count
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                isBn
                    ? '${searchResults.length}টি ফলাফল পাওয়া গেছে'
                    : '${searchResults.length} Results Found',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.kInkMuted,
                ),
              ),
            ),
          ],

          // Search Results
          if (searchResults.isEmpty && currentQuery.isNotEmpty) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.search_off_rounded, size: 52, color: context.kInkMuted.withValues(alpha: 0.5)),
                    const SizedBox(height: 14),
                    Text(
                      isBn ? 'কোনো ফলাফল পাওয়া যায়নি' : 'No Results Found',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: context.kInk,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isBn
                          ? 'বানান পরীক্ষা করুন অথবা ভিন্ন শব্দ দিয়ে অনুসন্ধান করুন।'
                          : 'Try checking your spelling or searching for another keyword.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: context.kInkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            ...searchResults.map((art) {
              return BloomCard(
                article: art,
                lang: lang,
                onTap: () {
                  ref.read(bloomArticlesProvider.notifier).recordRead(art.id);
                  context.push('/bloom/article/${art.id}');
                },
                onBookmarkToggle: () {
                  ref.read(bloomArticlesProvider.notifier).toggleBookmark(art.id);
                },
              );
            }),
          ],
        ],
      ),
    );
  }
}
