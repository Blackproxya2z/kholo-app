import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';

/// KHOLO full ThemeData — Light and Dark luxury design systems.
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
        surfaceContainerHigh: KholoColors.cardSurface,
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
        titleTextStyle:
            textTheme.headlineSmall?.copyWith(color: KholoColors.ink),
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
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          textStyle: textTheme.labelLarge?.copyWith(color: Colors.white),
          minimumSize: const Size(44, 52),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: KholoColors.wine,
          side: const BorderSide(color: KholoColors.magenta, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: KholoColors.blush,
        selectedColor: KholoColors.wine,
        labelStyle: textTheme.labelMedium,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(
        color: KholoColors.divider,
        thickness: 1,
        space: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? Colors.white : KholoColors.inkSubtle),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? KholoColors.wine : KholoColors.divider),
      ),
    );
  }

  // ── Dark Theme (Luxury Deep Plum & Wine Charcoal) ───────────────────────────

  static ThemeData get dark {
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
        secondaryContainer: Color(0xFF38152D),
        onSecondaryContainer: KholoColors.blush,
        tertiary: KholoColors.warmGold,
        onTertiary: KholoColors.darkCanvas,
        tertiaryContainer: Color(0xFF3D3000),
        onTertiaryContainer: KholoColors.warmGold,
        error: Color(0xFFFF6B6B),
        onError: Colors.white,
        errorContainer: Color(0xFF4D1515),
        onErrorContainer: Color(0xFFFF6B6B),
        surface: KholoColors.darkCanvas,
        onSurface: KholoColors.darkInk,
        surfaceContainerHighest: KholoColors.darkCard,
        surfaceContainerHigh: KholoColors.darkCardElevated,
        onSurfaceVariant: KholoColors.darkInkMuted,
        outline: KholoColors.darkDivider,
        outlineVariant: KholoColors.darkDivider,
        shadow: Color(0x66000000),
        scrim: Color(0xAA000000),
        inverseSurface: KholoColors.darkInk,
        onInverseSurface: KholoColors.darkCanvas,
        inversePrimary: KholoColors.wine,
      ),
      scaffoldBackgroundColor: KholoColors.darkCanvas,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: KholoColors.darkCanvas,
        foregroundColor: KholoColors.darkInk,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle:
            textTheme.headlineSmall?.copyWith(color: KholoColors.darkInk),
        iconTheme: const IconThemeData(color: KholoColors.darkInk),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: KholoColors.darkSurface,
        selectedItemColor: KholoColors.magenta,
        unselectedItemColor: KholoColors.darkInkSubtle,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: KholoColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: KholoColors.darkCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      cardTheme: CardThemeData(
        color: KholoColors.darkCard,
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          minimumSize: const Size(44, 52),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: KholoColors.blush,
          side: const BorderSide(color: KholoColors.magenta, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
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
        fillColor: KholoColors.darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: KholoColors.darkDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: KholoColors.darkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: KholoColors.magenta, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: KholoColors.darkInkMuted),
        hintStyle: textTheme.bodyMedium?.copyWith(color: KholoColors.darkInkSubtle),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: KholoColors.darkCard,
        selectedColor: KholoColors.wine,
        labelStyle: textTheme.labelMedium,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(
        color: KholoColors.darkDivider,
        thickness: 1,
        space: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? Colors.white : KholoColors.darkInkMuted),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? KholoColors.wine
                : KholoColors.darkDivider),
      ),
    );
  }
}
