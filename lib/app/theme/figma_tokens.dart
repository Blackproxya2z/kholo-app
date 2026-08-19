import 'package:flutter/material.dart';

/// ─── KHOLO FIGMA DESIGN SYSTEM TOKENS ──────────────────────────────────────
///
/// Complete 1-to-1 mapping with Figma Variables, Color Palettes, Typography,
/// Elevation, Spacing, and Component Specs.
///
/// To customize the app design:
/// 1. Edit values here or in your Figma file.
/// 2. Change any hex color, radius, or typography style.
/// 3. All screens automatically inherit these styles across light and dark modes.
/// ────────────────────────────────────────────────────────────────────────────

class FigmaColors {
  FigmaColors._();

  // ── Brand Primary & Accents ───────────────────────────────────────────────
  static const Color blush = Color(0xFFFFADEE); // Primary highlight & soft accents
  static const Color wine = Color(0xFF92003A); // Brand dominant & primary CTA
  static const Color plum = Color(0xFF5A0025); // Deep luxury plum
  static const Color magenta = Color(0xFFF62477); // Vibrant radiant glow
  static const Color warmGold = Color(0xFFFFE185); // Pregnancy & baby gold accent
  static const Color oatmeal = Color(0xFFFFFDFC); // Light background canvas
  static const Color cream = Color(0xFFFFF8F2); // Warm card backdrop

  // ── Status & Feedback ─────────────────────────────────────────────────────
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFE65100);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color error = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF1976D2);
  static const Color infoLight = Color(0xFFE3F2FD);

  // ── Dark Mode Palette ─────────────────────────────────────────────────────
  static const Color darkCanvas = Color(0xFF140B13); // Deep velvet night
  static const Color darkCard = Color(0xFF21131E); // Elevated dark surface
  static const Color darkCardElevated = Color(0xFF2E1A2B); // High-contrast container
  static const Color darkBorder = Color(0xFF45223C); // Subtle plum border
  static const Color darkInk = Color(0xFFFDE8F5); // High-contrast text
  static const Color darkInkMuted = Color(0xFFC79DBE); // Medium emphasis text

  // ── Light Mode Neutrals ───────────────────────────────────────────────────
  static const Color lightCanvas = Color(0xFFFFFDFC);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardElevated = Color(0xFFFFF7FA);
  static const Color lightBorder = Color(0xFFFFE5F3);
  static const Color lightInk = Color(0xFF26101B);
  static const Color lightInkMuted = Color(0xFF7A6472);
  static const Color lightInkSubtle = Color(0xFFA694A0);

  // ── Figma Gradients ───────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [wine, magenta],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blushGradient = LinearGradient(
    colors: [Color(0xFFFFD1F4), Color(0xFFFFADEE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF281423), Color(0xFF1C0D19)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class FigmaSpacing {
  FigmaSpacing._();

  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 40.0;
  static const double giant = 48.0;
}

class FigmaRadii {
  FigmaRadii._();

  static const double sm = 8.0;
  static const double md = 14.0;
  static const double lg = 20.0;
  static const double xl = 28.0;
  static const double pill = 999.0;

  static BorderRadius get roundedSm => BorderRadius.circular(sm);
  static BorderRadius get roundedMd => BorderRadius.circular(md);
  static BorderRadius get roundedLg => BorderRadius.circular(lg);
  static BorderRadius get roundedXl => BorderRadius.circular(xl);
  static BorderRadius get roundedPill => BorderRadius.circular(pill);
}

class FigmaShadows {
  FigmaShadows._();

  static List<BoxShadow> get cardLight => [
        BoxShadow(
          color: const Color(0xFF92003A).withValues(alpha: 0.05),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get cardDark => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get buttonGlow => [
        BoxShadow(
          color: const Color(0xFFF62477).withValues(alpha: 0.3),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];
}
