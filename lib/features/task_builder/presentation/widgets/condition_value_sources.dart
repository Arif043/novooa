import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_graph.dart';
import '../../domain/entities/workflow_node.dart';
import '../../domain/entities/workflow_node_outputs.dart';

/// Only offer outputs from preceding nodes in this path (including outer scopes).
WorkflowGraph conditionSourceGraph(WorkflowGraph graph, NodeId target) {
  List<WorkflowNode>? visit(
    WorkflowGraph current,
    List<WorkflowNode> inherited,
  ) {
    List<WorkflowNode> predecessors(NodeId id) {
      final ids = <NodeId>{};
      void collect(NodeId next) {
        for (final edge in current.edges.where((e) => e.to == next)) {
          if (edge.from != id && ids.add(edge.from)) collect(edge.from);
        }
      }

      collect(id);
      return current.nodes.where((node) => ids.contains(node.id)).toList();
    }

    if (current.nodes.any((node) => node.id == target)) {
      return [...inherited, ...predecessors(target)];
    }
    for (final node in current.nodes) {
      final nested = switch (node.config) {
        ConditionalNodeConfig(:final branches) => branches.map((b) => b.graph),
        ForEachNodeConfig(:final graph) => [graph],
        _ => <WorkflowGraph>[],
      };
      for (final child in nested) {
        final found = visit(child, [...inherited, ...predecessors(node.id)]);
        if (found != null) return found;
      }
    }
    return null;
  }

  return WorkflowGraph(nodes: visit(graph, []) ?? [], edges: const []);
}

Map<String, String> conditionValueSources(WorkflowGraph graph) {
  final result = <String, String>{};
  for (final node in graph.nodes) {
    // Flache Bausteine (strukturierter Prompt, Dialogeingabe, Script mit
    // workflow_output) bieten ihre Felder an, alle anderen ihre benannten
    // Werte — alle unter eigenem, flachem Namen.
    final names = hasFlatOutputFields(node.config)
        ? flatOutputFieldsOf(node.config)
        : [for (final output in node.outputs) output.name];
    for (final name in names.map((n) => n.trim()).where((n) => n.isNotEmpty)) {
      result['{{$name}}'] = '${node.title} · $name';
    }
  }
  return result;
}
