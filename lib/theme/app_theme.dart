import 'package:flutter/material.dart';

class AppTheme {
  // Apple iOS Palette & Background Colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color groupedBackground = Color(0xFFF2F2F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFF2F2F7);
  static const Color surfaceBorder = Color(0xFFE5E5EA);

  // Apple iOS System Accents
  static const Color primary = Color(0xFF007AFF); // Apple System Blue
  static const Color primaryLight = Color(0xFF0A84FF);
  static const Color accentGreen = Color(0xFF34C759); // Apple System Green
  static const Color accentCoral = Color(0xFFFF3B30); // Apple System Red
  static const Color accentAmber = Color(0xFFFF9500); // Apple System Orange
  static const Color accentBlue = Color(0xFF007AFF);
  static const Color accentPurple = Color(0xFFAF52DE); // Apple System Purple
  static const Color accentIndigo = Color(0xFF5856D6); // Apple System Indigo
  static const Color accentPink = Color(0xFFFF2D55); // Apple System Pink
  static const Color accentTeal = Color(0xFF30B0C7); // Apple System Teal

  // Apple Typography Colors
  static const Color textPrimary = Color(0xFF000000); // Apple Label Primary
  static const Color textSecondary = Color(0xFF8E8E93); // Apple Secondary Label
  static const Color textMuted = Color(0xFFC7C7CC); // Apple Tertiary / Placeholder

  // Priority Colors (Apple System Palette)
  static Color priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return accentCoral;
      case 'medium':
        return accentAmber;
      case 'low':
      default:
        return accentGreen;
    }
  }

  // Category Color Map (Apple Harmonious Palette)
  static Color categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'work':
        return accentBlue;
      case 'personal':
        return accentIndigo;
      case 'fitness':
        return accentGreen;
      case 'study':
        return accentAmber;
      case 'routine':
      default:
        return accentPurple;
    }
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: accentGreen,
        surface: surface,
        error: accentCoral,
        onPrimary: Colors.white,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: primary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: surfaceBorder, width: 0.8),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: surfaceBorder, width: 0.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: surfaceBorder, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textSecondary),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.white,
        contentTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: surfaceBorder, width: 1),
        ),
        elevation: 8,
        insetPadding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      ),
    );
  }

  // Alias for backward compatibility
  static ThemeData get darkTheme => lightTheme;
}
