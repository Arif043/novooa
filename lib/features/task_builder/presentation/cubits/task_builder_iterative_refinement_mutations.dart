part of 'task_builder_cubit.dart';

extension TaskBuilderIterativeRefinementMutations on TaskBuilderCubit {
  Future<void> addPromptToIterativeRefinement(NodeId nodeId) async {
    final task = loadedTaskOrNull();
    final owner = task == null ? null : _nodeOrNullInGraph(task.graph, nodeId);
    if (task == null || owner?.config is! IterativeRefinementNodeConfig) return;
    final config = owner!.config as IterativeRefinementNodeConfig;
    if (config.graph.nodes.isNotEmpty) return;
    final promptNode = _buildNode(
      WorkflowPrimitive.prompt,
      _nodeCount(task.graph),
    );
    await _updateNode(nodeId, (node) {
      final current = node.config;
      if (current is! IterativeRefinementNodeConfig) return node;
      final graph = current.graph.addNode(promptNode, const NodeId(''));
      return node.copyWith(config: current.copyWith(graph: graph));
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
