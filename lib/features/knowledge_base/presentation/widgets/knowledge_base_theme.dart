import 'package:flutter/material.dart';
import '../../../../core/theme/syscat_theme.dart';

/// Luminous Precision styling, scoped to the knowledge workspace.
abstract final class KnowledgeBaseTheme {
  static ThemeData from(ThemeData base) {
    final dark = base.brightness == Brightness.dark;
    final colors = base.colorScheme.copyWith(
      surface: dark ? SyscatTheme.surfaceDark : SyscatTheme.glassSurface,
      surfaceContainerLowest: dark
          ? SyscatTheme.backgroundDark
          : SyscatTheme.backgroundLight,
      surfaceContainerLow: dark
          ? SyscatTheme.surfaceDarkLow
          : SyscatTheme.surfaceContainerLow,
      onSurface: dark ? SyscatTheme.textMainDark : SyscatTheme.textMain,
      onSurfaceVariant: dark
          ? SyscatTheme.textMutedDark
          : SyscatTheme.textTertiary,
      outlineVariant: dark ? SyscatTheme.borderDark : SyscatTheme.borderLight,
      primary: dark
          ? SyscatTheme.primaryOrangeLight
          : SyscatTheme.primaryOrangeDark,
      surfaceTint: Colors.transparent,
    );
    final text = base.textTheme.apply(
      fontFamily: SyscatTheme.bodyFontFamily,
      bodyColor: colors.onSurface,
      displayColor: colors.onSurface,
    );
    return base.copyWith(
      colorScheme: colors,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: SyscatTheme.primaryOrange,
          foregroundColor: SyscatTheme.textMain,
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(
            fontFamily: SyscatTheme.bodyFontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textTheme: text.copyWith(
        headlineLarge: text.headlineLarge?.copyWith(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          letterSpacing: -.32,
        ),
        titleLarge: text.titleLarge?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: text.titleMedium?.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: text.bodyLarge?.copyWith(fontSize: 17, height: 24 / 17),
        bodySmall: text.bodySmall?.copyWith(
          fontSize: 14,
          color: colors.onSurfaceVariant,
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: colors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
      ),
    );
  }
}
