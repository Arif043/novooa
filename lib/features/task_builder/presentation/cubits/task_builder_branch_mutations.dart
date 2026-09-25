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

  /// Benennt einen einzelnen Zweig um (z.B. "Ja" → "Vielleicht") — wirkt
  /// sich fachlich auf die Verzweigung zur Laufzeit aus, da
  /// `conditionalFlow` den aufgelösten Wert gegen genau diese Branch-Labels
  /// matcht (siehe `conditional-executor.ts`).
  Future<void> updateConditionalBranchLabel({
    required NodeId conditionalNodeId,
    required String branchId,
    required String label,
  }) {
    if (label.trim().isEmpty) return Future.value();
    return _updateNode(conditionalNodeId, (node) {
      if (node.config case ConditionalNodeConfig config) {
        final branches = [
          for (final branch in config.branches)
            if (branch.id == branchId)
              branch.copyWith(label: label.trim())
            else
              branch,
        ];
        return node.copyWith(config: config.copyWith(branches: branches));
      }
      return node;
    });
  }
}
