part of 'task_builder_cubit.dart';

extension TaskBuilderPromptMutations on TaskBuilderCubit {
  Future<void> updatePromptInstruction(NodeId nodeId, String instruction) {
    return _updatePromptConfig(
      nodeId,
      (config) => config.copyWith(instruction: instruction),
    );
  }

  Future<void> updatePromptOutputType(
    NodeId nodeId,
    PromptOutputType outputType,
  ) {
    return _updatePromptConfig(
      nodeId,
      (config) => config.copyWith(outputType: outputType),
    );
  }

  Future<void> updatePromptChoice({
    required NodeId nodeId,
    required int choiceIndex,
    required String value,
  }) async {
    debugPrint("updatePromptChoice ${choiceIndex} ${value}");
    await _updatePromptConfig(
      nodeId,
      (config) => config.updateChoice(choiceIndex, value),
    );
    await _syncConditionalSuccessors(nodeId);
  }

  Future<void> addPromptChoice(NodeId nodeId) async {
    await _updatePromptConfig(nodeId, (config) => config.addChoice());
    await _syncConditionalSuccessors(nodeId);
  }

  Future<void> removePromptChoice({
    required NodeId nodeId,
    required int choiceIndex,
  }) async {
    await _updatePromptConfig(
      nodeId,
      (config) => config.removeChoice(choiceIndex),
    );
    await _syncConditionalSuccessors(nodeId);
  }

  Future<void> _updatePromptConfig(
    NodeId nodeId,
    PromptNodeConfig Function(PromptNodeConfig config) update,
  ) {
    return _updateNode(nodeId, (node) {
      if (node.config case PromptNodeConfig config) {
        return node.copyWith(config: update(config));
      }
      return node;
    });
  }

  Future<void> _syncConditionalSuccessors(NodeId nodeId) async {
    final task = loadedTaskOrNull();
    final promptChoices = _promptChoices(task, nodeId);
    if (task == null || promptChoices == null) return;
    for (final successor in task.successorsOf(nodeId)) {
      await _syncConditionalChoices(successor.id, promptChoices);
    }
  }

  List<String>? _promptChoices(Task? task, NodeId nodeId) {
    final node = task?.nodes.where((node) => node.id == nodeId).firstOrNull;
    if (node?.config case PromptNodeConfig config) return config.choices;
    return null;
  }

  Future<void> _syncConditionalChoices(NodeId nodeId, List<String> choices) {
    return _updateNode(nodeId, (node) {
      if (node.config case ConditionalNodeConfig config) {
        return node.copyWith(config: config.copyWith(choices: choices));
      }
      return node;
    });
  }
}
