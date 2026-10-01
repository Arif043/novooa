part of 'task_builder_cubit.dart';

extension TaskBuilderWriteFileMutations on TaskBuilderCubit {
  Future<void> updateWriteFileContent(NodeId nodeId, String contentTemplate) {
    return _updateWriteFileConfig(nodeId, (config) {
      if (config.contentTemplate == contentTemplate) return config;
      return config.copyWith(contentTemplate: contentTemplate);
    });
  }

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

  Future<void> selectExistingWriteFile(
    NodeId nodeId,
    NodeAttachment attachment,
  ) {
    return _updateWriteFileConfig(nodeId, (config) {
      return config.copyWith(
        fileName: attachment.displayName,
        contentType: attachment.contentType,
        fileId: _fileIdFromAttachment(attachment),
        clearFolderId: true,
      );
    });
  }

  Future<void> selectNewWriteFile({
    required NodeId nodeId,
    required String fileName,
    String? folderId,
    String contentType = 'text/plain',
  }) {
    return _updateWriteFileConfig(nodeId, (config) {
      return config.copyWith(
        fileName: fileName,
        contentType: contentType.trim().isEmpty ? 'text/plain' : contentType,
        clearFileId: true,
        folderId: folderId,
        clearFolderId: folderId == null,
      );
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

  String _fileIdFromAttachment(NodeAttachment attachment) {
    return attachment.id.split(':').first;
  }
}
