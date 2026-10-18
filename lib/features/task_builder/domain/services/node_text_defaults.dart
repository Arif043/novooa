import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';

/// Sprachabhängige Standardtexte neuer Bausteine.
///
/// Die Werte werden beim Anlegen im Task gespeichert; ein späterer
/// Sprachwechsel ändert bestehende Namen nicht. Ausgabenamen müssen `\w`
/// entsprechen (ASCII), weil sie als `{{name}}` referenziert werden.
abstract interface class NodeTextDefaults {
  /// Ausgabename ohne laufende Nummer, z. B. `input` oder `eingabe`.
  String outputBase(WorkflowPrimitive primitive);

  /// Name des Werts eines Prompts mit Ausgabetyp „Entscheidung“, z. B.
  /// `Antwort`.
  String decisionOutputBase();

  /// Ausgabename eines Sendebausteins, z. B. `sendemail` oder `sendenemail`.
  String sendOutputBase(ChannelEventKind kind);

  /// Name eines weiteren Werts ohne laufende Nummer, z. B. `Gefunden` für den
  /// Schlüssel `found` (siehe `outputFieldsOf`).
  String outputFieldBase(String fieldKey);

  /// Startcode eines neuen Script-Bausteins: ein auskommentiertes Beispiel
  /// für `workflow_output`, das noch keinen Wert anlegt.
  String scriptStarter();

  String title(WorkflowPrimitive primitive);

  String description(WorkflowPrimitive primitive);

  String readChannelTitle(ChannelEventKind kind);

  String readChannelDescription(ChannelEventKind kind);

  String sendChannelTitle(ChannelEventKind kind);

  String sendChannelDescription(ChannelEventKind kind);
}
