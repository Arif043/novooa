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

  /// Der Feldname ist ein fachlicher Output ohne umschließenden Knotennamen
  /// (siehe `workflow_canvas_layout.dart`) und muss deshalb graph-weit
  /// eindeutig sein — nicht nur innerhalb dieses Bausteins.
  Future<void> updatePromptStructuredField({
    required NodeId nodeId,
    required int fieldIndex,
    required StructuredOutputField field,
  }) {
    final task = loadedTaskOrNull();
    if (task == null) return Future.value();
    return _updatePromptConfig(nodeId, (config) {
      if (fieldIndex < 0 || fieldIndex >= config.structuredFields.length) {
        return config;
      }
      final previousName = config.structuredFields[fieldIndex].name;
      final uniqueField = _uniqueStructuredField(
        task.graph,
        previousName,
        field,
      );
      return config.updateStructuredField(fieldIndex, uniqueField);
    });
  }

  /// Bequemlichkeits-Wrapper für Aufrufer, die nur Feldindex und neuen Namen
  /// kennen (z.B. ein Leinwand-Label-Doppelklick) — holt das aktuelle Feld
  /// selbst und ändert nur `name`, Beschreibung bleibt erhalten.
  Future<void> renamePromptStructuredFieldName({
    required NodeId nodeId,
    required int fieldIndex,
    required String name,
  }) {
    final task = loadedTaskOrNull();
    final node = task == null ? null : _nodeOrNullInGraph(task.graph, nodeId);
    final field = switch (node?.config) {
      PromptNodeConfig(:final structuredFields)
          when fieldIndex >= 0 && fieldIndex < structuredFields.length =>
        structuredFields[fieldIndex],
      _ => null,
    };
    if (field == null) return Future.value();
    return updatePromptStructuredField(
      nodeId: nodeId,
      fieldIndex: fieldIndex,
      field: field.copyWith(name: name),
    );
  }

  StructuredOutputField _uniqueStructuredField(
    WorkflowGraph graph,
    String previousName,
    StructuredOutputField field,
  ) {
    final normalized = _normalizedOutputName(field.name);
    if (normalized.isEmpty) return field.copyWith(name: '');
    return field.copyWith(
      name: _uniqueOutputName(graph, previousName, normalized),
    );
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
