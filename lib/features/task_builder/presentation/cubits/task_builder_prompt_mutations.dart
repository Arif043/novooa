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

  /// Beim Wechsel auf oder weg von „Entscheidung“ bekommt der Hauptwert
  /// immer den Standardnamen des neuen Typs („Antwort“ bzw. „Text“, bei
  /// Kollision nummeriert) — auch wenn er vorher umbenannt war. Bedingungen
  /// eines nachfolgenden Bedingten Ablaufs ziehen den Namen nach.
  Future<void> updatePromptOutputType(
    NodeId nodeId,
    PromptOutputType outputType,
  ) async {
    final task = loadedTaskOrNull();
    if (task == null) return;
    final previousName = _primaryNameOf(nodeId);
    await _updateNode(nodeId, (node) {
      if (node.config case final PromptNodeConfig config) {
        final updated = node.copyWith(
          config: config.copyWith(outputType: outputType),
        );
        final decisionChanged =
            _isDecisionPrompt(config) != _isDecisionPrompt(updated.config);
        return decisionChanged
            ? _withResetPrimaryName(updated, task.graph)
            : updated;
      }
      return node;
    });
    await _renameDecisionOperands(nodeId, previousName, _primaryNameOf(nodeId));
  }

  /// Eine umbenannte Antwort zieht in Zweigen nach, deren Bedingung noch
  /// unverändert auf sie prüft (siehe `withRenamedAnswer`).
  Future<void> updatePromptChoice({
    required NodeId nodeId,
    required int choiceIndex,
    required String value,
  }) async {
    final previous = _promptChoiceOrNull(nodeId, choiceIndex);
    await _updatePromptConfig(
      nodeId,
      (config) => config.updateChoice(choiceIndex, value),
    );
    if (previous != null) {
      await _renameDecisionAnswer(nodeId, previous, value);
    }
  }

  String? _promptChoiceOrNull(NodeId nodeId, int choiceIndex) {
    final task = loadedTaskOrNull();
    final node = task == null ? null : _nodeOrNullInGraph(task.graph, nodeId);
    if (node?.config case PromptNodeConfig(
      :final choices,
    ) when choiceIndex >= 0 && choiceIndex < choices.length) {
      return choices[choiceIndex];
    }
    return null;
  }

  Future<void> addPromptChoice(NodeId nodeId) async {
    await _updatePromptConfig(nodeId, (config) => config.addChoice());
  }

  Future<void> removePromptChoice({
    required NodeId nodeId,
    required int choiceIndex,
  }) async {
    await _updatePromptConfig(
      nodeId,
      (config) => config.removeChoice(choiceIndex),
    );
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
