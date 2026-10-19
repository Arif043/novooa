part of 'node_config.dart';

/// Baustein „Teamarbeit“: Ein Orchestrator verteilt Aufträge an die
/// [members] und liefert ein Ergebnis mit den [outputFields].
class TeamworkNodeConfig extends NodeConfig
    with
        FileAttachmentSupport<TeamworkNodeConfig>,
        KnowledgeAttachmentSupport<TeamworkNodeConfig> {
  const TeamworkNodeConfig({
    required this.instruction,
    this.languageModelId = '',
    this.generationOptions = const PromptGenerationOptions(),
    this.members = const [],
    this.outputFields = const [
      StructuredOutputField(name: '', description: ''),
    ],
    this.review = const TeamworkReview(),
    this.attachments = const [],
    this.knowledgeAttachments = const [],
  });

  /// Höchstens so viele Mitarbeiter arbeiten in einem Team.
  static const maximumMembers = 5;

  /// Anweisung an den Orchestrator.
  final String instruction;

  /// Modell des Orchestrators; leer = Standardmodell.
  final String languageModelId;
  final PromptGenerationOptions generationOptions;
  final List<TeamMember> members;
  final List<StructuredOutputField> outputFields;
  final TeamworkReview review;
  @override
  final List<NodeAttachment> attachments;
  @override
  final List<KnowledgeAttachment> knowledgeAttachments;

  factory TeamworkNodeConfig.initial() =>
      const TeamworkNodeConfig(instruction: '');

  bool get canAddMember => members.length < maximumMembers;

  TeamworkNodeConfig copyWith({
    String? instruction,
    String? languageModelId,
    PromptGenerationOptions? generationOptions,
    List<TeamMember>? members,
    List<StructuredOutputField>? outputFields,
    TeamworkReview? review,
    List<NodeAttachment>? attachments,
    List<KnowledgeAttachment>? knowledgeAttachments,
  }) {
    return TeamworkNodeConfig(
      instruction: instruction ?? this.instruction,
      languageModelId: languageModelId ?? this.languageModelId,
      generationOptions: generationOptions ?? this.generationOptions,
      members: members ?? this.members,
      outputFields: outputFields ?? this.outputFields,
      review: review ?? this.review,
      attachments: attachments ?? this.attachments,
      knowledgeAttachments: knowledgeAttachments ?? this.knowledgeAttachments,
    );
  }

  /// Nimmt einen Mitarbeiter auf; schon im Team oder Team voll: unverändert.
  TeamworkNodeConfig addMember(String employeeId) {
    final known = members.any((member) => member.employeeId == employeeId);
    if (known || !canAddMember) return this;
    return copyWith(
      members: [
        ...members,
        TeamMember(employeeId: employeeId),
      ],
    );
  }

  TeamworkNodeConfig updateMember(TeamMember updated) {
    return copyWith(
      members: [
        for (final member in members)
          member.employeeId == updated.employeeId ? updated : member,
      ],
    );
  }

  TeamworkNodeConfig removeMember(String employeeId) {
    return copyWith(
      members: [
        for (final member in members)
          if (member.employeeId != employeeId) member,
      ],
    );
  }

  TeamworkNodeConfig updateOutputField(int index, StructuredOutputField field) {
    if (index < 0 || index >= outputFields.length) return this;
    return copyWith(outputFields: [...outputFields]..[index] = field);
  }

  TeamworkNodeConfig addOutputField() {
    const empty = StructuredOutputField(name: '', description: '');
    return copyWith(outputFields: [...outputFields, empty]);
  }

  TeamworkNodeConfig removeOutputField(int index) {
    if (index < 0 || index >= outputFields.length) return this;
    if (outputFields.length <= 1) return this;
    return copyWith(outputFields: [...outputFields]..removeAt(index));
  }

  @override
  TeamworkNodeConfig copyWithAttachments(List<NodeAttachment> attachments) {
    return copyWith(attachments: attachments);
  }

  @override
  TeamworkNodeConfig copyWithKnowledgeAttachments(
    List<KnowledgeAttachment> attachments,
  ) {
    return copyWith(knowledgeAttachments: attachments);
  }

  @override
  WorkflowPrimitive get primitive => .teamwork;

  @override
  List<Object?> get props => [
    instruction,
    languageModelId,
    generationOptions,
    members,
    outputFields,
    review,
    attachments,
    knowledgeAttachments,
  ];
}
