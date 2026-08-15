import 'package:flutter/material.dart';

/// KHOLO brand color tokens.
/// Built around the 4 core brand palette colors:
/// - Deep Wine: #92003A / rgb(146, 0, 58)
/// - Vivid Magenta: #F62477 / rgb(246, 36, 119)
/// - Soft Orchid Blush: #FFADEE / rgb(255, 173, 238)
/// - Warm Butter Gold: #FFE185 / rgb(255, 225, 133)
class KholoColors {
  KholoColors._();

  // ── Core Brand Palette (The 4 Brand Colors) ────────────────────────────────
  /// 1. Deep Velvet Wine / Crimson Berry (#92003A / rgb(146, 0, 58))
  static const Color wine = Color(0xFF92003A);

  /// 2. Vivid Rose / Electric Magenta (#F62477 / rgb(246, 36, 119))
  static const Color magenta = Color(0xFFF62477);

  /// 3. Soft Orchid / Blossom Blush (#FFADEE / rgb(255, 173, 238))
  static const Color blush = Color(0xFFFFADEE);

  /// 4. Warm Sunbeam / Butter Gold (#FFE185 / rgb(255, 225, 133))
  static const Color warmGold = Color(0xFFFFE185);

  // ── Primary Aliases ────────────────────────────────────────────────────────
  static const Color primary = wine; // #92003A
  static const Color primaryLight = Color(0xFFFFD6F2); // Soft wine-tinted blush
  static const Color primaryDark = Color(0xFF5E0025); // Deep wine shadow

  static const Color secondary = magenta; // #F62477
  static const Color secondaryLight = blush; // #FFADEE
  static const Color secondaryDark = Color(0xFFC70E58);

  static const Color tertiary = warmGold; // #FFE185
  static const Color tertiaryLight = Color(0xFFFFF9EC);
  static const Color tertiaryDark = Color(0xFFD49B28);

  // ── Canvas & surfaces ──────────────────────────────────────────────────────
  static const Color canvas = Color(0xFFFFFDFC); // Soft porcelain white
  static const Color cream = Color(0xFFFFF8F2); // Warm delicate cream
  static const Color cardSurface = Color(0xFFFFF1F7); // Soft blush-tinted card surface

  // ── Primary ink & typography ───────────────────────────────────────────────
  static const Color ink = Color(0xFF2C1625); // Deep rich wine-toned dark ink
  static const Color inkMuted = Color(0xFF6E4D64); // Muted berry ink
  static const Color inkSubtle = Color(0xFFA3829A); // Subtle mauve ink

  // ── Phase palette ─────────────────────────────────────────────────────────
  /// Menstrual phase — vivid rose magenta (#F62477)
  static const Color rose = magenta;
  static const Color roseLight = Color(0xFFFFE6F3);
  static const Color roseDark = Color(0xFFC70E58);

  /// Follicular / fertile — soft orchid / blush (#FFADEE) & wine accent
  static const Color lavender = Color(0xFFD678BF);
  static const Color lavenderLight = Color(0xFFFFF0FA);
  static const Color lavenderDark = wine;

  /// Ovulation / peak energy — deep velvet wine (#92003A)
  static const Color plum = wine;
  static const Color plumLight = Color(0xFFBA1C56);
  static const Color plumDark = Color(0xFF5E0025);

  /// Luteal — warm butter gold glow (#FFE185)
  static const Color lutealTint = Color(0xFFFFF9EB);
  static const Color lutealAccent = warmGold;

  // ── Baby care & pregnancy accent ──────────────────────────────────────────
  static const Color sage = Color(0xFFE89376);
  static const Color sageLight = Color(0xFFFFF1EB);
  static const Color sageDark = Color(0xFFB85939);

  // ── Utility ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF38A169);
  static const Color warning = warmGold; // #FFE185
  static const Color error = Color(0xFFD9383A);
  static const Color divider = Color(0xFFF3E2ED);

  // ── Phase convenience map ─────────────────────────────────────────────────
  static Color phaseColor(String phase) {
    switch (phase) {
      case 'menstrual':
        return rose;
      case 'follicular':
        return lavender;
      case 'ovulation':
        return plum;
      case 'luteal':
        return lutealAccent;
      default:
        return primary;
    }
  }

  static Color phaseLightColor(String phase) {
    switch (phase) {
      case 'menstrual':
        return roseLight;
      case 'follicular':
        return lavenderLight;
      case 'ovulation':
        return primaryLight;
      case 'luteal':
        return lutealTint;
      default:
        return cream;
    }
  }
}
