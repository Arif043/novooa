part of 'node_config.dart';

class IterativeRefinementNodeConfig extends NodeConfig {
  const IterativeRefinementNodeConfig({
    required this.optimizerPrompt,
    required this.critiquePrompt,
    required this.maxIterations,
  });

  final String optimizerPrompt;
  final String critiquePrompt;
  final int maxIterations;

  factory IterativeRefinementNodeConfig.initial() {
    return const IterativeRefinementNodeConfig(
      optimizerPrompt: '',
      critiquePrompt: '',
      maxIterations: 2,
    );
  }

  @override
  WorkflowPrimitive get primitive => .iterativeRefinement;

  @override
  List<Object?> get props => [optimizerPrompt, critiquePrompt, maxIterations];

  IterativeRefinementNodeConfig copyWith({
    String? optimizerPrompt,
    String? critiquePrompt,
    int? maxIterations,
  }) {
    return IterativeRefinementNodeConfig(
      optimizerPrompt: optimizerPrompt ?? this.optimizerPrompt,
      critiquePrompt: critiquePrompt ?? this.critiquePrompt,
      maxIterations: maxIterations ?? this.maxIterations,
    );
  }
}
