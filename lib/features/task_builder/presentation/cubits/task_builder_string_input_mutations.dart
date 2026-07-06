part of 'task_builder_cubit.dart';

extension TaskBuilderStringInputMutations on TaskBuilderCubit {
  Future<void> updateStringInputValue(NodeId nodeId, String value) {
    return _updateNode(nodeId, (node) {
      if (node.config case StringInputNodeConfig config) {
        if (config.value == value) return node;
        return node.copyWith(config: config.copyWith(value: value));
      }
      return node;
    });
  }
}
