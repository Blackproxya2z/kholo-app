import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/bloom_models.dart';
import '../services/bloom_health_service.dart';
import '../services/bloom_ai_guide_service.dart';
import 'providers.dart';

/// ─── KHOLO BLOOM HEALTH HUB STATE MANAGEMENT ─────────────────────────────────

final bloomServiceProvider = Provider<BloomHealthService>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return BloomHealthService(prefs);
});

/// ─── Language Provider ───────────────────────────────────────────────────────
class BloomLanguageNotifier extends StateNotifier<BloomLanguage> {
  final BloomHealthService _service;

  BloomLanguageNotifier(this._service) : super(_service.getLanguage());

  Future<void> setLanguage(BloomLanguage lang) async {
    await _service.setLanguage(lang);
    state = lang;
  }

  void toggle() {
    final next = state == BloomLanguage.bn ? BloomLanguage.en : BloomLanguage.bn;
    setLanguage(next);
  }
}

final bloomLanguageProvider =
    StateNotifierProvider<BloomLanguageNotifier, BloomLanguage>((ref) {
  return BloomLanguageNotifier(ref.watch(bloomServiceProvider));
});

/// ─── Articles State Management ───────────────────────────────────────────────
class BloomArticlesNotifier extends StateNotifier<List<BloomArticle>> {
  final BloomHealthService _service;

  BloomArticlesNotifier(this._service) : super(_service.getAllArticles());

  void refresh() {
    state = _service.getAllArticles();
  }

  Future<bool> toggleBookmark(String articleId) async {
    final isSaved = await _service.toggleBookmark(articleId);
    state = _service.getAllArticles();
    return isSaved;
  }

  Future<void> recordRead(String articleId) async {
    await _service.recordArticleRead(articleId);
    state = _service.getAllArticles();
  }
}

final bloomArticlesProvider =
    StateNotifierProvider<BloomArticlesNotifier, List<BloomArticle>>((ref) {
  return BloomArticlesNotifier(ref.watch(bloomServiceProvider));
});

/// ─── Saved / Bookmarked Articles ─────────────────────────────────────────────
final bloomSavedArticlesProvider = Provider<List<BloomArticle>>((ref) {
  final articles = ref.watch(bloomArticlesProvider);
  return articles.where((a) => a.isSaved).toList();
});

/// ─── Personalized Feed (AI Adapted) ──────────────────────────────────────────
final bloomPersonalizedFeedProvider = Provider<List<BloomArticle>>((ref) {
  final service = ref.watch(bloomServiceProvider);
  final profile = ref.watch(healthProfileProvider);
  // Re-read when articles change
  ref.watch(bloomArticlesProvider);
  return service.getPersonalizedFeed(profile);
});

/// ─── Daily Tip & User Streak ─────────────────────────────────────────────────
final bloomDailyTipProvider = Provider<BloomDailyTip>((ref) {
  final service = ref.watch(bloomServiceProvider);
  return service.getDailyTip();
});

final bloomUserProgressProvider = Provider<BloomUserProgress>((ref) {
  final service = ref.watch(bloomServiceProvider);
  // Depend on articles notifier to reflect streak & read changes
  ref.watch(bloomArticlesProvider);
  return service.getUserProgress();
});

/// ─── Realtime Search ─────────────────────────────────────────────────────────
final bloomSearchQueryProvider = StateProvider<String>((ref) => '');

final bloomSearchResultsProvider = Provider<List<BloomArticle>>((ref) {
  final query = ref.watch(bloomSearchQueryProvider);
  final service = ref.watch(bloomServiceProvider);
  ref.watch(bloomArticlesProvider);
  return service.searchArticles(query);
});

/// ─── AI Health Guide Chat ────────────────────────────────────────────────────
class BloomAiChatNotifier extends StateNotifier<List<BloomAiMessage>> {
  final BloomLanguage _lang;
  bool _isTyping = false;

  BloomAiChatNotifier(this._lang)
      : super([BloomAiGuideService.getWelcomeMessage(_lang)]);

  bool get isTyping => _isTyping;

  Future<void> sendMessage(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    final userMsg = BloomAiMessage(
      id: const Uuid().v4(),
      isUser: true,
      text: cleanText,
      timestamp: DateTime.now(),
    );

    state = [...state, userMsg];
    _isTyping = true;

    final aiResponse = await BloomAiGuideService.askQuestion(cleanText, _lang);
    _isTyping = false;

    state = [...state, aiResponse];
  }

  void reset() {
    state = [BloomAiGuideService.getWelcomeMessage(_lang)];
  }
}

final bloomAiChatProvider =
    StateNotifierProvider<BloomAiChatNotifier, List<BloomAiMessage>>((ref) {
  final lang = ref.watch(bloomLanguageProvider);
  return BloomAiChatNotifier(lang);
});
