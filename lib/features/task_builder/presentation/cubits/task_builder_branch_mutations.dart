part of 'task_builder_cubit.dart';

extension TaskBuilderBranchMutations on TaskBuilderCubit {
  Future<void> updateConditionalValue(NodeId nodeId, String valueTemplate) {
    return _updateNode(nodeId, (node) {
      if (node.config case ConditionalNodeConfig config) {
        return node.copyWith(
          config: config.copyWith(valueTemplate: valueTemplate),
        );
      }
      return node;
    });
  }

  /// Benennt einen einzelnen Zweig um (z.B. "Ja" → "Vielleicht") — wirkt
  /// sich fachlich auf die Verzweigung zur Laufzeit aus, da
  /// `conditionalFlow` den aufgelösten Wert gegen genau diese Branch-Labels
  /// matcht (siehe `conditional-executor.ts`).
  ///
  /// Geht diesem Baustein direkt ein Entscheidungs-Prompt voraus, ist dessen
  /// `choices`-Liste die fachliche Quelle der Branch-Labels (siehe
  /// `_syncConditionalSuccessors`) — die Umbenennung setzt dann dort an,
  /// damit die "Antwort" (Choice) des Prompts synchron bleibt, statt beim
  /// nächsten Lauf wieder die alte, nicht mehr passende Option zu erzeugen.
  Future<void> updateConditionalBranchLabel({
    required NodeId conditionalNodeId,
    required String branchId,
    required String label,
  }) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty) return;
    final task = loadedTaskOrNull();
    final config = switch (task == null
        ? null
        : _nodeOrNullInGraph(task.graph, conditionalNodeId)?.config) {
      ConditionalNodeConfig config => config,
      _ => null,
    };
    if (task == null || config == null) return;
    final branchIndex = config.branches.indexWhere(
      (branch) => branch.id == branchId,
    );
    if (branchIndex < 0) return;
    final syncedViaPrompt = await _syncPredecessorChoiceIfDecision(
      task: task,
      conditionalNodeId: conditionalNodeId,
      branchIndex: branchIndex,
      label: trimmed,
    );
    if (syncedViaPrompt) return;
    await _updateNode(conditionalNodeId, (node) {
      if (node.config case ConditionalNodeConfig config) {
        final branches = [
          for (final branch in config.branches)
            if (branch.id == branchId)
              branch.copyWith(label: trimmed)
            else
              branch,
        ];
        return node.copyWith(config: config.copyWith(branches: branches));
      }
      return node;
    });
  }

  /// Sucht den einzigen unmittelbaren Vorgänger des Bedingungs-Bausteins in
  /// seinem umschließenden Graphen (Haupt-Ebene oder Branch/Schleife) und
  /// stößt bei einem Entscheidungs-Prompt dessen bestehenden,
  /// bidirektionalen Sync-Pfad an (`updatePromptChoice` →
  /// `_syncConditionalSuccessors`), statt die Branch isoliert umzubenennen.
  /// Gibt `true` zurück, wenn dieser Pfad gegriffen hat.
  Future<bool> _syncPredecessorChoiceIfDecision({
    required Task task,
    required NodeId conditionalNodeId,
    required int branchIndex,
    required String label,
  }) async {
    final graph = _owningGraphOrNull(task.graph, conditionalNodeId);
    if (graph == null) return false;
    final predecessors = graph.predecessorsOf(conditionalNodeId);
    if (predecessors.length != 1) return false;
    final promptConfig = _decisionPromptConfig(task, predecessors.single.id);
    if (promptConfig == null || branchIndex >= promptConfig.choices.length) {
      return false;
    }
    await updatePromptChoice(
      nodeId: predecessors.single.id,
      choiceIndex: branchIndex,
      value: label,
    );
    return true;
  }
}
