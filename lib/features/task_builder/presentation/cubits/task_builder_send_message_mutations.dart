part of 'task_builder_cubit.dart';

extension TaskBuilderSendMessageMutations on TaskBuilderCubit {
  Future<void> updateSendMessageRecipient(NodeId nodeId, String recipient) {
    return _updateSendMessage(nodeId, (config) {
      return config.copyWith(recipient: recipient);
    });
  }

  Future<void> updateSendMessageBody(NodeId nodeId, String message) {
    return _updateSendMessage(nodeId, (config) {
      return config.copyWith(message: message);
    });
  }

  Future<void> updateSendMessageSubject(NodeId nodeId, String subject) {
    return _updateSendMessage(nodeId, (config) {
      return config.copyWith(subject: subject);
    });
  }

  Future<void> _updateSendMessage(
    NodeId nodeId,
    SendChannelMessageNodeConfig Function(SendChannelMessageNodeConfig config)
    update,
  ) {
    return _updateNode(nodeId, (node) {
      if (node.config case SendChannelMessageNodeConfig config) {
        final updated = update(config);
        if (updated == config) return node;
        return node.copyWith(config: updated);
      }
      return node;
    });
  }
}
