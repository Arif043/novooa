part of 'task_builder_cubit.dart';

extension TaskBuilderPluginMutations on TaskBuilderCubit {
  Future<void> updatePluginNode(
    NodeId nodeId,
    PluginNodeConfig Function(PluginNodeConfig config) update,
  ) {
    return _updateNode(nodeId, (node) {
      if (node.config case PluginNodeConfig config) {
        return node.copyWith(config: update(config));
      }
      return node;
    });
  }
}
