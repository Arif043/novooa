import 'package:flutter/material.dart';

class SyscatTheme {
  static const Color primaryOrange = Colors.orange;
  static final Color primaryOrangeDark = Colors.orange.shade800;
  static final Color primaryOrangeLight = Colors.orange.shade300;
  static final Color primaryOrangeLighter = Colors.orange.shade200;
  static final Color primaryOrangeLightest = Colors.orange.shade100;
  static final Color primaryOrangeHover = Colors.orange.shade50;

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  static const Color backgroundLight = Color(0xFFFCFDFD);
  static const Color glassSurface = Colors.white;
  static final Color glassSurfaceSoft = Colors.white.withValues(alpha: 0.85);
  static final Color glassSurfaceSofter = Colors.white.withValues(alpha: 0.3);

  static const Color textMain = Colors.black87;
  static final Color textSecondary = Colors.grey.shade700;
  static final Color textTertiary = Colors.grey.shade600;
  static final Color textMuted = Colors.grey.shade500;
  static final Color textHint = Colors.grey.shade400;
  static const Color textMainLight = Color(0xFFFFFFFF);

  static final Color borderLight = Colors.grey.withValues(alpha: 0.1);
  static final Color borderStrong = Colors.grey.shade200;
  static final Color shadowLight = Colors.black.withValues(alpha: 0.04);
  static final Color shadowMedium = Colors.black12;

  static const Color iconActive = Colors.white;
  static const Color iconInactive = Colors.grey;

  static List<BoxShadow> get glassShadows {
    return [
      BoxShadow(
        color: primaryOrangeDark.withValues(alpha: 0.08),
        blurRadius: 60,
        offset: const Offset(0, 30),
      ),
      BoxShadow(color: shadowLight, blurRadius: 24, offset: const Offset(0, 8)),
    ];
  }

  static BoxDecoration get glassPanelDecoration {
    return BoxDecoration(
      color: glassSurfaceSoft,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: glassSurface, width: 2),
      boxShadow: glassShadows,
    );
  }

  static LinearGradient get activeNavigationGradient {
    return LinearGradient(
      colors: [primaryOrange, primaryOrangeDark],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryOrange,
      surface: glassSurface,
      error: error,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
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
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: textMain,
        titleTextStyle: const TextStyle(
          color: textMain,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: glassSurfaceSoft,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
        ),
      ),
      dividerTheme: DividerThemeData(color: borderLight, thickness: 1),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textSecondary,
          hoverColor: primaryOrangeHover,
          highlightColor: primaryOrangeHover,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: textHint, fontSize: 14),
        border: InputBorder.none,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: textHint,
        selectedColor: primaryOrangeDark,
        selectedTileColor: primaryOrangeHover,
        textColor: textSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: glassSurfaceSoft,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}
