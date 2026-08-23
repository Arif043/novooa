part of 'task_builder_cubit.dart';

extension TaskBuilderForEachMutations on TaskBuilderCubit {
  Future<void> updateForEachPointer(NodeId nodeId, String itemsPointer) {
    return _updateNode(nodeId, (node) {
      if (node.config case ForEachNodeConfig config) {
        return node.copyWith(config: config.copyWith(itemsPointer: itemsPointer));
      }
      return node;
    });
  }
}
