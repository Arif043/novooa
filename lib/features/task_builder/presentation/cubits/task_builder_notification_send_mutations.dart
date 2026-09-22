part of 'task_builder_cubit.dart';

extension TaskBuilderNotificationSendMutations on TaskBuilderCubit {
  Future<void> updateNotificationSend(
    NodeId nodeId,
    NotificationSendNodeConfig Function(NotificationSendNodeConfig config) update,
  ) {
    return _updateNode(nodeId, (node) {
      if (node.config case NotificationSendNodeConfig config) {
        return node.copyWith(config: update(config));
      }
      return node;
    });
  }
}
