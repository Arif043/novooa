part of 'node_config.dart';

enum PromptOutputType {
  text('Freitext'),
  decision('Entscheidung'),
  structured('Strukturierte Ausgabe'),
  image('Bild');

  const PromptOutputType(this.label);

  final String label;
}

class StructuredOutputField extends Equatable {
  const StructuredOutputField({required this.name, required this.description});

  final String name;
  final String description;

  StructuredOutputField copyWith({String? name, String? description}) {
    return StructuredOutputField(
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }

  @override
  List<Object?> get props => [name, description];
}

class PromptNodeConfig extends NodeConfig
    with
        FileAttachmentSupport<PromptNodeConfig>,
        KnowledgeAttachmentSupport<PromptNodeConfig>,
        SkillAttachmentSupport<PromptNodeConfig>,
        EmployeeAssignmentSupport<PromptNodeConfig> {
  const PromptNodeConfig({
    required this.instruction,
    required this.outputType,
    required this.choices,
    this.structuredFields = const [
      StructuredOutputField(name: '', description: ''),
    ],
    this.attachments = const [],
    this.knowledgeAttachments = const [],
    this.skillAttachments = const [],
    this.employee,
  });

  final String instruction;
  final PromptOutputType outputType;
  final List<String> choices;
  final List<StructuredOutputField> structuredFields;
  @override
  final List<NodeAttachment> attachments;
  @override
  final List<KnowledgeAttachment> knowledgeAttachments;
  @override
  final List<SkillAttachment> skillAttachments;
  @override
  final EmployeeAttachment? employee;

  factory PromptNodeConfig.initial() {
    return const PromptNodeConfig(
      instruction: '',
      outputType: PromptOutputType.text,
      choices: ['', ''],
      structuredFields: [StructuredOutputField(name: '', description: '')],
      attachments: [],
      knowledgeAttachments: [],
      skillAttachments: [],
      employee: null,
    );
  }

  @override
  List<Object?> get props {
    return [
      instruction,
      outputType,
      choices,
      structuredFields,
      attachments,
      knowledgeAttachments,
      skillAttachments,
      employee,
    ];
  }

  PromptNodeConfig copyWith({
    String? instruction,
    PromptOutputType? outputType,
    List<String>? choices,
    List<StructuredOutputField>? structuredFields,
    List<NodeAttachment>? attachments,
    List<KnowledgeAttachment>? knowledgeAttachments,
    List<SkillAttachment>? skillAttachments,
    EmployeeAttachment? employee,
    bool clearEmployee = false,
  }) {
    return PromptNodeConfig(
      instruction: instruction ?? this.instruction,
      outputType: outputType ?? this.outputType,
      choices: choices ?? this.choices,
      structuredFields: structuredFields ?? this.structuredFields,
      attachments: attachments ?? this.attachments,
      knowledgeAttachments: knowledgeAttachments ?? this.knowledgeAttachments,
      skillAttachments: skillAttachments ?? this.skillAttachments,
      employee: clearEmployee ? null : employee ?? this.employee,
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
  PromptNodeConfig copyWithEmployee(EmployeeAttachment? employee) {
    return copyWith(employee: employee, clearEmployee: employee == null);
  }

  @override
  WorkflowPrimitive get primitive => .prompt;
}
