import 'node_config.dart';
import 'workflow_graph.dart';
import 'workflow_node.dart';

/// Der Graph, der [nodeId] tatsächlich enthält — durchsucht dazu rekursiv
/// auch die eingebetteten Graphen von Verzweigungs-Zweigen und „Für jedes
/// Element", da ein Knoten nicht zwingend im Wurzel-Graphen liegt.
WorkflowGraph? owningGraphOf(WorkflowGraph graph, NodeId nodeId) {
  if (graph.nodeOrNull(nodeId) != null) return graph;
  for (final node in graph.nodes) {
    final owner = _owningGraphInNestedGraphs(node.config, nodeId);
    if (owner != null) return owner;
  }
  return null;
}

WorkflowGraph? _owningGraphInNestedGraphs(NodeConfig config, NodeId nodeId) {
  if (config case ConditionalNodeConfig(:final branches)) {
    for (final branch in branches) {
      final owner = owningGraphOf(branch.graph, nodeId);
      if (owner != null) return owner;
    }
  }
  if (config case ForEachNodeConfig(:final graph)) {
    return owningGraphOf(graph, nodeId);
  }
  return null;
}

/// Der eindeutige, direkte Vorgänger-Baustein von [nodeId] — `null`, wenn es
/// keinen oder mehr als einen gibt (mehrdeutig — der Vorgänger ist dann
/// nicht mehr fachlich eindeutig ansprechbar), oder [nodeId] in keinem
/// erreichbaren Graphen liegt.
WorkflowNode? directPredecessorOf(WorkflowGraph rootGraph, NodeId nodeId) {
  final graph = owningGraphOf(rootGraph, nodeId);
  if (graph == null) return null;
  final predecessors = graph.predecessorsOf(nodeId);
  return predecessors.length == 1 ? predecessors.single : null;
}
