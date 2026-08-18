import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Emotional state representing KHOLO's caring connection to the user.
enum BrandEmotionalState {
  active,          // User is active (visited today or within 48h)
  gentleWaiting,   // 3-6 days inactive: gentle calm waiting
  caringReminder,  // 7-13 days inactive: warm caring reminder
  longingCare,     // 14+ days inactive: loving, supportive outreach
  welcomingBack,   // Just returned after 3+ days away
}

extension BrandEmotionalStateX on BrandEmotionalState {
  String get title {
    switch (this) {
      case BrandEmotionalState.active:
        return 'Calm & Radiant';
      case BrandEmotionalState.gentleWaiting:
        return 'Quietly Here for You';
      case BrandEmotionalState.caringReminder:
        return 'Caring Reminder';
      case BrandEmotionalState.longingCare:
        return 'KHOLO Misses You';
      case BrandEmotionalState.welcomingBack:
        return 'Welcome Back, Beautiful!';
    }
  }

  String get supportiveMessage {
    switch (this) {
      case BrandEmotionalState.active:
        return 'Your body and mind are in sync today. Take a gentle breath.';
      case BrandEmotionalState.gentleWaiting:
        return 'Whenever you need a moment of calm, KHOLO is quietly waiting for you.';
      case BrandEmotionalState.caringReminder:
        return 'A gentle check-in: How are you feeling in your body and heart today?';
      case BrandEmotionalState.longingCare:
        return 'We hope you are taking care of yourself. Your calm space is always open.';
      case BrandEmotionalState.welcomingBack:
        return 'It feels wonderful to see you again. Let\'s check in on your wellbeing.';
    }
  }

  String get emoji {
    switch (this) {
      case BrandEmotionalState.active:
        return '🌸';
      case BrandEmotionalState.gentleWaiting:
        return '🌿';
      case BrandEmotionalState.caringReminder:
        return '🕊️';
      case BrandEmotionalState.longingCare:
        return '🤍';
      case BrandEmotionalState.welcomingBack:
        return '✨';
    }
  }
}

/// ─── BRAND EMOTIONAL STATE & DYNAMIC ICON SYSTEM ────────────────────────────
///
/// Features:
/// 1. Low-overhead local activity tracker (zero battery drain).
/// 2. Calculates emotional connection based on last app visit and logging frequency.
/// 3. Never induces guilt; always provides warm, supportive wellness empathy.
/// 4. Welcomes returning users with delight.
/// ────────────────────────────────────────────────────────────────────────────
class BrandEmotionalStateService {
  static const String _keyLastOpen = 'kholo_last_open_timestamp';
  static const String _keyLastLog = 'kholo_last_log_timestamp';
  static const String _keyWasInactive = 'kholo_was_inactive_flag';

  BrandEmotionalStateService._();

  /// Records app open and returns the current emotional state.
  static Future<BrandEmotionalState> recordAppOpen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      final lastOpenMs = prefs.getInt(_keyLastOpen);

      bool wasInactive = false;
      if (lastOpenMs != null) {
        final daysSinceLastOpen = (now - lastOpenMs) / (1000 * 60 * 60 * 24);
        if (daysSinceLastOpen >= 3) {
          wasInactive = true;
        }
      }

      await prefs.setInt(_keyLastOpen, now);

      if (wasInactive) {
        await prefs.setBool(_keyWasInactive, true);
        return BrandEmotionalState.welcomingBack;
      }

      return await calculateState();
    } catch (e) {
      debugPrint('[BrandEmotionalService] Error recording app open: $e');
      return BrandEmotionalState.active;
    }
  }

  /// Calculates the current emotional state without updating last open time.
  static Future<BrandEmotionalState> calculateState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastOpenMs = prefs.getInt(_keyLastOpen);
      if (lastOpenMs == null) return BrandEmotionalState.active;

      final now = DateTime.now().millisecondsSinceEpoch;
      final daysSinceLastOpen = (now - lastOpenMs) / (1000 * 60 * 60 * 24);

      if (daysSinceLastOpen < 3) {
        return BrandEmotionalState.active;
      } else if (daysSinceLastOpen < 7) {
        return BrandEmotionalState.gentleWaiting;
      } else if (daysSinceLastOpen < 14) {
        return BrandEmotionalState.caringReminder;
      } else {
        return BrandEmotionalState.longingCare;
      }
    } catch (e) {
      return BrandEmotionalState.active;
    }
  }

  /// Records a health logging action (period, symptom, baby feeding, etc.).
  static Future<void> recordHealthLog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLastLog, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }
}
