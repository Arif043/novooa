part of 'task_builder_cubit.dart';

extension TaskBuilderHumanApprovalMutations on TaskBuilderCubit {
  Future<void> updateHumanApproval(
    NodeId nodeId,
    HumanApprovalNodeConfig Function(HumanApprovalNodeConfig config) update,
  ) {
    return _updateNode(nodeId, (node) {
      if (node.config case HumanApprovalNodeConfig config) {
        return node.copyWith(config: update(config));
      }
      return node;
    });
  }
}
