import 'package:flutter/material.dart';

class AppTheme {
  static const Color brand = Color(0xFF2563EB);
  static const Color brandDark = Color(0xFF1E3A8A);
  static const Color accent = Color(0xFF0F766E);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF8FAFC);
  static const Color surfaceMuted = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color text = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color danger = Color(0xFFDC2626);

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: brand,
      secondary: accent,
      surface: surface,
      error: danger,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: text,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      primaryColor: brand,
      scaffoldBackgroundColor: surfaceSoft,
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: brandDark,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brand,
          side: const BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: textMuted, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: brand, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: danger, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: text,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceMuted,
        selectedColor: brand.withValues(alpha: 0.12),
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        labelStyle: const TextStyle(
          color: text,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: text,
          letterSpacing: -0.4,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: text,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: text,
        ),
        bodyLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: text,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          color: textMuted,
        ),
      ),
    );
  }
}
