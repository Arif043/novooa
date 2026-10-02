/// Ergebnis der Vorabprüfung eines Auslösers auf Schleifen.
///
/// [blocked] ist gesetzt, wenn der Auslöser nicht zulässig ist (die Aufgabe
/// würde sich selbst starten). [warnings] nennen mögliche Schleifen, die der
/// Nutzer bewusst bestätigen kann.
class TriggerCycleAnalysis {
  const TriggerCycleAnalysis({this.blocked, this.warnings = const []});

  static const none = TriggerCycleAnalysis();

  final String? blocked;
  final List<String> warnings;

  bool get isBlocked => blocked != null;
  bool get hasWarnings => warnings.isNotEmpty;
}
