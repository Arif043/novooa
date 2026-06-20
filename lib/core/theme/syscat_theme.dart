import 'package:flutter/material.dart';

class SyscatTheme {
  // Brand Colors
  static const Color primaryOrange = Colors.orange;
  static final Color primaryOrangeDark = Colors.orange.shade800;
  static final Color primaryOrangeLight = Colors.orange.shade300;
  static final Color primaryOrangeLighter = Colors.orange.shade200;
  static final Color primaryOrangeLightest = Colors.orange.shade100;
  static final Color primaryOrangeHover = Colors.orange.shade50;

  // Semantic Colors
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFEF4444); // Red
  static const Color info = Color(0xFF3B82F6); // Blue

  // Background and Surface Colors
  static const Color backgroundLight = Color(0xFFFCFDFD);
  static const Color glassSurface = Colors.white;
  static final Color glassSurfaceSoft = Colors.white.withOpacity(0.85);
  static final Color glassSurfaceSofter = Colors.white.withOpacity(0.3);

  // Text Colors
  static const Color textMain = Colors.black87;
  static final Color textSecondary = Colors.grey.shade700;
  static final Color textTertiary = Colors.grey.shade600;
  static final Color textMuted = Colors.grey.shade500;
  static final Color textHint = Colors.grey.shade400;
  static const Color textMainLight = Color(0xFFFFFFFF); // White;

  // Border and Shadow Colors
  static final Color borderLight = Colors.grey.withOpacity(0.1);
  static final Color borderStrong = Colors.grey.shade200;
  static final Color shadowLight = Colors.black.withOpacity(0.04);
  static final Color shadowMedium = Colors.black12;

  // Icon Colors
  static const Color iconActive = Colors.white;
  static const Color iconInactive = Colors.grey;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryOrange,
        background: backgroundLight,
        surface: glassSurface,
      ),
      scaffoldBackgroundColor: backgroundLight,
      textTheme: TextTheme(
        displayLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textMain,
        ),
        titleLarge: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textMain,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: textTertiary),
        bodyMedium: TextStyle(fontSize: 14, color: textTertiary, height: 1.5),
        labelSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textMuted,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: textHint, fontSize: 14),
        border: InputBorder.none,
      ),
    );
  }
}
