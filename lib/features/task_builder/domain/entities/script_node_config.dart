part of 'node_config.dart';

class ScriptNodeConfig extends NodeConfig
    with FileAttachmentSupport<ScriptNodeConfig> {
  const ScriptNodeConfig({
    required this.script,
    this.inputTemplate = '',
    this.attachments = const [],
  });

  final String script;
  final String inputTemplate;
  @override
  final List<NodeAttachment> attachments;

  factory ScriptNodeConfig.initial() {
    return const ScriptNodeConfig(script: 'output = input', attachments: []);
  }

  @override
  WorkflowPrimitive get primitive => .script;

  @override
  List<Object?> get props => [script, inputTemplate, attachments];

  ScriptNodeConfig copyWith({
    String? script,
    String? inputTemplate,
    List<NodeAttachment>? attachments,
  }) {
    return ScriptNodeConfig(
      script: script ?? this.script,
      inputTemplate: inputTemplate ?? this.inputTemplate,
      attachments: attachments ?? this.attachments,
    );
  }

  @override
  ScriptNodeConfig copyWithAttachments(List<NodeAttachment> attachments) {
    return copyWith(attachments: attachments);
  }
}
