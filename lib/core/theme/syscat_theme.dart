import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

part 'syscat_theme_data.dart';
part 'syscat_theme_tokens.dart';

class SyscatTheme {
  static const String titleFontFamily = 'Space Grotesk';
  static const String bodyFontFamily = 'Inter';

  static TextStyle taskBody = const TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 24 / 17,
    color: textMain,
  );

  static TextStyle taskBodySmall = const TextStyle(
    fontFamily: bodyFontFamily,
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
  static const Color error = CupertinoColors.destructiveRed;
  static const Color info = Color.fromRGBO(26, 35, 126, 1);

  static const Color backgroundLight = Color(0xFFFCF8FB);
  static const Color backgroundDark = Color(0xFF141315);
  static const Color surfaceDark = Color(0xFF1D1B1F);
  static const Color surfaceDarkLow = Color(0xFF242227);
  static const Color surfaceDarkHigh = Color(0xFF302E33);
  static const Color surfaceDim = Color(0xFFDCD9DC);
  static const Color surfaceContainer = Color(0xFFF0EDEF);
  static const Color surfaceContainerLow = Color(0xFFF6F3F5);
  static const Color surfaceContainerHigh = Color(0xFFEAE7EA);
  static const Color glassSurface = Color(0xFFFFFFFF);
  static const Color glassSurfaceDark = Color(0xFF1D1B1F);
  static const Color glassSurfaceSoft = Color(0xFFFFFFFF);
  static final Color glassSurfaceSofter = glassSurface.withValues(alpha: 0.78);

  static const Color textMain = Color(0xFF1B1B1D);
  static const Color textMainDark = Color(0xFFF4F0F3);
  static const Color textSecondaryDark = Color(0xFFD9C8BA);
  static const Color textMutedDark = Color(0xFFC9C3C8);
  static const Color textSecondary = Color(0xFF554334);
  static const Color textTertiary = Color(0xFF5D5F5F);
  static const Color textMuted = Color(0xFF86868B);
  static const Color textHint = Color(0xFF887361);
  static const Color textMainLight = Color(0xFFFFFFFF);

  static const Color borderLight = Color(0xFFE5E5E7);
  static const Color borderDark = Color(0xFF3D3940);
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

  static List<BoxShadow> get darkShadows {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.28),
        blurRadius: 18,
        offset: const Offset(0, 6),
      ),
    ];
  }

  /// Nimmt bewusst [BuildContext] statt eines parameterlosen Getters: Die
  /// Variante mit `WidgetsBinding.instance.platformDispatcher.platformBrightness`
  /// fragte die OS-Einstellung direkt ab und ignorierte dabei, welches Theme
  /// `MaterialApp` (`theme`/`darkTheme`/`themeMode`) tatsächlich aufgelöst
  /// hat — sichtbar als schwarzes Panel, sobald das Betriebssystem dunkel,
  /// die App aber hell dargestellt wurde.
  static BoxDecoration glassPanelDecoration(BuildContext context) {
    return _adaptivePanelDecoration(
      context,
      lightColor: glassSurfaceSoft,
      darkColor: glassSurfaceDark,
      radius: 20,
    );
  }

  static BoxDecoration nodePanelDecoration(BuildContext context) {
    return _adaptivePanelDecoration(
      context,
      lightColor: glassSurface,
      darkColor: surfaceDark,
      radius: 16,
    );
  }

  static BoxDecoration _adaptivePanelDecoration(
    BuildContext context, {
    required Color lightColor,
    required Color darkColor,
    required double radius,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? darkColor : lightColor,
      borderRadius: BorderRadius.only(bottomRight: Radius.circular(radius), topRight: Radius.circular(radius)),
      border: Border.all(color: isDark ? borderDark : borderLight),
      boxShadow: isDark ? darkShadows : glassShadows,
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

  static ThemeData get darkTheme => buildSyscatDarkTheme();
}
