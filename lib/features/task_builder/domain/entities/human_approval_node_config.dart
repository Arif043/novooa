part of 'node_config.dart';

enum HumanApprovalReviewScope { currentInput, executionTrace }

class HumanApprovalNodeConfig extends NodeConfig {
  const HumanApprovalNodeConfig({
    required this.instruction,
    required this.reviewScope,
  });

  final String instruction;
  final HumanApprovalReviewScope reviewScope;

  factory HumanApprovalNodeConfig.initial() {
    return const HumanApprovalNodeConfig(
      instruction: 'Prüfe das Ergebnis und gib es frei.',
      reviewScope: HumanApprovalReviewScope.currentInput,
    );
  }

  @override
  WorkflowPrimitive get primitive => WorkflowPrimitive.humanApproval;

  @override
  List<Object?> get props {
    return [instruction, reviewScope];
  }

  HumanApprovalNodeConfig copyWith({
    String? instruction,
    HumanApprovalReviewScope? reviewScope,
  }) {
    return HumanApprovalNodeConfig(
      instruction: instruction ?? this.instruction,
      reviewScope: reviewScope ?? this.reviewScope,
    );
  }
}
