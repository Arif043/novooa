part of 'task_builder_cubit.dart';

extension TaskBuilderOutputMutations on TaskBuilderCubit {
  /// Jeder Wert eines Bausteins ist über einen graph-weit eindeutigen Namen
  /// erreichbar (`{{Gefunden}}`); ein belegter Name bekommt eine Nummer.
  Future<void> renameOutput({
    required NodeId nodeId,
    required String key,
    required String name,
  }) async {
    final task = loadedTaskOrNull();
    if (task == null) return;
    final normalizedName = _normalizedOutputName(name);
    if (normalizedName.isEmpty) return;
    final previousName = _primaryNameOf(nodeId);
    await _updateOutput(nodeId, key, (output) {
      final uniqueName = _uniqueOutputName(
        task.graph,
        output.name,
        normalizedName,
      );
      return output.copyWith(name: uniqueName);
    });
    if (key == WorkflowOutput.primaryOutputKey) {
      await _renameDecisionOperands(
        nodeId,
        previousName,
        _primaryNameOf(nodeId),
      );
    }
  }

  String _primaryNameOf(NodeId nodeId) {
    final task = loadedTaskOrNull();
    final node = task == null ? null : _nodeOrNullInGraph(task.graph, nodeId);
    return node?.primaryOutputName ?? '';
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

  /// Setzt den Hauptwert auf den Standardnamen des aktuellen Typs zurück;
  /// der bisherige Name des Bausteins gilt dabei als frei.
  WorkflowNode _withResetPrimaryName(WorkflowNode node, WorkflowGraph graph) {
    final synced = _withOutputs(node, graph);
    const key = WorkflowOutput.primaryOutputKey;
    final current = synced.outputNameOf(key);
    if (!synced.outputs.any((output) => output.key == key)) return synced;
    final base = _defaultOutputBase(synced.config, key, null);
    final taken = _allOutputNames(graph)..remove(current);
    return synced.copyWith(
      outputs: [
        for (final output in synced.outputs)
          output.key == key
              ? output.copyWith(name: _numberedName(base, taken))
              : output,
      ],
    );
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
    final name = _defaultOutputName(
      graph,
      _defaultOutputBase(node.config, key, valueBase),
      alsoTaken: {for (final output in reserved) output.name},
    );
    return WorkflowOutput(
      key: key,
      name: name,
      showOnCanvas: defaultShowOnCanvas(node.config, key),
    );
  }

  /// Felder (Prompt, Dialog, Script) heißen wie im Editor bzw. im Code; der
  /// Hauptwert nach dem Baustein, weitere Werte nach ihrem Schlüssel.
  String _defaultOutputBase(NodeConfig config, String key, String? valueBase) {
    if (hasFlatOutputFields(config)) return _normalizedOutputName(key);
    if (key == WorkflowOutput.primaryOutputKey) {
      if (_isDecisionPrompt(config)) {
        return nodeTextDefaults.decisionOutputBase();
      }
      return valueBase ?? nodeTextDefaults.outputBase(config.primitive);
    }
    return nodeTextDefaults.outputFieldBase(key);
  }
}

bool _sameOutputs(List<WorkflowOutput> left, List<WorkflowOutput> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

/// [candidate] oder mit `_2`/`_3`-Suffix, bis er sich von [siblings]
/// unterscheidet; leer bleibt leer.
String _uniqueFieldName(Iterable<String> siblings, String candidate) {
  if (candidate.isEmpty) return candidate;
  final taken = {for (final name in siblings) name.trim()};
  if (!taken.contains(candidate)) return candidate;
  var suffix = 2;
  while (taken.contains('${candidate}_$suffix')) {
    suffix += 1;
  }
  return '${candidate}_$suffix';
}

bool _isDecisionPrompt(NodeConfig config) =>
    config is PromptNodeConfig &&
    config.outputType == PromptOutputType.decision;
