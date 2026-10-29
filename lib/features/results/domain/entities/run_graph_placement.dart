import '../../../task_builder/domain/entities/node_config.dart';
import '../../../task_builder/domain/entities/workflow_graph.dart';

/// Wo ein Baustein im Graphen eines Laufs steht und wie er heißt: die
/// Schleife, deren Runde ihn bestimmt (auch durch Zweige hindurch), der
/// unmittelbar umschließende Baustein und sein Titel.
class RunGraphPlacement {
  RunGraphPlacement(WorkflowGraph graph) {
    _visit(graph, loopId: null, parentId: null);
  }

  final _loopOf = <String, String?>{};
  final _parentOf = <String, String?>{};
  final _titleOf = <String, String>{};

  /// Die nächste umschließende Schleife; `null` außerhalb von Schleifen.
  String? loopOf(String nodeId) => _loopOf[nodeId];

  String? parentOf(String nodeId) => _parentOf[nodeId];

  /// Der Titel aus dem Graphen; `null` für Bausteine, die es darin nicht gibt.
  String? titleOf(String nodeId) => _titleOf[nodeId];

  void _visit(
    WorkflowGraph graph, {
    required String? loopId,
    required String? parentId,
  }) {
    for (final node in graph.nodes) {
      final id = node.id.value;
      _loopOf[id] = loopId;
      _parentOf[id] = parentId;
      _titleOf[id] = node.title;
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
