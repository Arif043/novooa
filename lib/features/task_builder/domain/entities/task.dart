import 'package:uuid/uuid.dart';
import 'workflow_edge.dart';
import 'workflow_graph.dart';
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
    required this.graph,
    required this.selectedNodeId,
  });

  final String id;
  final String title;
  final String objective;
  final WorkflowGraph graph;
  final NodeId selectedNodeId;

  List<WorkflowNode> get nodes => graph.nodes;

  List<WorkflowEdge> get edges => graph.edges;

  static Task empty() {
    return Task(
      id: const Uuid().v4(),
      title: 'Empty Task',
      objective: '',
      graph: WorkflowGraph.empty(),
      selectedNodeId: const NodeId(''),
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
    return copyWith(
      graph: graph.addNode(node, selectedNodeId),
      selectedNodeId: node.id,
    );
  }

  /// Liefert alle ausgehenden Kanten eines Knotens in der Reihenfolge, in
  /// der sie im [edges]-Feld stehen. Wird vom Inspector für die
  /// Bedingungen-Liste verwendet.
  List<WorkflowEdge> outgoingEdgesOf(NodeId nodeId) {
    return graph.outgoingEdgesOf(nodeId);
  }

  /// Liefert alle eingehenden Kanten eines Knotens in der Reihenfolge, in
  /// der sie im [edges]-Feld stehen.
  List<WorkflowEdge> incomingEdgesOf(NodeId nodeId) {
    return graph.incomingEdgesOf(nodeId);
  }

  /// Liefert alle Knoten, die eine Kante zu [nodeId] haben.
  List<WorkflowNode> predecessorsOf(NodeId nodeId) {
    return graph.predecessorsOf(nodeId);
  }

  List<WorkflowNode> successorsOf(NodeId nodeId) {
    return graph.successorsOf(nodeId);
  }

  /// Aktualisiert das `conditionLabel` der Kante zwischen [from] und [to].
  /// No-op, wenn keine solche Kante existiert. Wird vom
  /// Bedingungen-Editor im Inspector verwendet.
  Task updateEdgeCondition({
    required NodeId from,
    required NodeId to,
    required String? conditionLabel,
  }) {
    return copyWith(
      graph: graph.updateEdgeCondition(
        from: from,
        to: to,
        conditionLabel: conditionLabel,
      ),
    );
  }

  /// Fügt eine neue ausgehende Bedingung von [from] nach [to] hinzu.
  /// Falls bereits eine Kante in dieser Richtung existiert, wird deren
  /// `conditionLabel` aktualisiert.
  Task addOutgoingCondition({
    required NodeId from,
    required NodeId to,
    String? conditionLabel,
  }) {
    return copyWith(
      graph: graph.addOutgoingCondition(
        from: from,
        to: to,
        conditionLabel: conditionLabel,
      ),
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

    final updatedGraph = graph.removeNode(nodeId);

    final selectionStillValid = updatedGraph.nodes.any(
      (node) => node.id == selectedNodeId,
    );
    final newSelection = selectionStillValid
        ? selectedNodeId
        : (updatedGraph.nodes.isNotEmpty
              ? updatedGraph.nodes.last.id
              : const NodeId(''));

    return copyWith(graph: updatedGraph, selectedNodeId: newSelection);
  }

  Task copyWith({
    String? title,
    String? objective,
    WorkflowGraph? graph,
    List<WorkflowNode>? nodes,
    List<WorkflowEdge>? edges,
    NodeId? selectedNodeId,
  }) {
    final updatedGraph =
        graph ?? this.graph.copyWith(nodes: nodes, edges: edges);
    return Task(
      id: id,
      title: title ?? this.title,
      objective: objective ?? this.objective,
      graph: updatedGraph,
      selectedNodeId: selectedNodeId ?? this.selectedNodeId,
    );
  }
}
