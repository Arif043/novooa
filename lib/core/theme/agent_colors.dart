import 'package:flutter/material.dart';

/// Farben, an denen man Agenten unterscheidet, die alle als Noovi erscheinen.
/// Jeder Mitarbeiter hat eine feste Farbe, abgeleitet aus seiner ID; der
/// Orchestrator und die Prüfung nehmen Farben aus dem Theme.
class AgentColors {
  const AgentColors._();

  /// Mittlere, kräftige Töne: als Ring gut sichtbar auf hellen und dunklen Flächen.
  static const List<Color> members = [
    Color(0xFF1E6FD9),
    Color(0xFF00897B),
    Color(0xFF7B3FC4),
    Color(0xFFC2185B),
    Color(0xFF2E7D32),
    Color(0xFF3949AB),
    Color(0xFF8D5524),
    Color(0xFF00838F),
  ];

  /// Immer dieselbe Farbe für denselben Mitarbeiter, auf jeder Plattform.
  static Color memberColor(String employeeId) =>
      members[_stableHash(employeeId) % members.length];

  static Color orchestratorOf(ColorScheme scheme) => scheme.primary;

  static Color reviewerOf(ColorScheme scheme) => scheme.tertiary;

  // FNV-1a über die UTF-16-Einheiten. `String.hashCode` ist nicht über
  // Plattformen (Web, VM) und Versionen hinweg festgelegt.
  static int _stableHash(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }
}
