part of 'node_config.dart';

class HumanApprovalNodeConfig extends NodeConfig {
  const HumanApprovalNodeConfig({required this.instruction});

  final String instruction;

  factory HumanApprovalNodeConfig.initial() {
    return const HumanApprovalNodeConfig(
      instruction: 'Prüfe das Ergebnis und gib es frei.',
    );
  }

  @override
  WorkflowPrimitive get primitive => WorkflowPrimitive.humanApproval;

  @override
  List<Object?> get props {
    return [instruction];
  }

  HumanApprovalNodeConfig copyWith({String? instruction}) {
    return HumanApprovalNodeConfig(
      instruction: instruction ?? this.instruction,
    );
  }
}
