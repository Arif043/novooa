part of 'task_builder_cubit.dart';

extension TaskBuilderBranchMutations on TaskBuilderCubit {
  Future<void> updateConditionalValue(NodeId nodeId, String valueTemplate) {
    return _updateNode(nodeId, (node) {
      if (node.config case ConditionalNodeConfig config) {
        return node.copyWith(
          config: config.copyWith(valueTemplate: valueTemplate),
        );
      }
      return node;
    });
  }
}
