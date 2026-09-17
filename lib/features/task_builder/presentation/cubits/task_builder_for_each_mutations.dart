part of 'task_builder_cubit.dart';

extension TaskBuilderForEachMutations on TaskBuilderCubit {
  Future<void> addNodeToForEachGraph({
    required NodeId forEachNodeId,
    required WorkflowPrimitive primitive,
  }) async {
    final task = loadedTaskOrNull();
    if (task == null) return;
    final node = _buildNode(primitive, _nextNodeNumber(task.graph));
    await _updateNode(forEachNodeId, (owner) {
      if (owner.config case final ForEachNodeConfig config) {
        final graph = _appendNode(config.graph, node);
        return owner.copyWith(config: config.copyWith(graph: graph));
      }
      return owner;
    });
  }

  Future<void> updateForEachPointer(NodeId nodeId, String itemsPointer) {
    return _updateNode(nodeId, (node) {
      if (node.config case ForEachNodeConfig config) {
        return node.copyWith(
          config: config.copyWith(itemsPointer: itemsPointer),
        );
      }
      return node;
    });
  }
}
