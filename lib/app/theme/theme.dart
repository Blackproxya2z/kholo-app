import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';

/// KHOLO full ThemeData — light and dark.
class KholoTheme {
  KholoTheme._();

  // ── Light Theme ────────────────────────────────────────────────────────────

  static ThemeData get light {
    final textTheme = KholoTypography.buildTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: KholoColors.wine,
        onPrimary: Colors.white,
        primaryContainer: KholoColors.blush,
        onPrimaryContainer: KholoColors.wine,
        secondary: KholoColors.magenta,
        onSecondary: Colors.white,
        secondaryContainer: KholoColors.roseLight,
        onSecondaryContainer: KholoColors.roseDark,
        tertiary: KholoColors.warmGold,
        onTertiary: KholoColors.ink,
        tertiaryContainer: KholoColors.lutealTint,
        onTertiaryContainer: Color(0xFF7A5400),
        error: KholoColors.error,
        onError: Colors.white,
        errorContainer: Color(0xFFFDE8E8),
        onErrorContainer: KholoColors.error,
        surface: KholoColors.canvas,
        onSurface: KholoColors.ink,
        surfaceContainerHighest: KholoColors.cream,
        onSurfaceVariant: KholoColors.inkMuted,
        outline: KholoColors.divider,
        outlineVariant: KholoColors.divider,
        shadow: Color(0x1492003A),
        scrim: Color(0x522C1625),
        inverseSurface: KholoColors.ink,
        onInverseSurface: KholoColors.canvas,
        inversePrimary: KholoColors.blush,
      ),
      scaffoldBackgroundColor: KholoColors.canvas,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: KholoColors.canvas,
        foregroundColor: KholoColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.headlineSmall?.copyWith(color: KholoColors.ink),
        iconTheme: const IconThemeData(color: KholoColors.ink),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: KholoColors.wine,
        unselectedItemColor: KholoColors.inkSubtle,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      cardTheme: CardThemeData(
        color: KholoColors.cream,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KholoColors.wine,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          textStyle: textTheme.labelLarge?.copyWith(color: Colors.white),
          minimumSize: const Size(44, 52),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: KholoColors.wine,
          side: const BorderSide(color: KholoColors.magenta, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          textStyle: textTheme.labelLarge?.copyWith(color: KholoColors.wine),
          minimumSize: const Size(44, 52),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: KholoColors.wine,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: textTheme.labelLarge?.copyWith(color: KholoColors.wine),
          minimumSize: const Size(44, 44),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: KholoColors.cream,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: KholoColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: KholoColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: KholoColors.wine, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: KholoColors.error),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: KholoColors.inkMuted),
        hintStyle: textTheme.bodyMedium?.copyWith(color: KholoColors.inkSubtle),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: KholoColors.blush,
        selectedColor: KholoColors.wine,
        labelStyle: textTheme.labelMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(
        color: KholoColors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // ── Dark Theme ─────────────────────────────────────────────────────────────

  static ThemeData get dark {
    const darkCanvas = Color(0xFF1A0D14);
    const darkSurface = Color(0xFF261320);
    const darkCard = Color(0xFF2E1826);
    const darkDivider = Color(0xFF3D2035);
    const darkInk = Color(0xFFF5E8F0);
    const darkInkMuted = Color(0xFFBB95AD);
    const darkInkSubtle = Color(0xFF7D5A74);

    final textTheme = KholoTypography.buildDarkTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: KholoColors.magenta,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF5E0025),
        onPrimaryContainer: KholoColors.blush,
        secondary: KholoColors.blush,
        onSecondary: KholoColors.wine,
        secondaryContainer: Color(0xFF3D1030),
        onSecondaryContainer: KholoColors.blush,
        tertiary: KholoColors.warmGold,
        onTertiary: KholoColors.ink,
        tertiaryContainer: Color(0xFF3D3000),
        onTertiaryContainer: KholoColors.warmGold,
        error: Color(0xFFFF6B6B),
        onError: Colors.white,
        errorContainer: Color(0xFF4D1515),
        onErrorContainer: Color(0xFFFF6B6B),
        surface: darkCanvas,
        onSurface: darkInk,
        surfaceContainerHighest: darkCard,
        onSurfaceVariant: darkInkMuted,
        outline: darkDivider,
        outlineVariant: darkDivider,
        shadow: Color(0x4492003A),
        scrim: Color(0x881A0D14),
        inverseSurface: darkInk,
        onInverseSurface: darkCanvas,
        inversePrimary: KholoColors.wine,
      ),
      scaffoldBackgroundColor: darkCanvas,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: darkCanvas,
        foregroundColor: darkInk,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.headlineSmall?.copyWith(color: darkInk),
        iconTheme: const IconThemeData(color: darkInk),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: KholoColors.magenta,
        unselectedItemColor: darkInkSubtle,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KholoColors.wine,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          minimumSize: const Size(44, 52),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: KholoColors.blush,
          side: const BorderSide(color: KholoColors.magenta, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          minimumSize: const Size(44, 52),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: KholoColors.blush,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: const Size(44, 44),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: KholoColors.magenta, width: 2),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: darkInkMuted),
        hintStyle: textTheme.bodyMedium?.copyWith(color: darkInkSubtle),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkCard,
        selectedColor: KholoColors.wine,
        labelStyle: textTheme.labelMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(
        color: darkDivider,
        thickness: 1,
        space: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? KholoColors.magenta : darkInkMuted),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? KholoColors.wine.withValues(alpha: 0.5)
                : darkDivider),
      ),
    );
  }
}
