import 'package:flutter/material.dart';
import 'package:material_ui/material_ui.dart' as editor;

/// `pro_image_editor` baut auf `material_ui` statt auf Flutters Material
/// auf; dieser Adapter überträgt das Farbschema der App, damit der Editor
/// wie die App aussieht (auch im Dunkelmodus).
editor.ThemeData imageEditorTheme(ColorScheme colors) {
  return editor.ThemeData.from(
    useMaterial3: true,
    colorScheme: editor.ColorScheme(
      brightness: colors.brightness,
      primary: colors.primary,
      onPrimary: colors.onPrimary,
      primaryContainer: colors.primaryContainer,
      onPrimaryContainer: colors.onPrimaryContainer,
      secondary: colors.secondary,
      onSecondary: colors.onSecondary,
      secondaryContainer: colors.secondaryContainer,
      onSecondaryContainer: colors.onSecondaryContainer,
      tertiary: colors.tertiary,
      onTertiary: colors.onTertiary,
      error: colors.error,
      onError: colors.onError,
      surface: colors.surface,
      onSurface: colors.onSurface,
      onSurfaceVariant: colors.onSurfaceVariant,
      surfaceContainerLowest: colors.surfaceContainerLowest,
      surfaceContainerLow: colors.surfaceContainerLow,
      surfaceContainer: colors.surfaceContainer,
      surfaceContainerHigh: colors.surfaceContainerHigh,
      surfaceContainerHighest: colors.surfaceContainerHighest,
      outline: colors.outline,
      outlineVariant: colors.outlineVariant,
      inverseSurface: colors.inverseSurface,
      onInverseSurface: colors.onInverseSurface,
    ),
  );
}
