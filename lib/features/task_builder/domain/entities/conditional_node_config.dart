part of 'node_config.dart';

class ConditionalBranch extends Equatable {
  const ConditionalBranch({
    required this.id,
    required this.label,
    required this.graph,
  });

  final String id;
  final String label;
  final WorkflowGraph graph;

  @override
  List<Object?> get props => [id, label, graph];

  ConditionalBranch copyWith({String? label, WorkflowGraph? graph}) {
    return ConditionalBranch(
      id: id,
      label: label ?? this.label,
      graph: graph ?? this.graph,
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

  factory ConditionalNodeConfig.initial([List<String>? choices]) {
    return ConditionalNodeConfig.fromChoices(choices ?? ['Ja', 'Nein']);
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
