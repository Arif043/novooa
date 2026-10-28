import '../../../task_builder/domain/entities/node_config.dart';
import '../../../task_builder/domain/entities/workflow_graph.dart';

/// Wo ein Baustein im Graphen eines Laufs steht: die Schleife, deren Runde
/// ihn bestimmt (auch durch Zweige hindurch), und der unmittelbar
/// umschließende Baustein.
class RunGraphPlacement {
  RunGraphPlacement(WorkflowGraph graph) {
    _visit(graph, loopId: null, parentId: null);
  }

  final _loopOf = <String, String?>{};
  final _parentOf = <String, String?>{};

  /// Die nächste umschließende Schleife; `null` außerhalb von Schleifen.
  String? loopOf(String nodeId) => _loopOf[nodeId];

  String? parentOf(String nodeId) => _parentOf[nodeId];

  void _visit(
    WorkflowGraph graph, {
    required String? loopId,
    required String? parentId,
  }) {
    for (final node in graph.nodes) {
      final id = node.id.value;
      _loopOf[id] = loopId;
      _parentOf[id] = parentId;
      switch (node.config) {
        case ForEachNodeConfig(:final graph):
          _visit(graph, loopId: id, parentId: id);
        case ConditionalNodeConfig(:final branches):
          for (final branch in branches) {
            _visit(branch.graph, loopId: loopId, parentId: id);
          }
        default:
          break;
      }
    }
  }
}
