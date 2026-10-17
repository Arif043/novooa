part of 'node_config.dart';

enum PromptOutputType {
  text('Freitext'),
  decision('Entscheidung'),
  structured('Strukturierte Ausgabe'),
  image('Bild');

  const PromptOutputType(this.label);

  final String label;
}

class PromptNodeConfig extends NodeConfig
    with
        FileAttachmentSupport<PromptNodeConfig>,
        KnowledgeAttachmentSupport<PromptNodeConfig>,
        SkillAttachmentSupport<PromptNodeConfig>,
        EmployeeAssignmentSupport<PromptNodeConfig> {
  const PromptNodeConfig({
    required this.instruction,
    this.languageModelId = '',
    this.generationOptions = const PromptGenerationOptions(),
    required this.outputType,
    required this.choices,
    this.structuredFields = const [
      StructuredOutputField(name: '', description: ''),
    ],
    this.attachments = const [],
    this.knowledgeAttachments = const [],
    this.skillAttachments = const [],
    this.employeeId,
  });

  final String instruction;
  final String languageModelId;
  final PromptGenerationOptions generationOptions;
  final PromptOutputType outputType;
  final List<String> choices;
  final List<StructuredOutputField> structuredFields;
  @override
  final List<NodeAttachment> attachments;
  @override
  final List<KnowledgeAttachment> knowledgeAttachments;
  @override
  final List<SkillAttachment> skillAttachments;

  /// Mitarbeiter (Subagent) des Bausteins. Schließt [skillAttachments] aus:
  /// `copyWith` hält die Regel ein (siehe `resolveNodeDelegation`).
  @override
  final String? employeeId;

  factory PromptNodeConfig.initial() {
    return const PromptNodeConfig(
      instruction: '',
      languageModelId: '',
      outputType: PromptOutputType.text,
      choices: ['', ''],
      structuredFields: [StructuredOutputField(name: '', description: '')],
      attachments: [],
      knowledgeAttachments: [],
      skillAttachments: [],
      employeeId: null,
    );
  }

  @override
  List<Object?> get props {
    return [
      instruction,
      languageModelId,
      generationOptions,
      outputType,
      choices,
      structuredFields,
      attachments,
      knowledgeAttachments,
      skillAttachments,
      employeeId,
    ];
  }

  PromptNodeConfig copyWith({
    String? instruction,
    String? languageModelId,
    PromptGenerationOptions? generationOptions,
    PromptOutputType? outputType,
    List<String>? choices,
    List<StructuredOutputField>? structuredFields,
    List<NodeAttachment>? attachments,
    List<KnowledgeAttachment>? knowledgeAttachments,
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
    return PromptNodeConfig(
      instruction: instruction ?? this.instruction,
      languageModelId: languageModelId ?? this.languageModelId,
      generationOptions: generationOptions ?? this.generationOptions,
      outputType: outputType ?? this.outputType,
      choices: choices ?? this.choices,
      structuredFields: structuredFields ?? this.structuredFields,
      attachments: attachments ?? this.attachments,
      knowledgeAttachments: knowledgeAttachments ?? this.knowledgeAttachments,
      skillAttachments: delegation.skillAttachments,
      employeeId: delegation.employeeId,
    );
  }

  PromptNodeConfig updateChoice(int index, String value) {
    if (index < 0 || index >= choices.length) return this;
    final updatedChoices = [...choices]..[index] = value;
    return copyWith(choices: updatedChoices);
  }

  PromptNodeConfig addChoice() {
    return copyWith(choices: [...choices, '']);
  }

  PromptNodeConfig removeChoice(int index) {
    if (index < 0 || index >= choices.length) return this;
    if (choices.length <= 1) return this;
    final updatedChoices = [...choices]..removeAt(index);
    return copyWith(choices: updatedChoices);
  }

  PromptNodeConfig updateStructuredField(
    int index,
    StructuredOutputField field,
  ) {
    if (index < 0 || index >= structuredFields.length) return this;
    final updatedFields = [...structuredFields]..[index] = field;
    return copyWith(structuredFields: updatedFields);
  }

  PromptNodeConfig addStructuredField() {
    return copyWith(
      structuredFields: [
        ...structuredFields,
        const StructuredOutputField(name: '', description: ''),
      ],
    );
  }

  PromptNodeConfig removeStructuredField(int index) {
    if (index < 0 || index >= structuredFields.length) return this;
    if (structuredFields.length <= 1) return this;
    final updatedFields = [...structuredFields]..removeAt(index);
    return copyWith(structuredFields: updatedFields);
  }

  @override
  PromptNodeConfig copyWithAttachments(List<NodeAttachment> attachments) {
    return copyWith(attachments: attachments);
  }

  @override
  PromptNodeConfig copyWithKnowledgeAttachments(
    List<KnowledgeAttachment> attachments,
  ) {
    return copyWith(knowledgeAttachments: attachments);
  }

  @override
  PromptNodeConfig copyWithSkillAttachments(List<SkillAttachment> attachments) {
    return copyWith(skillAttachments: attachments);
  }

  @override
  PromptNodeConfig copyWithEmployeeId(String? employeeId) {
    return copyWith(employeeId: employeeId, clearEmployee: employeeId == null);
  }

  @override
  WorkflowPrimitive get primitive => .prompt;
}
