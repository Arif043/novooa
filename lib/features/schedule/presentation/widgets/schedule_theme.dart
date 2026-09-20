import 'package:flutter/material.dart';
import '../../../../core/theme/syscat_theme.dart';

/// Luminous Precision styling, scoped to scheduling.
abstract final class ScheduleTheme {
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

class ScheduleSection extends StatelessWidget {
  const ScheduleSection({super.key, required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 12),
        child: Text(title, style: Theme.of(context).textTheme.titleSmall),
      ),
      DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Padding(padding: const EdgeInsets.all(20), child: child),
      ),
    ],
  );
}
