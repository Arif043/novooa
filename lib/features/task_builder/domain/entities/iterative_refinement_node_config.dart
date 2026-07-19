part of 'node_config.dart';

class IterativeRefinementNodeConfig extends NodeConfig
    with
        SkillAttachmentSupport<IterativeRefinementNodeConfig>,
        EmployeeAssignmentSupport<IterativeRefinementNodeConfig> {
  const IterativeRefinementNodeConfig({
    required this.optimizerPrompt,
    required this.critiquePrompt,
    required this.maxIterations,
    this.skillAttachments = const [],
    this.employee,
  });

  final String optimizerPrompt;
  final String critiquePrompt;
  final int maxIterations;
  @override
  final List<SkillAttachment> skillAttachments;
  @override
  final EmployeeAttachment? employee;

  factory IterativeRefinementNodeConfig.initial() {
    return const IterativeRefinementNodeConfig(
      optimizerPrompt: '',
      critiquePrompt: '',
      maxIterations: 2,
      skillAttachments: [],
      employee: null,
    );
  }

  @override
  WorkflowPrimitive get primitive => .iterativeRefinement;

  @override
  List<Object?> get props => [
    optimizerPrompt,
    critiquePrompt,
    maxIterations,
    skillAttachments,
    employee,
  ];

  IterativeRefinementNodeConfig copyWith({
    String? optimizerPrompt,
    String? critiquePrompt,
    int? maxIterations,
    List<SkillAttachment>? skillAttachments,
    EmployeeAttachment? employee,
    bool clearEmployee = false,
  }) {
    return IterativeRefinementNodeConfig(
      optimizerPrompt: optimizerPrompt ?? this.optimizerPrompt,
      critiquePrompt: critiquePrompt ?? this.critiquePrompt,
      maxIterations: maxIterations ?? this.maxIterations,
      skillAttachments: skillAttachments ?? this.skillAttachments,
      employee: clearEmployee ? null : employee ?? this.employee,
    );
  }

  @override
  IterativeRefinementNodeConfig copyWithSkillAttachments(
    List<SkillAttachment> attachments,
  ) {
    return copyWith(skillAttachments: attachments);
  }

  @override
  IterativeRefinementNodeConfig copyWithEmployee(EmployeeAttachment? employee) {
    return copyWith(employee: employee, clearEmployee: employee == null);
  }
}
