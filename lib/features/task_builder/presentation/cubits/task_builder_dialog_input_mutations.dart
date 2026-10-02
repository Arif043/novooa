part of 'task_builder_cubit.dart';

extension TaskBuilderDialogInputMutations on TaskBuilderCubit {
  Future<void> updateDialogInput(
    NodeId nodeId,
    DialogInputNodeConfig Function(DialogInputNodeConfig config) update,
  ) {
    return _updateNode(nodeId, (node) {
      if (node.config case DialogInputNodeConfig config) {
        return node.copyWith(config: update(config));
      }
      return node;
    });
  }

  /// Der Feldname ist ein fachlicher Output ohne umschließenden Knotennamen
  /// (siehe `workflow_canvas_layout.dart`) und muss deshalb graph-weit
  /// eindeutig sein — nicht nur innerhalb dieses Bausteins.
  Future<void> updateDialogInputField({
    required NodeId nodeId,
    required int fieldIndex,
    required DialogInputField field,
  }) {
    final task = loadedTaskOrNull();
    if (task == null) return Future.value();
    return updateDialogInput(nodeId, (config) {
      if (fieldIndex < 0 || fieldIndex >= config.fields.length) return config;
      final previousName = config.fields[fieldIndex].name;
      final uniqueField = _uniqueDialogField(task.graph, previousName, field);
      return config.updateField(fieldIndex, uniqueField);
    });
  }

  /// Bequemlichkeits-Wrapper für Aufrufer, die nur Feldindex und neuen Namen
  /// kennen (z.B. ein Leinwand-Label-Doppelklick) — holt das aktuelle Feld
  /// selbst und ändert nur `name`, restliche Feldeigenschaften bleiben
  /// erhalten.
  Future<void> renameDialogInputFieldName({
    required NodeId nodeId,
    required int fieldIndex,
    required String name,
  }) {
    final task = loadedTaskOrNull();
    final node = task == null ? null : _nodeOrNullInGraph(task.graph, nodeId);
    final field = switch (node?.config) {
      DialogInputNodeConfig(:final fields)
          when fieldIndex >= 0 && fieldIndex < fields.length =>
        fields[fieldIndex],
      _ => null,
    };
    if (field == null) return Future.value();
    return updateDialogInputField(
      nodeId: nodeId,
      fieldIndex: fieldIndex,
      field: field.copyWith(name: name),
    );
  }

  DialogInputField _uniqueDialogField(
    WorkflowGraph graph,
    String previousName,
    DialogInputField field,
  ) {
    final normalized = _normalizedOutputName(field.name);
    if (normalized.isEmpty) return field.copyWith(name: '');
    return field.copyWith(
      name: _uniqueOutputName(graph, previousName, normalized),
    );
  }
}
