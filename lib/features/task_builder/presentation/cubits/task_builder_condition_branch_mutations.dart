part of 'task_builder_cubit.dart';

/// Verwaltet bedingte Zweige (Baukasten-Bedingungen, siehe
/// `ConditionalBranchesEditor`) eines Bedingter-Ablauf-Bausteins ohne
/// Entscheidungs-Prompt-Vorgänger — für den anderen Fall bleibt
/// `TaskBuilderBranchMutations.updateConditionalBranchLabel` zuständig.
extension TaskBuilderConditionBranchMutations on TaskBuilderCubit {
  /// Der erste bedingte Zweig erhält standardmäßig einen Sonst-Pfad.
  /// Ein später explizit entfernter Sonst-Pfad bleibt ausgeschaltet.
  Future<void> addConditionBranch(NodeId conditionalNodeId) {
    return _updateNode(conditionalNodeId, (node) {
      if (node.config case ConditionalNodeConfig config) {
        final conditionedCount = config.branches
            .where((branch) => branch.condition != null)
            .length;
        final newBranch = ConditionalBranch(
          id: _nextBranchId(config.branches),
          label: 'Bedingung ${conditionedCount + 1}',
          graph: const WorkflowGraph(nodes: [], edges: []),
          condition: const ComparisonCondition(
            left: '',
            operator: ComparisonOperator.equals,
            right: '',
          ),
        );
        final sonstIndex = config.branches.indexWhere(
          (branch) => branch.condition == null,
        );
        final branches = sonstIndex < 0
            ? [
                ...config.branches,
                newBranch,
                if (conditionedCount == 0)
                  ConditionalBranch(
                    id: _nextBranchId([...config.branches, newBranch]),
                    label: 'Sonst',
                    graph: const WorkflowGraph(nodes: [], edges: []),
                  ),
              ]
            : [
                ...config.branches.sublist(0, sonstIndex),
                newBranch,
                ...config.branches.sublist(sonstIndex),
              ];
        return node.copyWith(config: config.copyWith(branches: branches));
      }
      return node;
    });
  }

  /// Entfernt einen bedingten Zweig. War es der letzte bedingte Zweig,
  /// wird der "Sonst"-Zweig mitentfernt: Rückkehr zum branchfreien
  /// Ausgangszustand statt eines nutzlosen Einzel-"Sonst"-Zweigs.
  Future<void> removeConditionBranch(
    NodeId conditionalNodeId,
    String branchId,
  ) {
    return _updateNode(conditionalNodeId, (node) {
      if (node.config case ConditionalNodeConfig config) {
        final target = config.branches.where((branch) => branch.id == branchId);
        if (target.isEmpty || target.first.condition == null) return node;
        final remaining = [
          for (final branch in config.branches)
            if (branch.id != branchId) branch,
        ];
        final hasConditionedLeft = remaining.any(
          (branch) => branch.condition != null,
        );
        final branches = hasConditionedLeft
            ? remaining
            : const <ConditionalBranch>[];
        return node.copyWith(config: config.copyWith(branches: branches));
      }
      return node;
    });
  }

  /// Nur bedingungsgesteuerte Verzweigungen haben einen optionalen Fallback.
  Future<void> setOtherwiseBranchEnabled(NodeId nodeId, bool enabled) {
    return _updateNode(nodeId, (node) {
      if (node.config case ConditionalNodeConfig config) {
        if (!config.branches.any((branch) => branch.condition != null)) {
          return node;
        }
        final hasOtherwise = config.branches.any(
          (branch) => branch.condition == null,
        );
        if (enabled == hasOtherwise) return node;
        final branches = enabled
            ? [
                ...config.branches,
                ConditionalBranch(
                  id: _nextBranchId(config.branches),
                  label: 'Sonst',
                  graph: const WorkflowGraph(nodes: [], edges: []),
                ),
              ]
            : config.branches
                  .where((branch) => branch.condition != null)
                  .toList();
        return node.copyWith(config: config.copyWith(branches: branches));
      }
      return node;
    });
  }

  /// Ersetzt den kompletten Ausdrucksbaum eines bedingten Zweigs atomar —
  /// die UI hält den Baum lokal und meldet ihn bei jeder Änderung als
  /// Ganzes zurück (gleiches Muster wie `PromptStructuredOutputSection`).
  /// Der "Sonst"-Zweig (`condition == null`) bleibt geschützt: dieser Pfad
  /// wirkt nur auf bereits bedingte Zweige.
  Future<void> updateBranchCondition({
    required NodeId conditionalNodeId,
    required String branchId,
    required BranchCondition condition,
  }) {
    return _updateNode(conditionalNodeId, (node) {
      if (node.config case ConditionalNodeConfig config) {
        final branches = [
          for (final branch in config.branches)
            if (branch.id == branchId && branch.condition != null)
              branch.copyWith(condition: condition)
            else
              branch,
        ];
        return node.copyWith(config: config.copyWith(branches: branches));
      }
      return node;
    });
  }

  String _nextBranchId(List<ConditionalBranch> branches) {
    final existingIds = branches.map((branch) => branch.id).toSet();
    var number = branches.length + 1;
    while (existingIds.contains('branch.$number')) {
      number += 1;
    }
    return 'branch.$number';
  }
}
