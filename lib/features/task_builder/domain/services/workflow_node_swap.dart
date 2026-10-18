import '../entities/node_config.dart';
import '../entities/workflow_edge.dart';
import '../entities/workflow_graph.dart';
import '../entities/workflow_node.dart';

/// Tauscht zwei Bausteine an beliebiger Stelle des Plans: im selben Graphen,
/// zwischen Hauptplan und Zweig, zwischen zwei Zweigen oder mit dem Unterplan
/// einer Schleife. Jeder nimmt Position und Kanten des anderen ein.
class WorkflowNodeSwap {
  const WorkflowNodeSwap(this.root);

  final WorkflowGraph root;

  /// Ein Container (Bedingung, Schleife) kann nicht in seinen eigenen
  /// Unterplan wandern; das würde ihn in sich selbst schachteln.
  bool canSwap(NodeId first, NodeId second) {
    if (first == second) return false;
    final firstNode = _find(root, first);
    final secondNode = _find(root, second);
    if (firstNode == null || secondNode == null) return false;
    return !_contains(firstNode, second) && !_contains(secondNode, first);
  }

  WorkflowGraph swap(NodeId first, NodeId second) {
    if (!canSwap(first, second)) return root;
    final replacements = {
      first: _find(root, second)!,
      second: _find(root, first)!,
    };
    return _mapGraph(root, (id) => replacements[id], first, second);
  }

  WorkflowGraph _mapGraph(
    WorkflowGraph graph,
    WorkflowNode? Function(NodeId id) replacementFor,
    NodeId first,
    NodeId second,
  ) {
    return graph.copyWith(
      nodes: [
        for (final node in graph.nodes)
          replacementFor(node.id) ??
              _mapSubgraphs(
                node,
                (subgraph) =>
                    _mapGraph(subgraph, replacementFor, first, second),
              ),
      ],
      edges: [
        for (final edge in graph.edges)
          WorkflowEdge(
            from: _swapped(edge.from, first, second),
            to: _swapped(edge.to, first, second),
            conditionLabel: edge.conditionLabel,
          ),
      ],
    );
  }

  NodeId _swapped(NodeId id, NodeId first, NodeId second) {
    if (id == first) return second;
    if (id == second) return first;
    return id;
  }
}

WorkflowNode _mapSubgraphs(
  WorkflowNode node,
  WorkflowGraph Function(WorkflowGraph) map,
) {
  return switch (node.config) {
    final ConditionalNodeConfig config => node.copyWith(
      config: config.copyWith(
        branches: [
          for (final branch in config.branches)
            branch.copyWith(graph: map(branch.graph)),
        ],
      ),
    ),
    final ForEachNodeConfig config => node.copyWith(
      config: config.copyWith(graph: map(config.graph)),
    ),
    _ => node,
  };
}

Iterable<WorkflowGraph> _subgraphsOf(WorkflowNode node) =>
    switch (node.config) {
      ConditionalNodeConfig(:final branches) => branches.map(
        (branch) => branch.graph,
      ),
      ForEachNodeConfig(:final graph) => [graph],
      _ => const [],
    };

WorkflowNode? _find(WorkflowGraph graph, NodeId id) {
  for (final node in graph.nodes) {
    if (node.id == id) return node;
    for (final subgraph in _subgraphsOf(node)) {
      final nested = _find(subgraph, id);
      if (nested != null) return nested;
    }
  }
  return null;
}

bool _contains(WorkflowNode container, NodeId id) {
  return _subgraphsOf(container).any((subgraph) => _find(subgraph, id) != null);
}
