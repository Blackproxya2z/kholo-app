import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/colors.dart';
import '../../core/models/bloom_models.dart';
import '../../core/providers/bloom_providers.dart';
import 'widgets/bloom_card.dart';
import 'widgets/bloom_category_chip.dart';
import 'widgets/bloom_daily_tip_card.dart';

/// ─── KHOLO BLOOM HEALTH HUB MAIN DISCOVERY SCREEN ─────────────────────────────
class BloomHubScreen extends ConsumerStatefulWidget {
  const BloomHubScreen({super.key});

  @override
  ConsumerState<BloomHubScreen> createState() => _BloomHubScreenState();
}

class _BloomHubScreenState extends ConsumerState<BloomHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  BloomCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(bloomLanguageProvider);
    final allArticles = ref.watch(bloomArticlesProvider);
    final personalizedArticles = ref.watch(bloomPersonalizedFeedProvider);
    final savedArticles = ref.watch(bloomSavedArticlesProvider);
    final dailyTip = ref.watch(bloomDailyTipProvider);
    final progress = ref.watch(bloomUserProgressProvider);

    final isBn = lang == BloomLanguage.bn;
    final isDark = context.isDark;

    // Filter current tab list
    List<BloomArticle> activeList;
    switch (_tabCtrl.index) {
      case 0: // For You (AI)
        activeList = personalizedArticles;
        break;
      case 1: // Trending
        activeList = allArticles.where((a) => a.isFeatured || a.viewsCount > 100).toList();
        break;
      case 2: // Categories
        activeList = _selectedCategory == null
            ? allArticles
            : allArticles.where((a) => a.category == _selectedCategory).toList();
        break;
      case 3: // Saved
        activeList = savedArticles;
        break;
      default:
        activeList = allArticles;
    }

    // Apply category filter if active on other tabs
    if (_tabCtrl.index != 2 && _selectedCategory != null) {
      activeList = activeList.where((a) => a.category == _selectedCategory).toList();
    }

    return Scaffold(
      backgroundColor: context.kCanvas,
      appBar: AppBar(
        backgroundColor: context.kCanvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'KHOLO Bloom',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : KholoColors.wine,
                  ),
                ),
                const SizedBox(width: 6),
                const Text('🌸', style: TextStyle(fontSize: 18)),
              ],
            ),
            Text(
              isBn ? 'দৈনন্দিন স্বাস্থ্য শিক্ষা ও আবিষ্কার' : 'Daily Health Education & Wellness',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: context.kInkMuted,
              ),
            ),
          ],
        ),
        actions: [
          // Language Switcher Button
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(bloomLanguageProvider.notifier).toggle();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.language_rounded, size: 14, color: KholoColors.terracotta),
                  const SizedBox(width: 5),
                  Text(
                    lang == BloomLanguage.bn ? 'বাং' : 'EN',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.kInk,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search Button
          IconButton(
            icon: const Icon(Icons.search_rounded),
            color: context.kInk,
            tooltip: isBn ? 'খুঁজুন' : 'Search',
            onPressed: () {
              HapticFeedback.selectionClick();
              context.push('/bloom/search');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AI Health Guide Banner Card
                    _AiGuideTriggerBanner(
                      lang: lang,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        context.push('/bloom/ai-guide');
                      },
                    ),
                    const SizedBox(height: 14),

                    // Daily Tip & Streak Card
                    BloomDailyTipCard(
                      tip: dailyTip,
                      streakDays: progress.streakDays,
                      lang: lang,
                      onTap: () {},
                    ),

                    // Category Chips Carousel
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          BloomCategoryChip(
                            category: null,
                            isSelected: _selectedCategory == null,
                            lang: lang,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedCategory = null);
                            },
                          ),
                          const SizedBox(width: 8),
                          ...BloomCategory.values.map((cat) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: BloomCategoryChip(
                                category: cat,
                                isSelected: _selectedCategory == cat,
                                lang: lang,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    if (_selectedCategory == cat) {
                                      _selectedCategory = null;
                                    } else {
                                      _selectedCategory = cat;
                                    }
                                  });
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tab Bar
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TabBar(
                        controller: _tabCtrl,
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          color: isDark ? const Color(0xFF2C2226) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        labelColor: isDark ? Colors.white : KholoColors.wine,
                        unselectedLabelColor: context.kInkMuted,
                        labelStyle: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                        unselectedLabelStyle: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        tabs: [
                          Tab(text: isBn ? 'আপনার জন্য ✨' : 'For You ✨'),
                          Tab(text: isBn ? 'ট্রেন্ডিং 🔥' : 'Trending 🔥'),
                          Tab(text: isBn ? 'ক্যাটাগরি 🌸' : 'Categories 🌸'),
                          Tab(text: isBn ? 'সংরক্ষিত 🔖' : 'Saved 🔖'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
          ];
        },
        body: RefreshIndicator(
          color: KholoColors.wine,
          onRefresh: () async {
            ref.read(bloomArticlesProvider.notifier).refresh();
          },
          child: activeList.isEmpty
              ? _EmptyStateView(
                  tabIndex: _tabCtrl.index,
                  lang: lang,
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 80),
                  itemCount: activeList.length,
                  itemBuilder: (context, index) {
                    final article = activeList[index];
                    return BloomCard(
                      article: article,
                      lang: lang,
                      onTap: () {
                        ref.read(bloomArticlesProvider.notifier).recordRead(article.id);
                        context.push('/bloom/article/${article.id}');
                      },
                      onBookmarkToggle: () {
                        ref.read(bloomArticlesProvider.notifier).toggleBookmark(article.id);
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }
}

/// ─── AI GUIDE TRIGGER BANNER ──────────────────────────────────────────────────
class _AiGuideTriggerBanner extends StatelessWidget {
  const _AiGuideTriggerBanner({
    required this.lang,
    required this.onTap,
  });

  final BloomLanguage lang;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isBn = lang == BloomLanguage.bn;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6B4E71), Color(0xFF432C4A)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF432C4A).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.15),
              ),
              child: const Text('✨', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isBn ? 'KHOLO AI Health Guide' : 'KHOLO AI Health Guide',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isBn
                        ? 'মাসিক, ত্বক বা পুষ্টি বিষয়ক প্রশ্ন করুন...'
                        : 'Ask your health questions in Bangla or English...',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                isBn ? 'প্রশ্ন করুন' : 'Ask AI',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF432C4A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─── EMPTY STATE VIEW ─────────────────────────────────────────────────────────
class _EmptyStateView extends StatelessWidget {
  const _EmptyStateView({
    required this.tabIndex,
    required this.lang,
  });

  final int tabIndex;
  final BloomLanguage lang;

  @override
  Widget build(BuildContext context) {
    final isBn = lang == BloomLanguage.bn;

    String title;
    String message;
    IconData icon;

    if (tabIndex == 3) {
      title = isBn ? 'কোনো সংরক্ষিত লেখা নেই' : 'No Bookmarks Yet';
      message = isBn
          ? 'যেকোনো লেখার বুকমার্ক বাটনে ক্লিক করে পরে পড়ার জন্য সংরক্ষণ করুন।'
          : 'Tap the bookmark icon on any article to save it for offline reading.';
      icon = Icons.bookmark_border_rounded;
    } else {
      title = isBn ? 'কোনো লেখা পাওয়া যায়নি' : 'No Articles Found';
      message = isBn
          ? 'অন্য ক্যাটাগরি নির্বাচন করুন অথবা নতুন লেখার জন্য অপেক্ষা করুন।'
          : 'Try selecting a different category or check back later for updates.';
      icon = Icons.article_outlined;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 54, color: context.kInkMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.kInk,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: context.kInkMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
