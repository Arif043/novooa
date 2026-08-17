part of 'task_builder_cubit.dart';

extension TaskBuilderMediaInputMutations on TaskBuilderCubit {
  Future<void> updateMediaInput(
    NodeId nodeId,
    MediaInputNodeConfig Function(MediaInputNodeConfig config) update,
  ) {
    return _updateNode(nodeId, (node) {
      if (node.config case MediaInputNodeConfig config) {
        return node.copyWith(config: update(config));
      }
      return node;
    });
  }
}
