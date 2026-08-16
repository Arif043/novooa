part of 'task_builder_cubit.dart';

extension TaskBuilderDialogInputMutations on TaskBuilderCubit {
  Future<void> updateDialogInput(
    NodeId nodeId,
    DialogInputNodeConfig Function(DialogInputNodeConfig config) update,
  ) {
    return _updateNode(nodeId, (node) {
      if (node.config case DialogInputNodeConfig config) {
        return node.copyWith(config: update(config));
      }
      return node;
    });
  }
}
