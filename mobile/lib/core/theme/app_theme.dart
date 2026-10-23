import 'package:flutter/material.dart';

/// Design tokens. Spacing uses logical (start/end) directions so layouts mirror in RTL.
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

abstract final class AppRadius {
  static const card = 16.0;
  static const control = 12.0;
}

abstract final class AppColors {
  /// Nile blue: primary brand colour; white text on it meets WCAG AA (contrast ≈ 8:1).
  static const primary = Color(0xFF0B5C7A);

  /// Aswan sandstone accent, used sparingly for highlights.
  static const accent = Color(0xFFC77D2E);
  static const surface = Color(0xFFF7F5F2);
  static const sampleBadge = Color(0xFF7A4A00);
  static const sampleBadgeBackground = Color(0xFFFFF0D6);
}

class AppTheme {
  static const fontFamily = 'Cairo';

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
    );
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          // Large touch target (NFR-UX-02); grows with text scaling.
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
        ),
      ),
      textTheme: base.textTheme.apply(bodyColor: const Color(0xFF1C1B1F)),
    );
  }
}
