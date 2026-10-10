part of 'task_builder_cubit.dart';

/// Ein Entscheidungs-Prompt und der direkt folgende Bedingte Ablauf sind nur
/// lose gekoppelt: Der Ablauf hat immer sichtbare Bedingungen
/// (`{{Antwort}}` *ist gleich* `Ja`); fehlende Zweige werden auf Wunsch
/// ergänzt, nie still überschrieben.
extension TaskBuilderDecisionBranchMutations on TaskBuilderCubit {
  /// Ergänzt vor „Sonst“ je einen Zweig für jede Antwort des direkt
  /// vorherigen Entscheidungs-Prompts, die noch keinen hat.
  Future<void> addMissingDecisionBranches(NodeId conditionalId) async {
    final task = loadedTaskOrNull();
    if (task == null) return;
    final prompt = directPredecessorOf(task.graph, conditionalId);
    final choices = _decisionChoicesOf(prompt);
    if (prompt == null || choices == null) return;
    await _updateNode(conditionalId, (node) {
      if (node.config case final ConditionalNodeConfig config) {
        final updated = _withDecisionBranches(
          config,
          prompt.primaryOutputName,
          choices,
        );
        return node.copyWith(config: updated);
      }
      return node;
    });
  }

  /// Ein frisch hinter [sourceId] angehängter, noch leerer Bedingter Ablauf
  /// bekommt die Zweige einmalig sofort.
  Future<void> _addDecisionBranchesToNewSuccessors(NodeId sourceId) async {
    final task = loadedTaskOrNull();
    if (task == null) return;
    for (final successor in _successorsOf(task, sourceId)) {
      if (successor.config case ConditionalNodeConfig(branches: [])) {
        await addMissingDecisionBranches(successor.id);
      }
    }
  }

  /// Hält die Bedingungen direkt folgender Bedingter Abläufe gültig, wenn
  /// der Hauptwert eines Bausteins umbenannt wird (`{{Antwort}}` →
  /// `{{Text}}`).
  Future<void> _renameDecisionOperands(
    NodeId nodeId,
    String from,
    String to,
  ) async {
    final task = loadedTaskOrNull();
    if (task == null || from.isEmpty || to.isEmpty || from == to) return;
    for (final successor in _successorsOf(task, nodeId)) {
      await _updateNode(successor.id, (node) {
        if (node.config case final ConditionalNodeConfig config) {
          return node.copyWith(config: withRenamedOperand(config, from, to));
        }
        return node;
      });
    }
  }

  ConditionalNodeConfig _withDecisionBranches(
    ConditionalNodeConfig config,
    String valueName,
    List<String> choices,
  ) {
    final missing = missingDecisionAnswers(config, valueName, choices);
    if (missing.isEmpty || valueName.isEmpty) return config;
    final branches = [...config.branches];
    final sonstIndex = branches.indexWhere(
      (branch) => branch.condition == null,
    );
    var insertAt = sonstIndex < 0 ? branches.length : sonstIndex;
    for (final answer in missing) {
      final branch = decisionBranchFor(
        id: _nextBranchId(branches),
        answer: answer,
        valueName: valueName,
      );
      branches.insert(insertAt, branch);
      insertAt += 1;
    }
    return config.copyWith(branches: branches);
  }
}

/// Die Antwortmöglichkeiten, wenn [node] ein Entscheidungs-Prompt ist.
List<String>? _decisionChoicesOf(WorkflowNode? node) {
  if (node?.config case PromptNodeConfig(
    outputType: PromptOutputType.decision,
    :final choices,
  )) {
    return choices;
  }
  return null;
}
