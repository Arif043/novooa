part of 'task_builder_cubit.dart';

extension TaskBuilderTableFromCollectionMutations on TaskBuilderCubit {
  Future<void> updateTableFromCollectionCollectionName(
    NodeId nodeId,
    String value,
  ) {
    return _updateNode(nodeId, (node) {
      if (node.config case TableFromCollectionNodeConfig config) {
        return node.copyWith(config: config.copyWith(collectionName: value));
      }
      return node;
    });
  }
}
