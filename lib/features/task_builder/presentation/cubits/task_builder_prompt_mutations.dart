part of 'task_builder_cubit.dart';

extension TaskBuilderPromptMutations on TaskBuilderCubit {
  Future<void> updatePromptInstruction(NodeId nodeId, String instruction) {
    return _updatePromptConfig(
      nodeId,
      (config) => config.copyWith(instruction: instruction),
    );
  }

  Future<void> updatePromptLanguageModel(
    NodeId nodeId,
    String languageModelId,
  ) {
    return _updatePromptConfig(
      nodeId,
      (config) => config.copyWith(languageModelId: languageModelId),
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

  /// Der Feldname ist der Schlüssel des Werts (JSON-Feld für das Modell) und
  /// muss nur innerhalb des Bausteins eindeutig sein; graph-weit eindeutig
  /// ist der Name in `WorkflowNode.outputs`.
  Future<void> updatePromptStructuredField({
    required NodeId nodeId,
    required int fieldIndex,
    required StructuredOutputField field,
  }) {
    return _updatePromptConfig(nodeId, (config) {
      if (fieldIndex < 0 || fieldIndex >= config.structuredFields.length) {
        return config;
      }
      final siblings = [
        for (final (index, other) in config.structuredFields.indexed)
          if (index != fieldIndex) other.name,
      ];
      final uniqueField = field.copyWith(
        name: _uniqueFieldName(siblings, _normalizedOutputName(field.name)),
      );
      return config.updateStructuredField(fieldIndex, uniqueField);
    });
  }

  Future<void> addPromptStructuredField(NodeId nodeId) {
    return _updatePromptConfig(nodeId, (config) => config.addStructuredField());
  }

  Future<void> removePromptStructuredField({
    required NodeId nodeId,
    required int fieldIndex,
  }) {
    return _updatePromptConfig(
      nodeId,
      (config) => config.removeStructuredField(fieldIndex),
    );
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
}
