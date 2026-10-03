part of 'node_config.dart';

class IterativeRefinementNodeConfig extends NodeConfig
    with
        SkillAttachmentSupport<IterativeRefinementNodeConfig>,
        EmployeeAssignmentSupport<IterativeRefinementNodeConfig> {
  const IterativeRefinementNodeConfig({
    required this.optimizerPrompt,
    required this.critiquePrompt,
    required this.maxIterations,
    this.draftTemplate = '',
    this.skillAttachments = const [],
    this.employeeId,
  });

  final String optimizerPrompt;
  final String critiquePrompt;
  final int maxIterations;
  final String draftTemplate;
  @override
  final List<SkillAttachment> skillAttachments;

  /// Mitarbeiter des Bausteins; schließt [skillAttachments] aus.
  @override
  final String? employeeId;

  factory IterativeRefinementNodeConfig.initial() {
    return const IterativeRefinementNodeConfig(
      optimizerPrompt: '',
      critiquePrompt: '',
      maxIterations: 2,
      skillAttachments: [],
      employeeId: null,
    );
  }

  @override
  WorkflowPrimitive get primitive => .iterativeRefinement;

  @override
  List<Object?> get props => [
    optimizerPrompt,
    critiquePrompt,
    maxIterations,
    draftTemplate,
    skillAttachments,
    employeeId,
  ];

  IterativeRefinementNodeConfig copyWith({
    String? optimizerPrompt,
    String? critiquePrompt,
    int? maxIterations,
    String? draftTemplate,
    List<SkillAttachment>? skillAttachments,
    String? employeeId,
    bool clearEmployee = false,
  }) {
    final delegation = resolveNodeDelegation(
      currentEmployeeId: this.employeeId,
      currentSkills: this.skillAttachments,
      employeeId: employeeId,
      clearEmployee: clearEmployee,
      skillAttachments: skillAttachments,
    );
    return IterativeRefinementNodeConfig(
      optimizerPrompt: optimizerPrompt ?? this.optimizerPrompt,
      critiquePrompt: critiquePrompt ?? this.critiquePrompt,
      maxIterations: maxIterations ?? this.maxIterations,
      draftTemplate: draftTemplate ?? this.draftTemplate,
      skillAttachments: delegation.skillAttachments,
      employeeId: delegation.employeeId,
    );
  }

  @override
  IterativeRefinementNodeConfig copyWithSkillAttachments(
    List<SkillAttachment> attachments,
  ) {
    return copyWith(skillAttachments: attachments);
  }

  @override
  IterativeRefinementNodeConfig copyWithEmployeeId(String? employeeId) {
    return copyWith(employeeId: employeeId, clearEmployee: employeeId == null);
  }
}
