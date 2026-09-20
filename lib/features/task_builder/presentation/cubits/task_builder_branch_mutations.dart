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

  Future<void> addNodeToBranch({
    required NodeId conditionalNodeId,
    required String branchId,
    required WorkflowPrimitive primitive,
  }) async {
    final task = loadedTaskOrNull();
    if (task == null) return;
    final node = _buildNode(primitive, _nextNodeNumber(task.graph));
    final update = _addNodeToBranchInGraph(
      graph: task.graph,
      conditionalNodeId: conditionalNodeId,
      branchId: branchId,
      node: node,
    );
    if (!update.changed) return;
    await _saveAndEmit(task.copyWith(graph: update.graph));
  }

  ({WorkflowGraph graph, bool changed}) _addNodeToBranchInGraph({
    required WorkflowGraph graph,
    required NodeId conditionalNodeId,
    required String branchId,
    required WorkflowNode node,
  }) {
    for (var index = 0; index < graph.nodes.length; index++) {
      final update = _addNodeToBranchInNode(
        owner: graph.nodes[index],
        conditionalNodeId: conditionalNodeId,
        branchId: branchId,
        node: node,
      );
      if (!update.changed) continue;
      final nodes = [...graph.nodes]..[index] = update.node;
      return (graph: graph.copyWith(nodes: nodes), changed: true);
    }
    return (graph: graph, changed: false);
  }

  ({WorkflowNode node, bool changed}) _addNodeToBranchInNode({
    required WorkflowNode owner,
    required NodeId conditionalNodeId,
    required String branchId,
    required WorkflowNode node,
  }) {
    final config = owner.config;
    if (config is ConditionalNodeConfig) {
      if (owner.id == conditionalNodeId) {
        return _addNodeToBranchConfig(owner, config, branchId, node);
      }
      return _addNodeToNestedBranch(
        owner,
        config,
        conditionalNodeId,
        branchId,
        node,
      );
    }
    if (config is ForEachNodeConfig) {
      final update = _addNodeToBranchInGraph(
        graph: config.graph,
        conditionalNodeId: conditionalNodeId,
        branchId: branchId,
        node: node,
      );
      if (update.changed) {
        return (
          node: owner.copyWith(config: config.copyWith(graph: update.graph)),
          changed: true,
        );
      }
    }
    return (node: owner, changed: false);
  }

  ({WorkflowNode node, bool changed}) _addNodeToBranchConfig(
    WorkflowNode owner,
    ConditionalNodeConfig config,
    String branchId,
    WorkflowNode node,
  ) {
    final branchIndex = config.branches.indexWhere(
      (branch) => branch.id == branchId,
    );
    if (branchIndex == -1) return (node: owner, changed: false);

    final branch = config.branches[branchIndex];
    final branches = [...config.branches]
      ..[branchIndex] = branch.copyWith(graph: _appendNode(branch.graph, node));
    return (node: _withBranches(owner, config, branches), changed: true);
  }

  ({WorkflowNode node, bool changed}) _addNodeToNestedBranch(
    WorkflowNode owner,
    ConditionalNodeConfig config,
    NodeId conditionalNodeId,
    String branchId,
    WorkflowNode node,
  ) {
    for (var index = 0; index < config.branches.length; index++) {
      final branch = config.branches[index];
      final update = _addNodeToBranchInGraph(
        graph: branch.graph,
        conditionalNodeId: conditionalNodeId,
        branchId: branchId,
        node: node,
      );
      if (!update.changed) continue;
      final branches = [...config.branches]
        ..[index] = branch.copyWith(graph: update.graph);
      return (node: _withBranches(owner, config, branches), changed: true);
    }
    return (node: owner, changed: false);
  }

  WorkflowNode _withBranches(
    WorkflowNode owner,
    ConditionalNodeConfig config,
    List<ConditionalBranch> branches,
  ) {
    return owner.copyWith(config: config.copyWith(branches: branches));
  }

  WorkflowGraph _appendNode(WorkflowGraph graph, WorkflowNode node) {
    final selectedNodeId = graph.nodes.isEmpty
        ? const NodeId('')
        : graph.nodes.last.id;
    return graph.addNode(node, selectedNodeId);
  }
}
