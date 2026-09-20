part of 'task_builder_cubit.dart';

extension TaskBuilderIterativeRefinementMutations on TaskBuilderCubit {
  Future<void> updateIterativeDraft(NodeId nodeId, String draftTemplate) {
    return _updateNode(nodeId, (node) {
      final config = node.config;
      if (config is! IterativeRefinementNodeConfig) return node;
      if (config.draftTemplate == draftTemplate) return node;
      return node.copyWith(
        config: config.copyWith(draftTemplate: draftTemplate),
      );
    });
  }

  Future<void> updateIterativeOptimizer(NodeId nodeId, String optimizerPrompt) {
    return _updateNode(nodeId, (node) {
      final config = node.config;
      if (config is! IterativeRefinementNodeConfig) return node;
      if (config.optimizerPrompt == optimizerPrompt) return node;
      return node.copyWith(
        config: config.copyWith(optimizerPrompt: optimizerPrompt),
      );
    });
  }

  Future<void> updateIterativeCritique(NodeId nodeId, String critiquePrompt) {
    return _updateNode(nodeId, (node) {
      final config = node.config;
      if (config is! IterativeRefinementNodeConfig) return node;
      if (config.critiquePrompt == critiquePrompt) return node;
      return node.copyWith(
        config: config.copyWith(critiquePrompt: critiquePrompt),
      );
    });
  }

  Future<void> updateIterativeMaxIterations(NodeId nodeId, int maxIterations) {
    return _updateNode(nodeId, (node) {
      final config = node.config;
      if (config is! IterativeRefinementNodeConfig) return node;
      final boundedIterations = maxIterations.clamp(1, 5).toInt();
      if (config.maxIterations == boundedIterations) return node;
      return node.copyWith(
        config: config.copyWith(maxIterations: boundedIterations),
      );
    });
  }
}
