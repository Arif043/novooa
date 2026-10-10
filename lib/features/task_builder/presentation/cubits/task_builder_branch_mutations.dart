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

  /// Benennt einen einzelnen Zweig um. Das Label ist nur die Beschriftung;
  /// welcher Zweig greift, entscheidet seine Bedingung.
  Future<void> updateConditionalBranchLabel({
    required NodeId conditionalNodeId,
    required String branchId,
    required String label,
  }) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty) return;
    await _updateNode(conditionalNodeId, (node) {
      if (node.config case ConditionalNodeConfig config) {
        final branches = [
          for (final branch in config.branches)
            if (branch.id == branchId)
              branch.copyWith(label: trimmed)
            else
              branch,
        ];
        return node.copyWith(config: config.copyWith(branches: branches));
      }
      return node;
    });
  }
}
