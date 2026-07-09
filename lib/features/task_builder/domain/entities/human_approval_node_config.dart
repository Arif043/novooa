part of 'node_config.dart';

enum HumanApprovalReviewScope { currentInput, executionTrace }

class HumanApprovalNodeConfig extends NodeConfig {
  const HumanApprovalNodeConfig({
    required this.instruction,
    required this.allowEdit,
    required this.allowReject,
    required this.requireRejectReason,
    required this.reviewScope,
  });

  final String instruction;
  final bool allowEdit;
  final bool allowReject;
  final bool requireRejectReason;
  final HumanApprovalReviewScope reviewScope;

  factory HumanApprovalNodeConfig.initial() {
    return const HumanApprovalNodeConfig(
      instruction: 'Prüfe das Ergebnis und gib es frei.',
      allowEdit: true,
      allowReject: true,
      requireRejectReason: true,
      reviewScope: HumanApprovalReviewScope.currentInput,
    );
  }

  @override
  WorkflowPrimitive get primitive => WorkflowPrimitive.humanApproval;

  @override
  List<Object?> get props {
    return [
      instruction,
      allowEdit,
      allowReject,
      requireRejectReason,
      reviewScope,
    ];
  }

  HumanApprovalNodeConfig copyWith({
    String? instruction,
    bool? allowEdit,
    bool? allowReject,
    bool? requireRejectReason,
    HumanApprovalReviewScope? reviewScope,
  }) {
    return HumanApprovalNodeConfig(
      instruction: instruction ?? this.instruction,
      allowEdit: allowEdit ?? this.allowEdit,
      allowReject: allowReject ?? this.allowReject,
      requireRejectReason: requireRejectReason ?? this.requireRejectReason,
      reviewScope: reviewScope ?? this.reviewScope,
    );
  }
}
