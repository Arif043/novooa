part of 'syscat_theme.dart';

ThemeData buildSyscatLightTheme() => _buildTheme(_ThemeTokens.light());

ThemeData buildSyscatDarkTheme() => _buildTheme(_ThemeTokens.dark());

ThemeData _buildTheme(_ThemeTokens tokens) {
  final scheme = ColorScheme.fromSeed(
    seedColor: SyscatTheme.primaryOrange,
    brightness: tokens.brightness,
    surface: tokens.background,
    primary: SyscatTheme.primaryOrange,
    onPrimary: SyscatTheme.textMainLight,
    primaryContainer: SyscatTheme.primaryOrange,
    onPrimaryContainer: tokens.primaryContainerText,
    secondary: tokens.secondary,
    onSecondary: SyscatTheme.textMainLight,
    secondaryContainer: tokens.surfaceHigh,
    onSecondaryContainer: tokens.secondary,
    error: tokens.error,
  );
  return ThemeData(
    useMaterial3: true,
    fontFamily: SyscatTheme.bodyFontFamily,
    colorScheme: scheme,
    scaffoldBackgroundColor: tokens.background,
    textTheme: _textTheme(tokens),
    appBarTheme: _appBarTheme(tokens),
    drawerTheme: _drawerTheme(tokens),
    dividerTheme: DividerThemeData(color: tokens.border, thickness: 1),
    iconButtonTheme: _iconButtonTheme(tokens),
    inputDecorationTheme: _inputDecorationTheme(tokens),
    listTileTheme: _listTileTheme(tokens),
    cardTheme: _cardTheme(tokens),
    filledButtonTheme: _filledButtonTheme(),
    switchTheme: _switchTheme(tokens),
    snackBarTheme: _snackBarTheme(tokens),
    brightness: tokens.brightness,
  );
}

TextTheme _textTheme(_ThemeTokens tokens) {
  return TextTheme(
    displayLarge: _titleText(48, FontWeight.w700, 52 / 48, tokens.text),
    headlineLarge: _titleText(32, FontWeight.w600, 38 / 32, tokens.text),
    titleLarge: _titleText(22, FontWeight.w600, 28 / 22, tokens.text),
    bodyLarge: _text(17, FontWeight.w400, 24 / 17, tokens.text),
    bodyMedium: _text(14, FontWeight.w400, 20 / 14, tokens.textMuted),
    labelSmall: _text(
      12,
      FontWeight.w600,
      16 / 12,
      tokens.textMuted,
    ).copyWith(letterSpacing: 0.6),
  );
}

TextStyle _titleText(
  double size,
  FontWeight weight,
  double height,
  Color color,
) {
  return _text(
    size,
    weight,
    height,
    color,
  ).copyWith(fontFamily: SyscatTheme.titleFontFamily);
}

TextStyle _text(double size, FontWeight weight, double height, Color color) {
  return TextStyle(
    fontFamily: SyscatTheme.bodyFontFamily,
    fontSize: size,
    fontWeight: weight,
    height: height,
    color: color,
  );
}

AppBarTheme _appBarTheme(_ThemeTokens tokens) {
  return AppBarTheme(
    centerTitle: false,
    elevation: 0,
    scrolledUnderElevation: 0,
    backgroundColor: tokens.background,
    foregroundColor: tokens.text,
    titleTextStyle: _titleText(22, FontWeight.w600, 28 / 22, tokens.text),
  );
}

DrawerThemeData _drawerTheme(_ThemeTokens tokens) {
  return DrawerThemeData(
    backgroundColor: tokens.surface,
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
    ),
  );
}

IconButtonThemeData _iconButtonTheme(_ThemeTokens tokens) {
  return IconButtonThemeData(
    style: IconButton.styleFrom(
      foregroundColor: tokens.textMuted,
      hoverColor: tokens.primaryHover,
      highlightColor: tokens.primaryHover,
    ),
  );
}

InputDecorationTheme _inputDecorationTheme(_ThemeTokens tokens) {
  return InputDecorationTheme(
    hintStyle: TextStyle(color: tokens.hint, fontSize: 17),
    filled: true,
    fillColor: tokens.surfaceLow,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.md,
    ),
    border: _inputBorder(BorderSide.none),
    enabledBorder: _inputBorder(BorderSide.none),
    focusedBorder: _inputBorder(
      const BorderSide(color: SyscatTheme.primaryOrange, width: 2),
    ),
    errorBorder: _inputBorder(BorderSide(color: tokens.error)),
    focusedErrorBorder: _inputBorder(BorderSide(color: tokens.error, width: 2)),
  );
}

OutlineInputBorder _inputBorder(BorderSide side) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: side,
  );
}

ListTileThemeData _listTileTheme(_ThemeTokens tokens) {
  return ListTileThemeData(
    iconColor: tokens.hint,
    selectedColor: SyscatTheme.primaryOrange,
    selectedTileColor: tokens.primaryHover,
    textColor: tokens.textMuted,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    titleTextStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
  );
}

CardThemeData _cardTheme(_ThemeTokens tokens) {
  return CardThemeData(
    color: tokens.surface,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: tokens.border),
    ),
  );
}

FilledButtonThemeData _filledButtonTheme() {
  return FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: SyscatTheme.primaryOrange,
      foregroundColor: SyscatTheme.textMainLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    ),
  );
}

SwitchThemeData _switchTheme(_ThemeTokens tokens) {
  return SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return SyscatTheme.primaryOrange;
      }
      return tokens.surfaceHigh;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return SyscatTheme.primaryOrange.withValues(alpha: 0.28);
      }
      return tokens.surfaceLow;
    }),
  );
}

SnackBarThemeData _snackBarTheme(_ThemeTokens tokens) {
  return SnackBarThemeData(
    contentTextStyle: .new(color: Colors.white),
    backgroundColor: Colors.black,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    behavior: SnackBarBehavior.floating,
    
    //actionTextColor: tokens.primaryOrange,
  );
}
