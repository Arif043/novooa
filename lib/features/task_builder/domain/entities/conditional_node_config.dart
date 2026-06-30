part of 'node_config.dart';

class ConditionalBranch extends Equatable {
  const ConditionalBranch({
    required this.id,
    required this.label,
    required this.nodeIds,
  });

  final String id;
  final String label;
  final List<NodeId> nodeIds;

  @override
  List<Object?> get props => [id, label, nodeIds];

  ConditionalBranch copyWith({String? label, List<NodeId>? nodeIds}) {
    return ConditionalBranch(
      id: id,
      label: label ?? this.label,
      nodeIds: nodeIds ?? this.nodeIds,
    );
  }
}

class ConditionalNodeConfig extends NodeConfig {
  const ConditionalNodeConfig({required this.branches});

  final List<ConditionalBranch> branches;

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
            nodeIds: const [],
          ),
      ],
    );
  }

  @override
  WorkflowPrimitive get primitive => .conditional;

  @override
  List<Object?> get props => [branches];

  ConditionalNodeConfig copyWith({
    List<ConditionalBranch>? branches,
    List<String>? choices,
  }) {
    if (choices != null) return updateBranchLabels(choices);
    return ConditionalNodeConfig(branches: branches ?? this.branches);
  }

  ConditionalNodeConfig updateBranchLabels(List<String> labels) {
    return ConditionalNodeConfig(
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
        nodeIds: const [],
      );
    }
    return branches[index].copyWith(label: label);
  }
}
