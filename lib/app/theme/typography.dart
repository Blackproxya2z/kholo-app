import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

/// KHOLO typography system.
/// Display/headings: Playfair Display (editorial serif).
/// Body/controls: DM Sans (humanist sans).
class KholoTypography {
  KholoTypography._();

  static TextTheme buildTextTheme() =>
      _build(KholoColors.ink, KholoColors.inkMuted, KholoColors.inkSubtle);

  static TextTheme buildDarkTextTheme() => _build(
        const Color(0xFFF5E8F0),
        const Color(0xFFBB95AD),
        const Color(0xFF7D5A74),
      );

  static TextTheme _build(Color ink, Color inkMuted, Color inkSubtle) {
    return TextTheme(
      displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 48, fontWeight: FontWeight.w700, color: ink, letterSpacing: -1.5, height: 1.1),
      displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 36, fontWeight: FontWeight.w700, color: ink, letterSpacing: -1.0, height: 1.15),
      displaySmall: GoogleFonts.playfairDisplay(
          fontSize: 28, fontWeight: FontWeight.w600, color: ink, letterSpacing: -0.5, height: 1.2),
      headlineLarge: GoogleFonts.dmSans(
          fontSize: 24, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.3),
      headlineMedium: GoogleFonts.dmSans(
          fontSize: 20, fontWeight: FontWeight.w600, color: ink, letterSpacing: -0.2),
      headlineSmall: GoogleFonts.dmSans(
          fontSize: 18, fontWeight: FontWeight.w600, color: ink),
      titleLarge: GoogleFonts.dmSans(
          fontSize: 16, fontWeight: FontWeight.w600, color: ink),
      titleMedium: GoogleFonts.dmSans(
          fontSize: 14, fontWeight: FontWeight.w600, color: ink, letterSpacing: 0.1),
      titleSmall: GoogleFonts.dmSans(
          fontSize: 12, fontWeight: FontWeight.w600, color: inkMuted, letterSpacing: 0.5),
      bodyLarge: GoogleFonts.dmSans(
          fontSize: 16, fontWeight: FontWeight.w400, color: ink, height: 1.55),
      bodyMedium: GoogleFonts.dmSans(
          fontSize: 14, fontWeight: FontWeight.w400, color: ink, height: 1.55),
      bodySmall: GoogleFonts.dmSans(
          fontSize: 12, fontWeight: FontWeight.w400, color: inkMuted, height: 1.5),
      labelLarge: GoogleFonts.dmSans(
          fontSize: 14, fontWeight: FontWeight.w600, color: ink, letterSpacing: 0.2),
      labelMedium: GoogleFonts.dmSans(
          fontSize: 12, fontWeight: FontWeight.w500, color: inkMuted, letterSpacing: 0.3),
      labelSmall: GoogleFonts.dmSans(
          fontSize: 10, fontWeight: FontWeight.w500, color: inkSubtle, letterSpacing: 0.5),
    );
  }
}
