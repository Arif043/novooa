part of 'task_builder_cubit.dart';

extension TaskBuilderReadFileMutations on TaskBuilderCubit {
  Future<void> selectReadFile(NodeId nodeId, NodeAttachment file) {
    return _updateReadFileConfig(nodeId, (config) {
      if (config.file == file) return config;
      return config.copyWith(file: file);
    });
  }

  Future<void> clearReadFile(NodeId nodeId) {
    return _updateReadFileConfig(
      nodeId,
      (config) => config.copyWith(clearFile: true),
    );
  }

  Future<void> _updateReadFileConfig(
    NodeId nodeId,
    ReadFileNodeConfig Function(ReadFileNodeConfig config) update,
  ) {
    return _updateNode(nodeId, (node) {
      if (node.config case ReadFileNodeConfig config) {
        return node.copyWith(config: update(config));
      }
      return node;
    });
  }
}
