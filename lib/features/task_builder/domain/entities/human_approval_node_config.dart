part of 'node_config.dart';

class HumanApprovalNodeConfig extends NodeConfig {
  const HumanApprovalNodeConfig({
    required this.instruction,
    this.reviewTemplate = '',
  });

  final String instruction;
  final String reviewTemplate;

  factory HumanApprovalNodeConfig.initial() {
    return const HumanApprovalNodeConfig(
      instruction: 'Prüfe das Ergebnis und gib es frei.',
    );
  }

  @override
  WorkflowPrimitive get primitive => WorkflowPrimitive.humanApproval;

  @override
  List<Object?> get props {
    return [instruction, reviewTemplate];
  }

  HumanApprovalNodeConfig copyWith({
    String? instruction,
    String? reviewTemplate,
  }) {
    return HumanApprovalNodeConfig(
      instruction: instruction ?? this.instruction,
      reviewTemplate: reviewTemplate ?? this.reviewTemplate,
    );
  }
}
