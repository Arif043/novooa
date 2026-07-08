import '../../domain/entities/node_config.dart';
import '../../domain/entities/prompt_attachment.dart';
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
      _ => NodeConfig.initial(primitive),
    };
  }

  Map<String, Object?> _stringInputToDocument(StringInputNodeConfig config) {
    return {'primitive': config.primitive.name, 'value': config.value};
  }

  Map<String, Object?> _scriptToDocument(ScriptNodeConfig config) {
    return {'primitive': config.primitive.name, 'script': config.script};
  }

  Map<String, Object?> _promptToDocument(PromptNodeConfig config) {
    return {
      'primitive': config.primitive.name,
      'instruction': config.instruction,
      'outputType': config.outputType.name,
      'choices': config.choices,
      'attachments': config.attachments.map(_attachmentToDocument).toList(),
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

  StringInputNodeConfig _stringInputFrom(Map<String, Object?> data) {
    return StringInputNodeConfig(value: data['value'] as String? ?? '');
  }

  ScriptNodeConfig _scriptFrom(Map<String, Object?> data) {
    return ScriptNodeConfig(script: data['script'] as String? ?? '');
  }

  PromptNodeConfig _promptFrom(Map<String, Object?> data) {
    return PromptNodeConfig(
      instruction: data['instruction'] as String? ?? '',
      outputType: _promptOutputTypeFrom(data['outputType']),
      choices: _stringListFrom(data['choices'], fallback: const ['', '']),
      attachments: _attachmentsFrom(data['attachments']),
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

  Map<String, Object?> _branchToDocument(ConditionalBranch branch) {
    return {
      'id': branch.id,
      'label': branch.label,
      'graph': graphToDocument(branch.graph),
    };
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

  Map<String, Object?> _attachmentToDocument(PromptAttachment attachment) {
    return {
      'id': attachment.id,
      'storagePath': attachment.storagePath,
      'generation': attachment.generation,
      'displayName': attachment.displayName,
      'contentType': attachment.contentType,
      'sizeBytes': attachment.sizeBytes,
    };
  }

  List<PromptAttachment> _attachmentsFrom(Object? value) {
    return _mapListFrom(value).map(_attachmentFrom).toList(growable: false);
  }

  PromptAttachment _attachmentFrom(Map<String, Object?> data) {
    return PromptAttachment(
      id: data['id'] as String? ?? '',
      storagePath: data['storagePath'] as String? ?? '',
      generation: data['generation'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      contentType: data['contentType'] as String? ?? '',
      sizeBytes: data['sizeBytes'] as int? ?? 0,
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
}
