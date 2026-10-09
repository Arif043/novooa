import 'agent_cursor_target.dart';

typedef AgentCursorTextChanged = Future<void> Function(String text);

/// Port, über den Aktionen den sichtbaren Cursor bedienen.
///
/// Alle Methoden sind reine Darstellung: Fehlt ein Ziel, kehren sie ohne
/// Fehler zurück, damit die fachliche Ausführung nie am Cursor hängt.
abstract interface class AgentCursorPerformer {
  /// Beginnt einen Lauf; die Oberfläche kann Platz machen (z. B. Panel schließen).
  Future<void> begin();

  Future<void> moveTo(AgentCursorTarget target);

  Future<void> click(AgentCursorTarget target);

  Future<void> typeInto(
    AgentCursorTarget target,
    String text,
    AgentCursorTextChanged onTextChanged,
  );

  /// Beendet den Lauf und blendet den Cursor aus.
  void hide();
}
