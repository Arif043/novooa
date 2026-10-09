part of 'task_builder_cubit.dart';

extension TaskBuilderChannelEventMutations on TaskBuilderCubit {
  /// Die Werte von „Nachricht lesen“ sind flache Outputs ohne Knotennamen
  /// (wie strukturierte Prompt-Felder) und müssen deshalb graph-weit
  /// eindeutig sein. Ein leerer Name wird ignoriert.
  Future<void> renameChannelEventOutputName({
    required NodeId nodeId,
    required ChannelEventOutputField field,
    required String name,
  }) {
    final task = loadedTaskOrNull();
    if (task == null) return Future.value();
    final normalized = _normalizedOutputName(name);
    if (normalized.isEmpty) return Future.value();
    return _updateNode(nodeId, (node) {
      if (node.config case ReadChannelEventNodeConfig config) {
        final previousName = config.outputNames.nameOf(field);
        final unique = _uniqueOutputName(task.graph, previousName, normalized);
        return node.copyWith(
          config: config.copyWith(
            outputNames: config.outputNames.rename(field, unique),
          ),
        );
      }
      return node;
    });
  }
}
