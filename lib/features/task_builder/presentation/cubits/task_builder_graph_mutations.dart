part of 'task_builder_cubit.dart';

extension TaskBuilderGraphMutations on TaskBuilderCubit {
  Future<void> addConnectedNode({
    required WorkflowPrimitive primitive,
    NodeId? ownerId,
    String? branchId,
    NodeId? afterId,
    ChannelEventKind? channelKind,
    String? pluginTypeId,
  }) async {
    final task = loadedTaskOrNull();
    if (task == null) return;
    var node = _buildNode(
      primitive,
      _nextNodeNumber(task.graph),
      task.graph,
      plugin: pluginTypeId == null
          ? null
          : PluginNodeModules.byTypeId(pluginTypeId),
    );
    if (channelKind != null) {
      node = switch (node.config) {
        ReadChannelEventNodeConfig config => node.copyWith(
          config: config.copyWith(kind: channelKind),
        ),
        SendChannelMessageNodeConfig config => node.copyWith(
          config: config.copyWith(kind: channelKind),
        ),
        _ => node,
      };
    }
    NodeId? insertedAfter;
    WorkflowGraph insert(WorkflowGraph graph) {
      final source =
          afterId ?? (graph.nodes.isEmpty ? node.id : graph.nodes.last.id);
      if (graph.nodes.isNotEmpty && graph.nodeOrNull(source) == null) {
        return graph;
      }
      insertedAfter = source;
      return graph.addNode(node, source);
    }

    if (ownerId == null) {
      final graph = insert(task.graph);
      if (graph == task.graph) return;
      await _saveAndEmit(task.copyWith(graph: graph, selectedNodeId: node.id));
      await _syncNewSuccessorIfNeeded(insertedAfter);
      return;
    }
    await _updateNode(ownerId, (owner) {
      if (owner.config case ConditionalNodeConfig config) {
        return owner.copyWith(
          config: config.copyWith(
            branches: [
              for (final branch in config.branches)
                if (branch.id == branchId)
                  branch.copyWith(graph: insert(branch.graph))
                else
                  branch,
            ],
          ),
        );
      }
      if (owner.config case ForEachNodeConfig config) {
        return owner.copyWith(
          config: config.copyWith(graph: insert(config.graph)),
        );
      }
      return owner;
    });
    await _syncNewSuccessorIfNeeded(insertedAfter);
  }

  /// Deckt den Fall ab, dass ein `conditionalFlow` neu direkt nach einem
  /// Entscheidungs-Prompt eingefügt wird — ohne diesen Aufruf bliebe er erst
  /// synchronisiert, sobald jemand danach eine Prompt-Choice bearbeitet.
  Future<void> _syncNewSuccessorIfNeeded(NodeId? source) async {
    if (source != null) await _syncConditionalSuccessors(source);
  }

  Future<void> swapNodes(NodeId sourceId, NodeId targetId) async {
    final task = loadedTaskOrNull();
    if (task == null || sourceId == targetId) return;
    final result = _swapNodesInGraph(task.graph, sourceId, targetId);
    if (!result.changed) return;
    await _saveAndEmit(task.copyWith(graph: result.graph));
  }

  ({WorkflowGraph graph, bool changed}) _swapNodesInGraph(
    WorkflowGraph graph,
    NodeId sourceId,
    NodeId targetId,
  ) {
    final swapped = graph.swapNodes(sourceId, targetId);
    if (swapped != graph) return (graph: swapped, changed: true);
    for (var index = 0; index < graph.nodes.length; index++) {
      final result = _swapNodesInNode(graph.nodes[index], sourceId, targetId);
      if (!result.changed) continue;
      final nodes = [...graph.nodes]..[index] = result.node;
      return (graph: graph.copyWith(nodes: nodes), changed: true);
    }
    return (graph: graph, changed: false);
  }

  ({WorkflowNode node, bool changed}) _swapNodesInNode(
    WorkflowNode node,
    NodeId sourceId,
    NodeId targetId,
  ) {
    if (node.config case final ConditionalNodeConfig config) {
      for (var index = 0; index < config.branches.length; index++) {
        final branch = config.branches[index];
        final result = _swapNodesInGraph(branch.graph, sourceId, targetId);
        if (!result.changed) continue;
        final branches = [...config.branches]
          ..[index] = branch.copyWith(graph: result.graph);
        return (node: _withBranches(node, config, branches), changed: true);
      }
    }
    if (node.config case final ForEachNodeConfig config) {
      final result = _swapNodesInGraph(config.graph, sourceId, targetId);
      if (result.changed) {
        return (
          node: node.copyWith(config: config.copyWith(graph: result.graph)),
          changed: true,
        );
      }
    }
    return (node: node, changed: false);
  }

  Future<void> _updateNode(
    NodeId nodeId,
    WorkflowNode Function(WorkflowNode node) update,
  ) async {
    final task = loadedTaskOrNull();
    if (task == null) return;
    final result = _updateNodeInGraph(task.graph, nodeId, update);
    if (!result.changed) return;
    await _saveAndEmit(task.copyWith(graph: result.graph));
  }

  ({WorkflowGraph graph, bool changed}) _updateNodeInGraph(
    WorkflowGraph graph,
    NodeId nodeId,
    WorkflowNode Function(WorkflowNode node) update,
  ) {
    for (var index = 0; index < graph.nodes.length; index++) {
      final result = _updateNodeInNode(graph.nodes[index], nodeId, update);
      if (!result.changed) continue;
      final nodes = [...graph.nodes]..[index] = result.node;
      return (graph: graph.copyWith(nodes: nodes), changed: true);
    }
    return (graph: graph, changed: false);
  }

  ({WorkflowNode node, bool changed}) _updateNodeInNode(
    WorkflowNode node,
    NodeId nodeId,
    WorkflowNode Function(WorkflowNode node) update,
  ) {
    if (node.id == nodeId) {
      final updatedNode = update(node);
      return (node: updatedNode, changed: updatedNode != node);
    }
    if (node.config case final ConditionalNodeConfig config) {
      return _updateNodeInBranches(node, config, nodeId, update);
    }
    if (node.config case final ForEachNodeConfig config) {
      final result = _updateNodeInGraph(config.graph, nodeId, update);
      if (result.changed) {
        return (
          node: node.copyWith(config: config.copyWith(graph: result.graph)),
          changed: true,
        );
      }
    }
    return (node: node, changed: false);
  }

  ({WorkflowNode node, bool changed}) _updateNodeInBranches(
    WorkflowNode node,
    ConditionalNodeConfig config,
    NodeId nodeId,
    WorkflowNode Function(WorkflowNode node) update,
  ) {
    for (var index = 0; index < config.branches.length; index++) {
      final branch = config.branches[index];
      final result = _updateNodeInGraph(branch.graph, nodeId, update);
      if (!result.changed) continue;
      final branches = [...config.branches]
        ..[index] = branch.copyWith(graph: result.graph);
      return (node: _withBranches(node, config, branches), changed: true);
    }
    return (node: node, changed: false);
  }

  WorkflowNode _withBranches(
    WorkflowNode node,
    ConditionalNodeConfig config,
    List<ConditionalBranch> branches,
  ) {
    return node.copyWith(config: config.copyWith(branches: branches));
  }

  WorkflowNode? _nodeOrNullInGraph(WorkflowGraph graph, NodeId nodeId) {
    for (final node in graph.nodes) {
      if (node.id == nodeId) return node;
      if (node.config case final ConditionalNodeConfig config) {
        final nestedNode = _nodeOrNullInBranches(config, nodeId);
        if (nestedNode != null) return nestedNode;
      }
      if (node.config case final ForEachNodeConfig config) {
        final nestedNode = _nodeOrNullInGraph(config.graph, nodeId);
        if (nestedNode != null) return nestedNode;
      }
    }
    return null;
  }

  WorkflowNode? _nodeOrNullInBranches(
    ConditionalNodeConfig config,
    NodeId nodeId,
  ) {
    for (final branch in config.branches) {
      final node = _nodeOrNullInGraph(branch.graph, nodeId);
      if (node != null) return node;
    }
    return null;
  }

  List<WorkflowNode> _successorsOf(Task task, NodeId nodeId) {
    final graph = _owningGraphOrNull(task.graph, nodeId);
    if (graph == null) return const [];
    return graph.edges
        .where((edge) => edge.from == nodeId)
        .map((edge) => graph.nodeOrNull(edge.to))
        .whereType<WorkflowNode>()
        .toList(growable: false);
  }

  WorkflowGraph? _owningGraphOrNull(WorkflowGraph graph, NodeId nodeId) {
    if (graph.nodes.any((node) => node.id == nodeId)) return graph;
    for (final node in graph.nodes) {
      if (node.config case final ConditionalNodeConfig config) {
        final owner = _owningGraphInBranches(config, nodeId);
        if (owner != null) return owner;
      }
      if (node.config case final ForEachNodeConfig config) {
        final owner = _owningGraphOrNull(config.graph, nodeId);
        if (owner != null) return owner;
      }
    }
    return null;
  }

  WorkflowGraph? _owningGraphInBranches(
    ConditionalNodeConfig config,
    NodeId nodeId,
  ) {
    for (final branch in config.branches) {
      final graph = _owningGraphOrNull(branch.graph, nodeId);
      if (graph != null) return graph;
    }
    return null;
  }

  /// Nur für Entscheidungs-Prompts — ihre Choices sind die einzig fachlich
  /// bedeutungsvollen Verzweigungsoptionen. Für andere Ausgabetypen bliebe
  /// ein direkt nachgeschalteter `conditionalFlow` weiterhin frei
  /// konfigurierbar (kein automatischer Eingriff in dessen `valueTemplate`).
  PromptNodeConfig? _decisionPromptConfig(Task? task, NodeId nodeId) {
    final node = task == null ? null : _nodeOrNullInGraph(task.graph, nodeId);
    if (node?.config case PromptNodeConfig config
        when config.outputType == PromptOutputType.decision) {
      return config;
    }
    return null;
  }

  Future<void> _syncConditionalSuccessors(NodeId nodeId) async {
    final task = loadedTaskOrNull();
    final promptNode = task == null
        ? null
        : _nodeOrNullInGraph(task.graph, nodeId);
    final promptConfig = _decisionPromptConfig(task, nodeId);
    if (task == null || promptNode == null || promptConfig == null) return;
    final valueTemplate = '{{${promptNode.outputName}}}';
    for (final successor in _successorsOf(task, nodeId)) {
      await _syncConditionalChoices(
        successor.id,
        promptConfig.choices,
        valueTemplate,
      );
    }
  }

  Future<void> _syncConditionalChoices(
    NodeId nodeId,
    List<String> choices,
    String valueTemplate,
  ) {
    return _updateNode(
      nodeId,
      (node) => switch (node.config) {
        ConditionalNodeConfig config => node.copyWith(
          config: config
              .copyWith(choices: choices)
              .copyWith(valueTemplate: valueTemplate),
        ),
        _ => node,
      },
    );
  }
}
