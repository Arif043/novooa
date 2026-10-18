import 'package:syscat2/features/script_packages/domain/entities/python_package.dart';
import '../../domain/entities/node_config.dart';
import '../../domain/entities/plugin_node_config.dart';
import '../../domain/entities/knowledge_attachment.dart';
import '../../domain/entities/node_attachment.dart';
import '../../domain/entities/node_delegation.dart';
import '../../domain/entities/skill_attachment.dart';
import '../../domain/entities/workflow_graph.dart';
import '../../domain/entities/workflow_node.dart';
import 'legacy_model_output_parameters.dart';
import 'prompt_generation_options_mapper.dart';

typedef GraphToDocument = Map<String, Object?> Function(WorkflowGraph graph);
typedef GraphFromDocument = WorkflowGraph Function(Object? data);

class NodeConfigDocumentMapper {
  const NodeConfigDocumentMapper({
    required this.graphToDocument,
    required this.graphFromDocument,
  });

  final GraphToDocument graphToDocument;
  final GraphFromDocument graphFromDocument;

  static const _generationOptionsMapper = PromptGenerationOptionsMapper();

  Map<String, Object?> toDocument(NodeConfig config) {
    return switch (config) {
      StringInputNodeConfig() => _stringInputToDocument(config),
      ScriptNodeConfig() => _scriptToDocument(config),
      PromptNodeConfig() => _promptToDocument(config),
      ConditionalNodeConfig() => _conditionalToDocument(config),
      IterativeRefinementNodeConfig() => _refinementToDocument(config),
      HumanApprovalNodeConfig() => _approvalToDocument(config),
      DialogInputNodeConfig() => _dialogInputToDocument(config),
      MediaInputNodeConfig() => _mediaInputToDocument(config),
      TextToSpeechNodeConfig() => _textToSpeechToDocument(config),
      SpeechToTextNodeConfig() => _speechToTextToDocument(config),
      ModelInferenceNodeConfig() => _modelInferenceToDocument(config),
      ForEachNodeConfig() => _forEachToDocument(config),
      WriteFileNodeConfig() => _writeFileToDocument(config),
      ReadFileNodeConfig() => _readFileToDocument(config),
      DocumentLookupNodeConfig() => _documentLookupToDocument(config),
      SaveDocumentNodeConfig() => _saveDocumentToDocument(config),
      TableFromCollectionNodeConfig() => _tableFromCollectionToDocument(config),
      ReadEmailNodeConfig() => {'primitive': config.primitive.name},
      ReadChannelEventNodeConfig() => {
        'primitive': config.primitive.name,
        'kind': config.kind.name,
      },
      SendChannelMessageNodeConfig() => _sendMessageToDocument(config),
      NotificationSendNodeConfig() => _notificationSendToDocument(config),
      HttpRequestNodeConfig() => _httpRequestToDocument(config),
      PluginNodeConfig() => {
        ...config.toDocument(),
        'primitive': config.documentPrimitive,
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
      WorkflowPrimitive.dialogInput => _dialogInputFrom(data),
      WorkflowPrimitive.mediaInput => _mediaInputFrom(data),
      WorkflowPrimitive.modelInference => _modelInferenceFrom(data),
      WorkflowPrimitive.textToSpeech => _textToSpeechFrom(data),
      WorkflowPrimitive.speechToText => _speechToTextFrom(data),
      WorkflowPrimitive.forEach => _forEachFrom(data),
      WorkflowPrimitive.writeFile => _writeFileFrom(data),
      WorkflowPrimitive.readFile => _readFileFrom(data),
      WorkflowPrimitive.documentLookup => _documentLookupFrom(data),
      WorkflowPrimitive.saveDocument => _saveDocumentFrom(data),
      WorkflowPrimitive.tableFromCollection => _tableFromCollectionFrom(data),
      WorkflowPrimitive.readEmail => const ReadEmailNodeConfig(),
      WorkflowPrimitive.readChannelEvent => ReadChannelEventNodeConfig(
        kind: _channelEventKindFrom(data['kind']),
      ),
      WorkflowPrimitive.sendChannelMessage => _sendMessageFrom(data),
      WorkflowPrimitive.notificationSend => _notificationSendFrom(data),
      WorkflowPrimitive.httpRequest => _httpRequestFrom(data),
      WorkflowPrimitive.plugin =>
        PluginNodeCodecs.fromDocument(data['primitive'], data) ??
            NodeConfig.initial(WorkflowPrimitive.stringInput),
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
      'packages': [for (final package in config.packages) package.spec],
      'attachments': config.attachments.map(_attachmentToDocument).toList(),
    };
  }

  Map<String, Object?> _promptToDocument(PromptNodeConfig config) {
    return {
      'primitive': config.primitive.name,
      'instruction': config.instruction,
      'languageModelId': config.languageModelId,
      if (!config.generationOptions.usesModelDefaults)
        'generationOptions': _generationOptionsMapper.toDocument(
          config.generationOptions,
        ),
      'outputType': config.outputType.name,
      'choices': config.choices,
      'structuredFields': config.structuredFields
          .map(_structuredFieldToDocument)
          .toList(),
      'attachments': config.attachments.map(_attachmentToDocument).toList(),
      'knowledgeAttachments': config.knowledgeAttachments
          .map(_knowledgeAttachmentToDocument)
          .toList(),
      'skillAttachments': config.skillAttachments
          .map(_skillAttachmentToDocument)
          .toList(),
      if (config.employeeId != null) 'employeeId': config.employeeId,
    };
  }

  Map<String, Object?> _conditionalToDocument(ConditionalNodeConfig config) {
    return {
      'primitive': config.primitive.name,
      'valueTemplate': config.valueTemplate,
      'branches': config.branches.map(_branchToDocument).toList(),
    };
  }

  Map<String, Object?> _refinementToDocument(
    IterativeRefinementNodeConfig config,
  ) {
    return {
      'primitive': config.primitive.name,
      'draftTemplate': config.draftTemplate,
      'optimizerPrompt': config.optimizerPrompt,
      'critiquePrompt': config.critiquePrompt,
      'maxIterations': config.maxIterations,
      'skillAttachments': config.skillAttachments
          .map(_skillAttachmentToDocument)
          .toList(),
      if (config.employeeId != null) 'employeeId': config.employeeId,
    };
  }

  Map<String, Object?> _approvalToDocument(HumanApprovalNodeConfig config) {
    return {
      'primitive': config.primitive.name,
      'instruction': config.instruction,
      'reviewTemplate': config.reviewTemplate,
    };
  }

  Map<String, Object?> _dialogInputToDocument(DialogInputNodeConfig config) {
    return {
      'primitive': config.primitive.name,
      'instruction': config.instruction,
      'fields': config.fields.map(_dialogInputFieldToDocument).toList(),
    };
  }

  Map<String, Object?> _dialogInputFieldToDocument(DialogInputField field) {
    return {
      'name': field.name,
      'type': field.type.name,
      'options': field.options,
    };
  }

  Map<String, Object?> _mediaInputToDocument(MediaInputNodeConfig config) {
    return {
      'primitive': config.primitive.name,
      'instruction': config.instruction,
      'documentScanEnabled': config.documentScanEnabled,
    };
  }

  Map<String, Object?> _modelInferenceToDocument(
    ModelInferenceNodeConfig config,
  ) {
    return {
      'primitive': config.primitive.name,
      'modelId': config.modelId,
      'inputMappings': config.inputMappings
          .map(_modelInferenceInputMappingToDocument)
          .toList(),
      if (config.settings.isNotEmpty)
        'settings': config.settings
            .map(_modelInferenceSettingToDocument)
            .toList(),
    };
  }

  Map<String, Object?> _modelInferenceInputMappingToDocument(
    ModelInferenceInputMapping mapping,
  ) {
    return {
      'modelInputName': mapping.modelInputName,
      'workflowMapping': mapping.workflowMapping,
      'sourceType': mapping.sourceType,
      'dataType': mapping.dataType,
      'shape': mapping.shape,
    };
  }

  Map<String, Object?> _modelInferenceSettingToDocument(
    ModelInferenceSetting parameter,
  ) {
    return {'name': parameter.name, 'valueTemplate': parameter.valueTemplate};
  }

  Map<String, Object?> _forEachToDocument(ForEachNodeConfig config) {
    return {
      'primitive': config.primitive.name,
      'itemsTemplate': config.itemsTemplate,
      'itemsPointer': config.itemsPointer,
      'graph': graphToDocument(config.graph),
    };
  }

  Map<String, Object?> _writeFileToDocument(WriteFileNodeConfig config) {
    return {
      'primitive': config.primitive.name,
      'contentTemplate': config.contentTemplate,
      'fileName': config.fileName,
      'contentType': config.contentType,
      if (config.fileId != null) 'fileId': config.fileId,
      if (config.folderId != null) 'folderId': config.folderId,
    };
  }

  Map<String, Object?> _readFileToDocument(ReadFileNodeConfig config) {
    return {
      'primitive': config.primitive.name,
      if (config.file != null) 'file': _attachmentToDocument(config.file!),
    };
  }

  Map<String, Object?> _documentLookupToDocument(
    DocumentLookupNodeConfig config,
  ) {
    return {
      'primitive': config.primitive.name,
      'collectionName': config.collectionName,
      'filters': config.filters.map(_lookupFilterToDocument).toList(),
    };
  }

  Map<String, Object?> _tableFromCollectionToDocument(
    TableFromCollectionNodeConfig config,
  ) {
    return {
      'primitive': config.primitive.name,
      'collectionName': config.collectionName,
    };
  }

  Map<String, Object?> _lookupFilterToDocument(DocumentLookupFilter filter) {
    return {
      'field': filter.field,
      'operator': filter.operator.name,
      'value': filter.value,
    };
  }

  Map<String, Object?> _saveDocumentToDocument(SaveDocumentNodeConfig config) {
    return {
      'primitive': config.primitive.name,
      'collectionName': config.collectionName,
      'filters': config.filters.map(_lookupFilterToDocument).toList(),
      'fields': config.fields.map(_fieldAssignmentToDocument).toList(),
    };
  }

  Map<String, Object?> _fieldAssignmentToDocument(
    DocumentFieldAssignment field,
  ) {
    return {'field': field.field, 'value': field.value};
  }

  Map<String, Object?> _sendMessageToDocument(
    SendChannelMessageNodeConfig config,
  ) {
    return {
      'primitive': config.primitive.name,
      'kind': config.kind.name,
      if (config.connectorId != null) 'connectorId': config.connectorId,
      'recipient': config.recipient,
      'subject': config.subject,
      'message': config.message,
    };
  }

  Map<String, Object?> _notificationSendToDocument(
    NotificationSendNodeConfig config,
  ) {
    return {
      'primitive': config.primitive.name,
      'title': config.title,
      'message': config.message,
    };
  }

  Map<String, Object?> _httpRequestToDocument(HttpRequestNodeConfig config) {
    List<Map<String, Object?>> pairs(List<HttpNameValue> items) => [
      for (final item in items) {'name': item.name, 'value': item.value},
    ];
    return {
      'primitive': config.primitive.name,
      if (config.connectionId.isNotEmpty) 'connectionId': config.connectionId,
      'method': config.method.wire,
      'url': config.url,
      'query': pairs(config.query),
      'headers': pairs(config.headers),
      'bodyType': config.bodyType.name,
      'body': config.body,
      'timeoutSeconds': config.timeoutSeconds,
      'failOnHttpError': config.failOnHttpError,
    };
  }

  HttpRequestNodeConfig _httpRequestFrom(Map<String, Object?> data) {
    List<HttpNameValue> pairs(Object? value) => [
      if (value is List)
        for (final item in value)
          if (item is Map)
            HttpNameValue(
              name: item['name'] as String? ?? '',
              value: item['value'] as String? ?? '',
            ),
    ];
    final timeout = data['timeoutSeconds'];
    return HttpRequestNodeConfig(
      connectionId: data['connectionId'] as String? ?? '',
      method: HttpRequestMethod.fromWire(data['method']),
      url: data['url'] as String? ?? '',
      query: pairs(data['query']),
      headers: pairs(data['headers']),
      bodyType: HttpBodyType.fromName(data['bodyType']),
      body: data['body'] as String? ?? '',
      timeoutSeconds: timeout is num ? timeout.toInt() : 30,
      failOnHttpError: data['failOnHttpError'] as bool? ?? true,
    );
  }

  NotificationSendNodeConfig _notificationSendFrom(Map<String, Object?> data) {
    return NotificationSendNodeConfig(
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
    );
  }

  StringInputNodeConfig _stringInputFrom(Map<String, Object?> data) {
    return StringInputNodeConfig(value: data['value'] as String? ?? '');
  }

  ScriptNodeConfig _scriptFrom(Map<String, Object?> data) {
    return ScriptNodeConfig(
      script: data['script'] as String? ?? '',
      packages: _pythonPackagesFrom(data['packages']),
      attachments: _attachmentsFrom(data['attachments']),
    );
  }

  PromptNodeConfig _promptFrom(Map<String, Object?> data) {
    final delegation = _delegationFrom(data);
    return PromptNodeConfig(
      instruction: data['instruction'] as String? ?? '',
      languageModelId: data['languageModelId'] as String? ?? '',
      generationOptions: _generationOptionsMapper.fromDocument(
        data['generationOptions'],
      ),
      outputType: _promptOutputTypeFrom(data['outputType']),
      choices: _stringListFrom(data['choices'], fallback: const ['', '']),
      structuredFields: _structuredFieldsFrom(data['structuredFields']),
      attachments: _attachmentsFrom(data['attachments']),
      knowledgeAttachments: _knowledgeAttachmentsFrom(
        data['knowledgeAttachments'],
      ),
      skillAttachments: delegation.skillAttachments,
      employeeId: delegation.employeeId,
    );
  }

  /// Mitarbeiter und eigene Fähigkeiten schließen sich aus. Trägt ein Dokument
  /// beides (Altdaten, von Hand bearbeitet), gewinnt der Mitarbeiter.
  NodeDelegation _delegationFrom(Map<String, Object?> data) {
    final employeeId = data['employeeId'];
    return normalizedNodeDelegation(
      employeeId: employeeId is String && employeeId.isNotEmpty
          ? employeeId
          : null,
      skillAttachments: _skillAttachmentsFrom(data['skillAttachments']),
    );
  }

  ConditionalNodeConfig _conditionalFrom(Map<String, Object?> data) {
    return ConditionalNodeConfig(
      branches: _branchesFrom(data['branches']),
      valueTemplate: data['valueTemplate'] as String? ?? '',
    );
  }

  IterativeRefinementNodeConfig _refinementFrom(Map<String, Object?> data) {
    final delegation = _delegationFrom(data);
    return IterativeRefinementNodeConfig(
      optimizerPrompt: data['optimizerPrompt'] as String? ?? '',
      critiquePrompt: data['critiquePrompt'] as String? ?? '',
      maxIterations: data['maxIterations'] as int? ?? 2,
      draftTemplate: data['draftTemplate'] as String? ?? '',
      skillAttachments: delegation.skillAttachments,
      employeeId: delegation.employeeId,
    );
  }

  HumanApprovalNodeConfig _approvalFrom(Map<String, Object?> data) {
    return HumanApprovalNodeConfig(
      instruction: data['instruction'] as String? ?? '',
      reviewTemplate: data['reviewTemplate'] as String? ?? '',
    );
  }

  DialogInputNodeConfig _dialogInputFrom(Map<String, Object?> data) {
    final fields = _mapListFrom(
      data['fields'],
    ).map(_dialogInputFieldFrom).toList(growable: false);
    return DialogInputNodeConfig(
      instruction: data['instruction'] as String? ?? '',
      fields: fields.isEmpty ? DialogInputNodeConfig.initial().fields : fields,
    );
  }

  DialogInputField _dialogInputFieldFrom(Map<String, Object?> data) {
    final typeName = data['type'] as String? ?? '';
    final type = DialogInputFieldType.values.firstWhere(
      (candidate) => candidate.name == typeName,
      orElse: () => DialogInputFieldType.string,
    );
    return DialogInputField(
      name: data['name'] as String? ?? '',
      type: type,
      options: _stringListFrom(data['options'], fallback: const []),
    );
  }

  MediaInputNodeConfig _mediaInputFrom(Map<String, Object?> data) {
    return MediaInputNodeConfig(
      instruction: data['instruction'] as String? ?? '',
      documentScanEnabled: data['documentScanEnabled'] as bool? ?? false,
    );
  }

  ForEachNodeConfig _forEachFrom(Map<String, Object?> data) {
    return ForEachNodeConfig(
      itemsPointer: data['itemsPointer'] as String? ?? '',
      itemsTemplate: data['itemsTemplate'] as String? ?? '',
      graph: graphFromDocument(data['graph']),
    );
  }

  ModelInferenceNodeConfig _modelInferenceFrom(Map<String, Object?> data) {
    return ModelInferenceNodeConfig(
      modelId: data['modelId'] as String? ?? '',
      inputMappings: _modelInferenceInputMappingsFrom(data['inputMappings']),
      settings: settingsWithLegacyOutputParameters(
        _modelInferenceSettingsFrom(data['settings']),
        data['outputParameters'],
      ),
    );
  }

  TextToSpeechNodeConfig _textToSpeechFrom(Map<String, Object?> data) {
    final config = _modelInferenceFrom(data);
    return TextToSpeechNodeConfig(
      modelId: config.modelId,
      inputMappings: config.inputMappings,
      settings: config.settings,
      languageModelId: data['languageModelId'] as String? ?? '',
      speechText: data['speechText'] as String? ?? '',
      voiceId: data['voiceId'] as String? ?? '',
    );
  }

  Map<String, Object?> _textToSpeechToDocument(TextToSpeechNodeConfig config) {
    return {
      ..._modelInferenceToDocument(config),
      'languageModelId': config.languageModelId,
      'speechText': config.speechText,
      'voiceId': config.voiceId,
    };
  }

  SpeechToTextNodeConfig _speechToTextFrom(Map<String, Object?> data) {
    final config = _modelInferenceFrom(data);
    return SpeechToTextNodeConfig(
      modelId: config.modelId,
      inputMappings: config.inputMappings,
      settings: config.settings,
      languageModelId: data['languageModelId'] as String? ?? '',
      audioTemplate: data['audioTemplate'] as String? ?? '',
    );
  }

  Map<String, Object?> _speechToTextToDocument(SpeechToTextNodeConfig config) {
    return {
      ..._modelInferenceToDocument(config),
      'languageModelId': config.languageModelId,
      'audioTemplate': config.audioTemplate,
    };
  }

  List<ModelInferenceInputMapping> _modelInferenceInputMappingsFrom(
    Object? value,
  ) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((entry) {
          final data = _objectMapFrom(entry);
          return ModelInferenceInputMapping(
            modelInputName: data['modelInputName'] as String? ?? '',
            workflowMapping: data['workflowMapping'] as String? ?? '',
            sourceType: data['sourceType'] as String? ?? '',
            dataType: data['dataType'] as String? ?? '',
            shape: _objectListFrom(data['shape']),
          );
        })
        .toList(growable: false);
  }

  List<ModelInferenceSetting> _modelInferenceSettingsFrom(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((entry) {
          final data = _objectMapFrom(entry);
          return ModelInferenceSetting(
            name: data['name'] as String? ?? '',
            valueTemplate: data['valueTemplate'] as String? ?? '',
          );
        })
        .toList(growable: false);
  }

  List<Object> _objectListFrom(Object? value) {
    if (value is! List) return const [];
    return value.whereType<Object>().toList(growable: false);
  }

  WriteFileNodeConfig _writeFileFrom(Map<String, Object?> data) {
    return WriteFileNodeConfig(
      fileName: data['fileName'] as String? ?? '',
      contentType: data['contentType'] as String? ?? '',
      contentTemplate: data['contentTemplate'] as String? ?? '',
      fileId: data['fileId'] as String?,
      folderId: data['folderId'] as String?,
    );
  }

  ReadFileNodeConfig _readFileFrom(Map<String, Object?> data) {
    final file = data['file'];
    return ReadFileNodeConfig(
      file: file is Map ? _attachmentFrom(_objectMapFrom(file)) : null,
    );
  }

  DocumentLookupNodeConfig _documentLookupFrom(Map<String, Object?> data) {
    final filters = _mapListFrom(
      data['filters'],
    ).map(_lookupFilterFrom).toList(growable: false);
    return DocumentLookupNodeConfig(
      collectionName: data['collectionName'] as String? ?? '',
      filters: filters.isEmpty
          ? DocumentLookupNodeConfig.initial().filters
          : filters,
    );
  }

  TableFromCollectionNodeConfig _tableFromCollectionFrom(
    Map<String, Object?> data,
  ) {
    return TableFromCollectionNodeConfig(
      collectionName: data['collectionName'] as String? ?? '',
    );
  }

  DocumentLookupFilter _lookupFilterFrom(Map<String, Object?> data) {
    return DocumentLookupFilter(
      field: data['field'] as String? ?? '',
      operator: _lookupOperatorFrom(data['operator']),
      value: data['value'] as String? ?? '',
    );
  }

  DocumentFilterOperator _lookupOperatorFrom(Object? value) {
    return DocumentFilterOperator.values.firstWhere(
      (operator) => operator.name == value,
      orElse: () => DocumentFilterOperator.equals,
    );
  }

  SaveDocumentNodeConfig _saveDocumentFrom(Map<String, Object?> data) {
    final fields = _mapListFrom(
      data['fields'],
    ).map(_fieldAssignmentFrom).toList(growable: false);
    return SaveDocumentNodeConfig(
      collectionName: data['collectionName'] as String? ?? '',
      filters: _saveFiltersFrom(data['filters']),
      fields: fields.isEmpty ? SaveDocumentNodeConfig.initial().fields : fields,
    );
  }

  List<DocumentLookupFilter> _saveFiltersFrom(Object? value) {
    final filters = _mapListFrom(
      value,
    ).map(_lookupFilterFrom).toList(growable: false);
    return filters.isEmpty ? SaveDocumentNodeConfig.initial().filters : filters;
  }

  DocumentFieldAssignment _fieldAssignmentFrom(Map<String, Object?> data) {
    return DocumentFieldAssignment(
      field: data['field'] as String? ?? '',
      value: data['value'] as String? ?? '',
    );
  }

  SendChannelMessageNodeConfig _sendMessageFrom(Map<String, Object?> data) {
    return SendChannelMessageNodeConfig(
      kind: _channelEventKindFrom(data['kind']),
      connectorId: data['connectorId'] as String?,
      recipient: data['recipient'] as String? ?? '',
      subject: data['subject'] as String? ?? '',
      message: data['message'] as String? ?? '',
    );
  }

  Map<String, Object?> _branchToDocument(ConditionalBranch branch) {
    return {
      'id': branch.id,
      'label': branch.label,
      'graph': graphToDocument(branch.graph),
      if (branch.condition != null)
        'condition': _branchConditionToDocument(branch.condition!),
    };
  }

  Map<String, Object?> _branchConditionToDocument(BranchCondition condition) {
    return switch (condition) {
      ComparisonCondition(:final left, :final operator, :final right) => {
        'kind': 'comparison',
        'left': left,
        'operator': operator.name,
        'right': right,
      },
      GroupCondition(:final combinator, :final children) => {
        'kind': 'group',
        'combinator': combinator.name,
        'children': children.map(_branchConditionToDocument).toList(),
      },
    };
  }

  Map<String, Object?> _structuredFieldToDocument(StructuredOutputField field) {
    return {
      'name': field.name,
      'description': field.description,
      'type': field.type.name,
    };
  }

  List<StructuredOutputField> _structuredFieldsFrom(Object? value) {
    final fields = _mapListFrom(value).map(_structuredFieldFrom).toList();
    return fields.isEmpty
        ? const [StructuredOutputField(name: '', description: '')]
        : fields;
  }

  // Altdaten ohne `type`-Schlüssel fallen auf `string` zurück — exakt das
  // Verhalten, das jedes strukturierte Feld vor dieser Erweiterung hatte.
  StructuredOutputField _structuredFieldFrom(Map<String, Object?> data) {
    final typeName = data['type'] as String? ?? '';
    final type = StructuredFieldType.values.firstWhere(
      (candidate) => candidate.name == typeName,
      orElse: () => StructuredFieldType.string,
    );
    return StructuredOutputField(
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      type: type,
    );
  }

  // Eine leere Branch-Liste ist ein gültiger, persistierter Zustand (ein
  // frei eingefügter, branchfreier Bedingter-Ablauf-Baustein — siehe
  // `ConditionalNodeConfig.initial`) und wird nicht mehr durch erfundene
  // "Ja"/"Nein"-Branches ersetzt.
  List<ConditionalBranch> _branchesFrom(Object? value) {
    return _mapListFrom(value).map(_branchFrom).toList();
  }

  // `condition` fehlt bei allen vor dieser Erweiterung persistierten
  // Branches (Entscheidungs-Prompt-getrieben oder branchfrei) — `null`
  // reproduziert exakt deren bisheriges Verhalten (Label-Matching-Pfad).
  ConditionalBranch _branchFrom(Map<String, Object?> data) {
    final conditionData = data['condition'];
    return ConditionalBranch(
      id: data['id'] as String? ?? '',
      label: data['label'] as String? ?? '',
      graph: graphFromDocument(data['graph']),
      condition: conditionData is Map
          ? _branchConditionFrom(conditionData.cast<String, Object?>())
          : null,
    );
  }

  // Unbekannte/korrupte `kind`-Werte fallen auf einen leeren Vergleich
  // zurück, statt das Laden der gesamten Aufgabe zu verhindern.
  BranchCondition _branchConditionFrom(Map<String, Object?> data) {
    return switch (data['kind']) {
      'group' => GroupCondition(
        combinator: BooleanCombinator.values.firstWhere(
          (candidate) => candidate.name == data['combinator'],
          orElse: () => BooleanCombinator.and,
        ),
        children: _mapListFrom(
          data['children'],
        ).map(_branchConditionFrom).toList(),
      ),
      _ => ComparisonCondition(
        left: data['left'] as String? ?? '',
        operator: ComparisonOperator.values.firstWhere(
          (candidate) => candidate.name == data['operator'],
          orElse: () => ComparisonOperator.equals,
        ),
        right: data['right'] as String? ?? '',
      ),
    };
  }

  Map<String, Object?> _attachmentToDocument(NodeAttachment attachment) {
    return {
      'id': attachment.id,
      'storagePath': attachment.storagePath,
      'generation': attachment.generation,
      'displayName': attachment.displayName,
      'contentType': attachment.contentType,
      'sizeBytes': attachment.sizeBytes,
      if (attachment.versionCreatedAt != null)
        'versionCreatedAt': attachment.versionCreatedAt!.millisecondsSinceEpoch,
    };
  }

  /// Ungültige Angaben fallen weg; gespeichert werden nur geprüfte Pakete.
  List<PythonPackage> _pythonPackagesFrom(Object? value) {
    if (value is! List) return const [];
    return [
      for (final item in value)
        if (item is String) ?PythonPackage.parse(item),
    ];
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
      versionCreatedAt: _versionCreatedAtFrom(data['versionCreatedAt']),
    );
  }

  DateTime? _versionCreatedAtFrom(Object? value) {
    if (value is! int) return null;
    return DateTime.fromMillisecondsSinceEpoch(value);
  }

  Map<String, Object?> _knowledgeAttachmentToDocument(
    KnowledgeAttachment attachment,
  ) {
    return {
      'knowledgeBaseId': attachment.knowledgeBaseId,
      'noteId': attachment.noteId,
      'title': attachment.title,
      'path': attachment.path,
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
    );
  }

  Map<String, Object?> _skillAttachmentToDocument(SkillAttachment attachment) {
    return {'name': attachment.name, 'description': attachment.description};
  }

  List<SkillAttachment> _skillAttachmentsFrom(Object? value) {
    return _mapListFrom(
      value,
    ).map(_skillAttachmentFrom).toList(growable: false);
  }

  SkillAttachment _skillAttachmentFrom(Map<String, Object?> data) {
    return SkillAttachment(
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
    );
  }

  WorkflowPrimitive _primitiveFrom(Object? value) {
    if (PluginNodeCodecs.contains(value)) return WorkflowPrimitive.plugin;
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
