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
  sendChannelMessage,
  toolCall,
  humanApproval,
  validation,
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
    this.referenceName = '',
  });

  final NodeId id;
  final String title;
  final String description;
  final String referenceName;
  final NodeConfig config;

  WorkflowNode copyWith({
    String? title,
    String? description,
    String? referenceName,
    NodeConfig? config,
  }) {
    return WorkflowNode(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      referenceName: referenceName ?? this.referenceName,
      config: config ?? this.config,
    );
  }

  @override
  List<Object?> get props => [id, title, description, referenceName, config];

  @override
  bool? get stringify => true;
}
