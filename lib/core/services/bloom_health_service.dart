import 'package:shared_preferences/shared_preferences.dart';
import '../models/bloom_models.dart';
import '../models/health_profile.dart';
import '../utils/cycle_engine.dart';

/// ─── KHOLO BLOOM HEALTH SERVICE ──────────────────────────────────────────────
///
/// Features:
/// 1. Comprehensive curated evidence-based medical content library (Bilingual EN/BN).
/// 2. Realtime bilingual medical search engine.
/// 3. AI Personalization engine matching user life-stage, cycle phase & wellness goals.
/// 4. Daily health tip deterministic rotation & streak progression.
/// 5. 100% Offline caching, bookmarking & reading history persistence.
/// ─────────────────────────────────────────────────────────────────────────────
class BloomHealthService {
  static const String _kSavedArticlesKey = 'kholo_bloom_saved_articles';
  static const String _kCompletedArticlesKey = 'kholo_bloom_completed_articles';
  static const String _kStreakDaysKey = 'kholo_bloom_streak_days';
  static const String _kLastReadDateKey = 'kholo_bloom_last_read_date';
  static const String _kLanguageKey = 'kholo_bloom_language';

  final SharedPreferences? _prefs;

  BloomHealthService([this._prefs]);

  /// Read current language preference (default: Bengali / বাংলা)
  BloomLanguage getLanguage() {
    final code = _prefs?.getString(_kLanguageKey);
    if (code == 'en') return BloomLanguage.en;
    return BloomLanguage.bn;
  }

  /// Persist language preference
  Future<void> setLanguage(BloomLanguage lang) async {
    await _prefs?.setString(_kLanguageKey, lang.code);
  }

  /// Get all curated articles
  List<BloomArticle> getAllArticles() {
    final savedIds = getSavedArticleIds();
    final completedIds = getCompletedArticleIds();

    return _curatedArticles.map((art) {
      return art.copyWith(
        isSaved: savedIds.contains(art.id),
        isCompleted: completedIds.contains(art.id),
      );
    }).toList();
  }

  /// Get articles filtered by category
  List<BloomArticle> getArticlesByCategory(BloomCategory category) {
    return getAllArticles().where((a) => a.category == category).toList();
  }

  /// Get featured articles
  List<BloomArticle> getFeaturedArticles() {
    return getAllArticles().where((a) => a.isFeatured).toList();
  }

  /// Get single article by ID
  BloomArticle? getArticleById(String id) {
    try {
      final list = getAllArticles();
      return list.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  /// ─── AI PERSONALIZATION ENGINE ─────────────────────────────────────────────
  /// Adapts feed based on user's life stage, cycle phase, pregnancy status, and goals.
  List<BloomArticle> getPersonalizedFeed(HealthProfile? profile) {
    final articles = getAllArticles();
    if (profile == null) return articles;

    final scored = articles.map((art) {
      int score = 0;

      // 1. Life Stage match
      if (profile.lifeStage == LifeStage.pregnant) {
        if (art.targetLifeStages.contains('pregnancy') ||
            art.category == BloomCategory.womenHealth ||
            art.category == BloomCategory.nutrition) {
          score += 50;
        }
      } else if (profile.lifeStage == LifeStage.postpartum) {
        if (art.targetLifeStages.contains('postpartum') ||
            art.targetLifeStages.contains('motherhood')) {
          score += 45;
        }
      }

      // 2. Cycle Phase match
      if (profile.lastPeriodDate != null && profile.lifeStage != LifeStage.pregnant) {
        final phaseCtx = CycleEngine.phaseContext(profile);
        if (phaseCtx != null) {
          final phaseName = phaseCtx.phase.name.toLowerCase();
          if (art.targetPhases.any((p) => p.toLowerCase() == phaseName)) {
            score += 40;
          }
        }
      }

      // 3. PCOS / Health concerns match
      if (profile.hasPcosPcod) {
        if (art.targetConcerns.contains('pcos') ||
            art.tags.any((t) => t.toLowerCase() == 'pcos')) {
          score += 35;
        }
      }

      // 4. Featured boost
      if (art.isFeatured) score += 15;

      return MapEntry(art, score);
    }).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).toList();
  }

  /// ─── REALTIME BILINGUAL SEARCH ENGINE ──────────────────────────────────────
  /// Matches Bengali and English queries against titles, summaries, tags, and content.
  List<BloomArticle> searchArticles(String query) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return getAllArticles();

    final all = getAllArticles();
    final scored = <MapEntry<BloomArticle, int>>[];

    for (final article in all) {
      int score = 0;
      final titleEn = article.titleEn.toLowerCase();
      final titleBn = article.titleBn.toLowerCase();
      final summaryEn = article.summaryEn.toLowerCase();
      final summaryBn = article.summaryBn.toLowerCase();
      final tags = article.tags.map((t) => t.toLowerCase()).toList();

      if (titleEn.contains(cleanQuery) || titleBn.contains(cleanQuery)) {
        score += 100;
      }
      if (tags.any((t) => t.contains(cleanQuery))) {
        score += 80;
      }
      if (summaryEn.contains(cleanQuery) || summaryBn.contains(cleanQuery)) {
        score += 50;
      }
      if (article.category.titleEn.toLowerCase().contains(cleanQuery) ||
          article.category.titleBn.toLowerCase().contains(cleanQuery)) {
        score += 40;
      }

      final expanded = _expandSearchSynonyms(cleanQuery);
      for (final eq in expanded) {
        if (titleEn.contains(eq) || titleBn.contains(eq)) score += 30;
        if (tags.any((t) => t.contains(eq))) score += 25;
        if (summaryEn.contains(eq) || summaryBn.contains(eq)) score += 15;
      }

      if (score > 0) {
        scored.add(MapEntry(article, score));
      }
    }

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).toList();
  }

  List<String> _expandSearchSynonyms(String query) {
    final synonyms = <String>[];
    final map = {
      'period': ['মাসিক', 'ঋতুস্রাব', 'bleeding', 'cramps', 'pain', 'ব্যথা'],
      'pain': ['ব্যথা', 'cramps', 'বেদনা', 'dysmenorrhea'],
      'acne': ['ব্রণ', 'পিম্পল', 'pimples', 'breakout', 'skin', 'ত্বক'],
      'skin': ['ত্বক', 'মুখ', 'glow', 'barrier', 'skincare'],
      'pcos': ['পলিসিস্টিক', 'irregular', 'অনিয়মিত', 'hormone', 'হরমোন'],
      'pregnancy': ['গর্ভধারণ', 'গর্ভবতী', 'baby', 'বাচ্চা', 'trimester', 'পুষ্টি'],
      'stress': ['মানসিক চাপ', 'দুশ্চিন্তা', 'anxiety', 'sleep', 'ঘুম'],
      'diet': ['খাবার', 'পুষ্টি', 'nutrition', 'vitamin', 'ভিটামিন'],
      'hormone': ['হরমোন', 'estrogen', 'progesterone', 'ইস্ট্রোজেন'],
      'sex': ['যৌন', 'মিলন', 'intimacy', 'wellness'],
    };

    map.forEach((key, values) {
      if (query == key || query.contains(key) || values.any((v) => v == query)) {
        synonyms.add(key);
        synonyms.addAll(values);
      }
    });

    return synonyms;
  }

  /// ─── DAILY DETERMINISTIC TIPS & STREAK ─────────────────────────────────────
  BloomDailyTip getDailyTip([DateTime? date]) {
    final now = date ?? DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final index = dayOfYear % _curatedDailyTips.length;
    return _curatedDailyTips[index];
  }

  BloomUserProgress getUserProgress() {
    final streak = _prefs?.getInt(_kStreakDaysKey) ?? 1;
    final lastReadStr = _prefs?.getString(_kLastReadDateKey);
    final lastReadDate = lastReadStr != null ? DateTime.tryParse(lastReadStr) : null;
    final saved = getSavedArticleIds();
    final completed = getCompletedArticleIds();

    return BloomUserProgress(
      streakDays: streak,
      lastReadDate: lastReadDate,
      savedArticleIds: saved,
      completedArticleIds: completed,
    );
  }

  Future<void> recordArticleRead(String articleId) async {
    final now = DateTime.now();
    final completed = getCompletedArticleIds();
    if (!completed.contains(articleId)) {
      completed.add(articleId);
      await _prefs?.setStringList(_kCompletedArticlesKey, completed);
    }

    final lastReadStr = _prefs?.getString(_kLastReadDateKey);
    final lastRead = lastReadStr != null ? DateTime.tryParse(lastReadStr) : null;

    int currentStreak = _prefs?.getInt(_kStreakDaysKey) ?? 1;

    if (lastRead == null) {
      currentStreak = 1;
    } else {
      final differenceInDays = DateTime(now.year, now.month, now.day)
          .difference(DateTime(lastRead.year, lastRead.month, lastRead.day))
          .inDays;

      if (differenceInDays == 1) {
        currentStreak += 1;
      } else if (differenceInDays > 1) {
        currentStreak = 1;
      }
    }

    await _prefs?.setInt(_kStreakDaysKey, currentStreak);
    await _prefs?.setString(_kLastReadDateKey, now.toIso8601String());
  }

  /// ─── BOOKMARKING & OFFLINE STORAGE ─────────────────────────────────────────
  List<String> getSavedArticleIds() {
    return _prefs?.getStringList(_kSavedArticlesKey) ?? [];
  }

  List<String> getCompletedArticleIds() {
    return _prefs?.getStringList(_kCompletedArticlesKey) ?? [];
  }

  Future<bool> toggleBookmark(String articleId) async {
    final saved = getSavedArticleIds();
    bool isNowSaved = false;
    if (saved.contains(articleId)) {
      saved.remove(articleId);
      isNowSaved = false;
    } else {
      saved.add(articleId);
      isNowSaved = true;
    }
    await _prefs?.setStringList(_kSavedArticlesKey, saved);
    return isNowSaved;
  }

  List<BloomArticle> getSavedArticles() {
    final savedIds = getSavedArticleIds();
    return getAllArticles().where((a) => savedIds.contains(a.id)).toList();
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // CURATED EVIDENCE-BASED MEDICAL CONTENT REPOSITORY
  // ═════════════════════════════════════════════════════════════════════════════
  static final List<BloomArticle> _curatedArticles = [
    // 🌸 1. Women Health: Period Cramps (Dysmenorrhea)
    BloomArticle(
      id: 'art_wh_period_pain',
      category: BloomCategory.womenHealth,
      titleEn: 'Why Do Period Cramps Happen & Science-Backed Natural Relief',
      titleBn: 'মাসিকে পেট বা কোমর ব্যথা কেন হয় এবং প্রাকৃতিক উপশম',
      summaryEn:
          'Prostaglandins trigger uterine muscle contractions during menstruation. Learn why cramps occur and proven clinical methods to reduce discomfort safely.',
      summaryBn:
          'মাসিকের সময় প্রোস্টাগ্ল্যান্ডিন হরমোনের কারণে জরায়ুর পেশী সংকুচিত হয়। জানুন ব্যথার কারণ এবং ঘরোয়া ও চিকিৎসাগত উপশম পদ্ধতি।',
      contentEn: '''
### What Causes Primary Dysmenorrhea?
During menstruation, the endometrial lining produces chemical messengers called **prostaglandins**. Higher prostaglandin levels trigger stronger uterine muscle spasms, temporarily constricting blood vessels and causing cramping in the lower abdomen and lower back.

### Clinically Proven Relief Strategies:
1. **Heat Therapy (40°C / 104°F):** Applying a heating pad or hot water bottle to the lower abdomen dilates constricted blood vessels and relaxes uterine smooth muscle just as effectively as standard OTC analgesics according to clinical trials.
2. **Magnesium & Vitamin B6:** Magnesium glycinate acts as a natural muscle relaxant, while Vitamin B6 supports neurotransmitter balance.
3. **Anti-Inflammatory Herbal Teas:** Ginger tea (*Zingiber officinale*) inhibits prostaglandin synthesis. Chamomile contains glycine, which eases muscle spasms.
4. **Gentle Movement & Yoga:** Child’s Pose (*Balasana*) and Cat-Cow stretches relieve pelvic floor tension.

### When to Seek Medical Evaluation:
Consult a gynecologist if pain is severe enough to disrupt daily life, persists beyond the first 48 hours, or is accompanied by heavy clotting, which may signal endometriosis or adenomyosis.
''',
      contentBn: '''
### মাসিকে ব্যথার মূল কারণ কী?
মাসিক চলাকালীন জরায়ুর ভেতরের স্তর থেকে **প্রোস্টাগ্ল্যান্ডিন (Prostaglandins)** নামক উপাদান নিঃসৃত হয়। এর মাত্রা বেশি হলে জরায়ুর পেশী শক্ত হয়ে সংকুচিত হয় এবং রক্তনালী সাময়িক চেপে যায়, যার ফলে তলপেট, কোমর ও উরুতে তীব্র ব্যথা অনুভূত হয়।

### বিজ্ঞানসম্মত উপশম পদ্ধতি:
১. **গরম পানির সেঁক (Heat Therapy):** তলপেটে হট ওয়াটার ব্যাগ বা হিটিং প্যাড রাখলে রক্ত চলাচল স্বাভাবিক হয় এবং পেশীর খিঁচুনি দ্রুত কমে।
২. **ম্যাগনেসিয়াম ও ভিটামিন বি৬ সমৃদ্ধ খাবার:** কলা, কাঠবাদাম, পালং শাক ও ডার্ক চকলেট পেশী শিথিল করতে সাহায্য করে।
৩. **ভেষজ চা:** আদা চা প্রোস্টাগ্ল্যান্ডিনের মাত্রা কমাতে অত্যন্ত কার্যকর। এছাড়া ক্যামোমাইল চাও চমৎকার আরাম দেয়।
৪. **হালকা স্ট্রেচিং ও ইয়োগা:** বাটারফ্লাই পোজ ও ক্যাট-কাউ স্ট্রেচিং পেলভিক পেশীর টান কমায়।

### কখন ডাক্তারের পরামর্শ নেবেন?
ব্যথা যদি স্বাভাবিক কাজকর্ম ব্যাহত করে, ২-৩ দিনের বেশি স্থায়ী হয় বা অতিরিক্ত রক্তক্ষরণ হয়, তবে বিশেষজ্ঞ চিকিৎসকের পরামর্শ নেওয়া জরুরি।
''',
      keyTakeawaysEn: [
        'Prostaglandins cause uterine muscle spasms and cramping.',
        'Heat pads (40°C) improve blood circulation and relieve tension rapidly.',
        'Ginger tea and magnesium act as natural anti-inflammatory agents.',
        'Severe, debilitating pain should always be evaluated by a gynecologist.'
      ],
      keyTakeawaysBn: [
        'প্রোস্টাগ্ল্যান্ডিন হরমোনের কারণে জরায়ুর পেশী সংকুচিত হয়ে ব্যথা হয়।',
        'গরম পানির সেঁক পেশীর খিঁচুনি কমিয়ে দ্রুত আরাম দেয়।',
        'আদা চা ও ম্যাগনেসিয়াম সমৃদ্ধ খাবার প্রদাহ রোধ করে।',
        'অতিরিক্ত অসহ্য ব্যথায় চিকিৎসকের শরণাপন্ন হওয়া আবশ্যক।'
      ],
      authorOrSource: 'ACOG (American College of Obstetricians and Gynecologists)',
      sourceUrl: 'https://www.acog.org',
      publishedDate: DateTime(2026, 8, 15),
      readTimeMinutes: 4,
      isFeatured: true,
      tags: ['Period', 'Pain Relief', 'Cramps', 'Women Health', 'Dysmenorrhea'],
      targetLifeStages: ['reproductive', 'young_adult', 'menstruation'],
      targetPhases: ['menstrual'],
      targetConcerns: ['pain', 'cramps', 'pms'],
    ),

    // 🌸 2. Women Health: PCOS & Irregular Cycles
    BloomArticle(
      id: 'art_wh_pcos_guide',
      category: BloomCategory.womenHealth,
      titleEn: 'Demystifying PCOS: Symptoms, Insulin Resistance & Hormone Balance',
      titleBn: 'PCOS কী? অনিয়মিত মাসিক, লক্ষণ এবং হরমোনের ভারসাম্য রক্ষার উপায়',
      summaryEn:
          'Polycystic Ovary Syndrome affects 1 in 10 women. Discover how insulin resistance impacts ovulation and how lifestyle adjustments restore hormonal harmony.',
      summaryBn:
          'পলিসিস্টিক ওভারি সিন্ড্রোম (PCOS) প্রতি ১০ জন নারীর ১ জনের হতে পারে। জানুন এর লক্ষণ, ইনসুলিন রেজিস্ট্যান্সের প্রভাব এবং জীবনযাত্রার পরিবর্তন।',
      contentEn: '''
### Understanding Polycystic Ovary Syndrome (PCOS)
PCOS is an endocrine and metabolic condition characterized by hormonal imbalance, specifically elevated androgens (male hormones) and insulin resistance.

### Classic Signs of PCOS:
- **Irregular or Missed Cycles:** Ovulation is delayed or absent.
- **Acne & Hirsutism:** Excess facial/body hair and persistent jawline acne due to elevated androgens.
- **Metabolic Challenges:** Fatigue, weight fluctuations around the midsection, and sugar cravings.

### Clinical Management & Lifestyle Steps:
1. **Low-Glycemic Nutrition:** Prioritize fiber-rich complex carbs, lean proteins, and healthy fats to stabilize blood glucose.
2. **Inositol Supplementation:** Myo-inositol and D-chiro-inositol (40:1 ratio) improve insulin sensitivity and support ovulatory function under medical guidance.
3. **Consistent Strength Training:** Building muscle improves glucose disposal and lowers circulating androgen levels.
''',
      contentBn: '''
### PCOS বা পলিসিস্টিক ওভারি সিন্ড্রোম কী?
PCOS হলো নারীদেহের হরমোন ও মেটাবলিক ভারসাম্যহীনতাজনিত একটি অবস্থা। এতে ওভারি থেকে নিয়মিত ডিম্বাণু নির্গমন ব্যাহত হয় এবং অ্যান্ড্রোজেন (পুরুষ হরমোন) কিছুটা বেড়ে যায়।

### প্রধান লক্ষণসমূহ:
- **অনিয়মিত বা বন্ধ মাসিক:** দীর্ঘ সময় পর পর মাসিক হওয়া বা সম্পূর্ণ বন্ধ থাকা।
- **মুখে ব্রণ ও অবাঞ্ছিত লোম:** থুতনি ও চোয়ালে একনে এবং অতিরিক্ত লোম গজানো।
- **ওজন বৃদ্ধি ও মিষ্টি খাওয়ার প্রবণতা:** ইনসুলিন রেজিস্ট্যান্সের কারণে মেটাবলিজম ধীর হয়ে যায়।

### জীবনযাত্রায় প্রয়োজনীয় পরিবর্তন:
১. **লো-গ্লাইসেমিক ডায়েট:** চিনি, ময়দা ও প্রসেসড খাবার বাদ দিয়ে শাকসবজি, ডিম, ডাল ও বাদাম খান।
২. **নিয়মিত ব্যায়াম:** সপ্তাহে ৩-৪ দিন হালকা ওয়েট ট্রেনিং বা ৩০ মিনিট দ্রুত হাঁটা ইনসুলিন সেন্সিটিভিটি বাড়ায়।
৩. **পর্যাপ্ত ঘুম ও স্ট্রেস নিয়ন্ত্রণ:** কর্টিসল হরমোন কম থাকলে সেক্স হরমোনের ভারসাম্য রক্ষা পায়।
''',
      keyTakeawaysEn: [
        'PCOS is driven primarily by insulin resistance and androgen imbalance.',
        'Low-GI nutrition stabilizes insulin and supports natural ovulation.',
        'Resistance training enhances metabolic health and hormone clearance.'
      ],
      keyTakeawaysBn: [
        'ইনসুলিন রেজিস্ট্যান্স PCOS-এর অন্যতম প্রধান কারণ।',
        'সুষম লো-সুগার ডায়েট হরমোনের ভারসাম্য রক্ষায় মুখ্য ভূমিকা পালন করে।',
        'নিয়মিত শারীরিক পরিশ্রম ও পরিমিত ঘুম ডিম্বস্ফোটন স্বাভাবিক রাখতে সাহায্য করে।'
      ],
      authorOrSource: 'NHS UK & Endocrine Society',
      sourceUrl: 'https://www.nhs.uk/conditions/polycystic-ovary-syndrome-pcos/',
      publishedDate: DateTime(2026, 8, 10),
      readTimeMinutes: 5,
      isFeatured: true,
      tags: ['PCOS', 'Hormones', 'Irregular Period', 'Ovulation', 'Fertility'],
      targetLifeStages: ['reproductive', 'fertility'],
      targetPhases: ['follicular', 'luteal'],
      targetConcerns: ['irregular_cycle', 'pcos', 'acne'],
    ),

    // ✨ 3. Skin Care: Skin Barrier Repair
    BloomArticle(
      id: 'art_sk_barrier_repair',
      category: BloomCategory.skinCare,
      titleEn: 'How to Repair a Damaged Skin Barrier: The Ultimate Guide',
      titleBn: 'ত্বকের ক্ষতিগ্রস্ত ব্যারিয়ার মেরামত ও গ্লো ফিরিয়ে আনার বিজ্ঞানসম্মত গাইড',
      summaryEn:
          'Redness, burning, and sudden breakouts? Your stratum corneum lipid barrier might be compromised. Learn the 3 essential ceramides and hydration protocol.',
      summaryBn:
          'ত্বকে জ্বালাপোড়া, লালচে ভাব বা হঠাৎ ব্রণের উপদ্রব? জেনে নিন স্কিন ব্যারিয়ার নষ্ট হওয়ার কারণ এবং সিরামাইড ও হায়ালুরনিক অ্যাসিড দিয়ে দ্রুত সারিয়ে তোলার উপায়।',
      contentEn: '''
### What Is the Skin Barrier?
The outermost layer of your skin (**stratum corneum**) functions like a brick wall: skin cells (*corneocytes*) are the bricks, and lipids (*ceramides, cholesterol, fatty acids*) are the mortar holding moisture in while keeping irritants and bacteria out.

### Signs of a Broken Skin Barrier:
- Stinging or burning sensation when applying gentle moisturizer.
- Dehydrated yet oily appearance (overproduction of sebum to compensate).
- Persistent redness, flaking, and sensitivity.

### The 4-Step Barrier Recovery Protocol:
1. **Pause All Active Ingredients:** Cease AHA/BHA exfoliants, Retinoids, and high-concentration Vitamin C for 14 to 21 days.
2. **Rebuild with Ceramides:** Use moisturizers containing Ceramides (NP, AP, EOP), Cholesterol, and Free Fatty Acids.
3. **Humectant Sandwiching:** Apply Hyaluronic Acid or Panthenol (Vitamin B5) on damp skin, then lock with a barrier cream.
4. **Mineral Sunscreen Protection:** Protect regenerating cells with zinc oxide sunscreen daily.
''',
      contentBn: '''
### স্কিন ব্যারিয়ার (Skin Barrier) কী?
আমাদের ত্বকের সবচেয়ে বাইরের স্তরটি একটি সুরক্ষাপ্রাচীরের মতো কাজ করে। এটি ত্বকের ভেতরের আর্দ্রতা ধরে রাখে এবং বাইরের ধুলাবালি, জীবাণু ও ক্ষতিকর উপাদান থেকে ত্বককে রক্ষা করে।

### ব্যারিয়ার নষ্ট হওয়ার লক্ষণ:
- সাধারণ ময়েশ্চারাইজার লাগালেও ত্বকে জ্বালাপোড়া বা চুলকানি হওয়া।
- ত্বক খসখসে অথচ তেলতেলে হয়ে থাকা।
- হঠাৎ লালচে ভাব ও সংবেদনশীলতা বেড়ে যাওয়া।

### ব্যারিয়ার মেরামতের ৪টি সহজ ধাপ:
১. **সব ধরনের এক্সফোলিয়েটর ও এসিড বন্ধ রাখুন:** কমপক্ষে ২-৩ সপ্তাহ AHA, BHA, রেটিনল ও তীব্র সিরাম ব্যবহার বন্ধ রাখুন।
২. **সিরামাইড ও সেন্টেলা যুক্ত ময়েশ্চারাইজার ব্যবহার করুন:** এটি ত্বকের সুরক্ষা প্রাচীর দ্রুত জোড়া লাগায়।
৩. **হালকা ক্লিনজার ব্যবহার করুন:** ত্বক অতিরিক্ত শুষ্ক করে এমন সাবান বা ফোমিং ফেসওয়াশ এড়িয়ে চলুন।
৪. **নিয়মিত সানস্ক্রিন ব্যবহার করুন:** সূর্যের অতিবেগুনী রশ্মি থেকে ত্বক বাঁচাতে প্রতিদিন সানস্ক্রিন লাগানো আবশ্যক।
''',
      keyTakeawaysEn: [
        'A damaged skin barrier causes burning, redness, and reactive breakouts.',
        'Pause active acids (AHA/BHA/Retinol) until the barrier heals.',
        'Ceramides, Centella Asiatica, and Panthenol restore the lipid matrix.'
      ],
      keyTakeawaysBn: [
        'স্কিন ব্যারিয়ার ক্ষতিগ্রস্ত হলে ত্বক জ্বালাপোড়া ও লালচে হয়ে যায়।',
        'ব্যারিয়ার ভালো না হওয়া পর্যন্ত সব ধরনের এসিড ও রেটিনল বন্ধ রাখা উচিত।',
        'সিরামাইড ও প্যান্থেনল যুক্ত ময়েশ্চারাইজার ত্বককে দ্রুত সুস্থ করে তোলে।'
      ],
      authorOrSource: 'AAD (American Academy of Dermatology)',
      sourceUrl: 'https://www.aad.org',
      publishedDate: DateTime(2026, 8, 12),
      readTimeMinutes: 4,
      isFeatured: true,
      tags: ['Skin Care', 'Skin Barrier', 'Ceramides', 'Sensitive Skin', 'Glow'],
      targetLifeStages: ['all'],
      targetPhases: ['all'],
      targetConcerns: ['skin', 'barrier', 'acne', 'sensitivity'],
    ),

    // ✨ 4. Skin Care: Active Ingredients 101
    BloomArticle(
      id: 'art_sk_ingredients_101',
      category: BloomCategory.skinCare,
      titleEn: 'Active Ingredients 101: Niacinamide, Salicylic Acid & Retinol',
      titleBn: 'স্কিনকেয়ার অ্যাক্টিভস পরিচিতি: নায়াসিনামাইড, স্যালিসিলিক এসিড ও রেটিনল',
      summaryEn:
          'Master how active skincare ingredients work, optimal concentrations, and how to safely layer them without irritation.',
      summaryBn:
          'জেনে নিন বিভিন্ন অ্যাক্টিভ উপাদান কোন ত্বকের জন্য উপযোগী, ব্যবহারের সঠিক নিয়ম এবং কোন দুটি উপাদান একসাথে ব্যবহার করা যাবে না।',
      contentEn: '''
### 1. Niacinamide (Vitamin B3)
- **Best For:** Pore refinement, redness reduction, oil balance, and barrier support.
- **Optimal Strength:** 2% - 5%.
- **Safe Pairing:** Pairs well with almost every ingredient, including Hyaluronic Acid and Peptides.

### 2. Salicylic Acid (BHA)
- **Best For:** Blackheads, whiteheads, and oily congested pores. Being oil-soluble, it penetrates deep into the follicle.
- **Usage Frequency:** 2-3 times per week at night.

### 3. Retinol (Vitamin A Derivative)
- **Best For:** Cellular turnover, collagen production, fine lines, and stubborn texture.
- **Golden Rule:** Start with 0.2% concentration twice weekly, always follow with sunscreen the next morning.
''',
      contentBn: '''
### ১. নায়াসিনামাইড (Niacinamide - Vitamin B3)
- **উপকারিতা:** লোমকূপ ছোট রাখা, ত্বকের তেল নিঃসরণ নিয়ন্ত্রণ ও দাগ হালকা করা।
- **ব্যবহারের নিয়ম:** সকালে ও রাতে যেকোনো স্কিন টাইপেই নিরাপদে ব্যবহার করা যায়।

### ২. স্যালিসিলিক এসিড (Salicylic Acid - BHA)
- **উপকারিতা:** ব্ল্যাকহেডস, হোয়াইটহেডস এবং তৈলাক্ত ত্বকের গভীরে গিয়ে ময়লা পরিষ্কার করা।
- **ব্যবহারের নিয়ম:** সপ্তাহে ২-৩ দিন রাতে ব্যবহার করা ভালো।

### ৩. রেটিনল (Retinol)
- **উপকারিতা:** ত্বকের কোলাজেন বৃদ্ধি, তারুণ্য বজায় রাখা ও সূক্ষ্ম রেখা দূর করা।
- **সতর্কতা:** শুরুতে সপ্তাহে ১-২ রাত ব্যবহার করুন এবং পরদিন অবশ্যই সানস্ক্রিন লাগান।
''',
      keyTakeawaysEn: [
        'Niacinamide (2-5%) soothes redness and regulates sebum production.',
        'BHA (Salicylic Acid) is oil-soluble and clears deep pore congestion.',
        'Never mix Retinol with strong AHA/BHA in the same routine.'
      ],
      keyTakeawaysBn: [
        'নায়াসিনামাইড ত্বকের লালচে ভাব কমায় এবং তেল নিয়ন্ত্রণ করে।',
        'স্যালিসিলিক এসিড ব্ল্যাকহেডস ও একনে দূর করতে সাহায্য করে।',
        'একই সময়ে রেটিনল এবং অ্যাসিড এক্সফোলিয়েটর একসাথে ব্যবহার করবেন না।'
      ],
      authorOrSource: 'British Association of Dermatologists',
      sourceUrl: 'https://www.bad.org.uk',
      publishedDate: DateTime(2026, 8, 8),
      readTimeMinutes: 3,
      isFeatured: false,
      tags: ['Skincare Ingredients', 'Niacinamide', 'Retinol', 'Salicylic Acid'],
      targetLifeStages: ['all'],
      targetPhases: ['all'],
      targetConcerns: ['skincare', 'acne', 'glow'],
    ),

    // ❤️ 5. Sexual Wellness: Safe Intimacy & Body Education
    BloomArticle(
      id: 'art_sw_body_education',
      category: BloomCategory.sexualWellness,
      titleEn: 'Sexual Health & Body Education: Scientific Facts & Pelvic Wellness',
      titleBn: 'যৌন স্বাস্থ্য ও শরীরবিজ্ঞান: বৈজ্ঞানিক তথ্য, সচেতনতা ও পেলভিক যত্ন',
      summaryEn:
          'Evidence-based education on reproductive anatomy, safe intimacy, pelvic floor strength, and debunking common health myths.',
      summaryBn:
          'প্রজনন স্বাস্থ্যবিজ্ঞান, স্বাস্থ্যকর সম্পর্ক, পেলভিক ফ্লোরের যত্ন এবং সামাজিক ভুল ধারণা দূরীকরণে বৈজ্ঞানিক ব্যাখ্যা।',
      contentEn: '''
### Scientific Overview of Reproductive & Sexual Wellness
Sexual wellness is recognized by the World Health Organization (WHO) as a vital state of physical, emotional, and social well-being in relation to sexuality.

### Key Pillars of Sexual Health:
1. **Pelvic Floor Health:** The pelvic floor muscles support the bladder, uterus, and bowel. Daily Kegel exercises improve circulation, muscle tone, and bladder control.
2. **Hydration & Natural pH Balance:** The vaginal microbiome is naturally acidic (pH 3.8 - 4.5), maintained by *Lactobacillus* bacteria. Harsh soaps or douching disrupt this barrier and should be avoided.
3. **Scientific Perspective on Masturbation & Solitary Release:** Medically, solitary sexual release is a normal physiological function that releases endorphins, dopamine, and oxytocin, aiding stress reduction and sleep without causing physical harm or weakness.
4. **Communication & Emotional Safety:** Mutual comfort, informed consent, and open dialogue reduce anxiety and enhance intimacy.
''',
      contentBn: '''
### প্রজনন ও যৌন স্বাস্থ্যের বৈজ্ঞানিক দৃষ্টিকোণ
বিশ্ব স্বাস্থ্য সংস্থা (WHO)-এর মতে, যৌন স্বাস্থ্য হলো শারীরিক, মানসিক ও আবেগীয় সুস্থতার একটি অপরিহার্য অঙ্গ। এটি কেবল রোগহীনতা নয়, বরং সামগ্রিক সুস্থতার পরিচায়ক।

### সুস্থতার গুরুত্বপূর্ণ দিকসমূহ:
১. **পেলভিক ফ্লোর পেশীর যত্ন:** পেলভিক ফ্লোর জরায়ু ও মূত্রাশয়কে ধরে রাখে। কিগেল (Kegel) ব্যায়াম এই পেশী শক্তিশালী করে রক্ত সঞ্চালন বাড়ায়।
২. **প্রাকৃতিক পিএইচ (pH) ভারসাম্য রক্ষা:** সাধারণ সাবান বা সুগন্ধিযুক্ত ওয়াশ যোনির প্রাকৃতিক এসিডিক ব্যালেন্স (pH 3.8 - 4.5) নষ্ট করে দেয়। শুধু কুসুম গরম পানি ব্যবহারই যথেষ্ট।
৩. **হস্তমৈথুন ও শরীরবৃত্তীয় তথ্যের বৈজ্ঞানিক সত্যতা:** চিকিৎসা বিজ্ঞানের দৃষ্টিতে হস্তমৈথুন একটি স্বাভাবিক শারীরিক প্রক্রিয়া। এটি শরীরের কোনো ক্ষতি বা দুর্বলতা তৈরি করে না, বরং এন্ডোরফিন ও ডোপামিন হরমোন নিঃসৃত করে মানসিক চাপ কমায়।
৪. **সম্পর্কের মানসিক প্রশান্তি ও খোলামেলা আলোচনা:** যেকোনো সুস্থ সম্পর্কের মূল ভিত্তি পারস্পরিক শ্রদ্ধা ও মানসিক নির্ভরতা।
''',
      keyTakeawaysEn: [
        'Sexual health is a recognized component of overall physical and mental wellness.',
        'Avoid scented washes; plain warm water preserves natural vaginal microflora.',
        'Pelvic floor exercises strengthen core support and prevent incontinence.'
      ],
      keyTakeawaysBn: [
        'যৌন ও প্রজনন স্বাস্থ্য সামগ্রিক শারীরিক সুস্থতার অংশ।',
        'সুগন্ধি সাবান পরিহার করে প্রাকৃতিক পিএইচ ব্যালেন্স বজায় রাখা দরকার।',
        'কিগেল ব্যায়াম পেলভিক পেশী মজবুত ও সক্রিয় রাখতে সহায়তা করে।'
      ],
      authorOrSource: 'World Health Organization (WHO)',
      sourceUrl: 'https://www.who.int/health-topics/sexual-health',
      publishedDate: DateTime(2026, 8, 14),
      readTimeMinutes: 5,
      isFeatured: true,
      tags: ['Sexual Wellness', 'Body Education', 'Pelvic Floor', 'WHO', 'Health'],
      targetLifeStages: ['reproductive', 'adult'],
      targetPhases: ['all'],
      targetConcerns: ['sexual_wellness', 'pelvic_health'],
    ),

    // 🌿 6. Men Health: Vitality, Hormones & Heart Health
    BloomArticle(
      id: 'art_mh_hormone_lifestyle',
      category: BloomCategory.menHealth,
      titleEn: 'Men’s Vitality Guide: Testosterone Optimization & Cardiovascular Wellness',
      titleBn: 'পুরুষ স্বাস্থ্য ও প্রাণশক্তি: টেস্টোস্টেরন ব্যালেন্স, ফিটনেস ও হৃদরোগ প্রতিরোধ',
      summaryEn:
          'Explore how sleep quality, micronutrients (Zinc, Vitamin D3), and resistance training sustain male vitality and metabolic health.',
      summaryBn:
          'গভীর ঘুম, প্রয়োজনীয় পুষ্টি (জিঙ্ক, ভিটামিন ডি৩) ও নিয়মিত ব্যায়াম কীভাবে পুরুষের শারীরিক শক্তি, হরমোন ও হৃদযন্ত্র ভালো রাখে।',
      contentEn: '''
### Understanding Male Hormonal Health
Testosterone plays a central role in bone density, muscle mass, cognitive focus, energy levels, and cardiovascular vitality.

### 4 Science-Backed Vitality Habits:
1. **Prioritize 7-8 Hours of Slow-Wave Sleep:** Over 70% of daily testosterone is synthesized during deep REM and stage-3 sleep.
2. **Zinc & Vitamin D3 Optimization:** Zinc is a fundamental cofactor for androgen synthesis. Oysters, pumpkin seeds, eggs, and moderate sunlight provide natural support.
3. **Compound Resistance Training:** Squats, deadlifts, and overhead presses stimulate metabolic output and insulin sensitivity.
4. **Stress & Cortisol Management:** Chronic psychological stress elevates cortisol, which directly blunts gonadotropin and testosterone production.
''',
      contentBn: '''
### পুরুষের হরমোন ও স্বাস্থ্যবিজ্ঞান
টেস্টোস্টেরন পুরুষের পেশী গঠন, হাড়ের ঘনত্ব, মানসিক মনোযোগ ও শারীরিক সক্ষমতার জন্য অত্যন্ত জরুরি একটি হরমোন।

### সুস্থ থাকার ৪টি প্রধান নিয়ম:
১. **৭-৮ ঘণ্টার পর্যাপ্ত ঘুম:** গভীর ঘুমের সময়ই শরীরে টেস্টোস্টেরন সবচেয়ে বেশি তৈরি হয়।
২. **জিঙ্ক ও ভিটামিন ডি যুক্ত খাবার:** ডিমের কুসুম, কুমড়ার বীজ, সামুদ্রিক মাছ ও সকালের রোদ হরমোনের স্বাভাবিক মাত্রা বজায় রাখে।
৩. **ব্যায়াম ও ওয়েট ট্রেনিং:** সপ্তাহে ৩-৪ দিন নিয়মিত ব্যায়াম মেটাবলিজম বাড়ায় এবং চর্বি কমাতে সাহায্য করে।
৪. **মানসিক চাপ নিয়ন্ত্রণ:** অতিরিক্ত কাজের চাপ ও দুশ্চিন্তা কর্টিসল বাড়িয়ে শক্তি ও রোগ প্রতিরোধ ক্ষমতা কমিয়ে দেয়।
''',
      keyTakeawaysEn: [
        '70% of testosterone synthesis occurs during deep sleep.',
        'Zinc, Vitamin D3, and healthy fats form the biochemical building blocks for vitality.',
        'Compound strength exercises improve insulin sensitivity and metabolic health.'
      ],
      keyTakeawaysBn: [
        'পর্যাপ্ত গভীর ঘুম পুরুষের শারীরিক শক্তি বৃদ্ধির প্রধান শর্ত।',
        'জিঙ্ক ও ভিটামিন ডি৩ হরমোনের স্বাভাবিক মাত্রা ধরে রাখতে অপরিহার্য।',
        'নিয়মিত ব্যায়াম হৃদযন্ত্র ও রক্তনালী সুস্থ রাখে।'
      ],
      authorOrSource: 'Harvard Men’s Health Watch',
      sourceUrl: 'https://www.health.harvard.edu/mens-health',
      publishedDate: DateTime(2026, 8, 11),
      readTimeMinutes: 4,
      isFeatured: false,
      tags: ['Men Health', 'Testosterone', 'Fitness', 'Cardiovascular', 'Lifestyle'],
      targetLifeStages: ['adult', 'men'],
      targetPhases: ['all'],
      targetConcerns: ['men_health', 'vitality', 'fitness'],
    ),

    // 🧘‍♀️ 7. Mental Wellness: Managing Anxiety & Sleep Quality
    BloomArticle(
      id: 'art_mw_anxiety_sleep',
      category: BloomCategory.mentalWellness,
      titleEn: 'Resetting the Nervous System: Cortisol, Box Breathing & Deep Sleep',
      titleBn: 'মানসিক প্রশান্তি ও গভীর ঘুম: কর্টিসল নিয়ন্ত্রণ, ব্রিদিং টেকনিক ও রিল্যাক্সেশন',
      summaryEn:
          'Learn the neurobiology of chronic stress, how vagus nerve activation calms the sympathetic nervous system, and sleep architecture tips.',
      summaryBn:
          'অতিরিক্ত দুশ্চিন্তা ও অনিদ্রা দূর করতে ভেগাস নার্ভ অ্যাক্টিভেশনের উপায়, ৪-৪-৪-৪ বক্স ব্রিদিং এবং গভীর ঘুমের প্রাকৃতিক নিয়মাবলী।',
      contentEn: '''
### The Neurobiology of Stress
When a stressor triggers the sympathetic nervous system, the adrenal glands release **cortisol** and **adrenaline**, elevating heart rate, narrowing blood vessels, and interrupting melatonin production.

### Practical Nervous System De-escalation Tools:
1. **Box Breathing (4-4-4-4 Method):** Inhale for 4 seconds, hold for 4 seconds, exhale for 4 seconds, hold for 4 seconds. This activates the vagus nerve and triggers the parasympathetic relaxation response.
2. **Morning Sunlight Exposure (10-15 Minutes):** Morning photons hitting retinal ganglion cells set the master circadian clock (Suprachiasmatic Nucleus), promoting natural melatonin release 14 hours later.
3. **Magnesium Glycinate & L-Theanine:** Calms excessive neural excitation in the brain for restful restorative sleep.
''',
      contentBn: '''
### মানসিক চাপ ও শরীরের প্রতিক্রিয়া
অতিরিক্ত মানসিক চাপের ফলে শরীরে **কর্টিসল (Cortisol)** হরমোন বেড়ে যায়। এর ফলে হৃদস্পন্দন দ্রুত হয়, মেজাজ খিটখিটে থাকে এবং রাতের ঘুম বিঘ্নিত হয়।

### মন শান্ত করার সহজ ও কার্যকর উপায়:
১. **বক্স ব্রিদিং (Box Breathing ৪-৪-৪-৪ পদ্ধতি):** ৪ সেকেন্ড ধরে নাক দিয়ে শ্বাস নিন, ৪ সেকেন্ড ধরে রাখুন, ৪ সেকেন্ডে মুখ দিয়ে ছাড়ুন, আবার ৪ সেকেন্ড থামুন। এটি সঙ্গে সঙ্গে স্নায়ুতন্ত্রকে শান্ত করে।
২. **সকালের মিষ্টি রোদ নেওয়া:** সকালে ১০-১৫ মিনিট রোদে থাকলে শরীরের বায়োলজিক্যাল ক্লক ঠিক থাকে এবং রাতে চমৎকার ঘুম আসে।
৩. **স্ক্রিন টাইম কমানো:** ঘুমানোর অন্তত ১ ঘণ্টা আগে মোবাইল ও ল্যাপটপের নীল আলো থেকে দূরে থাকুন।
''',
      keyTakeawaysEn: [
        'Box breathing stimulates the vagus nerve to rapidly lower heart rate.',
        'Morning sunlight sets the circadian clock for improved night-time melatonin release.',
        'Unplugging from screens 60 minutes before bed enhances deep sleep.'
      ],
      keyTakeawaysBn: [
        'বক্স ব্রিদিং স্নায়ুতন্ত্র শান্ত করে দ্রুত দুশ্চিন্তা কমায়।',
        'সকালের রোদ রাতের ঘুমের ছন্দ ঠিক রাখতে সহায়তা করে।',
        'ঘুমানোর আগে মোবাইল ফোন দূরে রাখলে ঘুমের গুণগত মান বাড়ে।'
      ],
      authorOrSource: 'Mind & Mental Health Foundation UK',
      sourceUrl: 'https://www.mind.org.uk',
      publishedDate: DateTime(2026, 8, 13),
      readTimeMinutes: 4,
      isFeatured: true,
      tags: ['Mental Wellness', 'Anxiety', 'Sleep', 'Cortisol', 'Breathing'],
      targetLifeStages: ['all'],
      targetPhases: ['luteal', 'menstrual'],
      targetConcerns: ['stress', 'sleep', 'anxiety', 'pms'],
    ),

    // 🥗 8. Nutrition: Superfoods for Hormonal Balance & Pregnancy
    BloomArticle(
      id: 'art_nu_hormone_nutrition',
      category: BloomCategory.nutrition,
      titleEn: 'Hormone-Balancing Nutrition: Iron, Omega-3s & Folate for Women',
      titleBn: 'হরমোন ব্যালেন্স ও সুস্থতায় পুষ্টিকর খাবার: আয়রন, ওমেগা-৩ এবং ফোলেটের গুরুত্ব',
      summaryEn:
          'Fuel your body through every cycle phase and pregnancy with bioavailable iron, anti-inflammatory fatty acids, and vibrant cruciferous vegetables.',
      summaryBn:
          'মাসিক, গর্ভধারণ ও দৈনন্দিন শক্তিতে সমৃদ্ধ আয়রন, সামুদ্রিক মাছের ওমেগা-৩ ও রঙিন শাকসবজির পুষ্টিগুণের বিশদ নির্দেশিকা।',
      contentEn: '''
### The Biochemical Foundation of Hormone Synthesis
Hormones are synthesized from dietary lipids, amino acids, and essential micronutrients. Eating for hormonal harmony involves balancing blood sugar and replenishing critical vitamins lost during menstruation.

### 4 Nutrition Pillars:
1. **Bioavailable Heme & Non-Heme Iron:** Pair spinach, lentils, and chickpeas with Vitamin C (lemon juice, bell peppers) to boost absorption by up to 300%.
2. **Omega-3 Fatty Acids (EPA/DHA):** Chia seeds, walnuts, and fatty fish dampen inflammatory prostaglandin cascades and alleviate cramping.
3. **Methylated Folate (Vitamin B9):** Essential for DNA synthesis, cellular repair, and healthy fetal development during preconception and pregnancy.
4. **Cruciferous Veggies for Estrogen Clearance:** Broccoli and cabbage contain DIM (Diindolylmethane), assisting the liver in processing excess estrogens.
''',
      contentBn: '''
### হরমোন ও পুষ্টির মেলবন্ধন
আমাদের শরীরের হরমোনগুলো মূলত খাদ্য থেকে পাওয়া ফ্যাট, প্রোটিন ও ভিটামিনের সমন্বয়ে তৈরি হয়। সুষম পুষ্টি রক্তে শর্করার মাত্রা ঠিক রাখে এবং শক্তি জোগায়।

### খাদ্যতালিকায় যা রাখবেন:
১. **আয়রন সমৃদ্ধ খাবার:** কচু শাক, পালং শাক, ডাল, কলিজা ও বেদানার সাথে লেবুর রস (ভিটামিন সি) খান, এতে আয়রন দ্রুত শরীরে শোষিত হয়।
২. **ওমেগা-৩ ফ্যাটি এসিড:** চিয়া সিড, তিসি, কাঠবাদাম ও সামুদ্রিক মাছ প্রদাহ ও মাসিকের ব্যথা কমাতে সহায়ক।
৩. **ফলিক এসিড (Folate):** গর্ভবতী নারী এবং মায়েদের জন্য সুস্থ কোষ গঠনে সবুজ শাকসবজি ও ডিম অপরিহার্য।
৪. **ব্রকলি ও বাঁধাকপি:** লিভার থেকে অতিরিক্ত ক্ষতিকর ইস্ট্রোজেন হরমোন পরিষ্কার করতে সাহায্য করে।
''',
      keyTakeawaysEn: [
        'Pairing iron-rich foods with Vitamin C boosts iron absorption 3x.',
        'Omega-3s naturally reduce inflammatory prostaglandins during menses.',
        'Folate is crucial for preconception and healthy pregnancy development.'
      ],
      keyTakeawaysBn: [
        'আয়রনযুক্ত খাবারের সাথে লেবুর রস খেলে আয়রন শরীরে সহজে গ্রহণ হয়।',
        'ওমেগা-৩ ফ্যাটি এসিড শরীরের ভেতরের প্রদাহ ও ব্যথা কমায়।',
        'গর্ভধারণ ও সাধারণ সুস্থতায় শাকসবজি ও ফলিক এসিডের কোনো বিকল্প নেই।'
      ],
      authorOrSource: 'Harvard T.H. Chan School of Public Health',
      sourceUrl: 'https://www.hsph.harvard.edu/nutritionsource/',
      publishedDate: DateTime(2026, 8, 9),
      readTimeMinutes: 4,
      isFeatured: false,
      tags: ['Nutrition', 'Hormones', 'Iron', 'Folate', 'Pregnancy Care'],
      targetLifeStages: ['reproductive', 'pregnancy', 'postpartum'],
      targetPhases: ['all'],
      targetConcerns: ['nutrition', 'energy', 'pregnancy', 'anemia'],
    ),
  ];

  // ═════════════════════════════════════════════════════════════════════════════
  // CURATED DAILY HEALTH TIPS
  // ═════════════════════════════════════════════════════════════════════════════
  static final List<BloomDailyTip> _curatedDailyTips = [
    BloomDailyTip(
      id: 'tip_1',
      category: BloomCategory.skinCare,
      titleEn: 'Daily Skin Care Tip',
      titleBn: 'আজকের Skin Care টিপ',
      bodyEn: 'Apply your hyaluronic acid serum on slightly damp skin to draw hydration deep into the dermis rather than pulling moisture out.',
      bodyBn: 'হায়ালুরনিক অ্যাসিড সিরাম সবসময় হালকা ভেজা মুখে লাগান। এতে এটি ত্বকের গভীরে পানি ধরে রেখে ত্বককে সতেজ ও মোলায়েম রাখে।',
      actionStepEn: 'Mist your face with water before applying serum today.',
      actionStepBn: 'সিরাম লাগানোর আগে মুখে সামান্য পানি দিয়ে ভেজা রাখুন।',
      source: 'KHOLO Dermatology Board',
      date: DateTime.now(),
    ),
    BloomDailyTip(
      id: 'tip_2',
      category: BloomCategory.womenHealth,
      titleEn: 'Daily Hormone Insight',
      titleBn: 'আজকের Hormone টিপ',
      bodyEn: 'During the Follicular Phase, rising estrogen boosts energy, mental clarity, and skin collagen. Perfect time for creative projects!',
      bodyBn: 'ফলিকুলার ধাপে ইস্ট্রোজেন বাড়ার কারণে শরীরে উদ্যম ও ফোকাস বৃদ্ধি পায়। নতুন পরিকল্পনা ও কাজ শুরু করার এটাই সেরা সময়!',
      actionStepEn: 'Take 10 minutes to plan your most important task of the week.',
      actionStepBn: 'আজকের সবচেয়ে গুরুত্বপূর্ণ কাজের জন্য ১০ মিনিট সময় দিন।',
      source: 'KHOLO Endocrinology Science',
      date: DateTime.now(),
    ),
    BloomDailyTip(
      id: 'tip_3',
      category: BloomCategory.mentalWellness,
      titleEn: 'Daily Wellness Reminder',
      titleBn: 'আজকের Wellness রিমাইন্ডার',
      bodyEn: 'A 60-second deep belly breath lowers heart rate and signals your brain that you are completely safe.',
      bodyBn: 'মাত্র ৬০ সেকেন্ড গভীর শ্বাস-প্রশ্বাসের অনুশীলন আপনার মস্তিষ্কে শান্তির সংকেত পাঠায় এবং দ্রুত উদ্বেগ দূর করে।',
      actionStepEn: 'Do 3 cycles of 4-second box breathing right now.',
      actionStepBn: 'এখনই ৩ বার ৪ সেকেন্ড করে গভীর শ্বাস নিন এবং ছাড়ুন।',
      source: 'KHOLO Mind Care',
      date: DateTime.now(),
    ),
    BloomDailyTip(
      id: 'tip_4',
      category: BloomCategory.nutrition,
      titleEn: 'Daily Nutrition Insight',
      titleBn: 'আজকের Nutrition টিপ',
      bodyEn: 'Pair your green leafy vegetables with citrus juice or vitamin C to amplify iron absorption by 300%.',
      bodyBn: 'শাকসবজি বা ডাল খাওয়ার সময় লেবুর রস মিশিয়ে নিন, এতে আয়রন শরীরে ৩ গুণ দ্রুত কাজ করবে।',
      actionStepEn: 'Squeeze fresh lemon over your meal today.',
      actionStepBn: 'আজকের খাবারে এক টুকরো তাজা লেবুর রস যোগ করুন।',
      source: 'KHOLO Nutritional Science',
      date: DateTime.now(),
    ),
  ];
}
