part of 'task_builder_cubit.dart';

extension TaskBuilderWriteFileMutations on TaskBuilderCubit {
  Future<void> updateWriteFileName(NodeId nodeId, String fileName) {
    return _updateWriteFileConfig(nodeId, (config) {
      if (config.fileName == fileName) return config;
      return config.copyWith(fileName: fileName);
    });
  }

  Future<void> updateWriteFileContentType(NodeId nodeId, String contentType) {
    return _updateWriteFileConfig(nodeId, (config) {
      if (config.contentType == contentType) return config;
      return config.copyWith(contentType: contentType);
    });
  }

  Future<void> _updateWriteFileConfig(
    NodeId nodeId,
    WriteFileNodeConfig Function(WriteFileNodeConfig config) update,
  ) {
    return _updateNode(nodeId, (node) {
      if (node.config case WriteFileNodeConfig config) {
        return node.copyWith(config: update(config));
      }
      return node;
    });
  }
}
