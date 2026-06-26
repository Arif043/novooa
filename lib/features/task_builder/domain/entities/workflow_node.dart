import 'prompt_node_config.dart';

/// Stabile Bausteintypen, aus denen ein Workflow zusammengesetzt wird.
///
/// Synchron zur Tabelle in `docs/features/aufgabe.md` § Primitives halten:
/// Jeder neue Enum-Wert braucht einen Eintrag dort, einen UI-Label in der
/// `WorkflowPrimitiveLabels`-Extension und ein Genkit-Mapping im Inspector.
enum WorkflowPrimitive {
  prompt,
  conditionalFlow,
  iterativeRefinement,
  toolCall,
  humanApproval,
  validation,
}

/// Auswertungsstrategie für [WorkflowPrimitive.conditionalFlow].
///
/// Wird im Inspector als Dropdown angeboten und am Knoten persistiert.
/// Andere Primitives ignorieren das Feld — es bleibt aus Kompatibilität
/// gesetzt (Default [LogicMode.schemaBasiert]).
enum LogicMode {
  schemaBasiert('Schema-basiert'),
  freeform('Freeform'),
  kiGestuetzt('KI-gestützt');

  const LogicMode(this.label);

  final String label;
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
class WorkflowNode {
  const WorkflowNode({
    required this.id,
    required this.primitive,
    required this.title,
    required this.description,
    this.logicMode = LogicMode.schemaBasiert,
    PromptNodeConfig? promptConfig,
  }) : promptConfig =
           promptConfig ??
           const PromptNodeConfig(
             instruction: '',
             outputType: PromptOutputType.text,
             firstChoice: '',
             secondChoice: '',
           );

  final NodeId id;
  final WorkflowPrimitive primitive;
  final String title;
  final String description;
  final LogicMode logicMode;
  final PromptNodeConfig promptConfig;

  WorkflowNode copyWith({
    WorkflowPrimitive? primitive,
    String? title,
    String? description,
    LogicMode? logicMode,
    PromptNodeConfig? promptConfig,
  }) {
    return WorkflowNode(
      id: id,
      primitive: primitive ?? this.primitive,
      title: title ?? this.title,
      description: description ?? this.description,
      logicMode: logicMode ?? this.logicMode,
      promptConfig: promptConfig ?? this.promptConfig,
    );
  }
}
