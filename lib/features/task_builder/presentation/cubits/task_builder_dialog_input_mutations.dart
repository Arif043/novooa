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

  /// Der Feldname ist Formular-Beschriftung und Schlüssel des Werts und muss
  /// nur innerhalb des Bausteins eindeutig sein; graph-weit eindeutig ist der
  /// Name in `WorkflowNode.outputs`.
  Future<void> updateDialogInputField({
    required NodeId nodeId,
    required int fieldIndex,
    required DialogInputField field,
  }) {
    return updateDialogInput(nodeId, (config) {
      if (fieldIndex < 0 || fieldIndex >= config.fields.length) return config;
      final siblings = [
        for (final (index, other) in config.fields.indexed)
          if (index != fieldIndex) other.name,
      ];
      final uniqueField = field.copyWith(
        name: _uniqueFieldName(siblings, _normalizedOutputName(field.name)),
      );
      return config.updateField(fieldIndex, uniqueField);
    });
  }
}
