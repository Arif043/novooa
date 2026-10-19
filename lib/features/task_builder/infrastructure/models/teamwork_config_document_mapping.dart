part of 'node_config_document_mapper.dart';

extension _TeamworkConfigDocumentMapping on NodeConfigDocumentMapper {
  Map<String, Object?> _teamworkToDocument(TeamworkNodeConfig config) {
    return {
      'primitive': config.primitive.name,
      'instruction': config.instruction,
      'languageModelId': config.languageModelId,
      if (!config.generationOptions.usesModelDefaults)
        'generationOptions': NodeConfigDocumentMapper._generationOptionsMapper
            .toDocument(config.generationOptions),
      'members': config.members.map(_teamMemberToDocument).toList(),
      'outputFields': config.outputFields
          .map(_structuredFieldToDocument)
          .toList(),
      'review': {
        'enabled': config.review.enabled,
        if (config.review.languageModelId.isNotEmpty)
          'languageModelId': config.review.languageModelId,
      },
      'attachments': config.attachments.map(_attachmentToDocument).toList(),
      'knowledgeAttachments': config.knowledgeAttachments
          .map(_knowledgeAttachmentToDocument)
          .toList(),
    };
  }

  TeamworkNodeConfig _teamworkFrom(Map<String, Object?> data) {
    return TeamworkNodeConfig(
      instruction: data['instruction'] as String? ?? '',
      languageModelId: data['languageModelId'] as String? ?? '',
      generationOptions: NodeConfigDocumentMapper._generationOptionsMapper
          .fromDocument(data['generationOptions']),
      members: _mapListFrom(
        data['members'],
      ).map(_teamMemberFrom).whereType<TeamMember>().toList(),
      outputFields: _structuredFieldsFrom(data['outputFields']),
      review: _teamworkReviewFrom(data['review']),
      attachments: _attachmentsFrom(data['attachments']),
      knowledgeAttachments: _knowledgeAttachmentsFrom(
        data['knowledgeAttachments'],
      ),
    );
  }

  Map<String, Object?> _teamMemberToDocument(TeamMember member) {
    return {
      'employeeId': member.employeeId,
      'responsibility': member.responsibility,
      if (member.languageModelId.isNotEmpty)
        'languageModelId': member.languageModelId,
    };
  }

  TeamworkReview _teamworkReviewFrom(Object? data) {
    if (data is! Map) return const TeamworkReview();
    return TeamworkReview(
      enabled: data['enabled'] as bool? ?? true,
      languageModelId: data['languageModelId'] as String? ?? '',
    );
  }

  /// Ohne Mitarbeiter-ID ist ein Eintrag wertlos und fällt weg.
  TeamMember? _teamMemberFrom(Map<String, Object?> data) {
    final employeeId = data['employeeId'];
    if (employeeId is! String || employeeId.isEmpty) return null;
    return TeamMember(
      employeeId: employeeId,
      responsibility: data['responsibility'] as String? ?? '',
      languageModelId: data['languageModelId'] as String? ?? '',
    );
  }
}
