import 'workflow_edge.dart';
import 'workflow_node.dart';

/// Aggregate Root eines Workflows.
///
/// Invarianten (siehe `docs/features/aufgabe.md` § Domänen-Invarianten):
/// 1. Immutable: jede Mutation liefert eine neue Instanz über [copyWith].
/// 2. Knoten-IDs sind stabil (über [NodeId]).
/// 3. Höchstens ein Knoten ist via [selectedNodeId] markiert.
/// 4. Edges referenzieren ausschließlich existierende Knoten.
/// 5. Persistenz nach jeder Mutation ist Sache des Cubits, nicht der Entity.
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.objective,
    required this.nodes,
    required this.edges,
    required this.selectedNodeId,
  });

  final String id;
  final String title;
  final String objective;
  final List<WorkflowNode> nodes;
  final List<WorkflowEdge> edges;
  final NodeId selectedNodeId;

  static Task empty() {
    return Task(
      id: '',
      title: '',
      objective: '',
      nodes: [],
      edges: [],
      selectedNodeId: NodeId(''),
    );
  }

  /// Selektierter Knoten. Wirft [StateError], wenn die Selection auf einen
  /// nicht (mehr) existierenden Knoten zeigt — die Cubit-Schicht hält diese
  /// Invariante ein. Für UI-Code, der defensiv sein muss, siehe
  /// [selectedNodeOrNull].
  WorkflowNode get selectedNode {
    return nodes.firstWhere((node) => node.id == selectedNodeId);
  }

  /// Null-sichere Variante von [selectedNode] für UI-Konsumenten.
  WorkflowNode? get selectedNodeOrNull {
    for (final node in nodes) {
      if (node.id == selectedNodeId) return node;
    }
    return null;
  }

  /// Setzt die Auswahl auf [nodeId]. No-op, wenn der Knoten nicht existiert
  /// (UI bleibt konsistent, statt im Inspector einen leeren Zustand zu zeigen).
  Task selectNode(NodeId nodeId) {
    final exists = nodes.any((node) => node.id == nodeId);
    if (!exists) return this;
    return copyWith(selectedNodeId: nodeId);
  }

  /// Fügt einen Knoten hinzu und erzeugt eine implizite Kante aus der
  /// aktuellen Selection. Wenn die Liste leer ist, wird der Knoten ohne
  /// eingehende Kante eingefügt und sofort selektiert.
  Task addNode(WorkflowNode node) {
    final newEdges = nodes.isEmpty ? edges : <WorkflowEdge>[...edges, WorkflowEdge(from: selectedNodeId, to: node.id)];
    return copyWith(nodes: [...nodes, node], edges: newEdges, selectedNodeId: node.id);
  }

  /// Liefert alle ausgehenden Kanten eines Knotens in der Reihenfolge, in
  /// der sie im [edges]-Feld stehen. Wird vom Inspector für die
  /// Bedingungen-Liste verwendet.
  List<WorkflowEdge> outgoingEdgesOf(NodeId nodeId) {
    final result = <WorkflowEdge>[];
    for (final edge in edges) {
      if (edge.from == nodeId) result.add(edge);
    }
    return result;
  }

  /// Aktualisiert das `conditionLabel` der Kante zwischen [from] und [to].
  /// No-op, wenn keine solche Kante existiert. Wird vom
  /// Bedingungen-Editor im Inspector verwendet.
  Task updateEdgeCondition({required NodeId from, required NodeId to, required String? conditionLabel}) {
    var changed = false;
    final newEdges = edges
        .map((edge) {
          if (edge.from == from && edge.to == to) {
            changed = true;
            return WorkflowEdge(from: edge.from, to: edge.to, conditionLabel: conditionLabel);
          }
          return edge;
        })
        .toList(growable: false);
    if (!changed) return this;
    return copyWith(edges: newEdges);
  }

  /// Fügt eine neue ausgehende Bedingung von [from] nach [to] hinzu.
  /// Falls bereits eine Kante in dieser Richtung existiert, wird deren
  /// `conditionLabel` aktualisiert.
  Task addOutgoingCondition({required NodeId from, required NodeId to, String? conditionLabel}) {
    final exists = edges.any((e) => e.from == from && e.to == to);
    if (exists) {
      return updateEdgeCondition(from: from, to: to, conditionLabel: conditionLabel);
    }
    return copyWith(
      edges: [
        ...edges,
        WorkflowEdge(from: from, to: to, conditionLabel: conditionLabel),
      ],
    );
  }

  /// Entfernt einen Knoten inklusive aller ein- und ausgehenden Kanten.
  /// Reparatur der Selection:
  /// - zeigt die Selection auf den entfernten Knoten, fällt sie auf den
  ///   letzten verbleibenden Knoten zurück,
  /// - zeigt sie auf einen noch existierenden Knoten, bleibt sie,
  /// - gibt es keinen Knoten mehr, wird ein Sentinel [NodeId] gesetzt;
  ///   [selectedNodeOrNull] liefert dann `null` und der Inspector zeigt den
  ///   leeren Zustand.
  Task removeNode(NodeId nodeId) {
    final nodeExists = nodes.any((node) => node.id == nodeId);
    if (!nodeExists) return this;

    final remainingNodes = nodes.where((node) => node.id != nodeId).toList(growable: false);
    final remainingEdges = edges.where((edge) => edge.from != nodeId && edge.to != nodeId).toList(growable: false);

    final selectionStillValid = remainingNodes.any((node) => node.id == selectedNodeId);
    final newSelection = selectionStillValid
        ? selectedNodeId
        : (remainingNodes.isNotEmpty ? remainingNodes.last.id : const NodeId(''));

    return copyWith(nodes: remainingNodes, edges: remainingEdges, selectedNodeId: newSelection);
  }

  Task copyWith({
    String? title,
    String? objective,
    List<WorkflowNode>? nodes,
    List<WorkflowEdge>? edges,
    NodeId? selectedNodeId,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      objective: objective ?? this.objective,
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
      selectedNodeId: selectedNodeId ?? this.selectedNodeId,
    );
  }
}
