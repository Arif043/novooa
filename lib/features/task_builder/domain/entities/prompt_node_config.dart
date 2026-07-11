part of 'node_config.dart';

enum PromptOutputType {
  text('Freitext'),
  decision('Entscheidung');

  const PromptOutputType(this.label);

  final String label;
}

class PromptNodeConfig extends NodeConfig
    with
        FileAttachmentSupport<PromptNodeConfig>,
        KnowledgeAttachmentSupport<PromptNodeConfig> {
  const PromptNodeConfig({
    required this.instruction,
    required this.outputType,
    required this.choices,
    this.attachments = const [],
    this.knowledgeAttachments = const [],
  });

  final String instruction;
  final PromptOutputType outputType;
  final List<String> choices;
  @override
  final List<NodeAttachment> attachments;
  @override
  final List<KnowledgeAttachment> knowledgeAttachments;

  factory PromptNodeConfig.initial() {
    return const PromptNodeConfig(
      instruction: '',
      outputType: PromptOutputType.text,
      choices: ['', ''],
      attachments: [],
      knowledgeAttachments: [],
    );
  }

  @override
  List<Object?> get props {
    return [
      instruction,
      outputType,
      choices,
      attachments,
      knowledgeAttachments,
    ];
  }

  PromptNodeConfig copyWith({
    String? instruction,
    PromptOutputType? outputType,
    List<String>? choices,
    List<NodeAttachment>? attachments,
    List<KnowledgeAttachment>? knowledgeAttachments,
  }) {
    return PromptNodeConfig(
      instruction: instruction ?? this.instruction,
      outputType: outputType ?? this.outputType,
      choices: choices ?? this.choices,
      attachments: attachments ?? this.attachments,
      knowledgeAttachments: knowledgeAttachments ?? this.knowledgeAttachments,
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
  WorkflowPrimitive get primitive => .prompt;
}
