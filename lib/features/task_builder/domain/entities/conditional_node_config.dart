part of 'node_config.dart';

class ConditionalBranch extends Equatable {
  const ConditionalBranch({
    required this.id,
    required this.label,
    required this.graph,
    this.condition,
  });

  final String id;
  final String label;
  final WorkflowGraph graph;

  /// `null` bedeutet: der "Sonst"-Branch (greift, wenn kein anderer Branch
  /// dieses Knotens zutrifft). Nur Altdaten ohne jede Bedingung laufen im
  /// Backend noch über das Label-Matching (`conditional-executor.ts`).
  final BranchCondition? condition;

  @override
  List<Object?> get props => [id, label, graph, condition];

  ConditionalBranch copyWith({
    String? label,
    WorkflowGraph? graph,
    BranchCondition? condition,
    bool clearCondition = false,
  }) {
    return ConditionalBranch(
      id: id,
      label: label ?? this.label,
      graph: graph ?? this.graph,
      condition: clearCondition ? null : condition ?? this.condition,
    );
  }
}

class ConditionalNodeConfig extends NodeConfig {
  const ConditionalNodeConfig({
    required this.branches,
    this.valueTemplate = '',
  });

  final List<ConditionalBranch> branches;
  final String valueTemplate;

  List<String> get choices {
    return branches.map((branch) => branch.label).toList(growable: false);
  }

  /// Ohne explizite [choices] bleibt der Baustein bewusst branchfrei: Nur
  /// ein direkt vorgeschalteter Entscheidungs-Prompt füllt die Zweige
  /// (sichtbare Bedingungen, siehe `addMissingDecisionBranches`) — ein frei
  /// eingefügter Bedingter Ablauf soll nicht ungefragt "Ja"/"Nein" erfinden.
  factory ConditionalNodeConfig.initial([List<String> choices = const []]) {
    return ConditionalNodeConfig.fromChoices(choices);
  }

  factory ConditionalNodeConfig.fromChoices(List<String> choices) {
    return ConditionalNodeConfig(
      branches: [
        for (var index = 0; index < choices.length; index++)
          ConditionalBranch(
            id: 'branch.${index + 1}',
            label: choices[index],
            graph: WorkflowGraph(nodes: const [], edges: const []),
          ),
      ],
    );
  }

  @override
  WorkflowPrimitive get primitive => .conditional;

  @override
  List<Object?> get props => [branches, valueTemplate];

  ConditionalNodeConfig copyWith({
    List<ConditionalBranch>? branches,
    List<String>? choices,
    String? valueTemplate,
  }) {
    if (choices != null) return updateBranchLabels(choices);
    return ConditionalNodeConfig(
      branches: branches ?? this.branches,
      valueTemplate: valueTemplate ?? this.valueTemplate,
    );
  }

  ConditionalNodeConfig updateBranchLabels(List<String> labels) {
    return ConditionalNodeConfig(
      valueTemplate: valueTemplate,
      branches: [
        for (var index = 0; index < labels.length; index++)
          _branchFor(index, labels[index]),
      ],
    );
  }

  ConditionalBranch _branchFor(int index, String label) {
    if (index >= branches.length) {
      return ConditionalBranch(
        id: 'branch.${index + 1}',
        label: label,
        graph: WorkflowGraph(nodes: const [], edges: const []),
      );
    }
    return branches[index].copyWith(label: label);
  }
}
