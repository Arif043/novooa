import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

part 'syscat_theme_data.dart';

class SyscatTheme {
  static TextStyle taskBody = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 24 / 17,
    color: textMain,
  );

  static TextStyle taskBodySmall = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 20 / 14,
    color: textMain,
  );

  static const Color primaryOrange = Color(0xFFFF9500);
  static const Color primaryOrangeDark = Color(0xFF8C5000);
  static const Color primaryOrangeLight = Color(0xFFFFB874);
  static const Color primaryOrangeLighter = Color(0xFFFFDCBF);
  static const Color primaryOrangeLightest = Color(0xFFFFF4E5);
  static const Color primaryOrangeHover = Color(0xFFFFF7EB);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFBA1A1A);
  static const Color info = Color(0xFF3B82F6);

  static const Color backgroundLight = Color(0xFFFCF8FB);
  static const Color surfaceDim = Color(0xFFDCD9DC);
  static const Color surfaceContainer = Color(0xFFF0EDEF);
  static const Color surfaceContainerLow = Color(0xFFF6F3F5);
  static const Color surfaceContainerHigh = Color(0xFFEAE7EA);
  static const Color glassSurface = Color(0xFFFFFFFF);
  static const Color glassSurfaceSoft = Color(0xFFFFFFFF);
  static final Color glassSurfaceSofter = glassSurface.withValues(alpha: 0.78);

  static const Color textMain = Color(0xFF1B1B1D);
  static const Color textSecondary = Color(0xFF554334);
  static const Color textTertiary = Color(0xFF5D5F5F);
  static const Color textMuted = Color(0xFF86868B);
  static const Color textHint = Color(0xFF887361);
  static const Color textMainLight = Color(0xFFFFFFFF);

  static const Color borderLight = Color(0xFFE5E5E7);
  static const Color borderStrong = Color(0xFFDBC2AD);
  static final Color shadowLight = Colors.black.withValues(alpha: 0.04);
  static final Color shadowMedium = Colors.black.withValues(alpha: 0.12);

  static const Color iconActive = Colors.white;
  static const Color iconInactive = Colors.grey;

  static List<BoxShadow> get glassShadows {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static BoxDecoration get glassPanelDecoration {
    return BoxDecoration(
      color: glassSurfaceSoft,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: borderLight),
      boxShadow: glassShadows,
    );
  }

  static BoxDecoration get nodePanelDecoration {
    return BoxDecoration(
      color: glassSurface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderLight),
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

  static ThemeData get lightTheme => buildSyscatLightTheme();
}
