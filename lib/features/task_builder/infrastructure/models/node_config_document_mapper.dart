import '../../domain/entities/node_config.dart';
import '../../domain/entities/knowledge_attachment.dart';
import '../../domain/entities/node_attachment.dart';
import '../../domain/entities/workflow_graph.dart';
import '../../domain/entities/workflow_node.dart';

typedef GraphToDocument = Map<String, Object?> Function(WorkflowGraph graph);
typedef GraphFromDocument = WorkflowGraph Function(Object? data);

class NodeConfigDocumentMapper {
  const NodeConfigDocumentMapper({
    required this.graphToDocument,
    required this.graphFromDocument,
  });

  final GraphToDocument graphToDocument;
  final GraphFromDocument graphFromDocument;

  Map<String, Object?> toDocument(NodeConfig config) {
    return switch (config) {
      StringInputNodeConfig() => _stringInputToDocument(config),
      ScriptNodeConfig() => _scriptToDocument(config),
      PromptNodeConfig() => _promptToDocument(config),
      ConditionalNodeConfig() => _conditionalToDocument(config),
      IterativeRefinementNodeConfig() => _refinementToDocument(config),
      HumanApprovalNodeConfig() => _approvalToDocument(config),
      WriteFileNodeConfig() => _writeFileToDocument(config),
      ReadFileNodeConfig() => _readFileToDocument(config),
      ReadEmailNodeConfig() => {'primitive': config.primitive.name},
      ReadChannelEventNodeConfig() => {
        'primitive': config.primitive.name,
        'kind': config.kind.name,
      },
      _ => {'primitive': config.primitive.name},
    };
  }

  NodeConfig fromDocument(Map<String, Object?> data) {
    final primitive = _primitiveFrom(data['primitive']);
    return switch (primitive) {
      WorkflowPrimitive.stringInput => _stringInputFrom(data),
      WorkflowPrimitive.script => _scriptFrom(data),
      WorkflowPrimitive.prompt => _promptFrom(data),
      WorkflowPrimitive.conditional => _conditionalFrom(data),
      WorkflowPrimitive.iterativeRefinement => _refinementFrom(data),
      WorkflowPrimitive.humanApproval => _approvalFrom(data),
      WorkflowPrimitive.writeFile => _writeFileFrom(data),
      WorkflowPrimitive.readFile => _readFileFrom(data),
      WorkflowPrimitive.readEmail => const ReadEmailNodeConfig(),
      WorkflowPrimitive.readChannelEvent => ReadChannelEventNodeConfig(
        kind: _channelEventKindFrom(data['kind']),
      ),
      _ => NodeConfig.initial(primitive),
    };
  }

  Map<String, Object?> _stringInputToDocument(StringInputNodeConfig config) {
    return {'primitive': config.primitive.name, 'value': config.value};
  }

  Map<String, Object?> _scriptToDocument(ScriptNodeConfig config) {
    return {
      'primitive': config.primitive.name,
      'script': config.script,
      'attachments': config.attachments.map(_attachmentToDocument).toList(),
    };
  }

  Map<String, Object?> _promptToDocument(PromptNodeConfig config) {
    return {
      'primitive': config.primitive.name,
      'instruction': config.instruction,
      'outputType': config.outputType.name,
      'choices': config.choices,
      'structuredFields': config.structuredFields
          .map(_structuredFieldToDocument)
          .toList(),
      'attachments': config.attachments.map(_attachmentToDocument).toList(),
      'knowledgeAttachments': config.knowledgeAttachments
          .map(_knowledgeAttachmentToDocument)
          .toList(),
    };
  }

  Map<String, Object?> _conditionalToDocument(ConditionalNodeConfig config) {
    return {
      'primitive': config.primitive.name,
      'branches': config.branches.map(_branchToDocument).toList(),
    };
  }

  Map<String, Object?> _refinementToDocument(
    IterativeRefinementNodeConfig config,
  ) {
    return {
      'primitive': config.primitive.name,
      'optimizerPrompt': config.optimizerPrompt,
      'critiquePrompt': config.critiquePrompt,
      'maxIterations': config.maxIterations,
    };
  }

  Map<String, Object?> _approvalToDocument(HumanApprovalNodeConfig config) {
    return {
      'primitive': config.primitive.name,
      'instruction': config.instruction,
    };
  }

  Map<String, Object?> _writeFileToDocument(WriteFileNodeConfig config) {
    return {
      'primitive': config.primitive.name,
      'fileName': config.fileName,
      'contentType': config.contentType,
      if (config.fileId != null) 'fileId': config.fileId,
    };
  }

  Map<String, Object?> _readFileToDocument(ReadFileNodeConfig config) {
    return {
      'primitive': config.primitive.name,
      if (config.file != null) 'file': _attachmentToDocument(config.file!),
    };
  }

  StringInputNodeConfig _stringInputFrom(Map<String, Object?> data) {
    return StringInputNodeConfig(value: data['value'] as String? ?? '');
  }

  ScriptNodeConfig _scriptFrom(Map<String, Object?> data) {
    return ScriptNodeConfig(
      script: data['script'] as String? ?? '',
      attachments: _attachmentsFrom(data['attachments']),
    );
  }

  PromptNodeConfig _promptFrom(Map<String, Object?> data) {
    return PromptNodeConfig(
      instruction: data['instruction'] as String? ?? '',
      outputType: _promptOutputTypeFrom(data['outputType']),
      choices: _stringListFrom(data['choices'], fallback: const ['', '']),
      structuredFields: _structuredFieldsFrom(data['structuredFields']),
      attachments: _attachmentsFrom(data['attachments']),
      knowledgeAttachments: _knowledgeAttachmentsFrom(
        data['knowledgeAttachments'],
      ),
    );
  }

  ConditionalNodeConfig _conditionalFrom(Map<String, Object?> data) {
    return ConditionalNodeConfig(branches: _branchesFrom(data['branches']));
  }

  IterativeRefinementNodeConfig _refinementFrom(Map<String, Object?> data) {
    return IterativeRefinementNodeConfig(
      optimizerPrompt: data['optimizerPrompt'] as String? ?? '',
      critiquePrompt: data['critiquePrompt'] as String? ?? '',
      maxIterations: data['maxIterations'] as int? ?? 2,
    );
  }

  HumanApprovalNodeConfig _approvalFrom(Map<String, Object?> data) {
    return HumanApprovalNodeConfig(
      instruction: data['instruction'] as String? ?? '',
    );
  }

  WriteFileNodeConfig _writeFileFrom(Map<String, Object?> data) {
    return WriteFileNodeConfig(
      fileName: data['fileName'] as String? ?? '',
      contentType: data['contentType'] as String? ?? '',
      fileId: data['fileId'] as String?,
    );
  }

  ReadFileNodeConfig _readFileFrom(Map<String, Object?> data) {
    final file = data['file'];
    return ReadFileNodeConfig(
      file: file is Map ? _attachmentFrom(_objectMapFrom(file)) : null,
    );
  }

  Map<String, Object?> _branchToDocument(ConditionalBranch branch) {
    return {
      'id': branch.id,
      'label': branch.label,
      'graph': graphToDocument(branch.graph),
    };
  }

  Map<String, Object?> _structuredFieldToDocument(StructuredOutputField field) {
    return {'name': field.name, 'description': field.description};
  }

  List<StructuredOutputField> _structuredFieldsFrom(Object? value) {
    final fields = _mapListFrom(value).map(_structuredFieldFrom).toList();
    return fields.isEmpty
        ? const [StructuredOutputField(name: '', description: '')]
        : fields;
  }

  StructuredOutputField _structuredFieldFrom(Map<String, Object?> data) {
    return StructuredOutputField(
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
    );
  }

  List<ConditionalBranch> _branchesFrom(Object? value) {
    final branches = _mapListFrom(value).map(_branchFrom).toList();
    return branches.isEmpty
        ? ConditionalNodeConfig.initial().branches
        : branches;
  }

  ConditionalBranch _branchFrom(Map<String, Object?> data) {
    return ConditionalBranch(
      id: data['id'] as String? ?? '',
      label: data['label'] as String? ?? '',
      graph: graphFromDocument(data['graph']),
    );
  }

  Map<String, Object?> _attachmentToDocument(NodeAttachment attachment) {
    return {
      'id': attachment.id,
      'storagePath': attachment.storagePath,
      'generation': attachment.generation,
      'displayName': attachment.displayName,
      'contentType': attachment.contentType,
      'sizeBytes': attachment.sizeBytes,
    };
  }

  List<NodeAttachment> _attachmentsFrom(Object? value) {
    return _mapListFrom(value).map(_attachmentFrom).toList(growable: false);
  }

  NodeAttachment _attachmentFrom(Map<String, Object?> data) {
    return NodeAttachment(
      id: data['id'] as String? ?? '',
      storagePath: data['storagePath'] as String? ?? '',
      generation: data['generation'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      contentType: data['contentType'] as String? ?? '',
      sizeBytes: data['sizeBytes'] as int? ?? 0,
    );
  }

  Map<String, Object?> _knowledgeAttachmentToDocument(
    KnowledgeAttachment attachment,
  ) {
    return {
      'knowledgeBaseId': attachment.knowledgeBaseId,
      'noteId': attachment.noteId,
      'title': attachment.title,
      'path': attachment.path,
      'type': attachment.type.name,
    };
  }

  List<KnowledgeAttachment> _knowledgeAttachmentsFrom(Object? value) {
    return _mapListFrom(
      value,
    ).map(_knowledgeAttachmentFrom).toList(growable: false);
  }

  KnowledgeAttachment _knowledgeAttachmentFrom(Map<String, Object?> data) {
    return KnowledgeAttachment(
      knowledgeBaseId: data['knowledgeBaseId'] as String? ?? 'default',
      noteId: data['noteId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      path: data['path'] as String? ?? '',
      type: _knowledgeAttachmentTypeFrom(data['type']),
    );
  }

  WorkflowPrimitive _primitiveFrom(Object? value) {
    final name = value == 'conditionalFlow' ? 'conditional' : value;
    return WorkflowPrimitive.values.firstWhere(
      (primitive) => primitive.name == name,
      orElse: () => WorkflowPrimitive.stringInput,
    );
  }

  PromptOutputType _promptOutputTypeFrom(Object? value) {
    return PromptOutputType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => PromptOutputType.text,
    );
  }

  KnowledgeAttachmentType _knowledgeAttachmentTypeFrom(Object? value) {
    return KnowledgeAttachmentType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => KnowledgeAttachmentType.unknown,
    );
  }

  List<String> _stringListFrom(
    Object? value, {
    required List<String> fallback,
  }) {
    if (value is! List) return fallback;
    return value.whereType<String>().toList(growable: false);
  }

  List<Map<String, Object?>> _mapListFrom(Object? value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map(_objectMapFrom).toList(growable: false);
  }

  Map<String, Object?> _objectMapFrom(Map<dynamic, dynamic> data) {
    return data.map((key, value) => MapEntry(key.toString(), value));
  }

  ChannelEventKind _channelEventKindFrom(Object? value) {
    final name = value as String? ?? '';
    return ChannelEventKind.values.firstWhere(
      (kind) => kind.name == name,
      orElse: () => ChannelEventKind.whatsapp,
    );
  }
}
