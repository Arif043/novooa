import 'package:flutter/material.dart';

/// Farben und Formen des Kunden. Widgets lesen Styles nur über
/// `Theme.of(context)`, nie direkt von hier.
class DashboardTheme {
  const DashboardTheme._();

  /// Hausfarbe des Kunden.
  static const _seed = Color(0xFF2F5BEA);

  static ThemeData light() => _theme(Brightness.light);

  static ThemeData dark() => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final colors = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: colors,
      useMaterial3: true,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}

/// Abstände des Designsystems (8er-Raster).
class Spacing {
  const Spacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;

  /// Breiteste Spalte für Formulare und Listen auf großen Bildschirmen.
  static const contentMaxWidth = 720.0;
}
