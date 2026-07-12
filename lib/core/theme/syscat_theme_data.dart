part of 'syscat_theme.dart';

ThemeData buildSyscatLightTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: SyscatTheme.primaryOrange,
    brightness: Brightness.light,
    surface: SyscatTheme.backgroundLight,
    primary: SyscatTheme.primaryOrange,
    onPrimary: SyscatTheme.textMainLight,
    primaryContainer: SyscatTheme.primaryOrange,
    onPrimaryContainer: SyscatTheme.primaryOrangeDark,
    secondary: SyscatTheme.textTertiary,
    onSecondary: SyscatTheme.textMainLight,
    secondaryContainer: SyscatTheme.surfaceContainerHigh,
    onSecondaryContainer: SyscatTheme.textTertiary,
    error: SyscatTheme.error,
  );
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    colorScheme: colorScheme,
    scaffoldBackgroundColor: SyscatTheme.backgroundLight,
    textTheme: _textTheme(),
    appBarTheme: _appBarTheme(),
    drawerTheme: _drawerTheme(),
    dividerTheme: DividerThemeData(
      color: SyscatTheme.borderLight,
      thickness: 1,
    ),
    iconButtonTheme: _iconButtonTheme(),
    inputDecorationTheme: _inputDecorationTheme(),
    listTileTheme: _listTileTheme(),
    cardTheme: _cardTheme(),
    filledButtonTheme: _filledButtonTheme(),
    switchTheme: _switchTheme(),
    brightness: Brightness.light,
  );
}

TextTheme _textTheme() {
  return const TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'Inter',
      fontSize: 48,
      fontWeight: FontWeight.w700,
      height: 52 / 48,
      color: SyscatTheme.textMain,
    ),
    headlineLarge: TextStyle(
      fontFamily: 'Inter',
      fontSize: 32,
      fontWeight: FontWeight.w600,
      height: 38 / 32,
      color: SyscatTheme.textMain,
    ),
    titleLarge: TextStyle(
      fontFamily: 'Inter',
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 28 / 22,
      color: SyscatTheme.textMain,
    ),
    bodyLarge: TextStyle(
      fontSize: 17,
      color: SyscatTheme.textMain,
      height: 24 / 17,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      color: SyscatTheme.textTertiary,
      height: 20 / 14,
    ),
    labelSmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.6,
      color: SyscatTheme.textMuted,
    ),
  );
}

AppBarTheme _appBarTheme() {
  return const AppBarTheme(
    centerTitle: false,
    elevation: 0,
    scrolledUnderElevation: 0,
    backgroundColor: SyscatTheme.backgroundLight,
    foregroundColor: SyscatTheme.textMain,
    titleTextStyle: TextStyle(
      fontFamily: 'Inter',
      color: SyscatTheme.textMain,
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 28 / 22,
    ),
  );
}

DrawerThemeData _drawerTheme() {
  return const DrawerThemeData(
    backgroundColor: SyscatTheme.glassSurface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
    ),
  );
}

IconButtonThemeData _iconButtonTheme() {
  return IconButtonThemeData(
    style: IconButton.styleFrom(
      foregroundColor: SyscatTheme.textSecondary,
      hoverColor: SyscatTheme.primaryOrangeHover,
      highlightColor: SyscatTheme.primaryOrangeHover,
    ),
  );
}

InputDecorationTheme _inputDecorationTheme() {
  return InputDecorationTheme(
    hintStyle: const TextStyle(color: SyscatTheme.textHint, fontSize: 17),
    filled: true,
    fillColor: SyscatTheme.surfaceContainerLow,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.md,
    ),
    border: _inputBorder(BorderSide.none),
    enabledBorder: _inputBorder(BorderSide.none),
    focusedBorder: _inputBorder(
      const BorderSide(color: SyscatTheme.primaryOrange, width: 2),
    ),
    errorBorder: _inputBorder(const BorderSide(color: SyscatTheme.error)),
    focusedErrorBorder: _inputBorder(
      const BorderSide(color: SyscatTheme.error, width: 2),
    ),
  );
}

OutlineInputBorder _inputBorder(BorderSide side) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: side,
  );
}

ListTileThemeData _listTileTheme() {
  return ListTileThemeData(
    iconColor: SyscatTheme.textHint,
    selectedColor: SyscatTheme.primaryOrange,
    selectedTileColor: SyscatTheme.primaryOrangeHover,
    textColor: SyscatTheme.textSecondary,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    titleTextStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
  );
}

CardThemeData _cardTheme() {
  return CardThemeData(
    color: SyscatTheme.glassSurface,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: SyscatTheme.borderLight),
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

SwitchThemeData _switchTheme() {
  return SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return SyscatTheme.primaryOrange;
      }
      return SyscatTheme.surfaceContainerHigh;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return SyscatTheme.primaryOrange.withValues(alpha: 0.28);
      }
      return SyscatTheme.surfaceContainer;
    }),
  );
}
