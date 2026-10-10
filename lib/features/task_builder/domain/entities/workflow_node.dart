import 'package:equatable/equatable.dart';

import 'node_config.dart';
import 'workflow_output.dart';

export 'workflow_output.dart';

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

/// Ob eine Primitive einen fachlichen Rückgabewert hat — Grundlage von
/// `outputKeysOf`, das festlegt, welche Werte ein Baustein benennt.
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
    this.outputs = const [],
  });

  final NodeId id;
  final String title;
  final String description;

  /// Die benannten Werte dieses Bausteins (siehe [WorkflowOutput]). Leer bei
  /// Bausteinen ohne Rückgabewert und bei flachen Bausteinen (strukturierte
  /// Prompt-Ausgabe, Dialogeingabe) — deren Felder tragen ihre Namen in der
  /// Konfiguration.
  final List<WorkflowOutput> outputs;
  final NodeConfig config;

  /// Der Name des Werts mit [key]; leer, wenn (noch) keiner vergeben ist.
  String outputNameOf(String key) {
    for (final output in outputs) {
      if (output.key == key) return output.name.trim();
    }
    return '';
  }

  /// Der Name des Hauptwerts (`value`), z.B. für `{{Anweisung}}`.
  String get primaryOutputName => outputNameOf(WorkflowOutput.primaryOutputKey);

  /// Die Werte, die als Chip auf der Leinwand stehen.
  List<WorkflowOutput> get canvasOutputs => [
    for (final output in outputs)
      if (output.showOnCanvas && output.name.trim().isNotEmpty) output,
  ];

  WorkflowNode copyWith({
    String? title,
    String? description,
    List<WorkflowOutput>? outputs,
    NodeConfig? config,
  }) {
    return WorkflowNode(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      outputs: outputs ?? this.outputs,
      config: config ?? this.config,
    );
  }

  @override
  List<Object?> get props => [id, title, description, outputs, config];

  @override
  bool? get stringify => true;
}
