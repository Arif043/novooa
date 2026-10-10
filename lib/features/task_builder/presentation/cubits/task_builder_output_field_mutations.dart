part of 'task_builder_cubit.dart';

extension TaskBuilderOutputFieldMutations on TaskBuilderCubit {
  /// Die weiteren Werte eines Bausteins (z.B. `found`) sind wie der Hauptwert
  /// über einen graph-weit eindeutigen Namen erreichbar (`{{Gefunden}}`) und
  /// werden deshalb genauso umbenannt wie ein Ausgabename.
  Future<void> renameOutputField({
    required NodeId nodeId,
    required String fieldKey,
    required String name,
  }) {
    final task = loadedTaskOrNull();
    if (task == null) return Future.value();
    final normalizedName = _normalizedOutputName(name);
    if (normalizedName.isEmpty) return Future.value();
    return _updateNode(nodeId, (node) {
      if (!outputFieldsOf(node.config).contains(fieldKey)) return node;
      final previousName = node.outputFieldNameOf(fieldKey);
      final uniqueName = _uniqueOutputName(
        task.graph,
        previousName,
        normalizedName,
      );
      if (previousName == uniqueName) return node;
      return node.copyWith(
        outputFieldNames: {...node.outputFieldNames, fieldKey: uniqueName},
      );
    });
  }

  /// Vergibt Namen für Werte, die noch keinen haben (neuer Baustein, andere
  /// Shopware-Aktion, anderer Kanal), und verwirft Namen für Werte, die der
  /// Baustein nicht mehr liefert. Vorhandene Namen bleiben unverändert.
  WorkflowNode _withOutputFieldNames(WorkflowNode node, WorkflowGraph graph) {
    final names = <String, String>{};
    for (final fieldKey in outputFieldsOf(node.config)) {
      final existing = node.outputFieldNameOf(fieldKey);
      names[fieldKey] = existing.isNotEmpty
          ? existing
          : _defaultOutputName(
              graph,
              nodeTextDefaults.outputFieldBase(fieldKey),
              alsoTaken: {node.outputName, ...names.values},
            );
    }
    if (_sameNames(names, node.outputFieldNames)) return node;
    return node.copyWith(outputFieldNames: names);
  }
}

bool _sameNames(Map<String, String> left, Map<String, String> right) {
  if (left.length != right.length) return false;
  return left.entries.every((entry) => right[entry.key] == entry.value);
}
