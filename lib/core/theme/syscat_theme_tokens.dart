part of 'syscat_theme.dart';

class _ThemeTokens {
  const _ThemeTokens({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceLow,
    required this.surfaceHigh,
    required this.text,
    required this.textMuted,
    required this.hint,
    required this.secondary,
    required this.border,
    required this.primaryHover,
    required this.primaryContainerText,
    required this.error,
  });

  factory _ThemeTokens.light() => const _ThemeTokens(
    brightness: Brightness.light,
    background: SyscatTheme.backgroundLight,
    surface: SyscatTheme.glassSurface,
    surfaceLow: SyscatTheme.surfaceContainerLow,
    surfaceHigh: SyscatTheme.surfaceContainerHigh,
    text: SyscatTheme.textMain,
    textMuted: SyscatTheme.textTertiary,
    hint: SyscatTheme.textHint,
    secondary: Colors.black,
    border: SyscatTheme.borderLight,
    primaryHover: SyscatTheme.primaryOrangeHover,
    primaryContainerText: SyscatTheme.primaryOrangeDark,
    error: SyscatTheme.error,
  );

  factory _ThemeTokens.dark() => const _ThemeTokens(
    brightness: Brightness.dark,
    background: SyscatTheme.backgroundDark,
    surface: SyscatTheme.glassSurfaceDark,
    surfaceLow: SyscatTheme.surfaceDarkLow,
    surfaceHigh: SyscatTheme.surfaceDarkHigh,
    text: SyscatTheme.textMainDark,
    textMuted: SyscatTheme.textMutedDark,
    hint: SyscatTheme.textSecondaryDark,
    secondary: SyscatTheme.textMutedDark,
    border: SyscatTheme.borderDark,
    primaryHover: Color(0xFF382414),
    primaryContainerText: SyscatTheme.textMainLight,
    error: Color(0xFFFFB4AB),
  );

  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color surfaceLow;
  final Color surfaceHigh;
  final Color text;
  final Color textMuted;
  final Color hint;
  final Color secondary;
  final Color border;
  final Color primaryHover;
  final Color primaryContainerText;
  final Color error;
}
