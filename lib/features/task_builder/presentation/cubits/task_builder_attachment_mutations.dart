part of 'task_builder_cubit.dart';

extension TaskBuilderAttachmentMutations on TaskBuilderCubit {
  Future<void> attachNodeFile({
    required NodeId nodeId,
    required NodeAttachment attachment,
  }) {
    return _updateAttachableConfig(
      nodeId,
      (config) => config.attachFile(attachment),
    );
  }

  Future<void> detachNodeFile({
    required NodeId nodeId,
    required String attachmentId,
  }) {
    return _updateAttachableConfig(
      nodeId,
      (config) => config.detachFile(attachmentId),
    );
  }

  Future<void> _updateAttachableConfig(
    NodeId nodeId,
    NodeConfig Function(FileAttachmentSupport config) update,
  ) {
    return _updateNode(nodeId, (node) {
      if (node.config case PromptNodeConfig config) {
        return node.copyWith(config: update(config));
      }
      if (node.config case ScriptNodeConfig config) {
        return node.copyWith(config: update(config));
      }
      return node;
    });
  }
}
