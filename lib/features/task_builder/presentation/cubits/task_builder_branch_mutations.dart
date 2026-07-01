part of 'task_builder_cubit.dart';

extension TaskBuilderBranchMutations on TaskBuilderCubit {

  Future<void> addNodeToBranch({
    required NodeId conditionalNodeId,
    required String branchId,
    required WorkflowPrimitive primitive,
  }) async {
    final task = loadedTaskOrNull();
    if (task == null) return;
    final nodeIndex = task.nodes.indexWhere(
      (node) => node.id == conditionalNodeId,
    );
    if (nodeIndex == -1) return;

    final conditionalNode = task.nodes[nodeIndex];
    if (conditionalNode.config case final ConditionalNodeConfig config) {
      await _addNodeToBranchConfig(
        task: task,
        conditionalNode: conditionalNode,
        conditionalNodeIndex: nodeIndex,
        config: config,
        branchId: branchId,
        primitive: primitive,
      );
    }
  }

  Future<void> _addNodeToBranchConfig({
    required Task task,
    required WorkflowNode conditionalNode,
    required int conditionalNodeIndex,
    required ConditionalNodeConfig config,
    required String branchId,
    required WorkflowPrimitive primitive,
  }) async {
    final branchIndex = config.branches.indexWhere(
      (branch) => branch.id == branchId,
    );
    if (branchIndex == -1) return;

    final branch = config.branches[branchIndex];
    final node = _buildNode(primitive, _nodeCount(task.graph));
    final updatedBranch = branch.copyWith(
      graph: _appendNode(branch.graph, node),
    );
    final updatedBranches = [...config.branches]..[branchIndex] = updatedBranch;
    final updatedNode = conditionalNode.copyWith(
      config: config.copyWith(branches: updatedBranches),
    );
    final updatedNodes = [...task.nodes]..[conditionalNodeIndex] = updatedNode;
    await _saveAndEmit(
      task.copyWith(graph: task.graph.copyWith(nodes: updatedNodes)),
    );
    debugPrint(loadedTaskOrNull()!.graph.toString());
  }

  WorkflowGraph _appendNode(WorkflowGraph graph, WorkflowNode node) {
    final selectedNodeId = graph.nodes.isEmpty
        ? const NodeId('')
        : graph.nodes.last.id;
    return graph.addNode(node, selectedNodeId);
  }

  int _nodeCount(WorkflowGraph graph) {
    var count = graph.nodes.length;
    for (final node in graph.nodes) {
      if (node.config case final ConditionalNodeConfig config) {
        for (final branch in config.branches) {
          count += _nodeCount(branch.graph);
        }
      }
    }
    return count;
  }
}
