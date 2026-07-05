part of 'node_config.dart';

class IterativeRefinementNodeConfig extends NodeConfig {
  const IterativeRefinementNodeConfig({
    required this.graph,
    required this.critiquePrompt,
    required this.maxIterations,
  });

  final WorkflowGraph graph;
  final String critiquePrompt;
  final int maxIterations;

  factory IterativeRefinementNodeConfig.initial() {
    return IterativeRefinementNodeConfig(
      graph: WorkflowGraph.empty(),
      critiquePrompt: '',
      maxIterations: 2,
    );
  }

  @override
  WorkflowPrimitive get primitive => .iterativeRefinement;

  @override
  List<Object?> get props => [graph, critiquePrompt, maxIterations];

  IterativeRefinementNodeConfig copyWith({
    WorkflowGraph? graph,
    String? critiquePrompt,
    int? maxIterations,
  }) {
    return IterativeRefinementNodeConfig(
      graph: graph ?? this.graph,
      critiquePrompt: critiquePrompt ?? this.critiquePrompt,
      maxIterations: maxIterations ?? this.maxIterations,
    );
  }
}
