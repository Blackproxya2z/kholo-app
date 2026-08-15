import 'package:flutter_test/flutter_test.dart';
import 'package:kholo/app/theme/colors.dart';
import 'package:kholo/app/theme/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Design System & Color Tokens Tests', () {
    test('The 4 brand colors have exact Hex and RGB values', () {
      // 1. #92003A / rgb(146, 0, 58)
      expect(KholoColors.wine.toARGB32(), 0xFF92003A);

      // 2. #F62477 / rgb(246, 36, 119)
      expect(KholoColors.magenta.toARGB32(), 0xFFF62477);

      // 3. #FFADEE / rgb(255, 173, 238)
      expect(KholoColors.blush.toARGB32(), 0xFFFFADEE);

      // 4. #FFE185 / rgb(255, 225, 133)
      expect(KholoColors.warmGold.toARGB32(), 0xFFFFE185);
    });

    testWidgets('KholoTheme builds a valid Material 3 ThemeData with brand palette', (tester) async {
      final theme = KholoTheme.light;
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, KholoColors.wine);
      expect(theme.colorScheme.secondary, KholoColors.magenta);
      expect(theme.colorScheme.tertiary, KholoColors.warmGold);
      expect(theme.colorScheme.primaryContainer, KholoColors.blush);
    });

    test('Phase color mappings resolve cleanly without errors', () {
      expect(KholoColors.phaseColor('menstrual'), KholoColors.rose);
      expect(KholoColors.phaseColor('follicular'), KholoColors.lavender);
      expect(KholoColors.phaseColor('ovulation'), KholoColors.plum);
      expect(KholoColors.phaseColor('luteal'), KholoColors.lutealAccent);

      expect(KholoColors.phaseLightColor('menstrual'), KholoColors.roseLight);
      expect(KholoColors.phaseLightColor('follicular'), KholoColors.lavenderLight);
      expect(KholoColors.phaseLightColor('ovulation'), KholoColors.primaryLight);
      expect(KholoColors.phaseLightColor('luteal'), KholoColors.lutealTint);
    });
  });
}
