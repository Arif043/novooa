part of 'task_builder_cubit.dart';

extension TaskBuilderOutputMutations on TaskBuilderCubit {
  /// Jeder Wert eines Bausteins ist über einen graph-weit eindeutigen Namen
  /// erreichbar (`{{Gefunden}}`); ein belegter Name bekommt eine Nummer.
  Future<void> renameOutput({
    required NodeId nodeId,
    required String key,
    required String name,
  }) {
    final task = loadedTaskOrNull();
    if (task == null) return Future.value();
    final normalizedName = _normalizedOutputName(name);
    if (normalizedName.isEmpty) return Future.value();
    return _updateOutput(nodeId, key, (output) {
      final uniqueName = _uniqueOutputName(
        task.graph,
        output.name,
        normalizedName,
      );
      return output.copyWith(name: uniqueName);
    });
  }

  /// Ob der Wert als Chip auf der Leinwand steht; im Panel steht er immer.
  Future<void> setOutputOnCanvas({
    required NodeId nodeId,
    required String key,
    required bool showOnCanvas,
  }) {
    return _updateOutput(
      nodeId,
      key,
      (output) => output.copyWith(showOnCanvas: showOnCanvas),
    );
  }

  Future<void> _updateOutput(
    NodeId nodeId,
    String key,
    WorkflowOutput Function(WorkflowOutput output) update,
  ) {
    return _updateNode(nodeId, (node) {
      if (!node.outputs.any((output) => output.key == key)) return node;
      return node.copyWith(
        outputs: [
          for (final output in node.outputs)
            output.key == key ? update(output) : output,
        ],
      );
    });
  }

  /// Gleicht die benannten Werte mit dem ab, was der Baustein liefert
  /// ([outputKeysOf]): Vorhandene bleiben samt Flag, fehlende bekommen einen
  /// Standardnamen (der Hauptwert ist auf der Leinwand sichtbar, die übrigen
  /// nicht), wegfallende Schlüssel (andere Aktion, flaches Script) gehen.
  WorkflowNode _withOutputs(
    WorkflowNode node,
    WorkflowGraph graph, {
    String? valueBase,
  }) {
    final outputs = <WorkflowOutput>[];
    for (final key in outputKeysOf(node.config)) {
      outputs.add(
        _existingOutput(node, key) ??
            _newOutput(node, graph, key, outputs, valueBase),
      );
    }
    if (_sameOutputs(outputs, node.outputs)) return node;
    return node.copyWith(outputs: outputs);
  }

  WorkflowOutput? _existingOutput(WorkflowNode node, String key) {
    for (final output in node.outputs) {
      if (output.key == key && output.name.trim().isNotEmpty) return output;
    }
    return null;
  }

  WorkflowOutput _newOutput(
    WorkflowNode node,
    WorkflowGraph graph,
    String key,
    List<WorkflowOutput> reserved,
    String? valueBase,
  ) {
    final isPrimary = key == WorkflowOutput.primaryOutputKey;
    final base = isPrimary
        ? valueBase ?? nodeTextDefaults.outputBase(node.config.primitive)
        : nodeTextDefaults.outputFieldBase(key);
    final name = _defaultOutputName(
      graph,
      base,
      alsoTaken: {for (final output in reserved) output.name},
    );
    return WorkflowOutput(key: key, name: name, showOnCanvas: isPrimary);
  }
}

bool _sameOutputs(List<WorkflowOutput> left, List<WorkflowOutput> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
