part of 'node_config.dart';

enum PromptOutputType {
  text('Freitext'),
  decision('Entscheidung'),
  structured('Strukturierte Ausgabe'),
  image('Bild');

  const PromptOutputType(this.label);

  final String label;
}

/// Der Laufzeit-Werttyp, den ein Feld einer strukturierten Prompt-Ausgabe
/// vom Modell erwartet — steuert das Genkit-Ausgabeschema
/// (`structuredSchemaFor` im Backend) und damit, ob der resultierende
/// Workflow-Ausgabewert als `NodeOutputValue` vom Typ `number`/`boolean`
/// statt immer `string` ankommt.
enum StructuredFieldType {
  string('Text'),
  number('Zahl'),
  boolean('Wahrheitswert');

  const StructuredFieldType(this.label);

  final String label;
}

class StructuredOutputField extends Equatable {
  const StructuredOutputField({
    required this.name,
    required this.description,
    this.type = StructuredFieldType.string,
  });

  final String name;
  final String description;
  final StructuredFieldType type;

  StructuredOutputField copyWith({
    String? name,
    String? description,
    StructuredFieldType? type,
  }) {
    return StructuredOutputField(
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
    );
  }

  @override
  List<Object?> get props => [name, description, type];
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
