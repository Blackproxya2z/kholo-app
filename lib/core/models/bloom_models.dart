import 'package:flutter/material.dart';

/// ─── KHOLO BLOOM HEALTH HUB DOMAIN MODELS ────────────────────────────────────
///
/// Features:
/// 1. Bilingual support (English & Bengali).
/// 2. 6 Core Health Categories with dedicated colors & icons.
/// 3. AI Personalization & Life-stage tagging.
/// 4. Evidence-based medical metadata & trusted sources (WHO, NHS, CDC, ACOG).
/// 5. Daily health tips & streak tracking.
/// ─────────────────────────────────────────────────────────────────────────────

enum BloomLanguage {
  en,
  bn;

  String get code => name;
  String get label => this == BloomLanguage.bn ? 'বাংলা' : 'English';
}

enum BloomCategory {
  womenHealth(
    id: 'women_health',
    titleEn: 'Women Health',
    titleBn: 'নারী স্বাস্থ্য',
    icon: '🌸',
    accentColor: Color(0xFFD47070),
    gradient: [Color(0xFFE89A9A), Color(0xFFD47070)],
    subcategories: [
      'Period Health',
      'PMS & Ovulation',
      'Hormones',
      'PCOS Awareness',
      'Fertility',
      'Pregnancy Care',
      'Postpartum Recovery'
    ],
  ),
  skinCare(
    id: 'skin_care',
    titleEn: 'Skin Care',
    titleBn: 'ত্বকের যত্ন',
    icon: '✨',
    accentColor: Color(0xFFB88258),
    gradient: [Color(0xFFD4A373), Color(0xFFB88258)],
    subcategories: [
      'Acne Education',
      'Skin Barrier Health',
      'Active Ingredients',
      'Sunscreen Science',
      'Anti-Aging',
      'Dermatology Tips'
    ],
  ),
  sexualWellness(
    id: 'sexual_wellness',
    titleEn: 'Sexual Wellness',
    titleBn: 'যৌন ও প্রজনন স্বাস্থ্য',
    icon: '❤️',
    accentColor: Color(0xFFC04D68),
    gradient: [Color(0xFFDD6B85), Color(0xFFC04D68)],
    subcategories: [
      'Sexual Health Awareness',
      'Safe Intimacy',
      'Body Education',
      'Relationship Wellness',
      'Scientific Body Facts'
    ],
  ),
  menHealth(
    id: 'men_health',
    titleEn: 'Men Health',
    titleBn: 'পুরুষ স্বাস্থ্য',
    icon: '🌿',
    accentColor: Color(0xFF4A7C59),
    gradient: [Color(0xFF6B9E78), Color(0xFF4A7C59)],
    subcategories: [
      'Male Hormones',
      'Physical Fitness',
      'Sexual Wellness',
      'Lifestyle & Vitality'
    ],
  ),
  mentalWellness(
    id: 'mental_wellness',
    titleEn: 'Mental Wellness',
    titleBn: 'মানসিক প্রশান্তি',
    icon: '🧘‍♀️',
    accentColor: Color(0xFF6B7280),
    gradient: [Color(0xFF8B93A2), Color(0xFF5A6270)],
    subcategories: [
      'Stress Relief',
      'Sleep Hygiene',
      'Anxiety Management',
      'Emotional Resilience'
    ],
  ),
  nutrition(
    id: 'nutrition',
    titleEn: 'Nutrition',
    titleBn: 'পুষ্টি ও খাদ্য',
    icon: '🥗',
    accentColor: Color(0xFF84A98C),
    gradient: [Color(0xFF98BC9E), Color(0xFF6E8E75)],
    subcategories: [
      'Hormone-Balancing Foods',
      'Essential Vitamins',
      'Hydration Science',
      'Metabolic Wellness'
    ],
  );

  const BloomCategory({
    required this.id,
    required this.titleEn,
    required this.titleBn,
    required this.icon,
    required this.accentColor,
    required this.gradient,
    required this.subcategories,
  });

  final String id;
  final String titleEn;
  final String titleBn;
  final String icon;
  final Color accentColor;
  final List<Color> gradient;
  final List<String> subcategories;

  String localizedTitle(BloomLanguage lang) =>
      lang == BloomLanguage.bn ? titleBn : titleEn;

  static BloomCategory fromId(String id) {
    return BloomCategory.values.firstWhere(
      (c) => c.id == id,
      orElse: () => BloomCategory.womenHealth,
    );
  }
}

class BloomArticle {
  final String id;
  final BloomCategory category;
  final String titleEn;
  final String titleBn;
  final String summaryEn;
  final String summaryBn;
  final String contentEn;
  final String contentBn;
  final List<String> keyTakeawaysEn;
  final List<String> keyTakeawaysBn;
  final String authorOrSource;
  final String sourceUrl;
  final DateTime publishedDate;
  final int readTimeMinutes;
  final String? coverImageUrl;
  final List<String> tags;
  final bool isFeatured;
  final int viewsCount;
  final int likesCount;
  final bool isSaved;
  final bool isCompleted;
  final List<String> targetLifeStages;
  final List<String> targetPhases;
  final List<String> targetConcerns;

  const BloomArticle({
    required this.id,
    required this.category,
    required this.titleEn,
    required this.titleBn,
    required this.summaryEn,
    required this.summaryBn,
    required this.contentEn,
    required this.contentBn,
    required this.keyTakeawaysEn,
    required this.keyTakeawaysBn,
    required this.authorOrSource,
    this.sourceUrl = 'https://www.who.int',
    required this.publishedDate,
    required this.readTimeMinutes,
    this.coverImageUrl,
    this.tags = const [],
    this.isFeatured = false,
    this.viewsCount = 120,
    this.likesCount = 45,
    this.isSaved = false,
    this.isCompleted = false,
    this.targetLifeStages = const [],
    this.targetPhases = const [],
    this.targetConcerns = const [],
  });

  String getTitle(BloomLanguage lang) =>
      lang == BloomLanguage.bn ? titleBn : titleEn;

  String getSummary(BloomLanguage lang) =>
      lang == BloomLanguage.bn ? summaryBn : summaryEn;

  String getContent(BloomLanguage lang) =>
      lang == BloomLanguage.bn ? contentBn : contentEn;

  List<String> getKeyTakeaways(BloomLanguage lang) =>
      lang == BloomLanguage.bn ? keyTakeawaysBn : keyTakeawaysEn;

  BloomArticle copyWith({
    String? id,
    BloomCategory? category,
    String? titleEn,
    String? titleBn,
    String? summaryEn,
    String? summaryBn,
    String? contentEn,
    String? contentBn,
    List<String>? keyTakeawaysEn,
    List<String>? keyTakeawaysBn,
    String? authorOrSource,
    String? sourceUrl,
    DateTime? publishedDate,
    int? readTimeMinutes,
    String? coverImageUrl,
    List<String>? tags,
    bool? isFeatured,
    int? viewsCount,
    int? likesCount,
    bool? isSaved,
    bool? isCompleted,
    List<String>? targetLifeStages,
    List<String>? targetPhases,
    List<String>? targetConcerns,
  }) {
    return BloomArticle(
      id: id ?? this.id,
      category: category ?? this.category,
      titleEn: titleEn ?? this.titleEn,
      titleBn: titleBn ?? this.titleBn,
      summaryEn: summaryEn ?? this.summaryEn,
      summaryBn: summaryBn ?? this.summaryBn,
      contentEn: contentEn ?? this.contentEn,
      contentBn: contentBn ?? this.contentBn,
      keyTakeawaysEn: keyTakeawaysEn ?? this.keyTakeawaysEn,
      keyTakeawaysBn: keyTakeawaysBn ?? this.keyTakeawaysBn,
      authorOrSource: authorOrSource ?? this.authorOrSource,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      publishedDate: publishedDate ?? this.publishedDate,
      readTimeMinutes: readTimeMinutes ?? this.readTimeMinutes,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      tags: tags ?? this.tags,
      isFeatured: isFeatured ?? this.isFeatured,
      viewsCount: viewsCount ?? this.viewsCount,
      likesCount: likesCount ?? this.likesCount,
      isSaved: isSaved ?? this.isSaved,
      isCompleted: isCompleted ?? this.isCompleted,
      targetLifeStages: targetLifeStages ?? this.targetLifeStages,
      targetPhases: targetPhases ?? this.targetPhases,
      targetConcerns: targetConcerns ?? this.targetConcerns,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.id,
        'titleEn': titleEn,
        'titleBn': titleBn,
        'summaryEn': summaryEn,
        'summaryBn': summaryBn,
        'contentEn': contentEn,
        'contentBn': contentBn,
        'keyTakeawaysEn': keyTakeawaysEn,
        'keyTakeawaysBn': keyTakeawaysBn,
        'authorOrSource': authorOrSource,
        'sourceUrl': sourceUrl,
        'publishedDate': publishedDate.toIso8601String(),
        'readTimeMinutes': readTimeMinutes,
        'coverImageUrl': coverImageUrl,
        'tags': tags,
        'isFeatured': isFeatured,
        'viewsCount': viewsCount,
        'likesCount': likesCount,
        'isSaved': isSaved,
        'isCompleted': isCompleted,
        'targetLifeStages': targetLifeStages,
        'targetPhases': targetPhases,
        'targetConcerns': targetConcerns,
      };

  factory BloomArticle.fromJson(Map<String, dynamic> json) {
    return BloomArticle(
      id: json['id'] as String? ?? 'art_unknown',
      category: BloomCategory.fromId(json['category'] as String? ?? 'women_health'),
      titleEn: json['titleEn'] as String? ?? '',
      titleBn: json['titleBn'] as String? ?? '',
      summaryEn: json['summaryEn'] as String? ?? '',
      summaryBn: json['summaryBn'] as String? ?? '',
      contentEn: json['contentEn'] as String? ?? '',
      contentBn: json['contentBn'] as String? ?? '',
      keyTakeawaysEn: (json['keyTakeawaysEn'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      keyTakeawaysBn: (json['keyTakeawaysBn'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      authorOrSource: json['authorOrSource'] as String? ?? 'WHO & Medical Review Board',
      sourceUrl: json['sourceUrl'] as String? ?? 'https://www.who.int',
      publishedDate: DateTime.tryParse(json['publishedDate'] as String? ?? '') ??
          DateTime.now(),
      readTimeMinutes: json['readTimeMinutes'] as int? ?? 3,
      coverImageUrl: json['coverImageUrl'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      isFeatured: json['isFeatured'] as bool? ?? false,
      viewsCount: json['viewsCount'] as int? ?? 100,
      likesCount: json['likesCount'] as int? ?? 30,
      isSaved: json['isSaved'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? false,
      targetLifeStages: (json['targetLifeStages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      targetPhases: (json['targetPhases'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      targetConcerns: (json['targetConcerns'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class BloomDailyTip {
  final String id;
  final BloomCategory category;
  final String titleEn;
  final String titleBn;
  final String bodyEn;
  final String bodyBn;
  final String actionStepEn;
  final String actionStepBn;
  final String source;
  final DateTime date;

  const BloomDailyTip({
    required this.id,
    required this.category,
    required this.titleEn,
    required this.titleBn,
    required this.bodyEn,
    required this.bodyBn,
    required this.actionStepEn,
    required this.actionStepBn,
    required this.source,
    required this.date,
  });

  String getTitle(BloomLanguage lang) =>
      lang == BloomLanguage.bn ? titleBn : titleEn;

  String getBody(BloomLanguage lang) =>
      lang == BloomLanguage.bn ? bodyBn : bodyEn;

  String getActionStep(BloomLanguage lang) =>
      lang == BloomLanguage.bn ? actionStepBn : actionStepEn;

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.id,
        'titleEn': titleEn,
        'titleBn': titleBn,
        'bodyEn': bodyEn,
        'bodyBn': bodyBn,
        'actionStepEn': actionStepEn,
        'actionStepBn': actionStepBn,
        'source': source,
        'date': date.toIso8601String(),
      };

  factory BloomDailyTip.fromJson(Map<String, dynamic> json) {
    return BloomDailyTip(
      id: json['id'] as String? ?? 'tip_1',
      category: BloomCategory.fromId(json['category'] as String? ?? 'skin_care'),
      titleEn: json['titleEn'] as String? ?? '',
      titleBn: json['titleBn'] as String? ?? '',
      bodyEn: json['bodyEn'] as String? ?? '',
      bodyBn: json['bodyBn'] as String? ?? '',
      actionStepEn: json['actionStepEn'] as String? ?? '',
      actionStepBn: json['actionStepBn'] as String? ?? '',
      source: json['source'] as String? ?? 'KHOLO Health Science',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class BloomAiMessage {
  final String id;
  final bool isUser;
  final String text;
  final String? title;
  final List<String>? bulletPoints;
  final String? clinicalSource;
  final bool isMedicalDisclaimer;
  final DateTime timestamp;

  const BloomAiMessage({
    required this.id,
    required this.isUser,
    required this.text,
    this.title,
    this.bulletPoints,
    this.clinicalSource,
    this.isMedicalDisclaimer = false,
    required this.timestamp,
  });
}

class BloomUserProgress {
  final int streakDays;
  final DateTime? lastReadDate;
  final List<String> savedArticleIds;
  final List<String> completedArticleIds;

  const BloomUserProgress({
    this.streakDays = 1,
    this.lastReadDate,
    this.savedArticleIds = const [],
    this.completedArticleIds = const [],
  });

  BloomUserProgress copyWith({
    int? streakDays,
    DateTime? lastReadDate,
    List<String>? savedArticleIds,
    List<String>? completedArticleIds,
  }) {
    return BloomUserProgress(
      streakDays: streakDays ?? this.streakDays,
      lastReadDate: lastReadDate ?? this.lastReadDate,
      savedArticleIds: savedArticleIds ?? this.savedArticleIds,
      completedArticleIds: completedArticleIds ?? this.completedArticleIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'streakDays': streakDays,
        'lastReadDate': lastReadDate?.toIso8601String(),
        'savedArticleIds': savedArticleIds,
        'completedArticleIds': completedArticleIds,
      };

  factory BloomUserProgress.fromJson(Map<String, dynamic> json) {
    return BloomUserProgress(
      streakDays: json['streakDays'] as int? ?? 1,
      lastReadDate: json['lastReadDate'] != null
          ? DateTime.tryParse(json['lastReadDate'] as String)
          : null,
      savedArticleIds: (json['savedArticleIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      completedArticleIds: (json['completedArticleIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
