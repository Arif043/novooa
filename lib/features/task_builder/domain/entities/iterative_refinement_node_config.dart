part of 'node_config.dart';

class IterativeRefinementNodeConfig extends NodeConfig {
  const IterativeRefinementNodeConfig({
    required this.critiquePrompt,
    required this.maxIterations,
  });

  final String critiquePrompt;
  final int maxIterations;

  factory IterativeRefinementNodeConfig.initial() {
    return const IterativeRefinementNodeConfig(
      critiquePrompt: '',
      maxIterations: 2,
    );
  }

  @override
  WorkflowPrimitive get primitive => .iterativeRefinement;

  @override
  List<Object?> get props => [critiquePrompt, maxIterations];

  IterativeRefinementNodeConfig copyWith({
    String? critiquePrompt,
    int? maxIterations,
  }) {
    return IterativeRefinementNodeConfig(
      critiquePrompt: critiquePrompt ?? this.critiquePrompt,
      maxIterations: maxIterations ?? this.maxIterations,
    );
  }
}
