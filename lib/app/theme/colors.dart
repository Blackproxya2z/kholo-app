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

  // ── Light Theme Base Tokens ────────────────────────────────────────────────
  static const Color canvas = Color(0xFFFFFDFC); // Soft porcelain white
  static const Color cream = Color(0xFFFFF8F2); // Warm delicate cream
  static const Color cardSurface = Color(0xFFFFF1F7); // Soft blush-tinted card surface

  // ── Dark Theme Luxury Base Tokens ──────────────────────────────────────────
  static const Color darkCanvas = Color(0xFF140A12); // Deep Velvet Wine Charcoal
  static const Color darkSurface = Color(0xFF1E101C); // Soft Warm Blackberry
  static const Color darkCard = Color(0xFF281525); // Elevated Plum Night
  static const Color darkCardElevated = Color(0xFF331B30); // Higher Elevation Plum
  static const Color darkDivider = Color(0xFF40223A); // Deep Berry Divider
  static const Color darkInk = Color(0xFFFFF0F8); // Soft Crisp Ivory Blush
  static const Color darkInkMuted = Color(0xFFC4A7BD); // Soft Mauve
  static const Color darkInkSubtle = Color(0xFF8E6D87); // Muted Berry

  // ── Primary ink & typography (Light) ───────────────────────────────────────
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
  static const Color terracotta = Color(0xFFC85A32);
  static const Color terracottaLight = Color(0xFFFFF0EB);
  static const Color terracottaDark = Color(0xFF9E3F1D);

  static const Color sage = Color(0xFFE89376);
  static const Color sageLight = Color(0xFFFFF1EB);
  static const Color sageDark = Color(0xFFB85939);

  // ── Utility ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF38A169);
  static const Color warning = warmGold; // #FFE185
  static const Color error = Color(0xFFD9383A);
  static const Color divider = Color(0xFFF3E2ED);

  // ── Dynamic Theme Helpers (Light vs Dark) ───────────────────────────────────
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color canvasOf(BuildContext context) =>
      isDark(context) ? darkCanvas : canvas;

  static Color surfaceOf(BuildContext context) =>
      isDark(context) ? darkSurface : cream;

  static Color cardOf(BuildContext context) =>
      isDark(context) ? darkCard : Colors.white;

  static Color cardSecondaryOf(BuildContext context) =>
      isDark(context) ? darkCardElevated : cardSurface;

  static Color inkOf(BuildContext context) =>
      isDark(context) ? darkInk : ink;

  static Color inkMutedOf(BuildContext context) =>
      isDark(context) ? darkInkMuted : inkMuted;

  static Color inkSubtleOf(BuildContext context) =>
      isDark(context) ? darkInkSubtle : inkSubtle;

  static Color dividerOf(BuildContext context) =>
      isDark(context) ? darkDivider : divider;

  static Color tintOf(BuildContext context, Color color,
      {double lightAlpha = 0.12, double darkAlpha = 0.22}) {
    return isDark(context)
        ? color.withValues(alpha: darkAlpha)
        : color.withValues(alpha: lightAlpha);
  }

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

  static Color phaseLightColorOf(BuildContext context, String phase) {
    final dark = isDark(context);
    switch (phase) {
      case 'menstrual':
        return dark ? rose.withValues(alpha: 0.22) : roseLight;
      case 'follicular':
        return dark ? lavender.withValues(alpha: 0.22) : lavenderLight;
      case 'ovulation':
        return dark ? plum.withValues(alpha: 0.25) : primaryLight;
      case 'luteal':
        return dark ? warmGold.withValues(alpha: 0.20) : lutealTint;
      default:
        return surfaceOf(context);
    }
  }
}

/// Convenience Extension on BuildContext for quick access to dynamic colors
extension KholoThemeExtension on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get kCanvas => KholoColors.canvasOf(this);
  Color get kSurface => KholoColors.surfaceOf(this);
  Color get kCard => KholoColors.cardOf(this);
  Color get kCardElevated => KholoColors.cardSecondaryOf(this);
  Color get kCardSecondary => KholoColors.cardSecondaryOf(this);
  Color get kInk => KholoColors.inkOf(this);
  Color get kInkMuted => KholoColors.inkMutedOf(this);
  Color get kInkSubtle => KholoColors.inkSubtleOf(this);
  Color get kDivider => KholoColors.dividerOf(this);
  Color kTint(Color color, {double lightAlpha = 0.12, double darkAlpha = 0.22}) =>
      KholoColors.tintOf(this, color, lightAlpha: lightAlpha, darkAlpha: darkAlpha);
}
