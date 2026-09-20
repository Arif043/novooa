import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';

/// Luminous Precision (docs/DESIGN.md), scoped to the workflow workspace.
abstract final class TaskBuilderTheme {
  static const paletteWidth = 280.0;

  static ThemeData from(ThemeData base) {
    final dark = base.brightness == Brightness.dark;
    final text = dark ? SyscatTheme.textMainDark : SyscatTheme.textMain;
    final secondary = dark
        ? SyscatTheme.textMutedDark
        : SyscatTheme.textTertiary;
    final surface = dark ? SyscatTheme.surfaceDark : SyscatTheme.glassSurface;
    final scheme = base.colorScheme.copyWith(
      surface: surface,
      surfaceContainerLowest: dark
          ? SyscatTheme.backgroundDark
          : SyscatTheme.backgroundLight,
      surfaceContainerLow: dark
          ? SyscatTheme.surfaceDarkLow
          : SyscatTheme.surfaceContainerLow,
      surfaceContainerHigh: dark
          ? SyscatTheme.surfaceDarkHigh
          : SyscatTheme.surfaceContainerHigh,
      surfaceContainerHighest: dark
          ? SyscatTheme.surfaceDarkHigh
          : SyscatTheme.surfaceContainer,
      onSurface: text,
      onSurfaceVariant: secondary,
      outline: dark ? SyscatTheme.textMutedDark : SyscatTheme.textHint,
      outlineVariant: dark ? SyscatTheme.borderDark : SyscatTheme.borderLight,
      primary: dark
          ? SyscatTheme.primaryOrangeLight
          : SyscatTheme.primaryOrangeDark,
      primaryContainer: SyscatTheme.primaryOrange,
      onPrimaryContainer: SyscatTheme.textMain,
      surfaceTint: Colors.transparent,
    );
    TextStyle style(
      double size,
      double height,
      FontWeight weight,
      Color color,
    ) => TextStyle(
      fontFamily: SyscatTheme.bodyFontFamily,
      fontSize: size,
      height: height / size,
      fontWeight: weight,
      color: color,
    );
    final typography = base.textTheme
        .apply(fontFamily: SyscatTheme.bodyFontFamily)
        .copyWith(
          headlineLarge: style(
            32,
            38,
            FontWeight.w600,
            text,
          ).copyWith(letterSpacing: -.32),
          titleLarge: style(22, 28, FontWeight.w600, text),
          titleMedium: style(
            17,
            24,
            FontWeight.w600,
            text,
          ).copyWith(letterSpacing: -.17),
          titleSmall: style(14, 20, FontWeight.w600, text),
          bodyLarge: style(
            17,
            24,
            FontWeight.w400,
            text,
          ).copyWith(letterSpacing: -.17),
          bodyMedium: style(14, 20, FontWeight.w400, text),
          bodySmall: style(14, 20, FontWeight.w400, secondary),
          labelLarge: style(14, 20, FontWeight.w600, text),
          labelMedium: style(
            12,
            16,
            FontWeight.w600,
            secondary,
          ).copyWith(letterSpacing: .6),
          labelSmall: style(
            12,
            16,
            FontWeight.w600,
            secondary,
          ).copyWith(letterSpacing: .6),
        );
    return base.copyWith(
      colorScheme: scheme,
      textTheme: typography,
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
      ),
      iconTheme: IconThemeData(color: secondary, size: 20),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(48),
          foregroundColor: secondary,
          hoverColor: scheme.primary.withValues(alpha: .08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        fillColor: scheme.surfaceContainerLow,
        hintStyle: typography.bodyMedium?.copyWith(color: secondary),
        labelStyle: typography.bodyMedium?.copyWith(color: secondary),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primaryContainer, width: 2),
        ),
      ),
      listTileTheme: base.listTileTheme.copyWith(
        textColor: text,
        iconColor: secondary,
        titleTextStyle: typography.bodyMedium,
        minVerticalPadding: 8,
      ),
    );
  }
}
