import 'package:flutter/widgets.dart';

/// Ein Reiter der Einstellungen. Neue Module melden sich hier an, ohne dass
/// Reiterleiste, Mobile-Liste und Inhalt einzeln angepasst werden müssen.
class SettingsTabContribution {
  const SettingsTabContribution({
    required this.icon,
    required this.labelKey,
    required this.builder,
  });

  final IconData icon;

  /// Übersetzungsschlüssel statt fertigem Text, damit ein Sprachwechsel
  /// auch Reiter aus statischen Listen erreicht.
  final String labelKey;
  final WidgetBuilder builder;
}
