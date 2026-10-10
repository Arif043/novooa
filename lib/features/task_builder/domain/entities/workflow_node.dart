import 'package:equatable/equatable.dart';

import 'node_config.dart';

/// Stabile Bausteintypen, aus denen ein Workflow zusammengesetzt wird.
///
/// Synchron zur Tabelle in `docs/features/aufgabe.md` § Primitives halten:
/// Jeder neue Enum-Wert braucht einen Eintrag dort, einen UI-Label in der
/// `WorkflowPrimitiveLabels`-Extension und ein Genkit-Mapping im Inspector.
enum WorkflowPrimitive {
  stringInput,
  script,
  prompt,
  conditional,
  iterativeRefinement,
  writeFile,
  readFile,
  readEmail,
  readChannelEvent,
  readWebhook,
  sendChannelMessage,
  notificationSend,
  toolCall,
  humanApproval,
  dialogInput,
  mediaInput,
  modelInference,
  textToSpeech,
  speechToText,
  forEach,
  documentLookup,
  saveDocument,
  tableFromCollection,
  validation,
  httpRequest,

  /// Sammelwert für Bausteine von Plugins (siehe `PluginNodeConfig`): Welcher
  /// Baustein es ist, steht in `PluginNodeConfig.typeId`. Neue Plugin-Bausteine
  /// brauchen deshalb keinen neuen Enum-Wert.
  plugin,
}

/// Ob eine Primitive einen fachlichen Rückgabewert hat.
///
/// Domain-Regel statt Presentation-Detail, weil sie an zwei unabhängigen
/// Stellen dieselbe Antwort braucht: `TaskBuilderCubit` beim Anlegen eines
/// Knotens und `TaskDocumentMapper` beim Laden gespeicherter Aufgaben (siehe
/// dort — Bausteine, die vor dieser Regel angelegt wurden, können noch einen
/// veralteten `outputName` tragen; der Mapper korrigiert das beim Laden statt
/// dass jede Aufgabe einzeln nachgepflegt werden müsste).
extension WorkflowPrimitiveOutput on WorkflowPrimitive {
  /// Reine Seiteneffekt-Bausteine ohne fachlichen Rückgabewert — aktuell nur
  /// `notificationSend` (siehe `docs/node-executor-outputs.md`).
  bool get hasNoOutput => this == WorkflowPrimitive.notificationSend;
}

/// Value Object für Knoten-Identifier.
///
/// Wrappt einen [String], damit Aufrufer `NodeId` nicht versehentlich mit
/// beliebigen Strings verwechseln können. `==` und `hashCode` sind
/// überschrieben, damit [WorkflowEdge] und [TaskDefinition] mit
/// `List.contains`, `firstWhere` etc. arbeiten können.
class NodeId {
  const NodeId(this.value);

  final String value;

  @override
  bool operator ==(Object other) {
    return other is NodeId && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'NodeId($value)';
}

/// Immutable Konfiguration einer Primitive-Instanz auf der Leinwand.
///
/// `id` ist absichtlich nicht Teil von [copyWith] — die Identität eines
/// Knotens bleibt über seine Lebensdauer hinweg stabil.
class WorkflowNode extends Equatable {
  const WorkflowNode({
    required this.id,
    required this.title,
    required this.description,
    required this.config,
    this.outputName = '',
    this.outputFieldNames = const {},
  });

  final NodeId id;
  final String title;
  final String description;

  /// Eindeutiger Name des primären fachlichen Outputs dieses Bausteins
  /// (`{{outputName}}` in Templates). Bleibt leer bei Bausteinen mit
  /// mehreren fachlichen Outputs (z.B. strukturierte Prompt-Ausgabe,
  /// Dialogeingabe) — dort trägt jedes Feld seinen eigenen Namen (siehe
  /// `StructuredOutputField.name`/`DialogInputField.name`).
  final String outputName;

  /// Namen der weiteren Werte dieses Bausteins: technischer Schlüssel des
  /// Executors (z.B. `found`, siehe `outputFieldsOf`) → graph-weit
  /// eindeutiger Name (`{{Gefunden}}`). Sie stehen nur im Panel, nicht auf
  /// der Leinwand.
  final Map<String, String> outputFieldNames;
  final NodeConfig config;

  /// Der Name eines weiteren Werts; leer, wenn (noch) keiner vergeben ist.
  String outputFieldNameOf(String fieldKey) =>
      outputFieldNames[fieldKey]?.trim() ?? '';

  WorkflowNode copyWith({
    String? title,
    String? description,
    String? outputName,
    Map<String, String>? outputFieldNames,
    NodeConfig? config,
  }) {
    return WorkflowNode(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      outputName: outputName ?? this.outputName,
      outputFieldNames: outputFieldNames ?? this.outputFieldNames,
      config: config ?? this.config,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    outputName,
    outputFieldNames,
    config,
  ];

  @override
  bool? get stringify => true;
}
